require 'test/unit'
require 'pp'

require 'miw/layout/box'
require 'miw/rectangle'
require 'miw/size'
require 'miw/view'

class Test_Layout_Box < ::Test::Unit::TestCase
  def test_vbox_do_layout_item1_resize_both
    box = MiW::Layout::VBox.new
    items = [
      [ MiW::Rectangle.new(0, 0, 100, 100), resize: [true, true] ]
    ]
    rect = MiW::Rectangle.new 0, 0, 200, 200
    box.do_layout items, rect
    assert_equal rect.width, items[0][0].width
    assert_equal rect.height, items[0][0].height
    assert_equal rect.x, items[0][0].x
    assert_equal rect.y, items[0][0].y
  end

  def test_vbox_do_layout_item1_resize_vertical
    box = MiW::Layout::VBox.new
    item = MiW::Rectangle.new 0, 0, 100, 100
    items = [
      [ item, resize: [false, true] ]
    ]
    rect = MiW::Rectangle.new 0, 0, 200, 200
    box.do_layout items, rect
    assert_equal 50, items[0][0].x
    assert_equal 0, items[0][0].y
    assert_equal 100, items[0][0].width
    assert_equal 200, items[0][0].height
  end

  # item:   1
  # resize: V
  # align:  [:top, :center]
  def test_vbox_do_layout_item1_resize_vertical_top
    box = MiW::Layout::VBox.new
    item = MiW::Rectangle.new 0, 0, 100, 100
    items = [
      [ item, resize: [false, true], align: [:top, :center] ]
    ]
    rect = MiW::Rectangle.new 0, 0, 200, 200
    box.do_layout items, rect
    assert_equal 0, items[0][0].x
    assert_equal 0, items[0][0].y
    assert_equal 100, items[0][0].width
    assert_equal 200, items[0][0].height
  end

  def test_vbox_do_layout_item1_resize_vertical_top
    box = MiW::Layout::VBox.new
    item = MiW::Rectangle.new 0, 0, 100, 100
    items = [
      [ item, resize: [false, true], align: [:top, :center] ]
    ]
    rect = MiW::Rectangle.new 0, 0, 200, 200
    box.do_layout items, rect
    assert_equal 0, items[0][0].x
    assert_equal 0, items[0][0].y
    assert_equal 100, items[0][0].width
    assert_equal 200, items[0][0].height
  end

  def test_vbox_do_layout_item2_resize_both
    box = MiW::Layout::VBox.new
    items = [
      [ MiW::Rectangle.new(0, 0, 100, 100), resize: [true, true] ],
      [ MiW::Rectangle.new(0, 0, 100, 100), resize: [true, true] ]
    ]
    exp = [
      [ 0, 0, 200, 100 ],
      [ 0, 100, 200, 100 ]
    ]
    rect = MiW::Rectangle.new 0, 0, 200, 200
    box.do_layout items, rect
    items.each_with_index do |item, i|
      assert_equal exp[i][0], item[0].x
      assert_equal exp[i][1], item[0].y
      assert_equal exp[i][2], item[0].width
      assert_equal exp[i][3], item[0].height
    end
  end
end
