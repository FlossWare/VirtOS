#!/bin/bash
#
# sync-versions.sh - Synchronize all package versions with VERSION file
#
# This script updates all package .tcz.info files to match the VERSION file.
# Used by CD pipeline after version bumps.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "VirtOS Version Synchronization"
echo "==============================="
echo ""

# Read main version
cd "$REPO_ROOT"
MAIN_VERSION="$(cat VERSION)"
echo "Synchronizing to version: $MAIN_VERSION"
echo ""

# Update all package info files (source only, not build output)
UPDATED=0

for info_file in packages/*/virtos-*.tcz.info; do
    # Skip output directory (contains generated files)
    if [[ "$info_file" == *"/output/"* ]]; then
        continue
    fi

    if [ ! -f "$info_file" ]; then
        continue
    fi

    # Check current version
    CURRENT_VERSION=$(grep '^Version:' "$info_file" | awk '{print $2}' || echo "")

    if [ "$CURRENT_VERSION" = "$MAIN_VERSION" ]; then
        echo "⏭️  SKIP: $info_file (already $MAIN_VERSION)"
    else
        # Update version
        sed -i "s/^Version:.*$/Version:        $MAIN_VERSION/" "$info_file"
        echo "✅ UPDATE: $info_file ($CURRENT_VERSION → $MAIN_VERSION)"
        UPDATED=$((UPDATED + 1))
    fi
done

echo ""
echo "Updated $UPDATED package(s) to version $MAIN_VERSION"

# Verify sync
echo ""
echo "Verifying synchronization..."
"$SCRIPT_DIR/verify-version-sync.sh"
