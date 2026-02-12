## Key-based decrypter for RPG Maker MV/MZ encrypted assets.
## Requires the 16-byte encryption key to decrypt files.

import ../common/types, ../utils/hex, ../utils/xorcrypt, ../utils/fileio
import strformat

type
  KeyDecrypter* = ref object
    ## Decrypter that uses a known encryption key to restore original file content.
    key*: seq[byte] ## The 16-byte decryption key.

proc newKeyDecrypter*(key: string): KeyDecrypter {.inline.} =
  ## Creates a new ``KeyDecrypter`` from a 32-character hexadecimal key string.
  KeyDecrypter(key: hexToBytes(key))

proc `$`*(d: KeyDecrypter): string =
  ## Returns a human-readable string representation of the ``KeyDecrypter``.
  if d.isNil: return "KeyDecrypter(nil)"
  fmt"KeyDecrypter(key: {bytesToHex(d.key)})"

proc decrypt*(self: KeyDecrypter, inputPath: string): DecryptedFile {.
  raises: [DecrypterError, IOError, OSError],
  tags: [ReadIOEffect, WriteIOEffect].} =
  ## Decrypts an encrypted RPG Maker file at ``inputPath`` using the stored key.
  ## Returns a ``DecryptedFile`` with the restored content and detected format.
  let path = normalizePathStandard(inputPath)
  let (content, fileType) = loadRpgFile(path)

  if content.len < FakeHeaderLen:
    raise newException(DecrypterError, fmt"File too short: {path}")

  var decryptedContent = content
  xorBytes(decryptedContent, self.key)

  newDecryptedFile(decryptedContent, path, fileType)
