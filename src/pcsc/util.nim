## Utility functions for PC/SC SDK (hex helpers, conversions).

import std/strutils

proc toHex*(data: openArray[byte]): string =
  ## Convert byte array → hex string.
  for b in data:
    result.add (int(b).toHex(2))

proc fromHex*(s: string): seq[byte] =
  assert s.len mod 2 == 0, "Hex string must have even length"
  for i in countup(0, s.len-2, 2):
    let hexPair = s[i .. i+1]
    let value = parseHexInt(hexPair).uint8
    result.add value

proc prettyHex*(data: openArray[byte]): string =
  ## Format hex string with spaces.
  for b in data:
    if result.len > 0: result.add " "
    result.add (int(b).toHex(2).toUpperAscii())

proc fromHexLoose*(s: string): seq[byte] =
  ## Parse hex string while ignoring non-hex characters (spaces, newlines, etc.)
  let hexChars = {'0'..'9', 'a'..'f', 'A'..'F'}
  var tmp = newSeq[char]()
  for ch in s:
    if ch in hexChars:
      tmp.add ch
  if (tmp.len mod 2) != 0:
    raise newException(ValueError, "Hex string has odd number of hex digits")
  for i in countup(0, tmp.len - 2, 2):
    let byteStr = $tmp[i] & $tmp[i+1]
    result.add parseHexInt(byteStr).uint8
