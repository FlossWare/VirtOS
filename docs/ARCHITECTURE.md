# Architecture Design

## System Layers

### 1. Hardware Layer
- x86_64 CPU with virtualization extensions (Intel VT-x or AMD-V)
- Adequate RAM (4GB minimum, 8GB+ recommended)
- Storage for host OS + guest images

### 2. Kernel Layer
**Base**: Linux kernel with virtualization support

**Required Kernel Features**:
- `CONFIG_KVM` - KVM support
- `CONFIG_KVM_INTEL` / `CONFIG_KVM_AMD` - CPU-specific KVM
- `CONFIG_VHOST_NET` - vhost-net for network performance
- `CONFIG_BRIDGE` - Network bridging
- `CONFIG_NAMESPACES` - Container isolation
- `CONFIG_CGROUPS` - Resource management
- `CONFIG_OVERLAY_FS` - Container layered filesystems
- `CONFIG_VETH` - Virtual ethernet devices

### 3. Virtualization Layer

#### KVM/QEMU
- **Purpose**: Full system virtualization
- **Use Cases**: Running complete OS instances (Windows, Linux, BSD)
- **Components**:
  - `/dev/kvm` kernel module
  - QEMU userspace emulator
  - virtio drivers for performance

#### LXC
- **Purpose**: System containers (OS-level virtualization)
- **Use Cases**: Lightweight Linux environments, system isolation
- **Components**:
  - LXC runtime
  - lxcfs for /proc compatibility
  - AppArmor or SELinux (optional security)

#### OCI Containers
- **Purpose**: Application containers
- **Use Cases**: Microservices, application deployment
- **Options**:
  - containerd (minimal, used by Kubernetes)
  - cri-o (Kubernetes-native)
  - Docker (full-featured, larger footprint)

### 4. Networking Layer

**Components**:
- `br-ctl` / `ip link` - Bridge management
- `iptables` / `nftables` - Firewall and NAT
- `dnsmasq` - DHCP and DNS for virtual networks
- OVS (optional) - Advanced virtual switching

**Network Modes**:
- Bridge - Connect VMs to host network
- NAT - VMs share host IP
- Host-only - Isolated network
- Macvlan - Direct MAC addressing

### 5. Storage Layer

**Components**:
- `qemu-img` - Disk image management
- `device-mapper` - Block device mapping
- LVM - Logical volume management (optional)
- ZFS / Btrfs - Advanced filesystems (optional)

**Storage Types**:
- Raw disk images
- qcow2 (QEMU copy-on-write)
- LXC directories
- Container overlay filesystems

### 6. Management Layer

**Options**:
- **libvirt** - Unified API for KVM/QEMU, LXC
- **virsh** - CLI for libvirt
- **virt-manager** - GUI (optional, for remote access)
- **Portainer** / **Cockpit** - Web UI (optional)
- Custom scripts - Tiny Core specific tools

## Boot Process

1. **BIOS/UEFI** loads bootloader (GRUB/syslinux)
2. **Bootloader** loads Tiny Core kernel + initrd
3. **Init** mounts system and loads extensions
4. **Extension loading**:
   - Core networking
   - KVM modules
   - Virtualization runtimes (on-demand)
5. **Service startup**:
   - Network configuration
   - libvirtd (if used)
   - Container runtime
6. **Ready** for VM/container creation

## Tiny Core Integration

### Extension (TCZ) Strategy

**Core Extensions** (always loaded):
- `kmaps` - Keyboard layouts
- `firmware` - Hardware firmware
- `kvm-modules` - KVM kernel modules
- `bridge-utils` - Network bridging

**On-Demand Extensions**:
- `qemu` - When running KVM VMs
- `lxc` - When running system containers
- `containerd` - When running OCI containers
- `libvirt` - If using libvirt management

### Persistence

**Options**:
1. **Full install** - Traditional disk installation
2. **Frugal install** - Boot from read-only + persistent home
3. **Cloud mode** - Boot from ISO, store data on separate partition

**Recommendation**: Frugal install with separate partition for VM/container storage

## Resource Isolation

### CPU
- KVM: Hardware virtualization, CPU pinning
- Containers: cgroups CPU shares/quotas

### Memory
- KVM: Dedicated memory allocation
- Containers: cgroups memory limits
- Balloon drivers for dynamic adjustment

### I/O
- virtio-blk / virtio-scsi for disk I/O
- virtio-net for network I/O
- cgroups blkio for container I/O limits

## Security Considerations

1. **Kernel hardening** - Minimal modules, secure defaults
2. **Isolation** - Namespaces, cgroups, seccomp
3. **MAC** - AppArmor or SELinux (optional)
4. **Firewall** - Default deny, explicit rules
5. **Updates** - Security patch strategy for minimal system
6. **Root access** - Limit exposure, consider sudo/doas

## Scalability

- **Single host**: Direct management, local storage
- **Cluster** (future): Distributed storage, migration, HA
