require 'miw/view'

module MiW
  class ScrollBar < View
    autoload :DefaultModel,      'miw/scroll_bar/default_model'
    autoload :ExtentBoundsModel, 'miw/scroll_bar/extent_bounds_model'

    VALID_ORIENTATION = [:vertical, :horizontal]
    RepeatInfo = Struct.new(:dir, :threshold)

    def initialize(id, orientation: :vertical, thickness: 16,
                   model: DefaultModel.new, size: nil, **opts)
      unless VALID_ORIENTATION.include? orientation
        raise ArgumentError, "invalid orientation specified"
      end
      super id, **opts
      @knob = Rectangle.new(0, 0, 0, 0)
      @orientation = orientation
      @thickness = thickness
      @mouse_in = false
      self.model = model
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
    attr_reader :orientaion, :thickness, :model

    def model=(m)
      @model = m
      update_knob
      invalidate
    end

    def vertical?
      @orientation == :vertical
    end

    def update
      update_knob
      invalidate
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
        @model.value = align_val @drag_start_val + val_delta
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
        @model.value = [@model.min, @model.value - @model.proportion].max
      when :forward
        @model.value = [@model.max - @model.proportion, @model.value + @model.proportion].min
      else
        return
      end
      invalidate
    end

    private

    def val_to_px(value)
      px_size = vertical? ? height : width
      va_size = @model.max - @model.min
      if va_size > 0
        value * px_size / va_size
      else
        px_size
      end
    end

    def px_to_val(px)
      px_size = vertical? ? height : width
      if px_size > 0
        px * (@model.max - @model.min) / px_size
      else
        @model.max
      end
    end

    def update_knob
      if vertical?
        w = width * 0.6
        h = val_to_px @model.proportion
        kx = width * 0.2
        ky = val_to_px @model.value
      else
        w = val_to_px @model.proportion
        h = height * 0.6
        kx = val_to_px @model.value
        ky = height * 0.2
      end
      @knob.offset_to kx, ky
      @knob.resize_to w, h
      @knob.intersect bounds
    end

    def start_dragging(mx, my)
      grab_input
      @drag_start_px = vertical? ? my : mx
      @drag_start_val = @model.value
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
      if val + @model.proportion > @model.max
        val = @model.max - @model.proportion
      end
      if val < @model.min
        val = @model.min
      end
      if @model.step && @model.step > 1
        # todo
        m = val % @model.step
        val -= m
        val += step if m > step / 2
      end
      val
    end

    def repeat_scroll_page
      if @repeat_info
        if (@repeat_info.dir == :forward && @model.value + @model.proportion < @repeat_info.threshold) ||
           (@repeat_info.dir == :backward && @model.value > @repeat_info.threshold)
          scroll_page @repeat_info.dir
          EM.add_timer 0.05, method(:repeat_scroll_page)
        end
      end
    end
  end
end
