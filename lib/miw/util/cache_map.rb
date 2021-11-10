begin
  require 'rbtree'
rescue LoadError
end
require 'miw/util/lru'

module MiW
  module Util
    class CacheMap
      Map = Kernel.const_defined?(:RBTree) ? RBTree : Hash
      def initialize(cache = Cache.new)
        @cache = cache
        @map = Map.new
      end

      def [](key)
        raise ArgumentError, "nil cannot be used as key" if key.nil?
        result = ((id = @map[key]) && @cache[id])
        @map.delete key unless result
        result
      end

      def []=(key, data)
        raise ArgumentError, "nil cannot be used as key" if key.nil?
        (id = @map[key]) && @cache.delete(id)
        @map[key] = @cache.cache data
        data
      end
    end
  end
end
