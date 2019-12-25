
require 'pango'

module MiW
  module Theme
    class Fonts
      def initialize(name)
        @name = name
        @fonts = {}
      end

      def []=(font_name, font_desc_string)
        desc = Pango::FontDescription.new font_desc_string
        raise "Invalid font" unless desc.family
        @fonts[font_name] = desc
      end

      def [](font_name)
        @fonts[font_name]
      end
    end
  end
end
