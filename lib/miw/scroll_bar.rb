require 'miw/view'

module MiW
  class ScrollBar < View

    VALID_ORIENTATION = [:vertical, :horizontal]
    RepeatInfo = Struct.new(:dir, :threshold)

    def initialize(id, orientation: :vertical, thickness: 16,
                   min: 0, max: 1000, value: 0, step: nil,
                   proportion: 50, min_proportion: 50, size: nil, **opts)
      unless VALID_ORIENTATION.include? orientation
        raise ArgumentError, "invalid orientation specified"
      end
      super id, **opts
      @orientation = orientation
      @min_proportion = min_proportion
      @proportion = proportion
      @thickness = thickness
      @step = step
      @mouse_in = false
      @knob = Rectangle.new(0, 0, 0, 0)
      set_range(min, max, value)
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
    attr_reader :orientaion, :thickness, :min, :max, :value, :step, :proportion

    def set_range(min, max, value)
      unless min <= max
        raise RangeError, "min should be less than or equal to max"
      end
      unless value >= min
        raise RangeError, "value should be greater than or equal to min"
      end
      unless value <= max
        raise RangeError, "value should be less than or equal to max"
      end
      @min, @max = min, max
      self.value = value
      update_knob
      invalidate
    end

    def value=(value)
      if @value != value
        unless value >= @min
          raise RangeError, "value should be greater than or equal to min"
        end
        unless value <= @max
          raise RangeError, "value should be less than or equal to max"
        end
        @value = value
        trigger :value_changed
        update_knob
        invalidate
      end
    end

    def set_min_proportion(v)
      unless v > 0
        raise ArgumentError, "min_proportion should be greater than 0"
      end
      @min_proportion = v
      if @proportion < @min_proportion
        set_proportion(@min_proportion)
      end
    end

    def set_proportion(proportion)
      if proportion < @min_proportion
        proportion = @min_proportion
      end
      if @proportion != proportion
        @proportion = proportion
        update_knob
        invalidate
      end
    end

    def vertical?
      @orientation == :vertical
    end

    def frame_resized(w, h)
      update_knob
      invalidate
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
        if vertical?
          return unless height > 0
          top = @knob.top
          bottom = @knob.bottom
          mv = my
        else
          return unless width > 0
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
      if vertical?
        return unless height > 0
      else
        return unless width > 0
      end
      prev = @mouse_in
      redraw = false
      case transit
      when :entered
        @mouse_in = true
      when :exited
        @mouse_in = false
      end
      redraw = true if prev != @mouse_in
      if dragging?
        px = vertical? ? my : mx
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
        self.value = [@min, @value - @proportion].max
      when :forward
        self.value = [@max - @proportion, @value + @proportion].min
      else
        return
      end
    end

    private

    def val_to_px(value)
      px_size = vertical? ? height : width
      va_size = @max - @min
      if va_size > 0
        value * px_size / va_size
      else
        px_size
      end
    end

    def px_to_val(px)
      px_size = vertical? ? height : width
      if px_size > 0
        px * (@max - @min) / px_size
      else
        @max
      end
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
      if val + @proportion > @max
        val = @max - @proportion
      end
      if val < @min
        val = @min
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
