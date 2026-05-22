# FlossWare VirtOS

A minimal, purpose-built virtualization operating system based on Tiny Core Linux.

## Overview

FlossWare VirtOS is designed to be a lightweight, efficient hypervisor platform supporting multiple virtualization technologies:

- **KVM/QEMU** - Full hardware virtualization
- **LXC** - System containers (lightweight VMs)
- **Containers** - Docker, Podman, and containerd (all optional, you choose!)
- **Modular** - Everything is choosable, nothing is forced
- **Extensible** - Support for additional virtualization technologies

## Philosophy

Built on Tiny Core Linux principles:
- **Minimal** - Only include what's necessary
- **Modular** - Extensions loaded on-demand
- **Fast** - Quick boot times, low overhead
- **Flexible** - Customize for your exact needs

## Architecture

```
┌─────────────────────────────────────────┐
│         Management Layer                │
│  (libvirt, CLI tools, optional web UI)  │
├─────────────────────────────────────────┤
│      Virtualization Runtimes            │
│  ┌──────┐  ┌──────┐  ┌──────────┐     │
│  │ QEMU │  │ LXC  │  │Container │     │
│  │ KVM  │  │      │  │ Runtime  │     │
│  └──────┘  └──────┘  └──────────┘     │
├─────────────────────────────────────────┤
│         Linux Kernel + Modules          │
│   (KVM, namespaces, cgroups, vhost)    │
├─────────────────────────────────────────┤
│       Tiny Core Linux Base              │
└─────────────────────────────────────────┘
```

## Project Structure

```
virtualization/
├── build/              # Build scripts and tools
├── packages/           # Custom TCZ extensions
├── config/             # System configurations
├── kernel/             # Kernel config and patches
├── docs/               # Documentation
└── iso/                # ISO build output
```

## Getting Started

### Quick Build

```bash
# 1. Clone repository
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS

# 2. Choose a profile (optional, edit build/build.conf)
# Available: minimal, standard, full, containers, developer
# Default: standard (~200MB with Docker, Podman, containerd)

# 3. Build
cd build/scripts
./build-all.sh

# 4. Test
qemu-system-x86_64 -enable-kvm -m 2048 \
    -cdrom ../output/FlossWare-Virt-*.iso
```

### First-Time Setup

**Interactive setup wizard (ncurses TUI):**
```bash
# Boot VirtOS, then run:
sudo virtos-setup
```

**Setup wizard configures:**
- Hostname and networking (DHCP or static IP)
- Storage for VMs (ext4, Btrfs, LVM, ZFS)
- Clustering (optional multi-host)
- Services to auto-start
- Admin user for remote access

**Takes 5-10 minutes.** See [docs/TUI.md](docs/TUI.md) for details.

### Management Console

**Text-based management interface (ncurses TUI):**
```bash
virtos-tui
```

**Features:**
- System monitoring (CPU, RAM, disk)
- VM management (start, stop, console)
- Container management (Docker, Podman, LXC)
- Storage administration (Btrfs, LVM, ZFS, NFS)
- Cluster status
- Service control
- System logs

**Perfect for remote SSH management.** See [docs/TUI.md](docs/TUI.md) for full guide.

### Profiles

| Profile | Size | What's Included |
|---------|------|-----------------|
| **minimal** | ~100MB | KVM + containerd only |
| **standard** | ~200MB | KVM + LXC + All 3 container runtimes (default) |
| **full** | ~400MB | Everything |
| **containers** | ~150MB | All container runtimes + minimal VMs |
| **developer** | ~250MB | All runtimes + dev tools |
| **kubernetes** | ~250MB | K3s + all runtimes + clustering |
| **storage** | ~350MB | Btrfs + LVM + ZFS + NFS (4GB+ RAM) |

See [docs/PROFILES.md](docs/PROFILES.md) for details.

### Remote Management

**Connect with virt-manager from your desktop:**
```bash
virt-manager -c qemu+ssh://vmadmin@virtos/system
```

VirtOS includes SSH and libvirt for remote management. See [docs/REMOTE-ACCESS.md](docs/REMOTE-ACCESS.md) for setup.

### Clustering

**Run multiple VirtOS instances that discover each other:**
```bash
# On any VirtOS host
virtos-cluster list

# Shows all VirtOS instances on your network:
# virtos-1  192.168.1.101  up  4 VMs
# virtos-2  192.168.1.102  up  2 VMs
# virtos-3  192.168.1.103  up  1 VM
```

Automatic discovery via mDNS/Avahi - hosts appear as `virtos-X.local`. See [docs/CLUSTERING.md](docs/CLUSTERING.md) for multi-host setup.

### Kubernetes (Optional)

**Deploy K3s across your VirtOS cluster:**
```bash
# On virtos-1
curl -sfL https://get.k3s.io | sh -

# On virtos-2, virtos-3
curl -sfL https://get.k3s.io | K3S_URL=https://virtos-1.local:6443 \
  K3S_TOKEN=<token> sh -

# Deploy apps across cluster
sudo k3s kubectl create deployment nginx --image=nginx --replicas=6
```

K3s provides orchestration, auto-scaling, and self-healing for containers. See [docs/KUBERNETES.md](docs/KUBERNETES.md) for complete setup.

### IaaS - Automated VM Placement

**Request VMs and let the cluster decide where to run them:**
```bash
# Just specify what you need - no manual host selection!
virtos-create-vm \
  --name myapp \
  --cpu 4 \
  --ram 8192 \
  --disk 50G

# System analyzes cluster and responds:
# "Best host: virtos-3 (94% fit score)"
# VM created on optimal host automatically
```

Infrastructure as a Service - simplified! See [docs/IAAS.md](docs/IAAS.md) for automated placement, scheduling policies, and resource management.

### Customization

**Everything is choosable!** Edit `build/build.conf`:

```bash
INCLUDE_DOCKER="yes"       # Docker
INCLUDE_PODMAN="yes"       # Podman  
INCLUDE_CONTAINERD="yes"   # containerd
INCLUDE_KVM="yes"          # KVM/QEMU
INCLUDE_LXC="yes"          # LXC
# ... 30+ options available
```

Or use a profile as starting point. See [docs/PROFILES.md](docs/PROFILES.md).

## How Does VirtOS Compare?

**vs Proxmox, ESXi, oVirt, XCP-ng, Harvester, etc.**

VirtOS occupies a unique niche:
- **Smaller** - 100-400MB vs 1GB+ for most alternatives
- **Faster** - <10s boot vs 30-120s for others
- **More flexible** - Choose only what you need (7 profiles)
- **Container-friendly** - Docker, Podman, containerd, LXC, K8s
- **Text-first** - TUI works great over SSH, no web overhead

**Trade-offs:**
- Less mature (new project vs 10+ years)
- No web UI (terminal/SSH only)
- Smaller community
- Manual HA (no automatic failover yet)

**Best for:** Home labs, edge computing, learning, cost-sensitive projects, terminal users

**Not ready for:** Large enterprises needing commercial support, mature HA, or web UI

See [docs/COMPARISON.md](docs/COMPARISON.md) for detailed comparison with 6 major platforms.

## What's Missing?

**VirtOS is alpha software.** Many features found in mature platforms are missing or incomplete:

**Critical gaps:**
- ✅ Automated backup/restore (virtos-backup - Phase 6)
- ✅ Automatic HA/failover (virtos-ha - Phase 7)
- ❌ Web UI (by design - TUI only)
- ✅ Live migration (virtos-migrate - Phase 7)
- ❌ Distributed storage (Ceph/GlusterFS)

**Important gaps:**
- ✅ Monitoring and alerting (virtos-monitor - Phase 7)
- ❌ User authentication/RBAC
- ✅ VM templates & snapshots (virtos-template, virtos-snapshot - Phase 6)
- ✅ Resource quotas (virtos-quota - Phase 7)
- ❌ REST API (basic via libvirt)

**VirtOS is good for:** Home labs, learning, edge computing, dev/test  
**VirtOS is NOT ready for:** Production with SLAs, mission-critical workloads, large enterprises

See [docs/MISSING-FEATURES.md](docs/MISSING-FEATURES.md) for complete list and roadmap.

**Being honest:** It will take years to match platforms with 10+ years of development. But VirtOS offers unique advantages (size, flexibility, container support) that may matter more for your use case.

## License

TBD
