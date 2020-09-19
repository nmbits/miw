require 'miw'
require 'miw/layout/box'

module MiW
  class TableView < View
    autoload :DataCache, "miw/table_view/data_cache"
    autoload :TextColumn, "miw/table_view/text_column"

    MARGIN_RATIO = 1.4   # pseudo
    DEFAULT_WIDTH = 80
    DEFAULT_ALIGN = :left
    def initialize(name, dataset: nil, tree_mode: false, **opts)
      super name, **opts
      @offset = 0
      @columns = []
      @tree_mode = tree_mode
      @mod = 0
      self.dataset = dataset
      @layout = Layout::HBox.new
    end

    def add_column(column)
      @columns << column
    end

    def dataset=(dataset)
      @data_cache = DataCache.new dataset
    end

    def extent
      Rectangle.new 0, 0, 100, @data_cache.count * row_height
    end

    def view_port
      Rectangle.new 0, @offset * row_height, 100, height
    end

    def scroll_to(x, y)
      if (h = row_height) > 0
        i = y / h
        @mod = y % h
        @offset = i
        invalidate
      end
    end

    def row_height
      (font_pixel_height * MARGIN_RATIO).ceil
    end

    def each_visible_column_with_hint
      hint = { resize: [true, true], min_size: [0, 0], max_size: [0, 0] }
      if block_given?
        @columns.each do |column|
          hint[:resize][0] = column.resize
          hint[:min_size][0] = column.min_width
          hint[:max_size][0] = column.max_width
          yield column, hint
        end
      else
        self.to_enum __callee__
      end
    end

    def do_layout
      @layout.do_layout each_visible_column_with_hint, self.bounds
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

        @data_cache.each(@offset) do |row|
          draw_row rect_row, row if rect_row.bottom > rect.top
          rect_row.offset_by 0, rect_row.height
          break if rect_row.y > rect.bottom
        end

        cairo.set_source_rgb 0.3, 0.3, 0.3 # pseudo
        @columns.each do |column|
          cairo.move_to column.x, rect.top
          cairo.line_to column.x, rect.bottom
          cairo.stroke
        end
      end
    end

    def draw_row(rect, row)
      column_rect = rect.dup
      @columns.each do |column|
        column_rect.x = column.x
        column_rect.width = column.width
        column.draw_value cairo, column_rect, row[column.key]
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
