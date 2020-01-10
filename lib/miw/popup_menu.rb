require 'miw/window.rb'
require 'miw/menu.rb'
require 'miw/layout/box.rb'

require 'pp'

module MiW
  class PopupMenu < Menu
    def show
      super
      unless attached?
        follow_cursor
        w = Window.new "popup_#{name}", x, y, 1, 1, layout: Layout::HBox, type: :popup_menu
        w.add_child self, resize: [true, true]
        size = preferred_size
        w.resize_to size.width, size.height
        w.show
      end
    end

    def hide
      if attached?
        window.hide
      end
    end

    def follow_cursor
      x, y = MiW.get_mouse
      if attached?
        window.move_to x, y
      else
        offset_to x, y
      end
    end

    def mouse_up(*a)
      super
      hide
    end
  end
end
