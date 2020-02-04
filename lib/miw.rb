require 'eventmachine'
require 'cairo'

module MiW
  autoload :KeySym,          "miw/keysym"
  autoload :Layout,          "miw/layout"
  autoload :Menu,            "miw/menu"
  autoload :MenuBar,         "miw/menu_bar"
  autoload :MenuItem,        "miw/menu_item"
  autoload :MenuWindow,      "miw/menu_window"
  autoload :Model,           "miw/model"
  autoload :MouseHandler,    "miw/mouse_handler"
  autoload :Pointe,          "miw/point"
  autoload :PopupMenu,       "miw/popup_menu"
  autoload :PopupMenuWindow, "miw/popup_menu_window"
  autoload :Rectangle,       "miw/rectangle"
  autoload :ScrollBar,       "miw/scroll_bar"
  autoload :ScrollView,      "miw/scroll_view"
  autoload :SeparatorItem,   "miw/separator_item"
  autoload :Size,            "miw/size"
  autoload :SplitView,       "miw/split_view"
  autoload :StringView,      "miw/string_view"
  autoload :TextView,        "miw/text_view"
  autoload :Theme,           "miw/theme"
  autoload :Util,            "miw/util"
  autoload :View,            "miw/view"
  autoload :Window,          "miw/window"
  autoload :XCB,             "miw/xcb"

  MiW::PLATFORM = MiW::XCB

  MOUSE_BUTTON_LEFT   = 1
  MOUSE_BUTTON_CENTER = 2
  MOUSE_BUTTON_RIGHT  = 3
  MOUSE_WHEEL_UP      = 4
  MOUSE_WHEEL_DOWN    = 5
  MOUSE_STATE_SHIFT   = 1
  MOUSE_STATE_CTRL    = 4

  def self.run
    if EM.reactor_running?
      MiW::PLATFORM.setup_for_em
    else
      EM.run { MiW::PLATFORM.setup_for_em }
    end
  end

  def self.get_mouse
    PLATFORM.get_mouse
  end

  colors = Theme::Colors.new("default")
  colors[:content_background]           = "#111"
  colors[:content_background_highlight] = "#9ff"
  colors[:content_background_active]    = "#4ff"
  colors[:content_background_disabled]  = "#eee"

  colors[:content_forground]           = "#bbb"
  colors[:content_forground_highlight] = "#bbb"
  colors[:content_forground_active]    = "#bbb"
  colors[:content_forground_disabled]  = "#bbb"

  colors[:control_background]           = "#333"
  colors[:control_background_highlight] = "#777"
  colors[:control_background_active]    = "#669"
  colors[:control_background_disabled]  = "#555"

  colors[:control_forground]           = "#888"
  colors[:control_forground_highlight] = "#444"
  colors[:control_forground_active]    = "#bbb"
  colors[:control_forground_disabled]  = "#666"

  colors[:control_border]           = "#000"
  colors[:control_border_highlight] = "#ccc"
  colors[:control_border_active]    = "#000"
  colors[:control_border_disabled]  = "#000"

  colors[:control_inner_background]           = "#111"
  colors[:control_inner_background_highlight] = "#222"
  colors[:control_inner_background_active]    = "#111"
  colors[:control_inner_background_disabled]  = "#555"

  colors[:control_inner_forground]           = "#000"
  colors[:control_inner_forground_highlight] = "#000"
  colors[:control_inner_forground_active]    = "#000"
  colors[:control_inner_forground_disabled]  = "#888"

  colors[:control_inner_border]           = "#000"
  colors[:control_inner_border_highlight] = "#ccc"
  colors[:control_inner_border_active]    = "#000"
  colors[:control_inner_border_disabled]  = "#000"

  DEFAULT_COLORS = colors

  fonts = Theme::Fonts.new("default")
  fonts[:monospace] = "monospace 11"
  fonts[:document] = "sans-serif 11"
  fonts[:ui] = "sans-serif 11"

  DEFAULT_FONTS = fonts

  # pseudo
  def self.colors
    DEFAULT_COLORS
  end

  def self.fonts
    DEFAULT_FONTS
  end
end
