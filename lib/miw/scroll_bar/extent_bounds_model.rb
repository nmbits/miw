module MiW
  class ScrollBar
    class ExtentBoundsModel
      def initialize(target, orientation)
        @target = target
        @orientation = orientation
      end

      def min
        extent = @target.extent
        case @orientation
        when :vertical
          extent.top
        else
          extent.left
        end
      end

      def max
        extent = @target.extent
        case @orientation
        when :vertical
          extent.bottom
        else
          extent.right
        end
      end

      def value
        bounds = @target.bounds
        case @orientation
        when :vertical
          bounds.top
        else
          bounds.left
        end
      end

      def value=(v)
        bounds = @target.bounds
        case @orientation
        when :vertical
          @target.scroll_to bounds.x, v
        else
          @target.scroll_to v, bounds.y
        end
      end

      def proportion
        bounds = @target.bounds
        case @orientation
        when :vertical
          bounds.height
        else
          bounds.width
        end
      end

      def step
        # pseud
        nil
      end
    end
  end
end
