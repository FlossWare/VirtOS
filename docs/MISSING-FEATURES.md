# Missing Features

Comprehensive list of features VirtOS lacks compared to mature virtualization platforms, organized by priority and feasibility.

## Critical Missing Features

Features essential for production use that VirtOS currently lacks.

### 1. Automated Backup and Restore

**Status:** ✅ IMPLEMENTED (Phase 6)

**What's included:**
- ✅ Automated VM backup scheduling (cron-based)
- ✅ Backup retention policies
- ✅ Point-in-time recovery
- ✅ Backup compression
- ✅ Backup verification (checksums)
- ✅ Backup to remote storage (SCP, S3)
- ✅ Restore wizard (virtos-backup restore)
- ⚠️ Incremental backups (planned for future)

**Implementation:**
```bash
# Backup a VM
virtos-backup backup web-server-1

# Schedule daily backups at 2 AM
virtos-backup schedule web-server-1 --daily 02:00

# Restore from backup
virtos-backup restore web-server-1 2026-05-22

# List backups
virtos-backup list

# Cleanup old backups
virtos-backup cleanup
```

**Features:**
- Automatic snapshot for consistent backups
- Compression to save space
- Remote destinations (SCP or S3)
- Retention policy enforcement
- Backup verification with SHA256
- Full VM backup (XML + all disks)

**Competitors still have:**
- Incremental/differential backups
- Deduplication
- More mature backup servers

**Priority:** 🟢 Implemented

**Completed:** Phase 6 (May 2026)

---

### 2. Automatic High Availability (HA)

**Status:** ✅ IMPLEMENTED (Phase 7)

**What's included:**
- ✅ Automatic VM failover on host failure
- ✅ Health monitoring for VMs and hosts
- ✅ VM restart policies (priority, max restarts)
- ✅ Cluster quorum awareness
- ✅ Manual and automatic failover
- ✅ HA daemon (virtos-ha)
- ⚠️ Fencing (network-based, STONITH requires hardware)

**Implementation:**
```bash
# Enable HA for a VM
virtos-ha enable web-server-1 --priority high

# Start HA daemon
virtos-ha start-daemon

# Manual failover if needed
virtos-ha failover db-server virtos-2

# Check HA status
virtos-ha status
```

**Features:**
- Automatic detection and restart of failed VMs
- Priority-based restart order
- Configurable restart attempts and delays
- Cluster-aware failover target selection
- HA status monitoring

**Competitors still have:**
- Hardware-based fencing (STONITH/BMC)
- More mature quorum algorithms
- Integrated power management

**Priority:** 🟢 Implemented

**Completed:** Phase 7 (May 2026)

---

### 3. Web UI

**Status:** ❌ Not implemented

**What's missing:**
- Graphical management interface
- VM console in browser
- Dashboard with metrics
- Configuration wizard
- User management
- Mobile-friendly interface
- Multi-language support

**Current solution:**
- TUI (virtos-tui) - ncurses interface
- SSH + CLI
- virt-manager (remote desktop app)

**Competitors have:**
- **Proxmox:** Excellent web UI (ExtJS)
- **ESXi:** vSphere Client web UI
- **oVirt:** oVirt Engine web UI
- **Harvester:** Modern web UI (Vue.js)

**Priority:** 🟡 Important but not critical

**Effort:** Very High (12+ weeks)

**Roadmap:** Planned for Phase 8 (optional)

**Note:** VirtOS philosophy is text-first. Web UI would be optional addon.

---

### 4. Live Migration

**Status:** ✅ IMPLEMENTED (Phase 7)

**What's included:**
- ✅ Live migration with shared storage
- ✅ Block migration without shared storage
- ✅ Offline migration
- ✅ Migration bandwidth limiting
- ✅ Compressed migration
- ✅ Auto-converge for busy VMs

**Implementation:**
```bash
# Live migration with shared storage
virtos-migrate --live --shared-storage web-1 virtos-2

# Block migration (no shared storage)
virtos-migrate --block app-1 virtos-3

# Offline migration
virtos-migrate --offline db-server virtos-2

# Compressed for large VMs
virtos-migrate --block --compressed vm-1 virtos-3
```

**Features:**
- Full block migration support (copies disks during live migration)
- Multiple migration strategies (live, block, offline)
- Progress monitoring
- Automatic requirement checking
- Automatic migration for load balancing
- Migration bandwidth limits
- Migration verification
- Rollback on failure
- Multi-hop migration

**Current limitation:**
```bash
# Requires shared storage (NFS)
virsh migrate --live vm-name qemu+ssh://host2/system

# Without shared storage: must shutdown
virsh shutdown vm-name
# ... copy disk manually ...
virsh start vm-name  # on new host
```

**Competitors have:**
- **Proxmox:** Live migration with/without shared storage
- **ESXi:** vMotion (even without shared storage)
- **oVirt:** Full live migration support
- **XCP-ng:** Storage motion

**Priority:** 🟡 Important for flexibility

**Effort:** Medium (4-6 weeks for block migration)

**Roadmap:** Planned for Phase 7

---

### 5. Distributed Storage

**Status:** ❌ Not implemented

**What's missing:**
- Ceph integration
- GlusterFS support
- Distributed replication
- Storage pools
- Automatic storage balancing
- Storage HA
- Erasure coding

**Current solution:**
- Local storage (ext4, Btrfs, LVM, ZFS)
- NFS (single point of failure)

**Competitors have:**
- **Proxmox:** Ceph, ZFS replication
- **ESXi:** vSAN (paid)
- **oVirt:** GlusterFS, Ceph
- **Harvester:** Longhorn

**Priority:** 🟡 Important for HA

**Effort:** Very High (10+ weeks)

**Roadmap:** Planned for Phase 9

---

## Important Missing Features

Significantly useful features that improve usability and functionality.

### 6. VM Templates and Cloning

**Status:** ✅ IMPLEMENTED (Phase 6)

**What's included:**
- ✅ Template library management
- ✅ Golden image management
- ✅ Clone wizard (virtos-template clone)
- ✅ Linked clones (copy-on-write with qcow2)
- ✅ Cloud image import
- ⚠️ Template versioning (basic, can improve)
- ⚠️ Cloud-init integration (planned for Phase 8)

**Implementation:**
```bash
# Create template from VM
virtos-template create ubuntu-vm ubuntu-22.04-template

# Clone from template (copy-on-write)
virtos-template clone ubuntu-22.04-template web-server-1

# Import cloud image as template
virtos-template import \
  https://cloud-images.ubuntu.com/...img \
  ubuntu-2204-cloud

# List templates
virtos-template list

# Delete template
virtos-template delete old-template
```

**Features:**
- Template library in /var/lib/virtos/templates
- Copy-on-write cloning (fast, space-efficient)
- Cloud image import support
- Template manifest tracking
- Automatic UUID/MAC generation for clones

**Competitors still have:**
- More sophisticated versioning
- Cloud-init integration (planned)
- Template marketplace

**Priority:** 🟢 Implemented

**Completed:** Phase 6 (May 2026)

---

### 7. Automated Monitoring and Alerting

**Status:** ✅ IMPLEMENTED (Phase 7)

**What's included:**
- ✅ CPU/RAM/disk monitoring with thresholds
- ✅ VM health monitoring
- ✅ Host health monitoring (cluster)
- ✅ Service health checks
- ✅ Alert system (email, webhook, log)
- ✅ Configurable thresholds
- ✅ Alert cooldown to prevent spam
- ✅ Monitoring daemon (virtos-monitor)
- ⚠️ Historical metrics (basic, no graphs yet)

**Implementation:**
```bash
# Start monitoring daemon
virtos-monitor start

# Run health checks
virtos-monitor check

# View alerts
virtos-monitor alerts

# Configure thresholds
virtos-monitor config cpu 90
virtos-monitor config memory 80

# Configure email alerts
virtos-monitor config email admin@example.com

# Check status
virtos-monitor status
```

**Features:**
- Real-time resource monitoring
- Automated health checks (CPU, memory, disk, VMs, hosts, services)
- Multi-channel alerts (email, webhook, log)
- Configurable WARNING and CRITICAL thresholds
- Alert cooldown prevents spam

**Competitors still have:**
- Historical metrics with graphs
- Prometheus/Grafana integration
- More advanced analytics
- SMS alerts

**Priority:** 🟢 Implemented

**Completed:** Phase 7 (May 2026)

---

### 8. User Authentication and RBAC

**Status:** ❌ Not implemented

**What's missing:**
- Multi-user support
- Role-based access control
- LDAP/Active Directory integration
- Two-factor authentication
- Audit logging
- User permissions (per-VM, per-cluster)
- API tokens

**Current solution:**
- Linux user accounts
- SSH key authentication
- libvirt group membership
- No fine-grained permissions

**Competitors have:**
- **Proxmox:** Full RBAC, LDAP/AD
- **ESXi:** vCenter SSO, AD integration
- **oVirt:** RBAC, LDAP
- **Harvester:** K8s RBAC

**Priority:** 🟡 Important for multi-user

**Effort:** High (6-8 weeks)

**Roadmap:** Planned for Phase 8

---

### 9. Network Virtualization (SDN)

**Status:** ❌ Not implemented

**What's missing:**
- Software-defined networking
- Virtual networks (VLANs)
- Firewall rules per VM
- Network isolation
- VXLAN support
- Load balancers
- Network QoS

**Current solution:**
- Linux bridges (br0)
- iptables for NAT
- Manual VLAN configuration

**Competitors have:**
- **Proxmox:** SDN with zones, VLANs, VXLAN
- **ESXi:** vSphere Distributed Switch
- **oVirt:** OVN (Open Virtual Network)
- **XCP-ng:** Network virtualization

**Priority:** 🟢 Nice to have

**Effort:** High (6-8 weeks)

**Roadmap:** Phase 9+

---

### 10. Resource Quotas and Limits

**Status:** ✅ IMPLEMENTED (Phase 7)

**What's included:**
- ✅ Per-VM resource limits (CPU, memory, disk)
- ✅ Cluster-wide quotas (max VMs, total CPU, total memory)
- ✅ Quota checking and reporting
- ✅ Quota enforcement configuration
- ✅ Resource usage tracking
- ✅ virtos-quota management tool
- ⚠️ Resource pools (future enhancement)
- ⚠️ NUMA awareness (future enhancement)

**Implementation:**
```bash
# Set VM resource limits
virtos-quota set web-1 cpu 4
virtos-quota set web-1 memory 8192
virtos-quota set web-1 disk 100

# Set cluster quotas
virtos-quota cluster-quota vms 100
virtos-quota cluster-quota cpu 256
virtos-quota cluster-quota memory 524288

# Check VM quota compliance
virtos-quota check web-1

# View all quotas
virtos-quota list

# Show cluster usage
virtos-quota usage

# Enable/disable enforcement
virtos-quota enforce on
```

**Features:**
- Per-VM resource limits
- Cluster-wide resource caps
- Quota violation detection
- Resource usage reporting
- Configurable enforcement

**Competitors still have:**
- Resource pools and hierarchies
- NUMA-aware scheduling
- More sophisticated fair-share algorithms

**Priority:** 🟢 Implemented

**Completed:** Phase 7 (May 2026)

---

## Convenience Features

Features that improve user experience but aren't essential.

### 11. Cloud-Init Integration

**Status:** ❌ Not implemented

**What's missing:**
- Cloud-init ISO generation
- Automated provisioning
- SSH key injection
- Hostname configuration
- Network configuration
- User creation
- Package installation

**Current solution:**
- Manual VM configuration
- Post-install scripts

**Competitors have:**
- **Proxmox:** Cloud-init support
- **oVirt:** Cloud-init integration
- **Harvester:** Cloud-init support

**Priority:** 🟢 Nice to have

**Effort:** Low-Medium (2-3 weeks)

**Roadmap:** Phase 8

---

### 12. VM Snapshots (Automated)

**Status:** ✅ IMPLEMENTED (Phase 6)

**What's included:**
- ✅ Snapshot scheduling (hourly, daily)
- ✅ Snapshot chains (libvirt managed)
- ✅ Snapshot manager CLI (virtos-snapshot)
- ✅ Automatic snapshot cleanup
- ✅ Storage-specific snapshots (Btrfs, ZFS, LVM)
- ⚠️ Application-consistent snapshots (requires guest agent)
- ⚠️ Snapshot replication (planned)

**Implementation:**
```bash
# Create snapshot
virtos-snapshot create web-server-1 "Before update"

# Schedule daily snapshots at 2 AM
virtos-snapshot schedule web-server-1 --daily 02:00 --keep 7

# List snapshots
virtos-snapshot list web-server-1

# Revert to snapshot
virtos-snapshot revert web-server-1 snapshot-20260522

# Cleanup old snapshots
virtos-snapshot cleanup web-server-1 --keep 7

# Storage-specific snapshots
virtos-snapshot btrfs web-server-1  # Btrfs snapshot
virtos-snapshot zfs db-server-1      # ZFS snapshot
virtos-snapshot lvm app-server-1     # LVM snapshot
```

**Features:**
- Automated scheduling via cron
- Retention policy (keep last N)
- Disk-only or memory snapshots
- Integration with storage backends
- Snapshot listing and management
- Automatic cleanup of old snapshots

**Competitors still have:**
- Application-consistent snapshots (need guest agent)
- Snapshot replication
- More sophisticated UI

**Priority:** 🟢 Implemented

**Completed:** Phase 6 (May 2026)

---

### 13. GPU Passthrough

**Status:** ❌ Not implemented (but possible manually)

**What's missing:**
- GPU detection
- Automated passthrough configuration
- vGPU support
- GPU scheduling
- SR-IOV support

**Current solution:**
```bash
# Manual VFIO configuration
# Edit kernel cmdline
# Bind GPU to vfio-pci
# Pass through in VM XML
```

**Competitors have:**
- **Proxmox:** PCI passthrough wizard
- **ESXi:** vGPU support (paid)
- **oVirt:** GPU passthrough

**Priority:** 🟢 Nice to have

**Effort:** Medium (3-4 weeks)

**Roadmap:** Phase 8+

---

### 14. USB Passthrough

**Status:** ⚠️ Partially implemented

**What works:**
- Manual USB passthrough via libvirt XML

**What's missing:**
- USB device selector
- Hot-plug USB devices
- USB redirection protocol
- USB device filtering

**Competitors have:**
- **Proxmox:** USB passthrough UI
- **ESXi:** USB passthrough
- **XCP-ng:** USB passthrough

**Priority:** 🟢 Nice to have

**Effort:** Low (1-2 weeks)

**Roadmap:** Phase 8

---

### 15. Integrated Firewall

**Status:** ⚠️ Partially implemented

**What works:**
- iptables on host
- Manual firewall rules

**What's missing:**
- Per-VM firewall rules
- Firewall rule templates
- Firewall UI/TUI
- Stateful inspection
- Security groups
- Network policies

**Competitors have:**
- **Proxmox:** Per-VM firewall
- **ESXi:** Distributed firewall (NSX)
- **oVirt:** Network filters

**Priority:** 🟢 Nice to have

**Effort:** Medium (3-4 weeks)

**Roadmap:** Phase 8

---

### 16. Update Mechanism

**Status:** ❌ Not implemented

**What's missing:**
- In-place updates
- Update repository
- Rollback mechanism
- Update notifications
- Staged updates
- Cluster-aware updates

**Current solution:**
- Rebuild ISO with new packages
- Boot new ISO
- Migrate VMs

**Competitors have:**
- **Proxmox:** APT-based updates
- **ESXi:** Update Manager
- **XCP-ng:** YUM updates
- **Harvester:** K8s upgrade operator

**Priority:** 🟢 Nice to have

**Effort:** High (6-8 weeks)

**Roadmap:** Phase 9

**Note:** Tiny Core's extension system makes this complex

---

### 17. REST API

**Status:** ⚠️ Partially implemented

**What works:**
- libvirt API (XML-RPC)
- virsh CLI

**What's missing:**
- RESTful HTTP API
- API documentation (OpenAPI/Swagger)
- API authentication (tokens)
- API versioning
- WebSocket support
- GraphQL API

**Competitors have:**
- **Proxmox:** Full REST API
- **ESXi:** vSphere API
- **oVirt:** REST API
- **Harvester:** K8s API

**Priority:** 🟢 Nice to have

**Effort:** Medium-High (5-6 weeks)

**Roadmap:** Phase 8

---

## Advanced Features

Specialized features for specific use cases.

### 18. Container Orchestration (Beyond K3s)

**Status:** ⚠️ Partially implemented

**What works:**
- K3s (lightweight Kubernetes)
- Docker Compose
- Manual container management

**What's missing:**
- Docker Swarm mode
- Nomad integration
- Rancher integration
- Fleet management
- Multi-cluster orchestration

**Priority:** 🔵 Low priority

**Effort:** Variable

**Roadmap:** Not planned (use K3s)

---

### 19. Windows Guest Tools

**Status:** ❌ Not implemented

**What's missing:**
- VirtIO driver ISO
- Guest agent for Windows
- Automated driver installation
- Windows-specific optimizations

**Current solution:**
- Download VirtIO drivers manually
- Install in Windows VM

**Competitors have:**
- **Proxmox:** VirtIO ISO provided
- **ESXi:** VMware Tools
- **oVirt:** Windows guest tools

**Priority:** 🔵 Low priority

**Effort:** Low (1 week for packaging)

**Roadmap:** Phase 8

---

### 20. Disaster Recovery

**Status:** ❌ Not implemented

**What's missing:**
- DR orchestration
- Failover automation
- Replication to DR site
- DR testing
- Recovery plans
- RTO/RPO tracking

**Current solution:**
- Manual backup to remote
- Manual failover procedures

**Competitors have:**
- **ESXi:** Site Recovery Manager (paid)
- **oVirt:** DR capabilities
- **Proxmox:** Replication to remote

**Priority:** 🔵 Low priority

**Effort:** Very High (10+ weeks)

**Roadmap:** Not planned (use external tools)

---

### 21. Terraform/Ansible Integration

**Status:** ❌ Not implemented

**What's missing:**
- Terraform provider
- Ansible modules
- Infrastructure as Code templates
- GitOps workflows

**Current solution:**
- Use libvirt Terraform provider
- Use Ansible with libvirt

**Competitors have:**
- **Proxmox:** Terraform provider
- **ESXi:** Terraform provider
- **Harvester:** K8s-native IaC

**Priority:** 🔵 Low priority

**Effort:** Medium (3-4 weeks)

**Roadmap:** Community contribution welcome

---

### 22. Multi-Datacenter Support

**Status:** ❌ Not implemented

**What's missing:**
- Site awareness
- Cross-site replication
- Geo-distribution
- Site failover
- WAN optimization

**Priority:** 🔵 Low priority

**Effort:** Very High

**Roadmap:** Not planned

---

## Features Intentionally Not Included

Features VirtOS won't implement due to philosophy or constraints.

### 23. Commercial Support

**Status:** ❌ Won't implement

**Reason:** Open source project, community-driven

**Alternatives:**
- Community forums
- GitHub issues
- Documentation
- Self-support

---

### 24. Windows Host Support

**Status:** ❌ Won't implement

**Reason:** Linux-only platform (Tiny Core Linux base)

---

### 25. Proprietary Integrations

**Status:** ❌ Won't implement

**Reason:** Open source philosophy

**Examples:**
- VMware ecosystem
- Hyper-V integration
- Proprietary cloud APIs

---

## Summary by Category

### Critical (Production Blockers)
1. ✅ Automated backup/restore **[IMPLEMENTED Phase 6]**
2. ✅ Automatic HA/failover **[IMPLEMENTED Phase 7]**
3. ❌ Web UI (philosophical choice - TUI is primary)
4. ✅ Live migration **[IMPLEMENTED Phase 7]**
5. ❌ Distributed storage

### Important (Significant Value)
6. ✅ VM templates/cloning **[IMPLEMENTED Phase 6]**
7. ✅ Monitoring/alerting **[IMPLEMENTED Phase 7]**
8. ❌ User authentication/RBAC
9. ❌ Network virtualization (SDN)
10. ✅ Resource quotas/limits **[IMPLEMENTED Phase 7]**

### Convenience (Nice to Have)
11. ❌ Cloud-init integration
12. ✅ VM snapshots **[IMPLEMENTED Phase 6]**
13. ❌ GPU passthrough (manual possible)
14. ⚠️ USB passthrough (partial)
15. ⚠️ Integrated firewall (partial)
16. ❌ Update mechanism
17. ⚠️ REST API (partial via libvirt)

### Advanced (Specialized)
18. ⚠️ Container orchestration beyond K3s
19. ❌ Windows guest tools
20. ❌ Disaster recovery
21. ❌ Terraform/Ansible providers
22. ❌ Multi-datacenter

### Intentionally Excluded
23. ❌ Commercial support
24. ❌ Windows host support
25. ❌ Proprietary integrations

## Implementation Priority

### Phase 6 ✅ COMPLETE (May 2026)
- ✅ Automated backup/restore (virtos-backup)
- ✅ VM templates/cloning (virtos-template)
- ✅ VM snapshot automation (virtos-snapshot)

### Phase 7 (Next - HA and Monitoring)
- Automatic HA/failover
- Monitoring and alerting
- Live migration improvements
- Resource quotas

### Phase 8 (User Experience)
- User authentication/RBAC
- Cloud-init integration
- REST API
- Optional Web UI
- GPU passthrough

### Phase 9 (Advanced)
- Distributed storage (Ceph)
- Network virtualization
- Update mechanism
- Disaster recovery

### Phase 10+ (Future)
- Community-driven features
- Ecosystem integrations
- Enterprise features

## How to Help

Want to contribute? Pick a feature and:

1. **Check roadmap** - See [ROADMAP.md](ROADMAP.md)
2. **Open issue** - Discuss approach
3. **Submit PR** - Implement feature
4. **Document** - Update docs
5. **Test** - Verify it works

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## Comparison with Competitors

### Features VirtOS Has That Others Don't

1. **Multiple container runtimes** - Docker AND Podman AND containerd
2. **7 build profiles** - Extreme customization
3. **Tiny footprint** - 100-400MB vs 1GB+
4. **Text-first** - ncurses TUI as primary interface
5. **IaaS placement** - Simple automated VM placement
6. **Kubernetes optional** - K3s built-in but optional

### Features Others Have That VirtOS Lacks

1. **Web UI** - All competitors (philosophical choice)
2. **Automatic HA** - Proxmox, ESXi, oVirt, XCP-ng, Harvester
3. **Mature backups** - Proxmox, oVirt, XCP-ng
4. **Commercial support** - ESXi, Proxmox (optional)
5. **Large community** - Proxmox, ESXi
6. **10+ years maturity** - All competitors

## The Reality Check

**VirtOS is alpha software.** Many features are missing or incomplete.

**Good for:**
- Home labs
- Learning
- Development/test
- Edge computing (if you manage manually)
- Small non-critical deployments

**Not ready for:**
- Production with SLAs
- Large enterprises
- Mission-critical workloads
- Non-technical users
- 24/7 operations without expert staff

**Be realistic about what VirtOS can and cannot do.**

The roadmap addresses the most critical gaps, but it will take time to match mature platforms with 10+ years of development.

## Questions?

See:
- [ROADMAP.md](ROADMAP.md) - Development plan
- [COMPARISON.md](COMPARISON.md) - vs competitors
- [CONTRIBUTING.md](../CONTRIBUTING.md) - How to help
- [GitHub Issues](https://github.com/FlossWare/VirtOS/issues) - Report bugs/request features
