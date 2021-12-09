require 'bundler/setup'
require 'miw'
require 'miw/panorama_view'
require 'miw/wide_container'
require 'miw/resizer_view'
require 'miw/button'

if __FILE__ == $0
  w = MiW::Window.new "test", 10, 10, 400, 400, layout: MiW::Layout::VBox
  w.title = "scroll view"
  def w.quit_requested
    p :quit_requested
    EM.stop_event_loop
  end
  
  wc = MiW::WideContainer.new :container, orientation: :vertical

  10.times do |i|
    v = MiW::StringView.new "text#{i}".to_sym, size: MiW::Size.new(0, 40),
                            string: "String #{i}"
    wc.add_child v, resize: [true, false]
  end

  pv = MiW::PanoramaView.new :panorama, orientation: :vertical
  pv.set_target wc, resize: [true, true]

  w.add_child pv, resize: [true, true]
  w.show
  MiW.run
end
