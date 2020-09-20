# coding: utf-8
require 'bundler/setup'
require 'miw'
require 'miw/scrollable'

if __FILE__ == $0

  class Check < MiW::View
    include MiW::Scrollable
    BOX_SIZE = 50
    EXTENT_SIZE = 1000
    RATIO_MIN = 0.1
    RATIO_MAX = 10.0
    def initialize(id)
      super id
      @view_port = MiW::Rectangle.new(0, 0, 100, 100)
      @extent = MiW::Rectangle.new(0, 0, EXTENT_SIZE, EXTENT_SIZE)
      @ratio = 1.0
      initialize_scrollable true, true
    end
    attr_reader :view_port, :extent

    def frame_resized(width, height)
      rect = content_rect
      nw = (rect.width * @ratio).to_i
      nh = (rect.height * @ratio).to_i
      @view_port.resize_to nw, nh
      dx = dy = 0
      if @view_port.right > EXTENT_SIZE
        dx = EXTENT_SIZE - @view_port.right
      end
      if @view_port.bottom > EXTENT_SIZE
        dy = EXTENT_SIZE - @view_port.bottom
      end
      @view_port.offset_by dx, dy
      view_port_changed
    end

    def mouse_down(mx, my, button, status, count)
      p button
      case button
      when 1
        window.set_tracking self
        @px = mx
        @py = my
        @dragging = true
      end
    end

    def mouse_up(*_)
      window.set_tracking nil
      @dragging = false
    end

    def mouse_moved(mx, my, transit, data)
      if @dragging
        dx = @px - mx
        dy = @py - my
        x = [0, @view_port.x + dx].max
        x = [x, @extent.width - @view_port.width].min
        y = [0, @view_port.y + dy].max
        y = [y, @extent.height - @view_port.height].min
        @view_port.offset_to x, y
        @px = mx
        @py = my
        view_port_changed
        invalidate
      end
      p MiW.get_mouse
    end

    def draw(rect)
      rect = content_rect
      dx = (@view_port.left % BOX_SIZE) * @ratio
      dy = (@view_port.top % BOX_SIZE) * @ratio
      # vertical
      x = rect.x - dx
      y = rect.y - dy
      cairo.rectangle 0, 0, rect.width, rect.height
      cairo.set_source_color MiW.colors[:control_background]
      cairo.fill
      while x < rect.width
        if x >= 0
          cairo.move_to x, 0
          cairo.line_to x, rect.height
        end
        x += BOX_SIZE * @ratio
      end
      while y < rect.height
        if y >= 0
          cairo.move_to 0, y
          cairo.line_to rect.width, y
        end
        y += BOX_SIZE * @ratio
      end
      cairo.set_source_color MiW.colors[:control_background_highlight]
      cairo.stroke
    end

    def scroll_to(x, y)
      @view_port.offset_to x, y
      invalidate
    end
  end

  w = MiW::Window.new("test", 10, 10, 400, 400, layout: MiW::Layout::VBox)
  w.title = "scroll view"
  def w.quit_requested
    p :quit_requested
    EM.stop_event_loop
  end

  m = MiW::MenuBar.new :menu
  m.add_item MiW::MenuItem.new("File")
  m.add_item MiW::MenuItem.new("Edit")
  w.add_child m, resize: [true, false]

  v = Check.new :v
  w.add_child v, resize: [true, true]

  w.show
  MiW.run
end
