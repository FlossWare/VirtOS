# VirtOS Functional Tests

These tests validate actual functionality, not just script structure.

## Overview

**Current Tests**: 4 files, 51 tests
- ✅ **virtos-paths.bats** - Path configuration system (51 tests) - **COMPLETE**
- 🟡 **VM workflow tests** - Planned (see Phase 1-3 below)

## Prerequisites

- libvirt/QEMU installed (`virsh`, `qemu-img` available) - for VM tests
- Root/sudo access (for VM operations) - optional for path tests
- At least 2GB free disk space - for VM tests
- At least 1GB free RAM - for VM tests

## Running Tests

```bash
# Install BATS if not available
sudo dnf install bats -y  # Fedora
# or
sudo apt install bats -y  # Debian/Ubuntu

# Run all functional tests
cd tests/functional
bats *.bats

# Run specific test
bats virtos-paths.bats

# Run with verbose output
bats -t virtos-paths.bats
```

## Current Tests

### virtos-paths.bats (51 tests) ✅

Tests the VirtOS path configuration system (`virtos-paths.conf` + `virtos-common.sh`):

**Path Configuration Loading** (6 tests):
- Configuration file exists and readable
- Configuration loads without errors
- Defines required variables (ETC_DIR, LOG_DIR, VERSION_FILE)
- Idempotent loading (loads only once)

**get_virtos_path() Basic Functionality** (10 tests):
- Error handling (no argument, undefined variable)
- Path retrieval (ETC_DIR, LOG_DIR, VERSION_FILE, SSH_CONFIG, CLUSTER_CONF, STORAGE_POOL_DEFAULT)
- Path matches environment variable

**Writable Path Validation** (3 tests):
- Writable flag succeeds for writable paths
- Writable flag fails for non-writable paths

**Auto-Create Functionality** (4 tests):
- Creates missing directory for file path
- Creates missing directory path
- Succeeds if directory already exists

**Convenience Functions** (6 tests):
- ensure_virtos_path() creates and returns path
- validate_virtos_path_writable() validates writable paths
- Error handling for undefined variables

**Environment Variable Overrides** (1 test):
- Custom VIRTOS_* variables override defaults

**Integration Tests** (2 tests):
- get_version() uses get_virtos_path() internally
- Path system integrates with version management

**Path Categories Coverage** (6 tests):
- Log paths (LOG_MONITOR)
- Cluster paths (CLUSTER_CONF)
- Storage paths (STORAGE_ISO)
- Backup paths (BACKUP_ORCHESTRATED)
- Configuration paths (CONF_ANALYTICS)
- Data directories (DATA_AI_MODELS)

**Usage Example**:
```bash
cd tests/functional
bats virtos-paths.bats
```

## Planned Tests (Phase 1-3)

### Phase 1 (Core Functionality) - TODO

- `01-vm-create.bats` - VM creation and deletion
- `02-vm-lifecycle.bats` - Start, stop, status
- `03-storage-basic.bats` - Storage pool operations
- `04-network-basic.bats` - Network bridge operations

### Phase 2 (Advanced Features) - TODO

- `05-vm-snapshot.bats` - Snapshot creation/revert
- `06-vm-backup.bats` - Backup and restore
- `07-vm-migrate.bats` - Migration (requires 2 hosts)

### Phase 3 (Integration) - TODO

- `08-full-workflow.bats` - End-to-end workflow
- `09-cluster.bats` - Cluster discovery

## Test Environment (for VM tests)

Tests create resources under:

- VMs: `virtos-test-*`
- Storage: `/var/lib/virtos-test/`
- Networks: `virtos-test-*`

All resources are cleaned up after tests (including on failure).

## CI Integration

Current tests run in GitHub Actions:

```yaml
# .github/workflows/ci.yml
- name: Run Functional Tests
  run: |
    cd tests/functional
    bats virtos-paths.bats
```

Future VM tests will require:
- Ubuntu runner with KVM enabled
- Self-hosted runner with libvirt
- See `.github/workflows/functional-tests.yml` (planned)

## Development Status

| Test File | Status | Tests | Description |
|-----------|--------|-------|-------------|
| virtos-paths.bats | ✅ Complete | 51 | Path configuration system |
| 01-vm-create.bats | 🟡 Planned | - | VM creation workflows |
| 02-vm-lifecycle.bats | 🟡 Planned | - | VM start/stop/status |
| 03-storage-basic.bats | 🟡 Planned | - | Storage operations |
| 04-network-basic.bats | 🟡 Planned | - | Network operations |

**Legend**: ✅ Complete | 🟡 Planned | ⚠️ Blocked

---

**Last Updated**: 2026-06-09
**Active Tests**: 51
**Files**: 4 (1 complete, 3 planned)
