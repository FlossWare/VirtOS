#!/bin/bash
#
# verify-version-sync.sh - Verify VERSION file matches all package metadata
#
# This script ensures version synchronization across:
# - VERSION file (source of truth)
# - packages/*/virtos-*.tcz.info files
#
# Exit code 0 = all synchronized
# Exit code 1 = mismatch found

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "VirtOS Version Synchronization Check"
echo "====================================="
echo ""

# Read main version
cd "$REPO_ROOT"
MAIN_VERSION="$(cat VERSION)"
echo "VERSION file: $MAIN_VERSION"
echo ""

# Check all package info files (source only, not build output)
echo "Checking package metadata files..."
ERRORS=0

for info_file in packages/*/virtos-*.tcz.info; do
    # Skip output directory (contains generated files)
    if [[ "$info_file" == *"/output/"* ]]; then
        continue
    fi

    if [ ! -f "$info_file" ]; then
        continue
    fi

    # Extract version from info file
    PKG_VERSION=$(grep '^Version:' "$info_file" | awk '{print $2}')

    if [ -z "$PKG_VERSION" ]; then
        echo "❌ ERROR: No Version field found in $info_file"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    if [ "$PKG_VERSION" != "$MAIN_VERSION" ]; then
        echo "❌ MISMATCH: $info_file"
        echo "   Expected: $MAIN_VERSION"
        echo "   Found:    $PKG_VERSION"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ OK: $info_file ($PKG_VERSION)"
    fi
done

echo ""

# Summary
if [ $ERRORS -eq 0 ]; then
    echo "✅ All versions synchronized to $MAIN_VERSION"
    exit 0
else
    echo "❌ Found $ERRORS version mismatch(es)"
    echo ""
    echo "To fix:"
    echo "  1. Update package .tcz.info files to match VERSION"
    echo "  2. Or run: ./ci/sync-versions.sh"
    exit 1
fi
