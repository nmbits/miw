require 'miw'
require 'miw/scroll_bar'

module MiW
  class ScrollView < View
    def initialize(id, vertical: true, horizontal: true, target: nil, **opts)
      super id, **opts
      @scroll_bars = {}
      if vertical
        add_scroll_bar(:vertical)
      end
      if horizontal
        add_scroll_bar(:horizontal)
      end
      self.target = target
    end
    attr_reader :target

    def target=(target)
      if @target
        @target.remove_observer self
        remove_child @target
      end
      @target = target
      if target
        target.add_observer self
        add_child target
        init_scroll_bars
      end
    end

    def add_scroll_bar(orientation)
      if orientation != :vertical && orientation != :horizontal
        raise ArgumentError, "orientation should be :vertical or :horizontal, but #{orientation}"
      end
      if @scroll_bars[orientation]
        raise "scroll bar for #{orientation} already exist"
      end
      scroll_bar = ScrollBar.new "__miw_scroll_bar_#{orientation}".to_sym,
                                 orientation: orientation, range: (0..1), proportion: 1
      scroll_bar.add_observer self
      add_child scroll_bar
      scroll_bar.show
      @scroll_bars[orientation] = scroll_bar
      init_scroll_bars
    end

    def remove_scroll_bar(orientation)
      if orientation != :vertical && orientation != :horizontal
        raise ArgumentError, "orientation should be :vertical or :horizontal, but #{orientation}"
      end
      scroll_bar = @scroll_bars[orientation]
      if scroll_bar
        scroll_bar.remove_observer self
        remove_child info.view
        @scroll_bars[orientation] = nil
      end
    end

    def scroll_bar(orientation)
      @scroll_bars[orientation]
    end

    def value_changed(view)
      if @target
        val = view.value
        case view
        when @scroll_bars[:vertical]
          @target.scroll_to @target.view_port.x, val
        when @scroll_bars[:horizontal]
          @target.scroll_to val, @target.view_port.y
        end
      end
    end

    def view_port_changed(view)
      vp = view.view_port
      if sc = @scroll_bars[:vertical]
        sc.proportion = vp.height
        sc.value = vp.top
      end
      if sc = @scroll_bars[:horizontal]
        sc.proportion = vp.width
        sc.value = vp.left
      end
      invalidate
    end

    def extent_changed(view)
      e = view.extent
      if sc = @scroll_bars[:vertical]
        range = (e.top..e.bottom)
        sc.range = range if sc.range != range
      end
      if sc = @scroll_bars[:horizontal]
        range = (e.left..e.right)
        sc.range = range if sc.range != range
      end
    end

    def do_layout
      return if window.nil?
      target_size = self.size
      sb_v = @scroll_bars[:vertical]
      if sb_v && sb_v.visible?
        target_size.width -= sb_v.thickness
      end
      sb_h = @scroll_bars[:horizontal]
      if sb_h && sb_h.visible?
        target_size.height -= sb_h.thickness
      end

      if @target
        @target.offset_to 0, 0
        @target.resize_to target_size.width, target_size.height
      end

      if sb_v && sb_v.visible?
        sb_v.offset_to target_size.width, 0
        sb_v.resize_to sb_v.thickness, target_size.height
      end
      if sb_h && sb_h.visible?
        sb_h.offset_to 0, target_size.height
        sb_h.resize_to target_size.width, sb_h.thickness
      end
      invalidate
    end

    private

    def init_scroll_bars
      if @target
        extent = @target.extent
        vp = @target.view_port
        if sb = @scroll_bars[:vertical]
          range = (extent.top..extent.bottom)
          sb.set_range range, vp.y
          sb.proportion = vp.height
        end
        if sb = @scroll_bars[:horizontal]
          range = (extent.left..extent.right)
          sb.set_range range, vp.x
          sb.proportion = vp.width
        end
      end
    end
  end
end
