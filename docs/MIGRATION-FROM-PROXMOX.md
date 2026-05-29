# Migration Guide: Proxmox VE to VirtOS

**Status**: ⚠️ **DRAFT** - VirtOS is not yet production-ready (v0.89 alpha)  
**Target Audience**: Proxmox VE users evaluating VirtOS  
**Prerequisites**: VirtOS v1.0+ (not available yet - estimated Q1 2027)

## ⚠️ Important Notice

**VirtOS is currently in alpha** and **NOT recommended for production migration** until v1.0 is released. This guide is provided for:
- Evaluation and testing purposes
- Planning future migrations
- Understanding feature parity
- Contributing to VirtOS development

**Do not migrate production systems at this time.**

---

## Why Migrate from Proxmox to VirtOS?

### Potential Benefits

**Lighter Resource Footprint**:
- VirtOS ISO: ~200MB (vs Proxmox ~1GB installer)
- Base system RAM: <512MB (vs Proxmox ~2GB)
- Minimal base system, modular extensions
- Faster boot times

**Unified VM + Container Management**:
- Native support for KVM, LXC, Docker, Podman, containerd
- Consistent CLI/TUI for all workload types
- platform-java orchestration layer

**Open Development Model**:
- Fully open-source (GPLv3)
- Community-driven development
- No commercial entity control
- Transparent roadmap

**Flexibility**:
- Choice of container runtimes (Docker/Podman/containerd)
- Modular package system (TCZ)
- Customizable profiles
- Terminal-first design

### Trade-offs to Consider

**What You Gain**:
- Smaller footprint
- More container options
- Lighter weight
- Terminal-centric workflow

**What You Lose** (vs Proxmox):
- ❌ Web UI (CLI/TUI only) - planned for v1.5
- ❌ Mature ecosystem (Proxmox has 15+ years)
- ❌ Commercial support options
- ❌ Large community (Proxmox forum has 100k+ users)
- ❌ Extensive hardware compatibility testing
- ❌ Backup solutions (Proxmox Backup Server)
- ❌ SDN features
- ❌ Hardware RAID management UI

---

## Feature Parity Matrix

| Feature | Proxmox VE | VirtOS v0.89 | VirtOS v1.0 (Planned) |
|---------|------------|--------------|----------------------|
| **VM Management** |
| KVM/QEMU VMs | ✅ Full | ✅ Working | ✅ Validated |
| VM Creation | ✅ Web UI | ✅ CLI/TUI | ✅ CLI/TUI |
| VM Snapshots | ✅ Full | ✅ Working | ✅ Validated |
| VM Migration | ✅ Full | ✅ Working | ✅ Validated |
| VM Templates | ✅ Full | ✅ Working | ✅ Validated |
| **Container Management** |
| LXC Containers | ✅ Full | ✅ Working | ✅ Validated |
| Docker | ⚠️ Via LXC | ✅ Native | ✅ Native |
| Podman | ❌ No | ✅ Native | ✅ Native |
| containerd | ❌ No | ✅ Native | ✅ Native |
| **Storage** |
| Local storage | ✅ Full | ✅ Working | ✅ Validated |
| NFS | ✅ Full | ✅ Working | ✅ Validated |
| iSCSI | ✅ Full | 🟡 Partial | ✅ Full |
| Ceph | ✅ Full | ❌ No | 📅 Planned v2.0 |
| ZFS | ✅ Full | ✅ Working | ✅ Validated |
| **Networking** |
| Linux Bridge | ✅ Full | ✅ Working | ✅ Validated |
| OVS | ✅ Full | 🟡 Partial | ✅ Full |
| SDN | ✅ Full | ❌ No | 📅 Planned v1.5 |
| VLANs | ✅ Full | ✅ Working | ✅ Validated |
| **Backup** |
| VM Backup | ✅ PBS | ✅ Local | ✅ Multiple backends |
| Scheduled Backups | ✅ Full | ✅ Working | ✅ Validated |
| Incremental | ✅ PBS | ❌ No | 📅 Planned |
| **High Availability** |
| HA Clustering | ✅ Full | 🟡 Basic | ✅ Validated |
| Fencing | ✅ Full | 🟡 Basic | ✅ Full |
| Live Migration | ✅ Full | ✅ Working | ✅ Validated |
| **Management** |
| Web UI | ✅ Excellent | ❌ No | 📅 v1.5 |
| CLI | ✅ pvesh | ✅ virtos-* | ✅ Enhanced |
| TUI | ❌ No | ✅ virtos-tui | ✅ Enhanced |
| REST API | ✅ Full | 🟡 Partial | ✅ Full |
| **Auth & Security** |
| LDAP/AD | ✅ Full | 🟡 Interface | ✅ Full |
| 2FA | ✅ TOTP | ❌ No | 📅 v1.5 |
| RBAC | ✅ Full | 🟡 Basic | ✅ Full |
| Firewall | ✅ GUI | ✅ CLI | ✅ CLI |

**Legend**:
- ✅ Full/Working - Feature implemented and functional
- 🟡 Partial - Partial implementation or interface only
- ❌ No - Not implemented
- 📅 Planned - On roadmap for future version

---

## Migration Prerequisites

### Before You Begin

**System Requirements**:
- VirtOS v1.0+ installed (wait for release)
- Sufficient storage for VM exports
- Network connectivity between Proxmox and VirtOS
- At least 2x storage space of VMs to migrate

**Proxmox Requirements**:
- Proxmox VE 7.x or 8.x
- All VMs stopped during export
- Backup of all VMs (safety net)
- Note of network configurations

**VirtOS Requirements**:
- Installed and validated
- Storage pools configured
- Networks configured to match Proxmox
- Sufficient resources (CPU, RAM, disk)

**Skills Required**:
- Comfortable with Linux command line
- Understanding of virtualization concepts
- Ability to troubleshoot boot issues
- Backup and recovery experience

---

## Migration Process

### Phase 1: Planning (1-2 Days)

**1. Inventory Your Environment**

```bash
# On Proxmox, list all VMs
pvesh get /cluster/resources --type vm --output-format json > vm-inventory.json

# Document for each VM:
# - VM ID
# - VM name
# - vCPU count
# - RAM allocation
# - Disk size and format
# - Network configuration
# - Boot order
# - Special hardware (GPU, USB)
# - Dependencies on other VMs
```

**2. Categorize VMs**

```markdown
## Migration Priority

**Wave 1: Test VMs** (Low Risk)
- dev-web-01
- test-database
- staging-app

**Wave 2: Non-Critical** (Medium Risk)
- internal-wiki
- backup-server
- monitoring

**Wave 3: Production** (High Risk - Migrate Last)
- production-web
- production-database
- payment-processing
```

**3. Plan Downtime Windows**

- Test VMs: Anytime
- Non-critical: Weekends
- Production: Scheduled maintenance window (2-4 hour window minimum)

**4. Create Rollback Plan**

```markdown
## Rollback Procedure

If migration fails:
1. Keep Proxmox VMs intact (do not delete)
2. Shut down VirtOS VMs
3. Start Proxmox VMs
4. Update DNS/load balancers to point back to Proxmox
5. Document what failed for retry
```

---

### Phase 2: Environment Preparation (1 Day)

**1. Set Up VirtOS**

```bash
# Install VirtOS (follow INSTALLATION.md)
sudo virtos-setup

# Configure storage pools
virtos-storage create-pool vm-storage dir /var/lib/libvirt/images

# Configure networks to match Proxmox
virtos-network bridge-create vmbr0
virtos-network create-nat vmbr1 192.168.100.0/24
```

**2. Configure Shared Storage (Optional)**

```bash
# If using NFS for migration
sudo mkdir -p /mnt/migration
sudo mount -t nfs proxmox-host:/export/vms /mnt/migration
```

---

### Phase 3: Test Migration (1 VM)

**1. Export VM from Proxmox**

```bash
# On Proxmox
# Stop the VM
qm stop 100

# Export VM configuration
qm config 100 > /tmp/vm-100-config.txt

# Export disk (qcow2 format)
# If VM disk is already qcow2:
cp /var/lib/vz/images/100/vm-100-disk-0.qcow2 /mnt/migration/

# If VM disk is raw or other format:
qemu-img convert -f raw -O qcow2 \
    /var/lib/vz/images/100/vm-100-disk-0.raw \
    /mnt/migration/vm-100-disk-0.qcow2
```

**2. Transfer to VirtOS**

```bash
# If not using shared storage, use scp
scp proxmox-host:/mnt/migration/vm-100-disk-0.qcow2 \
    /var/lib/libvirt/images/
```

**3. Import to VirtOS**

```bash
# On VirtOS
# Create VM definition matching Proxmox config
virtos-create-vm \
    --name test-vm-100 \
    --cpu 2 \
    --ram 4096 \
    --disk /var/lib/libvirt/images/vm-100-disk-0.qcow2 \
    --network vmbr0 \
    --os linux

# Or use virt-install for more control
virt-install \
    --name test-vm-100 \
    --memory 4096 \
    --vcpus 2 \
    --disk path=/var/lib/libvirt/images/vm-100-disk-0.qcow2,format=qcow2 \
    --network bridge=vmbr0 \
    --os-variant ubuntu22.04 \
    --import
```

**4. Test the VM**

```bash
# Start VM
virsh start test-vm-100

# Connect to console
virsh console test-vm-100

# Verify inside VM:
# - Network connectivity
# - Disk accessible
# - Services starting
# - Application functionality

# Test from outside:
ping <vm-ip>
ssh <vm-ip>
curl http://<vm-ip>
```

**5. Validate and Document**

```markdown
## Test Migration Results

**VM**: test-vm-100
**Status**: ✅ Success / ❌ Failed
**Boot Time**: 45 seconds
**Issues**:
- Network required manual configuration
- Disk UUID changed (updated /etc/fstab)

**Lessons Learned**:
- Document network MAC addresses before export
- Check /etc/fstab for disk UUIDs
- Verify firewall rules after migration
```

---

### Phase 4: Bulk Migration

**1. Automate Export Script**

```bash
#!/bin/bash
# export-proxmox-vms.sh

VM_IDS="100 101 102"  # Space-separated list
EXPORT_DIR="/mnt/migration"

for VMID in $VM_IDS; do
    echo "Exporting VM $VMID..."
    
    # Stop VM
    qm stop $VMID
    
    # Export config
    qm config $VMID > "$EXPORT_DIR/vm-$VMID-config.txt"
    
    # Export disk
    DISK=$(qm config $VMID | grep 'scsi0:' | cut -d: -f2 | cut -d, -f1)
    qemu-img convert -f qcow2 -O qcow2 \
        "/var/lib/vz/images/$VMID/$DISK" \
        "$EXPORT_DIR/vm-$VMID-disk-0.qcow2"
    
    echo "VM $VMID exported successfully"
done
```

**2. Automate Import Script**

```bash
#!/bin/bash
# import-to-virtos.sh

EXPORT_DIR="/mnt/migration"
VM_CONFIGS="100:test-vm-100:2:4096 101:web-server:4:8192"

for VM_CONFIG in $VM_CONFIGS; do
    IFS=':' read -r VMID NAME CPU RAM <<< "$VM_CONFIG"
    
    echo "Importing VM $NAME (Proxmox ID: $VMID)..."
    
    # Copy disk
    cp "$EXPORT_DIR/vm-$VMID-disk-0.qcow2" \
        "/var/lib/libvirt/images/$NAME.qcow2"
    
    # Create VM
    virtos-create-vm \
        --name "$NAME" \
        --cpu "$CPU" \
        --ram "$RAM" \
        --disk "/var/lib/libvirt/images/$NAME.qcow2" \
        --network vmbr0
    
    echo "VM $NAME imported successfully"
done
```

**3. Execute Migration in Waves**

```bash
# Wave 1: Test VMs (low risk)
./export-proxmox-vms.sh  # VM IDs 100-102
./import-to-virtos.sh

# Test all Wave 1 VMs
# If successful, proceed to Wave 2

# Wave 2: Non-critical VMs
./export-proxmox-vms.sh  # VM IDs 200-205
./import-to-virtos.sh

# Wave 3: Production VMs (during maintenance window)
./export-proxmox-vms.sh  # VM IDs 300-310
./import-to-virtos.sh
```

---

### Phase 5: Post-Migration Validation

**1. Functional Testing**

```bash
# For each migrated VM:

# Check VM is running
virsh list --all | grep <vm-name>

# Check resource allocation
virsh dominfo <vm-name>

# Test network connectivity
ping <vm-ip>
ssh <vm-ip>

# Test application functionality
curl http://<vm-ip>/<health-endpoint>

# Check logs for errors
virsh console <vm-name>
# Inside VM: journalctl -xe
```

**2. Performance Comparison**

```bash
# Benchmark before (on Proxmox) and after (on VirtOS)

# Disk I/O
fio --name=random-write --ioengine=libaio --iodepth=32 --rw=randwrite \
    --bs=4k --direct=1 --size=1G --numjobs=4 --runtime=60 --group_reporting

# Network throughput
iperf3 -s  # On target
iperf3 -c <target-ip> -t 60  # On source

# CPU performance
sysbench cpu --threads=4 --time=60 run
```

**3. Update Documentation**

```markdown
## Migration Results

**Total VMs**: 25
**Successful**: 23 (92%)
**Failed**: 2 (8%)
  - vm-old-kernel: Too old kernel, not compatible
  - vm-special-hardware: Required PCIe passthrough

**Total Downtime**: 
- Test VMs: <5 min per VM
- Production VMs: <15 min per VM

**Issues Encountered**:
1. Network MAC addresses changed - updated manually
2. Some VMs required /etc/fstab updates (disk UUIDs)
3. Firewall rules needed recreation

**Performance**: 
- VirtOS comparable to Proxmox for most workloads
- Slightly faster boot times
- Lower host RAM usage

**Recommendation**: Migration successful, VirtOS suitable for our use case
```

---

### Phase 6: Decommission Proxmox

**⚠️ Only after 30+ days of stable VirtOS operation**

```bash
# 1. Verify all VMs running on VirtOS for 30+ days
# 2. Verify all backups working
# 3. Verify monitoring and alerting operational
# 4. Document any issues and resolutions

# 5. Shut down Proxmox VMs
# (Keep them for 90 days as backup)

# 6. After 90 days of VirtOS stability:
# Consider repurposing Proxmox host or decommissioning
```

---

## Troubleshooting Common Issues

### VM Won't Boot After Migration

**Symptoms**: VM starts but doesn't boot OS

**Diagnosis**:
```bash
# Check VM logs
virsh console <vm-name>

# Common issues:
# - Wrong boot order
# - Missing bootloader
# - Disk UUID mismatch
```

**Solutions**:
```bash
# Fix boot order
virsh edit <vm-name>
# Change <boot dev='cdrom'/> to <boot dev='hd'/>

# Fix disk UUID in VM /etc/fstab
# Boot VM in rescue mode
# Mount root partition
# Update /etc/fstab with new UUIDs from blkid
```

---

### Network Not Working

**Symptoms**: VM has no network connectivity

**Solutions**:
```bash
# Check bridge exists
ip link show vmbr0

# Check VM network config
virsh domiflist <vm-name>

# Inside VM, reconfigure network
# Ubuntu/Debian:
sudo nano /etc/netplan/01-netcfg.yaml
sudo netplan apply

# CentOS/RHEL:
sudo nano /etc/sysconfig/network-scripts/ifcfg-eth0
sudo systemctl restart network
```

---

### Performance Degradation

**Symptoms**: VM slower on VirtOS than Proxmox

**Diagnosis**:
```bash
# Check virtio drivers
lsmod | grep virtio

# Check disk cache settings
virsh dumpxml <vm-name> | grep cache

# Check CPU pinning
virsh vcpuinfo <vm-name>
```

**Solutions**:
```bash
# Enable virtio drivers (if not already)
virsh edit <vm-name>
# Change disk driver to virtio
# Change network model to virtio

# Optimize disk caching
virsh edit <vm-name>
# Add: <driver name='qemu' type='qcow2' cache='none' io='native'/>

# Pin vCPUs to physical CPUs
virsh vcpupin <vm-name> 0 0
virsh vcpupin <vm-name> 1 1
```

---

## Alternatives to Full Migration

### Hybrid Approach

**Keep Proxmox for:**
- Production critical VMs (until VirtOS v1.0 proven)
- VMs requiring web UI management
- VMs with specific Proxmox features (Ceph, SDN)

**Use VirtOS for:**
- New development/test VMs
- Container workloads (Docker, Podman)
- Edge computing deployments
- Home lab experiments

### Gradual Migration

**Year 1**: Proxmox for production, VirtOS for dev/test
**Year 2**: Migrate non-critical to VirtOS after v1.0 release
**Year 3**: Evaluate migrating production based on v1.0 stability

---

## Getting Help

**VirtOS Community**:
- GitHub Issues: Report migration issues
- GitHub Discussions: Ask migration questions
- Discord: Real-time help (if/when created)

**Documentation**:
- [INSTALLATION.md](INSTALLATION.md)
- [QUICK-START.md](QUICK-START.md)
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

**Professional Services** (Future):
- Migration consulting
- Custom development
- Training and support

---

## Conclusion

**Current Recommendation**: 
- ⚠️ **Wait for VirtOS v1.0** before migrating production systems
- ✅ **Start testing now** with non-critical VMs
- ✅ **Contribute feedback** to help reach v1.0 faster

**When VirtOS v1.0 releases** (Q1 2027):
- Re-evaluate this migration guide
- Check production readiness status
- Start with test migrations
- Proceed to production if suitable

**Remember**: There's no rush. Proxmox is mature and stable. Migrate when VirtOS meets your requirements, not before.

---

**Migration Guide Version**: 1.0 (Draft)  
**Last Updated**: 2026-05-28  
**Target VirtOS Version**: 1.0+ (unreleased)  
**Status**: Planning/Evaluation Only
