# Storage on VirtOS

Complete guide to storage options, filesystems, and configurations for VirtOS.

## Overview

VirtOS supports multiple storage solutions from basic local filesystems to enterprise distributed storage. Choose based on your needs:

- **Basic** - ext4 for simple VM storage
- **Snapshots** - Btrfs or LVM for VM snapshots and cloning
- **Enterprise** - ZFS for data integrity and compression
- **Shared** - NFS for multi-host VM storage
- **Distributed** - Ceph for scalable storage clusters (future)

## Philosophy

Following VirtOS principles:

- **Minimal by default** - ext4 works for most cases
- **Optional advanced features** - Enable only what you need
- **Choosable** - Pick the right tool for your use case

## Built-in Filesystems

### ext2/ext3/ext4 (Default)

**Always available** - standard Linux filesystems.

```bash
# Format disk
mkfs.ext4 /dev/sdb1

# Mount
mkdir -p /mnt/vms
mount /dev/sdb1 /mnt/vms

# Make persistent (add to bootlocal.sh)
echo "mount /dev/sdb1 /mnt/vms" >> /opt/bootlocal.sh
```

**When to use:**

- ✓ Simple setups
- ✓ Good performance
- ✓ Stable and mature
- ✗ No snapshots
- ✗ No compression

### vfat/FAT32

**Always available** - compatibility filesystem.

```bash
# Format USB drive
mkfs.vfat /dev/sdc1

# Mount
mount /dev/sdc1 /mnt/usb
```

**When to use:**

- ✓ USB drives
- ✓ Cross-platform compatibility
- ✗ Not for VM storage (lacks features)

### tmpfs (RAM-based)

**Always available** - temporary storage in RAM.

```bash
# Mount tmpfs
mount -t tmpfs -o size=2G tmpfs /tmp/fast

# Create fast VM disk (lost on reboot!)
qemu-img create /tmp/fast/test.qcow2 10G
```

**When to use:**

- ✓ Temporary VMs
- ✓ Cache/scratch space
- ✓ Ultra-fast I/O
- ✗ Not persistent
- ✗ Uses RAM

## Optional Filesystems

Enable in `build/build.conf`:

```bash
# Advanced filesystems
INCLUDE_BTRFS="yes"      # Snapshots, compression
INCLUDE_LVM="yes"        # Flexible volume management
INCLUDE_ZFS="yes"        # Enterprise features

# Shared storage
CLUSTER_SHARED_STORAGE="yes"  # NFS client/server
```

### Btrfs - Modern Linux Filesystem

**Recommended for VM snapshots and cloning.**

#### Enable Btrfs

```bash
# In build.conf
INCLUDE_BTRFS="yes"
```

**Size:** ~10-20MB

#### Setup

```bash
# Format disk
mkfs.btrfs /dev/sdb1

# Mount
mount /dev/sdb1 /var/lib/vms

# Create subvolume for VMs
btrfs subvolume create /var/lib/vms/production
```

#### VM Snapshots

```bash
# Create VM
qemu-img create -f qcow2 /var/lib/vms/production/web-1.qcow2 50G

# Snapshot entire subvolume
btrfs subvolume snapshot /var/lib/vms/production \
  /var/lib/vms/production-backup-2026-05-22

# Clone VM (instant)
btrfs subvolume snapshot /var/lib/vms/production \
  /var/lib/vms/test-clone

# Restore from snapshot
mv /var/lib/vms/production /var/lib/vms/production-broken
mv /var/lib/vms/production-backup-2026-05-22 /var/lib/vms/production
```

#### Compression

```bash
# Enable compression (reduces disk usage)
mount -o compress=lz4 /dev/sdb1 /var/lib/vms

# Make persistent
echo "mount -o compress=lz4 /dev/sdb1 /var/lib/vms" >> /opt/bootlocal.sh
```

#### Features

- ✓ **Snapshots** - Instant, space-efficient
- ✓ **Compression** - Save disk space (lz4, zstd)
- ✓ **Subvolumes** - Organize storage
- ✓ **Easy to use** - Simple commands
- ✓ **Good performance** - Fast for most workloads
- ✗ **RAM usage** - Needs ~1GB per TB
- ✗ **RAID 5/6** - Not production-ready yet

**When to use:**

- VM snapshots before updates
- Quick VM cloning
- Save disk space with compression
- Flexible storage management

### LVM - Logical Volume Manager

**Recommended for flexible disk management.**

#### Enable LVM

```bash
# In build.conf
INCLUDE_LVM="yes"
```

**Size:** ~5MB

#### Setup

```bash
# Create physical volume
pvcreate /dev/sdb1

# Create volume group
vgcreate vg_vms /dev/sdb1

# Create logical volumes
lvcreate -L 50G -n web-1 vg_vms
lvcreate -L 100G -n db-1 vg_vms
```

#### Format and Use

```bash
# Format logical volume
mkfs.ext4 /dev/vg_vms/web-1

# Mount
mkdir -p /var/lib/vms/web-1
mount /dev/vg_vms/web-1 /var/lib/vms/web-1
```

#### VM Storage on LVM

```bash
# Create VM disk as logical volume (better than qcow2)
lvcreate -L 50G -n vm-web-1-disk vg_vms

# Use with QEMU/KVM
qemu-system-x86_64 \
  -drive file=/dev/vg_vms/vm-web-1-disk,format=raw \
  ...
```

#### Snapshots

```bash
# Snapshot (10GB snapshot space)
lvcreate -L 10G -s -n web-1-snapshot /dev/vg_vms/web-1

# Mount snapshot (read-only view)
mount -o ro /dev/vg_vms/web-1-snapshot /mnt/snapshot

# Restore from snapshot
lvconvert --merge /dev/vg_vms/web-1-snapshot
```

#### Resize Volumes

```bash
# Extend volume
lvextend -L +50G /dev/vg_vms/web-1
resize2fs /dev/vg_vms/web-1  # Grow filesystem

# Reduce volume (unmount first!)
umount /dev/vg_vms/web-1
e2fsck -f /dev/vg_vms/web-1
resize2fs /dev/vg_vms/web-1 50G
lvreduce -L 50G /dev/vg_vms/web-1
```

#### Add More Disks

```bash
# Add new disk to volume group
pvcreate /dev/sdc1
vgextend vg_vms /dev/sdc1

# Now you have more space!
vgdisplay vg_vms
```

#### Features

- ✓ **Flexible resizing** - Grow/shrink volumes
- ✓ **Snapshots** - Good for backups
- ✓ **Thin provisioning** - Overcommit storage
- ✓ **Multiple disks** - Combine into one pool
- ✓ **Mature** - Very stable
- ✗ **No compression** - Use at filesystem level
- ✗ **Complex** - More commands to learn

**When to use:**

- Dynamic storage allocation
- Need to resize VM disks
- Combine multiple physical disks
- Enterprise environments

### ZFS - Enterprise Storage

**Recommended for data integrity and advanced features.**

#### Enable ZFS

```bash
# In build.conf
INCLUDE_ZFS="yes"
```

**Size:** ~50-100MB  
**RAM:** Minimum 2GB, recommend 1GB per TB of storage

#### Setup

```bash
# Create pool (single disk)
zpool create vmpool /dev/sdb

# Create pool (mirror for redundancy)
zpool create vmpool mirror /dev/sdb /dev/sdc

# Create pool (RAID-Z, like RAID-5)
zpool create vmpool raidz /dev/sdb /dev/sdc /dev/sdd

# Create pool (RAID-Z2, like RAID-6, survives 2 disk failures)
zpool create vmpool raidz2 /dev/sdb /dev/sdc /dev/sdd /dev/sde
```

#### Create Datasets

```bash
# Create dataset for VMs
zfs create vmpool/vms

# Enable compression (HIGHLY RECOMMENDED)
zfs set compression=lz4 vmpool/vms

# Set deduplication (careful - needs LOTS of RAM)
zfs set dedup=on vmpool/vms  # Only if you have 5GB+ RAM per TB

# Set quota
zfs set quota=500G vmpool/vms
```

#### VM Storage on ZFS

```bash
# Create VM disk as ZFS volume (zvol)
zfs create -V 50G vmpool/vms/web-1

# Use with QEMU/KVM
qemu-system-x86_64 \
  -drive file=/dev/zvol/vmpool/vms/web-1,format=raw \
  ...
```

#### Snapshots

```bash
# Snapshot dataset (instant, space-efficient)
zfs snapshot vmpool/vms@backup-2026-05-22

# List snapshots
zfs list -t snapshot

# Clone from snapshot
zfs clone vmpool/vms@backup-2026-05-22 vmpool/test-clone

# Rollback to snapshot
zfs rollback vmpool/vms@backup-2026-05-22

# Delete snapshot
zfs destroy vmpool/vms@backup-2026-05-22
```

#### Send/Receive (Replication)

```bash
# Send snapshot to another host
zfs snapshot vmpool/vms@replicate
zfs send vmpool/vms@replicate | ssh virtos-2.local \
  zfs receive backup/vms

# Incremental send (only changes)
zfs snapshot vmpool/vms@replicate-2
zfs send -i vmpool/vms@replicate vmpool/vms@replicate-2 | \
  ssh virtos-2.local zfs receive backup/vms
```

#### Monitoring

```bash
# Pool status
zpool status

# Pool I/O stats
zpool iostat 5  # Update every 5 seconds

# Dataset usage
zfs list

# Compression ratio
zfs get compressratio vmpool/vms
```

#### Maintenance

```bash
# Scrub (verify data integrity)
zpool scrub vmpool

# Check scrub progress
zpool status
```

#### Features

- ✓ **Data integrity** - Checksums on everything
- ✓ **Compression** - Excellent (lz4, zstd)
- ✓ **Snapshots** - Instant, unlimited
- ✓ **Replication** - Built-in send/receive
- ✓ **RAID** - Multiple levels, self-healing
- ✓ **Deduplication** - Save space (if you have RAM)
- ✓ **Copy-on-write** - Never overwrites data
- ✗ **RAM hungry** - Needs significant RAM
- ✗ **Complex** - Steeper learning curve
- ✗ **Size** - Larger footprint

**When to use:**

- Data integrity is critical
- Large storage arrays
- Need compression
- Multi-host replication
- Enterprise environments

## Shared Storage (Multi-Host)

### NFS - Network File System

**Enable shared storage for VM migration.**

#### Enable NFS

```bash
# In build.conf
CLUSTER_SHARED_STORAGE="yes"
```

**Size:** ~5-10MB

#### Setup NFS Server (virtos-1)

```bash
# Create export directory
mkdir -p /export/vms

# Add to /etc/exports
cat >> /etc/exports <<EOF
/export/vms virtos-2.local(rw,sync,no_subtree_check,no_root_squash)
/export/vms virtos-3.local(rw,sync,no_subtree_check,no_root_squash)
EOF

# Start NFS server
/usr/local/etc/init.d/nfs-server start
exportfs -av
```

#### Setup NFS Client (virtos-2, virtos-3)

```bash
# Mount NFS share
mkdir -p /var/lib/vms
mount -t nfs virtos-1.local:/export/vms /var/lib/vms

# Make persistent
echo "mount -t nfs virtos-1.local:/export/vms /var/lib/vms" \
  >> /opt/bootlocal.sh
```

#### Use with VMs

```bash
# Create VM on shared storage (from any host)
qemu-img create -f qcow2 /var/lib/vms/web-1.qcow2 50G

# Start VM on virtos-1
virsh start web-1

# Stop on virtos-1, start on virtos-2 (migration!)
virsh shutdown web-1  # on virtos-1
virsh start web-1     # on virtos-2 (same storage!)
```

#### Features

- ✓ **Simple** - Easy to set up
- ✓ **VM migration** - Move VMs between hosts
- ✓ **Shared access** - Multiple hosts access same storage
- ✓ **Well supported** - Works everywhere
- ✗ **Single point of failure** - Server down = no storage
- ✗ **Performance** - Network overhead
- ✗ **No redundancy** - Built-in HA

**When to use:**

- Multi-host clusters
- VM migration needed
- Centralized VM storage

### Ceph - Distributed Storage (Future)

**Planned for VirtOS, not yet implemented.**

Would provide:

- Distributed storage pool
- High availability (no single point of failure)
- Automatic replication
- Self-healing
- Scalable to hundreds of nodes

**Requirements:**

- 3+ hosts minimum
- Dedicated network (10GbE recommended)
- Significant resources (CPU, RAM, disk)

**Status:** Not implemented yet. See [ROADMAP.md](ROADMAP.md).

## Storage Comparison

| Feature | ext4 | Btrfs | LVM | ZFS | NFS |
|---------|------|-------|-----|-----|-----|
| **Snapshots** | ✗ | ✓ | ✓ | ✓ | ✗ |
| **Compression** | ✗ | ✓ | ✗ | ✓ | ✗ |
| **Easy resize** | ✗ | ✓ | ✓ | ✓ | N/A |
| **RAID** | ✗ | ✓ | ✗ | ✓ | ✗ |
| **Dedup** | ✗ | ✗ | ✗ | ✓ | ✗ |
| **Shared** | ✗ | ✗ | ✗ | ✗ | ✓ |
| **Complexity** | Low | Med | Med | High | Low |
| **Size** | 0MB | 10-20MB | 5MB | 50-100MB | 5-10MB |
| **RAM** | Low | Med | Low | High | Low |
| **Maturity** | ★★★★★ | ★★★★☆ | ★★★★★ | ★★★★★ | ★★★★★ |

## Use Case Recommendations

### Home Lab / Learning

**Use:** ext4 (default)

```bash
INCLUDE_BTRFS="no"
INCLUDE_LVM="no"
INCLUDE_ZFS="no"
```

- Simple, reliable, sufficient

### Development / Testing

**Use:** Btrfs

```bash
INCLUDE_BTRFS="yes"
```

- Snapshots before testing
- Quick cloning
- Easy rollback

### Production Single Host

**Use:** LVM or ZFS

```bash
INCLUDE_LVM="yes"  # or
INCLUDE_ZFS="yes"
```

- LVM: Flexible, proven
- ZFS: Data integrity, compression

### Multi-Host Cluster

**Use:** ZFS + NFS

```bash
INCLUDE_ZFS="yes"
CLUSTER_SHARED_STORAGE="yes"
```

- ZFS on NFS server for data integrity
- NFS for shared access
- VM migration capability

### Enterprise / Large Scale

**Use:** ZFS (now) → Ceph (future)

```bash
INCLUDE_ZFS="yes"
```

- ZFS pools on each host
- Plan for Ceph migration later

## Best Practices

### 1. Separate OS and VM Storage

```bash
# OS on small SSD (VirtOS runs from RAM anyway)
/dev/sda1 - 20GB ext4 for persistence

# VMs on large disk(s)
/dev/sdb1 - 1TB+ Btrfs/LVM/ZFS for VMs
```

### 2. Regular Snapshots

**Btrfs:**

```bash
# Daily snapshot script
#!/bin/sh
DATE=$(date +%Y-%m-%d)
btrfs subvolume snapshot /var/lib/vms /var/lib/vms-snapshot-$DATE
# Keep last 7 days
find /var/lib/vms-snapshot-* -mtime +7 -exec btrfs subvolume delete {} \;
```

**ZFS:**

```bash
# Automated snapshots (zfs-auto-snapshot)
zfs snapshot vmpool/vms@daily-$(date +%Y-%m-%d)
# Keep last 7 days
zfs list -t snapshot | grep daily | tail -n +8 | cut -d@ -f1 | xargs -n1 zfs destroy
```

### 3. Monitor Disk Usage

```bash
# Disk space
df -h

# Btrfs usage
btrfs filesystem usage /var/lib/vms

# LVM usage
vgdisplay
lvdisplay

# ZFS usage
zpool list
zfs list
```

### 4. Performance Tuning

**For SSDs:**

```bash
# Disable barriers (only if battery-backed cache)
mount -o nobarrier /dev/sdb1 /var/lib/vms

# Use noop scheduler
echo noop > /sys/block/sdb/queue/scheduler
```

**For ZFS:**

```bash
# Set ARC size (ZFS cache, 50% of RAM max)
echo "options zfs zfs_arc_max=4294967296" > /etc/modprobe.d/zfs.conf
# 4GB in bytes
```

**For VMs:**

```bash
# Use virtio-scsi for better performance
qemu-system-x86_64 \
  -drive file=disk.qcow2,if=none,id=disk0 \
  -device virtio-scsi-pci,id=scsi0 \
  -device scsi-hd,drive=disk0,bus=scsi0.0
```

### 5. Backup Strategy

**Local snapshots (quick recovery):**

```bash
# Btrfs/ZFS snapshots before changes
btrfs subvolume snapshot /var/lib/vms /var/lib/vms-pre-update
```

**Off-site backups (disaster recovery):**

```bash
# ZFS send to remote
zfs send vmpool/vms@backup | ssh backup-server zfs receive pool/virtos-backup

# Or traditional backup
rsync -avz /var/lib/vms/ backup-server:/backups/virtos/
```

### 6. Storage Pooling with LVM

```bash
# Add multiple disks to one pool
pvcreate /dev/sdb1 /dev/sdc1 /dev/sdd1
vgcreate vg_vms /dev/sdb1 /dev/sdc1 /dev/sdd1

# Now you have combined capacity
vgdisplay vg_vms  # Total size = sum of all disks
```

## Profiles

### Storage Profile

Pre-configured with advanced storage:

```bash
# In build.conf
PROFILE="storage"
```

**Includes:**

- Btrfs - Snapshots and compression
- LVM - Volume management
- ZFS - Enterprise features
- NFS - Shared storage
- All storage tools

**Size:** ~350MB  
**RAM:** 4GB+ recommended (for ZFS)

See [PROFILES.md](PROFILES.md) for all profiles.

## Troubleshooting

### Btrfs Balance

```bash
# If "no space" errors with free space showing
btrfs balance start /var/lib/vms
```

### LVM Snapshot Full

```bash
# Extend snapshot
lvextend -L +10G /dev/vg_vms/web-1-snapshot
```

### ZFS Pool Degraded

```bash
# Check status
zpool status

# Replace failed disk
zpool replace vmpool /dev/sdb /dev/sde  # Replace sdb with sde

# Resilver will start automatically
```

### NFS Stale File Handle

```bash
# Unmount (force if needed)
umount -f /var/lib/vms

# Remount
mount -t nfs virtos-1.local:/export/vms /var/lib/vms
```

## Quick Reference

```bash
# ext4
mkfs.ext4 /dev/sdb1
mount /dev/sdb1 /mnt

# Btrfs
mkfs.btrfs /dev/sdb1
mount /dev/sdb1 /mnt
btrfs subvolume snapshot /mnt /mnt-snapshot

# LVM
pvcreate /dev/sdb1
vgcreate vg0 /dev/sdb1
lvcreate -L 10G -n lv0 vg0
mkfs.ext4 /dev/vg0/lv0

# ZFS
zpool create pool /dev/sdb
zfs create pool/data
zfs set compression=lz4 pool/data
zfs snapshot pool/data@snap1

# NFS Server
echo "/export/data *(rw,sync)" >> /etc/exports
exportfs -av

# NFS Client
mount -t nfs server:/export/data /mnt
```

## Related Documentation

- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Storage commands
- [PROFILES.md](PROFILES.md) - Storage profile details
- [CONFIGURATION.md](CONFIGURATION.md) - Storage build options
- [CLUSTERING.md](CLUSTERING.md) - Shared storage for clusters

## Summary

**Start simple:**

- Use ext4 (default) for basic needs

**Add as needed:**

- Btrfs for snapshots
- LVM for flexibility
- ZFS for enterprise
- NFS for sharing

**Remember:**

- VirtOS philosophy: optional and choosable
- Enable only what you need
- Start small, grow as needed

Choose the right tool for your use case!
