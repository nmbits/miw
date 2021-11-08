require 'miw/view'
require 'miw/rectangle'
require 'miw/size'
require 'cairo'
require 'eventmachine'

module MiW
  class Window < PLATFORM::Window
    def initialize(title, x, y, width, height, layout: nil, **opts)
      super x, y, width, height, opts
      @cairo = Cairo::Context.new surface
      @pango_layout = @cairo.create_pango_layout

      # mouse
      @last_button_time = Time.now
      @click_count = 0
      @click_interval = 500000 # us

      @root = View.new :__miw_root_view__, layout: layout
      @root.root = true
      @root.set_window self
      @root.resize_to width, height
      @root.show
      @invalid_rect = Rectangle.new(0, 0, width, height)
    end

    attr_reader :cairo, :pango_layout
    attr_accessor :focus

    def invalidate(x, y, width, height)
      if @invalid_rect
        @invalid_rect.union x, y, x + width, y + height
      else
        @invalid_rect = Rectangle.new(x, y, width, height)
      end
      update_if_needed
    end

    def update_if_needed
      if @invalid_rect && !@update_requested
        @update_requested = true
        EM.next_tick do
          r = @invalid_rect
          @invalid_rect = nil
          @update_requested = false
          update r.x, r.y, r.width, r.height
        end
      end
    end

    def draw(x, y, width, height)
      r = Rectangle.new x, y, width, height
      cairo.save do
        cairo.translate 0.5, 0.5
        cairo.line_width = 1.0
        draw_recursive @root, r
      end
      sync x, y, width, height
    end

    def grab_input(view)
      raise ArgumentError, "another view grabs input" if @grabbing_view
      raise ArgumentError, "view is not a member of this window" if view.window != self
      @grabbing_view = view
      grab_pointer
    end

    def ungrab_input(view)
      raise ArgumentError, "speicified view is not grabbing input" if view != @grabbing_view
      @grabbing_view = nil
      ungrab_pointer
    end

    def mouse_moved(x, y, transit, data)
      tr = nil
      if @grabbing_view
        view = view_at(x, y)
        tr = (view == @grabbinv_view ?
                (@last_view == @grabbing_view ? :inside : :entered) :
                (@last_view == @grabbing_view ? :exited : :outside))
        @last_view = view
        notify_mouse_moved @grabbing_view, x, y, tr, data
      else
        case transit
        when :entered
          view = view_at(x, y)
          if view
            @last_view = view
            notify_mouse_moved view, x, y, :entered, data
          end
        when :exited
          if @last_view
            view = @last_view
            @last_view = nil
            notify_mouse_moved view, x, y, :exited, data
          end
        when :inside
          view = view_at(x, y)
          if @last_view != view
            tmp = @last_view
            @last_view = view
            notify_mouse_moved tmp, x, y, :exited, data if tmp
            notify_mouse_moved view, x, y, :entered, data if view
          else
            notify_mouse_moved view, x, y, :inside, data if view
          end
        end
      end
    end

    def notify_mouse_moved(view, x, y, transit, data)
      vx, vy = view.convert_from_window x, y
      view.mouse_moved vx, vy, transit, data
    end

    def mouse_down(x, y, detail, state)
      view = @grabbing_view || @last_view
      if view
        click_count = 1
        now = Time.now
        if detail == @last_button
          interval = now.usec - @last_button_time.usec
          if interval < 0
            interval += (now.sec - @last_button_time.sec) * 1000000
          end
          if interval < @click_interval
            click_count = @click_count + 1
          end
        end
        @click_count = click_count
        @last_button_time = now
        @last_button = detail
        vx, vy = view.convert_from_window x, y
        view.mouse_down vx, vy, detail, state, @click_count
      end
    end

    def mouse_up(x, y, detail, state)
      view = @grabbing_view || @last_view
      if view
        vx, vy = view.convert_from_window x, y
        view.mouse_up vx, vy, detail, state
      end
    end

    def key_down(keysym, state)
      (@grabbing_view || @focus)&.key_down keysym, state
    end

    def key_up(keysym, state)
      (@grabbing_view || @focus)&.key_up keysym, state
    end

    def shown
      @root.do_layout
    end

    def view_at(x, y)
      view = @root.view_at(x, y)
      if view == @root
        nil
      else
        view
      end
    end

    def frame_resized(width, height)
      @root.resize_to width, height
    end

    def add_child(view, hint = {})
      @root.add_child view, hint
    end

    def hit?(screen_x, screen_y)
      f = self.frame
      frame[0], frame[1] = convert_to_screen f[0], f[1]
      (screen_x >= frame[0] &&
       screen_y >= frame[1] &&
       screen_x <  frame[0] + frame[2] &&
       screen_y <  frame[1] + frame[3])
    end

    private

    def draw_recursive(view, rect)
      return unless view.visible?
      intr = view.bounds.intersect rect
      return unless intr.valid?
      @cairo.save { view.draw intr }
      view.each_visible_child do |child|
        @cairo.save do
          @cairo.translate child.x, child.y
          draw_recursive child, child.convert_from_parent(intr)
        end
      end
      @cairo.save { view.draw_after_children intr }
    end
  end
end
