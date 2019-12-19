
module MiW
  class MouseHandler
    def initialize(window)
      @window = window
      @last_button = 0
      @last_button_time = Time.now
      @click_count = 0
      @click_interval = 500000 # us
    end

    def get_tracker
      if @tracker_view
        if @tracker_view.window.nil? ||
           @tracker_view.window != @window
          end_tracking
        end
      end
      @tracker_view
    end

    def mouse_moved(x, y, transit, data)
      if get_tracker
        tracked_mouse_motion(x, y, transit, data)
      else
        untracked_mouse_motion(x, y, transit, data)
      end
    end

    def mouse_down(x, y, detail, state)
      view = get_tracker || @last_view
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
        x, y = view.convert_from_window(x, y)
        view.mouse_down(x, y, detail, state, @click_count)
      end
    end

    def mouse_up(x, y, detail, state)
      view = get_tracker || @last_view
      if view
        x, y = view.convert_from_window(x, y)
        view.mouse_up(x, y, detail, state)
      end
    end        

    def tracked_mouse_motion(x, y, transit, data)
      view = @window.view_at(x, y)
      if view == @tracker_view   # not nil
        if view == @last_view
          notify_mouse_motion @tracker_view, x, y, :inside, data
        else
          notify_mouse_motion @tracker_view, x, y, :entered, data
        end
      else
        if @last_view == @tracker_view
          notify_mouse_motion @tracker_view, x, y, :exited, data
        else
          notify_mouse_motion @tracker_view, x, y, :outside, data
        end
      end
      @last_view = view
    end

    def untracked_mouse_motion(x, y, transit, data)
      view = @window.view_at(x, y)
      case transit
      when :entered
        if view
          @last_view = view
          notify_mouse_motion view, x, y, :entered, data
        end
      when :exited
        if @last_view
          view = @last_view
          @last_view = nil
          notify_mouse_motion view, x, y, :exited, data
        end
      when :inside
        if @last_view != view
          tmp = @last_view
          @last_view = view
          notify_mouse_motion tmp, x, y, :exited, data if tmp
          notify_mouse_motion view, x, y, :entered, data if view
        else
          notify_mouse_motion view, x, y, :inside, data if view
        end
      end
    end

    def notify_mouse_motion(view, x, y, transit, data)
      x, y = view.convert_from_window x, y
      view.mouse_moved x, y, transit, data
    end

    def set_tracking(view)
      if view
        if @tracker_view.nil? && @last_view == view
          @tracker_view = view
          true
        else
          false
        end
      else
        @tracker_view = nil
        true
      end
    end
  end
end
