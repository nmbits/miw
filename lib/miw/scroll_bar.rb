require 'miw/view'

module MiW
  class ScrollBar < View

    VALID_ORIENTATION = [:vertical, :horizontal]

    RepeatInfo = Struct.new(:dir, :threshold)

    def initialize(id, orientation: :vertical, thickness: 16,
                   range: (0...1000), value: 0, step: nil,
                   proportion: 50, min_proportion: 50, size: nil, **opts)
      super id, **opts
      unless VALID_ORIENTATION.include? orientation
        raise ArgumentError, "invalid orientation specified"
      end
      @orientation = orientation
      @proportion = proportion
      @min_proportion = min_proportion
      @thickness = thickness
      @range = range
      @value = value
      @step = step
      @mouse_in = false
      @knob = Rectangle.new(0, 0, 0, 0)
      if size
        resize_to size
      else
        if @orientation == :vertical
          resize_to @thickness, self.size.height
        else
          resize_to self.size.width, @thickness
        end
      end
    end
    attr_reader :orientaion, :thickness, :range, :value, :step, :proportion

    def set_range(range, value)
      @range = range
      trigger :range_changed
      @value = nil
      self.value = value
    end

    def range=(range)
      val = range.include?(@value) ? @value : range.min
      set_range range, val
    end

    def value=(value)
      if @value != value
        @value = value
        update_knob
        invalidate
      end
    end

    def proportion=(proportion)
      if @proportion != proportion
        @proportion = proportion
        invalidate
      end
    end

    def vertical?
      @orientation == :vertical
    end

    def frame_resized(w, h)
      update_knob
    end
    
    def draw(rect)
      # fill frame
      cs = MiW.colors
      cairo.move_to 0, 0
      cairo.rectangle 0, 0, width, height
      if @mouse_in || dragging?
        c = cs[:control_inner_background_highlight]
      else
        c = cs[:control_inner_background]
      end
      cairo.set_source_color c
      cairo.fill_preserve

      # stroke frame
      c = cs[:control_inner_border]
      cairo.set_source_color c
      cairo.stroke

      # knob
      cairo.rectangle @knob.x, @knob.y, @knob.width, @knob.height
      cs = MiW.colors
      if @mouse_in || dragging?
        c = cs[:control_background_highlight]
      else
        c = cs[:control_background]
      end
      cairo.set_source_color c
      cairo.fill
    end

    def mouse_down(mx, my, button, status, count)
      if button == 1
        if @orientation == :vertical
          top = @knob.top
          bottom = @knob.bottom
          mv = my
        else
          top = @knob.left
          bottom = @knob.right
          mv = mx
        end
        if mv >= top && mv < bottom
          start_dragging mx, my
        else
          start_repeat_page_scroll(top, mv)
        end
      end
    end

    def mouse_moved(mx, my, transit, data)
      prev = @mouse_in
      redraw = false
      case transit
      when :entered
        @mouse_in = true
      when :exited
        @mouse_in = false
      end
      redraw = true if prev != @mouse_in
      px = vertical? ? my : mx
      if dragging?
        px_delta = px - @drag_start_px
        val_delta = px_to_val px_delta
        self.value = align_val @drag_start_val + val_delta
        trigger :value_changed
        update_knob
        redraw = true
      end
      invalidate if redraw
    end

    def mouse_up(mx, my, button, *a)
      if button == 1
        if dragging?
          end_dragging
        elsif repeat_page_scroll?
          end_repeat_page_scroll
        end
        invalidate
      end
    end

    def scroll_page(dir)
      case dir
      when :backward
        @value = [@range.min, @value - @proportion].max
      when :forward
        @value = [@range.max - @proportion, @value + @proportion].min
      else
        return
      end
      trigger :value_changed
      update_knob
      invalidate
    end

    private

    def px_size
      size = [(vertical? ? height : width), 1].max
    end

    def val_to_px(value)
      if @range.size > 0
        value * px_size / @range.size
      else
        0
      end
    end

    def px_to_val(px)
      px * @range.size / px_size
    end

    def update_knob
      if vertical?
        w = width * 0.6
        h = val_to_px @proportion
        kx = width * 0.2
        ky = val_to_px @value
      else
        w = val_to_px @proportion
        h = height * 0.6
        kx = val_to_px @value
        ky = height * 0.2
      end
      @knob.offset_to kx, ky
      @knob.resize_to w, h
      @knob.intersect bounds
    end

    def start_dragging(mx, my)
      grab_input
      @drag_start_px = vertical? ? my : mx
      @drag_start_val = value
    end

    def end_dragging
      ungrab_input
      @drag_start_px = nil
    end

    def dragging?
      @drag_start_px != nil
    end

    def start_repeat_page_scroll(px, mouse_px)
      grab_input
      dir = mouse_px < px ? :backward : :forward
      threshold = px_to_val mouse_px
      @repeat_info = RepeatInfo.new dir, threshold
      scroll_page dir
      EM.add_timer(0.2, method(:repeat_scroll_page))
    end

    def end_repeat_page_scroll
      ungrab_input
      @repeat_info = nil
    end

    def repeat_page_scroll?
      @repeat_info != nil
    end

    def align_val(val)
      min = range.min
      max = range.max
      if val < min
        val = min
      elsif val + @proportion > max
        val = max - @proportion
      end
      if step && step > 1
        m = val % step
        val -= m
        val += step if m > step / 2
      end
      val
    end

    def repeat_scroll_page
      if @repeat_info
        if (@repeat_info.dir == :forward && @value + @proportion < @repeat_info.threshold) ||
           (@repeat_info.dir == :backward && @value > @repeat_info.threshold)
          scroll_page @repeat_info.dir
          EM.add_timer 0.05, method(:repeat_scroll_page)
        end
      end
    end
  end
end
