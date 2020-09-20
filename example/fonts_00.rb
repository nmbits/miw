# coding: utf-8
require 'bundler/setup'
require 'miw'

if __FILE__ == $0

  class PangoTest < MiW::View
    # https://developer.gnome.org/pango/stable/pango-Cairo-Rendering.html
    N_WORDS = 10
    FONT = "Sans Bold 27"

    def attached_to_window
      make_focus true
    end

    def mouse_down(x, y, button, state, count)
      case button
      when 4
        @scale += 0.05
      when 5
        @scale -= 0.05
      else
        @scale = 1.0
      end
      @scale = [[0.05, @scale].max, 3.0].min
      invalidate
    end

    def draw(rect)
      @scale ||= 1.0
      cairo.set_source_rgb 1.0, 1.0, 1.0
      cairo.paint
      cairo.scale @scale, @scale
      draw_text
    end

    def draw_text
      radius = [width, height].min / 2
      panl = pango_layout
      cairo.translate radius, radius
      panl.text = "Text"
      panl.font_description = FONT
      N_WORDS.times do |i|
        angle = 360.0 * i / N_WORDS
        cairo.save do
          red = (1 + Math.cos((angle - 60) * Math::PI / 180.0)) / 2
          cairo.set_source_rgb red, 0, 1.0 - red
          cairo.rotate angle * Math::PI / 180.0
          cairo.update_pango_layout panl
          w, _ = panl.pixel_size
          cairo.move_to(-w / 2.0, -radius)
          # cairo.move_to(-(width / Pango::SCALE) / 2.0, -radius)
          cairo.show_pango_layout panl
        end
      end
    end
  end

  w = MiW::Window.new "test", 10, 10, 400, 400, layout: MiW::Layout::HBox
  def w.quit_requested
    p :quit_requested
    EM.stop_event_loop
  end

  w.add_child PangoTest.new(:pango), resize: [true, true]

  w.show
  MiW.run
end
