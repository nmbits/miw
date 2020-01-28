
module MiW
  module Util
    class Axis
      def initialize(orientation)
        @vertical = (orientation == :vertical)
      end

      def size(target)
        @vertical ? target.height : target.width
      end

      def max_size(target)
        size target.max_size
      end

      def min_size(target)
        size target.min_size
      end

      def point(target)
        @vertical ? target.y : target.x
      end

      def resize_by(target, val)
        @vertical ? target.resize_by(0, val) : target.resize_by(val, 0)
      end

      def move_by(target, val)
        @vertical ? target.move_by(0, val) : target.move_by(val, 0)
      end
    end
  end
end
