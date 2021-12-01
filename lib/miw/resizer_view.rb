require 'miw/view'

module MiW
  class ResizerView < View
    def draw(rect)
      cs = MiW.colors
      cairo.rectangle rect.x, rect.y, rect.width, rect.height
      cairo.set_source_color cs[:control_background]
      cairo.fill
      r = bounds
      ix = r.width * 0.15
      iy = r.height * 0.15
      r.inset_by ix, iy
      cairo.triangle r.x + r.width * 0.6, r.y + r.height,
                     r.x + r.width      , r.y + r.height,
                     r.x + r.width      , r.y + r.height * 0.6
      cairo.set_source_color cs[:control_forground]
      cairo.fill
    end

    def mouse_down(x, y, button, status, count)
      if button == 1
        start_dragging x, y
      end
    end

    def mouse_up(x, y, button, status)
      if button == 1
        end_dragging
      end
    end

    def mouse_moved(x, y, transit, data)
      if dragging?
        sx, sy = convert_to_screen x, y
        w = @ini_size[0] + sx - @ini_point[0]
        h = @ini_size[1] + sy - @ini_point[1]
        w = 0 if w < 0
        h = 0 if h < 0
        window.resize_to w, h
      end
    end

    def start_dragging(x, y)
      grab_input
      sx, sy = convert_to_screen x, y
      @ini_point = [sx, sy]
      @ini_size = window.size
    end

    def end_dragging
      ungrab_input
      @ini_point = nil
    end

    def dragging?
      @ini_point != nil
    end
  end
end
