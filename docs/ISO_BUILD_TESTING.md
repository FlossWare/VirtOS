# VirtOS ISO Build Testing Guide

**Last Updated**: 2026-06-09  
**Status**: Testing Framework Implemented  
**Automated Tests**: ✅ Available  
**Manual Tests**: ✅ Available

This document describes the automated ISO testing framework for VirtOS ISO building and validation.

## Overview

VirtOS now includes a complete automated testing framework for ISO building that validates:

1. **Build prerequisites** - Tools, disk space, configuration
2. **ISO creation** - Successful build with proper output
3. **ISO content** - Boot loader, kernel, initrd present
4. **Boot capability** - QEMU boot testing (optional)
5. **All profiles** - Tests all 7 build profiles

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

### Run in GitHub Actions

Push to any branch or open a pull request. The `iso-build-test.yml` workflow automatically tests 3 profiles.

## Testing Framework

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

Tests all 7 build profiles sequentially.

**Usage**:
```bash
./test-all-profiles.sh
DRY_RUN=1 ./test-all-profiles.sh  # Preview without building
SKIP_PROFILES="kubernetes storage" ./test-all-profiles.sh  # Skip some
VERBOSE=1 ./test-all-profiles.sh  # Verbose output
```

### Test Phases

| Phase | Description |
|-------|-------------|
| 1: Pre-Build Validation | Tools, disk space, config, profile, scripts |
| 2: ISO Build | Build process, file creation, checksums |
| 3: Content Validation | ISO format, boot loader, kernel, initrd |
| 4: QEMU Boot | Boot capability, kernel load, panic detection |

### Build Profiles

All 7 build profiles are tested:
- minimal - Minimal VirtOS (~100MB)
- standard - Balanced configuration (~200MB) ← Default
- full - Everything included (~400MB)
- containers - Container-focused (~150MB)
- developer - Development tools (~250MB)
- kubernetes - K3s orchestration (~250MB)
- storage - Advanced storage (~350MB)

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

## CI/CD Integration

GitHub Actions workflow (`.github/workflows/iso-build-test.yml`) automatically tests 3 profiles on every push and PR.

**Monitoring**:
1. Go to repository → Actions tab
2. Click on "ISO Build Testing" workflow
3. See test results and download logs

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

Or disable QEMU tests:
```bash
HEADLESS=1 ./test-iso-boot.sh  # Skip if not needed
```

### Boot test times out
Increase timeout or check system resources:
```bash
BOOT_TIMEOUT=300 ./test-iso-boot.sh  # 5 minute timeout
free -h  # Check RAM
nproc    # Check CPUs
```

### ISO File Not Found
1. Ensure previous build completed
2. Check `build/output/` directory exists
3. Verify `genisoimage` and `isohybrid` installed
4. Check disk space: `df build/`

### Build Phase Fails
1. Run `build/scripts/validate-build.sh` first
2. Check `/tmp/virtos-build.log`
3. Ensure 20GB free disk space
4. Verify build dependencies installed

## Test Coverage

| Test | Automation | Status |
|------|-----------|--------|
| Pre-flight checks | ✅ Automated | Ready |
| Build environment validation | ✅ Automated | Ready |
| ISO build (all profiles) | ✅ Automated | Ready |
| ISO integrity validation | ✅ Automated | Ready |
| Boot testing | ✅ Automated | Ready |
| Hardware testing | ⏳ Manual | Needed |

## Summary

VirtOS has comprehensive automated ISO build and boot testing. All scripts are ready to use:

```bash
cd VirtOS/build/scripts
./test-iso-build.sh      # Build and validate ISO
./test-iso-boot.sh       # Test ISO boot in QEMU
./test-all-profiles.sh   # Test all 7 profiles
```

## See Also

- [ISO_TESTING_STATUS.md](../ISO_TESTING_STATUS.md) - Test tracking
- [RUNTIME_TESTING_PLAN.md](../RUNTIME_TESTING_PLAN.md) - Manual testing procedures
- [build/build.conf](../build/build.conf) - Build configuration
- [.github/workflows/iso-build-test.yml](../.github/workflows/iso-build-test.yml) - CI/CD workflow
