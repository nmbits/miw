# coding: utf-8
require 'test/unit'
require 'pp'

require 'miw/model/text_buffer'

class Test_TextBuffer < ::Test::Unit::TestCase

  MiW::Model::TextBuffer.class_eval do |c|
    public :realloc, :memmove, :memchr, :memrchr,
           :move_gap, :extend_gap, :shrink_gap,
           :index, :rindex
    attr_reader :gap_begin, :gap_length, :memory
    attr_accessor :eol
  end

  test "empty buffer" do
    target = MiW::Model::TextBuffer.new
    assert_equal 0, target.length
  end

  test "initialize with invalid eol" do
    assert_raise ArgumentError do
      target = MiW::Model::TextBuffer.new nil, 10
    end
  end

  test "insert string into empty buffer" do
    target = MiW::Model::TextBuffer.new
    target.insert 0, "abcd"
    assert_equal "abcd", target[0, 4]
    target.delete 1, 2
    assert_equal "ad", target[0, 2]
  end

  test "memmove" do
    s = "abcdefg"
    target = MiW::Model::TextBuffer.new
    target.insert 0, s
    target.realloc 1000
    target.memmove(500, 0, s.bytesize)
    assert_equal s, target[500, s.bytesize]
  end

  test "memchr" do
    #    012345678
    s = "abcdQeQfg"
    target = MiW::Model::TextBuffer.new
    target.insert 0, s
    assert_equal 4, target.memchr(0, "Q".getbyte(0), s.bytesize)
    assert_equal 6, target.memchr(5, "Q".getbyte(0), s.bytesize - 6)
    assert_nil target.memchr(0, "A".getbyte(0), s.bytesize)
  end

  test "memrchr" do
    #    012345678
    s = "abcdQeQfg"
    target = MiW::Model::TextBuffer.new
    target.insert 0, s
    assert_equal 6, target.memrchr(0, "Q".getbyte(0), s.bytesize)
    assert_equal 4, target.memrchr(0, "Q".getbyte(0), 6)
    assert_equal nil, target.memrchr(0, "A".getbyte(0), s.bytesize)
  end

  test "move_gap" do
    s = "0123456789abcdef"
    target = MiW::Model::TextBuffer.new
    target.insert 0, s

    target.move_gap 3
    assert_equal s, target[0, target.length]

    target.move_gap 7
    assert_equal s, target[0, target.length]

    target.move_gap 0
    assert_equal s, target[0, target.length]

    target.move_gap target.length
    assert_equal s, target[0, target.length]
  end

  test "extend_gap" do
    s = "0123456789abcdef"
    target = MiW::Model::TextBuffer.new s
    target.move_gap 3
    target.extend_gap 1000
    assert_equal 1000 + 400, target.gap_length
    assert_equal 1000 + 400 + s.bytesize, target.capacity
    assert_equal s, target[0, target.length]
  end

  test "shrink_gap" do
    s = "0123456789abcdef"
    target = MiW::Model::TextBuffer.new s
    target.move_gap 3
    target.extend_gap 1000
    target.shrink_gap
    assert_equal 400, target.gap_length
    assert_equal 400 + s.bytesize, target.capacity
    assert_equal s, target[0, target.length]
  end

  test "index" do
    s = "0123456789abcdef"
    target = MiW::Model::TextBuffer.new s
    target.move_gap 3
    assert_equal 2, target.index("2".getbyte(0), 0)
    assert_nil target.index("A".getbyte(0), 0)
    assert_equal 4, target.index("4".getbyte(0), 0)
  end

  test "rindex" do
    s = "0123456789abcdef"
    target = MiW::Model::TextBuffer.new s
    target.move_gap 3
    assert_equal 2, target.rindex("2".getbyte(0), target.length)
    assert_equal 3, target.rindex("3".getbyte(0), target.length)
    assert_nil target.rindex("A".getbyte(0), target.length)
    assert_equal 4, target.rindex("4".getbyte(0), target.length)
    assert_nil target.rindex("4".getbyte(0), 4)
    assert_equal 4, target.rindex("4".getbyte(0), 5)
  end

  test "beginning_of_line unix" do
    s = "\r\n23456789abcd\r\n0123456789abcd\r\n0123"
    target = MiW::Model::TextBuffer.new s
    target.move_gap 3
    assert_equal 0, target.beginning_of_line(0)
    assert_equal 2, target.beginning_of_line(15)
    assert_equal 16, target.beginning_of_line(16)
    assert_equal 16, target.beginning_of_line(17)
    assert_equal 32, target.beginning_of_line(target.length)
  end

  test "beginning_of_line mac" do
    s = "\r\n23456789abcd\r\n0123456789abcd\r\n0123"
    target = MiW::Model::TextBuffer.new s, :mac
    target.move_gap 3
    assert_equal 0, target.beginning_of_line(0)
    assert_equal 1, target.beginning_of_line(14)
    assert_equal 15, target.beginning_of_line(16)
    assert_equal 15, target.beginning_of_line(17)
    assert_equal 31, target.beginning_of_line(target.length)
  end

  test "beginning_of_line dos" do
    s = "\r\n23456789abcd\r\n0123456789abcd\r\n0123"
    target = MiW::Model::TextBuffer.new s, :dos
    target.move_gap 3
    assert_equal 0, target.beginning_of_line(0)
    assert_equal 2, target.beginning_of_line(15)
    assert_equal 16, target.beginning_of_line(16)
    assert_equal 16, target.beginning_of_line(17)
    assert_equal 32, target.beginning_of_line(target.length)
  end

  test "end of line unix" do
    s = "\r\n23456789abcd\r\n0123456789abcd\r\n0123"
    target = MiW::Model::TextBuffer.new s, :unix
    target.move_gap 3
    assert_equal 1, target.end_of_line(0)
    assert_equal 1, target.end_of_line(1)
    assert_equal 15, target.end_of_line(2)
    assert_equal 15, target.end_of_line(3)
    target.move_gap 15
    assert_equal 15, target.end_of_line(15)
    assert_equal 36, target.end_of_line(35)
    assert_equal 36, target.end_of_line(36)
    assert_raise RangeError do target.end_of_line(37) end
  end

  test "end of line mac" do
    s = "\r\n23456789abcd\r\n0123456789abcd\r\n0123"
    target = MiW::Model::TextBuffer.new s, :mac
    target.move_gap 3
    assert_equal 0, target.end_of_line(0)
    assert_equal 14, target.end_of_line(1)
    assert_equal 14, target.end_of_line(2)
    assert_equal 14, target.end_of_line(3)
    target.move_gap 14
    assert_equal 30, target.end_of_line(15)
    assert_equal 36, target.end_of_line(35)
    assert_equal 36, target.end_of_line(36)
    assert_raise RangeError do target.end_of_line(37) end
  end

  test "end of line dos" do
    s = "\r\n23456789abcd\r\n0123456789abcd\r\n0123"
    target = MiW::Model::TextBuffer.new s, :dos
    target.move_gap 3
    assert_equal 0, target.end_of_line(0)
    assert_equal 0, target.end_of_line(1)
    assert_equal 14, target.end_of_line(2)
    assert_equal 14, target.end_of_line(3)
    target.move_gap 14
    assert_equal 14, target.end_of_line(15)
    assert_equal 36, target.end_of_line(35)
    assert_equal 36, target.end_of_line(36)
    assert_raise RangeError do target.end_of_line(37) end
  end

  test "adjust forward" do
    s = "あいう9abcd\r\n"
    target = MiW::Model::TextBuffer.new s, :dos
    target.move_gap 3
    assert_equal 0, target.adjust(0, :forward)
    assert_equal 3, target.adjust(1, :forward)
    assert_equal 3, target.adjust(2, :forward)
    assert_equal 9, target.adjust(9, :forward)
    assert_equal 14, target.adjust(14, :forward)
    assert_equal 16, target.adjust(15, :forward)
    assert_equal 16, target.adjust(16, :forward)
  end

  test "adjust backward" do
    s = "あいう9abcd\r\n"
    target = MiW::Model::TextBuffer.new s, :dos
    target.move_gap 3
    assert_equal 0, target.adjust(0, :backward)
    assert_equal 0, target.adjust(1, :backward)
    assert_equal 9, target.adjust(9, :backward)
    assert_equal 14, target.adjust(14, :backward)
    assert_equal 14, target.adjust(15, :backward)
    assert_equal 16, target.adjust(16, :backward)
  end

  test "count_eols unix" do
    s = "\r\n23456789abcd\r\n0123456789abcd\r\n0123"
    target = MiW::Model::TextBuffer.new s, :unix
    target.move_gap 3
    assert_equal 3, target.count_eols(0)
    assert_equal 1, target.count_eols(1, 1)
  end

  test "count_eols dos" do
    s = "\r\n23456789abcd\r\n0123456789abcd\r\n0123"
    target = MiW::Model::TextBuffer.new s, :dos
    target.move_gap 3
    assert_equal 3, target.count_eols(0)
    assert_equal 0, target.count_eols(1, 1)
    assert_equal 1, target.count_eols(0, 2)
    assert_equal 0, target.count_eols(0, 1)
  end

  test "line_to_pos" do
    s = "\r\n23456789abcd\r\n0123456789abcd\r\n0123456789abcd\r\n"
    target = MiW::Model::TextBuffer.new s, :unix
    target.move_gap 3
    assert_equal 0, target.line_to_pos(0)
    assert_equal 16, target.line_to_pos(2)
    assert_equal 2, target.line_to_pos(1)
    assert_equal 32, target.line_to_pos(3)
    assert_equal 48, target.line_to_pos(4)
    assert_equal nil, target.line_to_pos(5)
    assert_equal 32, target.line_to_pos(3)
  end

  test "line_to_pos dos" do
    s = "\r\n23456789abcde\n0123456789abcd\r\n0123456789abcd\r\n"
    target = MiW::Model::TextBuffer.new s, :dos
    target.move_gap 3
    assert_equal 0, target.line_to_pos(0)
    assert_equal 32, target.line_to_pos(2)
    assert_equal 2, target.line_to_pos(1)
    assert_equal 48, target.line_to_pos(3)
    assert_equal nil, target.line_to_pos(4)
  end

  test "pos_to_line" do
    # L  0   1               2                 3                 4                5    6
    s = "\r\n23456789abcd\r\n0123456789abcd\r\n0123456789abcd\r\n0123456789abcde\n012\n5"
    #    0                   1                 2                 3                4
    target = MiW::Model::TextBuffer.new s, :unix
    target.move_gap 3
    target.line_to_pos(4)  # 48
    assert_equal 0, target.pos_to_line(0)
    assert_equal 2, target.pos_to_line(24)
    assert_equal 2, target.pos_to_line(25)
    assert_equal 3, target.pos_to_line(32)
    assert_equal 4, target.pos_to_line(49)
    assert_equal 5, target.pos_to_line(65)
    assert_equal 6, target.pos_to_line(target.length)
  end
end
