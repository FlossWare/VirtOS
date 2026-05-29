# VirtOS TCZ Package Strategy

**Last Updated**: 2026-05-28  
**Purpose**: Document which TCZ packages are included in each build profile

---

## Overview

VirtOS uses Tiny Core Linux's **.tcz (Tiny Core Extension)** package system. Each build profile includes only the packages needed for its use case.

---

## Package Categories

### Core System (All Profiles)

**Always included** - VirtOS cannot function without these:

| Package | Size | Purpose | Used By |
|---------|------|---------|---------|
| **bash.tcz** | ~1MB | Bash shell | virtos-* scripts |
| **openssh.tcz** | ~1MB | SSH server/client | Remote management |
| **dialog.tcz** | ~200KB | TUI dialogs | virtos-tui |
| **ncurses.tcz** | ~300KB | Terminal graphics | dialog dependency |
| **curl.tcz** | ~500KB | HTTP client | Downloads, API calls |

**Total**: ~3MB

---

### Networking (All Profiles)

**Required for VM/container networking**:

| Package | Size | Purpose |
|---------|------|---------|
| **bridge-utils.tcz** | ~100KB | Network bridges (br0) |
| **iptables.tcz** | ~500KB | Firewall/NAT |
| **iproute2.tcz** | ~1MB | Modern networking (ip command) |
| **dnsmasq.tcz** | ~500KB | DHCP/DNS for VMs |

**Total**: ~2MB

---

### Virtualization - VMs

**KVM/QEMU packages** (included in all profiles except container-only):

| Package | Size | Purpose | Required By |
|---------|------|---------|-------------|
| **qemu.tcz** | ~50MB | QEMU/KVM hypervisor | VM functionality |
| **qemu-img.tcz** | ~5MB | Disk image tools | virtos-create-vm |
| **libvirt.tcz** | ~10MB | Virtualization API | virtos-* VM scripts |

**Total**: ~65MB

---

### Virtualization - Containers

**Container runtime packages** (profile-dependent):

| Package | Size | Purpose | Profiles |
|---------|------|---------|----------|
| **lxc.tcz** | ~5-10MB | System containers | standard, containers, full |
| **docker.tcz** | ~30MB | Docker runtime | standard, containers, developer, kubernetes, full |
| **containerd.tcz** | ~20MB | Container runtime | standard, containers, developer, kubernetes, full |
| **podman.tcz** | ~25MB | Rootless containers | containers, developer, full |

---

### Utilities - Optional

**Text editors**:

| Package | Size | Alternative | Profiles |
|---------|------|-------------|----------|
| **vim.tcz** | ~5-8MB | busybox vi | standard, containers, developer, kubernetes, full |
| **nano.tcz** | ~1MB | busybox vi | developer, full |

**Monitoring**:

| Package | Size | Alternative | Profiles |
|---------|------|-------------|----------|
| **htop.tcz** | ~1-2MB | busybox top | standard, containers, developer, kubernetes, full |
| **wget.tcz** | ~500KB | curl | standard, developer, full |

---

### Advanced Networking

**Optional networking** (profile-dependent):

| Package | Size | Purpose | Profiles |
|---------|------|---------|----------|
| **openvswitch.tcz** | ~10MB | Software-defined networking | full |
| **wireguard.tcz** | ~500KB | VPN | developer, kubernetes, full |

---

### Advanced Storage

**Optional storage** (profile-dependent):

| Package | Size | Purpose | Profiles |
|---------|------|---------|----------|
| **lvm.tcz** | ~2MB | Logical Volume Manager | full, storage |
| **zfs.tcz** | ~20MB | ZFS filesystem | full, storage |
| **btrfs.tcz** | ~5MB | Btrfs filesystem | full, storage |

---

### Clustering

**Cluster discovery** (most profiles):

| Package | Size | Purpose | Profiles |
|---------|------|---------|----------|
| **avahi.tcz** | ~1MB | mDNS/service discovery | standard, containers, developer, kubernetes, full |

---

### Kubernetes

**K8s orchestration** (k8s profile only):

| Package | Size | Purpose | Profiles |
|---------|------|---------|----------|
| **k3s.tcz** | ~50MB | Lightweight Kubernetes | kubernetes, full |

---

## Build Profiles - Package Breakdown

### Minimal (~100MB) - VM-Only

**Use Case**: Smallest possible system, VMs only, no containers

**Included**:

- ✅ Core system (3MB)
- ✅ Networking (2MB)
- ✅ KVM/QEMU (65MB)
- ✅ libvirt (10MB)

**Excluded**:

- ❌ vim (use busybox vi)
- ❌ htop (use busybox top)
- ❌ LXC
- ❌ Docker/containerd/Podman
- ❌ Clustering
- ❌ Advanced networking/storage

**Total**: ~100MB

**Savings vs Standard**: ~100MB

---

### Standard (~200MB) - Balanced

**Use Case**: Home lab, balanced VM + container support

**Included**:

- ✅ Everything in Minimal
- ✅ vim (5-8MB)
- ✅ htop (1-2MB)
- ✅ wget (500KB)
- ✅ LXC (5-10MB)
- ✅ Docker (30MB)
- ✅ containerd (20MB)
- ✅ Clustering/Avahi (1MB)

**Excluded**:

- ❌ Podman
- ❌ nano
- ❌ Advanced networking/storage
- ❌ K3s

**Total**: ~200MB

---

### Containers (~150MB) - Container-Focused

**Use Case**: Container workloads, minimal VM support

**Included**:

- ✅ Everything in Standard
- ✅ Podman (25MB)

**Note**: Same as Standard + Podman

**Total**: ~150MB

---

### Developer (~250MB) - Dev-Friendly

**Use Case**: Development environment with all tools

**Included**:

- ✅ Everything in Containers
- ✅ nano (1MB)
- ✅ WireGuard (500KB)

**Total**: ~250MB

---

### Kubernetes (~250MB) - K8s Orchestration

**Use Case**: Kubernetes cluster node

**Included**:

- ✅ Everything in Developer (except nano)
- ✅ K3s (50MB)
- ✅ WireGuard (500KB)

**Total**: ~250MB

---

### Full (~400MB) - Everything

**Use Case**: All features enabled

**Included**:

- ✅ Everything in Developer
- ✅ K3s (50MB)
- ✅ Open vSwitch (10MB)
- ✅ LVM (2MB)
- ✅ ZFS (20MB)
- ✅ Btrfs (5MB)

**Total**: ~400MB

---

### Storage (~350MB) - Advanced Storage

**Use Case**: Storage server with advanced filesystems (requires 4GB+ RAM for ZFS)

**Included**:

- ✅ Standard packages
- ✅ LVM (2MB)
- ✅ ZFS (20MB)
- ✅ Btrfs (5MB)
- ✅ NFS server (2MB)

**Total**: ~350MB

---

## VirtOS Custom Packages

### virtos-tools.tcz (Always Included)

**Contents**: 54 management scripts

**Dependencies**:

- bash.tcz (required for scripts)
- dialog.tcz (required for virtos-tui)
- ncurses.tcz (required by dialog)

**Size**: ~500KB (scripts only, deps counted above)

---

### virtos-platform-java.tcz (Optional)

**Contents**: platform-java integration

**Dependencies**:

- openjdk-21-jre.tcz (~100MB) ⚠️ **LARGE**
- libvirt.tcz (already in base)

**Size**: ~100MB (mostly Java)

**When to include**: Only if using platform-java workload orchestration

**Installation**: Manual (not in any profile by default)

---

## Package Selection Strategy

### By Profile

**Minimal** → Remove everything optional:

- No containers (LXC/Docker/containerd/Podman)
- No extra editors (vim/nano → busybox vi)
- No extra monitors (htop → busybox top)
- No clustering
- **Goal**: Smallest possible (~100MB)

**Standard** → Balanced for most users:

- Include common containers (Docker, LXC)
- Include vim + htop (quality of life)
- Include clustering (multi-host)
- **Goal**: Homelab-ready (~200MB)

**Containers** → Container-focused:

- All container runtimes (Docker, containerd, Podman, LXC)
- Minimal VM support
- **Goal**: Container workloads (~150MB)

**Developer** → Dev-friendly:

- All containers
- All editors (vim, nano)
- WireGuard VPN
- **Goal**: Development environment (~250MB)

**Kubernetes** → K8s orchestration:

- K3s + all dependencies
- All container runtimes
- WireGuard for overlay network
- **Goal**: K8s cluster node (~250MB)

**Full** → Everything:

- All virtualization
- All containers
- All networking (OVS, WireGuard)
- All storage (LVM, ZFS, Btrfs)
- **Goal**: Maximum features (~400MB)

**Storage** → Advanced storage:

- Advanced filesystems (ZFS, Btrfs, LVM)
- NFS server
- Containers for storage services
- **Goal**: Storage server (~350MB)

---

## Customization

### Override in build.conf

Edit `build/build.conf` to customize packages:

```bash
# Example: Minimal + vim
PROFILE="minimal"
INCLUDE_VIM="yes"  # Override profile default
```

### Create Custom Profile

Create `build/profiles/myprofile.conf`:

```bash
# My Custom Profile
# Description

# Copy settings from existing profile
INCLUDE_KVM="yes"
INCLUDE_DOCKER="yes"
# ... customize as needed
```

Then in `build.conf`:

```bash
PROFILE="myprofile"
```

---

## Package Size Reference

**Tiny** (< 1MB):

- dialog, ncurses, curl, bridge-utils, iptables, dnsmasq, avahi, htop, wget, nano, wireguard

**Small** (1-10MB):

- bash, openssh, iproute2, lvm, btrfs, lxc, qemu-img, openvswitch

**Medium** (10-30MB):

- libvirt, zfs, docker

**Large** (30-100MB):

- qemu, k3s, containerd, podman, openjdk-21-jre

---

## Dependency Chain

```
virtos-tools.tcz
├── bash.tcz
├── dialog.tcz
│   └── ncurses.tcz
└── (no other deps)

virtos-platform-java.tcz
├── openjdk-21-jre.tcz (~100MB)
└── libvirt.tcz (already in base)
```

---

## Recommendations

### For Production

**Use Standard profile** (~200MB):

- Good balance of features vs size
- VM + container support
- Common tools included

### For Embedded/IoT

**Use Minimal profile** (~100MB):

- Smallest possible
- VM-only
- Basic tools

### For Development

**Use Developer profile** (~250MB):

- All tools included
- All container runtimes
- VPN support

### For Kubernetes

**Use Kubernetes profile** (~250MB):

- K3s included
- All container runtimes
- Optimized for cluster nodes

---

## Future Considerations

### Potential Additions

**Web UI**:

- cockpit.tcz (~5MB) - Already in build.conf, set to "no"
- portainer.tcz (~10MB) - Already in build.conf, set to "no"

**Observability**:

- prometheus.tcz (~50MB)
- grafana.tcz (~100MB)

**Storage**:

- ceph.tcz (~50MB)
- nfs.tcz (~2MB)

### Potential Removals

**Consider removing from Standard**:

- wget (use curl instead) - saves ~500KB
- LXC (if users prefer Docker only) - saves ~5-10MB

**Already optimized**:

- Minimal has no fat to trim without removing core functionality

---

## Related Documentation

- [Build Configuration](BUILD.md)
- [Build Profiles](PROFILES.md)
- [Package Building](../packages/README.md)

---

**Questions?** File an issue: <https://github.com/FlossWare/VirtOS/issues>
