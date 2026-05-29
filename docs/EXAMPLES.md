# VirtOS Examples

Practical examples for common use cases and workflows.

## Table of Contents

- [Quick Start Examples](#quick-start-examples)
- [Build System Examples](#build-system-examples)
- [Package Management](#package-management)
- [Development Workflows](#development-workflows)
- [Testing Examples](#testing-examples)

## Quick Start Examples

### Example 1: Build Your First Package (2 minutes)

```bash
# Clone the repository
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS

# Build the package
make packages

# Check the output
ls -lh packages/output/
```

**Expected output:**

```
virtos-tools.tcz          332K
virtos-tools.tcz.md5.txt   51B
virtos-tools.tcz.info     651B
virtos-tools.tcz.list    1.8K
```

### Example 2: Validate Your Environment

```bash
# Run validation
make validate

# Expected to check:
# - Disk space (need 20GB+)
# - RAM (need 4GB+)
# - Build tools installed
# - Project structure
# - Script syntax
```

### Example 3: Quick Test Everything

```bash
# Fast 5-second validation
make test

# Runs:
# 1. Environment validation
# 2. Script syntax checks
# 3. Package build test
# 4. Configuration validation
```

## Build System Examples

### Example 4: Build with Different Profiles

**Minimal Profile** (smallest, ~100MB target):

```bash
# Edit build/build.conf
PROFILE="minimal"

# Build
make build
```

**Full Profile** (everything, ~400MB target):

```bash
# Edit build/build.conf
PROFILE="full"

# Build
make build
```

**Custom Profile:**

```bash
# Edit build/build.conf
PROFILE="custom"
INCLUDE_KVM="yes"
INCLUDE_DOCKER="yes"
INCLUDE_LXC="no"
INCLUDE_PODMAN="no"

# Build
make build
```

### Example 5: Build for Specific Use Cases

**Container-focused build:**

```bash
# Edit build/build.conf
PROFILE="containers"
# Includes: Docker, Podman, containerd, minimal VMs

make build
```

**Kubernetes orchestration:**

```bash
# Edit build/build.conf
PROFILE="kubernetes"
# Includes: K3s, all runtimes, clustering

make build
```

**Storage server:**

```bash
# Edit build/build.conf
PROFILE="storage"
# Includes: Btrfs, LVM, ZFS, NFS

make build
```

## Package Management

### Example 6: Inspect Package Contents

```bash
# View files in package
cat packages/output/virtos-tools.tcz.list

# Verify checksum
cd packages/output
md5sum -c virtos-tools.tcz.md5.txt

# Extract package (requires squashfs-tools)
unsquashfs virtos-tools.tcz
ls -la squashfs-root/
```

### Example 7: Install Package in Tiny Core

**On a Tiny Core system:**

```bash
# Copy package to Tiny Core
scp packages/output/virtos-tools.tcz tc@tinycore:/tmp/

# On Tiny Core, install
tce-load -i /tmp/virtos-tools.tcz

# Verify installation
virtos-tui --help
virtos-cluster status
```

### Example 8: Create Custom Package

```bash
# Create package directory
mkdir -p packages/my-package/src/usr/local/bin

# Add your scripts
cp my-script.sh packages/my-package/src/usr/local/bin/

# Create metadata
cat > packages/my-package/my-package.tcz.info << EOF
Title:          my-package.tcz
Description:    My custom VirtOS package
Version:        1.0
Author:         Your Name
...
EOF

# Create build script (copy from virtos-tools/build.sh)
cp packages/virtos-tools/build.sh packages/my-package/

# Build
cd packages/my-package
./build.sh
```

## Development Workflows

### Example 9: Add a New virtos-* Script

```bash
# Create new script
cat > config/custom-scripts/virtos-mynewfeature << 'EOF'
#!/bin/bash
# VirtOS My New Feature

echo "This is my new feature!"
EOF

# Make executable
chmod +x config/custom-scripts/virtos-mynewfeature

# Test syntax
bash -n config/custom-scripts/virtos-mynewfeature

# Test execution
./config/custom-scripts/virtos-mynewfeature

# Rebuild package
make packages

# New script is now in virtos-tools.tcz
```

### Example 10: Modify Existing Script

```bash
# Edit script
vim config/custom-scripts/virtos-cluster

# Check syntax
make check

# Test
make test

# Rebuild
make packages

# Commit
git add config/custom-scripts/virtos-cluster
git commit -m "feat: Improve virtos-cluster auto-discovery"
```

### Example 11: Development with Git Hooks

```bash
# Setup development environment
make dev-setup

# This installs pre-commit hook that runs 'make check'

# Now when you commit, syntax is checked automatically
git commit -m "feat: Add new feature"
# Pre-commit hook runs make check
# Commit proceeds if no errors
```

## Testing Examples

### Example 12: Run Validation Before Committing

```bash
# Full validation workflow
make check      # Syntax
make test       # Quick test
make packages   # Build packages
make validate   # Environment check

# If all pass, commit
git commit -m "feat: My changes"
```

### Example 13: Test Build on Clean System

```bash
# Clean everything
make clean-all

# Validate from scratch
make validate

# Build from scratch
make packages

# Verifies build works on clean system
```

### Example 14: Continuous Testing During Development

```bash
# Terminal 1: Watch for changes
watch -n 5 'make check && echo "✓ All good"'

# Terminal 2: Edit files
vim config/custom-scripts/virtos-mynewscript

# Terminal 1 will show syntax errors immediately
```

## Automation Examples

### Example 15: Automated Build Script

```bash
#!/bin/bash
# auto-build.sh - Automated build with validation

set -e

echo "Starting automated build..."

# Validate
echo "[1/4] Validating..."
make validate

# Check syntax
echo "[2/4] Checking syntax..."
make check

# Test
echo "[3/4] Testing..."
make test

# Build
echo "[4/4] Building..."
make packages

echo "✓ Build complete!"
ls -lh packages/output/
```

### Example 16: Build Matrix (Multiple Profiles)

```bash
#!/bin/bash
# build-matrix.sh - Build all profiles

PROFILES="minimal standard full containers developer kubernetes storage"

for profile in $PROFILES; do
    echo "Building profile: $profile"

    # Update config
    sed -i "s/^PROFILE=.*/PROFILE=\"$profile\"/" build/build.conf

    # Build
    make build

    # Rename output
    mv build/output/VirtOS-*.iso build/output/VirtOS-$profile.iso

    echo "✓ $profile complete"
done
```

## Real-World Scenarios

### Example 17: Contributing a Bug Fix

```bash
# 1. Create branch
git checkout -b fix/virtos-backup-typo

# 2. Fix the bug
vim config/custom-scripts/virtos-backup
# Fix typo on line 42

# 3. Test
bash -n config/custom-scripts/virtos-backup  # Syntax
./config/custom-scripts/virtos-backup --help  # Execution

# 4. Commit
git add config/custom-scripts/virtos-backup
git commit -m "fix: Correct typo in virtos-backup help text"

# 5. Push and create PR
git push origin fix/virtos-backup-typo
```

### Example 18: Adding Documentation

```bash
# 1. Create branch
git checkout -b docs/add-examples

# 2. Add documentation
vim docs/MY-NEW-DOC.md

# 3. Update index
vim docs/INDEX.md
# Add link to new doc

# 4. Test markdown
# (optional: use markdown linter)

# 5. Commit
git add docs/
git commit -m "docs: Add examples for common use cases"

# 6. Push
git push origin docs/add-examples
```

### Example 19: Testing on Real Hardware

```bash
# 1. Build ISO
make build

# 2. Write to USB drive (⚠️ CAREFUL! Double-check device!)
sudo dd if=build/output/VirtOS-*.iso of=/dev/sdX bs=4M status=progress
sync

# 3. Boot from USB
# - Insert USB into target machine
# - Boot and select USB
# - Test VirtOS features

# 4. Report results
# Open GitHub issue with:
# - Hardware specs
# - What worked
# - What didn't work
# - Logs if any errors
```

## Advanced Examples

### Example 20: Custom Kernel Build

```bash
# 1. Prepare kernel source
cd /tmp
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.30.tar.xz
tar xf linux-6.6.30.tar.xz
cd linux-6.6.30

# 2. Use VirtOS kernel config
cp /path/to/VirtOS/kernel/virtos-base.config.example .config
make oldconfig

# 3. Build
make -j$(nproc)
make modules_install
make install

# 4. Package for Tiny Core
# (See kernel/README.md for TCZ packaging)
```

### Example 21: Multi-Host Testing

```bash
# Terminal 1 - Host 1
qemu-system-x86_64 -enable-kvm -m 2048 \
    -cdrom VirtOS.iso \
    -net nic -net user,hostfwd=tcp::2222-:22

# Terminal 2 - Host 2
qemu-system-x86_64 -enable-kvm -m 2048 \
    -cdrom VirtOS.iso \
    -net nic -net user,hostfwd=tcp::2223-:22

# Terminal 3 - Test clustering
ssh -p 2222 tc@localhost virtos-cluster list
ssh -p 2223 tc@localhost virtos-cluster list
# Should see both hosts
```

## Performance Testing

### Example 22: Benchmark Build Times

```bash
#!/bin/bash
# benchmark-build.sh

echo "Benchmarking VirtOS build..."

# Clean
time make clean-all

# Package build
echo "Testing package build..."
time make packages

# Repeat 3 times for average
for i in 1 2 3; do
    make clean
    time make packages 2>&1 | grep real
done
```

### Example 23: Package Size Optimization

```bash
# Before optimization
ls -lh packages/output/virtos-tools.tcz

# Remove debug symbols from binaries (if any)
find packages/virtos-tools/src -type f -executable -exec strip --strip-unneeded {} \;

# Rebuild
cd packages/virtos-tools
./build.sh

# After optimization
ls -lh virtos-tools.tcz

# Compare sizes
```

## Troubleshooting Examples

### Example 24: Debug Build Failures

```bash
# Enable verbose output
set -x

# Run build with debug
cd packages
bash -x build-all.sh

# Check logs
tail -f /tmp/virtos-*.log
```

### Example 25: Fix Permission Issues

```bash
# Find files without execute permission
find config/custom-scripts -name "virtos-*" ! -perm -111

# Fix them
chmod +x config/custom-scripts/virtos-*

# Verify
ls -l config/custom-scripts/virtos-* | grep -v "rwxr-xr-x" && echo "Still have issues" || echo "All fixed"
```

## Tips and Tricks

### Tip 1: Fast Iteration

```bash
# Use quick-test during development
watch -n 2 'make test'
```

### Tip 2: Check Before Commit

```bash
# Add to git alias
git config alias.check '!make check && make test'

# Use it
git check
```

### Tip 3: Package Only Changed Scripts

```bash
# Incremental rebuild (packages/virtos-tools/build.sh already handles this)
cd packages/virtos-tools
./build.sh
```

## See Also

- [BUILD.md](../BUILD.md) - Complete build guide
- [TESTING.md](../TESTING.md) - Testing procedures
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
- [QUICKSTART.md](../QUICKSTART.md) - Quick start guide

---

Have more examples to share? Contribute them via PR!
