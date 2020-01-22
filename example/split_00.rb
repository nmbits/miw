require 'bundler/setup'
require 'miw'
require 'miw/window'
require 'miw/split_view'
require 'miw/text_view'

if __FILE__ == $0

  w = MiW::Window.new("menu", 10, 10, 400, 400, layout: MiW::Layout::VBox)
  def w.quit_requested
    p :quit_requested
    EM.stop_event_loop
  end

  v = MiW::SplitView.new "split"
  v1 = MiW::TextView.new "text1"
  v1.resize_to 50, 1
  v1.set_text "1"
  v2 = MiW::TextView.new "text2"
  v2.resize_to 50, 1
  v1.set_text "2"
  v3 = MiW::TextView.new "text3"
  v3.resize_to 50, 1
  v1.set_text "3"
  v.add_child v1, resize: [false, true]
  v.add_child v2, resize: [true, true]
  v.add_child v3, resize: [false, true]
  w.add_child v, resize: [true, true]

  w.show
  MiW.run

end
