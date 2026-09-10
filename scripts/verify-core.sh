#!/bin/sh
# Check that a core built with the universal toolchain can be loaded by
# minarch on every supported firmware. Runs inside the toolchain image.
#
# Usage: verify-core.sh <core.so> <glibc-ceiling>
set -eu

CORE=$1
GLIBC_CEILING=$2
READELF=${CROSS_COMPILE}readelf

fail() {
	echo "Error: $*" >&2
	exit 1
}

"$READELF" -h "$CORE" | grep -q 'Machine:.*AArch64' || fail "$CORE is not an AArch64 ELF"
"$READELF" -h "$CORE" | grep -q 'Type:.*DYN' || fail "$CORE is not a shared object"

if "$READELF" -d "$CORE" | grep -Eq '\((RPATH|RUNPATH)\)'; then
	fail "$CORE embeds an RPATH or RUNPATH"
fi

highest=$("$READELF" -V "$CORE" | grep -o 'GLIBC_[0-9][0-9.]*' | sed 's/^GLIBC_//' | sort -uV | tail -n 1)
[ -n "$highest" ] || fail "$CORE has no GLIBC symbol versions"

if [ "$(printf '%s\n%s\n' "$highest" "$GLIBC_CEILING" | sort -V | tail -n 1)" != "$GLIBC_CEILING" ]; then
	fail "$CORE needs GLIBC_$highest, above the GLIBC_$GLIBC_CEILING ceiling"
fi

echo "==> Verified $(basename "$CORE"): AArch64, no RPATH, highest GLIBC_$highest (ceiling $GLIBC_CEILING)"
"$READELF" -d "$CORE" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/    needs \1/p'
