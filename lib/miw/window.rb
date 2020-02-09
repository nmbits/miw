require 'miw/mouse_handler'
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
      @mouse_handler = MouseHandler.new self
      @root = View.new "__miw_root_view__", layout: layout
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

    def mouse_moved(x, y, transit, data)
      @mouse_handler.mouse_moved(x, y, transit, data)
    end

    def mouse_down(x, y, detail, state)
      @mouse_handler.mouse_down x, y, detail, state
    end

    def mouse_up(x, y, detail, state)
      @mouse_handler.mouse_up x, y, detail, state
    end

    def key_down(keysym, state)
      @focus.key_down keysym, state if @focus
    end

    def key_up(keysym, state)
      @focus.key_up keysym, state if @focus
    end

    def shown
      @root.do_layout
    end

    def set_tracking(view)
      @mouse_handler.set_tracking(view)
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
      frame = self.frame
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
