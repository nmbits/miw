
module MiW
  module Util
    class DirectoryQuery
      STAT_ATTRIBUTES =  [
        :dev, :dev_major, :dev_minor, :ino, :mode, :nlink,
        :uid, :gid, :rdev, :rdev_major, :rdev_minor,
        :size, :blksize, :blocks, :atime, :mtime, :ctime
      ]
      ROW_ATTRIBUTES = [:parent, :id, :node, :name]
      VALID_ATTRIBUTES = STAT_ATTRIBUTES + ROW_ATTRIBUTES
      def initialize(**opts)
        @opts = opts
      end

      def order(*columns)
        DirectoryQuery.new order: columns, **@opts
      end

      def limit(limit, offset = nil)
        if offset
          DirectoryQuery.new limit: limit, offset: offset, **@opts
        else
          DirectoryQuery.new limit: limit, **@opts
        end
      end

      def offset(offset)
        DirectoryQuery.new offset: offset, **@opts
      end

      def where(cond)
        DirectoryQuery.new condition: cond, **@opts
      end

      def path_to_hash(path)
        hash = {}
        stat = File.lstat path
        STAT_ATTRIBUTES.each do |sym|
          hash[sym] = stat.__send__ sym
        end
        hash[:id] = path
        hash[:name] = File.basename(path)
        hash
      end

      def query
        cond = @opts[:condition]
        if cond.nil?
          raise "No condition specified."
        end
        parent = cond[:parent]
        id = cond[:id]

        if id
          return [] if parent && File.dirname(id) != parent
          return [path_to_hash(id)]
        end

        raise "id or parent required" unless parent

        abs_path = File.absolute_path parent
        pattern = File.join abs_path, "*"

        array = Dir.glob(pattern).map! do |path|
          path_to_hash File.join(path)
        end
        if @opts[:order]
          array.sort! do |h1, h2|
            r = 0
            @opts[:order].find do |c|
              r = (h1[c] <=> h2[c])
              r != 0
            end
            r
          end
        end
        limit = @opts[:limit] || array.length
        offset = @opts[:offset] || 0
        if offset > 0 || limit < array.length
          array[offset, limit]
        else
          array
        end
      end

      def all
        query
      end

      def first
        all.first
      end

      def count
        all.count
      end
    end
  end
end

if __FILE__ == $0
  require 'miw/util/query_tree'
  d = MiW::Util::DirectoryQuery.new
  # q = d.order(:mtime)

  r = MiW::Util::QueryTree::Root.new d, "/", order: :name
  r.open(0)
  r.open(2)
  r.open(4)
  r.each do |item|
    pp item.values_at(:id, :name, :mtime)
  end
end
