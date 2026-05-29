# VirtOS Testing Roadmap

**Last Updated**: 2026-05-29  
**Status**: Planning Phase  
**Critical Blockers**: 3 (All require VirtOS runtime environment)

---

## Executive Summary

VirtOS has comprehensive test infrastructure (581 unit tests + 52 integration tests) but **has never run functional tests** because it requires a VirtOS runtime environment. This document outlines the path from current state to full validation.

**Key Finding**: Test framework is complete and ready. What's missing is **a booted VirtOS system to run tests against**.

---

## Current State

### Test Infrastructure ✅ COMPLETE

| Component | Status | Details |
|-----------|--------|---------|
| **Unit Tests** | ✅ 100% | 54 test files (529 tests) for all scripts |
| **Integration Tests** | ✅ 100% | 5 suites (52 tests) for end-to-end workflows |
| **Test Framework** | ✅ Ready | BATS framework configured and tested |
| **CI Integration** | ✅ Ready | Workflows exist, waiting for runtime |
| **Test Fixtures** | ✅ Ready | YAML workload definitions for platform-java |
| **Test Documentation** | ✅ Complete | RUNTIME_TESTING_PLAN.md, ISO_TESTING_STATUS.md |

**What Works**:
- Structure validation (bash -n, argument parsing)
- Help text validation
- Version flag validation
- Syntax checking
- Code quality checks

**What's Missing**:
- Functional validation (does it actually create a VM?)
- End-to-end workflows (create → start → snapshot → backup → delete)
- Integration validation (platform-java + libvirt + VirtOS)

### The Three Critical Blockers

All three issues require **the same prerequisite**: A running VirtOS system.

#### Issue #103 - False Test Confidence
- **Problem**: 581 tests pass but validate structure not function
- **Blocker**: No VirtOS runtime to test against
- **Impact**: False sense of confidence in code quality
- **Priority**: P0 - Critical

#### Issue #85 - Integration Tests Never Run
- **Problem**: 52 integration tests always skipped
- **Blocker**: Tests require libvirt, QEMU, platform-java running in VirtOS
- **Impact**: No end-to-end workflow validation
- **Priority**: P0 - Critical

#### Issue #86 - ISO Never Booted
- **Problem**: 0/47 ISO validation tests completed
- **Blocker**: ISO has never been booted on real hardware or VM
- **Impact**: Unknown if ISO actually works
- **Priority**: P0 - Critical

---

## The Solution: Three-Phase Testing Plan

### Phase 1: Build and Boot (PREREQUISITE FOR ALL TESTING)

**Goal**: Create a VirtOS runtime environment  
**Duration**: 2-3 hours  
**Blockers**: None (can start immediately)

#### Steps:
1. **Build ISO**
   ```bash
   cd build/scripts
   ./build-all.sh
   ```
   - **Expected Output**: `build/output/VirtOS-0.1-alpha-*.iso`
   - **Success Criteria**: ISO file created, checksums match
   - **Addresses**: Issue #86 (Phase 1: Build Validation)

2. **Boot in QEMU**
   ```bash
   qemu-system-x86_64 \
     -enable-kvm \
     -m 4096 \
     -cdrom build/output/VirtOS-*.iso \
     -boot d \
     -display gtk
   ```
   - **Expected Output**: VirtOS boots to desktop
   - **Success Criteria**: No kernel panics, desktop loads
   - **Addresses**: Issue #86 (Phase 2: Boot Testing)

3. **Install Packages**
   ```bash
   # In VirtOS environment
   tce-load -i virtos-tools.tcz
   tce-load -i virtos-jplatform.tcz
   ```
   - **Expected Output**: Scripts available in `/usr/local/bin/`
   - **Success Criteria**: `virtos-setup --version` works
   - **Addresses**: Issue #86 (Phase 4: Package Management)

**Deliverable**: A running VirtOS system ready for testing

---

### Phase 2: Core Functionality Testing (UNBLOCKS ISSUES #103, #85)

**Goal**: Validate basic VM operations work  
**Duration**: 2-3 hours  
**Prerequisite**: Phase 1 complete

#### Steps:
1. **Setup VirtOS**
   ```bash
   sudo virtos-setup --auto
   ```
   - **Validates**: virtos-setup script
   - **Expected**: libvirt service starts, default network/storage created
   - **Addresses**: Issue #103 (core functionality)

2. **VM Lifecycle Test**
   ```bash
   # Create VM
   virtos-create-vm --name test-vm --cpu 2 --memory 1024 --disk 10G
   
   # Start VM
   virsh start test-vm
   
   # Verify running
   virsh list | grep test-vm
   
   # Stop VM
   virsh destroy test-vm
   
   # Delete VM
   virsh undefine test-vm --remove-all-storage
   ```
   - **Validates**: virtos-create-vm, libvirt integration
   - **Expected**: VM created, started, stopped, deleted successfully
   - **Addresses**: Issue #103 (VM functionality)

3. **Run Integration Tests**
   ```bash
   cd tests/integration
   bats 01-vm-lifecycle.bats
   bats 02-jplatform.bats
   bats 03-networking.bats
   bats 04-storage.bats
   ```
   - **Validates**: End-to-end workflows
   - **Expected**: At least 40/52 tests passing (77% threshold)
   - **Addresses**: Issue #85 (integration test execution)

**Deliverable**: Proof that core VirtOS functionality works

**Success Criteria**:
- [ ] virtos-setup completes without errors
- [ ] Can create, start, stop, delete a VM
- [ ] At least 40/52 integration tests pass
- [ ] No critical bugs found

---

### Phase 3: Comprehensive Validation (FULL RESOLUTION)

**Goal**: Complete all ISO testing and functional validation  
**Duration**: 4-6 hours  
**Prerequisite**: Phase 2 complete

#### Steps:
1. **Complete ISO Testing Checklist**
   - Run all 47 tests in [ISO_TESTING_STATUS.md](ISO_TESTING_STATUS.md)
   - Document results for each test
   - File bugs for any failures
   - **Addresses**: Issue #86 (complete resolution)

2. **Create Functional Tests**
   ```bash
   # Add functional tests to unit test suite
   # Example: tests/functional/virtos-create-vm.bats
   
   @test "virtos-create-vm actually creates a VM" {
     virtos-create-vm --name func-test --cpu 1 --memory 512 --disk 5G
     run virsh list --all
     [[ "$output" =~ "func-test" ]]
     virsh undefine func-test --remove-all-storage
   }
   ```
   - **Validates**: Actual functionality, not just structure
   - **Expected**: 20+ functional tests created
   - **Addresses**: Issue #103 (functional test coverage)

3. **Enable CI Testing**
   ```yaml
   # .github/workflows/functional-tests.yml
   jobs:
     functional-tests:
       runs-on: ubuntu-latest
       steps:
         - name: Build VirtOS ISO
           run: cd build/scripts && ./build-all.sh
         
         - name: Boot VirtOS in QEMU
           run: # Boot and wait for ready state
         
         - name: Run functional tests
           run: cd tests/functional && bats *.bats
   ```
   - **Validates**: CI can run functional tests
   - **Expected**: CI pipeline runs functional tests on every PR
   - **Addresses**: Issue #85 (CI integration)

**Deliverable**: Fully validated VirtOS with automated testing

**Success Criteria**:
- [ ] 40/47 ISO tests passing (85% threshold)
- [ ] 20+ functional tests created and passing
- [ ] 48/52 integration tests passing (92% threshold)
- [ ] CI pipeline runs functional tests automatically
- [ ] All three critical issues resolved

---

## Resource Requirements

### Hardware/VM Requirements

| Resource | Minimum | Recommended | Purpose |
|----------|---------|-------------|---------|
| **CPU** | 2 cores | 4+ cores | Nested virtualization |
| **RAM** | 4GB | 8GB+ | VirtOS + VMs |
| **Disk** | 20GB | 50GB+ | ISO, VMs, test artifacts |
| **Virtualization** | VT-x/AMD-V | Hardware acceleration | KVM support |

### Environment Options

1. **Physical Hardware** (Best for accuracy)
   - Real server or desktop with VT-x/AMD-V
   - Boot from USB stick
   - Full hardware access

2. **Nested Virtualization** (Best for development)
   - QEMU/KVM on Linux host
   - VMware Workstation with nested virt enabled
   - VirtualBox with nested paging

3. **Cloud VM** (Best for CI/CD)
   - AWS EC2 metal instances (m5.metal, c5.metal)
   - Azure Dv3/Ev3 with nested virt
   - GCP N1/N2 with nested virt

### Time Requirements

| Phase | Duration | Parallelizable | Priority |
|-------|----------|----------------|----------|
| **Phase 1** | 2-3 hours | No | P0 |
| **Phase 2** | 2-3 hours | Yes (multiple testers) | P0 |
| **Phase 3** | 4-6 hours | Yes (multiple test suites) | P1 |
| **Total** | 8-12 hours | - | - |

**Parallelization**: With 3 testers, Phases 2-3 can complete in 3-4 hours.

---

## Addressing Each Issue

### Issue #103 - False Test Confidence

**Current State**:
- 581 structural tests passing (100% coverage)
- 0 functional tests

**After Phase 2**:
- 581 structural tests passing
- 6+ functional tests passing (MVP: VM create/start/stop)
- Confidence level: **Low → Medium**

**After Phase 3**:
- 581 structural tests passing
- 20+ functional tests passing
- 48/52 integration tests passing
- Confidence level: **Medium → High**

**Resolution Criteria**:
- [ ] At least 20 functional tests created
- [ ] At least 40/52 integration tests passing
- [ ] One full workflow test (create → start → snapshot → backup → stop → delete)
- [ ] CI runs functional tests automatically

**Status After Completion**: ✅ RESOLVED

---

### Issue #85 - Integration Tests Never Run

**Current State**:
- 52 integration tests exist
- All 52 tests skipped (require VirtOS runtime)
- Status: ⏳ Waiting for runtime

**After Phase 2**:
- 52 integration tests can run
- 30-40/52 tests passing (expected, some may fail)
- Status: 🔧 Running but needs fixes

**After Phase 3**:
- Bugs from Phase 2 fixed
- 48-50/52 tests passing (92-96%)
- Status: ✅ Passing

**Resolution Criteria**:
- [ ] All 52 tests run (not skipped)
- [ ] At least 40/52 tests passing (77% threshold)
- [ ] Failures documented with bug reports
- [ ] CI runs integration tests on every PR

**Status After Completion**: ✅ RESOLVED

---

### Issue #86 - ISO Boot Testing

**Current State**:
- 0/47 ISO tests completed
- ISO never booted
- Status: ⏳ Not started

**After Phase 1**:
- 13/47 tests completed (Build + Boot + Package = 20 tests)
- Status: 🔧 In progress

**After Phase 2**:
- 33/47 tests completed (Core functionality = additional 12 tests)
- Status: 🔧 In progress

**After Phase 3**:
- 40-45/47 tests completed (85-96%)
- Status: ✅ Complete (meets 60% threshold)

**Resolution Criteria**:
- [ ] At least 28/47 tests passing (60% threshold for "tested" label)
- [ ] All Phase 1-3 tests passing (core functionality validated)
- [ ] Boot successful on at least 1 hardware platform (or QEMU)
- [ ] At least 3 VMs running simultaneously

**Status After Completion**: ✅ RESOLVED

---

## Quick Start: Run Phase 1 Now

**No blockers - can start immediately!**

```bash
# 1. Build ISO (10-20 minutes)
cd build/scripts
./build-all.sh

# 2. Verify build
ls -lh ../output/VirtOS-*.iso
md5sum -c ../output/VirtOS-*.iso.md5

# 3. Boot in QEMU (2-3 minutes)
qemu-system-x86_64 \
  -enable-kvm \
  -m 4096 \
  -cdrom ../output/VirtOS-*.iso \
  -boot d \
  -display gtk

# 4. Document results
# Update ISO_TESTING_STATUS.md with checkmarks
# Take screenshots for docs/testing/screenshots/
```

**Time to first booted system**: ~30 minutes

**This single action unblocks all three critical issues.**

---

## Next Steps

### Immediate (This Week)
1. ✅ **Create this roadmap document** (you are here)
2. ⏳ **Run Phase 1** - Build and boot ISO
3. ⏳ **Update ISO_TESTING_STATUS.md** with Phase 1 results
4. ⏳ **File bugs** for any Phase 1 failures

### Short-term (Next 2 Weeks)
5. ⏳ **Run Phase 2** - Core functionality testing
6. ⏳ **Create functional test suite** (20+ tests)
7. ⏳ **Fix critical bugs** found in Phase 2
8. ⏳ **Update issue #103, #85** with progress

### Medium-term (Next 4 Weeks)
9. ⏳ **Run Phase 3** - Comprehensive validation
10. ⏳ **Enable CI functional testing**
11. ⏳ **Complete all 47 ISO tests**
12. ⏳ **Close issues #103, #85, #86**

---

## Success Metrics

### MVP Success (Phase 2 Complete)
- [ ] ISO builds and boots ✅
- [ ] Can create, start, stop, delete VM ✅
- [ ] At least 6 functional tests passing ✅
- [ ] Integration tests run (even if some fail)

**Impact**: Issues #103, #85, #86 move from "blocked" to "in progress"

### Production Success (Phase 3 Complete)
- [ ] 40/47 ISO tests passing (85%)
- [ ] 20+ functional tests passing
- [ ] 48/52 integration tests passing (92%)
- [ ] CI runs functional tests automatically

**Impact**: Issues #103, #85, #86 closed as resolved ✅

---

## Risks and Mitigation

### Risk 1: ISO Doesn't Boot
**Likelihood**: Medium  
**Impact**: High (blocks everything)  
**Mitigation**: 
- Build system tested, syntax valid, packages verified
- If boot fails, debug with `qemu -serial stdio` for kernel logs
- Fallback: Boot Tiny Core Linux base, manually install packages

### Risk 2: Functional Tests Reveal Critical Bugs
**Likelihood**: High  
**Impact**: Medium (expected, good to find early)  
**Mitigation**:
- Bugs found in testing are successes, not failures
- Prioritize bug fixes by severity
- Document workarounds for medium/low priority bugs

### Risk 3: Integration Tests Fail
**Likelihood**: High  
**Impact**: Medium  
**Mitigation**:
- Tests written based on expected behavior, may need adjustment
- 77% passing threshold allows for some failures
- Failures guide improvements, not blockers

### Risk 4: Resource Constraints
**Likelihood**: Medium  
**Impact**: Medium  
**Mitigation**:
- Phase 1 requires minimal resources (2GB RAM, 2 cores)
- Cloud VMs available if local hardware insufficient
- Can parallelize testing across multiple environments

---

## Related Issues

**Critical Blockers** (require VirtOS runtime):
- [Issue #103](https://github.com/FlossWare/VirtOS/issues/103) - False test confidence
- [Issue #85](https://github.com/FlossWare/VirtOS/issues/85) - Integration tests skipped
- [Issue #86](https://github.com/FlossWare/VirtOS/issues/86) - ISO never booted

**Dependent Issues** (blocked by above):
- [Issue #134](https://github.com/FlossWare/VirtOS/issues/134) - Integration tests Phase 1
- [Issue #135](https://github.com/FlossWare/VirtOS/issues/135) - Integration tests in CI
- [Issue #90](https://github.com/FlossWare/VirtOS/issues/90) - Security audit
- [Issue #95](https://github.com/FlossWare/VirtOS/issues/95) - Production readiness

**Total Blocked Issues**: 7

**Unblocking Strategy**: Complete Phase 1 → unblocks 7 issues

---

## See Also

- [ISO_TESTING_STATUS.md](ISO_TESTING_STATUS.md) - Detailed ISO test checklist
- [RUNTIME_TESTING_PLAN.md](RUNTIME_TESTING_PLAN.md) - Comprehensive test procedures
- [INTEGRATION_TEST_REPORT.md](INTEGRATION_TEST_REPORT.md) - Current test status
- [CLAUDE.md](CLAUDE.md) - Development guide
- [tests/integration/README.md](tests/integration/README.md) - Integration test documentation

---

**Document Version**: 1.0  
**Status**: Planning  
**Next Review**: After Phase 1 completion
