
module MiW
  module Util
    class SortedMap
      def initialize
        @container = []
      end

      def each
        if block_given?
          @container.each { |e| yield *e }
        else
          self.to_enum __callee__
        end
      end

      def [](key)
        ent = @container.bsearch { |e| e.first >= key }
        ent&.first == key ? ent.last : nil
      end

      def []=(key, obj)
        index = @container.bsearch_index { |e| e.first >= key }
        if index
          ent = @container[index]
          if ent.first == key
            ent[1] = obj
          else
            @container.insert index, [key, obj]
          end
        else
          @container.push [key, obj]
        end
      end

      def delete(key)
        index = @container.bsearch_index { |e| e.first >= key }
        if index
          ent = @container[index]
          if ent.first == key
            @container.delete_at index
            return ent.last
          end
        end
        return nil
      end

      def clear
        @container.clear
      end
    end
  end
end

if __FILE__ == $0
  sorted_map = MiW::Util::SortedMap.new

  sorted_map[30] = "A"
  sorted_map[20] = "B"
  sorted_map[10] = "C"

  sorted_map.each do |k, v|
    pp [k, v]
  end

  pp "----"

  [10, 20, 30, 40].each do |i|
    pp [i, sorted_map[i]]
  end

  sorted_map[40] = "D"
  sorted_map[40] = "E"
  
  pp "----"

  [10, 20, 30, 40].each do |i|
    pp [i, sorted_map[i]]
  end

  sorted_map.delete 20
  sorted_map.delete 9
  sorted_map.delete 11
  
  pp "----"

  sorted_map.each do |k, v|
    pp [k, v]
  end


  sorted_map.clear

  T = 100000
  T.times do |i|
    sorted_map[rand(T)] = i
  end

  pp "----"

  last = 0
  sorted_map.each do |k, v|
    if k < last
      raise "order error"
    end
    last = k
  end
end
