
require 'bundler/setup'
require 'miw'
require 'miw/window'
require 'miw/menu'
require 'miw/menu_item'
require 'miw/popup_menu'

if __FILE__ == $0

  w = MiW::Window.new("menu", 10, 10, 400, 400, layout: MiW::Layout::VBox)
  def w.quit_requested
    p :quit_requested
    EM.stop_event_loop
  end

  popup = MiW::PopupMenu.new("popup")
  item = MiW::MenuItem.new("Open ...")
  popup.add_item item
  item = MiW::MenuItem.new("Save ...")
  popup.add_item item
  item = MiW::MenuItem.new("Save as ...")
  popup.add_item item
  popup.go 200, 200

  menu = MiW::Menu.new "menu00"
  w.add_child menu, resize: [true, true]

  item = MiW::MenuItem.new("Open ...")
  menu.add_item item
  item = MiW::MenuItem.new("Save ...")
  menu.add_item item
  item = MiW::MenuItem.new("Save as ...")
  menu.add_item item

  w.show
  MiW.run
end
