# nextui-gppx-pak

NextUI emulator pak bundling **Genesis Plus GX** (GPGX) as a libretro core.

Genesis Plus GX is an accurate Sega 8/16-bit emulator supporting Genesis/Mega Drive, Master System, Game Gear, SG-1000, and Sega/Mega CD.

## Supported Platforms

| Platform | Device |
|----------|--------|
| tg5040 | TrimUI Brick / Smart Pro |
| tg5050 | TrimUI Smart Pro S |
| my355 | Miyoo Flip |
| h700 | Anbernic H700 devices |

One core build serves every platform. It is compiled with the pinned `ghcr.io/loveretro/tg5040-toolchain` image, whose glibc 2.28 sysroot is older than every supported firmware, and tuned for Cortex-A53 so it runs on both A53 and A55 devices.

## Building

Requires Docker.

```sh
# Build the universal core and create build/release/GPGX.pak.zip
make package

# Build the universal core only
make universal

# Check the core's architecture, RPATH, and glibc ceiling
make verify

# Optional legacy per-platform builds, kept as regression checks
make matrix

# Clean build artifacts (preserves cached source)
make clean

# Clean everything including cached source
make distclean
```

`make package` verifies the core and asserts that `launch.sh`, `default.cfg`, `pak.json`, and `genesis_plus_gx_libretro.so` sit at the archive root.

## Installation

### Via Pak Store (Recommended)

1. Open **Pak Store** on your NextUI device.
2. Search for **GPGX** and tap **Install**.
3. Pak Store downloads `GPGX.pak.zip` and extracts it into `Emus/<platform>/GPGX.pak/` for your device.

### Manual Installation

1. Download `GPGX.pak.zip` from the [latest release](https://github.com/Helaas/nextui-gppx-pak/releases).
2. Extract the contents of the archive into `Emus/<platform>/GPGX.pak/` on your SD card, replacing `<platform>` with `tg5040`, `tg5050`, `my355`, or `h700`.

   The archive has no enclosing folder, so create `GPGX.pak/` first. It contains `launch.sh`, `default.cfg`, `pak.json`, `LICENSE`, and the stripped `genesis_plus_gx_libretro.so` core.

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

## Releasing

The **Build** workflow runs `make package` on every pull request and attaches `GPGX.pak.zip` to the run as an artifact.

To publish, bump `version` in `pak.json`, add a `changelog` entry for that version, and merge to `main`. The **Release** workflow builds the archive and, if no release with that tag exists yet, creates one with `GPGX.pak.zip` attached and the changelog entry as its notes.

## Core Version

Genesis Plus GX is pinned to commit [`fa4dca5`](https://github.com/libretro/Genesis-Plus-GX/commit/fa4dca561e08d5be9077419f7b255e1da213ed21) for reproducible builds.

## License

MIT
