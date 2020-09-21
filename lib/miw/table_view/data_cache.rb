
module MiW
  class TableView
    class DataCache
      DEFAULT_PAGE_SIZE = 4096
      def initialize(query, page_size = DEFAULT_PAGE_SIZE)
        @query = query
        @pages = {}
        @page_size = page_size
      end
      attr_reader :dataset

      def reset
        @pages = {}
      end

      def count
        @query.count
      end

      def each(offset = 0)
        if block_given?
          page_offset = offset % @page_size
          page_index = offset / @page_size
          loop do
            page = (@pages[page_index] ||= @query.get(page_index * @page_size, @page_size))
            break if page.empty?
            while page_offset < page.length
              yield page[page_offset]
              page_offset += 1
            end
            page_offset = 0
            page_index += 1
          end
        else
          enum_for :each, offset
        end
      end
    end
  end
end
