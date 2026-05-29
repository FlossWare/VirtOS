# VirtOS Troubleshooting Guide

**Last Updated**: 2026-05-29  
**Version**: 0.87

Complete guide for diagnosing and fixing common VirtOS issues.

## Quick Diagnosis

**Problem Type** → **Jump to Section**

- 🔴 **ISO won't boot** → [Boot Issues](#boot-issues)
- 🔨 **Build failed** → [Build Issues](#build-issues)  
- 🖥️ **VM problems** → [VM Management Issues](#vm-management-issues)
- 🌐 **Network problems** → [Network Issues](#network-issues)
- 💾 **Storage problems** → [Storage Issues](#storage-issues)
- ⚡ **Performance issues** → [Performance Issues](#performance-issues)
- 🔧 **Installation problems** → [Package/Installation Issues](#packageinstallation-issues)
- 🔌 **KVM/virtualization** → [libvirt/KVM Issues](#libvirtkvm-issues)
- 🔗 **Cluster problems** → [Cluster Issues](#cluster-issues)

## Table of Contents

- [Quick Diagnosis](#quick-diagnosis)
- [Boot Issues](#boot-issues)
- [Build Issues](#build-issues)
- [General Issues](#general-issues)
- [libvirt/KVM Issues](#libvirtkvm-issues)
- [VM Management Issues](#vm-management-issues)
- [Network Issues](#network-issues)
- [Storage Issues](#storage-issues)
- [Performance Issues](#performance-issues)
- [Cluster Issues](#cluster-issues)
- [Package/Installation Issues](#packageinstallation-issues)
- [Diagnostic Commands](#diagnostic-commands)
- [Getting Help](#getting-help)

---

## Boot Issues

### ISO Won't Boot - Black Screen

**Symptoms**:
- Black screen after USB/CD boot
- No boot menu appears
- System hangs at BIOS/UEFI

**Causes**:
- BIOS/UEFI boot mode mismatch
- Corrupted ISO image
- Incorrect USB writing method
- Secure Boot enabled

**Diagnosis**:
```bash
# Verify ISO checksum on build machine
md5sum build/output/VirtOS-*.iso
# Compare with build/output/VirtOS-*.iso.md5.txt

# Check ISO contents
file build/output/VirtOS-*.iso
# Should show: "DOS/MBR boot sector"
```

**Solutions**:

1. **Disable Secure Boot** (most common fix):
   - Reboot to BIOS/UEFI settings
   - Find Security → Secure Boot
   - Set to "Disabled"
   - Save and exit

2. **Try different boot mode**:
   - UEFI → Legacy BIOS (or vice versa)
   - Change in BIOS settings

3. **Re-write USB with different tool**:
   ```bash
   # Linux - Use dd (most reliable)
   sudo dd if=VirtOS-*.iso of=/dev/sdX bs=4M status=progress
   sudo sync
   
   # Or use Ventoy (works for both BIOS and UEFI)
   # https://www.ventoy.net/
   ```

4. **Verify ISO integrity**:
   ```bash
   # Rebuild if checksum fails
   cd build/scripts
   ./build-all.sh
   ```

### ISO Boots but Kernel Panic

**Symptoms**:
```
Kernel panic - not syncing: VFS: Unable to mount root fs
```

**Cause**: Missing initrd or kernel modules

**Solution**:
```bash
# Rebuild with correct kernel modules
cd build
# Edit build.conf - ensure KERNEL_MODULES includes required drivers
./scripts/build-all.sh
```

### ISO Boots to Console but No GUI/TUI

**Symptoms**:
- Boots to text console
- `virtos-tui` command not found
- Network works but no scripts

**Cause**: Package not loaded

**Solution**:
```bash
# Check if packages loaded
tce-load -l | grep virtos

# Manually load
tce-load -i virtos-tools

# Or add to boot list
echo virtos-tools.tcz >> /mnt/sda1/tce/onboot.lst
```

---

## Build Issues

### Build Failed - Missing Dependencies

**Symptoms**:
```
genisoimage: command not found
```
or
```
mksquashfs: not found
```

**Solution**:
```bash
# Fedora/RHEL
make install-deps-fedora

# Ubuntu/Debian
make install-deps-ubuntu

# Arch Linux
make install-deps-arch

# Or manual install
sudo dnf install genisoimage syslinux squashfs-tools  # Fedora
sudo apt install genisoimage syslinux-utils squashfs-tools  # Ubuntu
```

### Build Failed - Network Download Error

**Symptoms**:
```
wget: unable to resolve host address 'tinycorelinux.net'
```
or
```
Connection timed out
```

**Diagnosis**:
```bash
# Test network
ping -c 3 tinycorelinux.net
ping -c 3 8.8.8.8

# Test DNS
nslookup tinycorelinux.net
```

**Solutions**:

1. **Check internet connection**:
   ```bash
   # Test external connectivity
   curl -I https://google.com
   ```

2. **Try different DNS**:
   ```bash
   # Temporarily use Google DNS
   echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
   ```

3. **Use proxy if behind firewall**:
   ```bash
   export http_proxy=http://proxy.example.com:8080
   export https_proxy=http://proxy.example.com:8080
   ```

### Build Failed - Disk Space

**Symptoms**:
```
No space left on device
```

**Diagnosis**:
```bash
df -h .
du -sh build/
```

**Solution**:
```bash
# Clean old builds
make clean

# Or manually
rm -rf build/output/*
rm -rf build/download/cache/*

# Check required space (need ~2GB free)
df -h /
```

### Build Succeeds but ISO is Too Small

**Symptoms**:
- ISO only 50-100MB (should be 200MB+)
- Missing expected packages

**Diagnosis**:
```bash
# Check ISO contents
unsquashfs -ll build/output/VirtOS-*.iso

# Verify build profile
grep PROFILE= build/build.conf
```

**Solution**:
```bash
# Edit build profile
vim build/build.conf
# Change PROFILE=minimal to PROFILE=standard

# Rebuild
cd build/scripts
./build-all.sh
```

---

## General Issues

### virtos-* commands not found

**Symptom**:
```bash
bash: virtos-setup: command not found
```

**Solution**:
```bash
# Check if virtos-tools is installed
tce-load -i virtos-tools

# Verify installation
ls -l /usr/local/bin/virtos-*

# If missing, install
sudo cp /path/to/virtos-tools.tcz /mnt/sda1/tce/optional/
echo virtos-tools.tcz >> /mnt/sda1/tce/onboot.lst
tce-load -i virtos-tools
```

### Permission denied errors

**Symptom**:
```
Error: Permission denied
```

**Solution**:
```bash
# Most virtos-* commands need root
sudo virtos-setup
sudo virtos-create-vm --name test ...

# Add user to libvirt group
sudo usermod -aG libvirt $USER
# Log out and back in for group changes to take effect
```

---

## libvirt/KVM Issues

### libvirt daemon not running

**Symptom**:
```
Error: Failed to connect to libvirt
error: failed to connect to the hypervisor
```

**Diagnosis**:
```bash
# Check if libvirtd is running
ps aux | grep libvirtd

# Check systemd status
systemctl status libvirtd
```

**Solution**:
```bash
# Start libvirtd
sudo systemctl start libvirtd

# Enable at boot
sudo systemctl enable libvirtd

# If systemd not available (Tiny Core)
sudo /usr/local/etc/init.d/libvirtd start
```

### KVM module not loaded

**Symptom**:
```
Error: KVM not available
Could not access KVM kernel module
```

**Diagnosis**:
```bash
# Check if KVM module is loaded
lsmod | grep kvm

# Check CPU virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should return > 0
```

**Solution**:
```bash
# Load KVM module (Intel)
sudo modprobe kvm_intel

# Load KVM module (AMD)
sudo modprobe kvm_amd

# Make permanent
echo "kvm_intel" | sudo tee -a /etc/modules

# If CPU doesn't support virtualization:
# - Enable VT-x/AMD-V in BIOS
# - Or use containers instead of VMs
```

### Cannot access /dev/kvm

**Symptom**:
```
Error: Could not access KVM kernel module: Permission denied
```

**Solution**:
```bash
# Check permissions
ls -l /dev/kvm
# Should show: crw-rw---- 1 root kvm ...

# Add user to kvm group
sudo usermod -aG kvm $USER

# Log out and back in for group membership to take effect
# Or use: newgrp kvm
```

**Verify**:
```bash
groups
# Should include: kvm

# Test KVM access
kvm-ok
# Or: qemu-system-x86_64 -enable-kvm -version
```

**⚠️ Security Note**: NEVER use `chmod 666 /dev/kvm` - this allows any user/process to access the hypervisor, which is a severe security risk. Always use group-based access control (`chmod 660` with `kvm` group).

---

## VM Management Issues

### virtos-create-vm fails

**Symptom**:
```
Error: Failed to create VM
```

**Common Causes**:
1. Invalid VM name
2. Insufficient resources
3. Disk path doesn't exist
4. No cluster members found

**Diagnosis**:
```bash
# Check VM name is valid (alphanumeric, dash, underscore only)
echo "test-vm" | grep -E '^[a-zA-Z0-9_-]{1,64}$'

# Check available resources
free -h
nproc
df -h

# Check cluster configuration
virtos-cluster list
cat /etc/virtos/cluster.conf
```

**Solution**:
```bash
# Use valid VM name
virtos-create-vm --name web-server-01 --cpu 2 --ram 4096 --disk 20G

# Create VM directory if missing
sudo mkdir -p /var/lib/virtos/vms

# Refresh cluster cache
virtos-cluster refresh

# Use local host explicitly
virtos-create-vm --name test --cpu 1 --ram 1024 --disk 10G --require localhost
```

### VM won't start

**Symptom**:
```
Error: Failed to start domain 'test-vm'
```

**Diagnosis**:
```bash
# Check VM exists
virsh list --all

# Check VM state
virsh domstate test-vm

# Check for errors
virsh start test-vm
# Read error message carefully

# Check system logs
sudo journalctl -u libvirtd -n 50
```

**Common Issues & Solutions**:

**Disk image missing**:
```bash
# Find VM XML
virsh dumpxml test-vm | grep "source file"

# Check if disk exists
ls -lh /var/lib/virtos/vms/test-vm/test-vm.qcow2

# Create if missing
qemu-img create -f qcow2 /var/lib/virtos/vms/test-vm/test-vm.qcow2 20G
```

**Network bridge missing**:
```bash
# Check bridge exists
ip link show br0

# Create bridge
virtos-network create-bridge --name br0 --interface eth0
```

**Insufficient memory**:
```bash
# Check free memory
free -m

# Reduce VM RAM
virsh edit test-vm
# Change <memory> value to something smaller

# Or stop other VMs
virsh list
virsh shutdown other-vm
```

### VM migration fails

**Symptom**:
```
Error: Migration failed
```

**Diagnosis**:
```bash
# Check destination host is reachable
ping dest-host.local

# Check SSH access
ssh root@dest-host.local "echo test"

# Check libvirt on destination
ssh root@dest-host.local "systemctl status libvirtd"

# Check shared storage (if required)
ssh root@dest-host.local "ls -l /var/lib/virtos/vms/"
```

**Solution**:
```bash
# Ensure SSH keys are set up
ssh-copy-id root@dest-host.local

# Use shared storage or copy disk manually
scp /var/lib/virtos/vms/test-vm/test-vm.qcow2 root@dest-host:/var/lib/virtos/vms/test-vm/

# Try migration with verbose output
virtos-migrate --name test-vm --destination dest-host.local --verbose
```

---

## Network Issues

### Bridge not found

**Symptom**:
```
Error: Network bridge 'br0' not found
```

**Diagnosis**:
```bash
# List bridges
ip link show type bridge
brctl show

# List libvirt networks
virsh net-list --all
```

**Solution**:
```bash
# Create bridge using virtos-network
sudo virtos-network create-bridge --name br0 --interface eth0

# Or manually
sudo ip link add br0 type bridge
sudo ip link set br0 up
sudo ip link set eth0 master br0
```

### VMs can't access network

**Symptom**:
VM has no network connectivity

**Diagnosis**:
```bash
# From VM console (virsh console vm-name):
ip addr
ping 8.8.8.8
ping gateway

# Check VM network config
virsh dumpxml vm-name | grep -A5 interface

# Check host bridge
ip addr show br0
```

**Solution**:
```bash
# Ensure bridge has IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Make permanent
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

# Check firewall rules
sudo iptables -L -n -v

# Allow forwarding
sudo iptables -A FORWARD -i br0 -j ACCEPT
sudo iptables -A FORWARD -o br0 -j ACCEPT
```

---

## Storage Issues

### Disk image creation fails

**Symptom**:
```
Error: Failed to create disk image
```

**Diagnosis**:
```bash
# Check available disk space
df -h /var/lib/virtos/vms

# Check permissions
ls -ld /var/lib/virtos/vms
```

**Solution**:
```bash
# Create directory
sudo mkdir -p /var/lib/virtos/vms

# Fix permissions
sudo chown -R libvirt-qemu:kvm /var/lib/virtos/vms
sudo chmod 755 /var/lib/virtos/vms

# Create disk manually
sudo qemu-img create -f qcow2 /var/lib/virtos/vms/test.qcow2 20G
```

### Storage pool errors

**Symptom**:
```
Error: Storage pool 'default' not active
```

**Diagnosis**:
```bash
# List storage pools
virsh pool-list --all

# Check pool state
virsh pool-info default
```

**Solution**:
```bash
# Start pool
virsh pool-start default

# Set autostart
virsh pool-autostart default

# Create pool if missing
virtos-storage create-pool --name default --path /var/lib/virtos/vms --type dir
```

---

## Cluster Issues

### No cluster members found

**Symptom**:
```
No cluster members found
```

**Diagnosis**:
```bash
# Check cluster config
cat /etc/virtos/cluster.conf

# Check Avahi is running (for auto-discovery)
ps aux | grep avahi
systemctl status avahi-daemon

# Check network connectivity
ping other-host.local
```

**Solution**:
```bash
# Start Avahi
sudo systemctl start avahi-daemon

# Refresh cluster cache
virtos-cluster refresh

# Add hosts manually (if Avahi unavailable)
virtos-cluster add virtos-2 192.168.1.102
virtos-cluster add virtos-3 192.168.1.103

# Use static discovery
sudo vi /etc/virtos/cluster.conf
# Set: DISCOVERY_METHOD="static"

# Create static member list
sudo vi /etc/virtos/cluster-members.conf
# Add:
# virtos-1 192.168.1.101
# virtos-2 192.168.1.102
```

### Cannot SSH to cluster members

**Symptom**:
```
Permission denied (publickey)
```

**Solution**:
```bash
# Generate SSH key if not exists
ssh-keygen -t rsa -b 4096

# Copy key to other hosts
ssh-copy-id root@virtos-2.local
ssh-copy-id root@virtos-3.local

# Test SSH access
ssh root@virtos-2.local "echo test"
```

---

## Package/Installation Issues

### TCZ package won't load

**Symptom**:
```
Error loading extension virtos-tools.tcz
```

**Diagnosis**:
```bash
# Check package exists
ls -lh /mnt/sda1/tce/optional/virtos-tools.tcz

# Check dependencies
cat /mnt/sda1/tce/optional/virtos-tools.tcz.dep

# Check MD5 sum
cd /mnt/sda1/tce/optional
md5sum -c virtos-tools.tcz.md5.txt
```

**Solution**:
```bash
# Re-download package
cd /mnt/sda1/tce/optional
wget http://repo.packagecloud.io/flossware/virtos/packages/virtos-tools.tcz

# Verify checksum
md5sum virtos-tools.tcz

# Force reload
tce-load -i virtos-tools

# Check for errors
dmesg | tail
```

---

## Diagnostic Commands

### System Information
```bash
# VirtOS version
cat /usr/local/share/virtos/VERSION

# Kernel version
uname -a

# Loaded modules
lsmod | grep kvm

# libvirt version
virsh version

# System resources
free -h
nproc
df -h
```

### VM Information
```bash
# List all VMs
virsh list --all

# VM details
virsh dominfo vm-name

# VM XML
virsh dumpxml vm-name

# VM console (Ctrl+] to exit)
virsh console vm-name

# VM logs
sudo journalctl -u libvirtd | grep vm-name
```

### Network Information
```bash
# Bridges
brctl show
ip link show type bridge

# libvirt networks
virsh net-list --all
virsh net-info default

# Firewall rules
sudo iptables -L -n -v
```

### Storage Information
```bash
# Storage pools
virsh pool-list --all
virsh pool-info default

# Storage volumes
virsh vol-list default

# Disk usage
df -h /var/lib/virtos/vms
du -sh /var/lib/virtos/vms/*
```

---

## Performance Issues

### VM is Slow / Poor Performance

**Symptoms**:
- VM responds slowly
- High CPU usage on host
- Disk I/O very slow

**Diagnosis**:
```bash
# Check VM resource usage
virsh domstats vm-name

# Check host resources
top
iostat -x 1 5

# Check if using KVM acceleration
virsh dumpxml vm-name | grep kvm
# Should show: <domain type='kvm'>
```

**Solutions**:

1. **Enable KVM acceleration**:
   ```bash
   # Verify KVM available
   lsmod | grep kvm
   
   # Check CPU virtualization
   grep -E 'vmx|svm' /proc/cpuinfo
   
   # If missing, enable in BIOS
   # Look for "Intel VT-x" or "AMD-V"
   ```

2. **Allocate more resources**:
   ```bash
   # Increase CPU
   virsh setvcpus vm-name 4 --config --maximum
   virsh setvcpus vm-name 4 --config
   
   # Increase RAM  
   virsh setmem vm-name 8G --config
   ```

3. **Use virtio drivers**:
   ```bash
   # Edit VM XML
   virsh edit vm-name
   
   # Change disk to:
   <driver name='qemu' type='qcow2' cache='none' io='native'/>
   <target dev='vda' bus='virtio'/>
   
   # Change network to:
   <model type='virtio'/>
   ```

4. **Optimize disk**:
   ```bash
   # Convert to qcow2 with compression
   qemu-img convert -O qcow2 -c old.img new.qcow2
   
   # Use SSD for VM storage
   # Move /var/lib/virtos/vms to SSD mount
   ```

### High CPU Usage on Host

**Symptoms**:
- Host CPU at 100%
- Multiple VMs running slowly
- System unresponsive

**Diagnosis**:
```bash
# Find CPU hogs
top -o %CPU

# Check VM CPU allocation
for vm in $(virsh list --name); do
    echo "$vm: $(virsh vcpucount $vm)"
done

# Total allocated CPUs vs physical
virsh nodeinfo
```

**Solution**:
```bash
# Don't oversubscribe CPUs
# Rule: Total VM vCPUs < Host CPUs * 2

# Set CPU pinning for important VMs
virsh vcpupin vm-name 0 0
virsh vcpupin vm-name 1 1

# Limit CPU usage
virsh schedinfo vm-name --set vcpu_quota=50000
```

### Network Performance is Slow

**Symptoms**:
- VM network throughput < 100 Mbps
- High latency between VMs

**Diagnosis**:
```bash
# Test network speed
# Inside VM
iperf3 -c host-ip

# Check network model
virsh dumpxml vm-name | grep "model type"
```

**Solution**:
```bash
# Use virtio network
virsh edit vm-name
# Change to: <model type='virtio'/>

# Use bridge network (faster than NAT)
virtos-network create mybr --type bridged

# Enable multiqueue
virsh edit vm-name
# Add: <driver name='vhost' queues='4'/>
```

### Disk I/O is Slow

**Symptoms**:
- VM disk operations very slow
- High iowait on host

**Diagnosis**:
```bash
# Check I/O
iostat -x 1 5

# Check disk cache mode
virsh dumpxml vm-name | grep cache
```

**Solution**:
```bash
# Use optimal cache mode
virsh edit vm-name
# Change to: cache='none' io='native'

# Use raw images on SSD
qemu-img convert -O raw vm.qcow2 vm.raw

# Enable discard/TRIM
# Add to disk: <driver discard='unmap'/>

# Check host filesystem
# ext4: mount with noatime,discard
# btrfs: autodefrag,compress=zstd
```

---

## Getting Help

If issues persist:

1. **Check Logs**:
   - `/var/log/virtos/virtos.log`
   - `sudo journalctl -u libvirtd`
   - `dmesg | tail`

2. **GitHub Issues**: https://github.com/FlossWare/VirtOS/issues

3. **Documentation**:
   - [README.md](../README.md)
   - [ARCHITECTURE.md](ARCHITECTURE.md)
   - [CLAUDE.md](../CLAUDE.md)

4. **Community**:
   - GitHub Discussions
   - File detailed bug reports with logs

---

**Last Updated**: 2026-05-25  
**Version**: 1.0
