# VirtOS ISO Testing Status

**Last Updated**: 2026-05-26  
**Build Status**: ✅ Complete  
**Test Status**: ⏳ Not Started  
**Tests Passed**: 0/47

> **Note**: This document tracks ISO testing progress. See [RUNTIME_TESTING_PLAN.md](RUNTIME_TESTING_PLAN.md) for detailed test procedures.

## Testing Phases

### Phase 1: Build Validation (0/5)

Verify the ISO build process completes successfully:

- [ ] ISO builds successfully (`./build-all.sh` completes without errors)
- [ ] Checksums match (`md5sum -c VirtOS-*.iso.md5.txt` passes)
- [ ] ISO size reasonable (50-200MB range)
- [ ] genisoimage completes without errors  
- [ ] isohybrid creates hybrid MBR/UEFI image

**How to Test**: Run `cd build/scripts && ./build-all.sh`

---

### Phase 2: Boot Testing (0/8)

Verify the ISO boots in various environments:

- [ ] QEMU boot successful (`qemu-system-x86_64 -enable-kvm -m 2048 -cdrom VirtOS-*.iso`)
- [ ] Isolinux boot menu appears
- [ ] Kernel loads without errors
- [ ] Initramfs unpacks successfully
- [ ] Desktop/shell environment loads
- [ ] BIOS boot on real hardware
- [ ] UEFI boot on real hardware
- [ ] USB boot successful (written with `dd` to USB stick)

**How to Test**: See [RUNTIME_TESTING_PLAN.md](RUNTIME_TESTING_PLAN.md) - Boot Testing section

---

### Phase 3: Core Functionality (0/12)

Test basic VirtOS features:

- [ ] virtos-setup wizard runs (`virtos-setup`)
- [ ] virtos-tui interface loads and is navigable
- [ ] Can list VMs (`virsh list --all`)
- [ ] Can create VM (`virtos-create-vm --name test --cpu 2 --ram 2048 --disk 20G`)
- [ ] Can start VM (`virsh start test`)
- [ ] Can connect to VM console (`virsh console test`)
- [ ] Can stop VM (`virsh shutdown test`)
- [ ] Can delete VM (`virsh undefine test`)
- [ ] Network bridge operational (`brctl show`)
- [ ] Storage pools work (`virsh pool-list --all`)
- [ ] Snapshots function (`virtos-snapshot create test snap1`)
- [ ] Backups work (`virtos-backup create test`)

**How to Test**: See [RUNTIME_TESTING_PLAN.md](RUNTIME_TESTING_PLAN.md) - Core Functionality section

---

### Phase 4: Integration (0/7)

Test advanced integrations:

- [ ] SSH remote access works (`ssh tc@<virtos-ip>`)
- [ ] virt-manager connection from remote (`virt-manager -c qemu+ssh://tc@<ip>/system`)
- [ ] Cluster discovery via Avahi (`virtos-cluster discover`)
- [ ] platform-java commands available (`jplatform --version`)
- [ ] platform-java can deploy workload (`platform-java deploy examples/nginx-example.yaml`)
- [ ] Container runtime works (`docker run hello-world` or `podman run hello-world`)
- [ ] Multi-tier app deployment (database → app → web tier)

**How to Test**: See [RUNTIME_TESTING_PLAN.md](RUNTIME_TESTING_PLAN.md) - Integration Testing section

---

### Phase 5: Build Profiles (0/7)

Test each build profile:

- [ ] **minimal** profile builds and boots (core VM management only)
- [ ] **standard** profile builds and boots (VM + containers)
- [ ] **full** profile builds and boots (all features)
- [ ] **containers** profile works (Docker/LXC focus)
- [ ] **developer** profile works (dev tools included)
- [ ] **kubernetes** profile works (K8s runtime)
- [ ] **storage** profile works (advanced storage backends)

**How to Test**:
```bash
# Edit build/build.conf, set PROFILE=minimal
cd build/scripts && ./build-all.sh
# Boot and verify expected packages present/absent
```

---

### Phase 6: Hardware Compatibility (0/8)

Test on real hardware configurations:

- [ ] Intel CPU with VT-x (KVM acceleration works)
- [ ] AMD CPU with AMD-V (KVM acceleration works)
- [ ] NVIDIA GPU passthrough (`virtos-gpu list`)
- [ ] AMD GPU passthrough
- [ ] USB device passthrough (`virtos-usb list`)
- [ ] Multiple NICs (bridging and bonding)
- [ ] UEFI Secure Boot compatible
- [ ] Legacy BIOS boot

**How to Test**: Requires real hardware - see [RUNTIME_TESTING_PLAN.md](RUNTIME_TESTING_PLAN.md) hardware section

---

## Test Results

No testing has been performed yet. When tests are run, results will be documented here.

### Test Environment

Document test hardware/environment when testing begins:
- **CPU**: (to be filled)
- **RAM**: (to be filled)
- **Virtualization**: (to be filled)
- **Boot Mode**: (to be filled)

---

## Reporting Test Results

When you test VirtOS ISO:

1. **Update checkboxes** in this file as you complete tests
2. **Update Tests Passed** counter at the top
3. **Note failures** in Test Results section
4. **File issues** for bugs discovered during testing
5. **Update Test Status** from ⏳ to ⏸️ (in progress) to ✅ (complete)

---

## How to Remove "Untested" Label

VirtOS ISO can be marked as "tested" when:

1. **Phase 1-3 complete** (25/47 tests) - Basic functionality validated
2. **At least 1 profile tested** (1/7 profile tests) - One end-to-end build verified
3. **Real hardware OR QEMU testing** (at least 2/8 boot tests)

**Minimum**: 28/47 tests passed

**Full validation**: All 47 tests passed

---

## See Also

- [RUNTIME_TESTING_PLAN.md](RUNTIME_TESTING_PLAN.md) - Detailed test procedures
- [ISO_BUILD_STATUS.md](ISO_BUILD_STATUS.md) - Build system status
- [INTEGRATION_TEST_REPORT.md](INTEGRATION_TEST_REPORT.md) - Integration test results
- [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Common issues and solutions
