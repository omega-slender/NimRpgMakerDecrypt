# NimRpgMakerDecrypt 🗝️✨

A high-performance, pure Nim library for decrypting RPG Maker MV/MZ assets (images and audio). Supports both key-based decryption and header restoration (no-key mode), as well as automatic encryption key recovery.

## 🎯 Overview

NimRpgMakerDecrypt provides a robust toolset for handling encrypted RPG Maker assets. Whether you have the encryption key or need to recover it from the files themselves, this library offers a simple, type-safe API to restore your files to their original state. 🚀

## ✨ Features

### ⚖️ Disclaimer & Ethics
This project is **NOT** intended for malicious use, such as stealing assets or infringing on intellectual property. It is designed for:
- 🛠️ **Modding**: Creating fan mods or patches.
- 📝 **Translations**: Facilitating fan translations.
- 💾 **Recovery**: Restoring your own lost assets.

**Please respect the rights of game developers and artists.**

### ⚠️ Recommendation
While **No-Key Decryption** is available, it is **strongly recommended** to use **Key-Based Decryption** whenever possible. Using the correct encryption key ensures 100% accurate restoration of the original file content and minimizes the risk of corruption or playback issues.

### 🔌 Core Functionality
- **Key-Based Decryption** 🔐: Decrypt files using a known 16-byte hex key.
- **No-Key Decryption** 🔓: Restore files without a key by reconstructing standard file headers.
- **Format Support** 📄: Full support for encrypted PNG images (`.rpgmvp`, `.png_`) and OGG/M4A audio (`.rpgmvo`, `.ogg_`, `.rpgmvm`, `.m4a_`).

### 🎨 Smart Features
- **Auto Key Recovery** 🕵️: Automatically extract encryption keys from encrypted images or audio files.
- **Header Analysis** 🧠: Intelligent file type detection and validation.
- **Safe & Robust** 🛡️: Comprehensive error handling for corrupted or invalid files.

### ⚡ Performance
- **Pure Nim** 🐇: Native performance with no external dependencies.
- **Memory Efficient** 💾: Optimized file handling for large assets.

## 📦 Installation

```bash
nimble install https://github.com/omega-slender/NimRpgMakerDecrypt
```

Add to your `.nimble` file:

```nim
requires "nimrpgmakerdecrypt >= 1.0.0"
```

## 🚀 Quick Start

### Basic Decryption (With Key)

```nim
import nimrpgmakerdecrypt

# Initialize decrypter with 32-char hex key
let key = "d41d8cd98f00b204e9800998ecf8427e"
let decrypter = newKeyDecrypter(key)

try:
  # Decrypt an image file
  let decrypted = decrypter.decrypt("img/characters/Actor1.rpgmvp")
  
  # Save the restored content
  decrypted.save("Actor1.png")
  echo "Decryption successful!"
except DecrypterError:
  echo "Failed to decrypt file."
```

### Automatic Key Recovery

```nim
import nimrpgmakerdecrypt

# Recover key from an encrypted image
let keyParams = recoverKeyFromImage("img/system/Window.rpgmvp")

if keyParams != "":
  echo "Found key: ", keyParams
  
  # Use the recovered key
  let decrypter = newKeyDecrypter(keyParams)
  # ... proceed with decryption
else:
  echo "Could not recover key."
```

### No-Key Decryption (Header Restoration)

```nim
import nimrpgmakerdecrypt

# No key needed - reconstructs the header based on file type
let noKeyDecrypter = newNoKeyDecrypter()

try:
  let restored = noKeyDecrypter.decrypt("audio/bgm/Theme.rpgmvo")
  restored.save("Theme.ogg")
except DecrypterError:
  echo "Restoration failed."
```

### Previewing Decrypted Content 👁️

You can instantly preview the decrypted content without saving it manually using the `show()` method. This opens the file in the default system viewer (e.g., Image Viewer, Music Player).

**Note:** This feature is only available on **PC platforms (Windows, macOS, Linux)**. Calling it on Web (JS) or Mobile (Android/iOS) will raise an `OSError`.

```nim
import nimrpgmakerdecrypt

let decrypter = newKeyDecrypter("d41d8cd98f00b204e9800998ecf8427e")
let decrypted = decrypter.decrypt("img/characters/Actor1.rpgmvp")

try:
  decrypted.show() # Opens the image in default viewer
except OSError:
  echo "Preview not supported on this platform."
```

## 📖 Main Components

### KeyDecrypter 🔐
The primary class for decrypting files when the encryption key is known. It performs a standard XOR decryption on the file header.

```nim
let decrypter = newKeyDecrypter("your_hex_key_here")
```

### NoKeyDecrypter 🔓
A fallback decrypter that doesn't require a key. It replaces the encrypted header with a standard file header (PNG/OGG/M4A). Useful when the key is lost but the file content is intact.

```nim
let restorer = newNoKeyDecrypter()
```

### Key Recovery 🕵️
Static procedures to analyze encrypted files and derive the XOR key used for encryption.

- `recoverKeyFromImage(path)`: Fast recovery from PNG images.
- `recoverKeyFromAudio(path)`: Recovery from OGG/M4A audio files (includes serial number correction for OGG).

## 🔧 Supported Formats

| Extension | Original Format | Function |
|-----------|-----------------|----------|
| `.rpgmvp` / `.png_` | PNG Image 🖼️ | `recoverKeyFromImage` |
| `.rpgmvo` / `.ogg_` | OGG Audio 🎵 | `recoverKeyFromAudio` |
| `.rpgmvm` / `.m4a_` | M4A Audio 🎵 | `recoverKeyFromAudio` |

## 👨‍💻 Author

Created by **Omega Slender**

💬 Connect with me:
[🌳 Linktree](https://linktr.ee/omega_slender)

☕ Support the project:
[Ko-fi](https://ko-fi.com/omega_slender)

## 🙏 Credits

This project is based on the work of [Petschko](https://gitlab.com/Petschko/RPG-Maker-MV-Decrypter).

---

⭐ If you find this library useful, consider giving it a star!
