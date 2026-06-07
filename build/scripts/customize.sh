#!/bin/bash
# FlossWare VirtOS - Customization Script
# Adds VirtOS configurations to Tiny Core base

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$BUILD_DIR")"

WORKSPACE_DIR="$BUILD_DIR/workspace"
INITRD_DIR="$WORKSPACE_DIR/initrd"
CONFIG_DIR="$PROJECT_ROOT/config"

# Preserve any PROFILE exported by parent (build-all.sh --profile)
_OVERRIDE_PROFILE="${PROFILE:-}"

# Source build configuration for profile settings
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

# Create secure temporary directory (cleaned up on exit)
BUILD_TMPDIR=$(mktemp -d) || { echo "ERROR: Failed to create temporary directory" >&2; exit 1; }
trap 'rm -rf "$BUILD_TMPDIR"' EXIT

echo "=== FlossWare VirtOS - Customization ==="
echo ""

# Check preparation
if [ ! -f "$WORKSPACE_DIR/.prepared" ]; then
    echo "ERROR: Build environment not prepared!"
    echo "Run ./scripts/prepare.sh first"
    exit 1
fi

if [ ! -d "$INITRD_DIR" ]; then
    echo "ERROR: Initrd not extracted!"
    exit 1
fi

# Detect initrd filename (core.gz for older versions, corepure64.gz for 15.x+)
if [ -f "$WORKSPACE_DIR/iso-contents/boot/corepure64.gz" ]; then
    INITRD_NAME="corepure64.gz"
elif [ -f "$WORKSPACE_DIR/iso-contents/boot/core.gz" ]; then
    INITRD_NAME="core.gz"
else
    echo "ERROR: No initrd found in $WORKSPACE_DIR/iso-contents/boot/"
    exit 1
fi

# Backup original initrd
if [ ! -f "$WORKSPACE_DIR/${INITRD_NAME}.original" ]; then
    echo "Backing up original $INITRD_NAME..."
    cp "$WORKSPACE_DIR/iso-contents/boot/$INITRD_NAME" "$WORKSPACE_DIR/${INITRD_NAME}.original"
fi

echo "Customizing initrd..."
cd "$INITRD_DIR"

# Add bootsync.sh (runs early, before tc-config)
echo "  Adding custom bootsync.sh..."
sudo mkdir -p opt
sudo cp "$CONFIG_DIR/bootsync.sh" opt/bootsync.sh
sudo chmod +x opt/bootsync.sh

# Add bootlocal.sh (runs after tc-config)
echo "  Adding custom bootlocal.sh..."
sudo cp "$CONFIG_DIR/bootlocal.sh" opt/bootlocal.sh
sudo chmod +x opt/bootlocal.sh

# CRITICAL FIX: Ensure correct ownership of system files
# sudoers must be owned by root:root or su/sudo commands fail
echo "  Fixing system file ownership..."
sudo chown -R root:root etc/ usr/ opt/ bin/ sbin/ lib/ 2>/dev/null || true

# Add sysctl.conf
echo "  Adding sysctl.conf..."
sudo mkdir -p etc
sudo cp "$CONFIG_DIR/sysctl.conf" etc/sysctl.conf

# Create version file
echo "  Adding version information..."
sudo mkdir -p etc/virtos

# Read version from VERSION file
if [ -f "$PROJECT_ROOT/VERSION" ]; then
    FW_VERSION="$(cat "$PROJECT_ROOT/VERSION")"
    echo "  Using version from VERSION file: $FW_VERSION"
else
    FW_VERSION="0.1"
    echo "  WARNING: VERSION file not found, using default: $FW_VERSION"
fi

cat >"$BUILD_TMPDIR/version.txt" <<EOF
FlossWare VirtOS
Version: $FW_VERSION
Build Date: $(date)
Based on: Tiny Core Linux $(cat "$WORKSPACE_DIR/.tc-version")
EOF
sudo mv "$BUILD_TMPDIR/version.txt" etc/virtos/version.txt

# Add motd
echo "  Adding message of the day..."
cat >"$BUILD_TMPDIR/motd" <<'EOF'

 ██╗   ██╗██╗██████╗ ████████╗ ██████╗ ███████╗
 ██║   ██║██║██╔══██╗╚══██╔══╝██╔═══██╗██╔════╝
 ██║   ██║██║██████╔╝   ██║   ██║   ██║███████╗
 ╚██╗ ██╔╝██║██╔══██╗   ██║   ██║   ██║╚════██║
  ╚████╔╝ ██║██║  ██║   ██║   ╚██████╔╝███████║
   ╚═══╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝

 FlossWare VirtOS - Minimal. Powerful. Flexible.

 Virtualization: KVM/QEMU, LXC, Docker/Podman/containerd
 Documentation: /usr/local/share/doc/virtos

EOF
sudo mv "$BUILD_TMPDIR/motd" etc/motd

# Create documentation
echo "  Adding documentation..."
sudo mkdir -p usr/local/share/doc/virtos
cat >"$BUILD_TMPDIR/README" <<'EOF'
FlossWare VirtOS
================

Quick Start
-----------

1. Check KVM is available:
   ls -l /dev/kvm

2. Create a test VM:
   qemu-system-x86_64 -enable-kvm -m 512 -nographic

3. Create LXC container:
   lxc-create -n test -t download

4. Run Docker container:
   docker run hello-world

Network Setup
-------------

Bridge (br0) is created automatically for VM networking.

To connect VMs to the bridge:
  qemu-system-x86_64 -enable-kvm -netdev bridge,id=net0,br=br0 -device virtio-net,netdev=net0

Management
----------

libvirt: virsh <command>
LXC:     lxc-* commands
Docker:  docker <command>

See /opt/bootlocal.sh for initialization details.

More info: https://github.com/FlossWare/VirtOS
EOF
sudo mv "$BUILD_TMPDIR/README" usr/local/share/doc/virtos/README

# Add VirtOS management scripts
echo "  Adding VirtOS management scripts..."
sudo mkdir -p usr/local/bin

if [ -d "$CONFIG_DIR/custom-scripts" ]; then
    echo "  Copying virtos-* management tools..."
    SCRIPT_COUNT=0
    for script in "$CONFIG_DIR"/custom-scripts/virtos-*; do
        if [ -f "$script" ] && [ -x "$script" ]; then
            sudo cp "$script" usr/local/bin/
            SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
        fi
    done
    echo "  Added $SCRIPT_COUNT management scripts"

    # Also copy add-user.sh if present
    if [ -f "$CONFIG_DIR/custom-scripts/add-user.sh" ]; then
        sudo cp "$CONFIG_DIR/custom-scripts/add-user.sh" usr/local/bin/
        echo "  Added add-user.sh utility"
    fi

    # Copy common library files (virtos-common.sh, virtos-audit.sh, etc.)
    # Scripts source from /usr/local/lib/virtos-common.sh (no subdirectory)
    if [ -d "$CONFIG_DIR/custom-scripts/lib" ]; then
        echo "  Copying common libraries..."
        sudo mkdir -p usr/local/lib
        LIB_COUNT=0
        for libfile in "$CONFIG_DIR"/custom-scripts/lib/*; do
            if [ -f "$libfile" ]; then
                sudo cp "$libfile" usr/local/lib/
                LIB_COUNT=$((LIB_COUNT + 1))
            fi
        done
        echo "  Added $LIB_COUNT library files to /usr/local/lib/"
    else
        echo "  WARNING: lib directory not found at $CONFIG_DIR/custom-scripts/lib"
    fi
else
    echo "  WARNING: custom-scripts directory not found at $CONFIG_DIR/custom-scripts"
fi

# Copy logrotate configuration
if [ -d "$CONFIG_DIR/logrotate.d" ]; then
    echo "  Adding logrotate configuration..."
    sudo mkdir -p etc/logrotate.d
    for rotfile in "$CONFIG_DIR"/logrotate.d/*; do
        if [ -f "$rotfile" ]; then
            sudo cp "$rotfile" etc/logrotate.d/
        fi
    done
    echo "  Added logrotate configs from config/logrotate.d/"
fi

# Create helper scripts
echo "  Adding helper scripts..."

# KVM check script
cat >"$BUILD_TMPDIR/check-kvm" <<'EOF'
#!/bin/sh
echo "=== KVM Status ==="
echo ""
echo -n "CPU Virtualization: "
if grep -q "vmx\|svm" /proc/cpuinfo; then
    echo "Supported"
    grep -q "vmx" /proc/cpuinfo && echo "  Type: Intel VT-x"
    grep -q "svm" /proc/cpuinfo && echo "  Type: AMD-V"
else
    echo "NOT supported - enable in BIOS/UEFI"
fi

echo ""
echo -n "KVM Module: "
if lsmod | grep -q "^kvm"; then
    echo "Loaded"
    lsmod | grep kvm
else
    echo "NOT loaded"
fi

echo ""
echo -n "/dev/kvm: "
if [ -c /dev/kvm ]; then
    echo "Available"
    ls -l /dev/kvm
else
    echo "NOT available"
fi

echo ""
echo -n "QEMU KVM: "
if qemu-system-x86_64 --version >/dev/null 2>&1; then
    qemu-system-x86_64 --version | head -1
else
    echo "NOT installed"
fi
EOF
sudo mv "$BUILD_TMPDIR/check-kvm" usr/local/bin/check-kvm
sudo chmod +x usr/local/bin/check-kvm

# VM creation helper
cat >"$BUILD_TMPDIR/create-vm" <<'EOF'
#!/bin/sh
# Simple VM creation helper

if [ $# -lt 2 ]; then
    echo "Usage: create-vm <name> <size-in-GB> [iso-path]"
    echo ""
    echo "Examples:"
    echo "  create-vm ubuntu 20 /path/to/ubuntu.iso"
    echo "  create-vm test 10"
    exit 1
fi

NAME=$1
SIZE=$2
ISO=$3
VMDIR="/mnt/sda1/vms"  # Adjust to your persistent storage

# Validate ISO path if provided
if [ -n "$ISO" ]; then
    if [ ! -f "$ISO" ]; then
        echo "ERROR: ISO file not found: $ISO" >&2
        exit 1
    fi
    if [ ! -r "$ISO" ]; then
        echo "ERROR: ISO file not readable: $ISO" >&2
        exit 1
    fi
    # Basic check that it's actually an ISO file
    case "$ISO" in
        *.iso|*.ISO) ;;
        *)
            echo "WARNING: File does not have .iso extension: $ISO" >&2
            echo "Continuing anyway, but this may not be an ISO file" >&2
            ;;
    esac
fi

mkdir -p "$VMDIR/$NAME"
cd "$VMDIR/$NAME"

# Create disk
echo "Creating ${SIZE}GB disk: $NAME.qcow2"
qemu-img create -f qcow2 "$NAME.qcow2" "${SIZE}G"

# Create start script
cat > start.sh << VMEOF
#!/bin/sh
qemu-system-x86_64 \\
    -enable-kvm \\
    -m 2048 \\
    -smp 2 \\
    -drive file=$NAME.qcow2,format=qcow2 \\
    -netdev bridge,id=net0,br=br0 -device virtio-net,netdev=net0 \\
    -vnc :0 \\
    "\$@"
VMEOF
chmod +x start.sh

if [ -n "$ISO" ]; then
    echo "First boot with ISO: $ISO"
    echo "Run: cd $VMDIR/$NAME && ./start.sh -cdrom $ISO -boot d"
else
    echo "VM created: $VMDIR/$NAME"
    echo "Run: cd $VMDIR/$NAME && ./start.sh"
fi
EOF
sudo mv "$BUILD_TMPDIR/create-vm" usr/local/bin/create-vm
sudo chmod +x usr/local/bin/create-vm

# CRITICAL: Bundle TCZ packages BEFORE repacking initrd
echo ""
echo "Bundling TCZ packages..."
if [ -d "$BUILD_DIR/workspace/tcz" ] && [ "$(ls -1 $BUILD_DIR/workspace/tcz/*.tcz 2>/dev/null | wc -l)" -gt 0 ]; then
    cd "$INITRD_DIR"

    # Put TCZ files in /tmp/tce/optional/ (where tc-config expects them)
    sudo mkdir -p tmp/tce/optional
    sudo cp "$BUILD_DIR"/workspace/tcz/*.tcz tmp/tce/optional/
    TCZ_COUNT=$(ls -1 "$BUILD_DIR"/workspace/tcz/*.tcz 2>/dev/null | wc -l)
    echo "  Added $TCZ_COUNT TCZ packages to tmp/tce/optional/"

    # Also keep a copy in /optional/ for reference
    sudo mkdir -p optional
    sudo cp "$BUILD_DIR"/workspace/tcz/*.tcz optional/
    echo "  Backup copy in optional/"

    # Create onboot.lst to auto-load packages (only include what was downloaded)
    echo "  Generating onboot.lst from downloaded packages..."

    # Detect actual kernel version from Tiny Core
    TC_KERNEL_VERSION=""
    if [ -f "$WORKSPACE_DIR/.tc-version" ]; then
        TC_VERSION=$(cat "$WORKSPACE_DIR/.tc-version")
        # Try to detect kernel version from vmlinuz filename
        VMLINUZ=$(ls "$WORKSPACE_DIR/iso-contents/boot/vmlinuz"* 2>/dev/null | head -1)
        if [ -n "$VMLINUZ" ]; then
            # Extract version from filename (e.g., vmlinuz64 or vmlinuz-6.6.16-tinycore64)
            TC_KERNEL_VERSION=$(basename "$VMLINUZ" | sed 's/vmlinuz-//;s/vmlinuz64//')
        fi
    fi

    # Candidate packages for onboot.lst (in priority order)
    DESIRED_PACKAGES=(
        "bash.tcz"
        "openssh.tcz"
        "vim.tcz"
        "dialog.tcz"
        "bridge-utils.tcz"
        "iptables.tcz"
        "iproute2.tcz"
        "htop.tcz"
    )

    # Add kernel module if detected
    if [ -n "$TC_KERNEL_VERSION" ] && [ -f "$TCZ_DIR/kvm-${TC_KERNEL_VERSION}.tcz" ]; then
        DESIRED_PACKAGES=("kvm-${TC_KERNEL_VERSION}.tcz" "${DESIRED_PACKAGES[@]}")
    elif [ -f "$TCZ_DIR/kvm.tcz" ]; then
        DESIRED_PACKAGES=("kvm.tcz" "${DESIRED_PACKAGES[@]}")
    fi

    # Generate onboot.lst with ONLY packages that exist
    cat > "$BUILD_TMPDIR/onboot.lst" <<EOF
# Auto-load essential packages (auto-generated from downloaded packages)
# Dependencies are resolved recursively by download-tcz.sh
EOF

    MISSING_PACKAGES=()
    ADDED_PACKAGES=()

    for pkg in "${DESIRED_PACKAGES[@]}"; do
        if [ -f "$TCZ_DIR/$pkg" ]; then
            echo "$pkg" >> "$BUILD_TMPDIR/onboot.lst"
            ADDED_PACKAGES+=("$pkg")
            echo "    ✅ $pkg"
        else
            MISSING_PACKAGES+=("$pkg")
            echo "    ⚠️  $pkg (not found, skipping)"
        fi
    done

    # Optionally add QEMU/libvirt if available
    for pkg in "qemu.tcz" "libvirt.tcz"; do
        if [ -f "$TCZ_DIR/$pkg" ]; then
            echo "$pkg" >> "$BUILD_TMPDIR/onboot.lst"
            ADDED_PACKAGES+=("$pkg")
            echo "    ✅ $pkg (optional)"
        fi
    done

    sudo mv "$BUILD_TMPDIR/onboot.lst" tmp/tce/onboot.lst
    echo "  Created onboot.lst with ${#ADDED_PACKAGES[@]} packages"

    # Warn about critical missing packages
    CRITICAL_MISSING=()
    for pkg in "bash.tcz" "openssh.tcz"; do
        if [[ " ${MISSING_PACKAGES[@]} " =~ " ${pkg} " ]]; then
            CRITICAL_MISSING+=("$pkg")
        fi
    done

    if [ ${#CRITICAL_MISSING[@]} -gt 0 ]; then
        echo ""
        echo "  ⚠️  WARNING: Critical packages missing:"
        printf '    - %s\n' "${CRITICAL_MISSING[@]}"
        echo "  Run 'bash scripts/download-tcz.sh' to download packages"
        echo ""
    fi
else
    echo "  No TCZ packages found, skipping"
fi

# Configure SSH for automatic login
echo ""
echo "Configuring SSH access..."
cd "$INITRD_DIR"

# Create tc user home directory with SSH config
sudo mkdir -p home/tc/.ssh
sudo chmod 700 home/tc/.ssh

# Add authorized_keys (use existing key or generate new one)
SSH_KEY_FILE="${SSH_KEY_FILE:-$HOME/.ssh/id_rsa_virtos.pub}"
if [ -f "$SSH_KEY_FILE" ]; then
    sudo cp "$SSH_KEY_FILE" home/tc/.ssh/authorized_keys
    sudo chmod 600 home/tc/.ssh/authorized_keys
    echo "  Added SSH public key from $SSH_KEY_FILE"
else
    # Generate a new key pair if none exists
    echo "  WARNING: No SSH key found at $SSH_KEY_FILE"
    echo "  Generating new SSH key pair..."
    ssh-keygen -t rsa -b 2048 -f "$HOME/.ssh/id_rsa_virtos" -N "" -C "virtos-default-key"
    sudo cp "$HOME/.ssh/id_rsa_virtos.pub" home/tc/.ssh/authorized_keys
    sudo chmod 600 home/tc/.ssh/authorized_keys
    echo "  Generated and added new SSH key"
    echo "  Private key: $HOME/.ssh/id_rsa_virtos"
fi

# Set ownership to tc user (UID 1001 in Tiny Core)
sudo chown -R 1001:50 home/tc

# Install pre-configured sshd_config
sudo mkdir -p usr/local/etc/ssh
if [ -f "$CONFIG_DIR/sshd_config" ]; then
    sudo cp "$CONFIG_DIR/sshd_config" usr/local/etc/ssh/sshd_config
    sudo chmod 600 usr/local/etc/ssh/sshd_config
    echo "  Installed sshd_config"
fi

# Pre-generate SSH host keys
echo "  Pre-generating SSH host keys..."
sudo mkdir -p usr/local/etc/ssh
sudo ssh-keygen -t rsa -f "$BUILD_TMPDIR/ssh_host_rsa_key" -N "" >/dev/null 2>&1
sudo ssh-keygen -t ecdsa -f "$BUILD_TMPDIR/ssh_host_ecdsa_key" -N "" >/dev/null 2>&1
sudo ssh-keygen -t ed25519 -f "$BUILD_TMPDIR/ssh_host_ed25519_key" -N "" >/dev/null 2>&1
sudo mv "$BUILD_TMPDIR"/ssh_host_* usr/local/etc/ssh/
sudo chmod 600 usr/local/etc/ssh/ssh_host_*_key
sudo chmod 644 usr/local/etc/ssh/ssh_host_*_key.pub
echo "  Generated host keys"

echo "  SSH configured for passwordless access as 'tc' user"

# Repack initrd (NOW includes TCZ packages)
echo ""
echo "Repacking initrd with TCZ packages..."
cd "$INITRD_DIR"
sudo find . | sudo cpio -o -H newc | gzip -"${COMPRESSION_LEVEL:-9}" >"$WORKSPACE_DIR/${INITRD_NAME}.custom"

# Replace in ISO contents
echo "Updating ISO contents..."
sudo cp "$WORKSPACE_DIR/${INITRD_NAME}.custom" "$WORKSPACE_DIR/iso-contents/boot/$INITRD_NAME"

# Note: Serial console already configured in isolinux.cfg
# onboot.lst is in /tmp/tce/ and will be auto-loaded by tc-config

# Create marker
date >"$WORKSPACE_DIR/.customized"

echo ""
echo "=== Customization Complete ==="
echo ""
echo "Added:"
echo "  - Custom bootlocal.sh (KVM modules, networking)"
echo "  - Kernel parameters (sysctl.conf)"
echo "  - Helper scripts (check-kvm, create-vm)"
echo "  - VirtOS management scripts and shared libraries"
echo "  - Documentation"
echo "  - Custom MOTD"
echo "  - $TCZ_COUNT TCZ packages bundled in initrd"
echo ""
echo "Next step:"
echo "  Run ./scripts/iso.sh to build bootable ISO"
echo ""
