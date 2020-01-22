
require 'miw'
require 'miw/view'
require 'miw/layout/box'
require 'miw/point'

module MiW
  class SplitView < View
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

    def find_targets(x, y)
      each_visible_child.each_cons(2).find do |a, b|
        @orientation == :vertical ?
          (a.frame.bottom < y && y < b.frame.top) :
          (a.frame.right < x && x < b.frame.left)
      end
    end

    def mouse_down(x, y, button, state, count)
      if count_children > 1 && button == 1
        @targets = find_targets(x, y)
        if @targets
          @mouse_pos = Point.new x, y
          window.set_tracking self
          window.grab_pointer
        end
      end
    end

    def mouse_moved(x, y, transit, state)
      if @targets
        if @orientation == :vertical
          delta = y - @mouse_pos.y
          @targets[0].resize_by 0, delta
          @targets[1].offset_by 0, delta
          @targets[1].resize_by 0, -delta
        else
          delta = x - @mouse_pos.x
          @targets[0].resize_by delta, 0
          @targets[1].offset_by delta, 0
          @targets[1].resize_by -delta, 0
        end
        @mouse_pos.x = x
        @mouse_pos.y = y
        invalidate
      end
    end

    def mouse_up(x, y, button, state)
      if button == 1
        window.set_tracking nil
        window.ungrab_pointer
        @targets = nil
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
