class Button < Gosu::Image
    PADDING = 2

    attr_reader :window, :x, :y, :color, :drawn
    def initialize(window, file, fullscreen, x, y, color)
      @x = x
      @y = y
      @color = color
      @drawn = false
      @window = window
      super(window, file, fullscreen)
    end

    def clicked?
      return false unless drawn?
      under_point?(window.mouse_x, window.mouse_y)
    end

    alias_method :drawn?, :drawn
    def clear
      @drawn = false
    end

    def draw
      @drawn = true
      super(x, y, color)
    end

    private

    def under_point?(mouse_x, mouse_y)
      mouse_x > x - PADDING and mouse_x < x + width + PADDING and
        mouse_y > y - PADDING and mouse_y < y + height + PADDING
    end
end
