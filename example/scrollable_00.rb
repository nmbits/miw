# coding: utf-8
require 'bundler/setup'
require 'miw'
require 'miw/scroll_view'
require 'miw/resizer_view'

if __FILE__ == $0

  class Check < MiW::View
    BOX_SIZE = 20
    EXTENT_SIZE = 2000
    def initialize(id)
      super id
      @extent = MiW::Rectangle.new 0, 0, EXTENT_SIZE, EXTENT_SIZE
    end

    def extent
      @extent
    end

    def adjust_view_point(x, y)
      if x < 0 || extent.width < width
        x = 0
      elsif x > extent.right - width
        x = extent.right - width
      end
      if y < 0 || extent.height < height
        y = 0
      elsif y > extent.bottom - height
        y = extent.bottom - height
      end
      [x, y]
    end

    def frame_resized(width, height)
      x, y = adjust_view_point view_point.x, view_point.y
      if x != view_point.x || y != view_point.y
        scroll_to x, y
      else
        notify :bounds_changed
      end
    end

    def mouse_down(mx, my, button, status, count)
      case button
      when 1
        grab_input
        @px = mx
        @py = my
        @dragging = true
      end
    end

    def mouse_up(mx, my, button, status)
      if button == 1
        ungrab_input
        @dragging = false
      end
    end

    def mouse_moved(mx, my, transit, data)
      if @dragging
        dx = @px - mx
        dy = @py - my
        x = view_point.x + dx
        y = view_point.y + dy
        x, y = adjust_view_point(x, y)
        scroll_to x, y
      end
    end

    def draw(rect)
      cairo.save do
        cairo.rectangle rect.x, rect.y, rect.width, rect.height
        cairo.clip
        cairo.rectangle rect.x, rect.y, rect.width, rect.height
        cairo.set_source_color MiW.colors[:control_background]
        cairo.fill
        limit_x = [bounds.right, EXTENT_SIZE].min
        limit_y = [bounds.bottom, EXTENT_SIZE].min
        y = view_point.y / BOX_SIZE * BOX_SIZE
        while y < limit_y
          x = view_point.x / BOX_SIZE * BOX_SIZE
          while x < limit_x
            if ((x / BOX_SIZE).odd?  && (y / BOX_SIZE).even?) ||
               ((x / BOX_SIZE).even? && (y / BOX_SIZE).odd?)
              cairo.rectangle x, y, BOX_SIZE, BOX_SIZE
            end
            x += BOX_SIZE
          end
          y += BOX_SIZE
        end
        cairo.set_source_color MiW.colors[:control_background_highlight]
        cairo.fill
      end
    end
  end

  w = MiW::Window.new "test", 10, 10, 400, 400, layout: MiW::Layout::VBox
  w.title = "scroll view"
  def w.quit_requested
    p :quit_requested
    EM.stop_event_loop
  end

  m = MiW::MenuBar.new :menu
  m.add_item MiW::MenuItem.new("File")
  m.add_item MiW::MenuItem.new("Edit")
  w.add_child m, resize: [true, false]

  rv = MiW::ResizerView.new :resizer

  sv = MiW::ScrollView.new :scroll, layout: MiW::Layout::VBox,
                           vertical: true, horizontal: true,
                           corner: rv

  v = Check.new :v
  sv.set_target v, resize: [true, true]

  w.add_child sv, resize: [true, true]

  w.show
  MiW.run
end
