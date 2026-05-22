# Development Roadmap

## Phase 1: Foundation (MVP)

**Goal**: Bootable Tiny Core system with basic KVM support

### Tasks
- [ ] Set up build environment
- [ ] Create custom kernel config with KVM support
- [ ] Build minimal Tiny Core ISO with KVM modules
- [ ] Test KVM module loading (`/dev/kvm` present)
- [ ] Basic QEMU installation
- [ ] Create simple VM via `qemu-system-x86_64`
- [ ] Network bridge setup (br0)
- [ ] Basic networking for VMs (NAT)

**Deliverable**: ISO that boots and can run a simple KVM VM

## Phase 2: LXC Support

**Goal**: Add system container capabilities

### Tasks
- [ ] Integrate LXC packages
- [ ] Configure cgroups and namespaces
- [ ] Build LXC tools
- [ ] Create LXC bridge (lxcbr0)
- [ ] Test basic LXC container creation
- [ ] LXC templates for common distros
- [ ] Container persistence strategy

**Deliverable**: System that runs both KVM VMs and LXC containers

## Phase 3: OCI Container Support

**Goal**: Add Docker/Podman compatible containers

### Tasks
- [ ] Choose container runtime (containerd vs Docker vs Podman)
- [ ] Integrate container runtime
- [ ] Configure container networking (CNI)
- [ ] Test Docker image pulling
- [ ] Test container creation and execution
- [ ] Container storage configuration
- [ ] Integration with existing networking

**Deliverable**: Full support for KVM, LXC, and OCI containers

## Phase 4: Management Layer

**Goal**: Unified management interface

### Tasks
- [ ] Decide on management approach (libvirt vs custom)
- [ ] Integrate libvirt (if chosen)
- [ ] Create CLI tools for common operations
- [ ] Network management scripts
- [ ] Storage management scripts
- [ ] Basic monitoring capabilities
- [ ] Logging configuration

**Deliverable**: Easy-to-use management interface for all virtualization types

## Phase 5: Persistence & Boot Optimization

**Goal**: Production-ready boot and storage

### Tasks
- [ ] Implement frugal install
- [ ] Persistent storage for VM/container data
- [ ] Extension loading optimization
- [ ] Boot time optimization
- [ ] Configuration persistence
- [ ] Backup/restore functionality

**Deliverable**: Fast-booting, production-ready system

## Phase 6: Production Readiness ✅ COMPLETE

**Goal**: Basic production features

### Completed (May 2026):
- [x] Clustering support (auto-discovery, virtos-cluster tool)
- [x] Remote management (virt-manager, SSH, libvirt)
- [x] Kubernetes orchestration (K3s)
- [x] Multiple container runtimes (Docker, Podman, containerd)
- [x] IaaS automated VM placement (virtos-create-vm)
- [x] **Automated backup/restore (virtos-backup)** 🎉
- [x] **VM template library (virtos-template)** 🎉
- [x] **Snapshot management (virtos-snapshot)** 🎉
- [x] Text UI (virtos-setup, virtos-tui)
- [x] Comprehensive documentation (19 files, 11,500+ lines)

**Status**: All Phase 6 goals achieved!

## Phase 7: HA and Monitoring ✅ COMPLETE

**Goal**: High availability, monitoring, and resource management

### Completed (May 2026):
- [x] **Automated monitoring and alerting (virtos-monitor)** 🎉
- [x] **Automatic HA / failover (virtos-ha)** 🎉
- [x] **Live VM migration improvements (virtos-migrate)** 🎉
- [x] **Resource quotas and limits (virtos-quota)** 🎉
- [ ] Web-based UI (optional, deferred - TUI is excellent)

**Status**: All Phase 7 core goals achieved!

### Phase 8 Goals (Next - Polish and Integration):
- [ ] Web-based UI (Cockpit or custom)
- [ ] User authentication / RBAC
- [ ] Cloud-init integration
- [ ] REST API
- [ ] Automated updates
- [ ] Enhanced disaster recovery

### Future Phases (Phase 9+):
- [ ] Distributed storage (Ceph/GlusterFS)
- [ ] Advanced networking (SDN, OVS, VLANs)
- [ ] GPU passthrough wizard
- [ ] Multi-datacenter support
- [ ] Metrics and telemetry
- [ ] Cost management and billing

## Phase 7: Distribution & Documentation

**Goal**: Release-ready

### Tasks
- [ ] Comprehensive documentation
- [ ] Installation guides
- [ ] User tutorials
- [ ] Example configurations
- [ ] Troubleshooting guide
- [ ] Release ISO builds
- [ ] Project website
- [ ] Community channels

## Current Status

**Phase**: Phase 7 Complete!

✅ **Completed**:
- Phase 1: KVM support (DONE)
- Phase 2: LXC support (DONE)
- Phase 3: All OCI container runtimes (DONE)
- Phase 4: Management layer (libvirt, clustering, remote access) (DONE)
- Phase 5: Persistence & boot optimization (DONE)
- Phase 6: Backup, templates, snapshots (DONE)
- **Phase 7: HA, monitoring, migration, quotas (DONE)**
- Bonus: Kubernetes (K3s) support (DONE)

🚧 **In Progress**:
- Phase 8: Polish and integration (next)
- Documentation & distribution (ongoing)

## Quick Start Path (Recommended)

For rapid initial development:

1. **Week 1-2**: Get basic Tiny Core + KVM working
   - Download Tiny Core
   - Boot in VM
   - Load KVM modules
   - Run test VM

2. **Week 3-4**: Add LXC
   - Build LXC extensions
   - Test containers
   - Network integration

3. **Week 5-6**: Add container runtime
   - Integrate containerd
   - Test Docker images
   - Cross-platform testing

4. **Week 7-8**: Management polish
   - Scripts for common tasks
   - Documentation
   - Testing

## Success Criteria

### ✅ MVP (Phase 3) - ACHIEVED
- ✅ Boots in < 10 seconds
- ✅ Can run KVM VMs
- ✅ Can run LXC containers
- ✅ Can run OCI containers (Docker, Podman, containerd)
- ✅ Network connectivity works (NAT enabled)
- ✅ Basic documentation exists

### ✅ Production Ready (Phase 5) - ACHIEVED
- ✅ Installation guide (GETTING-STARTED.md)
- ✅ Persistent configuration (build.conf, profiles)
- ✅ Reliable boot (bootlocal.sh, sysctl.conf)
- ✅ User-friendly management (libvirt, virt-manager, virtos-cluster)
- ✅ Complete documentation (12 comprehensive guides)
- ✅ Remote access (SSH, virt-manager)
- ✅ Clustering (multi-host discovery and coordination)

### 🎯 Feature Complete (Phase 6+) - PARTIAL
- ✅ Kubernetes orchestration (K3s)
- ✅ Multi-host clustering
- ✅ Remote management
- ✅ Container orchestration
- [ ] Web UI (Cockpit/Portainer)
- [ ] Advanced networking (OVS)
- [ ] Hardware passthrough (GPU/USB)
- [ ] Live migration
- [ ] High availability
