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

### Via Pak Store (Recommended)

1. Open **Pak Store** on your NextUI device.
2. Search for **GPGX** and tap **Install**.
3. Pak Store will download the latest `GPGX.pakz` release and place the pak in the correct `Emus/<platform>/GPGX.pak/` directory for your device.

### Manual Installation

1. Download `GPGX.pakz` from the [latest release](https://github.com/Helaas/nextui-gppx-pak/releases).
2. Extract the archive to the root of your SD card. It will create the correct directory structure:

   ```
   Emus/
   ├── tg5040/GPGX.pak/
   ├── tg5050/GPGX.pak/
   └── my355/GPGX.pak/
   ```

   Each `GPGX.pak/` folder contains `launch.sh`, `default.cfg`, `LICENSE`, and the stripped `genesis_plus_gx_libretro.so` core for that platform.

## ROMs

Place ROMs in a folder suffixed with `(GPGX)` so NextUI associates them with this pak. Example layout:

```
Roms/
├── Mega Drive (GPGX)/
│   ├── Sonic The Hedgehog.md
│   └── Streets of Rage 2.md
├── Master System (GPGX)/
│   └── Alex Kidd in Miracle World.sms
├── Game Gear (GPGX)/
│   └── Sonic The Hedgehog.gg
├── SG-1000 (GPGX)/
│   └── F-16 Fighting Falcon.sg
└── Mega CD (GPGX)/
    └── Sonic CD.chd
```

Supported ROM extensions: `.md`, `.gen`, `.sms`, `.gg`, `.sg`, `.68k`, `.bin`, `.chd` (for CD images).

> **Mega CD note:** CD games require BIOS files (`bios_CD_E.bin`, `bios_CD_J.bin`, `bios_CD_U.bin`) placed in the `Bios/GPGX/` folder on your SD card.

## Core Version

Genesis Plus GX is pinned to commit [`fa4dca5`](https://github.com/libretro/Genesis-Plus-GX/commit/fa4dca561e08d5be9077419f7b255e1da213ed21) for reproducible builds.

## License

MIT