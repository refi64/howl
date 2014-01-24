-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'
require 'ljglibs.cdefs.gobject'
glib = require 'howl.cdefs.glib'

C = ffi.C

callback3 = (handler) ->
  ffi.cast('GCallback', ffi.cast('GCallback3', handler))

callback4 = (handler) ->
  ffi.cast('GCallback', ffi.cast('GCallback4', handler))

return {
  g_signal_connect3: (instance, signal, handler, data) ->
    C.g_signal_connect_data(instance, signal, callback3(handler), ffi.cast('gpointer', data), nil, 0)

  g_signal_connect4: (instance, signal, handler, data) ->
    C.g_signal_connect_data(instance, signal, callback4(handler), ffi.cast('gpointer', data), nil, 0)

}
