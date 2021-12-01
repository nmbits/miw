require 'observer'
require 'fiddle'

module MiW
  module Model
    class TextBuffer
      include Observable

      module UTF8
        MASK_1B = 0x80
        BITS_1B = 0x00
        MASK_MB = 0xc0
        BITS_MB = 0x80
        MASK_2B = 0xe0
        BITS_2B = 0xc0
        MASK_3B = 0xf0
        BITS_3B = 0xe0
        MASK_4B = 0xf8
        BITS_4B = 0xf0

        def self.middle?(c)
          (c & MASK_MB) == BITS_MB
        end
      end

      LIBC = Fiddle::Handle.new "libc.so.6"
      MEMMOVE = Fiddle::Function.new LIBC['memmove'],
                                     [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T],
                                     Fiddle::TYPE_VOIDP
      MEMCHR = Fiddle::Function.new LIBC['memchr'],
                                    [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_SIZE_T],
                                    Fiddle::TYPE_VOIDP
      MEMRCHR = Fiddle::Function.new LIBC['memrchr'],
                                     [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_SIZE_T],
                                     Fiddle::TYPE_VOIDP
      RUBY_XFREE = Fiddle::Function.new(Fiddle::RUBY_FREE, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)

      ALLOC_UNIT = 400
      CR = 0x0d
      LF = 0x0a
      VALID_EOL = [:unix, :dos, :mac]

      def initialize(text = nil, eol = :unix)
        raise ArgumentError, "eol should be :unix, :dos or :mac" unless VALID_EOL.include? eol
        @eol = eol
        allocate_memory
        insert 0, text if text
      end

      attr_reader :eol

      def eol_string
        case @eol
        when :unix
          "\n"
        when :dos
          "\r\n"
        when :mac
          "\r"
        end
      end

      def capacity
        @memory.size
      end

      def length
        @memory.size - @gap_length
      end

      def insert(cur, str)
        size = str.bytesize
        return if size == 0
        eols = str.scan(eol_string).size
        move_gap cur
        extend_gap size if @gap_length < size
        MEMMOVE.call(@memory + @gap_begin, str, size)
        @gap_begin += size
        @gap_length -= size
        if @linum_cache_cur > cur
          @linum_cache_cur = 0
          @linum_cache_linum = 0
        end
        @count_lines += eols
        changed
        notify_observers
        nil
      end

      def delete(cur, len)
        return if len > self.length
        return if self.length - cur < len
        eols = count_eols(cur, len)
        @count_lines -= eols
        move_gap cur
        @gap_length += len
        shrink_gap
        if @linum_cache_cur > cur
          @linum_cache_cur = 0
          @linum_cache_linum = 0
        end
        changed
        notify_observers
        nil
      end

      def clear
        allocate_memory
        changed
        notify_observers
      end

      def [](arg0, len = nil)
        case arg0
        when Range
          raise ArgumentError, "too many arguments" unless len == nil
          return nil if arg0.max.nil? || arg0.min.nil?
          len = arg0.max - arg0.min + 1
          pos = arg0.first
        when Integer
          if len
            raise TypeError, "argument 1 should be an Integer" unless Integer === len
            return nil if len < 0
          end
          pos = arg0
        else
          raise TypeError, "argument 0 should be an Integer"
        end
        raise RangeError, "out of range" if pos > self.length
        if len
          raise RangeError, "out of range" if pos + len > self.length
          buffer = "\0" * len
          buffer_ptr = Fiddle::Pointer[buffer]
          if pos < @gap_begin
            l = (pos + len < @gap_begin ? len : @gap_begin - pos)
            MEMMOVE.call(buffer_ptr, @memory + pos, l)
            len -= l
            pos = @gap_begin
            buffer_ptr += l
          end
          if len > 0
            MEMMOVE.call(buffer_ptr, @memory + pos + @gap_length, len)
          end
          buffer
        else
          getbyte(pos)
        end
      end

      def getbyte(pos)
        pos < @gap_begin ? @memory[pos] : @memory[pos + @gap_length]        
      end

      def end_of_line(cur)
        raise RangeError, "out of range" if cur < 0 || cur > length
        c = (@eol == :mac ? CR : LF)
        max = length
        case @eol
        when :mac, :unix
          index(c, cur)
        else
          while cur < max && (result = index LF, cur)
            break result - 1 if result > 0 && getbyte(result - 1) == CR
            cur = result + 1
          end
        end || max
      end

      def beginning_of_line(cur)
        raise RangeError, "out of range" if cur < 0 || cur > length
        c = (@eol == :mac ? CR : LF)
        case @eol
        when :mac, :unix
          (result = rindex c, cur) && (result + 1)
        else
          while cur > 1 && (result = rindex LF, cur)
            break result + 1 if result > 0 && getbyte(result - 1) == CR
            cur = result - 1
          end
        end || 0
      end

      def next_line(cur)
        eol_size = @eol == :dos ? 2 : 1
        eol_cur = end_of_line(cur)
        if eol_cur != length
          eol_cur + eol_size
        else
          nil
        end
      end

      def count_eols(cur, len = nil, eol = @eol)
        raise RangeError, "out of range" if cur < 0 || cur > length
        if len
          raise RangeError, "out of range" if cur + len > length
        else
          len = length - cur
        end
        answer = 0
        c = (eol == :mac ? CR : LF)
        max = cur + len
        min = cur
        while cur < max
          n = index c, cur, len
          break unless n && ((eol != :dos) || (n > min && (getbyte(n - 1) == CR)))
          answer += 1
          cur = n + 1
          len = max - cur
        end
        answer
      end

      def count_lines
        @count_lines
      end

      def line_to_pos(linum)
        raise RangeError, "out of range" if linum < 0
        eol_size = (@eol == :dos ? 2 : 1)
        if linum <= @linum_cache_linum / 2
          cur = 0
          count = linum
        else
          cur = @linum_cache_cur
          count = linum - @linum_cache_linum
        end
        while count > 0
          cur = next_line(cur)
          break unless cur
          count -= 1
        end
        while count < 0 && cur > 0
          cur = beginning_of_line(cur - 1)
          count += 1
        end
        return nil unless count == 0
        @linum_cache_linum = linum
        @linum_cache_cur = cur
        cur
      end

      def pos_to_line(cur)
        raise RangeError, "out of range" if cur < 0 || cur > length
        if cur <= @linum_cache_cur / 2
          count_eols(0, cur)
        elsif cur < @linum_cache_cur
          len = @linum_cache_cur - cur
          @linum_cache_linum - count_eols(cur, len)
        else
          len = cur - @linum_cache_cur
          @linum_cache_linum + count_eols(@linum_cache_cur, len)
        end
      end

      def adjust(pos, dir = :forward)
        raise RangeError, "out of range" if pos < 0 || pos > length
        case dir
        when :forward
          enum = (pos...length).each
          default = length
        when :backward
          return length if pos == length
          enum = (0..pos).reverse_each
          default = 0
        else
          raise ArgumentError, "dir should be :forward or :backward"
        end
        enum.find do |i|
          c = getbyte i
          if UTF8.middle?(c) ||
             (@eol == :dos && c == LF && i > 0 && getbyte(i - 1) == CR)
            false
          else
            true
          end
        end || default
      end

      private

      def allocate_memory
        addr = Fiddle.malloc ALLOC_UNIT
        @memory = Fiddle::Pointer.new addr, ALLOC_UNIT, RUBY_XFREE
        @gap_begin = 0
        @gap_length = ALLOC_UNIT
        @linum_cache_linum = 0
        @linum_cache_cur = 0
        @count_lines = 1
      end

      def realloc(size)
        address = Fiddle.realloc @memory.to_i, size
        if @memory.to_i == address
          @memory.size = size
        else
          @memory.free = nil
          @memory = Fiddle::Pointer.new address, size, RUBY_XFREE
        end
        nil
      end

      def memmove(dst, src, len)
        MEMMOVE.call(@memory + dst, @memory + src, len)
      end

      def memchr(raw, c, n)
        result = MEMCHR.call(@memory + raw, c, n)
        result.null? ? nil : result.to_i - @memory.to_i
      end

      def memrchr(raw, c, n)
        result = MEMRCHR.call(@memory + raw, c, n)
        result.null? ? nil : result.to_i - @memory.to_i
      end

      def move_gap(to)
        raise RangeError, "out of range" if length < to
        if to < @gap_begin
          len = @gap_begin - to
          dst = @gap_begin + @gap_length - len
          src = to
        else
          len = to - @gap_begin
          dst = @gap_begin
          src = @gap_begin + @gap_length
        end
        memmove(dst, src, len) if len > 0
        @gap_begin = to
        nil
      end

      def extend_gap(min)
        if @gap_length < min
          move_length = @memory.size - @gap_begin - @gap_length
          new_gap_length = min + ALLOC_UNIT
          new_capacity = @memory.size - @gap_length + new_gap_length
          new_capacity
          realloc(new_capacity)
          src = @gap_begin + @gap_length
          dst = @gap_begin + new_gap_length
          memmove(dst, src, move_length)
          @gap_length = new_gap_length
        end
        nil
      end

      def shrink_gap
        if @gap_length >= ALLOC_UNIT * 2
          new_gap_length = ALLOC_UNIT
          new_capacity = @memory.size - @gap_length + new_gap_length
          src = @gap_begin + @gap_length
          dst = @gap_begin + new_gap_length
          move_length = @memory.size - src
          memmove(dst, src, move_length)
          realloc(new_capacity)
          @gap_length = new_gap_length
        end
        nil
      end

      def index(chr, cur = 0, len = length)
        if cur < @gap_begin
          slen = [@gap_begin - cur, len].min
          raw = memchr cur, chr, slen
          return raw if raw
          cur += slen
          len -= slen
        end
        cur += @gap_length
        slen = [capacity - cur, len].min
        raw = memchr cur, chr, slen
        raw && (raw - @gap_length)
      end

      def rindex(chr, cur = length, len = length)
        if cur >= @gap_begin
          slen = [cur - @gap_begin, len].min
          raw = memrchr cur - slen + @gap_length, chr, slen
          return raw - @gap_length if raw
          cur = @gap_begin
          len -= slen
        end
        slen = [cur, len].min
        memrchr cur - slen, chr, slen
      end
    end
  end
end
