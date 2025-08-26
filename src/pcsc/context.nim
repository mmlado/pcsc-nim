# src/pcsc/context.nim
## High-level wrapper for PC/SC context management.
## Establishing and releasing contexts, listing readers.

import std/strutils
import ./core
import ./errors

type
  ## Represents an active PC/SC context (connection to the resource manager).
  PcscContext* = object
    handle*: SCARDCONTEXT

# -----------------------
# Context management
# -----------------------

proc establishContext*(scope: DWORD = SCARD_SCOPE_SYSTEM): PcscContext {.raises: [PcscError].} =
  ## Establish a PC/SC context with the given scope.
  var ctx: SCARDCONTEXT
  let res = SCardEstablishContext(scope, nil, nil, addr ctx)
  raiseIfError(res, "SCardEstablishContext failed")
  result.handle = ctx

proc release*(ctx: var PcscContext) =
  ## Release a previously established context.
  if ctx.handle != 0:
    let res = SCardReleaseContext(ctx.handle)
    raiseIfError(res, "SCardReleaseContext failed")
    ctx.handle = 0

# -----------------------
# Reader listing
# -----------------------

proc listReaders*(ctx: PcscContext): seq[string] {.raises: [PcscError].} =
  ## List available smart card readers.
  var needed: DWORD
  # First call with nil to get required buffer size
  var res = SCardListReaders(ctx.handle, nil, nil, addr needed)
  raiseIfError(res, "SCardListReaders (size query) failed")

  # Allocate buffer
  var buf = newString(int(needed))
  res = SCardListReaders(ctx.handle, nil, buf.cstring, addr needed)
  raiseIfError(res, "SCardListReaders (fetch) failed")

  # Buffer is MULTI_SZ (NUL-separated, double-NUL terminated)
  let trimmed = buf[0 ..< int(needed)]
  for reader in trimmed.split('\0'):
    if reader.len > 0:
      result.add(reader)
