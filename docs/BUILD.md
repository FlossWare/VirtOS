# Building VirtOS from Source

Complete guide for building VirtOS ISO images from source.

## Quick Start

```bash
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS
make build    # Will prompt for confirmation (downloads ~500MB)
```

## Table of Contents

- [Prerequisites](#prerequisites)
- [Build Process](#build-process)
- [Build Profiles](#build-profiles)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Advanced Options](#advanced-options)

## Prerequisites

### System Requirements

- **OS**: Linux (tested on Fedora 44, Ubuntu 24.04, Debian 12, Arch Linux)
- **Disk Space**: 20GB free (Tiny Core Linux downloads + build artifacts)
- **RAM**: 4GB minimum, 8GB recommended
- **Network**: Internet connection required for first build
- **Architecture**: x86_64

### Required Packages

Install build dependencies for your distribution:

**Fedora / RHEL**:
```bash
sudo dnf install -y genisoimage syslinux wget bash cpio gzip squashfs-tools
```

**Debian / Ubuntu**:
```bash
sudo apt install -y genisoimage syslinux-utils wget bash cpio gzip squashfs-tools
```

**Arch Linux**:
```bash
sudo pacman -S --needed cdrtools syslinux wget bash cpio gzip squashfs-tools
```

Or use the Makefile:
```bash
make install-deps-fedora    # For Fedora
make install-deps-ubuntu    # For Ubuntu/Debian
make install-deps-arch      # For Arch Linux
```

### Optional Packages

Recommended for testing and development:

- **qemu-kvm**: For testing ISOs in virtual machines
- **shellcheck**: For shell script linting
- **bats**: For running unit tests
- **git**: For version control and metadata

```bash
# Fedora
sudo dnf install qemu-kvm shellcheck bats

# Ubuntu/Debian
sudo apt install qemu-kvm shellcheck bats

# Arch
sudo pacman -S qemu bats shellcheck
```

## Build Process

### Step 1: Clone Repository

```bash
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS
```

### Step 2: Choose Build Profile

VirtOS supports multiple build profiles. Edit `build/build.conf` to select one:

```bash
# Set your profile (default: standard)
PROFILE="standard"
```

Available profiles:
- **minimal** - Minimal system (~100MB ISO)
- **standard** - Standard virtualization tools (~200MB ISO)
- **full** - All VirtOS features (~400MB ISO)
- **containers** - Container-focused build
- **developer** - Development tools included
- **kubernetes** - K8s management tools
- **storage** - Storage-optimized

See [Build Profiles](#build-profiles) for details.

### Step 3: Build Packages (Optional)

Build VirtOS packages first (recommended):

```bash
make packages
```

This creates:
- `packages/output/virtos-tools.tcz` - Core management scripts
- `packages/output/virtos-jplatform.tcz` - platform-java integration

### Step 4: Build ISO

Using Makefile (recommended):
```bash
make build
```

Or manually:
```bash
cd build/scripts
./build-all.sh
```

**Build Process**:
1. **Download Tiny Core Linux** (~500MB, cached for future builds)
   - `CorePure64-15.0.iso` or version from build.conf
   - Stored in `build/downloads/`
2. **Extract base system** to `build/workspace/`
3. **Customize system**:
   - Install VirtOS packages
   - Configure bootloader
   - Add custom scripts
4. **Build ISO** → `build/output/VirtOS-{PROFILE}-{VERSION}.iso`

**Build Time**: 10-20 minutes (first build), 2-5 minutes (subsequent)

### Step 5: Verify Build

Check build output:
```bash
ls -lh build/output/
# Should show:
# VirtOS-standard-0.13.iso
# VirtOS-standard-0.13.iso.md5
```

Verify checksum:
```bash
cd build/output
md5sum -c VirtOS-*.iso.md5
```

## Build Profiles

### minimal
- **Size**: ~100MB
- **Components**: Core Linux, busybox, basic networking
- **Use Case**: Embedded systems, minimal resource environments
- **Included**: virtos-setup, basic VM tools

### standard (Default)
- **Size**: ~200MB
- **Components**: KVM/QEMU, libvirt, networking, storage
- **Use Case**: General virtualization host
- **Included**: All virtos-* scripts, virtos-tui, clustering

### full
- **Size**: ~400MB
- **Components**: Everything from standard + containers, monitoring, advanced tools
- **Use Case**: Production environments, full-featured deployments
- **Included**: Docker, LXC, advanced networking, platform-java

### containers
- **Size**: ~250MB
- **Components**: Docker, LXC, container networking
- **Use Case**: Container-focused hosts
- **Included**: Container management, orchestration

### developer
- **Size**: ~300MB
- **Components**: Development tools, compilers, debuggers
- **Use Case**: VirtOS development
- **Included**: gcc, make, git, vim, debugging tools

### kubernetes
- **Size**: ~350MB
- **Components**: K8s client tools, kubectl, helm
- **Use Case**: Kubernetes management nodes
- **Included**: kubectl, kubeadm, helm, container runtime

### storage
- **Size**: ~280MB
- **Components**: Storage tools, NFS, Ceph, iSCSI
- **Use Case**: Storage servers
- **Included**: LVM, RAID, distributed storage tools

## Testing

### Test in QEMU

Test the ISO before deploying:

```bash
# Basic boot test
qemu-system-x86_64 -enable-kvm -m 2048 \
  -cdrom build/output/VirtOS-standard-0.13.iso

# With network
qemu-system-x86_64 -enable-kvm -m 2048 \
  -cdrom build/output/VirtOS-*.iso \
  -netdev user,id=net0 \
  -device virtio-net-pci,netdev=net0

# With persistent disk
qemu-img create -f qcow2 test-disk.qcow2 20G
qemu-system-x86_64 -enable-kvm -m 2048 \
  -cdrom build/output/VirtOS-*.iso \
  -drive file=test-disk.qcow2,if=virtio
```

### Write to USB Drive

**⚠️ WARNING**: Double-check device name to avoid data loss!

```bash
# Find USB device
lsblk

# Write ISO (replace /dev/sdX with your USB device)
sudo dd if=build/output/VirtOS-*.iso \
  of=/dev/sdX bs=4M status=progress oflag=sync

# Sync to ensure writes complete
sync
```

### Burn to CD/DVD

```bash
# Using wodim
wodim -v dev=/dev/sr0 build/output/VirtOS-*.iso

# Using growisofs (for DVD)
growisofs -dvd-compat -Z /dev/sr0=build/output/VirtOS-*.iso
```

### Run Integration Tests

```bash
# Run full test suite
make test

# Run specific tests
cd tests
./test-iso-boot.sh
./test-vm-creation.sh
```

See [RUNTIME_TESTING_PLAN.md](../RUNTIME_TESTING_PLAN.md) for comprehensive testing.

## Troubleshooting

### "genisoimage: command not found"

**Solution**: Install build dependencies
```bash
# See Prerequisites section for your distribution
make install-deps-fedora  # or ubuntu/arch
```

### "Failed to download Tiny Core Linux"

**Causes**:
- No internet connection
- tinycorelinux.net is down
- Firewall blocking downloads

**Solutions**:
```bash
# 1. Check network
ping tinycorelinux.net

# 2. Manual download
cd build/downloads
wget http://tinycorelinux.net/15.x/x86_64/release/CorePure64-15.0.iso

# 3. Use mirror (if main site is down)
# Edit build/build.conf and change TC_MIRROR_URL
```

See [BUILD_DEPENDENCIES.md](../BUILD_DEPENDENCIES.md) for offline builds.

### "Permission denied" during build

**Solution**: Don't run build as root
```bash
# Build as regular user
./build-all.sh

# Only specific operations need sudo (will prompt)
```

### ISO boots but no VMs can be created

**Causes**:
- CPU virtualization (VT-x/AMD-V) disabled
- KVM module not loaded
- Permission issues

**Solutions**:
```bash
# Check CPU virtualization
lscpu | grep Virtualization
# Should show: VT-x or AMD-V

# Enable in BIOS if missing
# (Reboot → BIOS/UEFI → Enable VT-x or AMD-V)

# Check KVM module
lsmod | grep kvm
# Should show: kvm_intel or kvm_amd

# Load KVM module
sudo modprobe kvm_intel  # or kvm_amd
```

### Build runs out of disk space

**Solution**: Clean old builds
```bash
make clean-all
# Removes: workspace, downloads, output
# Next build will re-download Tiny Core Linux
```

### Slow builds

**Causes**:
- Downloading Tiny Core Linux (first build only)
- Slow disk I/O
- Running on low-end hardware

**Solutions**:
```bash
# 1. Use faster disk (SSD)
# 2. Increase parallel jobs
export MAKE_JOBS=4

# 3. Cache Tiny Core download
# (automatic - downloads/ directory is reused)

# 4. Use minimal profile for faster builds
# Edit build/build.conf: PROFILE="minimal"
```

### "squashfs-tools not found"

Some distributions don't include squashfs-tools in base install:

```bash
# Fedora
sudo dnf install squashfs-tools

# Ubuntu/Debian
sudo apt install squashfs-tools

# Arch
sudo pacman -S squashfs-tools
```

## Advanced Options

### Custom Packages

Add your own packages to the ISO:

1. Create package TCZ file
2. Place in `build/custom-packages/`
3. Edit `build/scripts/customize.sh`
4. Add package installation commands

### Custom Branding

Modify boot splash and messages:

```bash
# Edit build/scripts/customize.sh
# Change lines 50-60 for version info

# Edit build/syslinux/*.cfg for bootloader messages
```

### Version Management

Version is auto-managed from `VERSION` file:

```bash
# Current version
cat VERSION

# Update version (example - actual version is auto-managed)
echo "0.87" > VERSION

# Build with new version
make build
```

Version bumping is automated in CD pipeline.

### Offline Builds

For air-gapped environments:

1. Download Tiny Core Linux on internet-connected system:
   ```bash
   wget http://tinycorelinux.net/15.x/x86_64/release/CorePure64-15.0.iso
   ```

2. Transfer to offline system → `build/downloads/`

3. Build normally:
   ```bash
   make build
   ```

See [BUILD_DEPENDENCIES.md](../BUILD_DEPENDENCIES.md) for complete offline build guide.

### Multi-Architecture Builds

Currently VirtOS supports x86_64 only. For other architectures:

- **ARM64**: Requires Tiny Core ARM64 base (not yet available)
- **i386**: Use CorePure32 base (modify build.conf)

## Build Scripts Reference

- `build/scripts/build-all.sh` - Main build orchestrator
- `build/scripts/download.sh` - Download Tiny Core Linux
- `build/scripts/extract.sh` - Extract base system
- `build/scripts/customize.sh` - Customize system
- `build/scripts/iso.sh` - Build final ISO
- `build/scripts/validate-build.sh` - Validation checks
- `build/scripts/quick-test.sh` - Quick smoke tests

## See Also

- [README.md](../README.md) - Project overview
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [RUNTIME_TESTING_PLAN.md](../RUNTIME_TESTING_PLAN.md) - Comprehensive testing guide
- [ISO_BUILD_STATUS.md](../ISO_BUILD_STATUS.md) - Build system status
- [BUILD_DEPENDENCIES.md](../BUILD_DEPENDENCIES.md) - Detailed dependency information
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - General troubleshooting

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for build system contribution guidelines.

## License

VirtOS is released under the GNU General Public License v3.0. See [LICENSE](../LICENSE) for details.
