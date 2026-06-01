# VirtOS Functional Tests

These tests validate actual functionality, not just script structure.

## Prerequisites

- libvirt/QEMU installed (`virsh`, `qemu-img` available)
- Root/sudo access (for VM operations)
- At least 2GB free disk space
- At least 1GB free RAM

## Running Tests

```bash
# Install BATS if not available
sudo dnf install bats -y  # Fedora
# or
sudo apt install bats -y  # Debian/Ubuntu

# Run functional tests
cd tests/functional
sudo bats *.bats

# Or run specific test
sudo bats 01-vm-create.bats
```

## Test Categories

### Phase 1 (Core Functionality)

- `01-vm-create.bats` - VM creation and deletion
- `02-vm-lifecycle.bats` - Start, stop, status
- `03-storage-basic.bats` - Storage pool operations
- `04-network-basic.bats` - Network bridge operations

### Phase 2 (Advanced Features)

- `05-vm-snapshot.bats` - Snapshot creation/revert
- `06-vm-backup.bats` - Backup and restore
- `07-vm-migrate.bats` - Migration (requires 2 hosts)

### Phase 3 (Integration)

- `08-full-workflow.bats` - End-to-end workflow
- `09-cluster.bats` - Cluster discovery

## Test Environment

Tests create resources under:

- VMs: `virtos-test-*`
- Storage: `/var/lib/virtos-test/`
- Networks: `virtos-test-*`

All resources are cleaned up after tests (including on failure).

## CI Integration

These tests can run in GitHub Actions with nested virtualization:

- Ubuntu runner with KVM enabled
- Self-hosted runner with libvirt

See `.github/workflows/functional-tests.yml` for configuration.
