require 'miw/view'
require 'miw/size'
require 'pango'

module MiW
  class StringView < View
    def initialize(id, string: "", **opts)
      super id, **opts
      @string = string
    end

    def draw(rect)
      cs = MiW.colors
      cairo.rectangle rect.x, rect.y, rect.width, rect.height
      cairo.set_source_color cs[:control_background]
      cairo.fill
      cairo.set_source_color cs[:control_forground]
      cairo.show_pango_layout pango_layout
      cairo.rectangle 0, 0, width, height
      cairo.stroke
    end

    private

    def pango_layout
      if cairo
        @pango_layout ||= cairo.create_pango_layout
        @pango_layout.font_description = font
        @pango_layout.text = @string
        @pango_layout.width = width * Pango::SCALE
        @pango_layout.height = height * Pango::SCALE
      end
      @pango_layout
    end

    def text
      @string
    end
  end
end
