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

      2.times do |j|
        submenu = MiW::Menu.new "submenu 1"
        10.times do |i|
          submenu.add_item "item #{j}-#{i}"
        end
        popup.add_submenu "submenu #{j}", submenu
      end

      x, y = MiW.get_mouse
      popup.go x, y
    end
  end

  m = MiW::MenuBar.new "menu_bar"

  file_menu = MiW::Menu.new "file_menu"
  file_menu.add_item "Open ..."
  file_menu.add_item "Save ..."
  file_menu.add_item "Save as ..."
  file_menu.add_separator_item

  2.times do |j|
    submenu = MiW::Menu.new "submenu 1"
    10.times do |i|
      submenu.add_item "item #{j}-#{i}"
    end
    file_menu.add_submenu "submenu #{j}", submenu
  end

  file_menu.add_item "fuga"

  edit_menu = MiW::Menu.new "edit"
  edit_menu.add_item "Cut"
  edit_menu.add_item "Copy"
  edit_menu.add_item "Paste"

  m.add_item MiW::MenuItem.new "File", submenu: file_menu
  m.add_item MiW::MenuItem.new "Edit", submenu: edit_menu
  m.add_separator_item
  m.add_item MiW::MenuItem.new "hoge"
  w.add_child m, resize: [true, false]
  m.show

  v.show
  w.add_child v, resize: [true, true]

  w.show
  MiW.run
end
