require 'test/unit'
require 'pp'

require 'miw/table_view/visual_state'

class Test_Table_VisualState < ::Test::Unit::TestCase

  setup do
    @s = MiW::TableView::VisualState.new
  end

  # test "new" do
  #   assert_equal 0, @s.count
  # end

  # test "reset_count 0" do
  #   @s.reset_count 0
  #   assert_equal 0, @s.count
  #   assert_raise RangeError do
  #     l = @s.lookup 0
  #   end
  # end

  # test "reset_count 1" do
  #   @s.reset_count 1
  #   assert_equal 1, @s.count
  #   l = @s.lookup 0
  #   subtree = l[1]
  #   exp = [[:closed, subtree.__id__, 0]]
  #   assert_equal exp, @s.debug_dump
  # end

  # test "lookup 1 for count 1" do
  #   @s.reset_count 1
  #   assert_raise RangeError do
  #     l = @s.lookup 1
  #   end
  # end

  # test "reset_count 2" do
  #   @s.reset_count 2
  #   assert_equal 2, @s.count
  #   l = @s.lookup 1
  #   subtree = l[1]
  #   exp = [
  #     [:closed, subtree.__id__, 0],
  #     [:closed, subtree.__id__, 1]
  #   ]
  #   assert_equal exp, @s.debug_dump
  # end

  # test "open #0 of 1" do
  #   @s.reset_count 1
  #   @s.open 0
  #   l = @s.lookup 0
  #   subtree = l[1]
  #   exp = [
  #     [:opened, subtree.__id__, 0]
  #   ]
  #   assert_equal exp, @s.debug_dump
  # end

  # test "open #0 of 1, reset_count 2" do
  #   @s.reset_count 1
  #   child_subtree = @s.open 0
  #   root_subtree = @s.lookup(0)[1]
  #   assert_equal root_subtree.child_at(0), child_subtree
  #   child_subtree.reset_count 2
  #   exp = [
  #     [:opened, root_subtree.__id__,  0],
  #     [:closed, child_subtree.__id__, 0],
  #     [:closed, child_subtree.__id__, 1]
  #   ]
  #   assert_equal 3,   @s.count
  #   assert_equal exp, @s.debug_dump(0)

  #   exp = [
  #     [:closed, child_subtree.__id__, 0],
  #     [:closed, child_subtree.__id__, 1]
  #   ]
  #   assert_equal exp, @s.debug_dump(1)

  #   exp = [
  #     [:closed, child_subtree.__id__, 1]
  #   ]
  #   assert_equal exp, @s.debug_dump(2)
  # end

  # test "open #0, #2 of 3, reset_count 2" do
  #   @s.reset_count 3
  #   child_subtree0 = @s.open 0
  #   child_subtree2 = @s.open 2
  #   root_subtree = @s.lookup(0)[1]
  #   assert_equal root_subtree.child_at(0), child_subtree0
  #   assert_equal root_subtree.child_at(2), child_subtree2

  #   child_subtree0.reset_count 2
  #   exp = [
  #     [:opened, root_subtree.__id__,  0],
  #     [:closed, child_subtree0.__id__, 0],
  #     [:closed, child_subtree0.__id__, 1],
  #     [:closed, root_subtree.__id__,  1],
  #     [:opened, root_subtree.__id__,  2]
  #   ]
  #   assert_equal 5,   @s.count
  #   assert_equal exp, @s.debug_dump(0)

  #   child_subtree2.reset_count 2
  #   exp = [
  #     [:opened, root_subtree.__id__,  0],
  #     [:closed, child_subtree0.__id__, 0],
  #     [:closed, child_subtree0.__id__, 1],
  #     [:closed, root_subtree.__id__,  1],
  #     [:opened, root_subtree.__id__,  2],
  #     [:closed, child_subtree2.__id__, 0],
  #     [:closed, child_subtree2.__id__, 1]
  #   ]
  #   assert_equal exp.size, @s.count
  #   assert_equal exp, @s.debug_dump(0)

  #   assert_equal exp[1, exp.size - 1], @s.debug_dump(1)
  # end

  test "open (#1, 3), (#3, 3) of 5, close #3" do
    @s.reset_count 5
    child_subtree1 = @s.open 1
    child_subtree1.reset_count 3
    child_subtree2 = @s.open 3
    child_subtree2.reset_count 3

    root_subtree = @s.lookup(0)[1]

    exp = [
      [:closed, root_subtree.__id__, 0],
      [:opened, root_subtree.__id__, 1],
      [:closed, child_subtree1.__id__, 0],
      [:opened, child_subtree1.__id__, 1],
      [:closed, child_subtree2.__id__, 0],
      [:closed, child_subtree2.__id__, 1],
      [:closed, child_subtree2.__id__, 2],
      [:closed, child_subtree1.__id__, 2],
      [:closed, root_subtree.__id__, 2],
      [:closed, root_subtree.__id__, 3],
      [:closed, root_subtree.__id__, 4],
    ]

    assert_equal exp, @s.debug_dump(0)

    @s.close 3
    exp = [
      [:closed, root_subtree.__id__, 0],
      [:opened, root_subtree.__id__, 1],
      [:closed, child_subtree1.__id__, 0],
      [:closed, child_subtree1.__id__, 1],
      [:closed, child_subtree1.__id__, 2],
      [:closed, root_subtree.__id__, 2],
      [:closed, root_subtree.__id__, 3],
      [:closed, root_subtree.__id__, 4],
    ]
    assert_equal exp, @s.debug_dump(0)
  end

  # test "open #0 of 1" do
  #   @s.reset_count 1
  #   @s.open 0
  #   exp = [[:opened, 0, 1, nil]]
  #   assert_equal exp, @s.debug_dump
  # end

  # test "open #0 of 2" do
  #   @s.reset_count 2
  #   @s.open 0
  #   exp = [[:opened, 0, 1, nil], [:closed, 0, 1, nil]]
  #   assert_equal exp, @s.debug_dump
  # end

  # test "open #0 of 2 then set 2 to L1" do
  #   @s.reset_count 2
  #   subtree = @s.open 0
  #   subtree.reset_count 2
  #   exp = [[:opened, 0, 1, nil], [:closed, 1, 2, nil], [:closed, 0, 1, nil]]
  #   assert_equal exp, @s.debug_dump
  # end

  # test "open #1 of 2" do
  #   @s.reset_count 2
  #   @s.open 1
  #   exp = [[:closed, 0, 1, nil], [:opened, 0, 1, nil]]
  #   assert_equal exp, @s.debug_dump
  # end

  # test "open #0 of 3" do
  #   @s.reset_count 3
  #   @s.open 0
  #   exp = [[:opened, 0, 1, nil], [:closed, 0, 2, nil]]
  #   assert_equal exp, @s.debug_dump
  # end

  # test "open #1 of 3" do
  #   @s.reset_count 3
  #   @s.open 1
  #   exp = [
  #     [:closed, 0, 1, nil],
  #     [:opened, 0, 1, nil],
  #     [:closed, 0, 1, nil]
  #   ]
  #   assert_equal exp, @s.debug_dump
  # end

  # test "open #1 of 3, set 100, open #2, open #5, lookup #1, #5, #6, #7" do
  #   @s.reset_count 3
  #   @s.open(1).reset_count 100
  #   @s.open(2)
  #   @s.open(5)
  #   exp = [
  #     [:closed, 0, 1, nil],
  #     [:opened, 0, 1, nil],
  #     [:opened, 1, 1, nil],
  #     [:closed, 1, 2, nil],
  #     [:opened, 1, 1, nil],
  #     [:closed, 1, 96, nil],
  #     [:closed, 0, 1, nil]
  #   ]
  #   assert_equal exp, @s.debug_dump
  #   assert_equal [:opened, 0, 1, nil], @s.lookup(1)
  #   assert_equal [:opened, 1, 1, nil], @s.lookup(5)
  #   assert_equal [:closed, 1, 96, nil], @s.lookup(6)
  #   assert_equal [:closed, 1, 95, nil], @s.lookup(7)
  # end

  # test "open #2 of 3" do
  #   @s.reset_count 3
  #   @s.open 2
  #   exp = [
  #     [:closed, 0, 2, nil],
  #     [:opened, 0, 1, nil]
  #   ]
  #   assert_equal exp, @s.debug_dump
  # end

  # test "close #0 of 1" do
  #   @s.reset_count 1
  #   @s.open(0).reset_count 100
  #   @s.close 0
  #   exp = [
  #     [:closed, 0, 1, nil]
  #   ]
  #   assert_equal exp, @s.debug_dump
  # end

  # test "close #0 of 2" do
  #   @s.reset_count 2
  #   @s.open(0).reset_count 100
  #   @s.close 0
  #   exp = [
  #     [:closed, 0, 2, nil]
  #   ]
  #   assert_equal exp, @s.debug_dump
  # end
end
