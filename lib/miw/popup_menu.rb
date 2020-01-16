require 'miw/popup_menu_window.rb'
require 'miw/menu.rb'
require 'miw/layout/box.rb'

require 'pp'

module MiW
  class PopupMenu < Menu
    def go(x, y)
      show
      unless attached?
        PopupMenuWindow.new(self, x, y).show unless attached?
      end
    end

    def hide
      window.hide if attached?
    end

    def mouse_up(x, y, button, state)
      super
      hide if button == 1
    end
  end
end
