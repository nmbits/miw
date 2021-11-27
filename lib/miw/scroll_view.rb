require 'miw/view'
require 'miw/scroll_bar'

module MiW
  class ScrollView < View
    def initialize(id, target: nil, target_hints: {}, corner: nil,
                   horizontal: false, vertical: false, **opts)
      super id, **opts
      if target
        set_target target, target_hints
        @target = target
      end
      if corner
        add_child corner
        @corner = corner
      end
      @scroll_bars = {}
      @scroll_bar_ids = []
      sb = ScrollBar.new "__miw_#{id}_h".to_sym, orientation: :horizontal
      add_child sb
      sb.add_observer self
      sb.show horizontal
      @scroll_bars[:horizontal] = sb
      sb = ScrollBar.new "__miw_#{id}_v", orientation: :vertical
      add_child sb
      sb.add_observer self
      sb.show vertical
      @scroll_bars[:vertical] = sb
      @scroll_bar_ids = @scroll_bars.values.map{|v| v.id}
    end

    def set_target(view, hints = {})
      return if view == @target
      if view
        if view.parent
          if view.parent != self
            raise ArgumentError, "The view is already a member of another view"
          end
        else
          add_child view, hints
        end
      end
      @target&.remove_observer self
      @target = view
      @target&.add_observer self
      extent_changed @target
      bounds_changed @target
    end

    def add_child(child, hints = {})
      raise ArgumentError, "invalid id" if @scroll_bar_ids.include? child.id
      super
    end

    def remove_child(child)
      raise ArgumentError, "invalid id" if @scroll_bar_ids.include? child.id
      @target.remove_observer self if @target && child == @target
      super
    end

    def scroll_bar(orientation)
      case orientation
      when :vertical, :horizontal
        @scroll_bars[orientation]
      else
        raise ArgumentError, "arg should be :horizontal or :vertical"
      end
    end

    def value_changed(scroll_bar)
      return unless @target
      value = scroll_bar.value
      b = @target.bounds
      case scroll_bar.id
      when @scroll_bars[:vertical].id
        @target.scroll_to b.x, value if value != b.y
      when @scroll_bars[:horizontal].id
        @target.scroll_to value, b.y if value != b.x
      end
    end

    def bounds_changed(view)
      if view == @target
        b = view.bounds
        s = @scroll_bars[:vertical]
        s.set_proportion b.height
        s.value = b.top
        s = @scroll_bars[:horizontal]
        s.set_proportion b.width
        s.value = b.left
      end
    end

    def extent_changed(view)
      if view == @target
        e = view.extent
        v = view.view_point
        @scroll_bars[:vertical].set_range e.top, e.bottom, v.y
        @scroll_bars[:horizontal].set_range e.left, e.right, v.x
      end
    end

    def do_layout
      rect = bounds
      if @scroll_bars[:vertical].visible?
        rect.width -= @scroll_bars[:vertical].thickness
      end
      if @scroll_bars[:horizontal].visible?
        rect.height -= @scroll_bars[:horizontal].thickness
      end
      except = [@scroll_bars[:vertical].id, @scroll_bars[:horizontal].id]
      except.push @corner.id if @corner
      @layout&.do_layout self.each_visible_child_with_hint(except: except), rect
      sc = @scroll_bars[:vertical]
      if sc.visible?
        sc.offset_to rect.right, rect.top
        sc.resize_to sc.thickness, rect.height
      end
      sc = @scroll_bars[:horizontal]
      if sc.visible?
        sc.offset_to rect.left, rect.bottom
        sc.resize_to rect.width, sc.thickness
      end
      if @corner && @corner.visible?
        @corner.offset_to rect.right, rect.bottom
        @corner.resize_to @scroll_bars[:vertical].thickness, @scroll_bars[:horizontal].thickness
      end
    end
  end
end
