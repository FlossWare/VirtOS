# VirtOS Build Dependencies

**Last Updated**: 2026-05-25  
**Applies To**: VirtOS 0.1+

---

## Overview

This document lists all dependencies required to build VirtOS from source, including package builds and ISO creation.

---

## Quick Start

### Fedora / Red Hat / CentOS

```bash
# Install all build dependencies
sudo dnf install \
  bash \
  wget \
  curl \
  git \
  squashfs-tools \
  genisoimage \
  syslinux \
  cpio \
  gzip \
  qemu-system-x86 \
  shellcheck
```

### Debian / Ubuntu

```bash
# Install all build dependencies
sudo apt-get update
sudo apt-get install \
  bash \
  wget \
  curl \
  git \
  squashfs-tools \
  genisoimage \
  syslinux-utils \
  isolinux \
  cpio \
  gzip \
  qemu-system-x86 \
  shellcheck
```

### Arch Linux

```bash
# Install all build dependencies
sudo pacman -S \
  bash \
  wget \
  curl \
  git \
  squashfs-tools \
  cdrtools \
  syslinux \
  cpio \
  gzip \
  qemu \
  shellcheck
```

---

## Dependency Categories

### Essential (Required for Package Build)

These are **required** to build VirtOS packages (.tcz files):

| Dependency | Purpose | Install Command (Fedora) | Install Command (Debian) |
|------------|---------|--------------------------|--------------------------|
| **bash** | Shell interpreter | `dnf install bash` | `apt install bash` |
| **squashfs-tools** | Create TCZ packages | `dnf install squashfs-tools` | `apt install squashfs-tools` |
| **git** | Version control | `dnf install git` | `apt install git` |

**Minimum to build packages**:
```bash
# Fedora
sudo dnf install bash squashfs-tools

# Debian/Ubuntu
sudo apt install bash squashfs-tools
```

### ISO Build (Required for Bootable ISO)

These are **required** to build bootable ISO images:

| Dependency | Purpose | Install Command (Fedora) | Install Command (Debian) |
|------------|---------|--------------------------|--------------------------|
| **genisoimage** | Create ISO 9660 filesystems | `dnf install genisoimage` | `apt install genisoimage` |
| **syslinux** | Bootloader utilities | `dnf install syslinux` | `apt install syslinux-utils isolinux` |
| **wget** | Download Tiny Core base | `dnf install wget` | `apt install wget` |
| **cpio** | Create initramfs | `dnf install cpio` | `apt install cpio` |
| **gzip** | Compression | `dnf install gzip` | `apt install gzip` |

**Minimum to build ISO**:
```bash
# Fedora
sudo dnf install genisoimage syslinux wget cpio gzip

# Debian/Ubuntu
sudo apt install genisoimage syslinux-utils isolinux wget cpio gzip
```

### Testing (Optional but Recommended)

| Dependency | Purpose | Install Command (Fedora) | Install Command (Debian) |
|------------|---------|--------------------------|--------------------------|
| **qemu-system-x86** | Test ISOs | `dnf install qemu-system-x86` | `apt install qemu-system-x86` |
| **shellcheck** | Lint shell scripts | `dnf install shellcheck` | `apt install shellcheck` |
| **bats** | Run unit tests | `dnf install bats` | `apt install bats` |

### Network Access

**Required Hosts**:
- `tinycorelinux.net` - Download Tiny Core Linux base system
- `repo.tinycorelinux.net` - Download TCZ packages
- `packagecloud.io` - Deploy VirtOS packages (CD pipeline only)
- `github.com` - Source repository

**Firewall Rules**:
```bash
# Allow outbound HTTP/HTTPS
# Port 80 (HTTP)
# Port 443 (HTTPS)
```

**Offline Build Workaround**: See [Offline Build](#offline-build) section below.

---

## Dependency Resolution

### Issue: genisoimage not found

**Symptoms**:
```
ERROR: genisoimage not found
Install required tools:
  Fedora:        sudo dnf install genisoimage syslinux
```

**Solution**:
```bash
# Fedora/RHEL/CentOS
sudo dnf install genisoimage syslinux

# Debian/Ubuntu
sudo apt install genisoimage syslinux-utils isolinux

# Arch Linux (use cdrtools instead)
sudo pacman -S cdrtools syslinux
```

**Alternative (Arch Linux)**:
On Arch Linux, `genisoimage` is part of `cdrtools`:
```bash
sudo pacman -S cdrtools
# Creates symlink: genisoimage -> mkisofs
```

---

### Issue: Cannot reach tinycorelinux.net

**Symptoms**:
```
WARNING: Cannot reach tinycorelinux.net (required for downloads)
```

**Causes**:
1. Network/firewall blocking access
2. DNS resolution failure
3. Temporary site outage
4. Offline environment

**Solutions**:

#### 1. Check Network Connectivity
```bash
# Test basic connectivity
ping tinycorelinux.net

# Test HTTP access
wget -q --spider https://tinycorelinux.net/15.x/x86_64/release/distribution_files/core.gz
echo $?  # Should return 0 for success
```

#### 2. Check DNS Resolution
```bash
# Verify DNS works
nslookup tinycorelinux.net

# Try alternative DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf.temp
```

#### 3. Check Firewall
```bash
# Fedora - check firewalld
sudo firewall-cmd --list-all

# Ubuntu - check ufw
sudo ufw status

# Allow outbound HTTP/HTTPS if blocked
sudo firewall-cmd --add-service=http --add-service=https
```

#### 4. Use Offline Build
See [Offline Build](#offline-build) section below.

---

### Issue: squashfs-tools missing

**Symptoms**:
```
mksquashfs: command not found
```

**Solution**:
```bash
# Fedora
sudo dnf install squashfs-tools

# Debian/Ubuntu
sudo apt install squashfs-tools

# Arch
sudo pacman -S squashfs-tools
```

---

### Issue: isohybrid not found

**Symptoms**:
```
WARNING: isohybrid failed, ISO may not boot from USB
```

**Solution**:
```bash
# Fedora
sudo dnf install syslinux

# Debian/Ubuntu
sudo apt install syslinux-utils

# Arch
sudo pacman -S syslinux
```

**Note**: This is non-critical - ISO will still boot from CD/DVD, just not from USB stick.

---

## Offline Build

### Scenario

Building VirtOS in an environment without internet access (air-gapped network, restricted firewall, etc.).

### Preparation (Online Machine)

On a machine **with internet access**:

```bash
# 1. Clone VirtOS repository
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS

# 2. Create downloads directory
mkdir -p build/downloads

# 3. Download Tiny Core Linux base (adjust version as needed)
TC_VERSION="15.x"
TC_ARCH="x86_64"
cd build/downloads

# Core files
wget https://tinycorelinux.net/${TC_VERSION}/${TC_ARCH}/release/distribution_files/vmlinuz64
wget https://tinycorelinux.net/${TC_VERSION}/${TC_ARCH}/release/distribution_files/core.gz
wget https://tinycorelinux.net/${TC_VERSION}/${TC_ARCH}/release/distribution_files/core.gz.md5.txt

# Verify checksums
md5sum -c core.gz.md5.txt

# 4. Download required TCZ packages (optional, for full offline build)
# List of packages to download
PACKAGES="
qemu.tcz
libvirt.tcz
docker.tcz
lxc.tcz
dialog.tcz
whiptail.tcz
avahi.tcz
"

for pkg in $PACKAGES; do
  wget https://repo.tinycorelinux.net/${TC_VERSION}/${TC_ARCH}/tcz/${pkg}
  wget https://repo.tinycorelinux.net/${TC_VERSION}/${TC_ARCH}/tcz/${pkg}.md5.txt
done

# 5. Package everything for transfer
cd ../..
tar czf virtos-offline.tar.gz \
  build/ \
  packages/ \
  config/ \
  docs/ \
  ci/ \
  .github/ \
  README.md \
  LICENSE \
  VERSION

# Transfer virtos-offline.tar.gz to offline machine
```

### Build (Offline Machine)

On the **offline/air-gapped machine**:

```bash
# 1. Install build dependencies (from local repository or RPM/DEB files)
# Fedora example with local RPMs
sudo dnf install --downloadonly --downloaddir=/tmp/rpms \
  bash squashfs-tools genisoimage syslinux

# Transfer RPMs to offline machine, then:
sudo dnf install /tmp/rpms/*.rpm

# 2. Extract VirtOS
tar xzf virtos-offline.tar.gz
cd VirtOS

# 3. Verify downloads exist
ls -lh build/downloads/
# Should see: vmlinuz64, core.gz, core.gz.md5.txt

# 4. Modify prepare.sh to skip download if files exist
vim build/scripts/prepare.sh

# Add this before download section:
if [ -f "$DOWNLOADS_DIR/core.gz" ] && [ -f "$DOWNLOADS_DIR/vmlinuz64" ]; then
    echo "Using cached TC base files (offline mode)..."
    SKIP_DOWNLOAD=true
else
    SKIP_DOWNLOAD=false
fi

if [ "$SKIP_DOWNLOAD" = false ]; then
    # ... existing download code ...
fi

# 5. Build packages (no network required)
cd packages
./build-all.sh

# 6. Build ISO (using cached files)
cd ../build/scripts
./build-all.sh
```

### Offline Build Validation

```bash
# Verify offline build works
cd build/scripts
./quick-test.sh

# Should see:
# ✓ All scripts valid
# ✓ Package built successfully
# ⚠ Cannot reach tinycorelinux.net (expected in offline mode)
```

---

## CI/CD Dependencies

GitHub Actions runners include most dependencies by default:

**Pre-installed**:
- bash, git, wget, curl
- cpio, gzip
- squashfs-tools

**Must Install in Workflow**:
- genisoimage
- syslinux-utils
- shellcheck (optional)

**Example CI Step**:
```yaml
- name: Install build tools
  run: |
    sudo apt-get update
    sudo apt-get install -y \
      squashfs-tools \
      genisoimage \
      syslinux-utils \
      shellcheck
```

---

## Verification

### Check All Dependencies Installed

```bash
# Run validation script
cd build/scripts
./validate-build.sh

# Should show:
# ✓ bash found
# ✓ wget found
# ✓ genisoimage found
# ✓ isohybrid found
# ✓ cpio found
# ✓ gzip found
# ✓ qemu-system-x86_64 found
# ✓ git found
```

### Quick Test Build

```bash
# Test package build
cd packages
./build-all.sh

# Verify
ls -lh output/virtos-tools.tcz
# Should be ~340 KB

# Test ISO build (if genisoimage installed)
cd ../build/scripts
./quick-test.sh

# Should complete without errors
```

---

## Platform-Specific Notes

### macOS

VirtOS build is **not officially supported** on macOS, but can work with modifications:

```bash
# Install via Homebrew
brew install \
  bash \
  wget \
  squashfs \
  cdrtools \
  qemu

# Note: Use mkisofs instead of genisoimage
# Modify build/scripts/iso.sh:
#   genisoimage → mkisofs
```

**Recommendation**: Use Linux VM or Docker for building on macOS.

### Windows (WSL)

Use Windows Subsystem for Linux (WSL2):

```powershell
# In PowerShell (install WSL2 if not already)
wsl --install -d Ubuntu

# In WSL Ubuntu shell
sudo apt update
sudo apt install \
  bash \
  wget \
  git \
  squashfs-tools \
  genisoimage \
  syslinux-utils \
  isolinux \
  qemu-system-x86

# Clone and build
cd ~
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS
cd packages && ./build-all.sh
```

**Recommendation**: WSL2 is fully supported for VirtOS builds.

### Docker

Build VirtOS inside a Docker container:

```dockerfile
# Dockerfile.build
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    bash \
    wget \
    curl \
    git \
    squashfs-tools \
    genisoimage \
    syslinux-utils \
    isolinux \
    cpio \
    gzip \
    qemu-system-x86 \
    shellcheck

WORKDIR /workspace

# Usage:
# docker build -t virtos-builder -f Dockerfile.build .
# docker run -v $(pwd):/workspace virtos-builder bash -c "cd packages && ./build-all.sh"
```

---

## Troubleshooting

### "Cannot create TCZ package"

**Problem**: `mksquashfs` fails

**Solution**:
```bash
# Check squashfs-tools installed
which mksquashfs

# If not found
sudo dnf install squashfs-tools  # Fedora
sudo apt install squashfs-tools  # Debian
```

### "ISO creation failed"

**Problem**: `genisoimage` command fails

**Diagnosis**:
```bash
# Check tool exists
which genisoimage

# Test manually
cd build/workspace/iso-contents
genisoimage -o /tmp/test.iso .
```

**Solution**: Install genisoimage (see above)

### "Permission denied" errors

**Problem**: Scripts not executable

**Solution**:
```bash
# Fix permissions
chmod +x build/scripts/*.sh
chmod +x config/custom-scripts/virtos-*
chmod +x packages/*/build.sh

# Or use git to restore
git checkout -- build/scripts/
```

---

## Related Documentation

- [ISO_BUILD_STATUS.md](../ISO_BUILD_STATUS.md) - ISO build validation status
- [RUNTIME_TESTING_PLAN.md](../RUNTIME_TESTING_PLAN.md) - Testing requirements
- [README.md](../README.md) - Project overview
- [BUILD.md](../BUILD.md) - Build instructions (if exists)

---

**Questions?**
- File an issue: https://github.com/FlossWare/VirtOS/issues
- Check discussions: https://github.com/FlossWare/VirtOS/discussions
