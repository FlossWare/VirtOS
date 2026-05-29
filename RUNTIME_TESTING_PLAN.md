# VirtOS Runtime Testing Plan

**Last Updated**: 2026-05-25  
**Status**: Ready for Execution  
**Priority**: CRITICAL (Issue #1)

---

## Executive Summary

This document provides a comprehensive testing plan for validating VirtOS and platform-java integration in a real runtime environment. All code is built and tested syntactically, but **end-to-end runtime validation has not been performed**.

**Goal**: Boot VirtOS, install packages, verify core VM management works, and confirm platform-java integration operates correctly.

---

## Prerequisites

### Hardware/VM Requirements

| Component | Minimum | Recommended | Purpose |
|-----------|---------|-------------|---------|
| **CPU** | 2 cores | 4+ cores with VT-x/AMD-V | For nested virtualization |
| **RAM** | 4GB | 8GB+ | For VirtOS + VMs + containers |
| **Disk** | 20GB | 50GB+ | For VirtOS, VM images, containers |
| **Network** | 1 NIC | 2 NICs | For bridged networking tests |

**Virtualization Support**: CPU must support hardware virtualization (Intel VT-x or AMD-V) and be enabled in BIOS.

### Test Environment Options

**Option 1: Physical Hardware** (Best for production validation)

- Real server or desktop with virtualization support
- Direct hardware access for GPU, USB passthrough tests
- Realistic performance characteristics

**Option 2: Nested Virtualization** (Best for development)

```bash
# On QEMU/KVM host
qemu-system-x86_64 \
  -enable-kvm \
  -cpu host \
  -m 8192 \
  -cdrom VirtOS-0.1-alpha-*.iso \
  -boot d \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22
```

**Option 3: Cloud VM** (Best for CI/CD)

- AWS EC2 metal instances (m5.metal, c5.metal)
- Azure Dv3/Ev3 with nested virt enabled
- GCP N1/N2 with nested virt enabled

---

## Phase 1: ISO Build and Boot (2-3 hours)

### 1.1 Build VirtOS ISO

**Prerequisites**:

```bash
# Install build tools (Fedora)
sudo dnf install genisoimage syslinux

# Or Debian/Ubuntu
sudo apt install genisoimage syslinux-utils
```

**Build Process**:

```bash
cd /path/to/VirtOS/build/scripts

# Quick validation (< 1 minute)
./quick-test.sh

# Full build (10-20 minutes)
./build-all.sh

# Verify output
ls -lh ../output/VirtOS-*.iso
md5sum -c ../output/VirtOS-*.iso.md5
```

**Expected Output**:

```
build/output/VirtOS-0.1-alpha-20260525.iso
build/output/VirtOS-0.1-alpha-20260525.iso.md5
build/output/VirtOS-0.1-alpha-20260525.iso.sha256

Size: 50-150MB (varies by profile)
```

**Success Criteria**:

- [ ] ISO file created
- [ ] MD5 checksum matches
- [ ] SHA256 checksum matches
- [ ] ISO size is reasonable (50-200MB)

### 1.2 Boot VirtOS in QEMU

**Test Command**:

```bash
qemu-system-x86_64 \
  -enable-kvm \
  -m 2048 \
  -cdrom build/output/VirtOS-0.1-alpha-*.iso \
  -boot d \
  -display gtk
```

**Boot Checklist**:

- [ ] BIOS/bootloader appears (isolinux menu)
- [ ] Kernel loads without errors
- [ ] Initramfs unpacks successfully
- [ ] Tiny Core desktop appears
- [ ] No kernel panics or fatal errors

**Screenshot Locations**: Save screenshots to `docs/testing/screenshots/`

### 1.3 Boot VirtOS on Real Hardware

**Write to USB**:

```bash
# DANGER: Verify device name! Wrong device = data loss!
lsblk  # Identify USB device (e.g., /dev/sdb)

sudo dd \
  if=build/output/VirtOS-*.iso \
  of=/dev/sdX \
  bs=4M \
  status=progress
sync
```

**Boot Process**:

1. Insert USB into target machine
2. Boot from USB (F12/F11/Del to access boot menu)
3. Select USB device
4. Wait for VirtOS to boot

**Hardware Boot Checklist**:

- [ ] BIOS boot successful
- [ ] UEFI boot successful (if applicable)
- [ ] All NICs detected
- [ ] Storage devices detected
- [ ] Desktop loads

---

## Phase 2: Package Installation (30 minutes)

### 2.1 Install VirtOS Tools Package

**From Tiny Core Desktop**:

```bash
# Mount TCZ repository (if not auto-mounted)
sudo mkdir -p /mnt/tcz
sudo mount -o loop /path/to/virtos-tools.tcz /mnt/tcz

# Or install from local file
tce-load -i /path/to/virtos-tools.tcz

# Or from packagecloud.io repository
# First, add VirtOS repository to Tiny Core mirror list
echo "https://packagecloud.io/flossware/virtos/packages/tiny_core_linux/15/x86_64/" >> /opt/tcemirror

# Then install with tce-load
tce-load -wi virtos-tools
tce-load -wi virtos-platform-java
```

**Manual Installation** (for testing):

```bash
# Copy package to /tmp
cp packages/output/virtos-tools.tcz /tmp/

# Install package
cd /tmp
unsquashfs -d virtos-tools virtos-tools.tcz
sudo cp -r virtos-tools/usr /usr/

# Verify installation
which virtos-tui
virtos-setup --version
```

**Installation Checklist**:

- [ ] Package installs without errors
- [ ] All 53 scripts appear in `/usr/local/bin/`
- [ ] Scripts are executable (`-rwxr-xr-x`)
- [ ] Help text works (`virtos-setup --help`)
- [ ] Version info works (`virtos-setup --version`)

### 2.2 Install platform-java Package

```bash
# Install virtos-platform-java package
tce-load -i /path/to/virtos-platform-java.tcz

# Or manual installation
cd /tmp
unsquashfs -d virtos-platform-java virtos-platform-java.tcz
sudo cp -r virtos-platform-java/usr /usr/

# Verify platform-java installation
which platform-java
platform-java --version
```

**platform-java Checklist**:

- [ ] Package installs without errors
- [ ] `platform-java` command available
- [ ] platform-java jar exists (`/opt/platform-java/platform-java.jar`)
- [ ] Dependencies present (Java runtime)

---

## Phase 3: Core VM Management (2-3 hours)

### 3.1 Setup VirtOS Environment

**Run Initial Setup**:

```bash
# Interactive setup wizard
sudo virtos-setup

# Or non-interactive
sudo virtos-setup \
  --auto \
  --network bridge \
  --storage /var/lib/virtos/storage
```

**Setup Checklist**:

- [ ] libvirt service starts
- [ ] KVM kernel module loads (`lsmod | grep kvm`)
- [ ] Default network created (`virsh net-list`)
- [ ] Default storage pool created (`virsh pool-list`)
- [ ] Wizard completes without errors

**Validation**:

```bash
# Check libvirt
virsh version
virsh list --all

# Check QEMU
qemu-system-x86_64 --version

# Check storage
virsh pool-info default
```

### 3.2 Create First VM

**Test VM Creation**:

```bash
# Create minimal test VM
virtos-create-vm \
  --name test-vm-01 \
  --cpu 2 \
  --memory 1024 \
  --disk 10G \
  --network default \
  --no-start

# Verify VM created
virsh list --all | grep test-vm-01
virsh dumpxml test-vm-01
```

**VM Creation Checklist**:

- [ ] Disk image created (`/var/lib/virtos/storage/test-vm-01.qcow2`)
- [ ] VM defined in libvirt (`virsh list --all`)
- [ ] XML configuration valid (`virsh dumpxml`)
- [ ] Disk size correct (`qemu-img info /var/lib/virtos/storage/test-vm-01.qcow2`)

### 3.3 VM Lifecycle Operations

**Start/Stop Test**:

```bash
# Start VM
virsh start test-vm-01
sleep 5

# Check status (should be "running")
virsh list | grep test-vm-01

# Check console output
virsh console test-vm-01  # Press Ctrl-] to exit

# Stop VM
virsh shutdown test-vm-01
sleep 5

# Force stop if needed
virsh destroy test-vm-01

# Verify stopped
virsh list --all | grep test-vm-01
```

**Lifecycle Checklist**:

- [ ] VM starts successfully
- [ ] Status shows "running"
- [ ] Console accessible (even if no OS installed)
- [ ] Graceful shutdown works
- [ ] Force shutdown works
- [ ] Status shows "shut off"

### 3.4 Snapshot Management

**Snapshot Test**:

```bash
# Create snapshot
virtos-snapshot create test-vm-01 snap1 "Initial state"

# List snapshots
virtos-snapshot list test-vm-01

# Snapshot info
virsh snapshot-info test-vm-01 snap1

# Delete snapshot
virtos-snapshot delete test-vm-01 snap1
```

**Snapshot Checklist**:

- [ ] Snapshot creates successfully
- [ ] Snapshot appears in list
- [ ] Snapshot metadata correct
- [ ] Deletion works

### 3.5 Network Management

**Network Test**:

```bash
# List networks
virtos-network list

# Create custom bridge
virtos-network create \
  --name test-bridge \
  --type bridge \
  --subnet 192.168.100.0/24

# Start network
virtos-network start test-bridge

# Verify bridge exists
ip link show | grep test-bridge
brctl show test-bridge

# Delete network
virtos-network delete test-bridge
```

**Network Checklist**:

- [ ] Default network exists and is active
- [ ] Custom bridge creates successfully
- [ ] Bridge interface appears in `ip link`
- [ ] Subnet configuration correct
- [ ] Network deletion works

### 3.6 Storage Management

**Storage Test**:

```bash
# List storage pools
virtos-storage list-pools

# Create directory pool
virtos-storage create-pool \
  --name test-pool \
  --type dir \
  --path /var/lib/virtos/test-pool

# Create volume
virtos-storage create-volume \
  --pool test-pool \
  --name test-disk.qcow2 \
  --size 5G \
  --format qcow2

# List volumes
virtos-storage list-volumes test-pool

# Delete volume and pool
virtos-storage delete-volume test-pool test-disk.qcow2
virtos-storage delete-pool test-pool
```

**Storage Checklist**:

- [ ] Default pool exists
- [ ] Custom pool creates successfully
- [ ] Volume creates successfully
- [ ] Volume size correct
- [ ] Deletion works (volume then pool)

### 3.7 Backup and Restore

**Backup Test**:

```bash
# Create VM for backup
virtos-create-vm --name backup-test --cpu 1 --memory 512 --disk 5G

# Create backup
virtos-backup backup backup-test /tmp/backup-test.xml

# Delete VM
virsh undefine backup-test --remove-all-storage

# Restore from backup
virtos-backup restore /tmp/backup-test.xml

# Verify restored
virsh list --all | grep backup-test
```

**Backup Checklist**:

- [ ] Backup creates successfully
- [ ] Backup file contains XML definition
- [ ] VM deletion works
- [ ] Restore recreates VM
- [ ] Restored VM matches original

---

## Phase 4: platform-java Integration (2-3 hours)

### 4.1 platform-java Basic Operations

**Install Example Workloads**:

```bash
# Verify platform-java responds
platform-java version
platform-java list

# Create simple workload definitions
mkdir -p /tmp/platform-java-test
cd /tmp/platform-java-test
```

**Test VM Workload**:

```yaml
# test-vm.yaml
applicationId: test-vm-platform-java
name: Test VM via platform-java
type: vm
properties:
  vm.vcpu: "2"
  vm.memory: "1024"
  vm.disk: /var/lib/platform-java/vms/test-vm.qcow2
  vm.network: default
dependencies: []
```

```bash
# Deploy VM via platform-java
platform-java deploy test-vm.yaml

# Start VM
platform-java start test-vm-platform-java

# Check status
platform-java status test-vm-platform-java

# Stop and undeploy
platform-java stop test-vm-platform-java
platform-java undeploy test-vm-platform-java
```

**platform-java VM Checklist**:

- [ ] Workload definition valid
- [ ] Deploy creates VM in libvirt
- [ ] Start works
- [ ] Status shows correct state
- [ ] Stop works
- [ ] Undeploy removes VM

### 4.2 Multi-Tier Application

**Deploy Three-Tier Example**:

```bash
# Get platform-java examples
git clone https://github.com/FlossWare/platform-java.git /tmp/platform-java
cd /tmp/platform-java/examples/multi-tier/three-tier-webapp

# Deploy database tier (VM)
platform-java deploy 1-database-tier.yaml
platform-java start postgres-db

# Wait for DB to start
sleep 10

# Deploy application tier (Java)
platform-java deploy 2-app-tier.yaml
platform-java start spring-app

# Wait for app to start
sleep 10

# Deploy web tier (container)
platform-java deploy 3-web-tier.yaml
platform-java start nginx-web

# Check all running
platform-java status
```

**Multi-Tier Checklist**:

- [ ] Database VM deploys and starts
- [ ] Application tier starts (waits for DB)
- [ ] Web tier starts (waits for app)
- [ ] Dependency resolution works
- [ ] All three tiers show as "running"

**Dependency Validation**:

```bash
# Stop app tier (should stop web tier too)
platform-java stop spring-app

# Verify web tier stopped
platform-java status nginx-web | grep "Stopped"

# Start app tier (should start web tier too)
platform-java start spring-app

# Verify cascading start
platform-java status | grep Running
```

**Cleanup**:

```bash
platform-java stop nginx-web
platform-java stop spring-app
platform-java stop postgres-db

platform-java undeploy nginx-web
platform-java undeploy spring-app
platform-java undeploy postgres-db
```

### 4.3 Resource Quotas

**Quota Test**:

```bash
# Set quota for user
platform-java quota set test-user \
  --cpu 4 \
  --memory 4096 \
  --disk 50G

# Verify quota
platform-java quota show test-user

# Deploy VM within quota (should succeed)
platform-java deploy test-vm.yaml --user test-user
platform-java start test-vm-platform-java

# Try to exceed quota (should fail)
cat > large-vm.yaml <<EOF
applicationId: large-vm
name: Large VM
type: vm
properties:
  vm.vcpu: "8"
  vm.memory: "8192"
  vm.disk: /var/lib/platform-java/vms/large.qcow2
dependencies: []
EOF

platform-java deploy large-vm.yaml --user test-user  # Should fail
```

**Quota Checklist**:

- [ ] Quota set successfully
- [ ] Quota displayed correctly
- [ ] VM within quota deploys
- [ ] VM exceeding quota rejected

---

## Phase 5: Advanced Features (4-6 hours)

### 5.1 Live Migration

**Prerequisites**: Requires 2 VirtOS hosts with shared storage

**Migration Test** (single-host simulation):

```bash
# Create VM on host1
virtos-create-vm --name migrate-test --cpu 2 --memory 1024 --disk 10G
virsh start migrate-test

# Simulate migration to host2
virtos-migrate \
  --vm migrate-test \
  --dest qemu+ssh://host2/system \
  --live \
  --persistent

# Verify migration
ssh host2 "virsh list | grep migrate-test"
```

**Migration Checklist**:

- [ ] Shared storage configured
- [ ] SSH key auth works between hosts
- [ ] Live migration completes
- [ ] VM continues running on destination
- [ ] Minimal downtime (< 1 second)

### 5.2 Clustering

**Cluster Test**:

```bash
# Enable Avahi on all hosts
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon

# Discover cluster nodes
virtos-cluster discover

# Join cluster
virtos-cluster join virtos-cluster

# List cluster members
virtos-cluster list

# Verify cluster status
virtos-cluster status
```

**Cluster Checklist**:

- [ ] Avahi service running
- [ ] Nodes discovered via mDNS
- [ ] Cluster formation works
- [ ] All nodes visible in list
- [ ] Status shows healthy

### 5.3 Monitoring and Metrics

**Monitor Test**:

```bash
# Get VM statistics
virtos-monitor stats test-vm-01

# Get system metrics
virtos-monitor system

# Continuous monitoring (10 sec updates)
virtos-monitor watch test-vm-01 --interval 10
```

**Monitoring Checklist**:

- [ ] VM stats display (CPU, memory, disk, network)
- [ ] System metrics display
- [ ] Watch mode updates correctly
- [ ] Metrics are accurate

### 5.4 virtos-tui Integration

**TUI Test**:

```bash
# Launch TUI
sudo virtos-tui

# Navigate menus:
# 1. VM Management → List VMs
# 2. VM Management → Create VM
# 3. Network Management → List Networks
# 17. platform-java Management → List Workloads
```

**TUI Checklist**:

- [ ] TUI launches without errors
- [ ] All menus accessible
- [ ] VM operations work from TUI
- [ ] platform-java menu functional
- [ ] Navigation intuitive

---

## Phase 6: Security Validation (2-3 hours)

### 6.1 Input Validation

**Command Injection Test**:

```bash
# These should ALL fail safely (not execute commands)
virtos-create-vm --name "vm;rm -rf /" --cpu 2 --memory 1024 --disk 10G
virtos-create-vm --name 'vm$(whoami)' --cpu 2 --memory 1024 --disk 10G
virtos-network create --name "bridge|whoami" --type bridge

# Expected: "Invalid name" error, NOT command execution
```

**Security Checklist**:

- [ ] Command injection attempts fail
- [ ] Path traversal blocked (`../../etc/passwd`)
- [ ] Invalid characters rejected (`;`, `|`, `&`, `$()`, etc.)
- [ ] Error messages don't reveal system info

### 6.2 Permission Checks

**Privilege Escalation Test**:

```bash
# As non-root user (should fail for VM operations)
virtos-create-vm --name test --cpu 1 --memory 512 --disk 5G
# Expected: Permission denied

# As root (should succeed)
sudo virtos-create-vm --name test --cpu 1 --memory 512 --disk 5G
# Expected: Success
```

**Permission Checklist**:

- [ ] Non-root users blocked from VM operations
- [ ] Sudo required for privileged operations
- [ ] File permissions correct (`/var/lib/virtos` owned by root)

---

## Phase 7: Performance Testing (2-4 hours)

### 7.1 VM Performance

**CPU Benchmark** (in guest VM):

```bash
# Install stress-ng in guest
apt install stress-ng  # Ubuntu guest

# CPU stress test
stress-ng --cpu 2 --timeout 60s --metrics

# Monitor from host
virtos-monitor stats test-vm-01
```

**Performance Metrics**:

- [ ] Guest CPU usage matches allocation
- [ ] No CPU contention on host
- [ ] Reasonable performance (> 50% of bare metal)

### 7.2 Storage Performance

**Disk I/O Test** (in guest):

```bash
# Sequential write
dd if=/dev/zero of=/tmp/test bs=1M count=1024 oflag=direct

# Sequential read
dd if=/tmp/test of=/dev/null bs=1M iflag=direct

# Random I/O (fio)
fio --name=randrw --rw=randrw --bs=4k --size=1G --numjobs=4
```

**Storage Metrics**:

- [ ] Write speed > 100 MB/s (virtio)
- [ ] Read speed > 200 MB/s
- [ ] IOPS reasonable for workload

### 7.3 Network Performance

**Network Throughput Test**:

```bash
# On host
iperf3 -s

# In guest
iperf3 -c <host-ip> -t 30
```

**Network Metrics**:

- [ ] Throughput > 1 Gbps (virtio-net)
- [ ] Latency < 1ms (host to guest)
- [ ] No packet loss

---

## Phase 8: Stress Testing (2-4 hours)

### 8.1 Multiple VMs

**Create 10 VMs**:

```bash
for i in {1..10}; do
  virtos-create-vm \
    --name stress-vm-$i \
    --cpu 1 \
    --memory 512 \
    --disk 5G \
    --network default &
done
wait

# Start all VMs
for i in {1..10}; do
  virsh start stress-vm-$i
done

# Monitor host resources
htop
```

**Stress Checklist**:

- [ ] All 10 VMs create successfully
- [ ] All start without errors
- [ ] Host system stable
- [ ] Memory usage acceptable

### 8.2 Rapid Creation/Deletion

**Churn Test**:

```bash
for i in {1..50}; do
  echo "Iteration $i/50"
  virtos-create-vm --name churn-test --cpu 1 --memory 512 --disk 5G
  virsh start churn-test
  sleep 5
  virsh destroy churn-test
  virsh undefine churn-test --remove-all-storage
done
```

**Churn Checklist**:

- [ ] All 50 iterations complete
- [ ] No resource leaks (check `df -h`, `free -h`)
- [ ] No orphaned processes
- [ ] libvirt stable

---

## Phase 9: Error Handling (1-2 hours)

### 9.1 Graceful Failures

**Network Failure Test**:

```bash
# Disconnect network during migration
virtos-migrate --vm test --dest qemu+ssh://unreachable-host/system
# Expected: Timeout error, VM stays on source host
```

**Disk Full Test**:

```bash
# Fill disk to 99%
dd if=/dev/zero of=/var/lib/virtos/fill bs=1M

# Try to create VM (should fail gracefully)
virtos-create-vm --name disk-full-test --cpu 1 --memory 512 --disk 50G
# Expected: "Insufficient disk space" error

# Cleanup
rm /var/lib/virtos/fill
```

**Error Handling Checklist**:

- [ ] Network failures handled gracefully
- [ ] Disk full errors clear and actionable
- [ ] Missing dependencies reported
- [ ] Invalid configurations rejected with helpful messages

### 9.2 Recovery from Crashes

**Process Crash Test**:

```bash
# Start VM
virsh start test-vm-01

# Kill libvirt (simulate crash)
sudo killall -9 libvirtd

# Restart libvirt
sudo systemctl restart libvirtd

# Verify VM still defined
virsh list --all | grep test-vm-01
```

**Recovery Checklist**:

- [ ] VMs survive libvirt restart
- [ ] Running VMs reconnect
- [ ] No data corruption

---

## Test Environment Matrix

| Test | Physical HW | Nested Virt | Cloud VM | Priority |
|------|-------------|-------------|----------|----------|
| ISO Build | ✓ | ✓ | ✓ | P0 |
| ISO Boot | ✓ | ✓ | ✓ | P0 |
| Package Install | ✓ | ✓ | ✓ | P0 |
| VM Lifecycle | ✓ | ✓ | ✓ | P0 |
| platform-java Basic | ✓ | ✓ | ✓ | P0 |
| Multi-Tier App | ✓ | ✓ | ✓ | P1 |
| Live Migration | ✓ | ~ | ✓ | P1 |
| Clustering | ✓ | - | ✓ | P2 |
| GPU Passthrough | ✓ | - | - | P2 |
| USB Passthrough | ✓ | - | - | P3 |

**Legend**: ✓ Supported | ~ Limited | - Not Supported

---

## Success Criteria

### Minimum Viable Product (MVP)

**Must Work**:

- [ ] ISO builds and boots
- [ ] Packages install
- [ ] VirtOS setup completes
- [ ] Create, start, stop, delete VM
- [ ] Basic networking (default bridge)
- [ ] platform-java deploys simple workload

**If these 6 items work**: VirtOS is MVP-ready.

### Production Ready

**Additional Requirements**:

- [ ] Snapshots work
- [ ] Backups work
- [ ] Storage pools work
- [ ] Multi-tier platform-java app works
- [ ] Dependency resolution works
- [ ] Security validation passes
- [ ] No critical bugs found in stress testing

### Enterprise Ready

**Additional Requirements**:

- [ ] Live migration works
- [ ] Clustering works
- [ ] HA/DR works
- [ ] Performance acceptable
- [ ] Full documentation
- [ ] Support processes in place

---

## Reporting Results

### Test Report Template

```markdown
# VirtOS Runtime Test Report

**Date**: YYYY-MM-DD  
**Tester**: Name  
**Environment**: Physical/Nested/Cloud  
**Version**: 0.X

## Phase 1: ISO Build and Boot
- [x] ISO builds successfully
- [x] ISO boots in QEMU
- [x] ISO boots on hardware

**Notes**: No issues found

## Phase 2: Package Installation
- [x] virtos-tools installs
- [x] virtos-platform-java installs
- [x] All scripts executable

**Notes**: Package installation smooth

## Phase 3: Core VM Management
- [x] Setup completes
- [x] VM creation works
- [x] VM lifecycle works
- [ ] Snapshots work - **FAILED: snapshot-create-xml error**
- [x] Network management works
- [x] Storage management works

**Issues Found**:
1. Snapshot creation fails with error: "unsupported configuration"
   - Reproduction: virtos-snapshot create test snap1
   - Expected: Snapshot created
   - Actual: Error message about unsupported disk format
   - Fix: Need to use qcow2 instead of raw for snapshot support

## Phase 4: platform-java Integration
- [x] Basic operations work
- [x] Multi-tier app deploys
- [x] Dependencies resolve correctly

**Notes**: platform-java integration working well

... (continue for all phases)

## Summary
- **MVP Status**: ✅ PASS (6/6 core features work)
- **Production Ready**: ❌ FAIL (1 critical bug: snapshots)
- **Overall**: Mostly working, needs snapshot fix

## Recommendations
1. Fix snapshot format issue (HIGH priority)
2. Add validation for disk format requirements
3. Consider additional stress testing
```

### Bug Report Template

```markdown
**Title**: Snapshot creation fails on raw disk images

**Severity**: Medium  
**Priority**: High  
**Component**: virtos-snapshot  
**Version**: 0.1

**Description**:
Creating a snapshot of a VM with raw disk images fails with "unsupported configuration" error.

**Steps to Reproduce**:
1. Create VM with raw disk: `virtos-create-vm --name test --disk 10G --format raw`
2. Start VM: `virsh start test`
3. Create snapshot: `virtos-snapshot create test snap1`

**Expected Behavior**:
Snapshot should be created successfully or script should warn about disk format.

**Actual Behavior**:
Error: "unsupported configuration: internal snapshot for disk vda unsupported for storage type raw"

**Workaround**:
Use qcow2 disk format: `--format qcow2`

**Fix Recommendation**:
Add validation in virtos-snapshot to check disk format before attempting snapshot, provide helpful error message.
```

---

## Timeline Estimate

| Phase | Duration | Depends On |
|-------|----------|------------|
| 1. ISO Build/Boot | 2-3 hours | Build tools installed |
| 2. Package Install | 30 min | Phase 1 |
| 3. Core VM Management | 2-3 hours | Phase 2 |
| 4. platform-java Integration | 2-3 hours | Phase 3 |
| 5. Advanced Features | 4-6 hours | Phase 4 |
| 6. Security Validation | 2-3 hours | Phase 3 |
| 7. Performance Testing | 2-4 hours | Phase 4 |
| 8. Stress Testing | 2-4 hours | Phase 4 |
| 9. Error Handling | 1-2 hours | Phase 3 |

**Total**: 18-30 hours (3-4 full work days)

**Parallelization**: Phases 6-9 can run in parallel if multiple testers available.

---

## Next Steps

1. **Assign Tester**: Identify who will execute the testing
2. **Provision Environment**: Set up test hardware/VM
3. **Build ISO**: Run build process
4. **Execute Phases 1-4**: MVP validation (1 day)
5. **Report Results**: Document findings
6. **Fix Critical Bugs**: Address any blockers found
7. **Execute Phases 5-9**: Full validation (2-3 days)
8. **Final Report**: Comprehensive test results
9. **Close Issue #1**: Once all critical items pass

---

## Related Documentation

- [ISO_BUILD_STATUS.md](ISO_BUILD_STATUS.md) - ISO build system status
- [INTEGRATION_TEST_REPORT.md](INTEGRATION_TEST_REPORT.md) - Current project status
- [SCRIPT_IMPLEMENTATION_AUDIT.md](SCRIPT_IMPLEMENTATION_AUDIT.md) - Implementation details
- [CLAUDE.md](CLAUDE.md) - Development guide
- [README.md](README.md) - Project overview

---

## Appendix: Automated Testing Script

```bash
#!/bin/bash
# VirtOS Automated Test Suite
# Runs all MVP-level tests automatically

set -e

LOGFILE="/tmp/virtos-test-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOGFILE"
}

# Phase 1: Boot validation (assumes ISO already booted)
log "Phase 1: Boot validation"
if pgrep -x qemu-system-x86 > /dev/null; then
    log "✓ QEMU running"
else
    log "✗ QEMU not running"
    exit 1
fi

# Phase 2: Package validation
log "Phase 2: Package validation"
if command -v virtos-setup >/dev/null 2>&1; then
    log "✓ virtos-tools installed"
else
    log "✗ virtos-tools not installed"
    exit 1
fi

# Phase 3: VM lifecycle
log "Phase 3: VM lifecycle test"
sudo virtos-create-vm --name auto-test --cpu 1 --memory 512 --disk 5G
if virsh list --all | grep -q auto-test; then
    log "✓ VM created"
else
    log "✗ VM creation failed"
    exit 1
fi

virsh start auto-test
sleep 5
if virsh list | grep -q auto-test; then
    log "✓ VM started"
else
    log "✗ VM start failed"
    exit 1
fi

virsh destroy auto-test
virsh undefine auto-test --remove-all-storage
log "✓ VM deleted"

# Phase 4: platform-java
log "Phase 4: platform-java test"
if command -v platform-java >/dev/null 2>&1; then
    log "✓ platform-java installed"
    platform-java version
else
    log "✗ platform-java not installed"
    exit 1
fi

log "=== All MVP Tests Passed ==="
log "Full log: $LOGFILE"
```

Save as `tests/automated-test.sh`, run after VirtOS boots.

---

**Document Version**: 1.0  
**Last Reviewed**: 2026-05-25  
**Next Review**: After first test execution
