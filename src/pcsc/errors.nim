# src/pcsc/errors.nim
## Error handling for PC/SC.
## Wraps raw error codes into Nim exceptions with readable messages.

import std/strutils
import ./core

# -----------------------
# Exception
# -----------------------

type
  PcscError* = ref object of CatchableError
    code*: LONG

# -----------------------
# Common error codes (not exhaustive)
# -----------------------

const
  SCARD_S_SUCCESS* = 0'i32
  SCARD_E_CANCELLED* = -0x80100002'i32
  SCARD_E_CANT_DISPOSE* = -0x8010000E'i32
  SCARD_E_INSUFFICIENT_BUFFER* = -0x80100008'i32
  SCARD_E_INVALID_HANDLE* = -0x80100003'i32
  SCARD_E_INVALID_PARAMETER* = -0x80100004'i32
  SCARD_E_INVALID_VALUE* = -0x80100011'i32
  SCARD_E_NO_SMARTCARD* = -0x8010000C'i32
  SCARD_E_NOT_READY* = -0x80100010'i32
  SCARD_E_NOT_TRANSACTED* = -0x80100016'i32
  SCARD_E_READER_UNAVAILABLE* = -0x80100017'i32
  SCARD_E_SHARING_VIOLATION* = -0x8010000B'i32
  SCARD_E_TIMEOUT* = -0x8010000A'i32
  SCARD_E_UNKNOWN_READER* = -0x80100009'i32
  SCARD_F_COMM_ERROR* = -0x80100013'i32
  SCARD_F_INTERNAL_ERROR* = -0x80100001'i32

# -----------------------
# Error name lookup
# -----------------------

proc pcscErrorName*(code: LONG): string =
  ## Return a short name for a PC/SC error code.
  case code
  of SCARD_S_SUCCESS: "SCARD_S_SUCCESS"
  of SCARD_E_CANCELLED: "SCARD_E_CANCELLED"
  of SCARD_E_CANT_DISPOSE: "SCARD_E_CANT_DISPOSE"
  of SCARD_E_INSUFFICIENT_BUFFER: "SCARD_E_INSUFFICIENT_BUFFER"
  of SCARD_E_INVALID_HANDLE: "SCARD_E_INVALID_HANDLE"
  of SCARD_E_INVALID_PARAMETER: "SCARD_E_INVALID_PARAMETER"
  of SCARD_E_INVALID_VALUE: "SCARD_E_INVALID_VALUE"
  of SCARD_E_NO_SMARTCARD: "SCARD_E_NO_SMARTCARD"
  of SCARD_E_NOT_READY: "SCARD_E_NOT_READY"
  of SCARD_E_NOT_TRANSACTED: "SCARD_E_NOT_TRANSACTED"
  of SCARD_E_READER_UNAVAILABLE: "SCARD_E_READER_UNAVAILABLE"
  of SCARD_E_SHARING_VIOLATION: "SCARD_E_SHARING_VIOLATION"
  of SCARD_E_TIMEOUT: "SCARD_E_TIMEOUT"
  of SCARD_E_UNKNOWN_READER: "SCARD_E_UNKNOWN_READER"
  of SCARD_F_COMM_ERROR: "SCARD_F_COMM_ERROR"
  of SCARD_F_INTERNAL_ERROR: "SCARD_F_INTERNAL_ERROR"
  else: "UNKNOWN_ERROR"

# -----------------------
# Error message
# -----------------------

proc pcscErrorMessage*(code: LONG): string =
  let name = pcscErrorName(code)
  result = name & " (0x" & toHex(int(code), 8) & ")"

# -----------------------
# Helper to raise exception
# -----------------------

proc raiseIfError*(code: LONG, msg = "") =
  if code != SCARD_S_SUCCESS:
    let errMsg = if msg.len > 0: msg else: pcscErrorName(code)
    let hexCode = toHex(int(code), 8)
    var e = PcscError(code: code)
    e.msg = errMsg & " (0x" & hexCode & ")"
    raise e

