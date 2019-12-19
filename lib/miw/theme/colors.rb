
require 'cairo'

module MiW
  module Theme
    class Colors
      def initialize(name)
        @name = name
        @colors = {}
      end

      def []=(color_name, color)
        @colors[color_name] = Cairo::Color.parse color
      end

      def [](color_name)
        @colors[color_name]
      end
    end
  end
end
