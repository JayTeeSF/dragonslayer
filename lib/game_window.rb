class GameWindow < Gosu::Window
  DEFAULT_WIDTH = 640
  DEFAULT_HEIGHT = 480
  DEFAULT_FULLSCREEN = false
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
    @caption = options[:caption] || game.name
    super(@width, @height, @fullscreen)
    self.caption = @caption
    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    @font_z_order = 0
  end

  def show
    @shown = true
    super
  end

  def update
    game.update
  end

  def draw
    # @font.draw(message, 10, 10, font_z_order, 1.0, 1.0, 0xffffff00)
    line_no = 10
    message.split("\n").each do |message_line|
      @font.draw(message_line, 10, line_no, font_z_order) #, 1.0, 1.0, 0x00000000)
      line_no += 30
    end
  end
end
