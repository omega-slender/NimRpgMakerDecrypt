## OGG Vorbis checksum calculation, serial number extraction, and CRC repair.

import ../utils/format

const OggCrcTable: array[256, uint32] = block:
  ## Precomputed CRC32 lookup table using the OGG polynomial (0x04C11DB7, MSB-first).
  var table: array[256, uint32]
  for i in 0 ..< 256:
    var crc = uint32(i) shl 24
    for _ in 0 ..< 8:
      if (crc and 0x80000000'u32) != 0:
        crc = (crc shl 1) xor 0x04C11DB7'u32
      else:
        crc = crc shl 1
    table[i] = crc
  table

proc calculateOggCrc*(data: openArray[byte], start, length: int): uint32 {.noSideEffect.} =
  ## Computes the OGG CRC32 checksum over ``length`` bytes of ``data``
  ## starting at index ``start``, using the standard OGG polynomial.
  result = 0'u32
  for i in 0 ..< length:
    let idx = ((result shr 24) xor uint32(data[start + i])) and 0xFF
    result = (result shl 8) xor OggCrcTable[idx]

proc findNextOggSerial*(content: openArray[byte]): seq[byte] {.noSideEffect.} =
  ## Searches for the next OGG page header within the first 8192 bytes of
  ## ``content`` and extracts its 4-byte serial number.
  ## Returns an empty sequence if no OGG page is found.
  let limit = min(content.len - 14, 8192)
  var i = 4
  while i < limit:
    if matchesSignature(content, i, 0x4f, 0x67, 0x67, 0x53):
      if i + 18 <= content.len:
        return @[content[i+14], content[i+15], content[i+16], content[i+17]]
    i.inc
  return @[]

proc fixOggCrc*(content: var seq[byte]) {.noSideEffect.} =
  ## Recalculates and writes the correct CRC32 checksum for the first OGG
  ## page in ``content``. This is necessary after modifying the page header
  ## (e.g. restoring the serial number during decryption).
  ## Does nothing if ``content`` is not a valid OGG page.
  if content.len < 27: return
  if not matchesSignature(content, 0, 0x4f, 0x67, 0x67, 0x53): return

  let pageSegments = content[26].int
  let headerSize = 27 + pageSegments
  if content.len < headerSize: return

  var bodySize = 0
  for i in 0 ..< pageSegments:
    bodySize += content[27 + i].int

  let pageSize = headerSize + bodySize
  if content.len < pageSize: return

  content[22] = 0
  content[23] = 0
  content[24] = 0
  content[25] = 0

  let crc = calculateOggCrc(content, 0, pageSize)
  content[22] = byte(crc and 0xFF)
  content[23] = byte((crc shr 8) and 0xFF)
  content[24] = byte((crc shr 16) and 0xFF)
  content[25] = byte((crc shr 24) and 0xFF)
