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

# Check for non-interactive mode (inherited from build-all.sh or environment)
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"

# Preserve any PROFILE exported by parent (build-all.sh --profile)
_OVERRIDE_PROFILE="${PROFILE:-}"

# Source build configuration
if [ -f "$BUILD_DIR/build.conf" ]; then
    # shellcheck disable=SC1091
    source "$BUILD_DIR/build.conf"
fi

# Restore overridden profile from parent script (takes priority over build.conf)
if [ -n "$_OVERRIDE_PROFILE" ]; then
    PROFILE="$_OVERRIDE_PROFILE"
fi

# Load profile configuration if set (overrides build.conf settings)
if [ -n "${PROFILE:-}" ] && [ -f "$BUILD_DIR/profiles/$PROFILE.conf" ]; then
    # shellcheck disable=SC1090
    source "$BUILD_DIR/profiles/$PROFILE.conf"
fi

# Read version from VERSION file
if [ -f "$PROJECT_ROOT/VERSION" ]; then
    VERSION="$(cat "$PROJECT_ROOT/VERSION")-alpha"
else
    VERSION="0.1-alpha"
fi

# Include profile name in ISO filename to avoid overwrites when building multiple profiles
if [ -n "${PROFILE:-}" ]; then
    ISO_NAME="VirtOS-${VERSION}-${PROFILE}-$(date +%Y%m%d).iso"
else
    ISO_NAME="VirtOS-${VERSION}-$(date +%Y%m%d).iso"
fi

echo "=== FlossWare VirtOS - ISO Build ==="
echo ""

# Check customization
if [ ! -f "$WORKSPACE_DIR/.customized" ]; then
    echo "WARNING: Customization not detected!"
    echo "Run ./scripts/customize.sh first for FlossWare features"
    echo ""
    if [ "$NON_INTERACTIVE" = true ]; then
        echo "Non-interactive mode: continuing without customization"
    else
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# Check tools - detect available ISO creation tool
echo "Checking build tools..."
ISO_TOOL=""
if command -v genisoimage >/dev/null 2>&1; then
    ISO_TOOL="genisoimage"
elif command -v mkisofs >/dev/null 2>&1; then
    ISO_TOOL="mkisofs"
elif command -v xorriso >/dev/null 2>&1; then
    ISO_TOOL="xorriso"
fi

if [ -z "$ISO_TOOL" ]; then
    echo "  ERROR: No ISO creation tool found"
    echo ""
    echo "Install one of the following:"
    echo "  Debian/Ubuntu: sudo apt install genisoimage"
    echo "  Fedora/RHEL:   sudo dnf install xorriso"
    echo "  Alternative:   sudo dnf install cdrkit (provides mkisofs)"
    exit 1
fi
echo "  Using ISO tool: $ISO_TOOL"

if ! command -v isohybrid >/dev/null 2>&1; then
    echo "  WARNING: isohybrid not found - ISO will not be USB-bootable"
    echo "  Install: syslinux-utils (Debian/Ubuntu) or syslinux (Fedora/RHEL)"
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
    sudo tee boot/isolinux/boot.msg >/dev/null <<EOF


  FlossWare VirtOS v${VERSION}

  Press <Enter> to boot


EOF
fi

# Create ISO with proper bootloader
echo "Creating ISO image with $ISO_TOOL..."
if [ "$ISO_TOOL" = "xorriso" ]; then
    xorriso -as mkisofs \
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
else
    # genisoimage and mkisofs share the same CLI interface
    "$ISO_TOOL" \
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
fi

# Make ISO hybrid (bootable from USB) if enabled in build.conf
if [ "${CREATE_HYBRID_ISO:-yes}" = "yes" ]; then
    if command -v isohybrid >/dev/null 2>&1; then
        echo "Making ISO hybrid (USB-bootable)..."
        isohybrid "$OUTPUT_DIR/$ISO_NAME" || {
            echo "WARNING: isohybrid failed, ISO may not boot from USB"
        }
    else
        echo "Skipping hybrid ISO (isohybrid not available)"
    fi
else
    echo "Skipping hybrid ISO (CREATE_HYBRID_ISO=no in build.conf)"
fi

# Calculate checksums if enabled in build.conf
if [ "${GENERATE_CHECKSUMS:-yes}" = "yes" ]; then
    echo "Calculating checksums..."
    cd "$OUTPUT_DIR"
    md5sum "$ISO_NAME" >"$ISO_NAME.md5"
    sha256sum "$ISO_NAME" >"$ISO_NAME.sha256"
else
    echo "Skipping checksum generation (GENERATE_CHECKSUMS=no in build.conf)"
    cd "$OUTPUT_DIR"
fi

# Get size
SIZE=$(du -h "$ISO_NAME" | cut -f1)

echo ""
echo "=== Build Complete ==="
echo ""
echo "ISO created: $OUTPUT_DIR/$ISO_NAME"
echo "Size: $SIZE"
echo ""
if [ -f "$ISO_NAME.md5" ] && [ -f "$ISO_NAME.sha256" ]; then
    echo "Checksums:"
    echo "  MD5:    $(<"$ISO_NAME".md5)"
    echo "  SHA256: $(<"$ISO_NAME".sha256)"
fi
echo ""
echo "To test in QEMU/KVM:"
echo "  qemu-system-x86_64 -enable-kvm -m 2048 -cdrom $OUTPUT_DIR/$ISO_NAME"
echo ""
echo "To write to USB (replace /dev/sdX with your USB device):"
echo "  sudo dd if=$OUTPUT_DIR/$ISO_NAME of=/dev/sdX bs=4M status=progress && sync"
echo ""
echo "WARNING: Double-check the device name - dd will overwrite the target!"
echo ""
