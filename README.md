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

### Profiles

| Profile | Size | What's Included |
|---------|------|-----------------|
| **minimal** | ~100MB | KVM + containerd only |
| **standard** | ~200MB | KVM + LXC + All 3 container runtimes (default) |
| **full** | ~400MB | Everything |
| **containers** | ~150MB | All container runtimes + minimal VMs |
| **developer** | ~250MB | All runtimes + dev tools |

See [docs/PROFILES.md](docs/PROFILES.md) for details.

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

## License

TBD
