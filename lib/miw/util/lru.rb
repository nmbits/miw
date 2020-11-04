
module MiW
  module Util
    class LRU
      DEFAULT_MAX_SIZE = 128
      def initialize(max_size = DEFAULT_MAX_SIZE)
        @max_size = max_size
        @data = Hash.new
      end

      def []=(key, object)
        @data.shift if @data.delete(key).nil? && @data.size > @max_size
        @data[key] = object
      end

      def [](key)
        (o = @data.delete(key)) && (@data[key] = o)
      end
    end

    class Cache
      def initialize(max_size = LRU::DEFAULT_MAX_SIZE)
        @lru = LRU.new(max_size)
        @key = 0
      end

      def cache(object)
        key = @key
        @lru[key] = object
        @key += 1
        key
      end

      def get(cache_key)
        @lru[cache_key]
      end
    end
  end
end
