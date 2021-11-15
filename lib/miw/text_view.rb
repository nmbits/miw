require 'miw'
require 'miw/view'
require 'miw/keysym'
require 'miw/model/text_buffer'
require 'pango'

module MiW
  class TextView < View
    def initialize(id, font: nil, **opts)
      super
      @layouts = []
      @top_linum = 0
      @visible_lines = 0
      @buffer = MiW::Model::TextBuffer.new
      @cursor = 0
      self.font = font || MiW.fonts[:monospace]
    end

    def set_text(text)
      text ||= ""
      @buffer.clear
      @buffer.insert 0, text
      @cursor = 0
      trigger :extent_changed
      trigger :view_port_changed
    end

    def insert(text, offset = nil)
    end

    def delete(start_offset = nil, end_offset = nil)
    end

    def text(offset = nil, length = nil)
    end

    def text_length
    end

    def count_lines
      @buffer.count_lines
    end

    def current_line
    end

    def go_to_line
    end

    def cut
    end

    def copy
    end

    def paste
    end

    def clear
    end

    def select(start_offset, end_offset)
    end

    def select_all()
    end

    def selection
    end

    def line_at(point_or_offset)
    end

    def offset_at(point_or_offset)
    end

    def extent
      Rectangle.new 0, 0, 100, @buffer.count_lines
    end

    def view_port
      Rectangle.new 0, @top_linum, 100, @visible_lines
    end

    # cursor motion

    def move_cursor(dir)
      case dir
      when :right
        if @cursor < @buffer.length
          @cursor = @buffer.adjust @cursor + 1, :forward
          @column = nil
        end
      when :left
        if @cursor > 0
          @cursor = @buffer.adjust @cursor - 1, :backward
          @column = nil
        end
      when :up
        cur_line_head = @buffer.beginning_of_line @cursor
        return if cur_line_head == 0
        target_line_head = @buffer.beginning_of_line cur_line_head - 1
        eol_size = @buffer.eol == :dos ? 2 : 1
        target_line_length = cur_line_head - target_line_head - eol_size
        col = (@column ||= @cursor - cur_line_head)
        if col > target_line_length
          col = target_line_length
        end
        @cursor = target_line_head + col
      when :down
        cur_line_head = @buffer.beginning_of_line @cursor
        target_line_head = @buffer.next_line @cursor
        return unless target_line_head
        eol_size = @buffer.eol == :dos ? 2 : 1
        target_line_end = @buffer.end_of_line target_line_head
        target_line_length = target_line_end - target_line_head
        col = (@column ||= @cursor - cur_line_head)
        if col > target_line_length
          col = target_line_length
        end
        @cursor = target_line_head + col
      end
      follow_cursor
    end

    def backspace
      if @cursor > 0
        new_cursor = @buffer.adjust @cursor - 1, :backward
        len = @cursor - new_cursor
        @buffer.delete(new_cursor, len)
        @cursor = new_cursor
        @column = nil
        update_pango_layout_all
        invalidate
      end
    end

    #################################
    # Hooks

    def draw(rect)
      cs = MiW.colors
      cairo.save do
        cairo.rectangle 0, 0, width + 1, height + 1
        cairo.clip
        update_pango_layout_all if @layouts.empty?
        fill_rect(cs, rect)
        draw_text(cs, rect)
        draw_cursor(cs, @cursor)
      end
    end

    def key_down(key, modifier)
      case key
      when KeySym::LEFT
        move_cursor :left
      when KeySym::RIGHT
        move_cursor :right
      when KeySym::UP
        move_cursor :up
      when KeySym::DOWN
        move_cursor :down
      when KeySym::ENTER
        @buffer.insert @cursor, "\n"
        update_pango_layout_all
        trigger :extent_changed
        @cursor += 1
        follow_cursor
      when KeySym::BACKSPACE
        backspace
        trigger :extent_changed
        follow_cursor
      when 0..0x100
        c = key.chr
        @buffer.insert @cursor, c
        update_pango_layout_all
        @cursor += 1
      else
        p key.to_s(16)
      end
      invalidate
    end

    def mouse_down(x, y, *_)
      make_focus true
      cur = 10 # pseudo
      row = nil
      @layouts.each_with_index do |layout, i|
        width, height = layout.pixel_size
        if y < cur + height
          row = i
          break
        end
        cur += height
      end
      if row
        linum = @top_linum + row
        layout = @layouts[row]
        lx = x
        ly = y - cur
        ans = layout.xy_to_index(lx * Pango::SCALE, ly * Pango::SCALE)
        inside, index, trailing = ans
        @cursor = @buffer.line_to_pos(linum) + index
        follow_cursor
        invalidate
      end
    end

    def frame_resized(width, height)
      if window
        update_pango_layout_all
        trigger :view_port_changed
      end
    end

    def scroll_to(x, y)
      @top_linum = [0, y].max
      update_pango_layout_all
    end

    private

    def update_pango_layout_all
      if cairo
        @visible_lines = 0
        @layouts = []
        cy = 0
        (@top_linum ... @buffer.count_lines).each do |linum|
          index = @buffer.line_to_pos(linum)
          len = @buffer.end_of_line(index) - index
          layout = cairo.create_pango_layout
          layout.font_description = font
          text = @buffer[index, len]
          layout.text = text
          @layouts << layout
          @visible_lines += 1
          cy += layout.pixel_size[1]
          break if cy >= self.height
        end
        invalidate
      end
    end

    def fill_rect(cs, rect)
      cairo.rectangle rect.x, rect.y, rect.width + 1, rect.height + 1
      cairo.set_source_color cs[:content_background]
      cairo.fill
    end

    def draw_text(cs, rect)
      cx = cy = 0
      @layouts.each_with_index do |layout, i|
        width, height = layout.pixel_size
        layout_rect = Rectangle.new(cx, cy, width, height)
        if rect.dup.intersect(layout_rect).valid?
          fill_rect(cs, layout_rect)
          cairo.set_source_color cs[:content_forground]
          cairo.move_to cx, cy
          cairo.show_pango_layout layout
        end
        cy += height
      end
    end

    def draw_cursor(cs, index)
      linum = @buffer.pos_to_line index
      line_index = @buffer.line_to_pos linum
      rindex = index - line_index
      row = linum - @top_linum
      cx = cy = 0
      @layouts.each_with_index do |layout, i|
        if i == row
          strong_pos, weak_pos = layout.get_cursor_pos(rindex)
          cairo.set_source_color cs[:content_forground]
          cx = strong_pos.x / Pango::SCALE
          cy = strong_pos.y / Pango::SCALE + cy
          cairo.move_to cx, cy
          cairo.line_to cx, cy + strong_pos.height / Pango::SCALE
          cairo.stroke
          break
        end
        _, height = layout.pixel_size
        cy += height
      end
    end

    def follow_cursor
      linum = @buffer.pos_to_line @cursor
      if linum < @top_linum
        scroll_to 0, linum - @visible_lines / 2
        trigger :view_port_changed
      elsif linum >= @top_linum + @visible_lines
        scroll_to 0, @top_linum + @visible_lines / 2
        trigger :view_port_changed
      end
    end
  end
end
