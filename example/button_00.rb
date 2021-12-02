require 'bundler/setup'
require 'miw'
require 'miw/button'

if __FILE__ == $0
  w = MiW::Window.new("menu", 10, 10, 400, 400, layout: MiW::Layout::VBox)
  def w.quit_requested
    p :quit_requested
    EM.stop_event_loop
  end

  b = MiW::Button.new :button, size: MiW::Size.new(100, 100)

  w.add_child b, resize: [false, false], min_size: [10, 10]
  w.show
  MiW.run
end
