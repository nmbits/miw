require "miw/layout"
require "miw/size"

module MiW
  module Layout
    class Box
      def initialize(dir = 0)
        @dir = dir
        @spacing = 0
      end
      attr_accessor :spacing

      def do_layout(container, rect, dir = 0)
        resize_items(container, rect, dir)
        move_items(container, rect, dir)
      end

      private

      def resize_items(container, rect, dir)
        odir = dir ^ 1
        size = [rect.width, rect.height]
        extent = size[dir]

        pass2_items = []

        num_items = 0
        weight_total = 0
        
        tmp_size = [0, 0]
        container.each do |item, hint|
          num_items += 1
          tmp_size[0] = item.width
          tmp_size[1] = item.height
          if hint && hint[:resize]
            resize_dir = hint[:resize][dir]
            resize_odir = hint[:resize][odir]
          else
            resize_dir = resize_odir = false
          end
          if resize_dir
            weight = hint && hint[:weight] || 1.0
            weight = 0.001 if weight <= 0
            weight_total += weight
            pass2_items << [item, hint]
          else
            extent -= tmp_size[dir]
          end
          if !resize_dir
            tmp_size[odir] = size[odir] if resize_odir
            item.resize_to tmp_size[0], tmp_size[1]
          end
        end
        return if num_items == 0

        extent -= @spacing * (num_items - 1)
        pass2_items.each do |item, hint|
          weight = hint && hint[:weight] || 1.0
          tmp_size[0] = item.width
          tmp_size[1] = item.height
          if extent <= 0
            tmp_size[dir] = 0
          else
            ratio = weight.to_f / weight_total
            tmp_size[dir] = (extent * ratio).round.to_i
          end
          if hint && hint[:resize] && hint[:resize][odir]
            tmp_size[odir] = size[odir]
          end
          item.resize_to(tmp_size[0], tmp_size[1])
        end
      end

      def move_items(container, rect, dir)
        odir = dir ^ 1
        pos = [rect.x, rect.y]
        size = [rect.width, rect.height]
        left_top = pos.dup

        tmp_size = [0, 0]
        container.each do |item, hint|
          align_odir = hint && hint[:align] && hint[:align][odir] || :center
          tmp_size[0] = item.width
          tmp_size[1] = item.height
          case align_odir
          when :top
            pos[odir] = left_top[odir]
          when :bottom
            pos[odir] = left_top[odir] + size[odir] - tmp_size[odir]
          else
            pos[odir] = left_top[odir] + (size[odir] - tmp_size[odir]) / 2
          end
          item.offset_to pos[0], pos[1]
          pos[dir] += tmp_size[dir] + @spacing
        end
      end
    end

    class HBox < Box
      def do_layout(container, frame)
        super container, frame, 0
      end
    end

    class VBox < Box
      def do_layout(container, frame)
        super container, frame, 1
      end
    end
  end # module Layout
end # module MiW
