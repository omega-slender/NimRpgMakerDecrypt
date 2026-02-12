## XOR-based encryption and decryption operations for RPG Maker file headers.

import ../common/types

proc xorBytes*(data: var openArray[byte], key: openArray[byte]) {.noSideEffect.} =
  ## XORs the first ``FakeHeaderLen`` bytes of ``data`` with ``key`` in-place.
  ## This is the core operation for both encrypting and decrypting
  ## RPG Maker MV/MZ file headers.
  if key.len == 0: return
  let limit = min(data.len, FakeHeaderLen)
  for i in 0 ..< limit:
    if i < key.len:
      data[i] = data[i] xor key[i]

proc recoverKeyXor*(encrypted, known: openArray[byte]): seq[byte] {.noSideEffect.} =
  ## Recovers the encryption key by XORing an encrypted header against a
  ## known plaintext header. The result length equals the shorter of the
  ## two inputs.
  let length = min(encrypted.len, known.len)
  result = newSeq[byte](length)
  for i in 0 ..< length:
    result[i] = encrypted[i] xor known[i]
