# nextui-gppx-pak

NextUI emulator pak bundling **Genesis Plus GX** (GPGX) as a libretro core.

Genesis Plus GX is an accurate Sega 8/16-bit emulator supporting Genesis/Mega Drive, Master System, Game Gear, SG-1000, and Sega/Mega CD.

## Supported Platforms

| Platform | Device | Toolchain |
|----------|--------|-----------|
| tg5040 | Trimui Smart Pro | `ghcr.io/loveretro/tg5040-toolchain:latest` |
| tg5050 | Trimui Smart Pro S | `ghcr.io/loveretro/tg5050-toolchain:latest` |
| my355 | Anbernic MY355 | `ghcr.io/loveretro/my355-toolchain:latest` |

## Building

Requires Docker.

```sh
# Build for all platforms and create .pakz
make package

# Build for a single platform
make tg5040

# Clean build artifacts (preserves cached source)
make clean

# Clean everything including cached source
make distclean
```

## Installation

Extract `GPGX.pakz` to the root of your SD card. It will create the correct directory structure:

```
Emus/
├── tg5040/GPGX.pak/
├── tg5050/GPGX.pak/
└── my355/GPGX.pak/
```

Place ROMs in a folder tagged `(GPGX)`:
```
Roms/Mega Drive (GPGX)/Sonic The Hedgehog.md
```

## Core Version

Genesis Plus GX is pinned to commit [`b72b8c9`](https://github.com/libretro/Genesis-Plus-GX/commit/b72b8c967adc50311dc3bb700c0818518bee74ef) (April 3, 2026) for reproducible builds.

## License

MIT