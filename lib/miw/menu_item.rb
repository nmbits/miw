
require 'miw'
require 'miw/rectangle'

module MiW
  class MenuItem
    EXTENT_RATIO = 1.4 # pseudo
    def initialize(label, shortcut: nil, accel_key: nil, icon: nil, type: :default)
      @label = label
      @shortcut = shortcut
      @accel_key = accel_key
      @icon = icon
      @type = type
      @frame = Rectangle.new 0, 0, 1, 1
      @highlight = false
    end
    attr_reader :label, :frame, :shortcut, :accel_key, :icon, :type
    attr_accessor :menu, :highlight

    def draw(highlight)
      cairo = menu.cairo
      cs = MiW.colors
      bgcolor = highlight ? cs[:control_background_highlight] : cs[:control_background]
      fgcolor = highlight ? cs[:control_forground_highlight] : cs[:control_forground]
      cairo.rectangle frame.x, frame.y, frame.width, frame.height
      cairo.set_source_color bgcolor
      cairo.fill
      panl = menu.pango_layout
      panl.text = @label
      x = @frame.x + @icon_width + 10 # pseudo
      y = @frame.y + ((@frame.height - @frame.height / EXTENT_RATIO) / 2).to_i
      cairo.move_to x, y
      cairo.set_source_color fgcolor
      cairo.show_pango_layout panl
    end

    def resize_to_preferred
      if menu
        panl = menu.pango_layout
        panl.text = @label
        w, h = panl.pixel_size
        @icon_width = h
        w += 20 #pseudo
        w += @icon_width
        h = (h * EXTENT_RATIO).ceil
        frame.resize_to w, h
      end
    end
  end
end
