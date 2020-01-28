
require 'miw'
require 'miw/view'
require 'miw/layout/box'
require 'miw/point'
require 'miw/util/axis'

module MiW
  class SplitView < View
    class Resizer
      def initialize(split_view, index)
        @view = split_view
        @index = index
        @orientation = @view.orientation
        @axis = Util::Axis.new @orientation
        @co = 0   # carry over
      end

      def setup(delta)
        enum_left = Enumerator.new do |y|
          (0...@index).reverse_each do |i|
            y << @view.child_at(i)
          end
        end
        enum_right = Enumerator.new do |y|
          (@index...@view.count_children).each do |i|
            y << @view.child_at(i)
          end
        end
        delta < 0 ? [enum_right, enum_left] : [enum_left, enum_right]
      end

      def do_resize(delta)
        enum_bigger, enum_smaller = setup delta
        d = @co + delta
        if @co != 0
          if (d < 0) == (@co < 0)
            @co = d
            return
          end
          @co = 0
        end
        bigger_px = enum_bigger.inject(0) do |memo, v|
          memo + @axis.max_size(v) - @axis.size(v)
        end
        smaller_px = enum_smaller.inject(0) do |memo, v|
          memo + @axis.size(v) - @axis.min_size(v)
        end
        d_abs = [bigger_px, smaller_px, d.abs].min
        if d_abs < d.abs
          @co = (delta.abs - d_abs) * (delta <=> 0)
        end
        tmp = d_abs
        enum_bigger.each do |v|
          sz = @axis.max_size(v) - @axis.size(v)
          ds = [sz, tmp].min
          @axis.resize_by(v, ds)
          tmp -= ds
          break if tmp == 0
        end
        tmp = d_abs
        enum_smaller.each do |v|
          sz = @axis.size(v) - @axis.min_size(v)
          ds = [sz, tmp].min
          @axis.resize_by(v, -ds)
          tmp -= ds
          break if tmp == 0
        end
      end
    end

    GAP_WIDTH = 10 # pseudo

    def initialize(name, orientation: :horizontal, layout: nil, **opts)
      case orientation
      when :vertical
        layout = Layout::VBox.new
      when :horizontal
        layout = Layout::HBox.new
      else
        raise ArgumentError, "orientation should be :vertical or :horizontal"
      end
      layout.spacing = GAP_WIDTH
      super name, layout: layout, **opts
      @orientation = orientation
    end
    attr_reader :orientation

    def mouse_down(x, y, button, state, count)
      if count_children > 1 && button == 1
        index = find_index x, y
        if index && index > 0
          @resizer = Resizer.new self, index
          @mouse_pos = Point.new x, y
          window.set_tracking self
          window.grab_pointer
        end
      end
    end

    def find_index(x, y)
      _, index = each_visible_child.each_with_index.find do |c, i|
        f = c.frame
        @orientation == :vertical ? (y < f.top) : (x < f.left)
      end
      index
    end

    def get_delta(x, y)
      answer = @orientation == :vertical ? y - @mouse_pos.y : x - @mouse_pos.x
      @mouse_pos.x = x
      @mouse_pos.y = y
      answer
    end

    def mouse_moved(x, y, transit, state)
      if @resizer
        @resizer.do_resize get_delta(x, y)
        do_layout
      end
    end

    def mouse_up(x, y, button, state)
      if button == 1
        window.set_tracking nil
        window.ungrab_pointer
        @resizer = nil
        invalidate
      end
    end

    def draw(rect)
      cs = MiW.colors
      cairo.rectangle rect.x, rect.y, rect.width, rect.height
      cairo.set_source_color cs[:control_background]
      cairo.fill
      cairo.save do
        cairo.rectangle rect.x, rect.y, rect.width, rect.height
        cairo.clip
        draw_knob
      end
    end

    def draw_knob
      cs = MiW.colors
      cairo.set_source_color cs[:control_forground]
      each_gap do |rect|
        if @orientation == :vertical
          dx = GAP_WIDTH * 0.7
          dy = 0
        else
          dx = 0
          dy = GAP_WIDTH * 0.7
        end
        cx = rect.x + rect.width / 2
        cy = rect.y + rect.height / 2
        3.times do |i|
          cairo.circle cx + (i - 1) * dx, cy + (i - 1) * dy, GAP_WIDTH * 0.1
          cairo.fill
        end
      end
    end
    private :draw_knob

    def each_gap
      if block_given?
        each_visible_child.each_cons(2) do |a, b|
          if @orientation == :vertical
            y = a.frame.bottom
            h = b.frame.top - y
            rect = Rectangle.new 0, y, width, h
          else
            x = a.frame.right
            w = b.frame.left - x
            rect = Rectangle.new x, 0, w, height
          end
          yield rect
        end
      else
        self.to_enum __callee__
      end
    end
    private :each_gap
  end
end
