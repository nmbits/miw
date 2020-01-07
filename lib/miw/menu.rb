require 'miw'
require 'miw/menu_item'
require 'miw/size'
require 'miw/layout/box'

module MiW
  class Menu < View
    def initialize(name, font: nil, **opts)
      super name, **opts
      @layout = Layout::VBox.new
      @items = []
      @preferred_size = Size.new(0, 0)
      self.font = (font || MiW.fonts[:ui])
    end
    attr_reader :items, :preferred_size

    def attached_to_window
      @preferred_size.resize_to 0, 0
      pango_layout.font_description = font
      @items.each do |item|
        item.resize_to_preferred
        @preferred_size.width = [@preferred_size.width, item.frame.width].max
        @preferred_size.height += item.frame.height
      end
    end

    def add_item(item)
      raise ArgumentError, "The item is already a member of another menu." if item.menu
      @items << item
      item.menu = self
      if attached?
        item.resize_to_preferred
        @preferred_size.width = [@preferred_size.width, item.frame.width].max
        @preferred_size.height = @preferred_size.height + item.frame.height
      end
    end

    def add_separator_item
    end

    def each_item_frame_with_hint
      hint = {resize: [true, false]}
      if block_given?
        @items.each { |item| yield item.frame, hint }
      else
        self.to_enum __callee__
      end
    end

    def do_layout
      @layout.do_layout each_item_frame_with_hint, self.bounds
    end

    def draw(rect)
      cs = MiW.colors
      cairo.rectangle 0, 0, width, height
      cairo.set_source_color cs[:control_background]
      cairo.fill
      @items.each { |item| item.draw false }
    end
  end
end
