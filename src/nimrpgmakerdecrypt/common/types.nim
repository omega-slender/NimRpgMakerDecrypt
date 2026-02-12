## Core types, error hierarchy, and constants for RPG Maker MV/MZ decryption.

import strformat

type
  DecrypterError* = object of CatchableError
    ## Base error type for all decryption-related failures.
  FileAccessError* = object of DecrypterError
    ## Raised when a file cannot be opened or created.
  FileFormatError* = object of DecrypterError
    ## Raised when a file does not conform to the expected RPG Maker format.
  DecryptionError* = object of DecrypterError
    ## Raised when the decryption process itself fails.

  DecryptedFile* = ref object
    ## Represents a successfully decrypted file with its content and metadata.
    content*: seq[byte] ## Raw decrypted binary content.
    fileName*: string   ## Original file name without extension.
    directory*: string  ## Directory where the original file was located.
    extension*: string  ## Detected output extension (png, ogg, m4a).

  FileType* = enum
    ## Detected media format of a decrypted file.
    ftUnknown = ""
    ftPng = "png"
    ftOgg = "ogg"
    ftM4a = "m4a"

const
  FakeHeaderLen* = 16
    ## Length in bytes of the RPG Maker fake header prepended to encrypted files.

  DefaultSignature* = "5250474d56000000"
    ## Hex-encoded signature for RPG Maker MV encrypted files ("RPGMV").
  DefaultSignatureMz* = "5250474d5a000000"
    ## Hex-encoded signature for RPG Maker MZ encrypted files ("RPGMZ").
  DefaultVersion* = "000301"
    ## Hex-encoded version field in the RPG Maker encryption header.
  DefaultRemain* = "0000000000"
    ## Hex-encoded remaining padding bytes in the RPG Maker encryption header.

  EncryptedExtensions* = [
    "rpgmvp", "rpgmvo", "rpgmvm",
    "png_", "ogg_", "m4a_"
  ] ## File extensions used by RPG Maker MV/MZ for encrypted assets.

  PngHeaderTemplate* = [
    0x89.byte, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52
  ] ## First 16 bytes of a standard PNG file header.

  OggHeaderTemplate* = [
    0x4f.byte, 0x67, 0x67, 0x53, 0x00, 0x02,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  ] ## First 14 bytes of a standard OGG Vorbis file header.

  M4aHeaderTemplate* = [
    0x00.byte, 0x00, 0x00, 0x1C, 0x66, 0x74, 0x79, 0x70,
    0x4D, 0x34, 0x41, 0x20, 0x00, 0x00, 0x00, 0x00
  ] ## First 16 bytes of a standard M4A (ftyp M4A) file header.

  FormatScanLimit* = 131072
    ## Maximum number of bytes to scan when detecting file format by content.

proc `$`*(df: DecryptedFile): string =
  ## Returns a human-readable string representation of a ``DecryptedFile``.
  if df.isNil: return "DecryptedFile(nil)"
  fmt"DecryptedFile(fileName: {df.fileName}, extension: {df.extension}, size: {df.content.len} bytes)"
