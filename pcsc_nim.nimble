# Package

version       = "0.1.0"
author        = "mmlado"
description   = "Thin + ergonomic Nim bindings for PC/SC (winscard / pcsc‑lite) "
license       = "MIT"
srcDir        = "src"
bin           = @["examples/list_readers", "examples/transmit_apdu"]

# Dependencies

requires "nim >= 1.6.14"
