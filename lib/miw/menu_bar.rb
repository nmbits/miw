require 'miw'
require 'miw/menu'
require 'miw/layout/box'
require 'pango'

module MiW
  class MenuBar < Menu
    EXTENT_RATIO = 1.4 # pseudo
    MARGINE_RATIO = 0.4 # pseudo
    def initialize(name, **opts)
      super
      resize_to DEFAULT_SIZE
      @pango_layouts = []
    end

    def attached_to_window
      new_height = 0
      items.each do |i|
        l = cairo.create_pango_layout
        l.font_description = font
        l.text = i.label
        @pango_layouts << l
        new_heigh = [new_height, l.pixel_size[1]].max
      end
      if new_height == 0
        l = cairo.create_pango_layout
        l.font_description = font
        l.text = "M"
        new_height = l.pixel_size[1]
      end
      new_height = (new_height * EXTENT_RATIO).ceil
      @margine = (new_height * MARGINE_RATIO).ceil
      p new_height
      resize_to(width, new_height)
    end

    def detached_from_window
      @pango_layouts.clean
    end

    def add_item(item)
      super
      if attached?
        l = cairo.create_pango_layout
        l.font_description = font
        l.text = item.text
        new_height = (l.pixel_size[1] * 1.2).to_i
        resize_to width, new_height if new_height > height
      end
    end

    def draw(rect)
      cx = @margine
      cy = (height * (1.0 - 1.0 / EXTENT_RATIO) / 2).to_i
      cs = MiW.colors
      cairo.rectangle 0, 0, width, height
      cairo.set_source_color cs[:control_background]
      cairo.fill
      cairo.set_source_color cs[:control_forground]
      @pango_layouts.each do |l|
        cairo.move_to cx, cy
        cairo.show_pango_layout l
        cx += l.pixel_size[0]
        cx += @margine
      end
    end
  end
end
