require 'miw'
require 'miw/menu'
require 'miw/layout/box'
require 'pango'

module MiW
  class MenuBar < Menu
    EXTENT_RATIO = 1.4 # pseudo
    MARGINE_RATIO = 0.4 # pseudo
    def initialize(name, layout: Layout::HBox, **opts)
      super name, layout: layout, **opts
      resize_to DEFAULT_SIZE
    end

    def add_item(item)
      add_item_common item, :short
    end

    def attached_to_window
      super
    end

    protected

    def calculate_preferred_size
      size = Size.new 20, 0 # pseudo
      if attached?
        items.each do |item|
          item.resize_to_preferred
          size.width += item.frame.width
          size.height = [size.height, item.frame.height].max
        end
      end
      size
    end

    def item_layout_hint
      {resize: [false, true]}
    end

    def submenu_pos(item)
      convert_to_screen item.frame.left_bottom
    end
  end
end
