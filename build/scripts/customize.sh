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

# Backup original initrd
if [ ! -f "$WORKSPACE_DIR/core.gz.original" ]; then
    echo "Backing up original core.gz..."
    cp "$WORKSPACE_DIR/iso-contents/boot/core.gz" "$WORKSPACE_DIR/core.gz.original"
fi

echo "Customizing initrd..."
cd "$INITRD_DIR"

# Add bootlocal.sh
echo "  Adding custom bootlocal.sh..."
sudo mkdir -p opt
sudo cp "$CONFIG_DIR/bootlocal.sh" opt/bootlocal.sh
sudo chmod +x opt/bootlocal.sh

# Add sysctl.conf
echo "  Adding sysctl.conf..."
sudo mkdir -p etc
sudo cp "$CONFIG_DIR/sysctl.conf" etc/sysctl.conf

# Create version file
echo "  Adding version information..."
sudo mkdir -p etc/virtos
cat > /tmp/version.txt << EOF
FlossWare VirtOS
Version: 0.1-alpha
Build Date: $(date)
Based on: Tiny Core Linux $(cat "$WORKSPACE_DIR/.tc-version")
EOF
sudo mv /tmp/version.txt etc/virtos/version.txt

# Add motd
echo "  Adding message of the day..."
cat > /tmp/motd << 'EOF'

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
sudo mv /tmp/motd etc/motd

# Create documentation
echo "  Adding documentation..."
sudo mkdir -p usr/local/share/doc/virtos
cat > /tmp/README << 'EOF'
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
sudo mv /tmp/README usr/local/share/doc/virtos/README

# Create helper scripts
echo "  Adding helper scripts..."
sudo mkdir -p usr/local/bin

# KVM check script
cat > /tmp/check-kvm << 'EOF'
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
sudo mv /tmp/check-kvm usr/local/bin/check-kvm
sudo chmod +x usr/local/bin/check-kvm

# VM creation helper
cat > /tmp/create-vm << 'EOF'
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
sudo mv /tmp/create-vm usr/local/bin/create-vm
sudo chmod +x usr/local/bin/create-vm

# Repack initrd
echo ""
echo "Repacking initrd..."
cd "$INITRD_DIR"
sudo find . | sudo cpio -o -H newc | gzip -9 > "$WORKSPACE_DIR/core.gz.custom"

# Replace in ISO contents
echo "Updating ISO contents..."
sudo cp "$WORKSPACE_DIR/core.gz.custom" "$WORKSPACE_DIR/iso-contents/boot/core.gz"

# Create marker
date > "$WORKSPACE_DIR/.customized"

echo ""
echo "=== Customization Complete ==="
echo ""
echo "Added:"
echo "  - Custom bootlocal.sh (KVM modules, networking)"
echo "  - Kernel parameters (sysctl.conf)"
echo "  - Helper scripts (check-kvm, create-vm)"
echo "  - Documentation"
echo "  - Custom MOTD"
echo ""
echo "Next step:"
echo "  Run ./scripts/iso.sh to build bootable ISO"
echo ""
