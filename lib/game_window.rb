require_relative "text_input"
require_relative "button"

class GameWindow < Gosu::Window
  DEFAULT_WIDTH = 640
  DEFAULT_HEIGHT = 480
  DEFAULT_FULLSCREEN = false
  DEFAULT_CURSOR_FILE = 'media/Cursor.png'

  attr_reader :text_field_font, :width, :height, :text_field_font_z_order, :shown, :game
  attr_accessor :message
  alias_method :shown?, :shown
  def initialize(game, options={})
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
    @text_field_font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    @text_field_font_z_order = 0
    bottom_third = @height - @height / 3
    @answer_field = TextField.new(self, text_field_font, 50, bottom_third)
    @cursor = Gosu::Image.new(self, @cursor_file, false)
    @continue_button = Button.new self, 'media/continue_button.png', false, 50, @height - 60, 0
    @submit_button = Button.new self, 'media/submit_button.png', false, 50, @height - 60, 0
  end

  def show
    @shown = true
    super
  end

  def update
    game.update
  end

  ENTER_KEY = 36 # vs. GosuKbEnter = 76 !?
  def button_down(id)
    puts "button id: #{id.inspect}"
    # puts "gosu enter (#{Gosu::KbEnter}) == #{ENTER_KEY}"
    if Gosu::MsLeft == id
      puts "got left mouse, now what..."
      if @answer_field.under_point?(mouse_x, mouse_y)
        puts "answer clicked"
        # Mouse click: Select text field based on mouse position.
        # Advanced: Move caret to clicked position
        self.text_input.move_caret(mouse_x) unless self.text_input.nil?
        @answer_field.text = "" # a bit abrupt
        self.text_input = @answer_field
        @answer_field.text = "" # a bit abrupt
      elsif @submit_button.clicked?
        puts "submit"
        game.raw_response = @answer_field.text
        @answer_field.text = "" # a bit abrupt
      elsif @continue_button.clicked?
        puts "continue"
        @game.sleep_end = Gosu::milliseconds - 1
      else
        puts "no-op"
      end
    elsif ENTER_KEY == id #Gosu::KbEnter == id
      game.raw_response = @answer_field.text
    end
  end

  def close
    super
    Kernel.exit
  end

  def draw
    if game.instructing?
      @submit_button.clear
      @continue_button.draw
    elsif game.attacking?
      @continue_button.clear
      @answer_field.draw
      @submit_button.draw
    end

    @cursor.draw(mouse_x, mouse_y, 0)
    line_no = 10
    message.split("\n").each do |message_line|
      @text_field_font.draw(message_line, 10, line_no, text_field_font_z_order)
      line_no += 30
    end
  end
end
