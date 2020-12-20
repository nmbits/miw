require 'miw/table_view'

module MiW
  class TableView::Sequel
    def initialize(dataset, order = :id)
      @dataset = dataset
      @order = order
    end

    def count
      @dataset.count
    end

    def order
      @order
    end

    def order=(columns)
      @order = columns
    end

    def item_at(i)
      @dataset.order(@order).offset(i).limit(1).first
    end

    def set_open(i)
    end

    def each(i = 0)
      if block_given?
        @dataset.order(@order).offset(i).each do |item|
          yield item
        end
      else
        self.to_enum __callee__, i
      end
    end
  end
end
