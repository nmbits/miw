require 'miw/table_view/column'

module MiW
  class TableView
    class TextColumn < Column
      def draw(cairo, rect, item)
        cairo.save do
          value = item[key]
          cairo.set_source_color MiW.colors[:control_forground]
          panl = cairo.create_pango_layout
          panl.font_description = MiW.fonts[:ui]
          panl.text = value.to_s
          tw, th = panl.pixel_size
          cairo.rectangle rect.x, rect.y, rect.width, rect.height
          cairo.clip
          cairo.move_to rect.x, rect.y + (rect.height - th) / 2
          cairo.show_pango_layout panl
        end
      end
    end
  end
end
