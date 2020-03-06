require 'miw'

module MiW
  class TableView < View
    MARGIN_RATIO = 1.4   # pseudo
    DEFAULT_WIDTH = 80
    DEFAULT_ALIGN = :left
    def initialize(name, dataset: nil, tree_mode: false, **opts)
      super name, **opts
      @offset = 0
      @columns = []
      @visible_lines = 20 # pseudo
      @tree_mode = tree_mode
      @view_model = (tree_mode ? ViewModel::TreeTable : ViewModel::FlatTable).new dataset
      @mod = 0
    end

    def columns=(cols)
      @columns = cols
    end

    def dataset=(d)
      @dataset = d
      @count = @dataset.count
    end

    def extent
      Rectangle.new 0, 0, 100, @view_model.total * row_height
    end

    def view_port
      Rectangle.new 0, @view_model.offset * row_height, 100, height
    end

    def scroll_to(x, y)
      if (h = row_height) > 0
        i = y / h
        @mod = y % h
        @view_model.offset_to i
        invalidate
      end
    end

    def row_height
      (font_pixel_height * MARGIN_RATIO).ceil
    end

    def draw(rect)
      x = 0
      y = - @mod
      h = row_height
      cs = MiW.colors
      cairo.save do
        cairo.rectangle rect.x, rect.y, rect.width, rect.height
        cairo.clip
        cairo.rectangle rect.x, rect.y, rect.width, rect.height
        cairo.set_source_color cs[:control_background]
        cairo.fill
        cairo.set_source_color cs[:control_forground]

        @view_model.each do |row|
          draw_row x, y, row
          y += h
          break if y > rect.y + rect.height
        end
      end
    end

    def draw_row(x, y, row)
      bx, by = x, y
      panl = pango_layout
      panl.font_description = MiW.fonts[:ui]
      max_height = 0
      @columns.each do |col|
        key = col[:key]
        if key
          value = row.content[key]
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
