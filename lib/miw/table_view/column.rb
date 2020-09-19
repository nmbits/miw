require 'miw/rectangle'

module MiW
  class TableView
    class Column
      include RectangleMixin
      attr_accessor :x, :y, :width, :height
      DEFAULT_WIDTH = 100
      def initialize(key, label = nil,
                     min: 0, max: Float::INFINITY, width: DEFAULT_WIDTH, resize: true,
                     **opts)
        @key = key
        @label = label
        @min_width = min
        @max_width = max
        @resize = resize
        @width = width
        @opts = opts
        @x = @y = @height = 0
      end
      attr_reader :key, :label, :min_width, :max_width, :resize, :opts

      def draw_label(cairo, rect)
        cairo.save do
          cairo.set_source_color MiW.colors[:control_forground]
          panl = cairo.create_pango_layout
          panl.font_description = MiW.fonts[:ui]
          panl.text = label
          tw, th = panl.pixel_size
          cairo.rectangle rect.x, rect.y, rect.width, rect.height
          cairo.clip
          cairo.move_to rect.x + (rect.width - tw) / 2, rect.y + (rect.height - th) / 2
          cairo.show_pango_layout panl
        end
      end
    end
  end
end
