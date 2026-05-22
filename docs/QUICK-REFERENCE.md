# Quick Reference Guide

## Remote Access

```bash
# virt-manager (GUI)
virt-manager -c qemu+ssh://vmadmin@virtos/system

# virsh (CLI)
virsh -c qemu+ssh://vmadmin@virtos/system list --all

# SSH
ssh vmadmin@virtos
```

See [REMOTE-ACCESS.md](REMOTE-ACCESS.md) for detailed setup.

## Cluster Management

```bash
# List all VirtOS instances on network
virtos-cluster list

# Show resources across cluster
virtos-cluster resources

# Node details
virtos-cluster info virtos-2

# Refresh discovery cache
virtos-cluster refresh
```

See [CLUSTERING.md](CLUSTERING.md) for multi-host setup.

## IaaS - Automated VM Placement

```bash
# Create VM with automatic placement
virtos-create-vm --name web-1 --cpu 2 --ram 4096 --disk 20G

# With OS template
virtos-create-vm --name app --cpu 4 --ram 8192 --disk 50G \
  --os ubuntu-22.04

# High availability (spread policy)
virtos-create-vm --name db --cpu 8 --ram 16384 --disk 200G \
  --policy spread --priority high

# Anti-affinity (different host than another VM)
virtos-create-vm --name db-replica --cpu 8 --ram 16384 --disk 200G \
  --anti-affinity db-primary

# Dry run (show where it would be placed)
virtos-create-vm --name test --cpu 2 --ram 4096 --disk 20G --dry-run

# Force specific host (skip scheduler)
virtos-create-vm --name special --cpu 2 --ram 4096 --disk 20G \
  --require virtos-2
```

See [IAAS.md](IAAS.md) for automated placement and scheduling.

## Backup & Restore

```bash
# Backup a VM
virtos-backup backup web-server-1

# Schedule daily backups at 2 AM
virtos-backup schedule web-server-1 --daily 02:00

# Schedule with retention policy (keep last 7)
virtos-backup schedule web-server-1 --daily 02:00 --keep 7

# Backup to remote location
virtos-backup backup web-server-1 --remote scp://backup@server:/backups

# List backups
virtos-backup list

# Restore from backup
virtos-backup restore web-server-1 2026-05-22

# Cleanup old backups
virtos-backup cleanup
```

## VM Templates

```bash
# Create template from existing VM (must be shut down)
virtos-template create ubuntu-vm ubuntu-22.04-template

# Clone from template
virtos-template clone ubuntu-22.04-template web-server-1

# Import cloud image as template
virtos-template import \
  https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img \
  ubuntu-2204-cloud

# List available templates
virtos-template list

# Delete template
virtos-template delete old-template
```

## VM Snapshots

```bash
# Create snapshot
virtos-snapshot create web-server-1 "Before update"

# Create disk-only snapshot (faster, no RAM state)
virtos-snapshot create web-server-1 "Pre-migration" --disk-only

# Create snapshot with memory state
virtos-snapshot create db-server "Debug state" --memory

# List snapshots
virtos-snapshot list web-server-1

# Revert to snapshot
virtos-snapshot revert web-server-1 snapshot-20260522-120000

# Delete snapshot
virtos-snapshot delete web-server-1 snapshot-20260520-080000

# Schedule daily snapshots at 2 AM, keep last 7
virtos-snapshot schedule web-server-1 --daily 02:00 --keep 7

# Cleanup old snapshots manually
virtos-snapshot cleanup web-server-1
```

## Monitoring & Alerts

```bash
# Start monitoring daemon
virtos-monitor start

# Stop monitoring daemon
virtos-monitor stop

# Check monitoring status
virtos-monitor status

# Run health checks once
virtos-monitor check

# View active alerts
virtos-monitor alerts

# Configure CPU threshold
virtos-monitor config cpu 90

# Configure memory threshold
virtos-monitor config memory 80

# Configure email alerts
virtos-monitor config email admin@example.com

# Configure webhook alerts
virtos-monitor config webhook https://hooks.example.com/alert
```

## High Availability (HA)

```bash
# Enable HA for a VM
virtos-ha enable web-server-1 --priority high

# Disable HA for a VM
virtos-ha disable web-server-1

# List HA-enabled VMs
virtos-ha list

# Check HA status
virtos-ha status

# Manual failover
virtos-ha failover db-server virtos-2

# Start HA daemon
virtos-ha start-daemon

# Stop HA daemon
virtos-ha stop-daemon
```

## VM Migration

```bash
# Live migration with shared storage
virtos-migrate --live --shared-storage web-1 virtos-2

# Block migration (no shared storage required)
virtos-migrate --block app-1 virtos-3

# Offline migration
virtos-migrate --offline db-server virtos-2

# Migration with bandwidth limit
virtos-migrate --live --bandwidth 100 web-1 virtos-2

# Compressed migration
virtos-migrate --block --compressed large-vm virtos-3

# Migration with auto-converge (for busy VMs)
virtos-migrate --live --auto-converge vm-1 virtos-2
```

## Resource Quotas

```bash
# Set VM CPU limit
virtos-quota set web-1 cpu 4

# Set VM memory limit
virtos-quota set db-server memory 8192

# Set VM disk limit
virtos-quota set app-1 disk 100

# Get VM quotas
virtos-quota get web-1

# Check VM quota compliance
virtos-quota check web-1

# List all quotas
virtos-quota list

# Show cluster resource usage
virtos-quota usage

# Set cluster-wide quotas
virtos-quota cluster-quota vms 100
virtos-quota cluster-quota cpu 256
virtos-quota cluster-quota memory 524288

# Enable quota enforcement
virtos-quota enforce on

# Disable quota enforcement
virtos-quota enforce off
```

## Build Commands

```bash
# Complete build (all steps)
cd build/scripts
./build-all.sh

# Individual steps
./prepare.sh      # Download and extract Tiny Core
./customize.sh    # Add FlossWare customizations  
./iso.sh          # Build bootable ISO

# Output
ls ../output/
```

## Test ISO

```bash
# In QEMU/KVM (fast)
qemu-system-x86_64 -enable-kvm -m 2048 \
    -cdrom build/output/FlossWare-Virt-*.iso

# Write to USB (DANGEROUS - verify device!)
sudo dd if=build/output/FlossWare-Virt-*.iso \
    of=/dev/sdX bs=4M status=progress && sync
```

## Helper Commands (once booted)

```bash
# First-time setup wizard (ncurses TUI)
sudo virtos-setup

# Management console (ncurses TUI)
virtos-tui

# Check KVM status
check-kvm

# Create a VM
create-vm myvm 20 /path/to/installer.iso

# Create remote user
add-user.sh vmadmin

# Check system info
cat /etc/virtos/version.txt

# Load extensions
tce-load -i qemu       # KVM/QEMU
tce-load -i lxc        # LXC containers
tce-load -i docker     # Docker
tce-load -i podman     # Podman
tce-load -i containerd # containerd
```

## KVM/QEMU

```bash
# Create disk image
qemu-img create -f qcow2 disk.qcow2 20G

# Simple VM
qemu-system-x86_64 -enable-kvm -m 2048 \
    -drive file=disk.qcow2,format=qcow2 \
    -cdrom installer.iso -boot d

# VM with networking (bridge)
qemu-system-x86_64 -enable-kvm -m 2048 \
    -drive file=disk.qcow2,format=qcow2 \
    -netdev bridge,id=net0,br=br0 \
    -device virtio-net,netdev=net0

# VM with VNC access
qemu-system-x86_64 -enable-kvm -m 2048 \
    -drive file=disk.qcow2,format=qcow2 \
    -vnc :0
# Connect with: vncviewer localhost:5900
```

## LXC

```bash
# Create container
lxc-create -n mycontainer -t download -- \
    -d ubuntu -r jammy -a amd64

# Start container
lxc-start -n mycontainer

# Attach to container
lxc-attach -n mycontainer

# List containers
lxc-ls -f

# Stop container
lxc-stop -n mycontainer

# Delete container
lxc-destroy -n mycontainer
```

## Docker

```bash
# Run container
docker run -d --name web -p 80:80 nginx

# List containers
docker ps

# View logs
docker logs web

# Execute command
docker exec -it web bash

# Stop/remove
docker stop web
docker rm web

# docker-compose
cd /path/to/compose/
docker-compose up -d
docker-compose logs
docker-compose down
```

## containerd

```bash
# Pull image
ctr image pull docker.io/library/nginx:latest

# Run container
ctr run -d docker.io/library/nginx:latest web1

# List containers
ctr task ls

# Execute command
ctr task exec --exec-id bash1 web1 bash

# Stop container
ctr task kill web1

# Remove container
ctr container delete web1
```

## Kubernetes (K3s)

```bash
# Install K3s server (first node)
curl -sfL https://get.k3s.io | sh -

# Get join token
sudo cat /var/lib/rancher/k3s/server/node-token

# Install K3s agent (other nodes)
curl -sfL https://get.k3s.io | \
  K3S_URL=https://virtos-1.local:6443 \
  K3S_TOKEN=<token> sh -

# Get nodes
sudo k3s kubectl get nodes

# Create deployment
sudo k3s kubectl create deployment nginx --image=nginx

# Scale deployment
sudo k3s kubectl scale deployment nginx --replicas=3

# Expose service
sudo k3s kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Get pods
sudo k3s kubectl get pods -o wide

# Get services
sudo k3s kubectl get svc

# Delete deployment
sudo k3s kubectl delete deployment nginx

# Uninstall K3s
sudo /usr/local/bin/k3s-uninstall.sh
```

## Networking

```bash
# Show bridges
brctl show

# Create bridge
brctl addbr br1
ifconfig br1 up

# Add interface to bridge
brctl addif br1 eth0

# Show routes
ip route

# Enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# NAT (replace eth0 with external interface)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i br0 -j ACCEPT
iptables -A FORWARD -o br0 -j ACCEPT
```

## Storage

```bash
# QEMU disk operations
qemu-img create -f qcow2 disk.qcow2 10G
qemu-img info disk.qcow2
qemu-img resize disk.qcow2 +10G
qemu-img convert -f qcow2 -O raw disk.qcow2 disk.raw

# Show mounts
mount

# Create mount point
mkdir /mnt/data
mount /dev/sdb1 /mnt/data
```

### Btrfs (if included)

```bash
# Create filesystem
mkfs.btrfs /dev/sdb1

# Mount with compression
mount -o compress=lz4 /dev/sdb1 /var/lib/vms

# Create subvolume
btrfs subvolume create /var/lib/vms/production

# Snapshot
btrfs subvolume snapshot /var/lib/vms/production \
  /var/lib/vms/backup-2026-05-22

# List subvolumes
btrfs subvolume list /var/lib/vms

# Delete snapshot
btrfs subvolume delete /var/lib/vms/backup-2026-05-22
```

### LVM (if included)

```bash
# Create physical volume
pvcreate /dev/sdb1

# Create volume group
vgcreate vg_vms /dev/sdb1

# Create logical volume
lvcreate -L 50G -n vm-disk vg_vms

# Format and mount
mkfs.ext4 /dev/vg_vms/vm-disk
mount /dev/vg_vms/vm-disk /mnt

# Extend volume
lvextend -L +50G /dev/vg_vms/vm-disk
resize2fs /dev/vg_vms/vm-disk

# Snapshot
lvcreate -L 10G -s -n vm-disk-snap /dev/vg_vms/vm-disk
```

### ZFS (if included)

```bash
# Create pool
zpool create vmpool /dev/sdb

# Create dataset with compression
zfs create vmpool/vms
zfs set compression=lz4 vmpool/vms

# Create zvol (block device)
zfs create -V 50G vmpool/vms/disk1

# Snapshot
zfs snapshot vmpool/vms@backup-2026-05-22

# Clone
zfs clone vmpool/vms@backup-2026-05-22 vmpool/test-clone

# Send to remote
zfs send vmpool/vms@backup | ssh host zfs receive pool/backup

# Pool status
zpool status
zpool iostat

# Dataset info
zfs list
zfs get compressratio vmpool/vms
```

### NFS (if included)

```bash
# Server - export directory
echo "/export/vms *(rw,sync,no_subtree_check)" >> /etc/exports
exportfs -av

# Client - mount
mount -t nfs virtos-1.local:/export/vms /var/lib/vms

# Show exports
showmount -e virtos-1.local
```

## libvirt (if installed)

```bash
# List VMs
virsh list --all

# Start VM
virsh start vmname

# Console access
virsh console vmname

# Shutdown VM
virsh shutdown vmname

# Define VM from XML
virsh define vm.xml

# Delete VM
virsh undefine vmname
```

## Persistence

```bash
# Backup configuration
filetool.sh -b

# Restore configuration
filetool.sh -r

# Edit backup list
vi /opt/.filetool.lst

# Backup now
sudo filetool.sh -b
```

## System Info

```bash
# CPU info
cat /proc/cpuinfo | grep -E "model name|vmx|svm"

# Memory
free -h

# Disk usage
df -h

# Kernel modules
lsmod

# System logs
dmesg | tail
```

## Troubleshooting

```bash
# KVM not available
lsmod | grep kvm           # Check modules loaded
check-kvm                  # Run diagnostic script
dmesg | grep kvm           # Check kernel messages

# Network issues
ip link show               # Show interfaces
brctl show                 # Show bridges
iptables -L -n -v          # Show firewall rules

# Container issues
docker info                # Docker status
systemctl status docker    # Docker service (if systemd)
journalctl -u docker       # Docker logs (if systemd)

# Disk space
du -sh /var/lib/docker     # Docker storage usage
du -sh /var/lib/lxc        # LXC storage usage
```

## File Locations

```
/opt/bootlocal.sh          - Boot script
/etc/sysctl.conf           - Kernel parameters
/etc/virtos/               - VirtOS config
/usr/local/bin/            - Helper scripts
/usr/local/share/doc/      - Documentation
/mnt/sda1/vms/             - VM storage (example)
/var/lib/lxc/              - LXC containers
/var/lib/docker/           - Docker data
```

## Boot Parameters

Edit at boot or in `/boot/grub/grub.cfg`:

```
# More memory for kernel
mem=4G

# KVM nested virtualization
kvm-intel.nested=1  # Intel
kvm-amd.nested=1    # AMD

# Console on serial
console=ttyS0,115200
```

## Performance Tuning

```bash
# CPU pinning (QEMU)
qemu-system-x86_64 -smp 4,cores=4 -cpu host

# Huge pages
echo 1024 > /proc/sys/vm/nr_hugepages

# I/O scheduler (for SSDs)
echo noop > /sys/block/sda/queue/scheduler
```
