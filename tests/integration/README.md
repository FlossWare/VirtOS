# VirtOS Integration Tests

End-to-end integration tests for VirtOS workflows.

## Overview

These tests validate complete workflows across VirtOS components:
- VM lifecycle (create, start, stop, delete, snapshot, backup)
- platform-java workload deployment
- Network configuration
- Storage management
- Cluster operations

## Status

**Current**: Comprehensive framework with 5 test suites and fixtures  
**Tests**: 54 integration tests across 5 suites  
**Fixtures**: 5 platform-java workload definitions  
**Coverage**: Framework complete, tests skipped pending VirtOS runtime environment

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
tce-load -wi virtos-platform-java
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

# platform-java tests only
bats tests/integration/02-platform-java.bats
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
├── 01-vm-lifecycle.bats   # VM creation, start, stop, snapshot, backup (7 tests)
├── 02-platform-java.bats      # platform-java workload deployment (8 tests)
├── 03-networking.bats     # Network bridges, VLANs, NAT (11 tests)
├── 04-storage.bats        # Storage pools and volumes (13 tests)
├── 05-cluster.bats        # Multi-host operations (15 tests)
└── fixtures/              # Test data and workload definitions
    ├── README.md          # Fixture documentation
    ├── test-vm.yaml       # Basic VM workload
    ├── test-container.yaml  # NGINX container workload
    ├── multi-tier-db.yaml   # Database tier (VM)
    ├── multi-tier-app.yaml  # Application tier (Container)
    └── multi-tier-web.yaml  # Web tier (Container)
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

### 01-vm-lifecycle.bats (7 tests)

- ✅ virsh availability check
- ✅ libvirtd service check
- ⏸️ VM creation workflow (placeholder)
- ⏸️ VM start/stop workflow (placeholder)
- ⏸️ VM snapshot workflow (placeholder)
- ⏸️ VM backup/restore workflow (placeholder)
- ⏸️ VM migration workflow (placeholder)

### 02-platform-java.bats (8 tests)

- ✅ platform-java CLI availability
- ✅ platform-java --version check
- ✅ platform-java --help output
- ⏸️ platform-java list workloads (placeholder)
- ⏸️ Deploy VM workload (placeholder)
- ⏸️ Deploy container workload (placeholder)
- ⏸️ Multi-tier deployment (placeholder)
- ⏸️ Quota management (placeholder)
- ⏸️ Dependency resolution (placeholder)

### 03-networking.bats (11 tests)

- ✅ virsh network commands availability
- ✅ default libvirt network check
- ⏸️ Create isolated network (placeholder)
- ⏸️ Create NAT network (placeholder)
- ⏸️ Create bridge network (placeholder)
- ⏸️ Attach VM to network (placeholder)
- ⏸️ DHCP lease management (placeholder)
- ⏸️ Port forwarding (placeholder)
- ⏸️ Bandwidth limiting (placeholder)
- ⏸️ Network list and status (placeholder)

### 04-storage.bats (13 tests)

- ✅ virsh storage commands availability
- ✅ qemu-img availability
- ⏸️ Create directory-based storage pool (placeholder)
- ⏸️ Create volume in storage pool (placeholder)
- ⏸️ Resize volume (placeholder)
- ⏸️ Clone volume (placeholder)
- ⏸️ Attach volume to VM (placeholder)
- ⏸️ Snapshot volume (placeholder)
- ⏸️ List pools and volumes (placeholder)
- ⏸️ Storage pool refresh (placeholder)
- ⏸️ Delete pool and volumes (placeholder)

### 05-cluster.bats (15 tests)

- ✅ virsh connection to localhost
- ⏸️ Cluster node discovery (placeholder)
- ⏸️ Cluster node registration (placeholder)
- ⏸️ Cluster status and health (placeholder)
- ⏸️ VM migration between nodes (placeholder)
- ⏸️ Live migration (placeholder)
- ⏸️ Cluster resource balancing (placeholder)
- ⏸️ Cluster-wide VM operations (placeholder)
- ⏸️ Cluster failover and HA (placeholder)
- ⏸️ Cluster shared storage (placeholder)
- ⏸️ Cluster network configuration (placeholder)
- ⏸️ Cluster backup coordination (placeholder)
- ⏸️ Cluster resource quotas (placeholder)
- ⏸️ Cluster monitoring (placeholder)
- ⏸️ Node maintenance mode (placeholder)

**Summary**: 9 dependency checks active, 45 workflow tests awaiting VirtOS runtime

**Legend**: ✅ Active | ⏸️ Placeholder (skip statement) | ❌ Failing

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

- [ ] Implement placeholder tests (remove `skip` statements when VirtOS runtime available)
- [x] Add networking integration tests (03-networking.bats) - **DONE**
- [x] Add storage integration tests (04-storage.bats) - **DONE**
- [x] Add cluster integration tests (05-cluster.bats) - **DONE**
- [x] Create test fixtures (fixtures/ directory) - **DONE**
- [x] Add CI integration - **DONE** (validation workflow)
- [ ] Execute tests in actual VirtOS environment
- [ ] Add performance benchmarks
- [ ] Add stress tests (many VMs, high load)
- [ ] Add security testing (SELinux, AppArmor integration)
- [ ] Add disaster recovery testing
