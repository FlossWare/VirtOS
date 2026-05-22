# Missing Features

Comprehensive list of features VirtOS lacks compared to mature virtualization platforms, organized by priority and feasibility.

## Critical Missing Features

Features essential for production use that VirtOS currently lacks.

### 1. Automated Backup and Restore

**Status:** ❌ Not implemented

**What's missing:**
- Automated VM backup scheduling
- Incremental backups
- Backup retention policies
- Point-in-time recovery
- Backup compression
- Backup verification
- Backup to remote storage
- Restore wizard

**Current workaround:**
```bash
# Manual backup
virsh dumpxml vm-name > vm-name.xml
qemu-img convert vm-disk.qcow2 vm-disk-backup.qcow2

# Manual restore
virsh define vm-name.xml
cp vm-disk-backup.qcow2 vm-disk.qcow2
```

**Competitors have:**
- **Proxmox:** Proxmox Backup Server, integrated backups
- **ESXi:** vSphere Data Protection (paid)
- **oVirt:** Integrated backup via API
- **XCP-ng:** Xen Orchestra backups

**Priority:** 🔴 Critical for production

**Effort:** Medium (3-4 weeks)

**Roadmap:** Planned for Phase 6

---

### 2. Automatic High Availability (HA)

**Status:** ❌ Not implemented (manual only)

**What's missing:**
- Automatic VM failover
- Health monitoring
- Fencing (STONITH)
- Resource constraints
- HA policies (which VMs are critical)
- Quorum handling
- Split-brain prevention

**Current workaround:**
```bash
# Manual failover
# On failed host:
virsh shutdown vm-name

# On backup host:
virsh start vm-name
```

**Competitors have:**
- **Proxmox:** Automatic HA with resource manager
- **ESXi:** vSphere HA (paid)
- **oVirt:** Full HA with power management
- **XCP-ng:** HA with Xen Orchestra

**Priority:** 🔴 Critical for production

**Effort:** High (6-8 weeks)

**Roadmap:** Planned for Phase 7

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

**Status:** ⚠️ Partially implemented

**What works:**
- Live migration with shared storage (NFS)

**What's missing:**
- Live migration without shared storage (block migration)
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

**Status:** ⚠️ Partially implemented

**What works:**
- Manual VM cloning via `qemu-img`
- Btrfs/ZFS snapshots for quick clones

**What's missing:**
- Template library
- Golden image management
- Clone wizard
- Linked clones (copy-on-write)
- Template versioning
- Cloud images (cloud-init)

**Current workaround:**
```bash
# Manual clone
qemu-img create -f qcow2 -b base-vm.qcow2 clone-vm.qcow2
virsh dumpxml base-vm > clone-vm.xml
# Edit clone-vm.xml (change name, UUID, MAC)
virsh define clone-vm.xml
```

**Competitors have:**
- **Proxmox:** Template system, clone wizard
- **ESXi:** Template library, content library
- **oVirt:** Template management
- **XCP-ng:** Template VMs

**Priority:** 🟡 Important for efficiency

**Effort:** Low-Medium (2-3 weeks)

**Roadmap:** Planned for Phase 6

---

### 7. Automated Monitoring and Alerting

**Status:** ❌ Not implemented

**What's missing:**
- CPU/RAM/disk monitoring
- Historical metrics
- Performance graphs
- Alert rules (email, SMS, webhook)
- Threshold alerts
- Log aggregation
- Metric export (Prometheus)

**Current solution:**
- virtos-tui shows current stats
- Manual monitoring via `top`, `htop`, `virsh`

**Competitors have:**
- **Proxmox:** Built-in graphs, email alerts
- **ESXi:** vCenter monitoring
- **oVirt:** Metrics and alerts
- **Harvester:** Prometheus + Grafana

**Priority:** 🟡 Important for operations

**Effort:** Medium (4-5 weeks)

**Roadmap:** Planned for Phase 7

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

**Status:** ⚠️ Partially implemented

**What works:**
- CPU/RAM limits via libvirt XML
- cgroups for containers

**What's missing:**
- Quota enforcement
- Resource reservations
- Resource pools
- Fair share scheduling
- CPU pinning GUI/TUI
- NUMA awareness
- Resource overcommit policies

**Current workaround:**
```bash
# Manual CPU/RAM limits in VM XML
<vcpu>4</vcpu>
<memory unit='GB'>8</memory>
```

**Competitors have:**
- **Proxmox:** Resource limits, pools
- **ESXi:** Resource pools, reservations, limits
- **oVirt:** Quota management
- **Harvester:** K8s resource quotas

**Priority:** 🟢 Nice to have

**Effort:** Medium (3-4 weeks)

**Roadmap:** Phase 7

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

**Status:** ⚠️ Partially implemented

**What works:**
- Storage snapshots (Btrfs, ZFS, LVM)
- Manual `virsh snapshot-create`

**What's missing:**
- Snapshot scheduling
- Snapshot chains
- Snapshot manager UI/TUI
- Automatic snapshot cleanup
- Application-consistent snapshots
- Snapshot replication

**Competitors have:**
- **Proxmox:** Snapshot management
- **ESXi:** Snapshot manager
- **oVirt:** Snapshot workflows

**Priority:** 🟢 Nice to have

**Effort:** Low (1-2 weeks)

**Roadmap:** Phase 6

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
1. ❌ Automated backup/restore
2. ❌ Automatic HA/failover
3. ❌ Web UI (philosophical choice - TUI is primary)
4. ⚠️ Live migration (partial - needs work)
5. ❌ Distributed storage

### Important (Significant Value)
6. ⚠️ VM templates/cloning (partial)
7. ❌ Monitoring/alerting
8. ❌ User authentication/RBAC
9. ❌ Network virtualization (SDN)
10. ⚠️ Resource quotas/limits (partial)

### Convenience (Nice to Have)
11. ❌ Cloud-init integration
12. ⚠️ VM snapshots (partial)
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

### Phase 6 (Next - Basic Production)
- Automated backup/restore
- VM templates/cloning
- VM snapshot automation

### Phase 7 (HA and Monitoring)
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
