## File I/O operations for loading encrypted RPG Maker files and saving
## decrypted output.

import os, strutils, strformat, streams
import ../common/types, hex, format

proc normalizePathStandard*(path: string): string {.noSideEffect, inline.} =
  ## Normalizes a file path by replacing all forward and back slashes
  ## with the platform-specific directory separator.
  path.multiReplace(("\\", $DirSep), ("/", $DirSep))

proc validateFakeHeader*(header: openArray[byte]) {.raises: [FileFormatError], noSideEffect.} =
  ## Validates that ``header`` contains a valid RPG Maker MV or MZ encryption
  ## header. Raises ``FileFormatError`` if the signature does not match
  ## either format.
  if header.len < FakeHeaderLen:
    raise newException(FileFormatError, "Invalid File Header: Too short.")

  let fakeHeaderMv = hexToBytes(DefaultSignature & DefaultVersion & DefaultRemain)
  let fakeHeaderMz = hexToBytes(DefaultSignatureMz & DefaultVersion & DefaultRemain)
  let headerSlice = header[0 ..< FakeHeaderLen]

  if headerSlice != fakeHeaderMv and headerSlice != fakeHeaderMz:
    let sigMv = hexToBytes(DefaultSignature)
    let sigMz = hexToBytes(DefaultSignatureMz)

    if headerSlice[0 ..< 8] != sigMv and headerSlice[0 ..< 8] != sigMz:
      raise newException(FileFormatError,
        "Invalid File Header. The file signature does not match RPG Maker MV/MZ encryption.")

proc loadRpgFile*(inputPath: string): (seq[byte], FileType) {.
  raises: [IOError, OSError, FileAccessError, FileFormatError],
  tags: [ReadIOEffect, WriteIOEffect].} =
  ## Loads an encrypted RPG Maker file, validates its header, strips the
  ## 16-byte fake header, and detects the underlying media format.
  ## Returns a tuple of the content bytes (without fake header) and the
  ## detected ``FileType``.
  if not fileExists(inputPath):
    raise newException(FileAccessError, fmt"Input file does not exist: {inputPath}")

  let fileSize = getFileSize(inputPath)
  if fileSize < FakeHeaderLen:
    raise newException(FileFormatError,
      fmt"File too short ({fileSize} bytes). Minimum: {FakeHeaderLen} bytes.")

  var fs = newFileStream(inputPath, fmRead)
  if fs.isNil:
    raise newException(FileAccessError, fmt"Unable to open file: {inputPath}")
  defer: fs.close()

  var header = newSeq[byte](FakeHeaderLen)
  if fs.readData(addr header[0], FakeHeaderLen) != FakeHeaderLen:
    raise newException(FileFormatError, fmt"Unexpected EOF reading header: {inputPath}")

  validateFakeHeader(header)

  let contentLen = fileSize - FakeHeaderLen
  var content = newSeq[byte](contentLen)
  if fs.readData(addr content[0], content.len) != content.len:
    raise newException(FileFormatError, fmt"Unexpected EOF reading content: {inputPath}")

  let fileType = detectFileFormat(content)
  return (content, fileType)

proc newDecryptedFile*(content: seq[byte], originalPath: string,
                       fileType: FileType): DecryptedFile {.inline, noSideEffect.} =
  ## Creates a new ``DecryptedFile`` by extracting the directory and file name
  ## from ``originalPath`` and associating them with the decrypted ``content``
  ## and detected ``fileType``.
  let (dir, name, _) = splitFile(originalPath)
  DecryptedFile(
    content: content,
    fileName: name,
    directory: dir,
    extension: $fileType
  )

proc save*(self: DecryptedFile, path: string = "") {.
  raises: [IOError, OSError, FileAccessError],
  tags: [WriteIOEffect].} =
  ## Writes the decrypted content to disk. If ``path`` is empty, the file is
  ## saved in its original directory with the detected extension.
  var finalPath = path
  if finalPath.len == 0:
    finalPath = self.directory / self.fileName & "." & self.extension

  var fs = newFileStream(finalPath, fmWrite)
  if fs.isNil:
    raise newException(FileAccessError, fmt"Unable to create output file: {finalPath}")

  defer: fs.close()
  fs.writeData(addr self.content[0], self.content.len)

proc show*(self: DecryptedFile) {.
  raises: [IOError, OSError, FileAccessError],
  tags: [ReadIOEffect, WriteIOEffect, ExecIOEffect].} =
  ## Writes the decrypted content to a temporary file and opens it using the
  ## default application for its file type. Supported on Windows, macOS, and Linux.
  when defined(js) or defined(android) or defined(ios):
    raise newException(OSError, "Show functionality is not supported on Web or Mobile platforms.")
  else:
    if self.content.len == 0:
      return

    let tempPath = getTempDir() / (self.fileName & "." & self.extension)

    var fs = newFileStream(tempPath, fmWrite)
    if fs.isNil:
      raise newException(FileAccessError, fmt"Unable to create temporary file: {tempPath}")

    try:
      fs.writeData(addr self.content[0], self.content.len)
    finally:
      fs.close()

    let quotedPath = quoteShell(tempPath)
    var cmd = ""

    when defined(windows):
      cmd = "cmd /c start \"\" " & quotedPath
    elif defined(macosx):
      cmd = "open " & quotedPath
    else:
      cmd = "xdg-open " & quotedPath

    discard execShellCmd(cmd)
