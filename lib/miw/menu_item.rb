
module MiW
  class MenuItem
    def initialize(label, shortcut: nil)
      @label = label
      @shortcut = shortcut
    end
    attr_reader :label
  end
end
