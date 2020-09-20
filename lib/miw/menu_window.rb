
require 'miw/window'

module MiW
  class MenuWindow < Window
    def initialize(menu, x, y, type)
      title = "__window__#{menu.id}"
      super title, x, y, 1, 1, layout: Layout::VBox, type: type
      add_child menu, resize: [true, true]
      menu.show
      @menu = menu
    end
    attr_reader :menu

    def shown
      size = menu.resize_to_preferred
      resize_to size.width, size.height
    end
  end
end
