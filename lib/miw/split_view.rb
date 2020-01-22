
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
      end
    end

    def draw(rect)
      cs = MiW.colors
      cairo.rectangle 0, 0, width, height
      cairo.set_source_color cs[:control_background]
      cairo.fill
    end
  end
end
