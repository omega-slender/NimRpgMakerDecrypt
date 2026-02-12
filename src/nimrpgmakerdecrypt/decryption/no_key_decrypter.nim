## Keyless decrypter for RPG Maker MV/MZ encrypted assets.
## Restores files by applying known file-type headers without requiring
## the encryption key. Less accurate than key-based decryption.

import ../common/types, ../utils/fileio, ../formats/ogg
import strformat

type
  NoKeyDecrypter* = ref object
    ## Decrypter that restores file headers using known magic bytes,
    ## without requiring the original encryption key.

proc newNoKeyDecrypter*(): NoKeyDecrypter {.inline, noSideEffect.} =
  ## Creates a new ``NoKeyDecrypter`` instance.
  NoKeyDecrypter()

proc `$`*(d: NoKeyDecrypter): string =
  ## Returns a human-readable string representation of the ``NoKeyDecrypter``.
  if d.isNil: return "NoKeyDecrypter(nil)"
  "NoKeyDecrypter()"

proc applyHeader(decrypted: var seq[byte], header: openArray[byte]) {.inline.} =
  ## Overwrites the beginning of ``decrypted`` with the bytes from ``header``.
  let limit = min(decrypted.len, header.len)
  for i in 0 ..< limit:
    decrypted[i] = header[i]

proc decrypt*(self: NoKeyDecrypter, inputPath: string): DecryptedFile {.
  raises: [DecrypterError, IOError, OSError],
  tags: [ReadIOEffect, WriteIOEffect].} =
  ## Decrypts an encrypted RPG Maker file at ``inputPath`` by replacing the
  ## corrupted header with the appropriate known header for the detected
  ## file type. For OGG files, also restores the serial number and
  ## recalculates the CRC32 checksum.
  let path = normalizePathStandard(inputPath)
  let (content, fileType) = loadRpgFile(path)

  if fileType == ftUnknown:
    raise newException(DecrypterError,
      fmt"Unable to determine file type for: {path}")

  var decrypted = content

  case fileType
  of ftPng:
    applyHeader(decrypted, PngHeaderTemplate)

  of ftOgg:
    let serial = findNextOggSerial(decrypted)
    if serial.len > 0:
      applyHeader(decrypted, OggHeaderTemplate)
      if decrypted.len > 14: decrypted[14] = serial[0]
      if decrypted.len > 15: decrypted[15] = serial[1]
      fixOggCrc(decrypted)
    else:
      applyHeader(decrypted, M4aHeaderTemplate)

  of ftM4a:
    applyHeader(decrypted, M4aHeaderTemplate)

  of ftUnknown:
    discard

  newDecryptedFile(decrypted, path, fileType)
