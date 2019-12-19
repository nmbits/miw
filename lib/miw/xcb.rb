
require 'miw_ext.so'
require 'eventmachine'

module MiW
  module XCB
    setup
    module FDWatcher
      def notify_readable
        XCB.process_event
      end
    end
    def self.setup_for_em
      fd = XCB.file_descriptor
      c = EM.watch fd, FDWatcher
      c.notify_readable = true
    end
  end
end
