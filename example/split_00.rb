require 'bundler/setup'
require 'miw'

if __FILE__ == $0

  orientation = ARGV[0] == 'vertical' ? :vertical : :horizontal

  w = MiW::Window.new("menu", 10, 10, 400, 400, layout: MiW::Layout::VBox)
  def w.quit_requested
    p :quit_requested
    EM.stop_event_loop
  end

  v = MiW::SplitView.new "split", orientation: orientation
  v1 = MiW::TextView.new "text1"
  v1.resize_to 50, 50
  v1.set_text "1"
  v2 = MiW::TextView.new "text2"
  v2.resize_to 50, 50
  v2.min_size = MiW::Size.new(20, 20)
  v2.set_text "2"
  v3 = MiW::TextView.new "text3"
  v3.resize_to 50, 50
  v3.min_size = MiW::Size.new(20, 20)
  v3.max_size = MiW::Size.new(100, 100)
  v3.set_text "3"

  resize_hint = orientation == :vertical ? [true, false] : [false, true]
  v.add_child v1, resize: resize_hint
  v.add_child v2, resize: [true, true]
  v.add_child v3, resize: resize_hint
  w.add_child v, resize: [true, true]

  w.show
  MiW.run

end
