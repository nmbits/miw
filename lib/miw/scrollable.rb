require 'miw'
require 'miw/point'
require 'miw/scroll_bar'

module MiW
  module Scrollable

    SCROLL_BAR_IDS = [:__miw_scrollable_h_sc, :__miw_scrollable_v_sc]

    def initialize_scrollable(horizontal, vertical)
      scroll_bar = ScrollBar.new :__miw_scrollable_h_sc, orientation: :horizontal
      range = (extent.left...extent.right)
      scroll_bar.set_range range, view_port.left
      scroll_bar.proportion = view_port.width
      scroll_bar.add_observer self
      add_child scroll_bar
      scroll_bar.show horizontal
      @__miw_scrollable_h_sc = scroll_bar

      scroll_bar = ScrollBar.new :__miw_scrollable_v_sc, orientation: :vertical
      range = (extent.top...extent.bottom)
      scroll_bar.set_range range, view_port.top
      scroll_bar.proportion = view_port.height
      scroll_bar.add_observer self
      add_child scroll_bar
      scroll_bar.show vertical
      @__miw_scrollable_v_sc = scroll_bar
    end

    def scroll_bar(orientation)
      case orientation
      when :vertical
        @__miw_scrollable_v_sc
      when :horizontal
        @__miw_scrollable_h_sc
      else
        raise ArgumentError, "arg should be :horizontal or :vertical"
      end
    end

    def show_scroll_bar(orientation, v = true)
      scroll_bar(orientation).show v
    end

    def hide_scroll_bar(orientation)
      show_scroll_bar orientation, false
    end

    def value_changed(scroll_bar)
      value = scroll_bar.value
      case scroll_bar
      when @__miw_scrollable_v_sc
        scroll_to view_port.x, value
      when @__miw_scrollable_h_sc
        scroll_to value, view_port.y
      end
    end

    def view_port_changed(view = self)
      vp = view.view_port
      @__miw_scrollable_v_sc.proportion = vp.height
      @__miw_scrollable_v_sc.value = vp.top
      @__miw_scrollable_h_sc.proportion = vp.width
      @__miw_scrollable_h_sc.value = vp.left
    end

    def extent_changed(view = self)
      ext = view.extent
      range = (ext.top...ext.bottom)
      @__miw_scrollable_v_sc.range = range if @__miw_scrollable_v_sc.range != range
      range = (ext.left...ext.right)
      @__miw_scrollable_h_sc.range = range if @__miw_scrollable_h_sc.range != range
    end

    def extent
      bounds
    end

    def view_port
      extent
    end

    def scroll_to x, y
    end

    def scroll_bars_rect
      bounds
    end

    def do_layout
      @layout&.do_layout self.each_visible_child_with_hint(except: SCROLL_BAR_IDS), bounds

      rect = scroll_bars_rect.dup
      if @__miw_scrollable_h_sc.visible?
        rect.height -= @__miw_scrollable_h_sc.thickness
      end
      if @__miw_scrollable_v_sc.visible?
        rect.width -= @__miw_scrollable_v_sc.thickness
      end

      if @__miw_scrollable_h_sc.visible?
        @__miw_scrollable_h_sc.offset_to rect.left, rect.bottom
        @__miw_scrollable_h_sc.resize_to rect.width, @__miw_scrollable_v_sc.thickness
      end

      if @__miw_scrollable_v_sc.visible?
        @__miw_scrollable_v_sc.offset_to rect.right, rect.top
        @__miw_scrollable_v_sc.resize_to @__miw_scrollable_h_sc.thickness, rect.height
      end
    end
  end
end
