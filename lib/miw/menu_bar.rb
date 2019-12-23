require 'miw'
require 'miw/menu'
require 'pango'

module MiW
  class MenuBar < Menu
    def initialize(name, **opts)
      super name, **opts
      resize_to(0, 14) #pseudo
    end

    def draw(rect)
      cx = cy = 0
      cs = MiW.colors
      cairo.rectangle 0, 0, width, height
      cairo.set_source_color cs[:control_background]
      cairo.fill
      cairo.set_source_color cs[:control_forground]
      items.each do |i|
        l = cairo.create_pango_layout
        l.text = i.label
        cairo.move_to cx, cy
        cairo.show_pango_layout l
        cx += l.pixel_size[0]
      end
    end
  end
end
