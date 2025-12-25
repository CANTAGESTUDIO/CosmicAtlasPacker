# Texture Compression Tools

This directory contains external tools for texture compression.

## Required Tools

### 1. astcenc (ARM ASTC Encoder)
- **Download**: https://github.com/ARM-software/astc-encoder/releases
- **Version**: 5.0.0 or later
- **File**: `astcenc-avx2` (macOS Universal Binary)
- **License**: Apache 2.0

### 2. EtcTool (Google ETC2 Compressor)
- **Download**: https://github.com/nicokraak/etc2comp
- **Build**: Requires CMake build
- **File**: `EtcTool`
- **License**: Apache 2.0

## Installation

1. Download `astcenc-avx2` from ARM releases
2. Build `EtcTool` from source (or find prebuilt)
3. Place both binaries in this directory
4. Ensure binaries have execute permission: `chmod +x astcenc-avx2 EtcTool`

## Directory Structure

```
Tools/
├── README.md           (this file)
├── astcenc-avx2        (ASTC encoder)
└── EtcTool             (ETC2 encoder)
```

## Usage

The app will automatically detect these tools and use them for texture compression when the "Texture Compression" toggle is enabled in the Export dialog.

If tools are not found, compression will fail with an appropriate error message.
