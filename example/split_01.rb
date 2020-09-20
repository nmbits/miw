require 'bundler/setup'
require 'miw'

if __FILE__ == $0

  orientation = ARGV[0] == 'vertical' ? :vertical : :horizontal

  w = MiW::Window.new("menu", 10, 10, 400, 400, layout: MiW::Layout::VBox)
  def w.quit_requested
    p :quit_requested
    EM.stop_event_loop
  end

  v = MiW::SplitView.new :split, orientation: orientation

  8.times do |i|
    t = MiW::TextView.new "text_#{i}".to_sym
    t.set_text i.to_s
    resize = if i.even?
               [true, true]
             elsif orientation == :vertical
               [true, false]
             else
               [false, true]
             end
    max_size = i % 4 == 2 ? [Float::INFINITY, Float::INFINITY] : [100, 100]
    v.add_child t, resize: resize, min_size: [20, 20], max_size: max_size
  end

  w.add_child v, resize: [true, true]
  w.show
  MiW.run

end
