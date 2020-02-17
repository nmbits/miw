require 'miw'

module MiW
  class TableView < View
    ColumnDef = Struct.new :key, :display_name, :width, :align

    def initialize(name, dataset: nil, **opts)
      super name, **opts
      @dataset = dataset
      @offset = 0
      @column_defs = []
    end
    attr_reader :dataset

    def add_column_def(key, display_name, width = 80, align = :left) # pseudo
      @column_defs << ColumnDef.new(key, display_name, width, align)
    end

    def dataset=(d)
      @dataset = d
    end

    def extent
      # pseudo
      Rectangle.new 0, 0, 100, @dataset.size
    end

    def view_port
      Rectangle.new 0, @offset, 100, @visible_lines
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
      @column_defs.each do |coldef|
        value = raw[coldef.key]
        panl.text = value.to_s
        cairo.move_to x, y
        cairo.show_pango_layout panl
        w, h = panl.pixel_size
        x += coldef.width
        max_height = [h, max_height].max
        # cairo.move_to x, by
        # cairo.line_to x, by + max_height
        # cairo.stroke
      end
      # cairo.move_to bx, by + max_height
      # cairo.line_to x, by + max_height
      # cairo.stroke
      max_height
    end
  end
end