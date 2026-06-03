# VirtOS ISO Build Testing Guide

**Last Updated**: 2026-06-03  
**Status**: Testing Framework Implemented  
**Automated Tests**: ✅ Available  
**Manual Tests**: ✅ Available

## Quick Start

```bash
# Test ISO build for the default profile (standard)
cd VirtOS/build/scripts
./test-iso-build.sh

# Test ISO boot in QEMU
./test-iso-boot.sh

# Test all 7 profiles
./test-all-profiles.sh
```

## Testing Scripts

### 1. test-iso-build.sh - ISO Build Validation

Tests the ISO build process end-to-end:
- Pre-flight checks (disk space, tools, project structure)
- Pre-build validation (configuration, script syntax)
- ISO build for specified profile(s)
- ISO file integrity (checksums, structure)

**Usage**:
```bash
./test-iso-build.sh
TEST_PROFILES=minimal ./test-iso-build.sh
TEST_PROFILES="minimal standard full" ./test-iso-build.sh
VERBOSE=1 ./test-iso-build.sh
SKIP_DOWNLOAD=1 ./test-iso-build.sh  # Reuse cached downloads
```

### 2. test-iso-boot.sh - ISO Boot Testing

Validates that built ISO images boot in QEMU:
- QEMU/KVM availability check
- ISO boots and kernel loads
- Initramfs extracts successfully
- Shell environment becomes ready

**Usage**:
```bash
./test-iso-boot.sh
HEADLESS=1 ./test-iso-boot.sh        # Serial output only
BOOT_TIMEOUT=300 ./test-iso-boot.sh  # Wait up to 5 minutes
QEMU_MEMORY=1024 ./test-iso-boot.sh  # Use less RAM
```

**VNC Display** (when run with HEADLESS=0, default):
```bash
# In another terminal
vncviewer :99
```

### 3. test-all-profiles.sh - Multi-Profile Testing

Tests all 7 build profiles sequentially:
- minimal - Minimal VirtOS (~100MB)
- standard - Balanced configuration (~200MB)
- full - Everything included (~400MB)
- containers - Container-focused (~150MB)
- developer - Development tools (~250MB)
- kubernetes - K3s orchestration (~250MB)
- storage - Advanced storage (~350MB)

**Usage**:
```bash
./test-all-profiles.sh
DRY_RUN=1 ./test-all-profiles.sh  # Preview without building
```

## Test Workflow

### Phase 1: Quick Validation (5 min)
```bash
./build/scripts/validate-build.sh
```

### Phase 2: Single Profile Build (30-60 min)
```bash
cd build/scripts
TEST_PROFILES=minimal ./test-iso-build.sh
```

### Phase 3: Boot Testing (5-30 min)
```bash
HEADLESS=1 ./test-iso-boot.sh
```

### Phase 4: All Profiles (2-4 hours)
```bash
./test-all-profiles.sh
```

## Troubleshooting

### "Insufficient disk space"
Free up space or use a partition with >20GB available.

### "Tool not found" (genisoimage, etc.)
```bash
# Debian/Ubuntu
sudo apt install genisoimage syslinux-utils wget cpio gzip

# Fedora
sudo dnf install genisoimage syslinux wget cpio gzip
```

### "qemu-system-x86_64 not found"
```bash
# Debian/Ubuntu
sudo apt install qemu-system-x86

# Fedora
sudo dnf install qemu-system-x86
```

### Boot test times out
Increase timeout or check system resources:
```bash
BOOT_TIMEOUT=300 ./test-iso-boot.sh  # 5 minute timeout
free -h  # Check RAM
nproc    # Check CPUs
```

## Test Coverage

| Test | Automation | Status |
|------|-----------|--------|
| Pre-flight checks | ✅ Automated | Ready |
| Build environment validation | ✅ Automated | Ready |
| ISO build (all profiles) | ✅ Automated | Ready |
| ISO integrity validation | ✅ Automated | Ready |
| Boot testing | ✅ Automated | Ready |
| Hardware testing | ⏳ Manual | Needed |

## See Also

- [ISO_TESTING_STATUS.md](ISO_TESTING_STATUS.md) - Test tracking
- [RUNTIME_TESTING_PLAN.md](RUNTIME_TESTING_PLAN.md) - Manual testing procedures
- [build/build.conf](build/build.conf) - Build configuration
- [.github/workflows/iso-build-test.yml](.github/workflows/iso-build-test.yml) - CI/CD workflow

## Summary

VirtOS now has comprehensive automated ISO build and boot testing. All scripts are ready to use:

```bash
cd VirtOS/build/scripts
./test-iso-build.sh      # Build and validate ISO
./test-iso-boot.sh       # Test ISO boot in QEMU
./test-all-profiles.sh   # Test all 7 profiles
```

See `ISO_TESTING_STATUS.md` to track test progress and results.
