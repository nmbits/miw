require 'miw/model/data_set'

module MiW
  module Util
    class DirectoryDataSet
      STAT_ATTRIBUTES =  [
        :dev, :dev_major, :dev_minor, :ino, :mode, :nlink,
        :uid, :gid, :rdev, :rdev_major, :rdev_minor,
        :size, :blksize, :blocks, :atime, :mtime, :ctime
      ]
      ROW_ATTRIBUTES = [:parent, :id, :node, :name]
      VALID_ATTRIBUTES = STAT_ATTRIBUTES + ROW_ATTRIBUTES
      S_IFDIR = 0040000
      def initialize(path = "/")
        @path = File.absolute_path path
      end

      def tree?
        true
      end

      def read_only?
        true
      end

      def group?(item)
        (item[:mode] & S_IFDIR) != 0 ? true : false
      end

      def count(filter = nil)
        dir = (filter && filter[:parent]) || @path
        answer = 0
        Dir.open dir do |d|
          answer = d.each_child.count
        end
        answer
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

      def get(offset, limit, filter = nil)
        parent = (filter && filter[:parent])
        order = (filter && filter[:order]) || :name

        dir = parent ? parent : @path

        abs_path = File.absolute_path dir

        array = nil
        Dir.open(abs_path) do |d|
          array = d.each_child.map{|path| path_to_hash File.join(abs_path, path)}
        end
        array.sort!{|h1, h2| h1[order] <=> h2[order]}
        array[offset, limit]
      end
    end
  end
end
