#!/bin/bash
# VirtOS - Pin Checksums for Build Reproducibility
#
# Generates SHA256 checksums for all downloaded build artifacts
# and writes them to build/pinned-checksums.sha256.
#
# Run this AFTER a verified build to lock down the hashes for
# reproducible future builds.
#
# Usage:
#   ./pin-checksums.sh                    # Pin from workspace downloads
#   ./pin-checksums.sh --verify-only      # Verify existing pins (no update)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"
CHECKSUMS_FILE="$BUILD_DIR/pinned-checksums.sha256"
DOWNLOAD_DIR="$BUILD_DIR/downloads"
TCZ_DIR="$BUILD_DIR/workspace/tcz"

VERIFY_ONLY=false
if [ "${1:-}" = "--verify-only" ]; then
    VERIFY_ONLY=true
fi

echo "=== VirtOS Checksum Pinning ==="
echo ""

if [ "$VERIFY_ONLY" = true ]; then
    echo "Mode: Verify existing pins"
    echo ""

    if [ ! -f "$CHECKSUMS_FILE" ]; then
        echo "ERROR: No pinned checksums file found at $CHECKSUMS_FILE"
        exit 1
    fi

    ERRORS=0

    # Verify ISO
    if [ -f "$DOWNLOAD_DIR/CorePure64-current.iso" ]; then
        ISO_HASH=$(sha256sum "$DOWNLOAD_DIR/CorePure64-current.iso" | awk '{print $1}')
        EXPECTED_HASH=$(grep -v '^#' "$CHECKSUMS_FILE" | grep -v '^$' | grep "  CorePure64-current.iso$" | awk '{print $1}' | head -1)
        if [ -n "$EXPECTED_HASH" ] && [ "$ISO_HASH" = "$EXPECTED_HASH" ]; then
            echo "  OK  CorePure64-current.iso"
        else
            echo "  FAIL  CorePure64-current.iso (hash does not match pinned checksum)"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo "  SKIP  CorePure64-current.iso (not downloaded)"
    fi

    # Verify TCZ packages
    if [ -d "$TCZ_DIR" ]; then
        for tcz in "$TCZ_DIR"/*.tcz; do
            if [ -f "$tcz" ]; then
                PKG_NAME=$(basename "$tcz")
                PKG_HASH=$(sha256sum "$tcz" | awk '{print $1}')
                EXPECTED_HASH=$(grep -v '^#' "$CHECKSUMS_FILE" | grep -v '^$' | grep "  ${PKG_NAME}$" | awk '{print $1}' | head -1)
                if [ -n "$EXPECTED_HASH" ] && [ "$PKG_HASH" = "$EXPECTED_HASH" ]; then
                    echo "  OK  $PKG_NAME"
                else
                    echo "  FAIL  $PKG_NAME (hash does not match pinned checksum)"
                    ERRORS=$((ERRORS + 1))
                fi
            fi
        done
    fi

    echo ""
    if [ "$ERRORS" -eq 0 ]; then
        echo "All downloaded artifacts match pinned checksums."
        exit 0
    else
        echo "ERROR: $ERRORS artifact(s) do not match pinned checksums!"
        echo ""
        echo "This could mean:"
        echo "  1. Upstream packages were updated (re-pin after verification)"
        echo "  2. Downloads were corrupted (re-download and verify)"
        echo "  3. Supply chain compromise (investigate before proceeding)"
        exit 1
    fi
fi

# --- Pin mode ---
echo "Mode: Generate pinned checksums"
echo ""

# Start with header
cat >"$CHECKSUMS_FILE" <<'HEADER'
# VirtOS Pinned Checksums (SHA256)
# =================================
# This file pins SHA256 hashes for all external downloads used in the build.
# It ensures build reproducibility and supply-chain integrity by verifying
# downloads against known-good hashes stored in version control.
#
# Format: <sha256hash>  <filename>
#
# To update after verifying a new download is legitimate:
#   sha256sum <file> >> build/pinned-checksums.sha256
#
# To regenerate all checksums from a known-good build:
#   build/scripts/pin-checksums.sh
#
# IMPORTANT: Only update these hashes after manually verifying the
# authenticity of new downloads (e.g., checking GPG signatures,
# comparing hashes from multiple mirrors, reviewing release notes).
HEADER

PINNED=0

# Pin ISO checksum
if [ -f "$DOWNLOAD_DIR/CorePure64-current.iso" ]; then
    echo "" >>"$CHECKSUMS_FILE"
    echo "# --- Tiny Core Linux Base ISO ---" >>"$CHECKSUMS_FILE"
    (cd "$DOWNLOAD_DIR" && sha256sum "CorePure64-current.iso") >>"$CHECKSUMS_FILE"
    echo "  Pinned: CorePure64-current.iso"
    PINNED=$((PINNED + 1))
else
    echo "  Skip: CorePure64-current.iso (not found in $DOWNLOAD_DIR)"
    echo "" >>"$CHECKSUMS_FILE"
    echo "# --- Tiny Core Linux Base ISO ---" >>"$CHECKSUMS_FILE"
    echo "# (not yet pinned -- download first with prepare.sh)" >>"$CHECKSUMS_FILE"
fi

# Pin TCZ package checksums
if [ -d "$TCZ_DIR" ] && ls "$TCZ_DIR"/*.tcz >/dev/null 2>&1; then
    echo "" >>"$CHECKSUMS_FILE"
    echo "# --- Core TCZ Packages ---" >>"$CHECKSUMS_FILE"
    for tcz in "$TCZ_DIR"/*.tcz; do
        if [ -f "$tcz" ]; then
            PKG_NAME=$(basename "$tcz")
            (cd "$TCZ_DIR" && sha256sum "$PKG_NAME") >>"$CHECKSUMS_FILE"
            echo "  Pinned: $PKG_NAME"
            PINNED=$((PINNED + 1))
        fi
    done
else
    echo "  Skip: No TCZ packages found in $TCZ_DIR"
    echo "" >>"$CHECKSUMS_FILE"
    echo "# --- Core TCZ Packages ---" >>"$CHECKSUMS_FILE"
    echo "# (not yet pinned -- download first with download-tcz.sh)" >>"$CHECKSUMS_FILE"
fi

echo ""
echo "=== Pinning Complete ==="
echo "Pinned $PINNED artifact(s) to: $CHECKSUMS_FILE"
echo ""
echo "Next steps:"
echo "  1. Review the checksums file: cat $CHECKSUMS_FILE"
echo "  2. Commit to version control: git add $CHECKSUMS_FILE"
echo "  3. Future builds will verify downloads against these hashes"
