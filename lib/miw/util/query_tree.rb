require 'bundler/setup'
require 'miw/util/lru'
require 'miw/util/sorted_map'

module MiW
  module Util
    module QueryTree
      class Node
        PAGE_SIZE = 128
        def initialize(parent_node, parent_id)
          @parent_node = parent_node
          @parent_id = parent_id
          @children = SortedMap.new
          @cache_keys = SortedMap.new
          @open = false
        end
        attr_reader :parent_node, :parent_id

        def level
          parent_node.level + 1
        end

        def root
          @parent_node.root
        end

        def root?
          false
        end

        def query
          q = root.dataset.where(root.parent_field => @parent_id)
          # pp [:node_query, q]
          q
        end

        def count
          query.count
        end

        def open?
          @open
        end

        def set_open(v = true)
          @open = v
        end

        def each_partition
          if block_given?
            current = 0
            rest = count
            @children.each do |offset, c|
              size = offset - current + 1
              # pp [level, :each_partition, :children, offset, size, c.parent_id]
              yield current, size, c
              rest -= size
              current = offset + 1
            end
            # pp [level, :each_partition, :rest, current, rest]
            yield current, rest, nil if rest > 0
            self
          else
            self.to_enum __callee__
          end
        end

        def find_deep(index)
          rest = index
          node = nil
          each_partition do |start, size, c|
            if rest < size
              node = self
              rest += start
              break
            end
            rest -= size
            if c && c.open?
              node, rest = c.find_deep(rest)
              break if node
            end
          end
          return node, rest
        end

        def branch(index)
          item = item_at(index)
          id = item[root.id_field]
          # pp [level, :branch, index, id]
          node = Node.new self, id
          node.set_open true
          add_child index, node
        end

        def item_at(idx)
          return nil if idx >= count
          page   = idx / PAGE_SIZE
          offset = idx % PAGE_SIZE
          page_data(page)[offset]
        end

        def each(index = 0, &br)
          if block_given?
            skip = index
            each_partition do |start, size, c|
              # pp [:each, start, size, skip]
              if skip < size
                (size - skip).times { |i| yield item_at(start + skip + i) }
                skip = 0
              else
                skip -= size
              end
              if c && c.open?
                skip = c.each(skip, &br)
              end
            end
            skip
          else
            self.to_enum __callee__, idx
          end
        end

        private

        def page_data(page)
          cache_key = @cache_keys[page]
          data = cache_key ? root.cache.get(cache_key) : nil
          unless data
            q = query.offset(page * PAGE_SIZE).limit(PAGE_SIZE)
            # pp [:page_data, q]
            data = q.all
            @cache_keys[page] = root.cache.cache(data)
          end
          data
        end

        def add_child(index, node)
          @children[index] = node
        end
      end

      class Root < Node
        def initialize(dataset, id = nil, id_field: :id, parent_field: :parent, order: :id)
          @dataset = dataset
          @id = id
          @id_field = id_field
          @parent_field = parent_field
          @order = order
          @cache = Cache.new
          if @id.nil?
            @pseudo_item = {}
          end
          super nil, nil
        end
        attr_reader :dataset, :id_field, :parent_field, :order, :cache

        def query
          q = @dataset.where(@id_field => @id)
          # pp [:root_query, q]
          q
        end

        def pseudo_item=(item)
          @pseudo_item = item
        end

        def count
          1
        end

        def item_at(i)
          raise RangeError if i != 0
          @pseudo_item || query.first
        end

        def level
          0
        end

        def root
          self
        end

        def root?
          true
        end

        def open(offset)
          node, i = find_deep(offset)
          node.branch i if node
        end
      end
    end
  end
end

if __FILE__ == $0
  require 'sequel'

  DB = Sequel.sqlite

  DB.create_table :items do
    primary_key :id
    String :name, unique: true, null: false
    foreign_key :parent, :items
  end

  dataset = DB[:items]

  root_id = dataset.insert name: "root"

  4.times do |i|
    id_l1 = dataset.insert name: "item_#{i}", parent: nil
    4.times do |j|
      id_l2 = dataset.insert name: "item_#{i}_#{j}", parent: id_l1
      4.times do |k|
        id_l3 = dataset.insert name: "item_#{i}_#{j}_#{k}", parent: id_l2
      end
    end
  end

  r = MiW::Util::QueryTree::Root.new dataset
  r.pseudo_item = { name: "pseudo_root" }

  r.open(0)
  r.open(4)
  r.open(9)
  r.open(11)
  r.each do |item|
    pp item
  end
end
