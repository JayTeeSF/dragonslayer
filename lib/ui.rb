require_relative 'game_window'

class Ui
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

  def initialize( game, options = {} )
    @game = game
    @window = GameWindow.new(game)

    @enemy_won_file = options[ :enemy_won_file ] || DEFAULT_ENEMY_WON_FILE
    @you_won_file = options[ :you_won_file ] || DEFAULT_YOU_WON_FILE
    @quit_file = options[ :quit_file ] || DEFAULT_QUIT_FILE
    @miss_file = options[ :miss_file ] || DEFAULT_MISS_FILE
    @defeat_file = options[ :defeat_file ] || DEFAULT_DEFEAT_FILE
    @victory_file = options[ :victory_file ] || DEFAULT_VICTORY_FILE
    @roar_file = options[ :roar_file ] || DEFAULT_ROAR_FILE
    @sword_file = options[ :sword_file ] || DEFAULT_SWORD_FILE
    @start_file = options[ :start_file ] || DEFAULT_START_FILE

    tileable = false
    # @start_image = Gosu::Image.new(start_image_path, @window, tileable)
    @null_sound = NullSound.new
  end

  def exit
    window.close
    exit
  end

  def display message
    #@window.show unless @window.shown?
    #@window.message = message
    puts message
  end

  def ask question
    #@window.message = "#{question}\n\t=> "
    print "#{question}\n\t=> "
    #system "stty -echo"
    answer = gets.chomp #<-- need to replace this with some screen buttons
    # put game in :await-answer state
    #system "stty echo"
    #@window.message += "\n"
    puts
    answer
  end

  def interstitial( message_or_question, options = {} )
    sound_name = extract_or_default( :sound_name, nil, options )
    initial_sleep = extract_or_default( :initial_sleep, 1, options )
    final_sleep = extract_or_default( :final_sleep, 1.2, options )
    presentation_method = extract_or_default( :presentation_method, :display, options )
    is_clear_screen = extract_or_default( :clear_screen, true, options )

    play sound_name if sound_name
    clear_screen(initial_sleep) if is_clear_screen
    # game.queue_presentation(presentation_method, message_or_question)
    #game.response = send(presentation_method, message_or_question)
    send(presentation_method, message_or_question).tap do |response|
      game_sleep(final_sleep)
    end
  end

  def game_sleep(sleep_amount)
    sleep sleep_amount
    # game.sleep_till(Gosu::milliseconds + (sleep_amount * 1000))
  end

  def play(key=:roar)
    send("#{key}_sound").play
  end

  def clear_screen( after = 0 )
    game_sleep( after )
    # display ""
    display "\e[H\e[2J"
  end


  private

  ['sword', 'start', 'roar', 'victory', 'defeat', 'quit', 'enemy_won', 'you_won', 'miss'].each do |key|
    method_name = "#{key}_sound"
    define_method(method_name) do
      music_file_name = send("#{key}_file")
      music_file_path =  "media/#{music_file_name}"
      unless instance_variable_get("@#{method_name}")
        if File.exists?(music_file_path)
          instance_variable_set("@#{method_name}", Gosu::Sample.new(window, music_file_path))
        end
      end
      if instance_variable_get("@#{method_name}")
        instance_variable_get("@#{method_name}")
      else
        warn "null for #{music_file_path.inspect}"
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
