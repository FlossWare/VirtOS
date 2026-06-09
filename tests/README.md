# VirtOS Test Suite

Comprehensive BATS test framework for VirtOS management scripts and libraries.

## Overview

**Total Test Files**: 64 (50 active + 14 archived)
**Total Tests**: ~1,174 active tests (~1,123 active + ~51 functional)
**Coverage**: 41 active scripts + common libraries

## Test Structure

```
tests/
├── README.md                          # This file
├── functional/                        # Functional/integration tests (4 files, 51 tests)
│   ├── README.md                      # Functional testing guide
│   ├── 01-vm-create.bats             # (Planned - VM creation workflow)
│   ├── 02-vm-lifecycle.bats          # (Planned - VM lifecycle tests)
│   └── virtos-paths.bats             # Path configuration system tests (NEW)
├── integration/                       # Integration workflow tests
│   ├── README.md                      # Integration testing guide
│   ├── fixtures/                      # Test data and workload definitions
│   └── *.bats                         # Integration test suites
├── archive/                           # Archived experimental tests (14 files, 72 tests)
│   └── virtos-*.bats                  # Tests for archived experimental scripts
├── virtos-*.bats                      # Unit tests for active scripts (41 files)
├── virtos-common.bats                 # Common library tests (UPDATED with path tests)
├── security-*.bats                    # Security validation tests (5 files)
└── test_helper.bash                   # Shared test utilities
```

## Script Coverage Status

### Active Scripts (41 scripts tested)

**Core VM Management (10 scripts)**:
- ✅ virtos-setup
- ✅ virtos-create-vm
- ✅ virtos-migrate
- ✅ virtos-snapshot
- ✅ virtos-network
- ✅ virtos-storage
- ✅ virtos-backup
- ✅ virtos-monitor
- ✅ virtos-cluster
- ✅ virtos-tui

**Advanced Features (19 scripts)**:
- ✅ virtos-template
- ✅ virtos-gpu
- ✅ virtos-usb
- ✅ virtos-container-security
- ✅ virtos-ha
- ✅ virtos-dr
- ✅ virtos-api
- ✅ virtos-automation
- ✅ virtos-devops
- ✅ virtos-security
- ✅ virtos-security-advanced
- ✅ virtos-cloud-init
- ✅ virtos-analytics
- ✅ virtos-observability
- ✅ virtos-telemetry
- ✅ virtos-quota
- ✅ virtos-billing
- ✅ virtos-datacenter
- ✅ virtos-web

**Infrastructure (9 scripts)**:
- ✅ virtos-auth
- ✅ virtos-database
- ✅ virtos-directory
- ✅ virtos-secrets
- ✅ virtos-update
- ✅ virtos-backup-orchestration
- ✅ virtos-dr-advanced
- ✅ virtos-networking-advanced
- ✅ virtos-performance

**Libraries (3 files)**:
- ✅ virtos-common.sh (input validation, security, path management)
- ✅ virtos-paths.conf (path configuration)
- ✅ virtos-keyring (credential storage)

### Archived Scripts (14 experimental scripts)

Moved to `tests/archive/` - these test experimental/demo scripts that were archived:
- virtos-ai, virtos-ai-advanced
- virtos-quantum, virtos-quantum-hardware
- virtos-blockchain, virtos-blockchain-advanced
- virtos-federation, virtos-federation-extended
- virtos-multicloud, virtos-edge
- virtos-mesh, virtos-governance
- virtos-sre, virtos-apm

## Test Categories

### Unit Tests (tests/*.bats - 46 files, ~1,123 tests)

Test individual script functionality:
- Script structure validation (exists, executable, shebang)
- Help output (`--help`, `-h`)
- Version output (`--version`, `-v`)
- Argument parsing
- Input validation
- Error handling
- Security (injection prevention, path traversal)

**Example**: `virtos-create-vm.bats` tests VM name validation, disk size parsing, help output.

### Functional Tests (tests/functional/*.bats - 4 files, 51 tests)

Test actual functionality with real backends (libvirt, QEMU):
- **virtos-paths.bats** (NEW): Path configuration system
  - Path loading and retrieval
  - Writable path validation
  - Auto-directory creation
  - Environment variable overrides
  - Integration with get_version()

**Planned**:
- VM lifecycle (create, start, stop, delete)
- Storage operations (pool creation, volume allocation)
- Network operations (bridge setup, NAT configuration)
- Snapshot and backup workflows

### Integration Tests (tests/integration/*.bats)

End-to-end workflow testing:
- Multi-tier application deployment
- platform-java workload orchestration
- Cluster coordination
- Disaster recovery scenarios

### Security Tests (tests/security-*.bats - 5 files)

Security validation tests:
- Command injection prevention
- Path traversal protection
- Credential storage security
- Temporary file handling
- Error code validation

## Running Tests

### Prerequisites

```bash
# Install BATS
sudo dnf install bats -y  # Fedora
# or
sudo apt install bats -y  # Debian/Ubuntu
```

### Run All Active Tests

```bash
cd tests
bats *.bats functional/*.bats
```

### Run Specific Test Suite

```bash
# Test common library
bats virtos-common.bats

# Test path configuration system
bats functional/virtos-paths.bats

# Test specific script
bats virtos-create-vm.bats

# Test security
bats security-*.bats
```

### Run With Verbose Output

```bash
bats -t virtos-common.bats
```

### Run Functional Tests (Requires Root/Sudo)

```bash
cd functional
sudo bats *.bats
```

## Test Results Summary

### Current Status (2026-06-09)

| Category | Files | Tests | Status |
|----------|-------|-------|--------|
| **Active Scripts** | 41 | ~980 | ✅ Pass (syntax/structure) |
| **Common Library** | 1 | ~143 | ✅ Pass (updated with paths) |
| **Functional** | 4 | ~51 | ✅ Pass (virtos-paths), 🟡 Planned (workflows) |
| **Security** | 5 | ~95 | ✅ Pass |
| **Integration** | 5 | ~54 | ⚠️ Awaiting VirtOS runtime |
| **Archived** | 14 | ~72 | ⚠️ Archived (experimental) |

**Total Active**: 50 files, ~1,174 tests

### Recent Updates (2026-06-09)

1. ✅ **Created tests/functional/virtos-paths.bats** (51 tests)
   - Tests new path configuration system (virtos-paths.conf)
   - Tests get_virtos_path(), ensure_virtos_path(), validate_virtos_path_writable()
   - Tests path loading, retrieval, validation, auto-creation
   - Tests environment variable overrides

2. ✅ **Updated tests/virtos-common.bats** (added 8 path management tests)
   - Tests get_virtos_path() integration
   - Tests ensure_virtos_path() functionality
   - Tests validate_virtos_path_writable()
   - Tests get_version() integration with path system

3. ✅ **Documented test suite reorganization**
   - 41 active scripts (was 55 before archival)
   - 14 experimental scripts archived
   - ~1,000+ active tests (down from ~1,200 after archival)

## Test Philosophy

### Coverage Levels

1. **Syntax Validation** (100% coverage)
   - All scripts pass `bash -n` syntax check
   - All scripts have executable permissions
   - All scripts have correct shebang

2. **Structural Tests** (100% coverage)
   - All scripts respond to `--help`
   - All scripts respond to `--version`
   - All scripts have consistent argument parsing

3. **Functional Tests** (Growing coverage)
   - Core VM management: High coverage (libvirt integration tested)
   - Path system: Full coverage (NEW)
   - Advanced features: Medium coverage (workflow tests planned)
   - Infrastructure: Medium coverage (backend integration pending)

4. **Security Tests** (High priority)
   - Input validation for all user inputs
   - Command injection prevention
   - Path traversal protection
   - Credential security

### Test Development Guidelines

1. **Always Test Failure Paths**
   - Invalid input handling
   - Missing dependencies
   - Permission errors

2. **Use Mocking Sparingly**
   - Prefer real backends when possible
   - Mock only external services (cloud APIs, etc.)

3. **Clean Up After Tests**
   - Remove test VMs, networks, storage pools
   - Use `teardown()` function consistently

4. **Test Independence**
   - Each test should be independent
   - No shared state between tests
   - Order shouldn't matter

## CI/CD Integration

Tests run automatically in GitHub Actions:

```yaml
# .github/workflows/ci.yml
- name: Run BATS Tests
  run: |
    cd tests
    bats *.bats functional/virtos-paths.bats
```

Future integration:
- Functional tests in nested KVM environment
- Integration tests with platform-java
- Performance benchmarking

## Known Limitations

1. **Functional Tests Require Environment**
   - Need libvirt/QEMU installed
   - Need root/sudo access
   - Not suitable for all CI environments

2. **Integration Tests Await VirtOS Runtime**
   - platform-java integration tests need VirtOS ISO
   - Cluster tests need multi-node environment
   - See [RUNTIME_TESTING_PLAN.md](/docs/testing/RUNTIME_TESTING_PLAN.md)

3. **Archived Tests Not Maintained**
   - Experimental script tests in `archive/` directory
   - Not run in CI/CD
   - Preserved for historical reference

## Adding New Tests

### For New Scripts

1. Create `tests/virtos-<name>.bats`:

```bash
#!/usr/bin/env bats
# Tests for virtos-<name>

setup() {
    SCRIPT_PATH="${BATS_TEST_DIRNAME}/../config/custom-scripts/virtos-<name>"
    [ -f "$SCRIPT_PATH" ] || skip "Script not found"
}

@test "virtos-<name>: script exists and is executable" {
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-<name>: shows help with --help" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-<name>: shows version with --version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}
```

2. Add functional tests to `tests/functional/`:

```bash
@test "virtos-<name>: performs operation successfully" {
    # Actual functionality test
    run virtos-<name> create test-resource
    [ "$status" -eq 0 ]
}

teardown() {
    # Clean up test resources
    virtos-<name> delete test-resource 2>/dev/null || true
}
```

### For New Libraries

1. Add tests to appropriate suite (e.g., `virtos-common.bats`)
2. Test all public functions
3. Test error handling
4. Test edge cases

## Troubleshooting

### Tests Fail with "Script not found"

Check that scripts exist:
```bash
ls -la config/custom-scripts/virtos-*
```

### Tests Fail with Permission Denied

Make scripts executable:
```bash
chmod +x config/custom-scripts/virtos-*
```

### Functional Tests Fail

Verify dependencies:
```bash
which virsh qemu-img
```

### BATS Not Found

Install BATS:
```bash
# Fedora
sudo dnf install bats

# Debian/Ubuntu  
sudo apt install bats

# From source
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

## Contributing

### Test Contribution Checklist

- [ ] New test file follows naming convention (`virtos-*.bats`)
- [ ] Tests are independent (no shared state)
- [ ] Tests clean up after themselves (`teardown()`)
- [ ] Tests have clear descriptions
- [ ] Tests cover both success and failure paths
- [ ] Tests validate security (injection, traversal)
- [ ] Tests documented in this README

## References

- [BATS Documentation](https://bats-core.readthedocs.io/)
- [VirtOS Testing Roadmap](/docs/testing/TESTING_ROADMAP.md)
- [Runtime Testing Plan](/docs/testing/RUNTIME_TESTING_PLAN.md)
- [Integration Test Report](/INTEGRATION_TEST_REPORT.md)

---

**Last Updated**: 2026-06-09
**Test Files**: 64 (50 active + 14 archived)
**Active Tests**: ~1,174
**Coverage**: 41/41 active scripts (100%)
