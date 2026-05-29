# Configuration Guide

FlossWare VirtOS is fully configurable. Choose exactly what you want - nothing is forced.

## Configuration File

All options are in: `build/build.conf`

## Philosophy

- **Modular**: Every component is optional
- **Choosable**: You decide what to include
- **Profiles**: Quick starts for common use cases
- **Flexible**: Mix and match as needed

## Quick Configuration Methods

### Method 1: Use a Profile

Fastest way to get started:

```bash
# Edit build/build.conf
PROFILE="standard"    # or minimal, full, containers, developer

# Build
./build/scripts/build-all.sh
```

Profiles are in `config/profiles/` - copy and modify to create your own!

### Method 2: Individual Options

Complete control:

```bash
# Edit build/build.conf
PROFILE=""  # Disable profile

# Choose exactly what you want
INCLUDE_KVM="yes"
INCLUDE_DOCKER="yes"
INCLUDE_PODMAN="no"
# ... etc
```

### Method 3: Profile + Overrides

Start with profile, tweak specifics:

```bash
PROFILE="standard"

# Override specific options
INCLUDE_PODMAN="no"     # Remove Podman from standard profile
INCLUDE_WIREGUARD="yes" # Add WireGuard
```

**Note**: Individual options override profile settings.

## Configuration Categories

### Virtualization Components

```bash
# Full system virtualization
INCLUDE_KVM="yes"           # KVM/QEMU

# System containers
INCLUDE_LXC="yes"           # LXC

# OCI Container Runtimes - Choose any combination!
INCLUDE_DOCKER="yes"        # Docker (familiar, docker-compose)
INCLUDE_PODMAN="yes"        # Podman (rootless, secure)
INCLUDE_CONTAINERD="yes"    # containerd (minimal, K8s)
```

**Can include all three container runtimes!** They don't conflict - load what you need at runtime.

### Management Tools

```bash
# Unified virtualization API
INCLUDE_LIBVIRT="yes"       # libvirt daemon
INCLUDE_VIRSH="yes"         # Command-line interface (requires libvirt)

# Web interfaces (future)
INCLUDE_COCKPIT="no"        # System management UI
INCLUDE_PORTAINER="no"      # Container management UI
```

### Networking

```bash
# Basic (recommended)
INCLUDE_BRIDGE_UTILS="yes"  # Bridge networking
INCLUDE_IPTABLES="yes"      # Firewall/NAT
INCLUDE_DNSMASQ="yes"       # DHCP/DNS for VMs

# Advanced
INCLUDE_OVS="no"            # Open vSwitch
INCLUDE_WIREGUARD="no"      # VPN
```

### Storage

```bash
# Basic (recommended)
INCLUDE_QEMU_IMG="yes"      # Disk image management

# Advanced
INCLUDE_LVM="no"            # Logical volumes
INCLUDE_ZFS="no"            # ZFS filesystem
INCLUDE_BTRFS="no"          # Btrfs filesystem
```

### System Utilities

```bash
# Shell
INCLUDE_BASH="yes"          # Bash (default is busybox ash)

# Editors
INCLUDE_VIM="yes"
INCLUDE_NANO="no"

# Remote access
INCLUDE_OPENSSH="yes"

# Monitoring
INCLUDE_HTOP="yes"

# Network tools
INCLUDE_CURL="yes"
INCLUDE_WGET="yes"
```

### Boot Options

```bash
# Auto-start at boot
AUTOSTART_NETWORKING="yes"
AUTOSTART_KVM="yes"
AUTOSTART_DOCKER="no"       # Load extension but don't start daemon
AUTOSTART_LIBVIRT="no"

# Boot parameters
BOOT_TIMEOUT="5"            # Seconds before auto-boot
ENABLE_SERIAL_CONSOLE="no"  # Serial console access

# System
HOSTNAME="flossware-virt"
```

### Build Options

```bash
# Compression
COMPRESSION_LEVEL="9"       # 1-9 (higher = smaller, slower build)

# ISO options
CREATE_HYBRID_ISO="yes"     # USB-bootable
GENERATE_CHECKSUMS="yes"    # MD5/SHA256

# Cleanup
CLEAN_AFTER_BUILD="no"      # Keep workspace for debugging
```

## Container Runtime Decision Matrix

**Include one, two, or all three** - they're all optional TCZ extensions:

| If you want... | Choose |
|----------------|--------|
| Familiar interface, docker-compose | **Docker** |
| Rootless containers, better security | **Podman** |
| Smallest footprint, K8s-compatible | **containerd** |
| Best of familiar + security | **Docker + Podman** |
| Maximum flexibility, learning | **All three** |
| Minimal system | **containerd only** |

At runtime, load what you need:

```bash
tce-load -i docker       # If you included it
tce-load -i podman       # If you included it
tce-load -i containerd   # If you included it
```

See [CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md) for detailed comparison.

## Example Configurations

### Home Lab (Balanced)

```bash
PROFILE="standard"  # Or manually:
INCLUDE_KVM="yes"
INCLUDE_LXC="yes"
INCLUDE_DOCKER="yes"
INCLUDE_PODMAN="yes"
INCLUDE_CONTAINERD="yes"  # All three!
INCLUDE_LIBVIRT="yes"
INCLUDE_BASH="yes"
```

### Minimal Production

```bash
PROFILE="minimal"  # Or manually:
INCLUDE_KVM="yes"
INCLUDE_LXC="no"
INCLUDE_DOCKER="no"
INCLUDE_PODMAN="no"
INCLUDE_CONTAINERD="yes"  # Smallest
INCLUDE_LIBVIRT="no"
INCLUDE_BASH="no"  # Use ash
```

### Container Host

```bash
PROFILE="containers"  # Or manually:
INCLUDE_KVM="yes"  # Minimal
INCLUDE_LXC="yes"
INCLUDE_DOCKER="yes"
INCLUDE_PODMAN="yes"
INCLUDE_CONTAINERD="yes"  # All runtimes
INCLUDE_LIBVIRT="no"
INCLUDE_PORTAINER="yes"
```

### Learning/Development

```bash
PROFILE="developer"  # Or manually:
INCLUDE_KVM="yes"
INCLUDE_LXC="yes"
INCLUDE_DOCKER="yes"
INCLUDE_PODMAN="yes"
INCLUDE_CONTAINERD="yes"  # All three to compare!
INCLUDE_LIBVIRT="yes"
INCLUDE_BASH="yes"
INCLUDE_VIM="yes"
INCLUDE_NANO="yes"
```

## Runtime Extension Loading

Even if you include everything, extensions only load when needed:

```bash
# Boot with minimal footprint
# Load extensions on demand

# Need to run VMs?
tce-load -i qemu
tce-load -i libvirt

# Need Docker?
tce-load -i docker
/usr/local/etc/init.d/docker start

# Need Podman instead?
tce-load -i podman
# (No daemon needed for Podman)

# Need minimal containers?
tce-load -i containerd
/usr/local/etc/init.d/containerd start
```

## Custom Scripts

```bash
# Enable custom scripts
INCLUDE_CUSTOM_SCRIPTS="yes"

# Place your scripts in:
config/custom-scripts/

# They'll be copied to /usr/local/bin/ in the ISO
```

## Validation

The build script will:

- Validate configuration
- Warn about conflicts
- Show what will be included
- Estimate final ISO size

## Default Configuration

If you don't edit `build.conf`, you get the **standard** profile:

- KVM + LXC
- All three container runtimes (Docker, Podman, containerd)
- libvirt
- Common utilities
- ~200MB ISO

## Advanced: Creating Custom Profiles

1. Create new profile:

```bash
cp config/profiles/standard.conf config/profiles/myprofile.conf
```

2. Edit to your needs

3. Use it:

```bash
# Edit build/build.conf
PROFILE="myprofile"
```

4. Or specify at build time:

```bash
PROFILE="myprofile" ./build/scripts/build-all.sh
```

## Configuration Tips

1. **Start with a profile** - easier than configuring from scratch
2. **Include all container runtimes** - they're optional at runtime anyway
3. **Keep OPENSSH** - remote access is essential
4. **Bash vs ash** - bash is more familiar, ash saves ~5MB
5. **libvirt** - adds ~25MB but simplifies VM management
6. **Web UIs** - add significant size, consider loading later
7. **Don't worry about size** - extensions load on-demand anyway

## Kubernetes Configuration

```bash
# Enable K3s (optional)
INCLUDE_K3S="yes"           # Lightweight Kubernetes

# K3s settings
K3S_VERSION="latest"        # or specific version
K3S_ROLE="server"           # server, agent, both
AUTOSTART_K3S="no"          # Auto-start at boot

# Advanced K3s
K3S_DISABLE_TRAEFIK="no"    # Disable built-in ingress
K3S_DISABLE_SERVICELB="no"  # Disable built-in LB
```

**When to enable**:

- Multi-host container orchestration
- Need auto-scaling and self-healing
- Microservices deployment
- Learning Kubernetes

**When to skip**:

- Single host (use docker-compose instead)
- Only running VMs
- Limited resources (<4GB RAM)

See [KUBERNETES.md](KUBERNETES.md) for complete guide.

## See Also

- [PROFILES.md](PROFILES.md) - Profile details
- [CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md) - Container runtime comparison
- [KUBERNETES.md](KUBERNETES.md) - K3s orchestration
- [PACKAGES.md](PACKAGES.md) - Package details and sizes
- [build/build.conf](../build/build.conf) - Full configuration file
