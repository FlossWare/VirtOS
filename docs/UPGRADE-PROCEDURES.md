# VirtOS Upgrade Procedures

**Last Updated**: 2026-05-28  
**Applies to**: VirtOS 0.80+

## Overview

This document describes procedures for upgrading VirtOS in production environments, including version upgrades, security patches, and rollback procedures.

## Version Compatibility

### Compatibility Matrix

| VirtOS Version | QEMU Version | libvirt Version | Tiny Core Version | platform-java Version | Support Status |
|----------------|--------------|-----------------|-------------------|-------------------|----------------|
| 0.80 - 0.82    | 6.2+         | 8.0+            | 14.x              | 0.12 - 0.13       | Legacy         |
| 0.83 - 0.89    | 7.0+         | 9.0+            | 14.x              | 0.13 - 0.14       | Current        |
| 0.90 - 0.99    | 7.2+         | 9.5+            | 15.x              | 0.14 - 0.15       | Future         |
| 1.0+           | 8.0+         | 10.0+           | 15.x              | 0.15+             | Future         |

### VM Compatibility

- **Forward compatible**: VMs created on 0.8x run on 0.9x
- **Breaking changes possible**: Major version upgrades (0.x → 1.0)
- **Always test**: VM migration before major upgrade

### Upgrade Paths

```
0.80 → 0.81 → 0.82 → 0.83 (current)
            ↓
0.82 → 0.90 (requires testing)
            ↓
0.90 → 1.0 (breaking changes expected)
```

**Important**: Cannot skip minor versions in production without testing.

## Pre-Upgrade Checklist

Before any upgrade, complete this checklist:

### Required Steps

- [ ] **Read release notes** for target version
- [ ] **Check breaking changes** and deprecations
- [ ] **Review upgrade path** (can skip versions?)
- [ ] **Verify compatibility** with current VMs
- [ ] **Test in staging** environment first
- [ ] **Create full backup** of host system
- [ ] **Snapshot all VMs** (or backup)
- [ ] **Document current configuration**
- [ ] **Schedule maintenance window**
- [ ] **Notify users** of planned downtime
- [ ] **Prepare rollback plan**

### System State Documentation

```bash
# Document current versions
virtos-version > /root/upgrade-$(date +%Y%m%d)/versions.txt
virsh version >> /root/upgrade-$(date +%Y%m%d)/versions.txt
qemu-system-x86_64 --version >> /root/upgrade-$(date +%Y%m%d)/versions.txt

# Document running VMs
virsh list --all > /root/upgrade-$(date +%Y%m%d)/vms.txt

# Document networks
virsh net-list --all > /root/upgrade-$(date +%Y%m%d)/networks.txt

# Document storage pools
virsh pool-list --all > /root/upgrade-$(date +%Y%m%d)/storage.txt

# Backup configurations
tar czf /root/upgrade-$(date +%Y%m%d)/configs.tar.gz \
    /etc/libvirt/ \
    /etc/virtos/ \
    /opt/
```

## Minor Version Upgrade (0.82 → 0.83)

**Expected downtime**: 15-30 minutes  
**Risk level**: Low  
**Rollback time**: 5-10 minutes

### Procedure

#### 1. Pre-Upgrade Backup

```bash
# Create system backup
sudo virtos-backup create-system-backup pre-upgrade-0.83

# Snapshot all running VMs
for vm in $(virsh list --name); do
    virtos-snapshot create $vm pre-upgrade-0.83
done

# Verify backups
virtos-backup verify-system-backup pre-upgrade-0.83
```

#### 2. Download and Verify

```bash
# Download new version
wget https://github.com/FlossWare/VirtOS/releases/download/v0.83/virtos-tools-0.83.tcz
wget https://github.com/FlossWare/VirtOS/releases/download/v0.83/virtos-tools-0.83.tcz.sha256

# Verify checksum
sha256sum -c virtos-tools-0.83.tcz.sha256
# Expected: virtos-tools-0.83.tcz: OK

# Backup current version
sudo cp /usr/local/tce.installed/virtos-tools /root/virtos-tools-0.82.backup
```

#### 3. Install Upgrade

```bash
# Install new TCZ package
tce-load -i virtos-tools-0.83.tcz

# Verify installation
virtos-version
# Expected: VirtOS 0.83

# Check libvirt version (should be unchanged or updated)
virsh version

# Restart libvirt if required
sudo systemctl restart libvirtd
```

#### 4. Post-Upgrade Validation

```bash
# Verify all VMs still defined
virsh list --all
# Compare with /root/upgrade-$(date +%Y%m%d)/vms.txt

# Start test VM
virsh start <test-vm>

# Verify VM works
virsh dominfo <test-vm>
virsh console <test-vm>
# Inside VM: ping 8.8.8.8

# Test VM operations
virtos-monitor status <test-vm>
virtos-snapshot create <test-vm> post-upgrade-test
virtos-snapshot delete <test-vm> post-upgrade-test

# Test critical virtos commands
virtos-network list
virtos-storage list-pools
virtos-backup list-backups <test-vm>
```

#### 5. Start Production VMs

```bash
# Start VMs one by one (not all at once)
for vm in $(virsh list --name --inactive); do
    echo "Starting $vm..."
    virsh start $vm
    sleep 10  # Wait before starting next

    # Verify VM started
    virsh list | grep $vm || echo "FAILED: $vm"
done

# Monitor for 30 minutes
watch -n 60 'virtos-monitor resources'
```

#### 6. Cleanup

```bash
# After 24-48 hours of stable operation
# Remove pre-upgrade snapshots
for vm in $(virsh list --name); do
    virtos-snapshot delete $vm pre-upgrade-0.83
done

# Keep backup for 30 days
# Delete after: rm /root/virtos-tools-0.82.backup
```

## Major Version Upgrade (0.9x → 1.0)

**Expected downtime**: 2-4 hours  
**Risk level**: High  
**Rollback time**: 30-60 minutes

### Procedure

#### 1. Extended Pre-Upgrade (1 Week Before)

```bash
# Review upgrade guide
wget https://github.com/FlossWare/VirtOS/releases/download/v1.0/UPGRADE-1.0.md
less UPGRADE-1.0.md

# Check breaking changes
cat UPGRADE-1.0.md | grep "BREAKING"

# Identify deprecated features
for script in /usr/local/bin/virtos-*; do
    grep -l "DEPRECATED" $script
done

# Test in staging environment
# (Clone production to staging first)
virtos-dr replicate-to-staging

# Upgrade staging
ssh staging-host
tce-load -i virtos-tools-1.0.tcz
# Run full test suite
./tests/integration/*.bats
```

#### 2. Migration Testing (3 Days Before)

```bash
# Test VM compatibility
virtos-compatibility-check --target-version 1.0

# Test VM migration
for vm in critical-vms; do
    virtos-migrate check-compatibility \
        --source prod-host \
        --target staging-host
done

# Document incompatibilities
virtos-compatibility-check --target-version 1.0 --report > /root/compat-issues.txt
```

#### 3. Upgrade Day

```bash
# Stop non-critical VMs
for vm in dev-vms test-vms; do
    virsh shutdown $vm
done

# Create full host backup
virtos-backup create-system-backup major-upgrade-1.0

# Install upgrade
tce-load -i virtos-tools-1.0.tcz

# Restart libvirt
sudo systemctl restart libvirtd

# Upgrade database schema (if applicable)
virtos-migrate-db --version 1.0

# Start VMs progressively
# Tier 0: Critical VMs
for vm in payment-api auth-server; do
    virsh start $vm
    # Test extensively before next
    sleep 300
done

# Tier 1: Important VMs
for vm in web-app database; do
    virsh start $vm
    sleep 60
done

# Monitor
tail -f /var/log/libvirt/qemu/*.log
```

#### 4. Post-Upgrade Monitoring

```bash
# Monitor for issues (24-48 hours)
virtos-monitor resources --watch
virtos-observability check-all

# Performance comparison
virtos-performance benchmark > /root/post-upgrade-performance.txt
diff /root/pre-upgrade-performance.txt /root/post-upgrade-performance.txt
```

## Rolling Upgrade (Zero Downtime, HA Cluster)

**Expected downtime**: 0 seconds (VMs migrated)  
**Risk level**: Medium  
**Total time**: 1-2 hours per host

### Prerequisites

- [ ] HA cluster configured (2+ hosts)
- [ ] Shared storage operational
- [ ] Live migration tested and working
- [ ] All VMs support live migration

### Procedure

#### 1. Prepare Cluster

```bash
# Verify cluster health
virtos-cluster status
# All nodes should be: Online, Healthy

# Verify shared storage
virtos-storage check-shared-pools
# All pools should be: Available, Accessible

# Test live migration
virtos-migrate --test web-server-01 host-01 host-02
# Should succeed with minimal downtime (<1s)
```

#### 2. Upgrade First Host

```bash
# 1. Drain host-01 (migrate all VMs off)
virtos-cluster drain host-01

# Monitor migration progress
watch virtos-cluster status

# Wait for all VMs to migrate
while [ $(virsh list --name | wc -l) -gt 0 ]; do
    echo "Waiting for VMs to migrate..."
    sleep 30
done

# 2. Upgrade host-01
tce-load -i virtos-tools-0.83.tcz
sudo systemctl restart libvirtd

# 3. Validate upgrade
virtos-version  # Should show 0.83
virtos-cluster validate host-01  # Should pass health checks

# 4. Activate host-01
virtos-cluster activate host-01

# Host-01 is now available for VMs
```

#### 3. Upgrade Remaining Hosts

```bash
# Repeat for host-02
virtos-cluster drain host-02
tce-load -i virtos-tools-0.83.tcz
sudo systemctl restart libvirtd
virtos-cluster validate host-02
virtos-cluster activate host-02

# Repeat for host-03, host-04, etc.
```

#### 4. Rebalance Cluster

```bash
# After all hosts upgraded, rebalance VMs
virtos-cluster rebalance

# Verify even distribution
virtos-cluster status
# Example output:
# host-01: 8 VMs (CPU: 45%, RAM: 60%)
# host-02: 10 VMs (CPU: 50%, RAM: 65%)
# host-03: 6 VMs (CPU: 40%, RAM: 55%)
```

**Downtime**: 0 seconds (VMs migrated live)  
**Total Duration**: ~1 hour per host

## Security Patch (Emergency)

**Expected downtime**: 5-15 minutes  
**Risk level**: Medium  
**Required for**: Critical CVEs

### Procedure

```bash
# 1. Verify security advisory
# Read: https://github.com/FlossWare/VirtOS/security/advisories/<CVE-ID>

# 2. Download security patch
wget https://github.com/FlossWare/VirtOS/releases/download/security/virtos-CVE-XXXX.patch
wget https://github.com/FlossWare/VirtOS/releases/download/security/virtos-CVE-XXXX.patch.sig

# 3. Verify signature
gpg --verify virtos-CVE-XXXX.patch.sig

# 4. Backup before patching
cp /usr/local/bin/virtos-* /root/backup-pre-patch/

# 5. Apply patch
cd /usr/local/bin
sudo patch < /root/virtos-CVE-XXXX.patch

# 6. Test affected functionality
# (Read patch description for what to test)

# 7. Restart affected services
sudo systemctl restart libvirtd

# 8. Verify patch applied
grep "CVE-XXXX" /usr/local/bin/virtos-* | head -1
# Should show patch version
```

## Rollback Procedures

If upgrade fails or causes issues, rollback immediately.

### Quick Rollback (TCZ Package)

**Time**: 5-10 minutes  
**Use when**: New package doesn't work

```bash
# 1. Stop affected services
sudo systemctl stop libvirtd

# 2. Restore previous package
sudo tce-load -i /root/virtos-tools-0.82.backup.tcz

# 3. Restart services
sudo systemctl start libvirtd

# 4. Verify rollback
virtos-version
# Should show 0.82 (previous version)

# 5. Test VMs
virsh list --all
virsh start <test-vm>
```

### Full System Rollback (From Backup)

**Time**: 30-60 minutes  
**Use when**: System corrupted or broken

```bash
# 1. Boot from VirtOS ISO (rescue mode)
# Select "Recovery Mode" from boot menu

# 2. Restore system backup
virtos-dr execute-dr-plan pre-upgrade-backup

# 3. Reboot
reboot

# 4. Verify restoration
virtos-version
virsh list --all

# 5. Start VMs
for vm in $(virsh list --name --inactive); do
    virsh start $vm
done
```

### Selective VM Rollback

**Time**: 5-15 minutes per VM  
**Use when**: Specific VMs don't work after upgrade

```bash
# 1. Shutdown affected VM
virsh shutdown <vm>

# 2. Restore from snapshot
virtos-snapshot revert <vm> pre-upgrade-0.83

# Or restore from backup
virtos-backup restore-backup <vm> pre-upgrade-0.83

# 3. Start VM
virsh start <vm>

# 4. Verify VM works
virsh console <vm>
```

## Upgrade Testing Checklist

After any upgrade, verify:

### Core Functionality

- [ ] **VMs start**: All VMs start successfully
- [ ] **VM performance**: No degradation in performance
- [ ] **Networking**: VM networking functional (ping, SSH, HTTP)
- [ ] **Storage**: VM storage accessible, no I/O errors
- [ ] **Snapshots**: Can create/revert snapshots
- [ ] **Backups**: Can create/restore backups
- [ ] **Migration**: Can migrate VMs between hosts
- [ ] **Console access**: VNC/serial console works

### Management Tools

- [ ] **virtos-tui**: Menu system loads and functions
- [ ] **virtos-monitor**: Metrics collection working
- [ ] **virtos-network**: Network management works
- [ ] **virtos-storage**: Storage management works
- [ ] **virtos-backup**: Backup operations work
- [ ] **virtos-cluster**: Cluster operations work (if applicable)

### Stability

- [ ] **No errors in logs**: Check `/var/log/libvirt/`, `/var/log/virtos/`
- [ ] **Resource usage normal**: CPU, RAM, disk I/O within expected ranges
- [ ] **No memory leaks**: Monitor memory usage over 24 hours
- [ ] **VMs stable**: No unexpected crashes or freezes

## Upgrade Schedule Recommendations

### Development Environment

- **Frequency**: Weekly or as needed
- **Testing**: Minimal (smoke tests)
- **Downtime**: Acceptable any time
- **Rollback**: Not critical

### Staging Environment

- **Frequency**: Monthly
- **Testing**: Full integration tests
- **Downtime**: Business hours acceptable
- **Rollback**: Test rollback procedures

### Production Environment

- **Frequency**: Quarterly (or critical security patches)
- **Testing**: Extensive (staging + pilot production)
- **Downtime**: Scheduled maintenance windows only
- **Rollback**: Tested and ready

## Maintenance Windows

### Recommended Maintenance Windows

- **Production**: Saturday 2:00 AM - 6:00 AM local time
- **Staging**: Tuesday 6:00 PM - 10:00 PM local time
- **Development**: Any time

### Maintenance Window Template

```
MAINTENANCE NOTIFICATION
========================

System: VirtOS Production Cluster
Date: 2026-06-01
Time: 02:00 AM - 06:00 AM EST
Duration: 4 hours (expected: 2 hours)

Reason: Upgrade VirtOS 0.82 → 0.83

Impact:
- VM services: No downtime (rolling upgrade)
- Management interface: 15 min downtime per host
- Backups: Suspended during upgrade

Contacts:
- Primary: ops@example.com
- Emergency: +1-555-1234

Rollback Plan: Restore from backup (30 min)
```

## Getting Help

- **Upgrade issues**: File GitHub issue with "upgrade" label
- **Security patches**: <security@flossware.org>
- **Emergency support**: Check [COMMUNITY.md](COMMUNITY.md)

---

**Upgrade Procedures Version**: 1.0 (2026-05-26)  
**Applies to**: VirtOS 0.80+  
**Related**: [QUICK-REFERENCE.md](QUICK-REFERENCE.md), [DR-PROCEDURES.md](DR-PROCEDURES.md)
