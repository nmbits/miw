require 'miw'
require 'miw/menu_item'
require 'miw/separator_item'
require 'miw/size'
require 'miw/layout/box'
require 'miw/menu_window'

module MiW
  class Menu < View
    def initialize(name, font: MiW.fonts[:ui], layout: Layout::VBox, **opts)
      super name, font: font, layout: layout, **opts
      @items = []
    end
    attr_reader :items, :master, :highlight

    def attached_to_window
      pango_layout.font_description = font
      resize_to_preferred
    end

    def preferred_size
      @preferred_size ||= calculate_preferred_size
    end

    def add_item(item_or_label)
      case item_or_label
      when String
        item = MenuItem.new item_or_label
      when MenuItem
        item = item_or_label
      else
        raise TypeError, "invalid argument type"
      end
      add_item_common item, :long
    end

    def add_submenu(label, menu)
      item = MenuItem.new label, submenu: menu
      add_item item
    end

    def add_separator_item
      add_item SeparatorItem.new
    end

    def do_layout
      layout.do_layout each_item_frame_with_hint, self.bounds
    end

    def draw(rect)
      cs = MiW.colors
      cairo.rectangle 0, 0, width, height
      cairo.set_source_color cs[:control_background]
      cairo.fill
      @items.each_with_index { |item, i| item.draw }
    end

    def mouse_down(x, y, button, state, count)
      redirect_mouse(:mouse_down, x, y, button, state, count) ||
        mouse_down_impl(x, y, button)
    end

    def mouse_down_impl(x, y, button)
      if button == 1 && !@master
        item = item_at(x, y)
        if item && item.enable?
          start_menuing
          open_submenu(item) if item.submenu
        end
      end
    end
    private :mouse_down_impl

    def mouse_moved(x, y, *_)
      redirect_mouse(:mouse_moved, x, y, *_) ||
        mouse_moved_impl(x, y)
    end

    def mouse_moved_impl(x, y)
      prev = @highlight
      item = @items.find { |item| item.enable? && item.frame.contain?(x, y) }
      if prev != item
        if @master
          if item&.submenu
            open_submenu(item)
          elsif item
            close_submenu
          end
        end
        @highlight = item if item
        invalidate
      end
    end
    private :mouse_moved_impl

    def mouse_up(x, y, button, state)
      # p :mouse_up
      # p [x, y, button, state]
      redirect_mouse(:mouse_up, x, y, button, state) ||
        mouse_up_impl(x, y, button, state)
    end

    def mouse_up_impl(x, y, button, state)
      if button == 1
        item = item_at x, y
        if item && item.enable?
          if item.submenu.nil?
            @master.item_selected item
          end
        end
      end
    end
    private :mouse_up_impl

    def start_menuing
      @master = self
      window.set_tracking self
      window.grab_pointer
    end

    def end_menuing
      close_submenu
      @master = nil
      @active_submenu_item = nil
      window.set_tracking nil
      window.ungrab_pointer
    end

    def open_submenu(item)
      pos = submenu_pos item
      item.submenu.open pos.x, pos.y, @master
    end
    private :open_submenu

    def open_submenu(item)
      if @active_submenu_item != item
        close_submenu
        if item
          pos = submenu_pos item
          item.submenu.open pos.x, pos.y, @master
          @active_submenu_item = item
        end
      end
    end
    private :open_submenu

    def item_at(x, y)
      @items.find { |item| item.frame.contain? x, y }
    end

    protected

    def item_selected(item)
      end_menuing
      @highlight = nil
      invalidate
      p item.label
    end

    def calculate_preferred_size
      size = Size.new 0, 0
      if attached?
        items.each do |item|
          item.resize_to_preferred
          size.width = [size.width, item.frame.width].max
          size.height += item.frame.height
        end
      end
      size
    end

    def add_item_common(item, appearance)
      raise ArgumentError, "The item is a member of another menu." if item.menu
      @items << item
      item.menu = self
      item.appearance = appearance
      @preferred_size = nil
      resize_to_preferred if attached?
      item
    end

    def item_layout_hint
      {resize: [true, false]}
    end

    def submenu_pos(item)
      convert_to_screen item.frame.right_top
    end

    def open(x, y, master)
      @master = master
      MenuWindow.new(self, x, y, :dropdown_menu).show unless attached?
    end

    def close_submenu
      @active_submenu_item.submenu.close if @active_submenu_item&.submenu
      @active_submenu_item = nil
    end

    def close
      close_submenu
      @highlight = nil
      @master = nil
      if attached?
        window.hide
        remove_self
      end
    end

    def find_submenu(sx, sy)
      item = @active_submenu_item
      if item&.submenu
        item.submenu.find_submenu(sx, sy) ||
          item.submenu.hit_and_self(sx, sy)
      end
    end

    def hit_and_self(sx, sy)
      if window&.hit?(sx, sy)
        return self if frame.contain? *window.convert_from_screen(sx, sy)
      end
      nil
    end

    private

    def each_item_frame_with_hint
      hint = item_layout_hint
      if block_given?
        @items.each { |item| yield item.frame, hint }
      else
        self.to_enum __callee__
      end
    end

    def redirect_mouse(sym, x, y, *a)
      if @master == self
        sx, sy = convert_to_screen x, y
        submenu = find_submenu sx, sy
        if submenu
          vx, vy = submenu.convert_from_screen sx, sy
          p [submenu.__id__, vx, vy]
          submenu.__send__ sym, vx, vy, *a
          return true
        end
      end
      false
    end
  end
end
