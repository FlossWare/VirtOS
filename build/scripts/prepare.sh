#!/bin/bash
# FlossWare VirtOS - Preparation Script
# Downloads and prepares Tiny Core Linux base

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"

# Source security library for path validation
COMMON_LIB="${BUILD_DIR}/../config/custom-scripts/lib/virtos-common.sh"
if [ -f "$COMMON_LIB" ]; then
    # shellcheck disable=SC1090
    source "$COMMON_LIB"
fi

# Path validation function (fallback if virtos-common.sh not available)
validate_safe_path() {
    local path="$1"
    # Prevent path traversal and command injection
    # Disallow: .. (parent directory), ; & | $ ` < > ( ) { } [ ] ! \ " '
    if echo "$path" | grep -qE '\.\.|[;&|$`<>(){}[\]!\\"]|'"'"''; then
        echo "Error: Invalid or unsafe path: $path" >&2
        return 1
    fi
    # Path must be absolute or relative without dangerous chars
    if ! echo "$path" | grep -qE '^[a-zA-Z0-9/_. -]+$'; then
        echo "Error: Path contains invalid characters: $path" >&2
        return 1
    fi
    return 0
}

# Preserve any PROFILE exported by parent (build-all.sh --profile)
_OVERRIDE_PROFILE="${PROFILE:-}"

# Source build configuration for TC version and other settings
if [ -f "$BUILD_DIR/build.conf" ]; then
    # shellcheck disable=SC1091
    source "$BUILD_DIR/build.conf"
else
    echo "ERROR: build.conf not found at $BUILD_DIR/build.conf" >&2
    exit 1
fi

# Restore overridden profile from parent script (takes priority over build.conf)
if [ -n "$_OVERRIDE_PROFILE" ]; then
    PROFILE="$_OVERRIDE_PROFILE"
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
        echo "Edit build/build.conf and select a valid PROFILE" >&2
        exit 1
    fi

    # Load profile configuration to override build.conf settings
    if [ -f "$BUILD_DIR/profiles/$PROFILE.conf" ]; then
        # shellcheck disable=SC1090
        source "$BUILD_DIR/profiles/$PROFILE.conf"
    fi
fi

# Additional configuration
TC_MIRROR="${TC_MIRROR:-http://tinycorelinux.net}"
DOWNLOAD_DIR="$BUILD_DIR/downloads"
WORKSPACE_DIR="$BUILD_DIR/workspace"
TCZ_DIR="$WORKSPACE_DIR/tcz"

# Validate critical directory paths to prevent attacks
if ! validate_safe_path "$DOWNLOAD_DIR"; then
    echo "ERROR: Invalid download directory path: $DOWNLOAD_DIR"
    exit 1
fi

if ! validate_safe_path "$WORKSPACE_DIR"; then
    echo "ERROR: Invalid workspace directory path: $WORKSPACE_DIR"
    exit 1
fi

if ! validate_safe_path "$TCZ_DIR"; then
    echo "ERROR: Invalid TCZ directory path: $TCZ_DIR"
    exit 1
fi

# Ensure directories are within BUILD_DIR (prevent directory traversal)
for dir in "$DOWNLOAD_DIR" "$WORKSPACE_DIR"; do
    case "$dir" in
        "$BUILD_DIR"*)
            # Path is within BUILD_DIR, safe to continue
            ;;
        *)
            echo "ERROR: Directory must be within build directory: $dir"
            exit 1
            ;;
    esac
done

echo "=== FlossWare VirtOS - Prepare Build Environment ==="
if [ -n "${PROFILE:-}" ]; then
    echo "Profile: $PROFILE"
fi
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

# Validate TC_ISO filename to prevent path traversal
if ! validate_safe_path "$TC_ISO"; then
    echo "ERROR: Invalid ISO filename: $TC_ISO"
    exit 1
fi

# Validate TC_MIRROR URL to prevent command injection
if echo "$TC_MIRROR" | grep -qE '[;&|$`<>(){}[\]!\\"]'; then
    echo "ERROR: TC_MIRROR contains invalid characters: $TC_MIRROR"
    echo "Check build/build.conf and ensure TC_MIRROR is a valid URL"
    exit 1
fi

TC_URL="$TC_MIRROR/$TC_VERSION/$TC_ARCH/release/$TC_ISO"

if [ -f "$TC_ISO" ]; then
    echo "  ✓ $TC_ISO already exists, skipping download"
else
    echo "  Downloading from $TC_URL"
    if ! wget -c "$TC_URL" 2>&1; then
        echo ""
        echo "ERROR: Failed to download Tiny Core Linux"
        echo ""
        echo "Possible solutions:"
        echo "  1. Check internet connection"
        echo "  2. Verify tinycorelinux.net is accessible"
        echo "  3. Try alternative mirror (edit build/build.conf: TC_MIRROR=...)"
        echo ""
        echo "For offline builds:"
        echo "  1. Download manually: $TC_URL"
        echo "  2. Place in: $DOWNLOAD_DIR/"
        echo "  3. Re-run this script"
        echo ""
        echo "See docs/BUILD.md section 'Offline Builds' for details"
        exit 1
    fi
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

# Validate extraction paths to prevent path traversal attacks
if ! validate_safe_path "$EXTRACT_DIR"; then
    echo "ERROR: Invalid extraction directory path: $EXTRACT_DIR"
    exit 1
fi

if ! validate_safe_path "$CONTENTS_DIR"; then
    echo "ERROR: Invalid contents directory path: $CONTENTS_DIR"
    exit 1
fi

# Ensure paths are within BUILD_DIR (prevent directory traversal)
case "$EXTRACT_DIR" in
    "$BUILD_DIR"*)
        # Path is within BUILD_DIR, safe to continue
        ;;
    *)
        echo "ERROR: Extraction directory must be within build directory"
        echo "  Build dir: $BUILD_DIR"
        echo "  Extract dir: $EXTRACT_DIR"
        exit 1
        ;;
esac

case "$CONTENTS_DIR" in
    "$BUILD_DIR"*)
        # Path is within BUILD_DIR, safe to continue
        ;;
    *)
        echo "ERROR: Contents directory must be within build directory"
        echo "  Build dir: $BUILD_DIR"
        echo "  Contents dir: $CONTENTS_DIR"
        exit 1
        ;;
esac

mkdir -p "$EXTRACT_DIR"
if [ -d "$CONTENTS_DIR" ]; then
    echo "  Cleaning old extraction..."
    rm -rf "$CONTENTS_DIR"
fi
mkdir -p "$CONTENTS_DIR"

# Mount and copy
echo "  Mounting ISO..."

# Validate ISO file exists and is a regular file
if [ ! -f "$TC_ISO" ]; then
    echo "ERROR: ISO file not found: $TC_ISO"
    exit 1
fi

# Get absolute path and validate it
TC_ISO_ABS="$(cd "$(dirname "$TC_ISO")" && pwd)/$(basename "$TC_ISO")"
if ! validate_safe_path "$TC_ISO_ABS"; then
    echo "ERROR: Invalid absolute ISO path: $TC_ISO_ABS"
    exit 1
fi

# Ensure ISO is within DOWNLOAD_DIR (prevent using arbitrary files)
case "$TC_ISO_ABS" in
    "$DOWNLOAD_DIR"*)
        # Path is within DOWNLOAD_DIR, safe to continue
        ;;
    *)
        echo "ERROR: ISO file must be within download directory"
        echo "  Download dir: $DOWNLOAD_DIR"
        echo "  ISO path: $TC_ISO_ABS"
        exit 1
        ;;
esac

sudo mount -o loop,ro "$TC_ISO_ABS" "$EXTRACT_DIR" || {
    echo "ERROR: Failed to mount ISO"
    exit 1
}

echo "  Copying contents..."
# Use explicit source path to prevent globbing attacks
if [ -d "$EXTRACT_DIR" ]; then
    cp -r "$EXTRACT_DIR/." "$CONTENTS_DIR/" || {
        echo "ERROR: Failed to copy ISO contents"
        sudo umount "$EXTRACT_DIR" 2>/dev/null || true
        exit 1
    }
else
    echo "ERROR: Extract directory not accessible after mount"
    sudo umount "$EXTRACT_DIR" 2>/dev/null || true
    exit 1
fi

echo "  Unmounting ISO..."
sudo umount "$EXTRACT_DIR"

# Extract initrd (core.gz)
echo ""
echo "Extracting initrd (core.gz)..."
INITRD_DIR="$WORKSPACE_DIR/initrd"

# Validate initrd directory path
if ! validate_safe_path "$INITRD_DIR"; then
    echo "ERROR: Invalid initrd directory path: $INITRD_DIR"
    exit 1
fi

# Ensure INITRD_DIR is within BUILD_DIR
case "$INITRD_DIR" in
    "$BUILD_DIR"*)
        # Path is within BUILD_DIR, safe to continue
        ;;
    *)
        echo "ERROR: Initrd directory must be within build directory"
        echo "  Build dir: $BUILD_DIR"
        echo "  Initrd dir: $INITRD_DIR"
        exit 1
        ;;
esac

if [ -d "$INITRD_DIR" ]; then
    rm -rf "$INITRD_DIR"
fi
mkdir -p "$INITRD_DIR"

# Validate core.gz path
CORE_GZ_PATH="$CONTENTS_DIR/boot/core.gz"
if ! validate_safe_path "$CORE_GZ_PATH"; then
    echo "ERROR: Invalid core.gz path: $CORE_GZ_PATH"
    exit 1
fi

if [ ! -f "$CORE_GZ_PATH" ]; then
    echo "ERROR: core.gz not found at: $CORE_GZ_PATH"
    exit 1
fi

cd "$INITRD_DIR"
zcat "$CORE_GZ_PATH" | sudo cpio -i -H newc -d

echo ""
echo "Checking for KVM kernel modules..."
if [ -d "$INITRD_DIR/lib/modules" ]; then
    KVM_MODULES=$(sudo find "$INITRD_DIR/lib/modules" -name "*kvm*.ko*" 2>/dev/null || true)
    if [ -n "$KVM_MODULES" ]; then
        echo "  Found KVM modules:"
        echo "$KVM_MODULES" | while read -r mod; do
            echo "    - $(basename "$mod")"
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
mkdir -p "$TCZ_DIR"

# List of packages we want (we'll download them later if available)
cat >"$TCZ_DIR/package-list.txt" <<'EOF'
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
date >"$WORKSPACE_DIR/.prepared"
echo "$TC_VERSION" >"$WORKSPACE_DIR/.tc-version"

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
