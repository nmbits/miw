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
      rect_row = Rectangle.new 0, -@mod, width, row_height
      cs = MiW.colors
      cairo.save do
        cairo.rectangle rect.x, rect.y, rect.width, rect.height
        cairo.clip
        cairo.rectangle rect.x, rect.y, rect.width, rect.height
        cairo.set_source_color cs[:control_background]
        cairo.fill
        cairo.set_source_color cs[:control_forground]
        pango_layout.font_description = MiW.fonts[:ui]

        @view_model.each do |row|
          draw_row rect_row, row if rect_row.bottom > rect.top
          rect_row.offset_by 0, rect_row.height
          break if rect_row.y > rect.bottom
        end

        cairo.set_source_rgb 0.3, 0.3, 0.3 # pseudo
        x = 0
        @columns.each do |col|
          cairo.move_to x, rect.top
          cairo.line_to x, rect.bottom
          cairo.stroke
          x += (col[:width] || DEFAULT_WIDTH)
        end
      end
    end

    def draw_row(rect, row)
      x = bx = rect.x
      y = by = rect.y
      panl = pango_layout
      @columns.each do |col|
        key = col[:key]
        if key
          value = row.content[key]
          panl.text = value.to_s
          tw, th = panl.pixel_size
          cairo.move_to x, y + (rect.height - th) / 2
          cairo.show_pango_layout panl
          x += (col[:width] || DEFAULT_WIDTH)
        end
      end
      cairo.save do
        cairo.set_source_rgb 0.3, 0.3, 0.3 # pseudo
        cairo.move_to rect.left, rect.bottom
        cairo.line_to rect.right, rect.bottom
        cairo.stroke
      end
    end
  end
end
