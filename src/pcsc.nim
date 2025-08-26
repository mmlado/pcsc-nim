## Umbrella module — import this for the full SDK.

# import ./pcsc/core
# import ./pcsc/errors
# import ./pcsc/context
# import ./pcsc/card
# import ./pcsc/util

# export core, errors, context, card, util

# src/pscsc.nim
# ----------------
# Single‑file library: low‑level FFI + small, idiomatic high‑level wrapper.
# Works on Windows (winscard.dll), Linux (libpcsclite.so.1), macOS (PCSC.framework).
import std/strutils

when defined(windows):
  const pcsclib* = "winscard.dll"
  {.pragma: pcscall, stdcall, dynlib: pcsclib.}
elif defined(macosx):
  const pcsclib* = "PCSC"
  {.pragma: pcscall, dynlib: pcsclib.}
else:
  const pcsclib* = "libpcsclite.so.1"
  {.pragma: pcscall, dynlib: pcsclib.}

# ---------- C types ----------
type
  DWORD* = uint32
  LONG*  = int32
  SCARDCONTEXT* = uint   # ULONG_PTR in WinAPI; pointer‑sized
  SCARDHANDLE*  = uint   # ULONG_PTR

  SCARD_IO_REQUEST* = object
    dwProtocol*: DWORD
    cbPciLength*: DWORD

# ---------- Constants (subset) ----------
const
  SCARD_S_SUCCESS* = LONG(0)

  # Scopes
  SCARD_SCOPE_USER*    = DWORD(0)
  SCARD_SCOPE_SYSTEM*  = DWORD(2)

  # Share modes
  SCARD_SHARE_EXCLUSIVE* = DWORD(1)
  SCARD_SHARE_SHARED*    = DWORD(2)
  SCARD_SHARE_DIRECT*    = DWORD(3)

  # Protocols
  SCARD_PROTOCOL_T0*   = DWORD(1)
  SCARD_PROTOCOL_T1*   = DWORD(2)
  SCARD_PROTOCOL_RAW*  = DWORD(4)

  # Disconnect actions
  SCARD_LEAVE_CARD*   = DWORD(0)
  SCARD_RESET_CARD*   = DWORD(1)
  SCARD_UNPOWER_CARD* = DWORD(2)
  SCARD_EJECT_CARD*   = DWORD(3)

# Some notable error codes (extend as needed)
const
  SCARD_F_INTERNAL_ERROR*   = -2146435071'i32
  SCARD_E_CANCELLED*        = -2146435070'i32
  SCARD_E_INVALID_HANDLE*   = -2146435068'i32
  SCARD_E_INVALID_PARAMETER* = -2146435067'i32
  SCARD_E_INVALID_TARGET*   = -2146435066'i32
  SCARD_E_NO_MEMORY*        = -2146435065'i32
  SCARD_F_WAITED_TOO_LONG*  = -2146435064'i32
  SCARD_E_INSUFFICIENT_BUFFER* = -2146435063'i32
  SCARD_E_UNKNOWN_READER*   = -2146435062'i32
  SCARD_E_TIMEOUT*          = -2146435061'i32
  SCARD_E_SHARING_VIOLATION* = -2146435054'i32
  SCARD_E_NO_SMARTCARD*     = -2146435053'i32
  SCARD_E_PROTO_MISMATCH*   = -2146435050'i32
  SCARD_E_NOT_READY*        = -2146435052'i32
  SCARD_W_RESET_CARD*       = -2146435043'i32

# ---------- Imported PC/SC functions ----------
proc SCardEstablishContext*(dwScope: DWORD, pvReserved1: pointer, pvReserved2: pointer, phContext: ptr SCARDCONTEXT): LONG
  {.importc, pcscall.}
proc SCardReleaseContext*(hContext: SCARDCONTEXT): LONG {.importc, pcscall.}
proc SCardListReaders*(hContext: SCARDCONTEXT, mszGroups: cstring, mszReaders: cstring, pcchReaders: ptr DWORD): LONG {.importc, pcscall.}
proc SCardConnect*(hContext: SCARDCONTEXT, szReader: cstring, dwShareMode: DWORD, dwPreferredProtocols: DWORD, phCard: ptr SCARDHANDLE, pdwActiveProtocol: ptr DWORD): LONG {.importc, pcscall.}
proc SCardDisconnect*(hCard: SCARDHANDLE, dwDisposition: DWORD): LONG {.importc, pcscall.}
proc SCardTransmit*(hCard: SCARDHANDLE, pioSendPci: pointer, pbSendBuffer: pointer, cbSendLength: DWORD, pioRecvPci: pointer, pbRecvBuffer: pointer, pcbRecvLength: ptr DWORD): LONG {.importc, pcscall.}

# PC/SC exports pointers to prebuilt SCARD_IO_REQUEST structs for each protocol.
# We import them as variables.
var SCARD_PCI_T0_STRUCT*: SCARD_IO_REQUEST = SCARD_IO_REQUEST(
  dwProtocol: SCARD_PROTOCOL_T0,
  cbPciLength: sizeof(SCARD_IO_REQUEST).uint32
)

var SCARD_PCI_T1_STRUCT*: SCARD_IO_REQUEST = SCARD_IO_REQUEST(
  dwProtocol: SCARD_PROTOCOL_T1,
  cbPciLength: sizeof(SCARD_IO_REQUEST).uint32
)

var SCARD_PCI_RAW_STRUCT*: SCARD_IO_REQUEST = SCARD_IO_REQUEST(
  dwProtocol: SCARD_PROTOCOL_RAW,
  cbPciLength: sizeof(SCARD_IO_REQUEST).uint32
)

# ---------- Error handling ----------


type
  PcscError* = object of CatchableError

proc `$`*(e: PcscError): string =
  result = e.msg


proc raiseIfErr(code: LONG, ctx = ""): void =
  if code != SCARD_S_SUCCESS:
    var m = ctx
    if m.len > 0: m.add ": "
    m.add "PC/SC error " & $code
    raise newException(PcscError, m)

# ---------- Utility helpers ----------
proc parseMsz*(s: string): seq[string] =
  ## Parse a multi‑string (char** packed, NUL‑separated, double‑NUL terminated)
  ## returned by SCardListReaders. Filters out empty tail.
  for part in s.split('\0'):
    if part.len > 0: result.add part

# ---------- High‑level API ----------
type
  PcscContext* = object
    h*: SCARDCONTEXT

  Card* = object
    h*: SCARDHANDLE
    activeProto*: DWORD

proc establishContext*(scope: DWORD = SCARD_SCOPE_SYSTEM): PcscContext =
  var ctx: SCARDCONTEXT
  raiseIfErr SCardEstablishContext(scope, nil, nil, addr ctx), "SCardEstablishContext"
  result.h = ctx

proc `=destroy`*(c: var PcscContext) =
  if c.h != 0'u:
    discard SCardReleaseContext(c.h)
    c.h = 0'u

proc listReaders*(c: PcscContext): seq[string] =
  var needed: DWORD
  # First call to get required length
  let rc1 = SCardListReaders(c.h, nil, nil, addr needed)
  if rc1 == SCARD_E_NO_MEMORY or needed == 0'u32:
    return @[]
  raiseIfErr rc1, "SCardListReaders(size)"
  var buf = newString(int(needed))
  raiseIfErr SCardListReaders(c.h, nil, buf.cstring, addr needed), "SCardListReaders(buf)"
  result = parseMsz(buf)

proc connect*(c: PcscContext, reader: string, share: DWORD = SCARD_SHARE_SHARED, prefer: DWORD = (SCARD_PROTOCOL_T0 or SCARD_PROTOCOL_T1)): Card =
  var h: SCARDHANDLE
  var active: DWORD
  raiseIfErr SCardConnect(c.h, reader.cstring, share, prefer, addr h, addr active), "SCardConnect"
  result.h = h
  result.activeProto = active


proc `=destroy`*(k: var Card) =
  if k.h != 0'u:
    discard SCardDisconnect(k.h, SCARD_LEAVE_CARD)
    k.h = 0'u

proc sendPciPtr(proto: DWORD): ptr SCARD_IO_REQUEST =
  case proto
  of SCARD_PROTOCOL_T0: result = addr SCARD_PCI_T0_STRUCT
  of SCARD_PROTOCOL_T1: result = addr SCARD_PCI_T1_STRUCT
  of SCARD_PROTOCOL_RAW: result = addr SCARD_PCI_RAW_STRUCT
  else: result = nil


proc transmit*(k: Card, apdu: openArray[byte], recvMax: int = 258): seq[byte] =
  ## Transmit an APDU and return raw response bytes (including SW1 SW2).
  var recv = newSeq[byte](recvMax)
  var recvLen = DWORD(recv.len)
  let pci = sendPciPtr(k.activeProto)
  if pci.isNil:
    raise newException(PcscError, "Unsupported protocol for transmit: " & $k.activeProto)
  raiseIfErr SCardTransmit(
    k.h,
    pci,
    unsafeAddr apdu[0],
    DWORD(apdu.len),
    nil,
    unsafeAddr recv[0],
    addr recvLen
    ), "SCardTransmit"

  result = recv[0 ..< int(recvLen)]

proc transmitHex*(k: Card, apduHex: string, recvMax: int = 258): seq[byte] =
  ## Convenience: APDU as hex string like "00A4040000" (spaces allowed)
  var tmp: seq[byte] = @[]
  var acc = newSeq[char]()
  for ch in apduHex:
    if ch in {' ', '\t', '\n', '\r'}: continue
    acc.add ch
    if acc.len == 2:
      let b = parseHexInt("0x" & acc.join("")).uint8
      tmp.add byte(b)
      acc.setLen 0
  if acc.len != 0:
    raise newException(PcscError, "Odd number of hex digits in APDU")
  result = k.transmit(tmp, recvMax)

proc sw*(resp: openArray[byte]): tuple[sw1, sw2: byte] =
  if resp.len < 2: (0'u8, 0'u8) else: (resp[^2], resp[^1])

proc prettyHex*(data: openArray[byte]): string =
  for b in data:
    if result.len > 0: result.add ' '
    result.add $(b.int shr 4 and 0xF).toHex(1)
    result.add $(b.int and 0xF).toHex(1)

# ---------- Example (guarded) ----------
when isMainModule:
  try:
    let ctx = establishContext()
    let readers = ctx.listReaders()
    if readers.len == 0:
      echo "No readers found"
      quit 0
    echo "Readers:"; for r in readers: echo "  ", r
    let card = ctx.connect(readers[0])
    let resp = card.transmitHex("00 A4 04 00 08 A0 00 00 08 04 00 01 01")  # SELECT MF, safe no‑op
    echo "Response:", "\n  ", prettyHex(resp)
    let (sw1, sw2) = sw(resp)
    echo "SW1SW2: 0x", (sw1.int shl 8 or sw2.int).toHex(4)
  except PcscError as e:
    echo "PCSC failure: ", e.msg

# examples/list_readers.nim
# ----------------
# when compiled, run: `nim r examples/list_readers.nim`
#
# import pscsc
# let ctx = establishContext()
# for r in ctx.listReaders(): echo r
