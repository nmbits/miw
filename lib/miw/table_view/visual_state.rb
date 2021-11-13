module MiW
  class TableView
    class VisualState
      class Subtree
        def initialize(parent)
          @parent = parent
          @data = nil
          @children = []
          @count = 0
          @count_children = 0
        end
        attr_reader :parent, :count_children, :count
        attr_accessor :data

        def lookup(index)
          sindex = 0
          result = nil
          @children.each_with_index do |ent, i|
            if Integer === ent
              if index < ent
                result = [self, i, index, index + sindex]
                break
              end
              index -= ent
              sindex += ent
            else
              if index == 0
                result = [self, i, 0, sindex]
                break
              end
              index -= 1
              sindex += 1
              c = ent.count
              if index < c
                result = ent.lookup(index)
                break
              end
              index -= c
            end
          end
          result
        end

        def child_at(i)
          @children[i]
        end

        def each_child(start = 0)
          return self.to_enum __callee__, start unless block_given?
          i = start
          while i < @children.size
            yield @children[i]
            i += 1
          end
        end

        def open(child, rel)
          answer = nil
          ent = @children[child]
          raise RangeError unless ent
          if Integer === ent
            raise RangeError if ent <= rel
            latter = ent - rel - 1
            answer = Subtree.new(self)
            if rel > 0
              @children[child] = rel
              child += 1
              @children.insert child, answer
            else
              @children[child] = answer
            end
            @children.insert child + 1, latter if latter > 0
          end
          answer
        end

        def close(child)
          answer = false
          ent = @children[child]
          raise RangeError unless ent
          if Subtree === ent
            add_count(0 - ent.count)
            @children[child] = 1
            child -= 1 if child > 0 && Integer === @children[child - 1]
            # pp [:children0, @children, child]
            loop do
              break unless Integer === @children[child + 1]
              @children[child] += @children[child + 1]
              @children.delete_at(child + 1)
              # pp [:children1, @children]
            end
            # pp [:children2, @children]
            answer = true
          end
          answer
        end

        def reset_count(count)
          delta = count - @count
          @count = count
          @count_children = count
          if count > 0
            @children = [count]
          else
            @children = []
          end
          @parent&.add_count delta
        end

        def add_count(count)
          @count += count
          @parent&.add_count count
        end

        def level
          unless @level
            @level = @parent ? @parent.level + 1 : 0
          end
          @level
        end
      end # Subtree

      def initialize
        @root = Subtree.new nil
      end

      def count
        @root.count
      end

      def reset_count(count)
        @root.reset_count count
      end

      def open(index)
        subtree, child, cindex, sindex = @root.lookup index
        raise RangeError unless subtree
        subtree.open child, cindex
      end

      def close(index)
        subtree, child, cindex, sindex = @root.lookup index
        raise RangeError unless subtree
        subtree.close child
      end

      def each_recursive(subtree, child, cindex, sindex, &block)
        subtree.each_child(child) do |ent|
          if Integer === ent
            (ent - cindex).times do
              yield [:closed, subtree, sindex]
              sindex += 1
            end
          else
            yield [:opened, subtree, sindex]
            each_recursive ent, 0, 0, 0, &block
            sindex += 1
          end
          cindex = 0
        end
      end
      private :each_recursive

      def each(start = 0, &block)
        if block_given?
          while start < count
            subtree, child, cindex, sindex = @root.lookup start
            pp [:lookup, start, subtree.__id__, child, cindex, sindex]
            raise RangeError unless subtree
            each_recursive subtree, child, cindex, sindex, &block
            start += subtree.count - sindex
          end
        else
          self.to_enum __callee__, start
        end
      end

      def lookup(index)
        subtree, child, cindex, sindex = @root.lookup index
        raise RangeError unless subtree
        ent = subtree.child_at(child)
        if Integer === ent
          [:closed, subtree, subtree.level, child, cindex, ent - cindex, sindex]
        else
          [:opened, subtree, subtree.level, child, cindex, 1           , sindex]
        end
      end

      def set_root_data(data)
        @root.data = data
      end

      def debug_dump(start = 0)
        result = []
        each(start) do |e|
          result << [e[0], e[1].__id__, e[2]]
        end
        result
      end
    end
  end # VisualState
end
