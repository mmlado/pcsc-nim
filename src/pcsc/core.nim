when defined(windows):
  const libpcsc* = "winscard.dll"
  {.pragma: pcscall, stdcall, dynlib: libpcsc.}
elif defined(macosx):
  const libpcsc* = "/System/Library/Frameworks/PCSC.framework/PCSC"
  {.pragma: pcscall, dynlib: libpcsc.}
else:
  const libpcsc* = "libpcsclite.so.1"
  {.pragma: pcscall, cdecl, dynlib: libpcsc.}

type
  DWORD* = uint32
  LONG* = int32
  # Pointer-sized handles (works on 64-bit)
  SCARDCONTEXT* = uint
  SCARDHANDLE* = uint

  SCARD_IO_REQUEST* {.bycopy.} = object
    dwProtocol*: DWORD
    cbPciLength*: DWORD

# PC/SC constants (DWORD/u32)
const
  SCARD_S_SUCCESS* = LONG(0)
  SCARD_SCOPE_USER* = DWORD(0)
  SCARD_SCOPE_SYSTEM* = DWORD(2)
  SCARD_SHARE_EXCLUSIVE* = DWORD(1)
  SCARD_SHARE_SHARED* = DWORD(2)
  SCARD_PROTOCOL_T0* = DWORD(1)
  SCARD_PROTOCOL_T1* = DWORD(2)
  SCARD_PROTOCOL_RAW* = DWORD(4)
  SCARD_LEAVE_CARD* = DWORD(0)
  SCARD_RESET_CARD* = DWORD(1)
  SCARD_UNPOWER_CARD* = DWORD(2)

# FFI procs
proc SCardEstablishContext*(dwScope: DWORD, pv1, pv2: pointer,
    ph: ptr SCARDCONTEXT): LONG {.importc: "SCardEstablishContext", pcscall.}
proc SCardReleaseContext*(h: SCARDCONTEXT): LONG {.importc: "SCardReleaseContext", pcscall.}
when defined(windows):
  proc SCardListReaders*(h: SCARDCONTEXT, groups, readers: cstring,
      pLen: ptr DWORD): LONG {.importc: "SCardListReadersA", pcscall.}
  proc SCardConnect*(h: SCARDCONTEXT, reader: cstring, share, proto: DWORD,
      pCard: ptr SCARDHANDLE,
      pActive: ptr DWORD): LONG {.importc: "SCardConnectA", pcscall.}
else:
  proc SCardListReaders*(h: SCARDCONTEXT, groups, readers: cstring,
      pLen: ptr DWORD): LONG {.importc: "SCardListReaders", pcscall.}
  proc SCardConnect*(h: SCARDCONTEXT, reader: cstring, share, proto: DWORD,
      pCard: ptr SCARDHANDLE,
      pActive: ptr DWORD): LONG {.importc: "SCardConnect", pcscall.}
proc SCardDisconnect*(card: SCARDHANDLE,
    disposition: DWORD): LONG {.importc: "SCardDisconnect", pcscall.}
proc SCardTransmit*(card: SCARDHANDLE, pioSendPci: pointer, sendBuf: pointer, sendLen: DWORD,
                    pioRecvPci: pointer, recvBuf: pointer,
                        pRecvLen: ptr DWORD): LONG {.importc: "SCardTransmit", pcscall.}

# Use *local* PCI structs (addressable everywhere)
var
  PCI_T0*: SCARD_IO_REQUEST = SCARD_IO_REQUEST(dwProtocol: SCARD_PROTOCOL_T0,
      cbPciLength: DWORD sizeof(SCARD_IO_REQUEST))
  PCI_T1*: SCARD_IO_REQUEST = SCARD_IO_REQUEST(dwProtocol: SCARD_PROTOCOL_T1,
      cbPciLength: DWORD sizeof(SCARD_IO_REQUEST))
  PCI_RAW*: SCARD_IO_REQUEST = SCARD_IO_REQUEST(dwProtocol: SCARD_PROTOCOL_RAW,
      cbPciLength: DWORD sizeof(SCARD_IO_REQUEST))
