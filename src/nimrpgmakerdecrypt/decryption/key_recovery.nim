## Encryption key recovery from encrypted RPG Maker MV/MZ asset files.
## Recovers the 16-byte XOR key by comparing encrypted headers against
## known plaintext file headers. Returns empty string on failure (no-raise API).

import ../common/types, ../utils/hex, ../utils/xorcrypt, ../formats/ogg, ../utils/fileio

proc recoverKeyFromContent(content: seq[byte], knownHeader: openArray[byte],
                           useSerial: bool = false): string {.noSideEffect.} =
  ## Attempts to recover the encryption key from already-loaded file content
  ## by XORing the encrypted header against ``knownHeader``.
  ## When ``useSerial`` is true, corrects bytes 14-15 of the key using the
  ## OGG serial number from the next page. Returns empty string on failure.
  if content.len < FakeHeaderLen:
    return ""

  let encryptedHeader = content[0 ..< FakeHeaderLen]
  var keyBytes = recoverKeyXor(encryptedHeader, knownHeader[0 ..< FakeHeaderLen])

  if useSerial:
    let serial = findNextOggSerial(content)
    if serial.len >= 2:
      keyBytes[14] = encryptedHeader[14] xor serial[0]
      keyBytes[15] = encryptedHeader[15] xor serial[1]

  let key = bytesToHex(keyBytes)

  if knownHeader == PngHeaderTemplate:
    if isValidKey(key):
      return key
    return ""

  return key

proc recoverKeyFromImage*(inputPath: string): string {.
  tags: [ReadIOEffect, WriteIOEffect].} =
  ## Recovers the encryption key from an encrypted PNG image file.
  ## The key is derived by XORing the encrypted header against the known
  ## PNG header template. Returns empty string if recovery fails.
  var content: seq[byte]

  try:
    (content, _) = loadRpgFile(inputPath)
  except CatchableError:
    return ""

  recoverKeyFromContent(content, PngHeaderTemplate, useSerial = false)

proc recoverKeyFromAudio*(inputPath: string): string {.
  tags: [ReadIOEffect, WriteIOEffect].} =
  ## Recovers the encryption key from an encrypted audio file (OGG or M4A).
  ## For OGG files, uses the serial number from the second page to correct
  ## key bytes 14-15. Returns empty string if recovery fails or the file
  ## format is unrecognized.
  var content: seq[byte]
  var fileType: FileType

  try:
    (content, fileType) = loadRpgFile(inputPath)
  except CatchableError:
    return ""

  if content.len < FakeHeaderLen:
    return ""

  case fileType
  of ftOgg:
    recoverKeyFromContent(content, OggHeaderTemplate, useSerial = true)
  of ftM4a:
    recoverKeyFromContent(content, M4aHeaderTemplate, useSerial = false)
  else:
    ""
