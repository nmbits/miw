
require 'miw/window'
require 'miw/layout/box'

module MiW
  class PopupMenuWindow < Window
    def initialize(popup_menu)
      name = "__window__#{popup_menu}"
      super name, 0, 0, 1, 1, layout: Layout::VBox, type: :popup_menu
      @popup_menu = popup_menu
    end
    attr_reader :popup_menu

    def shown
      follow_cursor
      grab_pointer
      set_tracking @popup_menu
      add_child @popup_menu, resize: [true, true]
      size = popup_menu.resize_to_preferred
      resize_to size.width, size.height
    end

    def hidden
      set_tracking nil
      ungrab_pointer
    end

    def follow_cursor
      x, y = MiW.get_mouse
      move_to x, y
    end
  end
end
