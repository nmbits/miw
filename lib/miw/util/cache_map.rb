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
        (id = @map[key]) && @cache[id]
      end

      def []=(key, data)
        (id = @map[key]) && @cache.delete(id)
        @map[key] = @cache.cache data
        data
      end
    end
  end
end
