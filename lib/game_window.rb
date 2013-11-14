require_relative "text_input"
require_relative "button"

class GameWindow < Gosu::Window
  DEFAULT_WIDTH = 640
  DEFAULT_HEIGHT = 480
  DEFAULT_FULLSCREEN = false
  DEFAULT_CURSOR_FILE = 'media/Cursor.png'
  LINE_HEIGHT = 20
  PADDING = 10

  attr_reader :text_field_font, :width, :height, :text_field_font_z_order, :shown, :game
  attr_accessor :message
  def initialize(game, options={})
    Log.start { "GW.new" }
    @game = game
    @shown = false
    @message  = ""
    @width = options[:width] || DEFAULT_WIDTH
    @height = options[:height]||DEFAULT_HEIGHT
    @fullscreen = options[:fullscreen] || DEFAULT_FULLSCREEN
    @cursor_file = options[:cursor_file] || DEFAULT_CURSOR_FILE
    @caption = options[:caption] || game.name
    super(@width, @height, @fullscreen)
    self.caption = @caption
    Log.puts { "captioned..." }
    @you_health_font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    @enemy_health_font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    @text_field_font = Gosu::Font.new(self, Gosu::default_font_name, 20)

    Log.puts { "new fonts..." }
    @text_field_font_z_order = 0
    @answer_field = TextField.new(self, text_field_font, left_of_middle_third, top_of_bottom_third)
    @cursor = Gosu::Image.new(self, @cursor_file, false)
    @continue_button = Button.new self, 'media/continue_button.png', false, left_of_middle_third, mid_bottom_third, 0
    @submit_button = Button.new self, 'media/submit_button.png', false, left_of_middle_third, mid_bottom_third, 0
    Log.stop { "GW.new" }
  end

  def top_of_middle_third
    Log.start { "tomt" }
    unless @top_of_middle_third
      @top_of_middle_third = @height / 3
    end
    Log.stop { "tomt" }
    @top_of_middle_third
  end

  def left_of_right_third
    Log.start { "lort" }
    unless @left_of_right_third
      @left_of_right_third = @width - @width / 3
    end
    Log.stop { "lort" }
    @left_of_right_third
  end
  def left_of_middle_third
    Log.start { "lomt" }
    unless @left_of_middle_third
      @left_of_middle_third = @width / 3
    end
    Log.stop { "lomt" }
    @left_of_middle_third
  end

  def mid_bottom_third
    Log.start { "mbt" }
    unless @mid_bottom_third
      @mid_bottom_third = @height - ((@height / 3) / 2)
    end
    Log.stop { "mbt" }
    @mid_bottom_third
  end

  def top_of_bottom_third
    Log.start { "tobt" }
    unless @top_of_bottom_third
      @top_of_bottom_third = @height - @height / 3
    end
    Log.stop { "tobt" }
    @top_of_bottom_third
  end

  def show
    Log.start { "GW#show..." }
    if shown
      Log.puts { "already shown" }
      return
    end
    @shown = true
    super
    Log.stop { "GW#show..." }
  end

  def update
    Log.start { "GW#upd..." }
    Log.puts { "DS#update" }
    game.update
    Log.puts { "DS#instructing? || DS.attacking?" }
    if game.instructing?
      Log.puts { "erasing answer_field" }
      @answer_field.erase
      Log.puts { "erasing submit_button" }
      @submit_button.erase
    elsif game.attacking?
      Log.puts { "erasing continue_button" }
      @continue_button.erase
    end
    Log.stop { "GW#upd..." }
  end

  ENTER_KEY = 36 # vs. GosuKbEnter = 76 !?
  def button_down(id)
    Log.start { "GW#button_down..." }
    Log.puts { "button id: #{id.inspect}" }
    # puts "gosu enter (#{Gosu::KbEnter}) == #{ENTER_KEY}"
    if Gosu::MsLeft == id
      Log.puts { "got left mouse, now what..." }
      if @answer_field.clicked?
        Log.puts { "answer clicked" }
        # Mouse click: Select text field based on mouse position.
        # Advanced: Move caret to clicked position
        self.text_input.move_caret(mouse_x) unless self.text_input.nil?
        @answer_field.text = "" # a bit abrupt
        self.text_input = @answer_field
        @answer_field.text = "" # a bit abrupt
      elsif @submit_button.clicked?
        Log.puts { "submit" }
        game.raw_response = @answer_field.text
        @answer_field.text = "" # a bit abrupt
      elsif @continue_button.clicked?
        Log.puts { "continue" }
        @game.sleep_end = Gosu::milliseconds - 1
      else
        Log.puts { "no-op" }
      end
    elsif ENTER_KEY == id #Gosu::KbEnter == id
      game.raw_response = @answer_field.text
    end
    Log.stop { "GW#button_down..." }
  end

  def close
    Log.start { "GW#closing; by #{caller}" }
    # game._end
    super
    Log.stop { "GW#close..." }
    Kernel.exit
  end

  def draw
    Log.start { "GW#draw (by #{caller.detect{|c| c =~ %r[dragonslayer/lib]}.inspect})..." }
    Log.puts { "DS#instructing? || DS.attacking?" }
    if game.instructing?
      Log.puts { "instructing == true" }
      @continue_button.draw
    elsif game.attacking?
      Log.puts { "attacking == true" }
      @answer_field.draw
      @submit_button.draw
    else
      Log.puts { "neither instructing nor attacking" }
    end

    #puts "d cursor..."
    @cursor.draw(mouse_x, mouse_y, 0)

    Log.puts { "you_h: #{game.you.health}, @ #{you_score_left_x}, #{you_score_top_y}, with zo: #{text_field_font_z_order}" }
    @you_health_font.draw(game.you.health.to_s, you_score_left_x, you_score_top_y, text_field_font_z_order)
    Log.puts { "d enemy_h: #{game.enemy.health}, @ #{enemy_score_left_x}, #{enemy_score_top_y}, with zo: #{text_field_font_z_order}" }
    @enemy_health_font.draw(game.enemy.health.to_s, enemy_score_left_x, enemy_score_top_y, text_field_font_z_order)

    line_indent = message_left_x
    Log.puts { "set line_indent #{line_indent}" }
    line_y = message_top_y
    Log.puts { "set line_y: #{line_y}" }

    message_lines = message.split("\n")
    Log.puts { "message_lines: #{message_lines.inspect}" }
    message_lines.each do |message_line|
      if "" == message_line
        Log.puts { "skipping line" }
      else
        Log.puts { "drawing text: (#{message_line}) at: #{line_indent}, #{line_y}, with z: #{text_field_font_z_order}" }
        @text_field_font.draw(message_line, line_indent, line_y, text_field_font_z_order)
      end
      line_y = line_y + LINE_HEIGHT
      Log.puts { "new line_y: #{line_y}" }
    end
    Log.stop { "GW#draw" }
  end

  # Positioning
  def you_score_top_y
    Log.one { "ysty..." }
    PADDING
  end

  def message_left_x
    Log.one { "mlx..." }
    PADDING
  end

  alias_method :enemy_score_top_y, :you_score_top_y
  alias_method :message_top_y, :top_of_middle_third
  alias_method :you_score_left_x, :message_left_x
  alias_method :enemy_score_left_x, :left_of_right_third
end
