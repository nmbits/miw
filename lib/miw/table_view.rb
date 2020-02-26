require 'miw'

module MiW
  class TableView < View
    MARGIN_RATIO = 1.4   # pseudo
    DEFAULT_WIDTH = 80
    DEFAULT_ALIGN = :left
    def initialize(name, dataset: nil, **opts)
      super name, **opts
      @dataset = dataset
      @offset = 0
      @columns = []
      @row_height = 0
      @visible_lines = 20 # pseudo
    end
    attr_reader :dataset

    def attached_to_window
      panl = pango_layout
      panl.font_description = MiW.fonts[:ui]
      panl.text = "M"
      _, h = panl.pixel_size
      @row_height = (h * MARGIN_RATIO).ceil
    end

    def columns=(cols)
      @columns = cols
    end

    def dataset=(d)
      @dataset = d
    end

    def extent
      # pseudo
      Rectangle.new 0, 0, 100, @dataset.count
    end

    def view_port
      Rectangle.new 0, @offset, 100, 20 # pseudo
      # Rectangle.new 0, @offset, 100, @visible_lines
    end

    def scroll_to(x, y)
      @offset = y
      invalidate
    end

    def draw(rect)
      x = y = 0
      cs = MiW.colors
      cairo.save do
        cairo.rectangle rect.x, rect.y, rect.width, rect.height
        cairo.clip
        cairo.rectangle rect.x, rect.y, rect.width, rect.height
        cairo.set_source_color cs[:control_background]
        cairo.fill
        cairo.set_source_color cs[:control_forground]

        @dataset.offset(@offset).each do |row|
          h = draw_row x, y, row
          y += h
          break if y > rect.y + rect.height
        end
      end
    end

    def draw_row(x, y, raw)
      bx, by = x, y
      panl = pango_layout
      panl.font_description = MiW.fonts[:ui]
      max_height = 0
      @columns.each do |col|
        key = col[:key]
        if key
          value = raw[key]
          panl.text = value.to_s
          cairo.move_to x, y
          cairo.show_pango_layout panl
          w, h = panl.pixel_size
          x += (col[:width] || DEFAULT_WIDTH)
          max_height = [h, max_height].max
          # cairo.move_to x, by
          # cairo.line_to x, by + max_height
          # cairo.stroke
        end
      end
      # cairo.move_to bx, by + max_height
      # cairo.line_to x, by + max_height
      # cairo.stroke
      max_height
    end
  end
end
