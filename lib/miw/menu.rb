require 'miw'
require 'miw/menu_item'

module MiW
  class Menu < View
    def initialize(name, font: nil, **opts)
      super
      @items = []
      self.font = (font || MiW.fonts[:ui])
    end
    attr_reader :items

    def add_item(item)
      @items << item
    end

    def add_separator_item
    end
  end
end
