#!/bin/bash
# FlossWare VirtOS - ISO Build Script
# Creates bootable ISO image

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$BUILD_DIR")"

WORKSPACE_DIR="$BUILD_DIR/workspace"
ISO_CONTENTS="$WORKSPACE_DIR/iso-contents"
OUTPUT_DIR="$BUILD_DIR/output"

# Read version from VERSION file
if [ -f "$PROJECT_ROOT/VERSION" ]; then
    VERSION="$(cat "$PROJECT_ROOT/VERSION")-alpha"
else
    VERSION="0.1-alpha"
fi
ISO_NAME="VirtOS-${VERSION}-$(date +%Y%m%d).iso"

echo "=== FlossWare VirtOS - ISO Build ==="
echo ""

# Check customization
if [ ! -f "$WORKSPACE_DIR/.customized" ]; then
    echo "WARNING: Customization not detected!"
    echo "Run ./scripts/customize.sh first for FlossWare features"
    echo ""
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check tools
echo "Checking build tools..."
TOOLS_OK=true
for tool in genisoimage isohybrid; do
    if ! command -v $tool >/dev/null 2>&1; then
        echo "  ERROR: $tool not found"
        TOOLS_OK=false
    fi
done

if [ "$TOOLS_OK" = false ]; then
    echo ""
    echo "Install required tools:"
    echo "  Debian/Ubuntu: sudo apt install genisoimage syslinux-utils"
    echo "  Fedora:        sudo dnf install genisoimage syslinux"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Build ISO
echo ""
echo "Building ISO: $ISO_NAME"
echo "  Source: $ISO_CONTENTS"
echo "  Output: $OUTPUT_DIR/$ISO_NAME"
echo ""

cd "$ISO_CONTENTS"

# Update boot message
if [ -d "boot/isolinux" ]; then
    echo "Updating boot message..."
    cat >boot/isolinux/boot.msg <<EOF


  FlossWare VirtOS v${VERSION}

  Press <Enter> to boot


EOF
fi

# Create ISO with proper bootloader
echo "Creating ISO image..."
genisoimage \
    -l -J -R \
    -V "VirtOS" \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -b boot/isolinux/isolinux.bin \
    -c boot/isolinux/boot.cat \
    -o "$OUTPUT_DIR/$ISO_NAME" \
    . || {
    echo "ERROR: ISO creation failed"
    exit 1
}

# Make ISO hybrid (bootable from USB)
echo "Making ISO hybrid (USB-bootable)..."
isohybrid "$OUTPUT_DIR/$ISO_NAME" || {
    echo "WARNING: isohybrid failed, ISO may not boot from USB"
}

# Calculate checksum
echo "Calculating checksum..."
cd "$OUTPUT_DIR"
md5sum "$ISO_NAME" >"$ISO_NAME.md5"
sha256sum "$ISO_NAME" >"$ISO_NAME.sha256"

# Get size
SIZE=$(du -h "$ISO_NAME" | cut -f1)

echo ""
echo "=== Build Complete ==="
echo ""
echo "ISO created: $OUTPUT_DIR/$ISO_NAME"
echo "Size: $SIZE"
echo ""
echo "Checksums:"
echo "  MD5:    $(cat $ISO_NAME.md5)"
echo "  SHA256: $(cat $ISO_NAME.sha256)"
echo ""
echo "To test in QEMU/KVM:"
echo "  qemu-system-x86_64 -enable-kvm -m 2048 -cdrom $OUTPUT_DIR/$ISO_NAME"
echo ""
echo "To write to USB (replace /dev/sdX with your USB device):"
echo "  sudo dd if=$OUTPUT_DIR/$ISO_NAME of=/dev/sdX bs=4M status=progress && sync"
echo ""
echo "WARNING: Double-check the device name - dd will overwrite the target!"
echo ""
