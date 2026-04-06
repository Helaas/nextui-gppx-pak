###########################################################
# NextUI GPGX Pak — Genesis Plus GX libretro core
###########################################################

# Core source
GPGX_REPO   := https://github.com/libretro/Genesis-Plus-GX.git
GPGX_HASH   := b72b8c967adc50311dc3bb700c0818518bee74ef
CORE_SONAME := genesis_plus_gx_libretro.so

# Pak metadata
PAK_NAME := GPGX

# Directories
BUILD_DIR   := build
DIST_DIR    := $(BUILD_DIR)/release
STAGING_DIR := $(BUILD_DIR)/staging
CACHE_DIR   := .cache/genesis-plus-gx
SENTINEL    := .cache/.gpgx-$(GPGX_HASH)

# Toolchain images
TG5040_TOOLCHAIN := ghcr.io/loveretro/tg5040-toolchain:latest
TG5050_TOOLCHAIN := ghcr.io/loveretro/tg5050-toolchain:latest
MY355_TOOLCHAIN  := ghcr.io/loveretro/my355-toolchain:latest

# Platform-specific compiler flags
TG5040_FLAGS := -mcpu=cortex-a53 -mtune=cortex-a53
TG5050_FLAGS := -mcpu=cortex-a55 -mtune=cortex-a55
MY355_FLAGS  := -mcpu=cortex-a55 -mtune=cortex-a55

# Common build flags passed to the libretro makefile
# NOTE: CPU-specific flags go via FLAGS= (appended to CFLAGS inside the Makefile).
# We must include -D_7ZIP_ST and -DZSTD_DISABLE_ASM because the Makefile.common
# sets them via FLAGS+=, which is overridden by our command-line FLAGS=.
COMMON_FLAGS := platform=unix FRONTEND_SUPPORTS_RGB565=1 HAVE_CHD=1
GPGX_FLAGS   := -D_7ZIP_ST -DZSTD_DISABLE_ASM

# Parallel jobs inside container (auto-detect)
JOBS := $$(nproc)

###########################################################
# Phony targets
###########################################################

.PHONY: all package package-tg5040 package-tg5050 package-my355 \
        tg5040 tg5050 my355 checkout clean distclean help

all: package

help:
	@echo "NextUI GPGX Pak build system"
	@echo ""
	@echo "Targets:"
	@echo "  make package          Build all platforms and create .pakz"
	@echo "  make tg5040           Build core for TG5040 only"
	@echo "  make tg5050           Build core for TG5050 only"
	@echo "  make my355            Build core for MY355 only"
	@echo "  make package-tg5040   Build + package .pak for TG5040"
	@echo "  make package-tg5050   Build + package .pak for TG5050"
	@echo "  make package-my355    Build + package .pak for MY355"
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
# Platform builds — cross-compile inside Docker
###########################################################

# Usage: $(call docker_build,<toolchain-image>,<platform-cflags>,<output-dir>)
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
				FLAGS="$(GPGX_FLAGS) $(2) -fomit-frame-pointer -ffast-math" \
				-j$(JOBS) && \
			$${CROSS_COMPILE}strip $(CORE_SONAME) \
		'
	@cp $(CACHE_DIR)/$(CORE_SONAME) $(BUILD_DIR)/$(3)/$(CORE_SONAME)
	@echo "==> Built: $(BUILD_DIR)/$(3)/$(CORE_SONAME)"
endef

tg5040: $(SENTINEL)
	$(call docker_build,$(TG5040_TOOLCHAIN),$(TG5040_FLAGS),tg5040)

tg5050: $(SENTINEL)
	$(call docker_build,$(TG5050_TOOLCHAIN),$(TG5050_FLAGS),tg5050)

my355: $(SENTINEL)
	$(call docker_build,$(MY355_TOOLCHAIN),$(MY355_FLAGS),my355)

###########################################################
# Packaging — assemble .pak directories
###########################################################

# Usage: $(call assemble_pak,<platform>)
define assemble_pak
	@echo "==> Assembling $(PAK_NAME).pak for $(1)"
	@rm -rf "$(BUILD_DIR)/$(1)/$(PAK_NAME).pak"
	@mkdir -p "$(BUILD_DIR)/$(1)/$(PAK_NAME).pak"
	@cp launch.sh      "$(BUILD_DIR)/$(1)/$(PAK_NAME).pak/"
	@cp default.cfg    "$(BUILD_DIR)/$(1)/$(PAK_NAME).pak/"
	@cp "$(BUILD_DIR)/$(1)/$(CORE_SONAME)" "$(BUILD_DIR)/$(1)/$(PAK_NAME).pak/"
	@if [ -f LICENSE ]; then cp LICENSE "$(BUILD_DIR)/$(1)/$(PAK_NAME).pak/"; fi
endef

package-tg5040: tg5040
	$(call assemble_pak,tg5040)

package-tg5050: tg5050
	$(call assemble_pak,tg5050)

package-my355: my355
	$(call assemble_pak,my355)

###########################################################
# Final .pakz — multi-platform archive
###########################################################

package: package-tg5040 package-tg5050 package-my355
	@echo "==> Creating $(PAK_NAME).pakz"
	@rm -rf $(STAGING_DIR)
	@mkdir -p $(STAGING_DIR)/Emus/tg5040
	@mkdir -p $(STAGING_DIR)/Emus/tg5050
	@mkdir -p $(STAGING_DIR)/Emus/my355
	@cp -a "$(BUILD_DIR)/tg5040/$(PAK_NAME).pak" $(STAGING_DIR)/Emus/tg5040/
	@cp -a "$(BUILD_DIR)/tg5050/$(PAK_NAME).pak" $(STAGING_DIR)/Emus/tg5050/
	@cp -a "$(BUILD_DIR)/my355/$(PAK_NAME).pak"  $(STAGING_DIR)/Emus/my355/
	@mkdir -p $(DIST_DIR)
	@cd $(STAGING_DIR) && zip -9 -r "$(CURDIR)/$(DIST_DIR)/$(PAK_NAME).pakz" . \
		-x '.DS_Store' '**/.DS_Store'
	@echo "==> Done: $(DIST_DIR)/$(PAK_NAME).pakz"

###########################################################
# Cleanup
###########################################################

clean:
	rm -rf $(BUILD_DIR)

distclean: clean
	rm -rf .cache
