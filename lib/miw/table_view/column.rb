require 'miw/rectangle'

module MiW
  class TableView
    class Column
      include RectangleMixin
      attr_accessor :x, :y, :width, :height
      DEFAULT_WIDTH = 80
      def initialize(key, label = nil, width = DEFAULT_WIDTH, **opts)
        @key = key
        @label = label
        @width = width
        @opts = opts
      end
      attr_reader :key, :label, :opts
    end
  end
end
