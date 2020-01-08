require 'miw/window.rb'
require 'miw/menu.rb'
require 'miw/layout/box.rb'

require 'pp'

module MiW
  class PopupMenu < Menu
    def go(x, y)
      unless attached?
        win = Window.new("popup", x, y, 1, 1, layout: Layout::HBox, type: :popup_menu)
        win.add_child self, resize: [true, true]
        self.show
        size = preferred_size
        win.resize_to size.width, size.height
        win.show
      end
    end

    def mouse_up(*a)
      window.set_tracking nil
      window.hide # pseudo
    end

    def mouse_down(*a)
    end
  end
end
