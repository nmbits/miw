
require 'miw'
require 'miw/rectangle'

module MiW
  class MenuItem
    EXTENT_RATIO = 1.4 # pseudo
    MARGINE = 20 # pseudo
    def initialize(label, shortcut: nil, accel_key: nil, icon: nil, submenu: nil, type: :default)
      @label = label
      @shortcut = shortcut
      @accel_key = accel_key
      @icon = icon
      @type = type
      @frame = Rectangle.new 0, 0, 1, 1
      @enable = true
      @appearance = :long
      @submenu = submenu
    end
    attr_reader :label, :frame, :shortcut, :accel_key, :icon, :type, :submenu
    attr_accessor :menu, :appearance

    def enable=(v = true)
      @enable = v ? true : false
    end

    def disable
      @enable = false
    end

    def enable?
      @enable ? true : false
    end

    def highlight?
      menu && menu.highlight == self
    end

    def draw
      cairo = menu.cairo
      cs = MiW.colors
      if enable?
        bgcolor = highlight? ? cs[:control_background_highlight] : cs[:control_background]
        fgcolor = highlight? ? cs[:control_forground_highlight] : cs[:control_forground]
      else
        bgcolor = cs[:control_background]
        fgcolor = cs[:control_forground_disabled]
      end
      cairo.rectangle frame.x, frame.y, frame.width, frame.height
      cairo.set_source_color bgcolor
      cairo.fill
      cairo.set_source_color fgcolor
      panl = menu.pango_layout
      panl.text = @label
      case @appearance
      when :long
        x = @frame.x + @icon_width + 10 # pseudo
      when :short
        x = @frame.x + MARGINE / 2 # pseudo
      end
      y = @frame.y + (@frame.height * (1.0 - 1 / EXTENT_RATIO) / 2).to_i
      cairo.move_to x, y
      cairo.show_pango_layout panl
    end

    def resize_to_preferred
      if menu
        panl = menu.pango_layout
        panl.text = @label
        w, h = panl.pixel_size
        case @appearance
        when :long
          @icon_width = h
          w += @icon_width
        when :short
        end
        w += MARGINE #pseudo
        h = (h * EXTENT_RATIO).ceil
        frame.resize_to w, h
      end
    end
  end
end
