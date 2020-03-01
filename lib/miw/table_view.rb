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
    end

    def columns=(cols)
      @columns = cols
    end

    def dataset=(d)
      @dataset = d
      @count = @dataset.count
    end

    def extent
      # pseudo
      Rectangle.new 0, 0, 100, @view_model.total
    end

    def view_port
      Rectangle.new 0, @view_model.offset, 100, 20 # pseudo
    end

    def scroll_to(x, y)
      @view_model.offset_to y
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

        @view_model.each do |row|
          h = draw_row x, y, row
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
