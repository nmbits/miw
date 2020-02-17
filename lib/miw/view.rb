require 'miw'
require 'miw/rectangle'
require 'miw/point'
require 'miw/size'
require 'set'

module MiW
  class View

    attr_reader :parent, :window, :name, :layout
    attr_accessor :font, :layout_hints

    DEFAULT_SIZE = Size.new(50, 50).freeze
    ZERO_SIZE = [0, 0].freeze
    INFINITE_SIZE = [Float::INFINITY, Float::INFINITY].freeze

    def initialize(name, layout: nil, font: nil, size: nil, **opts)
      @options = opts
      @frame = MiW::Rectangle.new 0, 0, 0, 0
      @frame.resize_to size || DEFAULT_SIZE
      @name = name
      @children = []
      @visible = true
      if layout.class == Class
        @layout = layout.new
      else
        @layout = layout
      end
      @observers = Set.new
      @font = font || MiW.fonts[:document]
      @layout_hints = { min_size: ZERO_SIZE, max_size: INFINITE_SIZE }
    end

    # geometry

    def bounds
      @frame.dup.offset_to 0, 0
    end

    def frame
      @frame.dup
    end

    def x;            @frame.x            end
    def y;            @frame.y            end
    def width;        @frame.width        end
    def height;       @frame.height       end
    def size;         @frame.size         end
    def left_top;     @frame.left_top     end
    def left_bottom;  @frame.left_bottom  end
    def right_top;    @frame.right_top    end
    def right_bottom; @frame.right_bottom end

    # size

    def min_size
      Size.new *@layout_hints[:min_size]
    end

    def min_size=(sz)
      @layout_hints[:min_size] = [sz.width, sz.height].freeze
    end

    def max_size
      Size.new *@layout_hints[:max_size]
    end

    def max_size=(sz)
      @layout_hints[:max_size] = [sz.width, sz.height].freeze
    end

    # drawing
    def cairo
      @window ? @window.cairo : nil
    end

    def pango_layout
      @window ? @window.pango_layout : nil
    end

    # hooks

    def draw(rect)
    end

    def draw_after_children(rect)
    end

    def mouse_down(*a)
    end

    def mouse_up(*a)
    end

    def mouse_moved(x, y, transit, data)
    end

    def key_down(*a)
    end

    def key_up(*a)
    end

    def frame_moved(x, y)
    end

    def frame_resized(width, height)
    end

    def attached_to_window
    end

    def all_attached
    end

    def detached_from_window
    end

    def all_detached
    end

    def window_activated(active)
    end

    # layout hints
    def replace_layout_hints(hints)
      @layout_hints = @layout_hints.slice :min_size, :max_size
      @layout_hints.merge! hints
    end

    # tree

    def add_child(child, hints = {})
      if child.parent
        raise "The view is already a member of another view"
      end
      child.replace_layout_hints hints
      @children << child
      child.set_parent self
      do_layout if child.visible? && @window
    end

    def remove_child(child)
      unless child.parent == self
        raise "not a member of this view"
      end
      @children.delete(child)
      child.set_parent nil
      do_layout if child.visible? && @windos
    end

    def count_children
      @children.length
    end

    def child_at(i)
      @children[i]
    end

    def remove_self
      @parent.remove_child self if @parent
    end

    def attached?
      return (@window ? true : false)
    end

    def convert_to_parent(a1, a2 = nil)
      if a2
        [a1 + @frame.x, a2 + @frame.y]
      else
        a1.dup.offset_by @frame
      end
    end

    def convert_from_parent(a1, a2 = nil)
      if a2
        [a1 - @frame.x, a2 - @frame.y]
      else
        a1.dup.offset_by 0 - @frame.x, 0 - @frame.y
      end
    end

    def convert_to_window(a1, a2 = nil)
      view = self
      while view && !view.root?
        a1, a2 = view.convert_to_parent a1, a2
        view = view.parent
      end
      if a2
        [a1, a2]
      else
        a1
      end
    end

    def convert_from_window(a1, a2 = nil)
      view = self
      while view && !view.root?
        a1, a2 = view.convert_from_parent(a1, a2)
        view = view.parent
      end
      if a2
        [a1, a2]
      else
        a1
      end
    end

    def convert_to_screen(a1, a2 = nil)
      if window
        if a2
          window.convert_to_screen *convert_to_window(a1, a2)
        else
          pos = convert_to_window(a1)
          x, y = window.convert_to_screen pos.x, pos.y
          Point.new x, y
        end
      else
        raise "not attached"
      end
    end

    def convert_from_screen(a1, a2 = nil)
      if window
        if a2
          convert_from_window *window.convert_from_screen(a1, a2)
        else
          x, y = window.convert_from_screen(a1.x, a1.y)
          convert_from_window Point.new(x, y)
        end
      else
        raise "not attached"
      end
    end

    def invalidate(rect = self.bounds)
      ax, ay = convert_to_window rect.x, rect.y
      @window.invalidate ax, ay, rect.width, rect.height
    end

    # visibility

    def show(v = true)
      @visible = (v ? true : false)
    end

    def hide
      show false
    end

    def visible?
      @visible
    end

    def hidden?
      ! @visible
    end

    def do_layout
      @layout&.do_layout self.each_visible_child_with_hint, self.bounds
    end

    def resize_by(a1, a2 = nil)
      if a2
        resize_to(a1 + width, a2 + height)
      else
        resize_to a1.width, a1.height
      end
    end

    def resize_to(a1, a2 = nil)
      min = min_size
      if a2
        # if a1 < 0 || a2 < 0
        #   raise ArgumentError, "size should be greater than or equal to 0"
        # end
        w = [a1, 0, min.width].max
        h = [a2, 0, min.height].max
        @frame.resize_to w, h
      else
        # if a1.width < 0 || a1.height < 0
        #   raise ArgumentError, "size should be greater than or equal to 0"
        # end
        w = [a1.width, 0, min.width].max
        h = [a1.height, 0, min.height].max
        @frame.resize_to w, h
      end
      do_layout if @window
      frame_resized @frame.width, @frame.height
      @frame.size
    end

    def preferred_size
      size
    end

    def resize_to_preferred
      sz = preferred_size
      resize_to sz
    end

    def offset_by(a1, a2 = nil)
      if a2
        offset_to @frame.x + a1, @frame.y + a2
      else
        offset_to @frame.x + a1.x, @frame.y + a1.y
      end
    end

    def offset_to(a1, a2 = nil)
      if a2
        @frame.offset_to a1, a2
      else
        @frame.offset_to a1.x, a1.y
      end
      frame_moved(@frame.x, @frame.y)
    end

    def root?
      @root
    end

    def root=(bool)
      @root = bool
    end

    def each_child
      if block_given?
        @children.each { |c| yield c }
      else
        self.to_enum __callee__
      end
    end

    def each_visible_child
      if block_given?
        @children.each { |c| yield c if c.visible? }
      else
        self.to_enum __callee__
      end
    end

    def each_visible_child_with_hint
      if block_given?
        @children.each { |c| yield c, c.layout_hints if c.visible? }
      else
        self.to_enum __callee__
      end
    end

    def view_at(x, y, visible_only = true)
      return nil if visible_only && hidden?
      if @frame.contain? x, y
        dx = x - @frame.x
        dy = y - @frame.y
        v = nil
        each_child do |c|
          v = c.view_at dx, dy
          break if v
        end
        v ? v : self
      else
        nil
      end
    end

    def set_window(window)
      if @window
        raise "The view is already attached to another window" if window
        @window = nil
        detached_from_window
        each_child { |c| c.set_window nil }
        all_detached
      else
        if window
          @window = window
          attached_to_window
          each_child { |c| c.set_window @window }
          all_attached
        end
      end
    end

    def set_parent(parent)
      raise "The view is a member of another view" if @parent && parent
      if @parent || parent
        @parent = parent
        set_window(parent ? parent.window : nil)
      end
    end

    # focus
    def is_focus
      (@window && @window.focus == self) ? true : false
    end

    def make_focus(focus)
      changed = false
      if @window
        focus_view = @window.focus
        if focus_view == self && !focus
          changed = true
        elsif focus_view != self && focus
          focus_view.make_focus false if focus_view
          @window.focus = self
          changed = true
        end
        invalidate if changed
      end
    end

    # view port
    def extent
      bounds
    end

    def view_port
      bounds
    end

    def scroll_to(x, y)
    end

    # mvc
    def trigger(sym, *args)
      @observers.each do |o|
        o.__send__(sym, self, *args) if o.respond_to? sym
      end
    end

    def add_observer(observer)
      @observers.add observer
    end

    def remove_observer(observer)
      @observers.delete observer
    end

    # mouse
    def get_mouse
      if attached?
        x, y = window.get_mouse
        convert_from_window x, y
      end
    end
  end
end
