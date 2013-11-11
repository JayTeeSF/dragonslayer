require_relative "text_input"
class GameWindow < Gosu::Window
  DEFAULT_WIDTH = 640
  DEFAULT_HEIGHT = 480
  DEFAULT_FULLSCREEN = false
  DEFAULT_CURSOR_FILE = 'media/Cursor.png'

  attr_reader :font, :width, :height, :font_z_order, :shown, :game
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
    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    @font_z_order = 0
    @answer_field = TextField.new(self, font, 50, @height - 60)
    @cursor = Gosu::Image.new(self, @cursor_file, false)
  end

  def show
    @shown = true
    super
  end

  def update
    game.update
  end

  MOUSE_CLICK = 256
  ENTER_KEY = 36
  def button_down(id)
    # puts "key id: #{id.inspect}"
    if MOUSE_CLICK == id
      # Mouse click: Select text field based on mouse position.
      if @answer_field.under_point?(mouse_x, mouse_y)
        @answer_field.text = "" # a bit abrupt
        self.text_input = @answer_field
      end
      # Advanced: Move caret to clicked position
      self.text_input.move_caret(mouse_x) unless self.text_input.nil?
    elsif ENTER_KEY == id #Gosu::KbEnter == id
      game.raw_response = @answer_field.text
    end
  end

  def draw
    @answer_field.draw
    @cursor.draw(mouse_x, mouse_y, 0)
    line_no = 10
    message.split("\n").each do |message_line|
      @font.draw(message_line, 10, line_no, font_z_order) #, 1.0, 1.0, 0x00000000)
      line_no += 30
    end
  end
end
