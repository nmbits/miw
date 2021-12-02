require 'miw/abstract_button'

module MiW
  class Button < AbstractButton
    def draw(rect)
      draw_background rect
      draw_forground rect
    end

    def draw_background(rect)
      b = bounds
      cs = MiW.colors
      bgcolor = @active ? cs[:control_background_highlight] : cs[:control_background]
      fgcolor = @active ? cs[:control_forground_highlight] : cs[:control_forground]
      cairo.set_source_color bgcolor
      cairo.rectangle b.x, b.y, b.width, b.height
      cairo.fill_preserve
      cairo.set_source_color fgcolor
      cairo.stroke
    end

    def draw_forground(rect)
    end

    def pressed
      @active = true
      invalidate
      p :pressed
    end

    def released
      @active = false
      invalidate
      p :released
    end

    def clicked
      @active = false
      invalidate
      p :clicked
    end

    def entered
      p :entered
    end

    def exited
      p :exited
    end
  end
end
