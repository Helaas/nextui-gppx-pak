###########################################################
# NextUI GPGX Pak — Genesis Plus GX libretro core
###########################################################

# Core source
GPGX_REPO   := https://github.com/libretro/Genesis-Plus-GX.git
GPGX_HASH   := fa4dca561e08d5be9077419f7b255e1da213ed21
GPGX_SHORT  := $(shell printf '%.7s' $(GPGX_HASH))
CORE_SONAME := genesis_plus_gx_libretro.so

# Pak metadata
PAK_NAME         := GPGX
RELEASE_FILENAME := $(PAK_NAME).pak.zip

# Directories
BUILD_DIR     := build
DIST_DIR      := $(BUILD_DIR)/release
UNIVERSAL_DIR := $(BUILD_DIR)/universal
PAK_DIR       := $(UNIVERSAL_DIR)/$(PAK_NAME).pak
CACHE_DIR     := .cache/genesis-plus-gx
SENTINEL      := .cache/.gpgx-$(GPGX_HASH)

# One pinned image builds the core for tg5040, tg5050, my355, and h700.
# Its glibc 2.28 sysroot is older than every supported firmware
# (tg5040/tg5050 2.33, h700 2.35, my355 2.36), and cortex-a53 code
# runs on both the A53 (tg5040, h700) and A55 (tg5050, my355) cores.
UNIVERSAL_TOOLCHAIN := ghcr.io/loveretro/tg5040-toolchain@sha256:f131c6af64029a8723d0ce8d3c2682642f5f091b04714f6beedda9bec18477ab
UNIVERSAL_FLAGS     := -mcpu=cortex-a53 -mtune=cortex-a53
GLIBC_CEILING       := 2.28

# Legacy per-platform toolchains, kept as regression oracles
TG5040_TOOLCHAIN := ghcr.io/loveretro/tg5040-toolchain:latest
TG5050_TOOLCHAIN := ghcr.io/loveretro/tg5050-toolchain:latest
MY355_TOOLCHAIN  := ghcr.io/loveretro/my355-toolchain:latest

TG5040_FLAGS := -mcpu=cortex-a53 -mtune=cortex-a53
TG5050_FLAGS := -mcpu=cortex-a55 -mtune=cortex-a55
MY355_FLAGS  := -mcpu=cortex-a55 -mtune=cortex-a55

# Common build flags passed to the libretro makefile
# NOTE: CPU-specific flags go via FLAGS= (appended to CFLAGS inside the Makefile).
# We must include -D_7ZIP_ST and -DZSTD_DISABLE_ASM because the Makefile.common
# sets them via FLAGS+=, which is overridden by our command-line FLAGS=.
# GIT_VERSION is pinned rather than read with git inside the container, which
# refuses a checkout owned by another user (as on CI runners) and would drop
# the suffix from the core's reported version and change the binary.
COMMON_FLAGS := platform=unix FRONTEND_SUPPORTS_RGB565=1 HAVE_CHD=1
GPGX_FLAGS   := -D_7ZIP_ST -DZSTD_DISABLE_ASM

# Parallel jobs inside container (auto-detect)
JOBS := $$(nproc)

###########################################################
# Phony targets
###########################################################

.PHONY: all universal verify package tg5040 tg5050 my355 matrix \
        checkout clean distclean help

all: package

help:
	@echo "NextUI GPGX Pak build system"
	@echo ""
	@echo "Targets:"
	@echo "  make package          Build the universal core and create $(RELEASE_FILENAME)"
	@echo "  make universal        Build one core for tg5040, tg5050, my355, and h700"
	@echo "  make verify           Check the universal core's architecture, RPATH, and glibc ceiling"
	@echo "  make tg5040           Build core with the legacy TG5040 toolchain"
	@echo "  make tg5050           Build core with the legacy TG5050 toolchain"
	@echo "  make my355            Build core with the legacy MY355 toolchain"
	@echo "  make matrix           Build all three legacy cores as a regression check"
	@echo "  make checkout         Clone/update GPGX source"
	@echo "  make clean            Remove build artifacts"
	@echo "  make distclean        Remove build artifacts and cached source"

###########################################################
# Source checkout — pinned to GPGX_HASH for reproducibility
###########################################################

checkout: $(SENTINEL)

$(SENTINEL):
	@echo "==> Checking out Genesis Plus GX @ $(GPGX_HASH)"
	@mkdir -p .cache
	@if [ ! -d "$(CACHE_DIR)/.git" ]; then \
		git clone --depth 1 $(GPGX_REPO) $(CACHE_DIR); \
	fi
	@cd $(CACHE_DIR) && \
		git fetch --depth=1 origin $(GPGX_HASH) && \
		git checkout $(GPGX_HASH) && \
		git submodule update --init --recursive
	@touch $(SENTINEL)

###########################################################
# Core builds — cross-compile inside Docker
###########################################################

# Usage: $(call docker_build,<toolchain-image>,<cpu-cflags>,<output-dir>)
define docker_build
	@echo "==> Building $(CORE_SONAME) for $(3)"
	@mkdir -p $(BUILD_DIR)/$(3)
	docker run --rm \
		-v "$(CURDIR)":/workspace \
		-w /workspace/$(CACHE_DIR) \
		$(1) \
		/bin/bash -c '\
			make -f Makefile.libretro clean && \
			make -f Makefile.libretro \
				$(COMMON_FLAGS) \
				GIT_VERSION="\" $(GPGX_SHORT)\"" \
				FLAGS="$(GPGX_FLAGS) $(2) -fomit-frame-pointer -ffast-math" \
				-j$(JOBS) && \
			$${CROSS_COMPILE}strip $(CORE_SONAME) \
		'
	@cp $(CACHE_DIR)/$(CORE_SONAME) $(BUILD_DIR)/$(3)/$(CORE_SONAME)
	@echo "==> Built: $(BUILD_DIR)/$(3)/$(CORE_SONAME)"
endef

universal: $(SENTINEL)
	$(call docker_build,$(UNIVERSAL_TOOLCHAIN),$(UNIVERSAL_FLAGS),universal)

verify:
	@test -f "$(UNIVERSAL_DIR)/$(CORE_SONAME)" || \
		{ echo "Error: $(UNIVERSAL_DIR)/$(CORE_SONAME) is missing; run make universal."; exit 1; }
	@docker run --rm \
		-v "$(CURDIR)":/workspace \
		-w /workspace \
		$(UNIVERSAL_TOOLCHAIN) \
		/bin/sh scripts/verify-core.sh "$(UNIVERSAL_DIR)/$(CORE_SONAME)" $(GLIBC_CEILING)

tg5040: $(SENTINEL)
	$(call docker_build,$(TG5040_TOOLCHAIN),$(TG5040_FLAGS),tg5040)

tg5050: $(SENTINEL)
	$(call docker_build,$(TG5050_TOOLCHAIN),$(TG5050_FLAGS),tg5050)

my355: $(SENTINEL)
	$(call docker_build,$(MY355_TOOLCHAIN),$(MY355_FLAGS),my355)

matrix: tg5040 tg5050 my355

###########################################################
# Packaging — one platform-neutral Pak Store archive
###########################################################

# The ZIP holds the pak contents at its root. Pak Store extracts it into
# Emus/<current platform>/<pak.json name>.pak on the device.
package: universal
	@$(MAKE) --no-print-directory verify
	@grep -q '"release_filename": "$(RELEASE_FILENAME)"' pak.json || \
		{ echo "Error: pak.json release_filename is not $(RELEASE_FILENAME)."; exit 1; }
	@echo "==> Assembling $(PAK_NAME).pak"
	@rm -rf "$(PAK_DIR)"
	@mkdir -p "$(PAK_DIR)" "$(DIST_DIR)"
	@cp launch.sh default.cfg pak.json LICENSE "$(PAK_DIR)/"
	@cp "$(UNIVERSAL_DIR)/$(CORE_SONAME)" "$(PAK_DIR)/"
	@chmod 755 "$(PAK_DIR)/launch.sh"
	@rm -f "$(DIST_DIR)/$(RELEASE_FILENAME)"
	@cd "$(PAK_DIR)" && zip -9 -q -r "$(CURDIR)/$(DIST_DIR)/$(RELEASE_FILENAME)" . -x '.*'
	@for f in launch.sh default.cfg pak.json $(CORE_SONAME); do \
		unzip -Z1 "$(DIST_DIR)/$(RELEASE_FILENAME)" | grep -qx "$$f" || \
			{ echo "Error: $$f is missing from the archive root."; exit 1; }; \
	done
	@unzip -p "$(DIST_DIR)/$(RELEASE_FILENAME)" $(CORE_SONAME) | cmp -s - "$(UNIVERSAL_DIR)/$(CORE_SONAME)" || \
		{ echo "Error: archived core differs from $(UNIVERSAL_DIR)/$(CORE_SONAME)."; exit 1; }
	@echo "==> Done: $(DIST_DIR)/$(RELEASE_FILENAME)"

###########################################################
# Cleanup
###########################################################

clean:
	rm -rf $(BUILD_DIR)

distclean: clean
	rm -rf .cache
