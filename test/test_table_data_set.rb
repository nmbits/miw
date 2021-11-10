require 'test/unit'
require 'pp'

require 'miw/table_view/data_set'

class Test_Table_DataSet < ::Test::Unit::TestCase

  def make_data_0(start, limit)
    limit.times.map do |i|
      { id: start + i, value: limit - i }
    end
  end

  def make_tree_data(limit1, limit2)
    id1 = 1
    answer = []
    limit1.times.map do |i|
      answer << { id: id1, value: limit1 - i }
      limit2.times.map do |j|
        answer << { id: id1 * limit2 + j, value: limit2 - j, parent: id1 }
      end
      id1 += 1
    end
    answer
  end

  test "get" do
    ds = MiW::TableView::DataSet.new
    data0 = make_data_0 0, 100
    data0.each{|item| ds.insert item}
    sorted = data0.sort_by{|item| item[:value]}
    assert_equal [], ds.get(0, 0, {order: :value})
    assert_equal sorted[0, 10], ds.get(0, 10, {order: :value})
    assert_equal data0[5, 10], ds.get(5, 10)
    assert_equal sorted[1, 1], ds.get(1, 1, {order: :value})
  end

  test "get tree" do
    ds = MiW::TableView::DataSet.new
    data0 = make_tree_data 5, 7
    data0.each{|item| ds.insert item}
    sorted = data0.sort_by{|item| item[:value]}
    children1 = sorted.select{|item| item[:parent] == 5}
    assert_equal children1, ds.get(0, 7, parent: 5, order: :value)
    assert_equal children1, ds.get(0, 7, parent: 5).sort_by{|item| item[:value]}
  end
end
