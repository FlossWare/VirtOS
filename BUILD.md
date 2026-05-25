# VirtOS Build Guide

Complete guide to building VirtOS from source.

## Build Status

### ✅ What Works (Tested & Functional)

**Package Building:**
- ✅ **virtos-tools.tcz** - All 52 management scripts packaged successfully (332KB)
- ✅ Package build system (TCZ creation with squashfs)
- ✅ Automated build-all.sh for batch packaging
- ✅ MD5/SHA256 checksum generation
- ✅ Package metadata and dependency tracking

**Build Infrastructure:**
- ✅ Build validation script (checks prerequisites)
- ✅ Quick test script (rapid validation)
- ✅ Syntax checking for all scripts
- ✅ Configuration system (build.conf with 7 profiles)
- ✅ Automated integration of virtos-* scripts

**Scripts & Configuration:**
- ✅ All 52 virtos-* management scripts (syntax validated)
- ✅ Custom bootlocal.sh for initialization
- ✅ Kernel parameters (sysctl.conf)
- ✅ Helper scripts (check-kvm, create-vm)

### 🟡 Partially Implemented (Framework Ready)

**ISO Building:**
- 🟡 **prepare.sh** - Downloads Tiny Core, extracts ISO (untested)
- 🟡 **customize.sh** - Adds VirtOS customizations (untested)
- 🟡 **iso.sh** - Creates bootable ISO (untested)
- ⚠️ **Missing**: genisoimage (can use mkisofs as alternative)

**Reason**: Need to download ~500MB Tiny Core Linux to test. Framework is complete.

### ❌ Not Yet Implemented

**TCZ Packages:**
- ❌ qemu-kvm.tcz - QEMU with KVM support
- ❌ libvirt.tcz - Virtualization API
- ❌ docker.tcz - Docker container runtime
- ❌ lxc.tcz - Linux containers
- ❌ podman.tcz - Podman container runtime
- ❌ containerd.tcz - containerd runtime

**Reason**: These require compiling from source or downloading from Tiny Core repos. Weeks of work.

**Kernel:**
- ❌ Custom kernel with KVM modules
- ❌ Kernel configuration testing
- ❌ Kernel packaging as TCZ

**Reason**: Kernel compilation is complex and time-consuming.

## Quick Start

### Prerequisites

**Required:**
- Linux system (Fedora, Ubuntu, Debian, etc.)
- 20GB+ free disk space
- 4GB+ RAM
- Internet connection

**Install build tools:**

```bash
# Fedora
sudo dnf install squashfs-tools mkisofs syslinux wget cpio gzip

# Ubuntu/Debian
sudo apt install squashfs-tools genisoimage syslinux-utils wget cpio gzip

# Arch
sudo pacman -S squashfs-tools cdrtools syslinux wget cpio gzip
```

### Validate Build Environment

```bash
cd build/scripts
./validate-build.sh
```

This checks:
- Disk space, RAM, architecture
- Required tools installed
- Project structure intact
- Script syntax
- Configuration validity

### Quick Test

```bash
./quick-test.sh
```

Runs rapid validation without downloading anything.

## Build Options

### Option 1: Package Building Only (TESTED ✅)

Build the virtos-tools TCZ package:

```bash
cd packages
./build-all.sh
```

**Output:**
- `packages/output/virtos-tools.tcz` (332KB)
- Package metadata and checksums

**Use case:** Create packages for manual installation into existing Tiny Core.

### Option 2: Full ISO Build (UNTESTED 🟡)

Build complete bootable ISO:

```bash
cd build/scripts
./build-all.sh
```

**What it does:**
1. Downloads Tiny Core Linux (~500MB)
2. Extracts and customizes initrd
3. Adds virtos-tools package
4. Creates bootable ISO

**Output:**
- `build/output/VirtOS-0.1-alpha-YYYYMMDD.iso`
- Checksums (MD5, SHA256)

**Time:** ~30-60 minutes (first build, includes download)

**Status:** Framework complete, not tested due to network/download requirements.

### Option 3: Custom Profile Build

Edit `build/build.conf` to select a profile:

```bash
# Choose one:
PROFILE="minimal"      # ~100MB, KVM only
PROFILE="standard"     # ~200MB, KVM + all containers (default)
PROFILE="full"         # ~400MB, everything
PROFILE="containers"   # ~150MB, container-focused
PROFILE="developer"    # ~250MB, dev tools included
PROFILE="kubernetes"   # ~250MB, K3s orchestration
PROFILE="storage"      # ~350MB, advanced storage (4GB+ RAM)
```

Then build:

```bash
cd build/scripts
./build-all.sh
```

## Build Workflow

### Detailed Steps

**1. Validation**
```bash
cd build/scripts
./validate-build.sh
```

**2. Package Build**
```bash
cd ../../packages
./build-all.sh
```

**3. ISO Preparation**
```bash
cd ../build/scripts
./prepare.sh
```

Downloads Tiny Core Linux and extracts it.

**4. Customization**
```bash
./customize.sh
```

Adds:
- VirtOS bootlocal.sh
- sysctl.conf
- Helper scripts
- Management tools
- Documentation

**5. ISO Creation**
```bash
./iso.sh
```

Creates bootable ISO with hybrid (USB) support.

## Testing the Build

### Test Package Contents

```bash
# Extract and inspect
cd packages/output
unsquashfs -l virtos-tools.tcz

# Verify checksums
md5sum -c virtos-tools.tcz.md5.txt

# View file list
cat virtos-tools.tcz.list
```

### Test ISO (Once Built)

```bash
# In QEMU/KVM
qemu-system-x86_64 \
    -enable-kvm \
    -m 2048 \
    -cdrom build/output/VirtOS-*.iso

# Write to USB (⚠️ DESTRUCTIVE - verify device!)
sudo dd if=build/output/VirtOS-*.iso of=/dev/sdX bs=4M status=progress
sync
```

## Build Configuration

### Configuration File: build/build.conf

**Key Options:**

```bash
# Base system
TC_VERSION="15.x"              # Tiny Core version
PROFILE="standard"             # Build profile

# Virtualization
INCLUDE_KVM="yes"              # KVM/QEMU
INCLUDE_LXC="yes"              # Linux Containers
INCLUDE_DOCKER="yes"           # Docker
INCLUDE_PODMAN="yes"           # Podman
INCLUDE_CONTAINERD="yes"       # containerd

# Management
INCLUDE_LIBVIRT="yes"          # Libvirt API
INCLUDE_VIRSH="yes"            # virsh CLI

# Networking
INCLUDE_BRIDGE_UTILS="yes"    # Bridge networking
INCLUDE_IPTABLES="yes"         # Firewall
INCLUDE_DNSMASQ="yes"          # DHCP/DNS

# Storage
INCLUDE_LVM="no"               # LVM (standard=no, full=yes)
INCLUDE_BTRFS="no"             # Btrfs
INCLUDE_ZFS="no"               # ZFS

# System
INCLUDE_BASH="yes"             # Bash shell
INCLUDE_VIM="yes"              # Vim editor
INCLUDE_OPENSSH="yes"          # SSH server

# Clustering
ENABLE_CLUSTERING="yes"        # Cluster discovery
INCLUDE_AVAHI="yes"            # mDNS for .local domains

# Kubernetes
INCLUDE_K3S="no"               # K3s (kubernetes profile=yes)

# Custom
INCLUDE_CUSTOM_SCRIPTS="yes"   # virtos-* management tools
```

### Profiles Comparison

| Profile | Size | KVM | LXC | Containers | K3s | Storage | Use Case |
|---------|------|-----|-----|------------|-----|---------|----------|
| minimal | ~100MB | ✓ | ✗ | containerd | ✗ | basic | Edge/IoT |
| standard | ~200MB | ✓ | ✓ | all 3 | ✗ | basic | Home lab |
| full | ~400MB | ✓ | ✓ | all 3 | ✓ | advanced | Production |
| containers | ~150MB | basic | ✗ | all 3 | ✗ | basic | Container focus |
| developer | ~250MB | ✓ | ✓ | all 3 | ✗ | basic | Development |
| kubernetes | ~250MB | ✓ | ✓ | all 3 | ✓ | basic | Orchestration |
| storage | ~350MB | ✓ | ✓ | containerd | ✗ | Btrfs/LVM/ZFS | Storage server |

## Build Output

### Successfully Built Artifacts ✅

```
packages/output/
├── virtos-tools.tcz            # 332KB - Management scripts package
├── virtos-tools.tcz.dep        # Dependencies
├── virtos-tools.tcz.info       # Package metadata
├── virtos-tools.tcz.list       # File listing
└── virtos-tools.tcz.md5.txt    # Checksum
```

### Expected ISO Output (Not Yet Built) 🟡

```
build/output/
├── VirtOS-0.1-alpha-YYYYMMDD.iso      # Bootable ISO
├── VirtOS-0.1-alpha-YYYYMMDD.iso.md5  # MD5 checksum
└── VirtOS-0.1-alpha-YYYYMMDD.iso.sha256  # SHA256 checksum
```

## Troubleshooting

### Common Issues

**1. "genisoimage not found"**

```bash
# Use mkisofs instead (same thing)
sudo dnf install mkisofs  # Fedora
# or edit iso.sh to use xorrisofs
```

**2. "Cannot reach tinycorelinux.net"**

Network/firewall blocking downloads. Options:
- Check firewall settings
- Use VPN if needed
- Download manually from http://tinycorelinux.net

**3. "mksquashfs not found"**

```bash
# Install squashfs-tools
sudo dnf install squashfs-tools  # Fedora
sudo apt install squashfs-tools  # Ubuntu/Debian
```

**4. "Permission denied" when building packages**

```bash
# Ensure ownership
sudo chown -R $USER:$USER packages/

# Or use sudo
sudo ./build-all.sh
```

**5. Syntax errors in scripts**

```bash
# Check which script
bash -n path/to/script.sh

# Check all
for script in config/custom-scripts/virtos-*; do
  bash -n "$script" || echo "Error in: $script"
done
```

## Advanced Build Options

### Custom Kernel

To use a custom kernel:

1. Build kernel with KVM modules (see `kernel/README.md`)
2. Package as `vmlinuz64` TCZ
3. Place in `packages/kernel/`
4. Update `customize.sh` to include it

### Adding TCZ Packages

To add new packages:

1. Create directory: `packages/package-name/`
2. Add build.sh, .tcz.info, .tcz.dep
3. Update `packages/build-all.sh` PACKAGES array
4. Build: `cd packages && ./build-all.sh`

Example package structure:
```
packages/qemu-kvm/
├── build.sh            # Build script
├── qemu-kvm.tcz.info   # Metadata
├── qemu-kvm.tcz.dep    # Dependencies
└── src/                # Source files or compiled binaries
```

### Offline Build

For air-gapped environments:

1. Download Tiny Core ISO manually
2. Place in `build/downloads/CorePure64-current.iso`
3. Download required TCZ packages
4. Place in `build/workspace/tcz/`
5. Run build with `OFFLINE=yes ./build-all.sh`

## Continuous Integration

The project includes GitHub Actions workflows:

- **ci.yml** - Validates scripts, checks syntax, tests package builds
- **documentation.yml** - Validates documentation

These run automatically on every commit.

## Build Performance

**Tested build times (on Fedora 44, 16 cores, 62GB RAM):**

- Package build (virtos-tools): **~2 seconds**
- Quick test: **~5 seconds**
- Validation: **~3 seconds**

**Estimated (untested):**

- Full ISO build (first time): **30-60 minutes** (includes download)
- Full ISO build (subsequent): **5-10 minutes** (cached)

## Next Steps

### To Make ISO Build Fully Functional

1. **Test ISO build** - Run prepare.sh/customize.sh/iso.sh with actual download
2. **Create more TCZ packages** - qemu, libvirt, docker, lxc
3. **Custom kernel** - Compile kernel with KVM modules
4. **Integration testing** - Boot ISO and test features

### To Expand Package Library

1. **QEMU package** - Compile QEMU with KVM support
2. **libvirt package** - Build libvirt and dependencies
3. **Container runtimes** - Package Docker, Podman, containerd
4. **Network tools** - OVS, WireGuard, etc.

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to help.

## Build Checklist

Before building:
- [ ] Validated environment (`./validate-build.sh`)
- [ ] Quick test passed (`./quick-test.sh`)
- [ ] Selected profile in `build.conf`
- [ ] 20GB+ free disk space
- [ ] Network connectivity for downloads

After building:
- [ ] Verify checksums
- [ ] Test in QEMU/KVM
- [ ] Check package contents
- [ ] Validate boot process
- [ ] Test basic functionality

## Additional Resources

- [TESTING.md](TESTING.md) - Comprehensive testing guide
- [packages/README.md](packages/README.md) - Package building guide
- [kernel/README.md](kernel/README.md) - Kernel configuration guide
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines

## Build Support

Issues with building?

1. Check [TESTING.md](TESTING.md) for validation procedures
2. Search existing issues: https://github.com/FlossWare/VirtOS/issues
3. Create new issue with:
   - Output of `./validate-build.sh`
   - Build command used
   - Error messages
   - OS and version

## License

VirtOS is released under the MIT License. See [LICENSE](LICENSE).
