# VirtOS Packages

This directory contains Tiny Core Linux (TCZ) package definitions and build scripts for VirtOS components.

## Package Overview

VirtOS extends Tiny Core Linux with additional packages for virtualization and management. Packages are distributed as TCZ (Tiny Core Zipped) extensions.

## Core Packages

### Virtualization
- **qemu-kvm.tcz** - QEMU with KVM support
- **libvirt.tcz** - Virtualization API and tools
- **lxc.tcz** - Linux Containers
- **docker.tcz** - Docker container runtime (optional)
- **podman.tcz** - Podman container runtime (optional)
- **containerd.tcz** - containerd runtime (optional)

### Management
- **virtos-tools.tcz** - VirtOS management scripts
- **virtos-tui.tcz** - Text-based user interface
- **dialog.tcz** - TUI dependency
- **ncurses.tcz** - Terminal UI library

### Networking
- **bridge-utils.tcz** - Network bridge utilities
- **iptables.tcz** - Firewall management
- **avahi.tcz** - mDNS for cluster discovery
- **openvswitch.tcz** - Software-defined networking (optional)

### Storage
- **lvm2.tcz** - Logical Volume Manager
- **btrfs-progs.tcz** - Btrfs utilities
- **zfs.tcz** - ZFS filesystem (optional)
- **nfs-utils.tcz** - NFS client/server (optional)

### Monitoring
- **prometheus.tcz** - Metrics collection (optional)
- **node-exporter.tcz** - System metrics (optional)

## Package Structure

Each package directory contains:

```
package-name/
├── build.sh           # Build script
├── package.tcz.info   # Package metadata
├── package.tcz.dep    # Dependencies
├── package.tcz.list   # File list
└── src/               # Source code or files
```

## Building Packages

### Prerequisites

Install Tiny Core Linux compilation tools:
```bash
tce-load -wi compiletc squashfs-tools
```

### Build a Single Package

```bash
cd packages/virtos-tools
./build.sh
```

This creates:
- `virtos-tools.tcz` - The package archive
- `virtos-tools.tcz.md5.txt` - Checksum
- `virtos-tools.tcz.info` - Package info
- `virtos-tools.tcz.dep` - Dependencies
- `virtos-tools.tcz.list` - File listing

### Build All Packages

```bash
cd packages
./build-all.sh
```

Packages are output to `packages/output/`.

## Package Profiles

Different VirtOS profiles require different package sets:

### Minimal Profile (~100MB)
```
qemu-kvm.tcz
libvirt.tcz
containerd.tcz
virtos-tools.tcz
bridge-utils.tcz
```

### Standard Profile (~200MB)
```
<minimal packages>
+ lxc.tcz
+ docker.tcz
+ podman.tcz
+ virtos-tui.tcz
+ avahi.tcz
```

### Full Profile (~400MB)
```
<standard packages>
+ lvm2.tcz
+ btrfs-progs.tcz
+ zfs.tcz
+ openvswitch.tcz
+ prometheus.tcz
```

See `../config/profiles/` for complete profile definitions.

## Installing Packages

### During Build
Packages are automatically included in the ISO based on the selected profile.

### On Running System
```bash
# Load package from ISO
tce-load -i virtos-tools.tcz

# Load package from repository
tce-load -wi virtos-tools

# Load package on boot
tce-load -i virtos-tools.tcz
echo "virtos-tools.tcz" >> /etc/sysconfig/tcedir/onboot.lst
```

## Package Dependencies

### virtos-tools.tcz
```
bash.tcz
coreutils.tcz
grep.tcz
sed.tcz
```

### qemu-kvm.tcz
```
glib2.tcz
pixman.tcz
libfdt.tcz
libslirp.tcz
```

### libvirt.tcz
```
qemu-kvm.tcz
libxml2.tcz
gnutls.tcz
yajl.tcz
```

### docker.tcz
```
containerd.tcz
runc.tcz
libseccomp.tcz
```

See individual `.tcz.dep` files for complete dependency trees.

## Creating Custom Packages

### Example: Creating virtos-tools.tcz

1. **Create package directory:**
```bash
mkdir -p packages/virtos-tools/src/usr/local/bin
mkdir -p packages/virtos-tools/src/usr/local/tce.installed
```

2. **Copy files:**
```bash
cp ../config/custom-scripts/virtos-* packages/virtos-tools/src/usr/local/bin/
```

3. **Create install script:**
```bash
cat > packages/virtos-tools/src/usr/local/tce.installed/virtos-tools << 'EOF'
#!/bin/sh
# Post-install script
chmod +x /usr/local/bin/virtos-*
EOF
chmod +x packages/virtos-tools/src/usr/local/tce.installed/virtos-tools
```

4. **Create metadata:**
```bash
cat > packages/virtos-tools/virtos-tools.tcz.info << EOF
Title:          virtos-tools
Description:    VirtOS management tools
Version:        1.0
Author:         FlossWare
Original-site:  https://github.com/FlossWare/VirtOS
Copying-policy: MIT
Size:           1.2M
Extension_by:   FlossWare
Tags:           virtualization management
Comments:       Core VirtOS management scripts
Change-log:     2026/05/24 Initial release
Current:        2026/05/24
EOF
```

5. **Create dependency file:**
```bash
cat > packages/virtos-tools/virtos-tools.tcz.dep << EOF
bash.tcz
dialog.tcz
EOF
```

6. **Create build script:**
```bash
cat > packages/virtos-tools/build.sh << 'EOF'
#!/bin/bash
set -e

PACKAGE="virtos-tools"
VERSION="1.0"

# Clean previous build
rm -f ${PACKAGE}.tcz ${PACKAGE}.tcz.md5.txt ${PACKAGE}.tcz.list

# Create package
cd src
sudo mksquashfs . ../${PACKAGE}.tcz -noappend -b 4096

# Generate file list
cd ..
unsquashfs -l ${PACKAGE}.tcz | tail -n +4 | sed 's/^squashfs-root//' > ${PACKAGE}.tcz.list

# Generate checksum
md5sum ${PACKAGE}.tcz > ${PACKAGE}.tcz.md5.txt

echo "Package ${PACKAGE}.tcz created successfully"
EOF
chmod +x packages/virtos-tools/build.sh
```

7. **Build the package:**
```bash
cd packages/virtos-tools
./build.sh
```

## Package Repository

Built packages can be hosted in a repository for easy installation:

### Local Repository
```bash
# Create repository structure
mkdir -p /opt/tcz-repo

# Copy packages
cp packages/output/*.tcz* /opt/tcz-repo/

# Serve via HTTP
cd /opt/tcz-repo
python3 -m http.server 8080
```

### Remote Repository
Upload packages to a web server and configure Tiny Core to use it:
```bash
echo "http://yourserver.com/tcz-repo" > /opt/tcedir/mirrors.lst
```

## Testing Packages

### Basic Tests
```bash
# Extract and inspect
unsquashfs virtos-tools.tcz
ls -la squashfs-root/

# Verify dependencies
cat virtos-tools.tcz.dep

# Test installation
sudo tce-load -i virtos-tools.tcz
virtos-tui --help
```

### Automated Tests
```bash
# Run package test suite
./test-package.sh virtos-tools.tcz
```

## Package Updates

To update a package:
1. Modify source files
2. Update version in `.tcz.info`
3. Add entry to `Change-log` in `.tcz.info`
4. Rebuild package
5. Update checksum

## Package Size Optimization

Tips for keeping packages small:
- Strip binaries: `strip --strip-unneeded binary`
- Remove debug symbols: `strip --strip-debug library.so`
- Compress with UPX: `upx --best binary` (carefully, may break some binaries)
- Split large packages into base + optional components
- Use shared dependencies instead of static linking

## Upstream Sources

Where to get sources for common packages:

- **QEMU**: https://www.qemu.org/download/
- **libvirt**: https://libvirt.org/downloads.html
- **LXC**: https://linuxcontainers.org/lxc/downloads/
- **Docker**: https://github.com/moby/moby
- **Podman**: https://github.com/containers/podman
- **containerd**: https://github.com/containerd/containerd

## Contributing Packages

To contribute a new package:
1. Create package directory structure
2. Write build script
3. Test on clean Tiny Core system
4. Document dependencies
5. Submit PR with package files

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## Package Signing

For security, packages should be signed:

```bash
# Generate key (once)
gpg --gen-key

# Sign package
gpg --armor --detach-sign virtos-tools.tcz

# Verify signature
gpg --verify virtos-tools.tcz.asc virtos-tools.tcz
```

## Troubleshooting

### Package won't load
```bash
# Check dependencies
cat package.tcz.dep

# Load dependencies manually
tce-load -i dependency.tcz

# Check for missing libraries
ldd /usr/local/bin/program
```

### Build fails
```bash
# Ensure build tools installed
tce-load -wi compiletc

# Check for missing build dependencies
# Install them with tce-load -wi

# Check build.sh for errors
bash -x build.sh
```

### Package too large
```bash
# Check what's inside
unsquashfs -l package.tcz

# Look for unexpected files
# Remove documentation, man pages if not needed
# Split into multiple packages
```

## References

- [Tiny Core Extension Building](https://wiki.tinycorelinux.net/wiki:creating_extensions)
- [TCZ Format Specification](https://wiki.tinycorelinux.net/wiki:tcz_format)
- [Package Guidelines](https://wiki.tinycorelinux.net/wiki:extension_guidelines)

## Status

**Current State**: Package definitions to be added

**Next Steps**:
1. Create build scripts for core packages
2. Set up build environment
3. Build and test packages
4. Create package repository

See [TESTING.md](../TESTING.md) for testing procedures.
