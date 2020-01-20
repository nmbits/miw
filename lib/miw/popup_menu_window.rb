
require 'miw/menu_window'
require 'miw/layout/box'

module MiW
  class PopupMenuWindow < MenuWindow
    def initialize(popup_menu, x, y)
      super popup_menu, x, y, :popup_menu
    end

    def shown
      super
      menu.start_menuing
    end
  end
end
