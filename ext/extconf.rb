require 'mkmf'

if have_library("xcb") &&
   have_library("cairo") &&
   have_library("xkbcommon") &&
   have_library("xkbcommon-x11")
  create_makefile "miw_ext"
end
