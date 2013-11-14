require_relative 'dragon_slayer'
require_relative 'game_window'

class Ui
  class NullGame
    def sleep_till(*args)
      Log.one { "NG#sleep_till..." }
    end
    def queue(*args)
      Log.one { "NG#queue..." }
    end
  end

  class NullWindow
    def show
      Log.one { "NW#show..." }
    end
    def close
      Log.one { "NW#close..." }
    end
    def message=(*args)
      Log.one { "NW#message=..." }
    end
  end

  DEFAULT_ENEMY_WON_FILE = 'sword_drop.mp3'.freeze
  DEFAULT_YOU_WON_FILE = 'sword_slice.mp3'.freeze
  DEFAULT_DEFEAT_FILE = 'defeat.mp3'.freeze
  DEFAULT_VICTORY_FILE = 'victory.mp3'.freeze
  DEFAULT_ROAR_FILE = 'dragon_fire.mp3'.freeze
  DEFAULT_SWORD_FILE = 'sword1.mp3'.freeze
  DEFAULT_START_FILE = 'war_horn.mp3'.freeze
  DEFAULT_MISS_FILE = 'sword_whoosh.mp3'.freeze
  DEFAULT_QUIT_FILE = 'chicken_cluck.mp3'.freeze
  attr_reader :you_won_file
  attr_reader :enemy_won_file
  attr_reader :miss_file
  attr_reader :defeat_file
  attr_reader :victory_file
  attr_reader :roar_file
  attr_reader :start_file
  attr_reader :quit_file
  attr_reader :sword_file
  attr_reader :null_sound
  attr_reader :window
  attr_reader :game

  def initialize( options = {} )
    Log.start { "UI.new" }

    @enemy_won_file = options[ :enemy_won_file ] || DEFAULT_ENEMY_WON_FILE
    @you_won_file = options[ :you_won_file ] || DEFAULT_YOU_WON_FILE
    @quit_file = options[ :quit_file ] || DEFAULT_QUIT_FILE
    @miss_file = options[ :miss_file ] || DEFAULT_MISS_FILE
    @defeat_file = options[ :defeat_file ] || DEFAULT_DEFEAT_FILE
    @victory_file = options[ :victory_file ] || DEFAULT_VICTORY_FILE
    @roar_file = options[ :roar_file ] || DEFAULT_ROAR_FILE
    @sword_file = options[ :sword_file ] || DEFAULT_SWORD_FILE
    @start_file = options[ :start_file ] || DEFAULT_START_FILE

    @null_sound = NullSound.new

    Log.puts { "new DS" }
    @game = DragonSlayer.new :ui => self
    Log.puts { "new GW" }
    @window = GameWindow.new(@game)
    Log.stop { "UI.new" }
  end

  def run
    Log.start { "Ui#run..." }
    Log.puts { "GW.show: entering game loop" }
    @window.show
    Log.stop { "Ui#run..." }
  end

  def exit
    Log.start { "UI#exit by #{caller}" }
    window.close
    Log.stop { "UI#exit ...should never be seen" }
  end

  def display message, options={}
    Log.start { "Ui#display #{message}..." }
    final_sleep = extract_or_default( :final_sleep, nil, options )
    @window.message = message
    if final_sleep
      Log.puts { "going to sleep state..." }
      game_sleep(final_sleep)
    end
    Log.stop { "Ui#display" }
  end

  def ask question, options={}
    Log.start { "ask #{question.inspect}..." }
    @window.message = "#{question}\n\t=> "

    if final_sleep = extract_or_default( :final_sleep, nil, options )
      Log.puts { "going to sleep state..." }
      game_sleep(final_sleep)
    end
    Log.stop { "ask" }
  end

  def interstitial( message_or_question, options = {} )
    Log.start { "UI#interstitial..." }
    sound_name = extract_or_default( :sound_name, nil, options )
    initial_sleep = extract_or_default( :initial_sleep, 1, options )
    final_sleep = extract_or_default( :final_sleep, 1.2, options )
    presentation_method = extract_or_default( :presentation_method, :display, options )
    is_clear_screen = extract_or_default( :clear_screen, true, options )

    Log.puts { "play #{sound_name.inspect}" }
    play( sound_name ) if sound_name
    # sleep & then queue-up some post-interstitial

    # clear_screen(initial_sleep) if is_clear_screen
    # game.queue_presentation(presentation_method, message_or_question)
    #game.response = send(presentation_method, message_or_question)
    Log.puts { "presenting with #{presentation_method.inspect}..." }
    send(presentation_method, message_or_question, :final_sleep => final_sleep)
    Log.stop { "UI#interstitial..." }
  end

  def game_sleep(sleep_amount)
    game.sleep_till(Gosu::milliseconds + (sleep_amount * 1000))
  end

  def play(key=:roar)
    Log.start { "play #{key}..." }
    send("#{key}_sound").play
    Log.stop { "play" }
  end

  def clear_display
    Log.start { "clear_display" }
    # display "\e[H\e[2J"
    display ""
    Log.stop { "clear_display" }
  end

  def clear_screen( after = 0 )
    Log.start { "clear_screen" }
    game.queue(:clear_display)
    game_sleep( after )
    Log.stop { "clear_screen" }
  end


  private

  ['sword', 'start', 'roar', 'victory', 'defeat', 'quit', 'enemy_won', 'you_won', 'miss'].each do |key|
    method_name = "#{key}_sound"
    define_method(method_name) do
      Log.start { method_name }
      unless instance_variable_get("@#{method_name}")
        music_file_name = send("#{key}_file")
        music_file_path =  "media/#{music_file_name}"
        if File.exists?(music_file_path)
          Log.puts { "found music: #{music_file_path}" }
          instance_variable_set("@#{method_name}", Gosu::Sample.new(window, music_file_path))
        end
      end
      if instance_variable_get("@#{method_name}")
        Log.stop { method_name }
        instance_variable_get("@#{method_name}")
      else
        Log.puts { "null" }
        Log.stop { method_name }
        null_sound
      end
    end
  end

  def extract_or_default(key, default, options={})
    if options.has_key?(key)
      got = options[key]
    else
      got = default
    end
    return got
  end
end
