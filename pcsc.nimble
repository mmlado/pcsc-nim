# Package

version       = "0.1.0"
author        = "mmlado"
description   = "Thin + ergonomic Nim bindings for PC/SC (winscard / pcsc‑lite) "
license       = "MIT"
srcDir        = "src"
installDirs   = @["src"]
skipDirs      = @["examples", "tests"]

# Dependencies

requires "nim >= 1.6.14"

task list_readers, "Run list_readers example":
  exec "nim c -r examples/list_readers.nim"

task transmit_apdu, "Run transmit_apdu example":
  exec "nim c -r examples/transmit_apdu.nim"

task clean, "Clean build artifacts":
  exec "rm -rf nimcache/"
  exec "rm -rf tests/nimcache/"
  exec "rm -rf examples/nimcache/"
  # Remove compiled binaries
  exec "rm -f tests/transport_test"
  exec "rm -f tests/select_test"
  exec "rm -f examples/example"