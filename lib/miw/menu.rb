require 'miw'
require 'miw/menu_item'
require 'miw/separator_item'
require 'miw/size'
require 'miw/layout/box'

module MiW
  class Menu < View
    def initialize(name, font: MiW.fonts[:ui], layout: Layout::VBox, **opts)
      super name, font: font, layout: layout, **opts
      @items = []
    end
    attr_reader :items

    def attached_to_window
      pango_layout.font_description = font
      resize_to_preferred
    end

    def preferred_size
      @preferred_size ||= calculate_preferred_size
    end

    def add_item(item)
      add_item_common item, :long
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

    def mouse_moved(x, y, transit, state)
      prev_highlight = @highlight
      @highlight = nil
      @items.each_with_index do |item, i|
        next unless item.enable?
        if item.frame.y > y
          break
        elsif item.frame.contain? x, y
          @highlight = i
          break
        end
      end
      if prev_highlight != @highlight
        @items[prev_highlight].highlight = false if prev_highlight
        @items[@highlight].highlight = true if @highlight
        invalidate
      end
    end

    def mouse_up(x, y, button, state)
      if button == 1
        @items.each do |item|
          next unless item.enable?
          if item.frame.contain? x, y
            trigger :item_selected, item
            break
          end
        end
      end
    end

    protected

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
    end

    def item_layout_hint
      {resize: [true, false]}
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
  end
end
