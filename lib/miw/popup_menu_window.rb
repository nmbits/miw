
require 'miw/menu_window'
require 'miw/layout/box'

module MiW
  class PopupMenuWindow < MenuWindow
    def initialize(popup_menu)
      super popup_menu, type: :popup_menu
    end

    def shown
      super
      follow_cursor
      grab_pointer
      set_tracking menu
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
