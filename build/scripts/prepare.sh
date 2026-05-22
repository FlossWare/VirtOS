#!/bin/bash
# FlossWare VirtOS - Preparation Script
# Downloads and prepares Tiny Core Linux base

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$BUILD_DIR")"

# Configuration
TC_VERSION="15.x"  # Adjust to latest stable
TC_ARCH="x86_64"
TC_MIRROR="http://tinycorelinux.net"
DOWNLOAD_DIR="$BUILD_DIR/downloads"
WORKSPACE_DIR="$BUILD_DIR/workspace"

echo "=== FlossWare VirtOS - Prepare Build Environment ==="
echo ""

# Create directories
echo "Creating build directories..."
mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$WORKSPACE_DIR"
mkdir -p "$BUILD_DIR/output"

# Download Tiny Core base
echo ""
echo "Downloading Tiny Core Linux $TC_VERSION ($TC_ARCH)..."
cd "$DOWNLOAD_DIR"

TC_ISO="CorePure64-current.iso"
TC_URL="$TC_MIRROR/$TC_VERSION/$TC_ARCH/release/$TC_ISO"

if [ -f "$TC_ISO" ]; then
    echo "  $TC_ISO already exists, skipping download"
else
    echo "  Downloading from $TC_URL"
    wget -c "$TC_URL" || {
        echo "ERROR: Failed to download Tiny Core"
        echo "Please check version/URL at http://tinycorelinux.net"
        exit 1
    }
fi

# Download checksums
echo ""
echo "Downloading checksums..."
if [ ! -f "CorePure64-current.iso.md5.txt" ]; then
    wget -c "$TC_MIRROR/$TC_VERSION/$TC_ARCH/release/CorePure64-current.iso.md5.txt" || echo "Warning: Checksum not available"
fi

# Verify checksum if available
if [ -f "CorePure64-current.iso.md5.txt" ]; then
    echo "Verifying checksum..."
    md5sum -c CorePure64-current.iso.md5.txt || {
        echo "ERROR: Checksum verification failed!"
        exit 1
    }
fi

# Extract ISO
echo ""
echo "Extracting ISO..."
EXTRACT_DIR="$WORKSPACE_DIR/iso-extract"
CONTENTS_DIR="$WORKSPACE_DIR/iso-contents"

mkdir -p "$EXTRACT_DIR"
if [ -d "$CONTENTS_DIR" ]; then
    echo "  Cleaning old extraction..."
    rm -rf "$CONTENTS_DIR"
fi
mkdir -p "$CONTENTS_DIR"

# Mount and copy
echo "  Mounting ISO..."
sudo mount -o loop "$TC_ISO" "$EXTRACT_DIR" || {
    echo "ERROR: Failed to mount ISO"
    exit 1
}

echo "  Copying contents..."
cp -r "$EXTRACT_DIR"/* "$CONTENTS_DIR/"

echo "  Unmounting ISO..."
sudo umount "$EXTRACT_DIR"

# Extract initrd (core.gz)
echo ""
echo "Extracting initrd (core.gz)..."
INITRD_DIR="$WORKSPACE_DIR/initrd"
if [ -d "$INITRD_DIR" ]; then
    rm -rf "$INITRD_DIR"
fi
mkdir -p "$INITRD_DIR"

cd "$INITRD_DIR"
zcat "$CONTENTS_DIR/boot/core.gz" | sudo cpio -i -H newc -d

echo ""
echo "Checking for KVM kernel modules..."
if [ -d "$INITRD_DIR/lib/modules" ]; then
    KVM_MODULES=$(sudo find "$INITRD_DIR/lib/modules" -name "*kvm*.ko*" 2>/dev/null || true)
    if [ -n "$KVM_MODULES" ]; then
        echo "  Found KVM modules:"
        echo "$KVM_MODULES" | while read mod; do
            echo "    - $(basename $mod)"
        done
    else
        echo "  WARNING: No KVM modules found in kernel!"
        echo "  You may need to compile a custom kernel or use different TC version"
    fi
else
    echo "  Module directory not found, skipping check"
fi

# Download TCZ extensions (if online repo available)
echo ""
echo "Setting up TCZ repository access..."
TCZ_REPO="$TC_MIRROR/$TC_VERSION/$TC_ARCH/tcz"
TCZ_DIR="$WORKSPACE_DIR/tcz"
mkdir -p "$TCZ_DIR"

# List of packages we want (we'll download them later if available)
cat > "$TCZ_DIR/package-list.txt" << 'EOF'
# Core packages
bash.tcz
openssh.tcz
vim.tcz

# Networking
bridge-utils.tcz
iptables.tcz
iproute2.tcz
dnsmasq.tcz

# Virtualization (check availability)
qemu.tcz
libvirt.tcz
lxc.tcz

# Container runtime
docker.tcz
containerd.tcz

# Monitoring
htop.tcz
EOF

echo "  Package list created at $TCZ_DIR/package-list.txt"
echo "  Note: Not all packages may be available in official repo"
echo "  Some will need to be compiled from source"

# Create marker file
echo ""
echo "Creating build markers..."
date > "$WORKSPACE_DIR/.prepared"
echo "$TC_VERSION" > "$WORKSPACE_DIR/.tc-version"

echo ""
echo "=== Preparation Complete ==="
echo ""
echo "Build environment ready:"
echo "  Tiny Core version: $TC_VERSION"
echo "  ISO extracted to:  $CONTENTS_DIR"
echo "  Initrd extracted:  $INITRD_DIR"
echo "  TCZ cache:         $TCZ_DIR"
echo ""
echo "Next steps:"
echo "  1. Review kernel modules (KVM support)"
echo "  2. Run ./scripts/customize.sh to add FlossWare customizations"
echo "  3. Run ./scripts/iso.sh to build final ISO"
echo ""
