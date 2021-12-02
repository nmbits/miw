require 'miw/view'

module MiW
  class AbstractButton < View
    def mouse_down(x, y, button, status, count)
      if button == 1 && window.grabbing_view == nil
        grab_input
        @mouse_inside = true
        pressed
      end
    end

    def mouse_up(x, y, button, status)
      if button == 1 && window.grabbing_view == self
        ungrab_input
        @mouse_inside ? clicked : released
      end
    end

    def mouse_moved(x, y, transit, data)
      case transit
      when :entered
        @mouse_inside = true
        entered
      when :exited
        @mouse_inside = false
        exited
      end
    end

    def pressed;  end
    def clicked;  end
    def released; end
    def entered;  end
    def exited;   end
  end
end
