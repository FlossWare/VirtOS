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
