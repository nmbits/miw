require 'miw'
require 'miw/menu_item'

module MiW
  class Menu < View
    def initialize(name, **opts)
      super
      @items = []
    end
    attr_reader :items

    def add_item(item)
      @items << item
    end

    def add_separator_item
    end
  end
end
