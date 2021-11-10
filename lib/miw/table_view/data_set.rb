module MiW
  module TableView
    class DataSet
      def initialize(id_field: :id, parent_field: :parent, tree: false)
        @storage = {}
        @id_field = id_field
        @parent_field = parent_field.to_sym
        @tree = tree
        @read_only = false
      end
      attr_reader :id_field, :parent_field

      def set_group_checker(pr = nil, &block)
        @group_proc = pr || block
      end

      def tree?
        @tree
      end

      def read_only?
        @read_only
      end

      def set_read_only(b)
        @read_only = (b ? true : false)
      end

      def insert(item)
        raise "read only" if read_only?
        id = item[@id_field]
        raise ArgumentError unless id
        if @storage.include? id
          raise ArgumentError, "id #{id} already included"
        end
        @storage[id] = item
      end

      def delete(id)
        raise "read only" if read_only?
        @sotrage.delete id
      end

      def update(item)
        raise "read only" if read_only?
        id = item[@id_field]
        raise ArgumentError, "item should have id" unless id
        raise ArgumentError, "id not found" unless @storage.include? id
        @storage[id] = item
      end

      def get(offset, limit, filter = nil)
        parent = filter && filter[:parent]
        order = filter && filter[:order]
        enum = @storage.each_value.lazy.find_all{|item| item[@parent_field] == parent}
        if order
          enum.sort_by{|a| a[order]}[offset, limit]
        else
          enum.drop(offset).take(limit).force
        end
      end

      def count(filter)
        raise ArgumentError unless filter
        parent = filter[:parent]
        @storage.each_value.count{|item| item[@parent_field] == parent}
      end

      def group?(item)
        @group_proc ? @group_proc.call(item) : false
      end
    end
  end
end
