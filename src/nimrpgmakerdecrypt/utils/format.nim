## File format detection based on magic bytes and content signatures.

import ../common/types

template matchesSignature*(data: openArray[byte], offset: int, sig: varargs[byte]): bool =
  ## Checks whether the bytes at ``offset`` in ``data`` match the given signature.
  ## Returns false if the signature would extend past the end of ``data``.
  block:
    var matches = true
    if offset + sig.len > data.len:
      matches = false
    else:
      for i in 0 ..< sig.len:
        if data[offset + i] != sig[i]:
          matches = false
          break
    matches

proc detectFileFormat*(content: openArray[byte]): FileType {.noSideEffect.} =
  ## Detects the media format of decrypted content by examining magic bytes.
  ##
  ## Checks for PNG, OGG Vorbis, and M4A signatures both at the start
  ## and deeper in the content (up to ``FormatScanLimit`` bytes) for cases
  ## where the header has been partially corrupted by encryption.
  ## Returns ``ftUnknown`` if no known format is detected.
  if content.len < 16:
    return ftUnknown

  if matchesSignature(content, 0, 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A):
    return ftPng

  if matchesSignature(content, 0, 0x4f, 0x67, 0x67, 0x53):
    return ftOgg

  if content.len >= 8 and matchesSignature(content, 4, 0x66, 0x74, 0x79, 0x70):
    return ftM4a

  if content.len > 16:
    let startSearch = max(16, content.len - 256)
    for i in startSearch ..< content.len - 3:
      if matchesSignature(content, i, 0x49, 0x45, 0x4E, 0x44):
        return ftPng

  let limit = min(content.len - 4, FormatScanLimit)

  for i in 16 ..< limit:
    if matchesSignature(content, i, 0x4f, 0x67, 0x67, 0x53):
      return ftOgg

  for i in 16 ..< limit:
    if matchesSignature(content, i, 0x6D, 0x64, 0x61, 0x74) or
       matchesSignature(content, i, 0x6D, 0x6F, 0x6F, 0x76):
      return ftM4a

  return ftUnknown
