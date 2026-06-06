#!/bin/bash
# Build VirtOS ISO with serial console support for automated testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$BUILD_DIR")"

echo "=== Building VirtOS with Serial Console Support ==="
echo ""

# Run prepare and customize
echo "Step 1: Prepare and customize..."
cd "$BUILD_DIR"
bash scripts/prepare.sh
bash scripts/customize.sh

# Modify isolinux.cfg to add serial console
echo ""
echo "Step 2: Adding serial console support..."
ISOLINUX_CFG="$BUILD_DIR/workspace/iso-contents/boot/isolinux/isolinux.cfg"

if [ -f "$ISOLINUX_CFG" ]; then
    echo "  Modifying $ISOLINUX_CFG"

    # Backup original
    sudo cp "$ISOLINUX_CFG" "$ISOLINUX_CFG.bak"

    # Replace append line to include console=ttyS0
    sudo sed -i 's/append loglevel=3/append loglevel=3 console=tty0 console=ttyS0,115200n8/' "$ISOLINUX_CFG"

    echo "  Added: console=tty0 console=ttyS0,115200n8"
    echo ""
    echo "  New configuration:"
    grep "append" "$ISOLINUX_CFG"
else
    echo "  ERROR: $ISOLINUX_CFG not found"
    exit 1
fi

# Build ISO
echo ""
echo "Step 3: Building ISO..."
bash scripts/iso.sh

echo ""
echo "=== Serial Console ISO Complete ==="
echo ""
echo "To test with serial console:"
echo "  qemu-system-x86_64 -enable-kvm -m 2048 \\"
echo "    -cdrom build/output/VirtOS-*-serial-*.iso \\"
echo "    -boot d -nographic"
echo ""
