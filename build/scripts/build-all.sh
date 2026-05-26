#!/bin/bash
# FlossWare VirtOS - Complete Build Pipeline

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"

# Source and validate build configuration
if [ -f "$BUILD_DIR/build.conf" ]; then
    source "$BUILD_DIR/build.conf"
else
    echo "ERROR: build.conf not found at $BUILD_DIR/build.conf" >&2
    exit 1
fi

# Validate profile if set
if [ -n "${PROFILE:-}" ]; then
    VALID_PROFILES="minimal standard full containers developer kubernetes storage"

    if ! echo " $VALID_PROFILES " | grep -q " $PROFILE "; then
        echo "ERROR: Invalid profile '$PROFILE'" >&2
        echo "" >&2
        echo "Valid profiles:" >&2
        for p in $VALID_PROFILES; do
            echo "  - $p" >&2
        done
        echo "" >&2
        echo "Edit build/build.conf to select a valid profile" >&2
        exit 1
    fi
fi

echo "=========================================="
echo "FlossWare VirtOS - Full Build"
echo "=========================================="
echo ""
if [ -n "${PROFILE:-}" ]; then
    echo "Profile: $PROFILE"
    echo ""
fi

# Step 1: Prepare
echo "Step 1/3: Preparing build environment..."
"$SCRIPT_DIR/prepare.sh"

echo ""
read -p "Preparation complete. Continue to customization? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    exit 0
fi

# Step 2: Customize
echo ""
echo "Step 2/3: Customizing system..."
"$SCRIPT_DIR/customize.sh"

echo ""
read -p "Customization complete. Continue to ISO build? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    exit 0
fi

# Step 3: Build ISO
echo ""
echo "Step 3/3: Building ISO..."
"$SCRIPT_DIR/iso.sh"

echo ""
echo "=========================================="
echo "Build pipeline complete!"
echo "=========================================="
