
require 'miw'
require 'miw/rectangle'

module MiW
  class MenuItem
    def initialize(label, shortcut: nil)
      @label = label
      @shortcut = shortcut
      @frame = Rectangle.new 0, 0, 1, 1
    end
    attr_reader :label, :frame

    def draw(menu, highlight)
      cs = MiW.colors
      menu.pango_layout.text = @label
      menu.cairo.move_to @frame.x, @frame.y
      menu.cairo.set_source_color cs[:control_forground]
      menu.cairo.show_pango_layout menu.pango_layout
    end
  end
end
