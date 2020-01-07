
require 'miw'
require 'miw/rectangle'

module MiW
  class MenuItem
    EXTENT_RATIO = 1.4 # pseudo
    def initialize(label, shortcut: nil)
      @label = label
      @shortcut = shortcut
      @frame = Rectangle.new 0, 0, 1, 1
    end
    attr_reader :label, :frame
    attr_accessor :menu

    def draw(highlight)
      cs = MiW.colors
      panl = menu.pango_layout
      cairo = menu.cairo
      panl.text = @label
      cairo.move_to @frame.x, @frame.y
      cairo.set_source_color cs[:control_forground]
      cairo.show_pango_layout panl
    end

    def resize_to_preferred
      if menu
        panl = menu.pango_layout
        panl.text = @label
        w, h = panl.pixel_size
        w += 20 #pseudo
        h = (h * EXTENT_RATIO).ceil
        frame.resize_to w, h
      end
    end
  end
end
