require 'miw/table_view'

module MiW
  class TableView::SequelQuery
    def initialize(dataset, id_field = :id, parent_field = :parent, root = nil)
      @dataset = dataset
      @id_field = id_field
      @parent_field = parent_field
      @root = root
    end

    def count
      @dataset.count
    end

    def order
      if @root
        @root.order
      else
        @order ||= []
      end
    end

    def order=(columns)
      order.replace columns
    end

    def get(offset, limit)
      @dataset.offset(offset).limit(limit).all
    end

    def parent?(row)
      false
    end

    def query_for_children(row)
      root = (@root || self)
      children = @dataset.where(@parent_field, row[@id_field])
      SequelQuery.new children, @id_field, @parent_field, self
    end

    def update(row, hash)
      @dataset.where(@id_field, row[@id_field]).update(hash)
    end
  end
end
