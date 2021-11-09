
module MiW
  module Util
    class LRU
      DEFAULT_MAX_SIZE = 128
      def initialize(max_size = DEFAULT_MAX_SIZE)
        raise ArgumentError, "max_size should be greater than 0" unless max_size > 0
        @max_size = max_size
        @data = Hash.new
      end

      def []=(key, object)
        if object.nil?
          delete key
        else
          @data.shift if @data.delete(key).nil? && @data.size >= @max_size
          @data[key] = object
        end
        object
      end

      def [](key)
        (o = @data.delete(key)) && (@data[key] = o)
      end

      def soft_get(key)
        @data[key]
      end

      def delete(key)
        @data.delete key
      end
    end

    class Cache
      def initialize(max_size = LRU::DEFAULT_MAX_SIZE)
        @lru = LRU.new(max_size)
        @key = 0
      end

      def cache(object)
        key = get_key
        @lru[key] = object
        key
      end

      def [](cache_key)
        @lru[cache_key]
      end

      def delete(cache_key)
        @lru.delete(cache_key)
      end

      private

      def get_key
        key = @key
        @key += 1
        key
      end
    end
  end
end
