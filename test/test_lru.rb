require 'test/unit'
require 'pp'

require 'miw/util/lru'

class Test_LRU < ::Test::Unit::TestCase
  test "add 1 item" do
    data = Object.new
    lru = MiW::Util::LRU.new
    lru[1] = data
    assert_equal data, lru[1]
  end

  test "add 2 items for 1 cache slot" do
    data1 = Object.new
    data2 = Object.new
    lru = MiW::Util::LRU.new 1
    lru[1] = data1
    lru[2] = data2
    # pp lru.instance_variable_get(:@data)
    assert_equal data2, lru[2]
    assert_nil lru[1]
  end

  test "add nil" do
    data1 = Object.new
    data2 = Object.new
    lru = MiW::Util::LRU.new 2
    lru[1] = data1
    lru[2] = data2
    lru[3] = nil
    assert_equal data1, lru[1]
    assert_equal data2, lru[2]
    assert_nil lru[3]
  end

  test "over write" do
    data1 = Object.new
    data2 = Object.new
    data3 = Object.new
    lru = MiW::Util::LRU.new 2
    lru[1] = data1
    lru[2] = data2
    lru[1] = data3
    assert_equal data3, lru[1]
    assert_equal data2, lru[2]
  end
end

class Test_Cache < ::Test::Unit::TestCase
  test "cache 1 item" do
    data1 = Object.new
    cache = MiW::Util::Cache.new 1
    key = cache.cache data1
    assert_equal data1, cache[key]
  end

  test "cache 2 items for 1 cache slot" do
    data1 = Object.new
    data2 = Object.new
    cache = MiW::Util::Cache.new 1
    key1 = cache.cache data1
    key2 = cache.cache data2
    assert_equal data2, cache[key2]
    assert_nil cache[key1]
  end

  test "cache nil" do
    data1 = Object.new
    data2 = Object.new
    cache = MiW::Util::Cache.new 2
    key1 = cache.cache data1
    key2 = cache.cache data2
    key3 = cache.cache nil
    assert_equal data2, cache[key2]
    assert_equal data1, cache[key1]
    assert_nil cache[key3]
  end
end
