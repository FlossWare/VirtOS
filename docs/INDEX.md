# VirtOS Documentation Index

Complete documentation for FlossWare VirtOS.

## Quick Start

- **[README.md](../README.md)** - Project overview and quick start
- **[GETTING-STARTED.md](GETTING-STARTED.md)** - Build your first VirtOS ISO
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Command cheat sheet

## Core Documentation

### System Design
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - 7-layer system design and components
- **[PACKAGES.md](PACKAGES.md)** - Required packages and size estimates
- **[ROADMAP.md](ROADMAP.md)** - Development phases and status

### Configuration
- **[CONFIGURATION.md](CONFIGURATION.md)** - 30+ configuration options
- **[PROFILES.md](PROFILES.md)** - 7 build profiles comparison
- **[BRANDING.md](BRANDING.md)** - VirtOS naming and branding
- **[STORAGE.md](STORAGE.md)** - Storage options and filesystems

## Virtualization Technologies

### VMs and Containers
- **[CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md)** - Docker vs Podman vs containerd
- **[KUBERNETES.md](KUBERNETES.md)** - K3s orchestration (optional)
- **[MICROSERVICES.md](MICROSERVICES.md)** - Deploying microservices on VirtOS

## Multi-Host Features

- **[CLUSTERING.md](CLUSTERING.md)** - Multi-host discovery and coordination
- **[IAAS.md](IAAS.md)** - Automated VM placement and scheduling
- **[REMOTE-ACCESS.md](REMOTE-ACCESS.md)** - virt-manager and SSH setup

## User Interface

- **[TUI.md](TUI.md)** - Text user interface (ncurses setup wizard and management console)

## Reference

- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - All commands in one place
- **[COMPARISON.md](COMPARISON.md)** - VirtOS vs similar projects (Proxmox, ESXi, etc.)
- **[MISSING-FEATURES.md](MISSING-FEATURES.md)** - What VirtOS lacks (honest assessment)
- **[CONTRIBUTING.md](../CONTRIBUTING.md)** - How to contribute

## Documentation by Use Case

### I want to...

#### Build VirtOS
1. [GETTING-STARTED.md](GETTING-STARTED.md) - Initial setup
2. [PROFILES.md](PROFILES.md) - Choose a profile
3. [CONFIGURATION.md](CONFIGURATION.md) - Customize build

#### Run Virtual Machines
1. [GETTING-STARTED.md](GETTING-STARTED.md) - Boot VirtOS
2. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - KVM/QEMU commands
3. [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - Use virt-manager
4. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Backup, templates, snapshots

#### Run Containers
1. [CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md) - Choose runtime
2. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Container commands
3. [KUBERNETES.md](KUBERNETES.md) - Add orchestration (optional)

#### Set Up Multiple Hosts
1. [CLUSTERING.md](CLUSTERING.md) - Multi-host setup
2. [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - Remote management
3. [KUBERNETES.md](KUBERNETES.md) - K3s cluster (optional)

#### Manage Remotely
1. [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - SSH and virt-manager setup
2. [CLUSTERING.md](CLUSTERING.md) - virtos-cluster commands
3. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - All commands

#### Deploy Microservices
1. [MICROSERVICES.md](MICROSERVICES.md) - Complete microservices guide
2. [CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md) - Choose runtime
3. [CLUSTERING.md](CLUSTERING.md) - Set up cluster
4. [KUBERNETES.md](KUBERNETES.md) - Deploy with K3s

#### Use IaaS Automation
1. [CLUSTERING.md](CLUSTERING.md) - Set up multi-host cluster
2. [IAAS.md](IAAS.md) - Enable automated placement
3. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - virtos-create-vm commands

#### Configure VirtOS (First Boot)
1. [TUI.md](TUI.md) - Run virtos-setup wizard
2. [STORAGE.md](STORAGE.md) - Choose filesystem (if advanced storage)
3. [CLUSTERING.md](CLUSTERING.md) - Join cluster (if multi-host)

#### Manage VirtOS (Daily)
1. [TUI.md](TUI.md) - Use virtos-tui management console
2. [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - SSH access
3. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - CLI commands

#### Configure Advanced Storage
1. [STORAGE.md](STORAGE.md) - Choose filesystem (Btrfs/LVM/ZFS)
2. [PROFILES.md](PROFILES.md) - Use storage profile
3. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Storage commands

#### Backup and Protect VMs
1. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - virtos-backup commands
2. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - virtos-snapshot commands
3. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - virtos-template commands

## Documentation by Profile

### Minimal Profile
- [PROFILES.md](PROFILES.md#minimal-profile)
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - KVM commands
- Minimal docs needed - it's simple!

### Standard Profile (Default)
- [PROFILES.md](PROFILES.md#standard-profile-default)
- [CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md) - All 3 runtimes
- [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - libvirt management

### Full Profile
- [PROFILES.md](PROFILES.md#full-profile)
- All documentation applies!

### Containers Profile
- [PROFILES.md](PROFILES.md#containers-profile)
- [CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md)
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Container commands

### Developer Profile
- [PROFILES.md](PROFILES.md#developer-profile)
- [CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md)
- [KUBERNETES.md](KUBERNETES.md)

### Kubernetes Profile
- [PROFILES.md](PROFILES.md#kubernetes-profile)
- [KUBERNETES.md](KUBERNETES.md) - Complete K3s guide
- [CLUSTERING.md](CLUSTERING.md) - Multi-node setup

### Storage Profile
- [PROFILES.md](PROFILES.md#storage-profile)
- [STORAGE.md](STORAGE.md) - Complete storage guide
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Storage commands

## Feature Matrix

| Feature | Documentation |
|---------|---------------|
| KVM/QEMU VMs | QUICK-REFERENCE.md, GETTING-STARTED.md |
| LXC Containers | QUICK-REFERENCE.md |
| Docker | CONTAINER-RUNTIMES.md, QUICK-REFERENCE.md |
| Podman | CONTAINER-RUNTIMES.md, QUICK-REFERENCE.md |
| containerd | CONTAINER-RUNTIMES.md, QUICK-REFERENCE.md |
| K3s/Kubernetes | KUBERNETES.md |
| Microservices | MICROSERVICES.md |
| libvirt | REMOTE-ACCESS.md, QUICK-REFERENCE.md |
| virt-manager | REMOTE-ACCESS.md |
| Clustering | CLUSTERING.md |
| IaaS Placement | IAAS.md |
| Remote Access | REMOTE-ACCESS.md |
| Storage (Btrfs/LVM/ZFS/NFS) | STORAGE.md, QUICK-REFERENCE.md |
| Text UI (ncurses) | TUI.md |
| Build Profiles | PROFILES.md |
| Configuration | CONFIGURATION.md |
| Backup & Restore | QUICK-REFERENCE.md (virtos-backup) |
| VM Templates | QUICK-REFERENCE.md (virtos-template) |
| Snapshots | QUICK-REFERENCE.md (virtos-snapshot) |
| Monitoring & Alerts | QUICK-REFERENCE.md (virtos-monitor) |
| High Availability | QUICK-REFERENCE.md (virtos-ha) |
| Live Migration | QUICK-REFERENCE.md (virtos-migrate) |
| Resource Quotas | QUICK-REFERENCE.md (virtos-quota) |
| Authentication/RBAC | QUICK-REFERENCE.md (virtos-auth) |
| Cloud-init | QUICK-REFERENCE.md (virtos-cloud-init) |
| REST API | QUICK-REFERENCE.md (virtos-api) |
| System Updates | QUICK-REFERENCE.md (virtos-update) |
| Disaster Recovery | QUICK-REFERENCE.md (virtos-dr) |
| Distributed Storage | QUICK-REFERENCE.md (virtos-storage) |
| Network Virtualization | QUICK-REFERENCE.md (virtos-network) |
| GPU Passthrough | QUICK-REFERENCE.md (virtos-gpu) |
| USB Device Management | QUICK-REFERENCE.md (virtos-usb) |

## Total Documentation

- **19 Documentation Files**
- **13,000+ Lines**
- **Complete and Honest Coverage** - including what's missing
- **Phase 9 Complete** - Distributed storage, network virtualization, GPU/USB passthrough (May 2026)

## Getting Help

1. Check relevant documentation above
2. See [QUICK-REFERENCE.md](QUICK-REFERENCE.md) for commands
3. Review [ROADMAP.md](ROADMAP.md) for feature status
4. Open issue: https://github.com/FlossWare/VirtOS/issues

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for:
- How to contribute code
- Documentation improvements
- Bug reports
- Feature requests
