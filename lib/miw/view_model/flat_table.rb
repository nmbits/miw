
module MiW
  module ViewModel
    class FlatTable
      attr_reader :total
      attr_reader :offset
      def initialize(dataset)
        @dataset = dataset
        @offset = 0
        update
      end

      def update
        @total = @dataset.count
        @offset = @total if @offset > @total
      end

      def offset_to(offset)
        raise RangeError if offset > @total || offset < 0
        @offset = offset
      end

      def each
        if block_given?
          @dataset.offset(@offset).each do |data|
            yield Row.new(data, false, 0, 0)
          end
        else
          to_enum __callee__
        end
      end
    end
  end
end
