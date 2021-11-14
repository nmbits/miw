require 'miw'
require 'miw/layout/box'
require 'miw/scrollable'
require 'miw/util/cache_map'

module MiW
  class TableView < View
    include Scrollable
    autoload :TextColumn,  "miw/table_view/text_column"
    autoload :VisualState, "miw/table_view/visual_state"
    autoload :DataSet,     "miw/table_view/data_set"

    MARGIN_RATIO = 1.4   # pseudo
    DEFAULT_WIDTH = 80
    DEFAULT_ALIGN = :left
    PAGE_SIZE = 50

    def initialize(id, dataset: nil, tree_mode: false, show_label: false, **opts)
      super id, layout: Layout::HBox, **opts
      @columns = []
      @tree_mode = tree_mode
      @mod = 0
      @show_label = show_label
      @columns_layout = Layout::HBox.new
      @current = 0
      @cache = Util::Cache.new(10)
      @vs = VisualState.new
      add_observer self
      initialize_scrollable false, true
      self.dataset = dataset
    end
    attr_reader :show_label

    def add_column(column)
      @columns << column
    end

    def dataset=(dataset)
      @dataset = dataset
      @vs.reset_count @dataset.count
      @vs.set_root_data Hash.new
    end

    def extent
      Rectangle.new 0, 0, 100, @vs.count * row_height
    end

    def view_port
      if @show_label
        Rectangle.new 0, @current * row_height, 100, height - row_height
      else
        Rectangle.new 0, @current * row_height, 100, height
      end
    end

    def scroll_to(x, y)
      if row_height > 0
        @current = y / row_height
        @mod = y % row_height
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

        rect_item = Rectangle.new rect.x, rect.y - @mod, rect.width, row_height
        prev_subtree = nil
        prev_page = nil
        items = nil
        @vs.each(@current) do |state, subtree, sindex|
          if prev_subtree != subtree
            prev_subtree = subtree
            prev_page = nil
          end
          page = sindex / PAGE_SIZE
          if page != prev_page
            prev_page = page
            items = nil
          end
          unless items
            cache = (subtree.data[:cache] ||= Util::CacheMap.new(@cache))
            items = cache[page]
          end
          unless items
            parent = subtree.data[:parent]
            items = @dataset.get page * PAGE_SIZE, PAGE_SIZE, {parent: parent}
            cache[page] = items
          end
          rindex = sindex % PAGE_SIZE
          item = items[rindex]

          draw_item rect_item, item, state, subtree.level
          rect_item.y += row_height
          break if rect_item.y > rect.bottom
        end
      end
    end

    def draw_item(rect, item, state, level)
      column_rect = rect.dup
      @columns.each_with_index do |column, i|
        column_rect.x = column.x
        column_rect.width = column.width
        if i == 0
          expander_width = rect.height            # TODO
          if @dataset.group? item
            triangle_width = (expander_width * 0.75).to_i  # TODO
            if state == :opened
              x = column_rect.x + (expander_width - triangle_width) / 2
              y = column_rect.y + triangle_width / 2
              cairo.move_to  x, y
              cairo.triangle x,                      y,
                             x + triangle_width    , y,
                             x + triangle_width / 2, y + triangle_width / 2
            else   # closed
              x = column_rect.x + expander_width / 2
              y = column_rect.y + (expander_width - triangle_width) / 2
              cairo.move_to x, y
              cairo.triangle x,                      y,
                             x + triangle_width / 2, y + triangle_width / 2,
                             x,                      y + triangle_width
            end
            cairo.fill
          end
          column_rect.x     += expander_width
          column_rect.width -= expander_width
        end
        column.draw cairo, column_rect, item
      end
      cairo.set_source_rgb 0.3, 0.3, 0.3 # pseudo
      cairo.move_to rect.left, rect.bottom
      cairo.line_to rect.right, rect.bottom
      cairo.stroke
    end
  end
end
