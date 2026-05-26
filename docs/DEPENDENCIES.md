# VirtOS Script Dependencies

Complete documentation of external command dependencies for all virtos-* management scripts.

## Quick Reference

### Check Your System

```bash
# Run dependency check (recommended)
virtos-check-deps

# Or check manually
./scripts/check-dependencies.sh
```

## Core Dependencies (Required for All)

All virtos-* scripts require:

| Command | Package | Used For |
|---------|---------|----------|
| `sh` / `bash` | coreutils | Script execution |
| `grep` | grep | Pattern matching |
| `awk` | gawk/mawk | Text processing |
| `sed` | sed | Text manipulation |

**Install**:
```bash
# Usually pre-installed on all Linux systems
```

## VM Management Scripts

### virtos-setup

**Required**:
- `dialog` OR `whiptail` - Interactive TUI

**Install**:
```bash
# Fedora
sudo dnf install dialog

# Ubuntu/Debian
sudo apt install dialog
```

### virtos-create-vm

**Required**:
- `virsh` (libvirt-client) - VM management
- `qemu-img` (qemu-utils) - Disk image creation

**Optional**:
- `virt-install` - Advanced VM creation

**Install**:
```bash
# Fedora
sudo dnf install libvirt qemu-img virt-install

# Ubuntu/Debian
sudo apt install libvirt-clients qemu-utils virtinst
```

### virtos-migrate

**Required**:
- `virsh` (libvirt-client) - VM management
- `ssh` (openssh-client) - Remote host access

**Install**:
```bash
# Fedora
sudo dnf install libvirt openssh-clients

# Ubuntu/Debian
sudo apt install libvirt-clients openssh-client
```

### virtos-snapshot

**Required**:
- `virsh` (libvirt-client) - Snapshot management

**Install**:
```bash
# Fedora
sudo dnf install libvirt

# Ubuntu/Debian
sudo apt install libvirt-clients
```

### virtos-backup

**Required**:
- `virsh` (libvirt-client) - VM operations
- `qemu-img` (qemu-utils) - Image conversion
- `tar` - Archive creation

**Install**:
```bash
# Fedora
sudo dnf install libvirt qemu-img tar

# Ubuntu/Debian
sudo apt install libvirt-clients qemu-utils tar
```

### virtos-monitor

**Required**:
- `virsh` (libvirt-client) - VM stats

**Optional**:
- `htop` - Process monitoring
- `iotop` - I/O monitoring

**Install**:
```bash
# Fedora
sudo dnf install libvirt htop iotop

# Ubuntu/Debian
sudo apt install libvirt-clients htop iotop
```

## Network Management Scripts

### virtos-network

**Required**:
- `virsh` (libvirt-client) - Network management
- `ip` (iproute2) - Network configuration
- `brctl` (bridge-utils) - Bridge management

**Optional**:
- `iptables` - Firewall rules
- `dnsmasq` - DNS/DHCP

**Install**:
```bash
# Fedora
sudo dnf install libvirt iproute bridge-utils iptables dnsmasq

# Ubuntu/Debian
sudo apt install libvirt-clients iproute2 bridge-utils iptables dnsmasq
```

### virtos-firewall

**Required**:
- `iptables` - Firewall management

**Optional**:
- `nft` (nftables) - Modern firewall

**Install**:
```bash
# Fedora
sudo dnf install iptables nftables

# Ubuntu/Debian
sudo apt install iptables nftables
```

## Storage Management Scripts

### virtos-storage

**Required**:
- `virsh` (libvirt-client) - Storage pool management

**Optional**:
- `lvs`, `vgs`, `pvs` (lvm2) - LVM volumes
- `btrfs` (btrfs-progs) - Btrfs filesystems
- `zpool`, `zfs` (zfsutils) - ZFS pools

**Install**:
```bash
# Fedora (base)
sudo dnf install libvirt

# Fedora (with LVM)
sudo dnf install libvirt lvm2

# Fedora (with Btrfs)
sudo dnf install libvirt btrfs-progs

# Ubuntu (base)
sudo apt install libvirt-clients

# Ubuntu (with LVM)
sudo apt install libvirt-clients lvm2

# Ubuntu (with Btrfs)
sudo apt install libvirt-clients btrfs-progs
```

### virtos-storage-pool

**Required**:
- `virsh` (libvirt-client) - Pool operations

**Install**: Same as virtos-storage

## Container Management Scripts

### virtos-container

**Required** (at least one):
- `docker` (docker-ce) - Docker containers
- `podman` - Rootless containers
- `lxc-create` (lxc) - System containers

**Install**:
```bash
# Fedora (Docker)
sudo dnf install docker

# Fedora (Podman - recommended)
sudo dnf install podman

# Fedora (LXC)
sudo dnf install lxc

# Ubuntu (Docker)
sudo apt install docker.io

# Ubuntu (Podman)
sudo apt install podman

# Ubuntu (LXC)
sudo apt install lxc
```

## Cluster Management Scripts

### virtos-cluster

**Required**:
- `ssh` (openssh-client) - Remote communication

**Optional**:
- `avahi-browse` (avahi-utils) - mDNS discovery
- `socat` OR `nc` - Multicast communication
- `nmap` - Network scanning (fallback)

**Install**:
```bash
# Fedora (full)
sudo dnf install openssh-clients avahi-tools socat nmap

# Ubuntu (full)
sudo apt install openssh-client avahi-utils socat nmap

# Minimal (SSH only)
sudo dnf install openssh-clients  # Fedora
sudo apt install openssh-client   # Ubuntu
```

### virtos-ha

**Required**:
- `virsh` (libvirt-client) - VM management
- `ssh` (openssh-client) - Remote operations

**Optional**:
- `pacemaker` - Cluster resource manager
- `corosync` - Cluster communication

**Install**:
```bash
# Fedora
sudo dnf install libvirt openssh-clients pacemaker corosync

# Ubuntu
sudo apt install libvirt-clients openssh-client pacemaker corosync
```

## Template Management Scripts

### virtos-template

**Required**:
- `virsh` (libvirt-client) - VM/template operations
- `qemu-img` (qemu-utils) - Image conversion

**Optional**:
- `wget` OR `curl` - Cloud image download

**Install**:
```bash
# Fedora
sudo dnf install libvirt qemu-img wget

# Ubuntu
sudo apt install libvirt-clients qemu-utils wget
```

## Utility Scripts

### virtos-tui

**Required**:
- `dialog` OR `whiptail` - Text UI

**Install**:
```bash
# Fedora
sudo dnf install dialog

# Ubuntu
sudo apt install dialog
```

### virtos-version

**Required**:
- None (uses only shell builtins)

### virtos-logs

**Required**:
- `journalctl` (systemd) - Log viewing

**Optional**:
- `less` - Log paging

**Install**:
```bash
# Usually pre-installed with systemd
```

## Optional Advanced Dependencies

### GPU Passthrough (virtos-gpu)

**Required**:
- `lspci` (pciutils) - PCI device listing
- `modprobe` (kmod) - Kernel module management

**Install**:
```bash
# Fedora
sudo dnf install pciutils kmod

# Ubuntu
sudo apt install pciutils kmod
```

### USB Passthrough (virtos-usb)

**Required**:
- `lsusb` (usbutils) - USB device listing

**Install**:
```bash
# Fedora
sudo dnf install usbutils

# Ubuntu
sudo apt install usbutils
```

### Advanced Networking (virtos-networking-advanced)

**Required**:
- `ovs-vsctl` (openvswitch) - OVS management

**Install**:
```bash
# Fedora
sudo dnf install openvswitch

# Ubuntu
sudo apt install openvswitch-switch
```

## Development Dependencies

For building and testing VirtOS:

**Required**:
- `bash` - Build scripts
- `genisoimage` - ISO creation
- `syslinux` - Bootloader
- `squashfs-tools` - Package compression

**Optional**:
- `shellcheck` - Script linting
- `bats` - Unit testing
- `qemu-system-x86_64` - ISO testing

**Install**:
```bash
# Fedora (full dev environment)
sudo dnf install bash genisoimage syslinux squashfs-tools shellcheck qemu-kvm

# Ubuntu (full dev environment)
sudo apt install bash genisoimage syslinux-utils squashfs-tools shellcheck bats qemu-kvm
```

## Checking Dependencies

### Manual Check

```bash
# Check if a command exists
command -v virsh >/dev/null 2>&1 && echo "✓ virsh" || echo "✗ virsh"

# Check multiple commands
for cmd in virsh qemu-img ssh; do
    command -v $cmd >/dev/null 2>&1 && echo "✓ $cmd" || echo "✗ $cmd"
done
```

### Automated Check

Create `/usr/local/bin/virtos-check-deps`:

```bash
#!/bin/sh
# Check all virtos dependencies

echo "VirtOS Dependency Check"
echo "======================="
echo ""

check_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "✓ $1"
        return 0
    else
        echo "✗ $1 (missing)"
        return 1
    fi
}

echo "Core VM Management:"
check_cmd virsh
check_cmd qemu-img

echo ""
echo "Networking:"
check_cmd ip
check_cmd brctl
check_cmd iptables

echo ""
echo "Containers:"
check_cmd docker || check_cmd podman || echo "  (none found)"

echo ""
echo "Clustering:"
check_cmd ssh
check_cmd avahi-browse || echo "  (optional)"

echo ""
echo "Storage:"
check_cmd lvs || echo "  (LVM not installed)"
check_cmd btrfs || echo "  (Btrfs not installed)"

echo ""
echo "Utilities:"
check_cmd dialog || check_cmd whiptail
```

## Troubleshooting

### Command Not Found Errors

**Error**: `virsh: command not found`

**Solution**:
```bash
# Install libvirt client
sudo dnf install libvirt  # Fedora
sudo apt install libvirt-clients  # Ubuntu
```

**Error**: `brctl: command not found`

**Solution**:
```bash
# Install bridge-utils
sudo dnf install bridge-utils  # Fedora
sudo apt install bridge-utils  # Ubuntu
```

**Error**: `docker: command not found`

**Solution**:
```bash
# Install Docker OR Podman
sudo dnf install docker  # Fedora
sudo apt install docker.io  # Ubuntu

# Or use Podman (rootless, recommended)
sudo dnf install podman  # Fedora
sudo apt install podman  # Ubuntu
```

### Permission Errors

**Error**: `error: Failed to connect to libvirtd`

**Solution**:
```bash
# Start libvirtd service
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

# Add user to libvirt group
sudo usermod -aG libvirt $USER
# Log out and back in for group to take effect
```

**Error**: `permission denied: /dev/kvm`

**Solution**:
```bash
# Add user to kvm group
sudo usermod -aG kvm $USER
# Log out and back in

# Or (temporary, insecure)
sudo chmod 660 /dev/kvm
```

### Service Not Running

**Error**: `error: failed to connect to the hypervisor`

**Solution**:
```bash
# Check libvirtd status
sudo systemctl status libvirtd

# Start if not running
sudo systemctl start libvirtd

# Enable for boot
sudo systemctl enable libvirtd
```

## Minimal Installation

Absolute minimum for basic VM operations:

```bash
# Fedora
sudo dnf install libvirt qemu-img

# Ubuntu
sudo apt install libvirt-clients qemu-utils
```

## Full Installation

Everything for complete VirtOS functionality:

```bash
# Fedora
sudo dnf install libvirt qemu-img virt-install \
                 iproute bridge-utils iptables dnsmasq \
                 openssh-clients avahi-tools \
                 lvm2 btrfs-progs \
                 docker podman \
                 dialog pciutils usbutils

# Ubuntu
sudo apt install libvirt-clients qemu-utils virtinst \
                 iproute2 bridge-utils iptables dnsmasq \
                 openssh-client avahi-utils \
                 lvm2 btrfs-progs \
                 docker.io podman \
                 dialog pciutils usbutils
```

## See Also

- [BUILD.md](BUILD.md) - Build dependencies and requirements
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Development dependencies
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [README.md](../README.md) - Quick start guide

## Questions?

If you encounter missing dependency errors not covered here:
1. Check the script source code for `command -v` checks
2. File an issue at https://github.com/FlossWare/VirtOS/issues
3. Update this documentation with the solution
