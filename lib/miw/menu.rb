require 'miw'
require 'miw/menu_item'
require 'miw/size'
require 'miw/layout/box'

module MiW
  class Menu < View
    EXTENT_RATIO = 1.4 # pseudo
    def initialize(name, font: nil, **opts)
      super name, **opts
      @layout = MiW::Layout::VBox.new
      @items = []
      self.font = (font || MiW.fonts[:ui])
    end
    attr_reader :items

    def attached_to_window
      size = Size.new 0, 0
      pango_layout.font_description = font
      @items.each do |item|
        update_item_size item
        size.width = [size.width, i.frame.width].max
        size.height += item.frame.height
      end
      resize_to size
    end

    def add_item(item)
      @items << item
      if attached?
        update_item_size item
        width = [self.width, item.frame.width].max
        height = self.height + item.frame.height
        resize_to width, height
      end
    end

    def add_separator_item
    end

    def update_item_size(item)
      pango_layout.text = item.label
      s = pango_layout.pixel_size
      w = s[0] + 20 #pseudo
      h = (s[1] * EXTENT_RATIO).ceil
      item.frame.resize_to w, h
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
      @items.each { |item| item.draw self, false }
    end
  end
end
