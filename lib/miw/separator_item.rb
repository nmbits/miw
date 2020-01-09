
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
        frame.resize_to w, h / 2
        @Mpx = w
      end
    end

    def enable?
      false
    end

    def draw
      cairo = menu.cairo
      cs = MiW.colors
      cairo.move_to frame.left + @Mpx / 2, frame.top + frame.height / 2
      cairo.line_to frame.right - @Mpx / 2, frame.top + frame.height / 2
      cairo.set_source_color cs[:control_background_disabled]
      cairo.stroke
    end
  end
end
