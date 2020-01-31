require "miw/layout"
require "miw/size"

module MiW
  module Layout
    class Box
      RESIZE_DEFAULT = [false, false].freeze
      WEIGHT_DEFAULT = [100, 100].freeze
      MIN_SIZE_DEFAULT = [0, 0].freeze
      MAX_SIZE_DEFAULT = [Float::INFINITY, Float::INFINITY].freeze

      def initialize(dir = 0, spacing = 0)
        @dir = dir
        @spacing = spacing
      end
      attr_accessor :spacing

      def do_layout(container, rect)
        Box.resize_items(container, rect, @dir, @spacing)
        Box.move_items(container, rect, @dir, @spacing)
      end

      def self.resize_items(container, rect, dir, spacing)
        odir = dir ^ 1
        size = [rect.width, rect.height]
        extent = size[dir]

        count_resize_items = 0

        count_items = 0
        weight_total = 0

        tmp_size = [0, 0]

        # pass 1:
        container.each do |item, hint|
          count_items += 1
          tmp_size[0] = item.width
          tmp_size[1] = item.height
          extent -= tmp_size[dir]

          resize = hint[:resize] || RESIZE_DEFAULT
          weight = hint[:weight] || WEIGHT_DEFAULT
          min_size = hint[:min_size] || MIN_SIZE_DEFAULT

          if resize[dir]
            count_resize_items += 1
          else
            r = tmp_size[dir] - min_size[dir]
            weight_total += weight[dir]
            if resize[odir]
              tmp_size[odir] = size[odir]
              item.resize_to *tmp_size
            end
          end
        end
        return if count_items == 0

        count_fixed_items = count_items - count_resize_items
        extent -= spacing * (count_items - 1)

        # pass 2:
        if count_resize_items > 0
          sign = (extent <=> 0)

          recalc = false
          distr = extent.abs / count_resize_items
          rem = extent.abs % count_resize_items
          container.each do |item, hint|
            resize = hint[:resize] || RESIZE_DEFAULT
            next unless resize[dir]
            tmp_size[0] = item.width
            tmp_size[1] = item.height
            min_size = hint[:min_size] || MIN_SIZE_DEFAULT
            max_size = hint[:max_size] || MAX_SIZE_DEFAULT
            if recalc
              distr = extent.abs / count_resize_items
              rem = extent.abs % count_resize_items
              recalc = false
            end

            sz = tmp_size[dir] + distr * sign
            if rem > 0
              sz += sign
              rem -= 1
            end
            szr = [[sz, min_size[dir]].max, max_size[dir]].min
            recalc = (szr != sz)
            extent -= szr - tmp_size[dir]

            tmp_size[dir] = szr
            tmp_size[odir] = size[odir] if resize[odir]
            item.resize_to *tmp_size
            count_resize_items -= 1
          end
        end

        # pass 3:
        if extent < 0
          container.each do |item, hint|
            resize = hint[:resize] || RESIZE_DEFAULT
            next if resize[dir]
            tmp_size[0] = item.width
            tmp_size[1] = item.height
            min_size = hint[:min_size] || MIN_SIZE_DEFAULT
            w = (hint[:weight] || WEIGHT_DEFAULT)[dir]
            distr = extent.abs * w / weight_total
            sz = tmp_size[dir] - distr
            szr = [sz, min_size[dir]].max
            tmp_size[dir] = szr
            extent += szr
            item.resize_to *tmp_size
            break unless extent < 0
          end
        end
      end

      def self.move_items(container, rect, dir, spacing)
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
          pos[dir] += tmp_size[dir] + spacing
        end
      end
    end

    class HBox < Box
      def initialize(spacing = 0)
        super 0, spacing
      end
    end

    class VBox < Box
      def initialize(spacing = 0)
        super 1, spacing
      end
    end
  end # module Layout
end # module MiW
