
require 'miw/menu_window'
require 'miw/layout/box'

module MiW
  class PopupMenuWindow < MenuWindow
    def initialize(popup_menu, x, y)
      super popup_menu, x, y, type: :popup_menu
    end

    def shown
      super
      grab_pointer
      set_tracking menu
    end

    def hidden
      set_tracking nil
      ungrab_pointer
    end
  end
end
