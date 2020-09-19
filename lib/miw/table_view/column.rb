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
    end
  end
end
