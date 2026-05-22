# Build Profiles

FlossWare VirtOS supports multiple build profiles to suit different use cases. Everything is **choosable** - use a profile as a starting point or customize individual components.

## Quick Start

Edit `build/build.conf` and set the `PROFILE` variable:

```bash
# Choose one:
PROFILE="minimal"      # ~100MB - Smallest system
PROFILE="standard"     # ~200MB - Balanced (default)
PROFILE="full"         # ~400MB - Everything
PROFILE="containers"   # ~150MB - Container-focused
PROFILE="developer"    # ~250MB - Dev-friendly
```

Or customize individual options (see Configuration section below).

## Profile Comparison

| Component | Minimal | Standard | Full | Containers | Developer |
|-----------|---------|----------|------|------------|-----------|
| **Size** | ~100MB | ~200MB | ~400MB | ~150MB | ~250MB |
| **KVM/QEMU** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **LXC** | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Docker** | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Podman** | ❌ | ✅ | ✅ | ✅ | ✅ |
| **containerd** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **libvirt** | ❌ | ✅ | ✅ | ❌ | ✅ |
| **Web UI** | ❌ | ❌ | ✅ | Portainer | Portainer |
| **Bash** | ❌ (ash) | ✅ | ✅ | ✅ | ✅ |
| **Advanced Net** | ❌ | ❌ | ✅ | OVS | WireGuard |
| **Storage** | Basic | Basic | All | Basic | Basic |

## Profile Details

### Minimal Profile
**Size**: ~100MB  
**Use Case**: Embedded systems, minimal footprint, production hosts

**Includes**:
- KVM/QEMU for VMs
- containerd (smallest container runtime)
- Basic networking
- openssh for remote access
- Busybox utilities only

**Best for**:
- Edge computing
- Minimal attack surface
- Learning virtualization basics
- Resource-constrained environments

**Command**: 
```bash
PROFILE="minimal" ./build/scripts/build-all.sh
```

### Standard Profile (Default)
**Size**: ~200MB  
**Use Case**: Home lab, general virtualization, balanced features

**Includes**:
- KVM/QEMU for VMs
- LXC for system containers
- **All three container runtimes** (Docker, Podman, containerd)
- libvirt for unified management
- Common utilities (bash, vim, htop)
- Networking tools

**Best for**:
- Home labs
- Learning all virtualization types
- Experimenting with different container runtimes
- General development

**Command**: 
```bash
PROFILE="standard" ./build/scripts/build-all.sh
# or just:
./build/scripts/build-all.sh
```

### Full Profile
**Size**: ~400MB  
**Use Case**: Feature-complete system, all options

**Includes**:
- Everything in Standard
- Web management UIs (Cockpit, Portainer)
- Advanced networking (OVS, WireGuard)
- Advanced storage (LVM, ZFS, Btrfs)
- All utilities

**Best for**:
- Full-featured lab environment
- Testing all features
- Learning advanced topics
- When size doesn't matter

**Command**: 
```bash
PROFILE="full" ./build/scripts/build-all.sh
```

### Containers Profile
**Size**: ~150MB  
**Use Case**: Container-focused workloads

**Includes**:
- **All container runtimes** (Docker, Podman, containerd)
- LXC system containers
- Minimal KVM (for testing)
- Portainer web UI
- Advanced networking (OVS)

**Excludes**:
- libvirt (not needed for containers)
- Advanced storage
- Extra utilities

**Best for**:
- Microservices deployment
- Container development
- Kubernetes nodes
- Docker/Podman hosting

**Command**: 
```bash
PROFILE="containers" ./build/scripts/build-all.sh
```

### Developer Profile
**Size**: ~250MB  
**Use Case**: Development and learning

**Includes**:
- **All container runtimes** (Docker, Podman, containerd)
- KVM + LXC
- libvirt + virsh
- Portainer
- Both editors (vim + nano)
- WireGuard VPN
- Development tools

**Best for**:
- Learning all virtualization types
- Comparing container runtimes
- Development workstation
- Educational purposes

**Command**: 
```bash
PROFILE="developer" ./build/scripts/build-all.sh
```

## Custom Configuration

Don't like the profiles? **Customize everything!**

Edit `build/build.conf`:

```bash
# Don't use a profile
PROFILE=""

# Choose exactly what you want
INCLUDE_KVM="yes"
INCLUDE_LXC="yes"
INCLUDE_DOCKER="yes"      # ← Choose container runtimes
INCLUDE_PODMAN="yes"      # ← All three available!
INCLUDE_CONTAINERD="no"   # ← Or pick and choose
INCLUDE_LIBVIRT="yes"
INCLUDE_BASH="yes"
# ... etc
```

**Every component is optional!** See `build/build.conf` for all options.

## Container Runtime Combinations

You can include any combination:

```bash
# Docker only (familiar, easy)
INCLUDE_DOCKER="yes"
INCLUDE_PODMAN="no"
INCLUDE_CONTAINERD="no"

# Podman only (secure, rootless)
INCLUDE_DOCKER="no"
INCLUDE_PODMAN="yes"
INCLUDE_CONTAINERD="no"

# containerd only (minimal, K8s)
INCLUDE_DOCKER="no"
INCLUDE_PODMAN="no"
INCLUDE_CONTAINERD="yes"

# Docker + Podman (best of both)
INCLUDE_DOCKER="yes"
INCLUDE_PODMAN="yes"
INCLUDE_CONTAINERD="no"

# All three (maximum flexibility)
INCLUDE_DOCKER="yes"
INCLUDE_PODMAN="yes"
INCLUDE_CONTAINERD="yes"
```

See [CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md) for detailed comparison.

## Switching Profiles After Install

Profiles only affect what's **included** in the ISO. After booting, you can:

```bash
# Load additional extensions on demand
tce-load -i docker
tce-load -i podman
tce-load -i lxc
tce-load -i qemu

# They'll download from Tiny Core repository
# (if available, else compile from source)
```

## Creating Custom Profiles

1. Copy existing profile:
```bash
cp config/profiles/standard.conf config/profiles/myprofile.conf
```

2. Edit to your needs

3. Use it:
```bash
PROFILE="myprofile" ./build/scripts/build-all.sh
```

## Profile Files Location

Profiles are stored in `config/profiles/`:
- `minimal.conf`
- `standard.conf`
- `full.conf`
- `containers.conf`
- `developer.conf`

## Size Estimates

Sizes are approximate and include:
- Base Tiny Core (~20MB)
- Kernel modules (~10MB)
- Selected packages
- Custom configurations

Actual size depends on:
- Tiny Core version
- Package versions
- Compression settings
- Custom additions

## Recommendation by Use Case

| Use Case | Recommended Profile |
|----------|---------------------|
| Home lab | **Standard** |
| Production VMs | **Minimal** or **Standard** |
| Container hosting | **Containers** |
| Learning/Education | **Developer** |
| Edge/IoT | **Minimal** |
| Testing everything | **Full** |
| Custom needs | **Edit build.conf** |

## Next Steps

1. Choose a profile (or customize `build.conf`)
2. Build: `./build/scripts/build-all.sh`
3. Test: `qemu-system-x86_64 -enable-kvm -m 2048 -cdrom output/*.iso`
4. Deploy: Write to USB or install to disk

See [GETTING-STARTED.md](GETTING-STARTED.md) for build instructions.
