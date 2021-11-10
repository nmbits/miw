require 'test/unit'
require 'pp'

require 'miw/util/cache_map'

class Test_CacheMap < ::Test::Unit::TestCase
  test "add 2 items in 1 cache slot" do
    cache = MiW::Util::Cache.new(1)
    cm = MiW::Util::CacheMap.new cache
    data1 = Object.new
    data2 = Object.new
    cm[1] = data1
    cm[2] = data2
    assert_nil cm[1]
    assert_equal data2, cm[2]
  end
end
