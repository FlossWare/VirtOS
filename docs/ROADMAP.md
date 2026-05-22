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

## Phase 6: Advanced Features

**Goal**: Enhanced capabilities

### Optional features (priority TBD):
- [ ] Web-based UI (Cockpit/Portainer)
- [ ] Advanced networking (OVS, VLANs)
- [ ] GPU passthrough support
- [ ] USB passthrough
- [ ] Live migration (if clustered)
- [ ] Snapshot management
- [ ] Template library
- [ ] Automated updates
- [ ] Clustering support (future)
- [ ] Additional hypervisors (Xen, VirtualBox)

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

**Phase**: Planning / Phase 1 kickoff

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

### MVP (End of Phase 3)
- Boots in < 10 seconds
- Can run KVM VMs
- Can run LXC containers
- Can run OCI containers
- Network connectivity works
- Basic documentation exists

### Production Ready (End of Phase 5)
- Installation guide
- Persistent configuration
- Reliable boot
- User-friendly management
- Complete documentation

### Feature Complete (End of Phase 6+)
- Web UI
- Advanced networking
- Hardware passthrough
- Enterprise features
