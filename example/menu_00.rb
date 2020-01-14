# coding: utf-8

require 'bundler/setup'
require 'miw'
require 'miw/window'
require 'miw/menu'
require 'miw/menu_item'
require 'miw/popup_menu'
require 'miw/menu_bar'

if __FILE__ == $0

  w = MiW::Window.new("menu", 10, 10, 400, 400, layout: MiW::Layout::VBox)
  def w.quit_requested
    p :quit_requested
    EM.stop_event_loop
  end

  class Observer
    def item_selected(menu, item)
      puts "#{item.label} selected"
    end
  end

  v = MiW::View.new "view"
  def v.mouse_down(x, y, button, state, count)
    if button == 3
      popup = MiW::PopupMenu.new("popup")
      popup.add_item "Open ..."
      item = popup.add_item "Save ..."
      item.enable = false
      popup.add_item "Save as ..."
      popup.add_separator_item
      popup.add_item "閉じる"
      popup.show
    end
  end

  m = MiW::MenuBar.new "menu_bar"
  m.add_item MiW::MenuItem.new("File")
  m.add_item MiW::MenuItem.new("Edit")
  m.add_separator_item
  m.add_item MiW::MenuItem.new("hoge")
  w.add_child m, resize: [true, false]
  m.show

  v.show
  w.add_child v, resize: [true, true]

  w.show
  MiW.run
end
