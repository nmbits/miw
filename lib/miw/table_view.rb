require 'miw'
require 'miw/layout/box'
require 'miw/scrollable'

module MiW
  class TableView < View
    include Scrollable
    autoload :DataCache, "miw/table_view/data_cache"
    autoload :TextColumn, "miw/table_view/text_column"

    MARGIN_RATIO = 1.4   # pseudo
    DEFAULT_WIDTH = 80
    DEFAULT_ALIGN = :left
    def initialize(id, query: nil, tree_mode: false, show_label: false, **opts)
      super id, layout: Layout::HBox, **opts
      @offset = 0
      @columns = []
      @tree_mode = tree_mode
      @mod = 0
      @show_label = show_label
      @columns_layout = Layout::HBox.new
      self.query = query
      add_observer self
      initialize_scrollable false, true
    end
    attr_reader :show_label

    def add_column(column)
      @columns << column
    end

    def query=(query)
      @data_cache = DataCache.new query
    end

    def extent
      Rectangle.new 0, 0, 100, @data_cache.count * row_height
    end

    def view_port
      if @show_label
        Rectangle.new 0, @offset * row_height, 100, height - row_height
      else
        Rectangle.new 0, @offset * row_height, 100, height
      end
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

    def scroll_bars_rect
      rect = bounds
      if @show_label
        rect.height -= row_height
        rect.y += row_height
      end
      rect
    end

    def frame_resized(width, height)
      trigger :extent_changed
      trigger :view_port_changed
    end

    def each_visible_columns
      @columns.each
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
      super
      @columns_layout.do_layout each_visible_column_with_hint, self.bounds
    end

    def draw(rect)
      if show_label
        rect_label = Rectangle.new 0, 0, width, row_height
        rect_rows = Rectangle.new 0, row_height, width, rect.height - row_height
      else
        rect_rows = rect
      end
      draw_labels rect_label if show_label
      draw_rows rect_rows
      cairo.save do
        cairo.set_source_rgb 0.3, 0.3, 0.3 # pseudo
        @columns.each do |column|
          cairo.move_to column.x, rect.top
          cairo.line_to column.x, rect.bottom
          cairo.stroke
        end
      end
    end

    def draw_labels(rect)
      cairo.save do
        cairo.rectangle rect.x, rect.y, rect.width, rect.height
        cairo.clip true
        cairo.set_source_color MiW.colors[:control_background]
        cairo.fill
        column_rect = rect.dup
        @columns.each do |column|
          column_rect.x = column.x
          column_rect.width = column.width
          column.draw_label cairo, column_rect
        end
        cairo.set_source_rgb 0.3, 0.3, 0.3 # pseudo
        cairo.move_to rect.left, rect.bottom
        cairo.line_to rect.right, rect.bottom
        cairo.stroke
      end
    end

    def draw_rows(rect)
      cairo.save do
        cairo.rectangle rect.x, rect.y, rect.width, rect.height
        cairo.clip true
        cairo.set_source_color MiW.colors[:control_background]
        cairo.fill

        rect_row = Rectangle.new rect.x, rect.y - @mod, rect.width, row_height
        @data_cache.each(@offset) do |row|
          draw_row rect_row, row
          rect_row.y += row_height
          break if rect_row.y > rect.bottom
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
      cairo.set_source_rgb 0.3, 0.3, 0.3 # pseudo
      cairo.move_to rect.left, rect.bottom
      cairo.line_to rect.right, rect.bottom
      cairo.stroke
    end
  end
end
