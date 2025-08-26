## High-level wrapper for connecting to cards and transmitting APDUs.

import ./core
import ./errors
import ./context

type
  PcscCard* = object
    handle*: SCARDHANDLE
    protocol*: DWORD
    ctx*: PcscContext

proc connect*(ctx: PcscContext, reader: string,
              share: DWORD = SCARD_SHARE_SHARED,
              prefer: DWORD = (SCARD_PROTOCOL_T0 or
                  SCARD_PROTOCOL_T1)): PcscCard =
  var h: SCARDHANDLE
  var active: DWORD
  raiseIfError SCardConnect(ctx.handle, reader.cstring, share, prefer, addr h,
      addr active), "SCardConnect"
  result.handle = h
  result.protocol = active
  result.ctx = ctx

proc disconnect*(c: var PcscCard, disposition: DWORD = SCARD_LEAVE_CARD) =
  if c.handle != SCARDHANDLE(0):
    discard SCardDisconnect(c.handle, disposition)
    c.handle = SCARDHANDLE(0)

# Strong, nil-safe transmit taking seq[byte]
proc transmit*(c: PcscCard, apdu: seq[byte], recvMax: int = 258): seq[byte] =
  let sendPci =
    case c.protocol
    of SCARD_PROTOCOL_T0: addr PCI_T0
    of SCARD_PROTOCOL_T1: addr PCI_T1
    of SCARD_PROTOCOL_RAW: addr PCI_RAW
    else: nil
  if sendPci.isNil: raise newException(ValueError, "Unsupported protocol: " & $c.protocol)

  let sendPtr = (if apdu.len > 0: unsafeAddr apdu[0] else: nil)
  let sendLen = DWORD(apdu.len)

  var recv = newSeq[byte](recvMax)
  var recvLen = DWORD(recv.len)
  let recvPtr = (if recv.len > 0: unsafeAddr recv[0] else: nil)

  raiseIfError SCardTransmit(c.handle, sendPci, sendPtr, sendLen, nil, recvPtr,
      addr recvLen), "SCardTransmit"
  recv.setLen(int(recvLen))
  recv




