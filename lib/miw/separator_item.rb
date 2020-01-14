
require 'miw'
require 'miw/menu_item'

module MiW
  class SeparatorItem < MenuItem
    def initialize
      super ""
    end

    def resize_to_preferred
      if menu
        panl = menu.pango_layout
        panl.text = "M"
        w, h = panl.pixel_size
        case appearance
        when :long
          frame.resize_to w, h / 2
          @Mpx = w
        when :short
          frame.resize_to w / 2, h
          @Mpx = h
        end
      end
    end

    def enable?
      false
    end

    def draw
      cairo = menu.cairo
      cs = MiW.colors
      case appearance
      when :long
        cairo.move_to frame.left + @Mpx / 2, frame.top + frame.height / 2
        cairo.line_to frame.right - @Mpx / 2, frame.top + frame.height / 2
      when :short
        h = (frame.height * (1.0 - 1 / EXTENT_RATIO) / 2).to_i
        cairo.move_to frame.left + frame.width / 2, frame.top + h
        cairo.line_to frame.left + frame.width / 2, frame.bottom - h
      end
      cairo.set_source_color cs[:control_background_disabled]
      cairo.stroke
    end
  end
end
