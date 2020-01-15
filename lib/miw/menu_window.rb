
require 'miw/window'

module MiW
  class MenuWindow < Window
    def initialize(menu, type: nil)
      name = "__window__#{menu.name}"
      super name, 0, 0, 1, 1, layout: Layout::VBox, type: type
      @menu = menu
    end
    attr_reader :menu

    def shown
      add_child menu, resize: [true, true]
      size = menu.resize_to_preferred
      resize_to size.width, size.height
    end
  end
end
