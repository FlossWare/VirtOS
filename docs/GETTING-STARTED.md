# Getting Started

## Prerequisites

### Development Machine

- Linux system (for building)
- 4GB+ RAM
- 20GB+ free disk space
- Internet connection

### Target System (where FlossWare Virt will run)

- x86_64 CPU with VT-x (Intel) or AMD-V (AMD)
- 4GB+ RAM (8GB+ recommended)
- 20GB+ storage
- BIOS/UEFI with virtualization enabled

## Step 1: Check CPU Virtualization Support

On your target system:

```bash
# Check for virtualization extensions
grep -E 'vmx|svm' /proc/cpuinfo

# If output shows 'vmx' (Intel) or 'svm' (AMD), you're good
# If no output, enable virtualization in BIOS/UEFI
```

## Step 2: Set Up Build Environment

```bash
# Install dependencies (on Debian/Ubuntu build machine)
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    gcc \
    make \
    wget \
    squashfs-tools \
    genisoimage \
    git

# For Red Hat/Fedora
sudo dnf install -y \
    gcc \
    make \
    wget \
    squashfs-tools \
    genisoimage \
    git
```

## Step 3: Download Tiny Core Linux

```bash
# Create working directory
mkdir -p ~/virtos-build/build
cd ~/virtos-build/build

# Download Tiny Core (64-bit)
# Version 14.x (check https://tinycorelinux.net for latest)
wget https://tinycorelinux.net/14.x/x86_64/release/CorePure64-current.iso

# Extract the ISO
mkdir iso-extract
sudo mount -o loop CorePure64-current.iso iso-extract
mkdir iso-contents
cp -r iso-extract/* iso-contents/
sudo umount iso-extract
```

## Step 4: Verify KVM Kernel Modules

Tiny Core's default kernel usually includes KVM modules. Verify:

```bash
# Boot Tiny Core in a VM first to test
# Or extract and check kernel modules

mkdir kernel-check
cd kernel-check
zcat ../iso-contents/boot/core.gz | cpio -idv

# Look for KVM modules
find . -name "*kvm*"
# Should see: kvm.ko, kvm-intel.ko, kvm-amd.ko
```

## Step 5: Create Custom Boot Script

Create a boot script to load KVM modules automatically:

```bash
#!/bin/sh
# /opt/bootlocal.sh

# Load KVM modules
modprobe kvm
modprobe kvm-intel  # or kvm-amd for AMD CPUs

# Set up networking
/sbin/ifconfig eth0 up
/sbin/udhcpc -i eth0

# Create bridge for VMs
brctl addbr br0
brctl addif br0 eth0
ifconfig br0 up

# Load extensions (if using TCE)
tce-load -i qemu.tcz
tce-load -i bridge-utils.tcz
```

**Note**: VirtOS build scripts handle this automatically!

## Step 6: Build Custom ISO (Basic)

```bash
# Repack the ISO with custom bootlocal.sh
cd ~/virtos-build/build/iso-contents

# Add custom bootlocal.sh to initrd
mkdir -p custom/opt
cat > custom/opt/bootlocal.sh << 'EOF'
#!/bin/sh
modprobe kvm
modprobe kvm-intel
echo "KVM modules loaded"
EOF
chmod +x custom/opt/bootlocal.sh

# Repack core.gz
cd custom
find . | cpio -o -H newc | gzip > ../boot/core.gz
cd ..

# Create new ISO
genisoimage -l -J -R -V "VirtOS" \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -b boot/isolinux/isolinux.bin \
    -c boot/isolinux/boot.cat \
    -o ../VirtOS-v0.1.iso .
```

## Step 7: Test the ISO

```bash
# Test in QEMU/KVM
qemu-system-x86_64 \
    -enable-kvm \
    -m 2048 \
    -cdrom VirtOS-v0.1.iso \
    -boot d

# Inside the booted system, verify:
# 1. Check KVM is available
ls -l /dev/kvm  # Should exist

# 2. Test simple VM
qemu-system-x86_64 -enable-kvm -m 512 -nographic
# (Ctrl+A, X to exit)
```

## Step 8: Next Steps

Once you have the basic ISO working:

1. **Add package repository access**
   - Configure TCE for package downloads
   - Install QEMU, LXC, containers

2. **Configure networking**
   - Set up bridges
   - Configure NAT/routing

3. **Add persistence**
   - Frugal install
   - Separate partition for VM storage

4. **Build management tools**
   - Scripts for VM creation
   - Container management

See [ROADMAP.md](ROADMAP.md) for detailed development phases.

## Quick Test Commands

```bash
# Check CPU supports virtualization
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should be > 0

# Check KVM module loaded
lsmod | grep kvm

# Check /dev/kvm exists
ls -l /dev/kvm

# Test QEMU can use KVM
qemu-system-x86_64 --version
qemu-system-x86_64 -enable-kvm -m 512 -nographic -serial mon:stdio
```

## Troubleshooting

### No /dev/kvm

- Check BIOS virtualization is enabled
- Verify CPU supports VT-x/AMD-V
- Ensure kvm modules are loaded

### Module not found

- Kernel may not have KVM compiled
- Need to recompile kernel or use different Tiny Core version

### QEMU too slow

- Ensure `-enable-kvm` flag is used
- Check KVM acceleration is active

### Network issues

- Verify bridge created: `brctl show`
- Check IP routing: `ip route`
- Verify iptables rules allow forwarding

## Resources

- Tiny Core Wiki: <https://wiki.tinycorelinux.net>
- KVM Documentation: <https://www.linux-kvm.org>
- This project's docs: See `/docs` directory
