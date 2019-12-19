# coding: utf-8
require 'bundler/setup'
require 'miw'
require 'miw/window'
require 'miw/scroll_view'
require 'miw/text_view'
require 'miw/layout/box'

if __FILE__ == $0

  w = MiW::Window.new("test", 10, 10, 400, 400, layout: MiW::Layout::HBox)
  def w.quit_requested
    p :quit_requested
    EM.stop_event_loop
  end

  sv = MiW::ScrollView.new("sv")
  w.add_child sv, resize: [true, true]

  dir = File.dirname(__FILE__)
  text = File.read(dir + "/../lib/miw/text_view.rb")

  v = MiW::TextView.new("text_view_0")
  v.set_text text
  sv.target = v

  w.show
  MiW.run
end
