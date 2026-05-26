# VirtOS Integration Tests

End-to-end integration tests for VirtOS workflows.

## Overview

These tests validate complete workflows across VirtOS components:
- VM lifecycle (create, start, stop, delete, snapshot, backup)
- JPlatform workload deployment
- Network configuration
- Storage management
- Cluster operations

## Status

**Current**: Framework in place, tests are placeholders  
**Tests**: 2 suites (VM lifecycle, JPlatform)  
**Coverage**: 0% (all tests currently skipped pending implementation)

## Requirements

### System Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install -y \
    libvirt-daemon-system \
    qemu-kvm \
    bats \
    bridge-utils

# Fedora
sudo dnf install -y \
    libvirt \
    qemu-kvm \
    bats \
    bridge-utils

# Start libvirtd
sudo systemctl start libvirtd
sudo systemctl enable libvirtd
```

### User Permissions

```bash
# Add user to libvirt and kvm groups
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

# Log out and back in for groups to take effect
# Or use: newgrp libvirt
```

### VirtOS Installation

Option 1: From source (development):
```bash
# virtos-* scripts must be in PATH
export PATH="$PWD/config/custom-scripts:$PATH"
```

Option 2: From packages (runtime):
```bash
# On Tiny Core Linux / VirtOS
tce-load -wi virtos-tools
tce-load -wi virtos-jplatform
```

## Running Tests

### Run All Integration Tests

```bash
cd tests/integration
bats *.bats
```

### Run Specific Test Suite

```bash
# VM lifecycle tests only
bats tests/integration/01-vm-lifecycle.bats

# JPlatform tests only
bats tests/integration/02-jplatform.bats
```

### Run With Sudo (if needed)

```bash
# Some tests may require elevated privileges
sudo -E bats tests/integration/*.bats
```

### Verbose Output

```bash
# Show all test output
bats --verbose-run tests/integration/*.bats

# Tap format for CI
bats --formatter tap tests/integration/*.bats
```

## Test Organization

```
tests/integration/
├── README.md              # This file
├── 01-vm-lifecycle.bats   # VM creation, start, stop, snapshot, backup
├── 02-jplatform.bats      # JPlatform workload deployment
├── 03-networking.bats     # Network bridges, VLANs, NAT (TODO)
├── 04-storage.bats        # Storage pools and volumes (TODO)
├── 05-cluster.bats        # Multi-host operations (TODO)
└── fixtures/              # Test data and workload definitions (TODO)
    ├── vm-workload.yaml
    ├── container-workload.yaml
    └── multi-tier-app.yaml
```

## Test Structure

Each integration test:

1. **setup()**: Check dependencies, prepare test environment
2. **@test blocks**: Individual test cases
3. **teardown()**: Cleanup resources (VMs, networks, storage)
4. **skip**: Tests skip if dependencies unavailable

Example:
```bash
@test "VM creation workflow" {
    # Create VM
    run virtos-create-vm test-vm --memory 512 --disk 5G
    [ "$status" -eq 0 ]
    
    # Verify exists
    virsh list --all | grep -q test-vm
}
```

## Current Test Status

### 01-vm-lifecycle.bats

- ✅ virsh availability check
- ✅ libvirtd service check
- ⏸️ VM creation (placeholder)
- ⏸️ VM start/stop (placeholder)
- ⏸️ VM snapshot (placeholder)
- ⏸️ VM backup/restore (placeholder)
- ⏸️ VM migration (placeholder)

### 02-jplatform.bats

- ✅ jplatform command check
- ✅ jplatform --version check
- ✅ jplatform --help check
- ⏸️ Deploy VM workload (placeholder)
- ⏸️ Deploy container workload (placeholder)
- ⏸️ Multi-tier deployment (placeholder)
- ⏸️ Quota management (placeholder)
- ⏸️ Dependency resolution (placeholder)

**Legend**: ✅ Implemented | ⏸️ Placeholder | ❌ Failing

## Implementing Tests

To convert a placeholder test to a real test:

1. **Remove `skip` statement**
2. **Implement actual virtos-* script integration**
3. **Add proper assertions**
4. **Test locally before committing**

Example:
```bash
# Before (placeholder):
@test "VM creation" {
    skip "Requires functional virtos-create-vm"
    # ...
}

# After (implemented):
@test "VM creation" {
    run virtos-create-vm test-vm --memory 512 --disk 5G
    [ "$status" -eq 0 ]
    virsh list --all | grep -q test-vm
}
```

## CI Integration

Add integration tests to CI pipeline:

```yaml
# .github/workflows/integration-tests.yml
name: Integration Tests

on:
  pull_request:
  push:
    branches: [main]

jobs:
  integration:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y libvirt-daemon-system qemu-kvm bats
          sudo systemctl start libvirtd
          sudo usermod -aG libvirt $USER
      
      - name: Run integration tests
        run: |
          cd tests/integration
          sudo -E bats *.bats
```

## Debugging Failed Tests

### Check Libvirt Status

```bash
sudo systemctl status libvirtd
virsh version
virsh list --all
```

### Check Permissions

```bash
groups  # Should include 'libvirt' and 'kvm'
ls -l /dev/kvm  # Should be readable
```

### View Test Logs

```bash
# Run single test with verbose output
bats --verbose-run --tap tests/integration/01-vm-lifecycle.bats

# Check libvirt logs
sudo journalctl -u libvirtd -f
```

### Manual Testing

```bash
# Test virsh directly
virsh list --all

# Test virtos scripts
virtos-setup --help
virtos-create-vm --help
```

## Contributing

When adding new integration tests:

1. **Follow naming convention**: `0X-feature.bats`
2. **Add setup/teardown**: Clean up resources
3. **Use skip for missing deps**: Don't fail if deps unavailable
4. **Document requirements**: In test file header
5. **Test locally first**: Don't commit failing tests
6. **Update this README**: Document new test suite

## See Also

- [RUNTIME_TESTING_PLAN.md](../../RUNTIME_TESTING_PLAN.md) - Manual testing procedures
- [ISO_TESTING_STATUS.md](../../ISO_TESTING_STATUS.md) - ISO validation checklist
- [../virtos-common.bats](../virtos-common.bats) - Unit tests
- [TESTING.md](../../TESTING.md) - Overall testing strategy

## Future Work

- [ ] Implement placeholder tests (remove `skip` statements)
- [ ] Add networking integration tests (03-networking.bats)
- [ ] Add storage integration tests (04-storage.bats)
- [ ] Add cluster integration tests (05-cluster.bats)
- [ ] Create test fixtures (fixtures/ directory)
- [ ] Add CI integration
- [ ] Add performance benchmarks
- [ ] Add stress tests (many VMs, high load)
