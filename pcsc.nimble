# Package

version       = "0.1.0"
author        = "mmlado"
description   = "Thin + ergonomic Nim bindings for PC/SC (winscard / pcsc‑lite) "
license       = "MIT"
srcDir        = "src"
installDirs   = @["src"]      # install only the library sources
skipDirs      = @["examples", "tests"]  # don’t install these
bin           = @[]

# Dependencies

requires "nim >= 1.6.14"

repository   = "https://github.com/mmlado/pcsc-nim"

task list_readers, "Run list_readers example":
  exec "nim c -r examples/list_readers.nim"

task transmit_apdu, "Run transmit_apdu example":
  exec "nim c -r examples/transmit_apdu.nim"