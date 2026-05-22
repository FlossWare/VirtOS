#!/bin/bash
# FlossWare VirtOS - Complete Build Pipeline

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "FlossWare VirtOS - Full Build"
echo "=========================================="
echo ""

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
