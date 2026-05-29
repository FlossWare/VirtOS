# Package Requirements

## Tiny Core Linux Base

### Core System
- **CorePure64** (64-bit) or **Core** (32-bit)
- **Version**: Latest stable (14.x as of 2025)
- **Size**: ~15-20 MB base

## Essential Packages

### Kernel Modules
```
kmod-kvm
kmod-kvm-intel (or kmod-kvm-amd)
kmod-vhost-net
kmod-bridge
kmod-tun
kmod-macvlan
```

### KVM/QEMU Stack
```
qemu
qemu-system-x86_64
seabios (BIOS for QEMU)
edk2-ovmf (UEFI support, optional)
```

### LXC Stack
```
lxc
lxcfs
liblxc
```

### Container Runtime (choose one or more)

**Option 1: containerd** (minimal, Kubernetes-compatible)
```
containerd
runc
cni-plugins
```

**Option 2: Docker** (full-featured)
```
docker
docker-cli
docker-compose (optional)
```

**Option 3: Podman** (rootless-friendly)
```
podman
crun or runc
```

### Networking
```
bridge-utils
iptables
iproute2
dnsmasq
ebtables (optional, for advanced bridging)
```

### Storage
```
qemu-img (usually with qemu)
lvm2 (optional)
device-mapper
parted
```

### Management Tools

**Option 1: libvirt** (recommended for KVM/LXC)
```
libvirt
libvirt-daemon
virsh
```

**Option 2: Direct tools**
```
Custom scripts (minimal)
```

### System Utilities
```
bash (optional, busybox ash is default)
vim or nano (optional editor)
openssh (for remote management)
curl or wget
htop or top (monitoring)
```

## Optional Packages

### Advanced Networking
```
openvswitch (software-defined networking)
wireguard (VPN)
```

### Monitoring
```
collectd
prometheus-node-exporter
```

### Web UI
```
cockpit (system management)
portainer (container management)
nginx or lighttpd (web server)
```

### Advanced Storage
```
zfs or btrfs
ceph (distributed storage)
nfs-utils
```

## Package Size Estimates

| Component | Approximate Size |
|-----------|-----------------|
| Base Tiny Core | 15 MB |
| Kernel modules (KVM) | 5 MB |
| QEMU/KVM | 25-40 MB |
| LXC | 3-5 MB |
| containerd | 20-30 MB |
| Docker | 60-80 MB |
| libvirt | 15-25 MB |
| Networking tools | 5-10 MB |
| **Minimal system** | **~100 MB** |
| **Full-featured** | **~200 MB** |

## Building Custom Extensions

Packages not available in Tiny Core repository need to be compiled:

### Build Process
1. Set up Tiny Core build environment
2. Compile from source
3. Create TCZ extension
4. Generate dependencies
5. Test installation

### Common builds needed:
- Latest QEMU (if not in repo)
- Latest libvirt
- Specific container runtime versions

## Extension Loading Strategy

### Boot-time (always load)
```
/opt/bootlocal.sh:
  tce-load -i kvm-modules
  tce-load -i bridge-utils
  tce-load -i iptables
```

### On-demand (load when needed)
```
# Start KVM VM
tce-load -i qemu
tce-load -i libvirt

# Start LXC container  
tce-load -i lxc

# Start OCI container
tce-load -i containerd
```

### Persistent (installed)
```
tce/onboot.lst:
  kvm-modules.tcz
  bridge-utils.tcz
  iptables.tcz
  openssh.tcz
```

## Dependency Management

Extensions have dependencies (.dep files). Key dependency chains:

```
libvirt -> qemu -> pixman -> cairo -> ...
lxc -> liblxc -> libcap
containerd -> runc -> libseccomp
```

Use `tce-load -wi package` to automatically resolve dependencies.

## Repository Sources

1. **Official Tiny Core repo**: https://tinycorelinux.net/14.x/x86_64/tcz/
2. **Custom builds**: Compile and host locally
3. **Community repos**: Third-party TCZ collections (verify trust)
