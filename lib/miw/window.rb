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
      @width = width
      @height = height
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
      update(0, 0, @width, @height) if @invalid_rect
    end

    def draw(x, y, width, height)
      rect = Rectangle.new(x, y, width, height)
      if @invalid_rect
        rect.intersect @invalid_rect
        if rect.width > 0 && rect.height > 0
          @cairo.save{ draw_recursive @root, rect }
          @invalid_rect = nil
        end
      end
      sync rect.x, rect.y, rect.width, rect.height
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
      if @lazy_size
        @lazy_size.resize_to(width, height)
      else
        @lazy_size = Size.new(width, height)
        EM.add_timer 0.01 do
          @width = @lazy_size.width
          @height = @lazy_size.height
          @root.resize_to @width, @height
          invalidate 0, 0, @width, @height
          @lazy_size = nil
        end
      end
    end

    def add_child(view, hint = {})
      @root.add_child view, hint
    end

    private

    def draw_recursive(view, rect)
      return unless view.visible?
      intr = view.bounds.intersect rect
      return unless intr.valid?
      @cairo.save{ view.draw intr }
      view.each_child do |child|
        next unless child.visible?
        @cairo.save do
          @cairo.translate child.x, child.y
          draw_recursive child, child.convert_from_parent(intr)
        end
      end
      @cairo.save{ view.draw_after_children intr }
    end
  end
end
