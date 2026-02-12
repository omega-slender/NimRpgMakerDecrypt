## Hexadecimal conversion utilities and encryption key validation.

import strutils, parseutils

proc hexToBytes*(hex: string): seq[byte] {.noSideEffect.} =
  ## Converts a hexadecimal string into a sequence of bytes.
  ## Each pair of hex characters is decoded into one byte.
  ## Invalid hex pairs are silently skipped.
  result = newSeqOfCap[byte](hex.len div 2)
  var i = 0
  while i < hex.len - 1:
    var val: int
    if parseHex(hex[i .. i+1], val) == 2:
      result.add(val.byte)
    i += 2

proc bytesToHex*(bytes: openArray[byte]): string {.noSideEffect.} =
  ## Converts a byte sequence into an uppercase hexadecimal string.
  result = newStringOfCap(bytes.len * 2)
  for b in bytes:
    result.add(toHex(b, 2))

proc isValidKey*(key: string): bool {.noSideEffect, inline.} =
  ## Checks whether a string is a valid 16-byte RPG Maker encryption key
  ## represented as 32 hexadecimal characters.
  key.len == 32 and key.allCharsInSet(HexDigits)
