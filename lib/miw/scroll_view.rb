require 'miw/view'
require 'miw/scroll_bar'

module MiW
  class ScrollView < View
    def initialize(id, target: nil, target_hints: {}, corner: nil,
                   horizontal: false, vertical: false, **opts)
      super id, **opts
      @scroll_bars = {}
      [[:horizontal, horizontal],[:vertical, vertical]].each do |o, v|
        sb = ScrollBar.new "__miw_#{id}_sb_#{o}".to_sym, orientation: o
        add_child sb
        sb.show v
        @scroll_bars[o] = sb
      end
      set_target target, target_hints if target
      if corner
        add_child corner
        @corner = corner
      end
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
        model_h = ScrollBar::ExtentBoundsModel.new view, :horizontal
        model_v = ScrollBar::ExtentBoundsModel.new view, :vertical
      else
        model_h = ScrollBar::DefaultModel.new
        model_v = ScrollBar::DefaultModel.new
      end
      @scroll_bars[:horizontal].model = model_h
      @scroll_bars[:vertical].model = model_v
      @target = view
      update_scroll_bars
    end

    def add_child(child, hints = {})
      raise ArgumentError, "invalid id" if @scroll_bars.find{|k, v| child.id == v.id }
      super
    end

    def remove_child(child)
      raise ArgumentError, "invalid id" if @scroll_bars.find{|k, v| child.id == v.id }
      if @target && child == @target
        set_target nil
      end
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

    def update_scroll_bars
      [:vertical, :horizontal].each do |o|
        @scroll_bars[o].model.changed
        @scroll_bars[o].model.notify_observers
      end
    end

    def receive(view, what, *args)
      if view == @target
        case what
        when :bounds_changed, :extent_changed
          update_scroll_bars
        end
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
