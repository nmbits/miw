require 'miw/view'
require 'miw/button'
require 'miw/layout/box'

module MiW
  class PanoramaView < View
    class ScrollButton < Button
      pi = Math::PI
      R = {top:    pi / 2 * 3, left:  pi,
           bottom: pi / 2,     right: 0  }.map do |k, v|
        d = pi / 3 * 2
        [k, [[Math.cos(v        ), Math.sin(v        )],
             [Math.cos(v + d    ), Math.sin(v + d    )],
             [Math.cos(v + d * 2), Math.sin(v + d * 2)]]]
      end.to_h

      def initialize(id, position: :top, **opts)
        super id, **opts
        @position = position
      end
      attr_reader :position

      def draw_forground(rect)
        r = [width, height].min / 2 * 0.8
        b = bounds
        cx = b.left + b.width / 2
        cy = b.top  + b.height / 2
        first = false
        cairo.new_path
        R[@position].each do |rx, ry|
          if first
            cairo.move_to cx + r * rx, cy + r * ry
            first = false
          else
            cairo.line_to cx + r * rx, cy + r * ry
          end
        end
        cairo.close_path
        cairo.set_source_color MiW.colors[:control_forground]
        cairo.fill
      end
    end

    def initialize(id, orientation: :horizontal, layout: nil, target: nil,
                   button_thickness: 16, **opts)
      case orientation
      when :vertical
        layout = MiW::Layout::VBox
        @button0 = ScrollButton.new "#{id}_button0", position: :top
        @button1 = ScrollButton.new "#{id}_button1", position: :bottom
        @button0.resize_to 0, button_thickness
        @button1.resize_to 0, button_thickness
        button_resize = [true, false]
      when :horizontal
        layout = MiW::Layout::HBox
        @button0 = ScrollButton.new "#{id}_button0", position: :left
        @button1 = ScrollButton.new "#{id}_button1", position: :right
        @button0.resize_to button_thickness, 0
        @button1.resize_to button_thickness, 0
        button_resize = [false, true]
      else
        raise ArgumentError, "orientation should be :vertical or :horizontal"
      end
      @orientation = orientation
      @button_thickness = button_thickness
      super id, layout: layout, **opts
      add_child @button0, resize: button_resize
      add_child @button1, resize: button_resize
      set_target target, resize: [true, true] if target
    end

    def set_target(view, hints = {})
      return if view == @target
      if view
        if view.parent
          if view.parent != self
            raise ArgumentError, "The view is already a member of another view"
          end
        else
          @target = view
          add_child view, hints
        end
      end
    end

    def remove_child(child)
      raise ArgumentError, "invalid id" if @scroll_bars.find{|k, v| child.id == v.id }
      set_target nil if @target && child == @target
      super
    end

    def adjust
      return unless @target
      b = @target.bounds
      e = @target.extent
      bn = b.to_a
      en = e.to_a
      o = @orientation == :vertical ? 1 : 0
      s = o + 2
      if @button0.visible?
        if bn[o] <= en[o] + @button_thickness
          bn[o] = en[o]
          @button0.hide
        end
      else
        if bn[o] >= en[o]
          bn[o] += @button_thickness
          @button0.show
        end
      end
      if @button1.visible?
        if bn[o] + bn[s] >= en[o] + en[s] - @button_thickness
          @button1.hide
        end
      else
        if bn[o] + bn[s] < en[o] + en[s] - @button_thickness
          @button1.show
        end
      end
      @target.scroll_to bn[0], bn[1]
    end

    def all_attached
      adjust
      do_layout
    end

    def frame_resized(x, y)
      adjust
      do_layout
    end

    def receive(from, what, *args)
      return unless @target
      if what == :clicked && (from == @button0 || from == @button1)
        scroll_target from.position
        do_layout
      end
    end

    def scroll_target(pos)
      return unless @target
      b = @target.bounds
      e = @target.extent
      case pos
      when :top
        o = 1
        offset = - b.height / 3
      when :left
        o = 0
        offset = - b.width / 3
      when :bottom
        o = 1
        offset = b.height / 3
      when :right
        o = 0
        offset = b.width / 3
      end
      s = o + 2
      bn  = b.to_a
      en  = e.to_a
      n = bn[o] + offset
      case pos
      when :top, :left
        n = en[o] if n < en[o]
      when :bottom, :right
        if n + bn[s] > en[o] + en[s] - @button_thickness
          n = en[o] + en[s] - bn[s] - @button_thickness
        end
      end
      case pos
      when :left, :right
        @target.scroll_to n, b.y
      when :top, :bottom
        @target.scroll_to b.x, n
      end
      adjust
    end

    def do_layout
      b = bounds
      rect = b.dup
      [@button0, @button1].each do |button|
        if button.visible?
          if @orientation == :vertical
            button.resize_to width, @button_thickness
            rect.height -= button.height
          else
            button.resize_to @button_thickness, height
            rect.width -= button.width
          end
        end
      end
      if @button0.visible?
        if @orientation == :vertical
          rect.y += @button0.height
        else
          rect.x += @button0.width
        end
      end
      except = [@button0.id, @button1.id]
      @layout&.do_layout each_visible_child_with_hint(except: except), rect
      if @button0.visible?
        @button0.offset_to b.x, b.y
      end
      if @button1.visible?
        if @orientation == :vertical
          @button1.offset_to b.x, rect.bottom
        else
          @button1.offset_to rect.right, b.y
        end
      end
    end
  end
end
