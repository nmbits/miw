require 'observer'

module MiW
  class ScrollBar
    class DefaultModel
      include Observable

      def initialize(min: 0, max: 100, value: 0, proportion: 20, step: nil)
        @min = min
        @max = max
        @value = value
        @proportion = proportion
        @step = step
      end
      attr_reader :min, :max, :value, :proportion
      attr_accessor :step

      def set_range(min, max, value)
        unless min <= max
          raise RangeError, "min should be less than or equal to max"
        end
        unless value >= min
          raise RangeError, "value should be greater than or equal to min"
        end
        unless value <= max
          raise RangeError, "value should be less than or equal to max"
        end
        if @min != min
          @min = min
          changed
        end
        if @max != max
          @max = max
          changed
        end
        if @value != value
          @value = value
          changed
        end
        notify_observers
      end

      def value=(value)
        set_range @min, @max, value
      end
    end
  end
end
