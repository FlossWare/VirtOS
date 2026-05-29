# VirtOS Troubleshooting Guide

**Last Updated**: 2026-05-29  
**Version**: 0.89  
**Status**: Comprehensive

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
- 🌐 **Web UI problems** → [Web UI Issues](#web-ui-issues)
- 🔌 **API problems** → [API Issues](#api-issues)

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
- [Web UI Issues](#web-ui-issues)
- [API Issues](#api-issues)
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
```bash

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

```bash
Kernel panic - not syncing: VFS: Unable to mount root fs
```bash

**Cause**: Missing initrd or kernel modules

**Solution**:

```bash
# Rebuild with correct kernel modules
cd build
# Edit build.conf - ensure KERNEL_MODULES includes required drivers
./scripts/build-all.sh
```bash

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
```bash

---

## Build Issues

### Build Failed - Missing Dependencies

**Symptoms**:

```bash
genisoimage: command not found
```bash

or

```bash
mksquashfs: not found
```bash

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
```bash

### Build Failed - Network Download Error

**Symptoms**:

```bash
wget: unable to resolve host address 'tinycorelinux.net'
```bash

or

```bash
Connection timed out
```bash

**Diagnosis**:

```bash
# Test network
ping -c 3 tinycorelinux.net
ping -c 3 8.8.8.8

# Test DNS
nslookup tinycorelinux.net
```bash

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

```bash
No space left on device
```bash

**Diagnosis**:

```bash
df -h .
du -sh build/
```bash

**Solution**:

```bash
# Clean old builds
make clean

# Or manually
rm -rf build/output/*
rm -rf build/download/cache/*

# Check required space (need ~2GB free)
df -h /
```bash

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
```bash

**Solution**:

```bash
# Edit build profile
vim build/build.conf
# Change PROFILE=minimal to PROFILE=standard

# Rebuild
cd build/scripts
./build-all.sh
```bash

---

## General Issues

### virtos-* commands not found

**Symptom**:

```bash
bash: virtos-setup: command not found
```bash

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
```bash

### Permission denied errors

**Symptom**:

```bash
Error: Permission denied
```bash

**Solution**:

```bash
# Most virtos-* commands need root
sudo virtos-setup
sudo virtos-create-vm --name test ...

# Add user to libvirt group
sudo usermod -aG libvirt $USER
# Log out and back in for group changes to take effect
```bash

---

## libvirt/KVM Issues

### libvirt daemon not running

**Symptom**:

```bash
Error: Failed to connect to libvirt
error: failed to connect to the hypervisor
```bash

**Diagnosis**:

```bash
# Check if libvirtd is running
ps aux | grep libvirtd

# Check systemd status
systemctl status libvirtd
```bash

**Solution**:

```bash
# Start libvirtd
sudo systemctl start libvirtd

# Enable at boot
sudo systemctl enable libvirtd

# If systemd not available (Tiny Core)
sudo /usr/local/etc/init.d/libvirtd start
```bash

### KVM module not loaded

**Symptom**:

```bash
Error: KVM not available
Could not access KVM kernel module
```bash

**Diagnosis**:

```bash
# Check if KVM module is loaded
lsmod | grep kvm

# Check CPU virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should return > 0
```bash

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
```bash

### Cannot access /dev/kvm

**Symptom**:

```bash
Error: Could not access KVM kernel module: Permission denied
```bash

**Solution**:

```bash
# Check permissions
ls -l /dev/kvm
# Should show: crw-rw---- 1 root kvm ...

# Add user to kvm group
sudo usermod -aG kvm $USER

# Log out and back in for group membership to take effect
# Or use: newgrp kvm
```bash

**Verify**:

```bash
groups
# Should include: kvm

# Test KVM access
kvm-ok
# Or: qemu-system-x86_64 -enable-kvm -version
```bash

**⚠️ Security Note**: NEVER use `chmod 666 /dev/kvm` - this allows any user/process to access the hypervisor, which is a severe security risk. Always use group-based access control (`chmod 660` with `kvm` group).

---

## VM Management Issues

### virtos-create-vm fails

**Symptom**:

```bash
Error: Failed to create VM
```bash

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
```bash

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
```bash

### VM won't start

**Symptom**:

```bash
Error: Failed to start domain 'test-vm'
```bash

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
```bash

**Common Issues & Solutions**:

**Disk image missing**:

```bash
# Find VM XML
virsh dumpxml test-vm | grep "source file"

# Check if disk exists
ls -lh /var/lib/virtos/vms/test-vm/test-vm.qcow2

# Create if missing
qemu-img create -f qcow2 /var/lib/virtos/vms/test-vm/test-vm.qcow2 20G
```bash

**Network bridge missing**:

```bash
# Check bridge exists
ip link show br0

# Create bridge
virtos-network create-bridge --name br0 --interface eth0
```bash

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
```bash

### VM migration fails

**Symptom**:

```bash
Error: Migration failed
```bash

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
```bash

**Solution**:

```bash
# Ensure SSH keys are set up
ssh-copy-id root@dest-host.local

# Use shared storage or copy disk manually
scp /var/lib/virtos/vms/test-vm/test-vm.qcow2 root@dest-host:/var/lib/virtos/vms/test-vm/

# Try migration with verbose output
virtos-migrate --name test-vm --destination dest-host.local --verbose
```bash

---

## Network Issues

### Bridge not found

**Symptom**:

```bash
Error: Network bridge 'br0' not found
```bash

**Diagnosis**:

```bash
# List bridges
ip link show type bridge
brctl show

# List libvirt networks
virsh net-list --all
```bash

**Solution**:

```bash
# Create bridge using virtos-network
sudo virtos-network create-bridge --name br0 --interface eth0

# Or manually
sudo ip link add br0 type bridge
sudo ip link set br0 up
sudo ip link set eth0 master br0
```bash

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
```bash

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
```bash

---

## Storage Issues

### Disk image creation fails

**Symptom**:

```bash
Error: Failed to create disk image
```bash

**Diagnosis**:

```bash
# Check available disk space
df -h /var/lib/virtos/vms

# Check permissions
ls -ld /var/lib/virtos/vms
```bash

**Solution**:

```bash
# Create directory
sudo mkdir -p /var/lib/virtos/vms

# Fix permissions
sudo chown -R libvirt-qemu:kvm /var/lib/virtos/vms
sudo chmod 755 /var/lib/virtos/vms

# Create disk manually
sudo qemu-img create -f qcow2 /var/lib/virtos/vms/test.qcow2 20G
```bash

### Storage pool errors

**Symptom**:

```bash
Error: Storage pool 'default' not active
```bash

**Diagnosis**:

```bash
# List storage pools
virsh pool-list --all

# Check pool state
virsh pool-info default
```bash

**Solution**:

```bash
# Start pool
virsh pool-start default

# Set autostart
virsh pool-autostart default

# Create pool if missing
virtos-storage create-pool --name default --path /var/lib/virtos/vms --type dir
```bash

---

## Cluster Issues

### No cluster members found

**Symptom**:

```bash
No cluster members found
```bash

**Diagnosis**:

```bash
# Check cluster config
cat /etc/virtos/cluster.conf

# Check Avahi is running (for auto-discovery)
ps aux | grep avahi
systemctl status avahi-daemon

# Check network connectivity
ping other-host.local
```bash

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
```bash

### Cannot SSH to cluster members

**Symptom**:

```bash
Permission denied (publickey)
```bash

**Solution**:

```bash
# Generate SSH key if not exists
ssh-keygen -t rsa -b 4096

# Copy key to other hosts
ssh-copy-id root@virtos-2.local
ssh-copy-id root@virtos-3.local

# Test SSH access
ssh root@virtos-2.local "echo test"
```bash

---

## Package/Installation Issues

### TCZ package won't load

**Symptom**:

```bash
Error loading extension virtos-tools.tcz
```bash

**Diagnosis**:

```bash
# Check package exists
ls -lh /mnt/sda1/tce/optional/virtos-tools.tcz

# Check dependencies
cat /mnt/sda1/tce/optional/virtos-tools.tcz.dep

# Check MD5 sum
cd /mnt/sda1/tce/optional
md5sum -c virtos-tools.tcz.md5.txt
```bash

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
```bash

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
```bash

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
```bash

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
```bash

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
```bash

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
```bash

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
```bash

**Solution**:

```bash
# Don't oversubscribe CPUs
# Rule: Total VM vCPUs < Host CPUs * 2

# Set CPU pinning for important VMs
virsh vcpupin vm-name 0 0
virsh vcpupin vm-name 1 1

# Limit CPU usage
virsh schedinfo vm-name --set vcpu_quota=50000
```bash

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
```bash

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
```bash

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
```bash

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
```bash

---

## Web UI Issues

### Cockpit Won't Start

**Symptoms**:

- Cannot access web UI at `https://localhost:9090`
- Connection refused error
- Cockpit service not running

**Diagnosis**:

```bash
# Check Cockpit status
sudo systemctl status cockpit

# Check if port is open
sudo netstat -tlnp | grep 9090

# Check firewall
sudo firewall-cmd --list-ports
```bash

**Solution**:

```bash
# Start Cockpit
sudo systemctl start cockpit
sudo systemctl enable cockpit

# Open firewall port
sudo firewall-cmd --add-service=cockpit --permanent
sudo firewall-cmd --reload

# For development (HTTP):
sudo systemctl start cockpit.socket
```bash

### VirtOS Module Not Showing

**Symptoms**:

- Cockpit works but VirtOS module missing
- No "VirtOS" menu item
- Module shows as disabled

**Diagnosis**:

```bash
# List installed modules
ls -la /usr/share/cockpit/

# Check VirtOS module
ls -la /usr/share/cockpit/virtos/

# Check module manifest
cat /usr/share/cockpit/virtos/manifest.json
```bash

**Solution**:

```bash
# Install VirtOS Cockpit module
sudo tce-load -wi virtos-cockpit-module.tcz

# Restart Cockpit
sudo systemctl restart cockpit

# Check browser cache (Ctrl+Shift+R to reload)

# Verify module permissions
sudo chmod -R 755 /usr/share/cockpit/virtos/
```bash

### Dashboard Shows No Data

**Symptoms**:

- Dashboard loads but shows "No VMs"
- Metrics not updating
- Cluster tab empty

**Diagnosis**:

```bash
# Check libvirt connection
virsh list --all

# Check if libvirt socket accessible
ls -la /var/run/libvirt/libvirt-sock

# Check user permissions
groups
# Should include: libvirt, kvm

# Check browser console (F12) for JavaScript errors
```bash

**Solution**:

```bash
# Add user to libvirt group
sudo usermod -aG libvirt $USER
# Log out and log back in

# Restart libvirtd
sudo systemctl restart libvirtd

# Check libvirt connection in browser console
# Should see: "Connected to libvirt"

# Reload Cockpit page (Ctrl+Shift+R)
```bash

### Certificate/HTTPS Errors

**Symptoms**:

- Browser shows "Your connection is not private"
- Certificate warning
- NET::ERR_CERT_AUTHORITY_INVALID

**Diagnosis**:

```bash
# Check Cockpit certificate
sudo ls -la /etc/cockpit/ws-certs.d/

# Check certificate validity
sudo openssl x509 -in /etc/cockpit/ws-certs.d/0-self-signed.cert -text -noout
```bash

**Solution**:

**Option 1** - Accept self-signed (development):

- Click "Advanced" in browser
- Click "Proceed to localhost (unsafe)"
- Certificate is self-signed, safe for local use

**Option 2** - Use Let's Encrypt (production):

```bash
# Install certbot
sudo tce-load -wi certbot.tcz

# Get certificate (requires public domain)
sudo certbot certonly --standalone -d virtos.example.com

# Link to Cockpit
sudo ln -sf /etc/letsencrypt/live/virtos.example.com/fullchain.pem \
    /etc/cockpit/ws-certs.d/1-letsencrypt.cert
sudo ln -sf /etc/letsencrypt/live/virtos.example.com/privkey.pem \
    /etc/cockpit/ws-certs.d/1-letsencrypt.key

# Restart Cockpit
sudo systemctl restart cockpit
```bash

**Option 3** - Disable HTTPS (development only):

```bash
# ONLY for development/testing - NOT for production
sudo systemctl edit cockpit.socket

# Add:
# [Socket]
# ListenStream=
# ListenStream=9090
# (not recommended - use self-signed instead)
```bash

---

## API Issues

### API Server Won't Start

**Symptoms**:

- `virtos-api start` fails
- Port already in use
- Permission denied for port

**Diagnosis**:

```bash
# Check what's using port 8080
sudo netstat -tlnp | grep 8080

# Try starting API
virtos-api start

# Check for permission errors
virtos-api start --port 80
# Ports < 1024 require root
```bash

**Solution**:

```bash
# Use different port
virtos-api start --port 9080

# Or stop conflicting service
sudo systemctl stop jenkins  # Example
virtos-api start

# For privileged port (< 1024), use sudo
sudo virtos-api start --port 80
```bash

### Connection Refused

**Symptoms**:

- `curl http://localhost:8080/api/v1/health` fails
- Connection refused
- Cannot reach API

**Diagnosis**:

```bash
# Check if API is running
ps aux | grep virtos-api

# Check port binding
sudo netstat -tlnp | grep virtos-api

# Check firewall
sudo firewall-cmd --list-ports
```bash

**Solution**:

```bash
# Start API server
virtos-api start

# Open firewall port
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload

# For remote access, bind to specific IP
virtos-api start --host 192.168.1.10 --port 8080
```bash

### 503 Service Unavailable

**Symptoms**:

- API returns `{"error":"libvirt not available"}`
- 503 status code
- Cannot list VMs

**Diagnosis**:

```bash
# Check libvirt status
sudo systemctl status libvirtd

# Try virsh directly
virsh list --all

# Check libvirt socket
ls -la /var/run/libvirt/libvirt-sock
```bash

**Solution**:

```bash
# Start libvirtd
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

# Verify libvirt works
virsh list --all

# Restart API
virtos-api stop
virtos-api start

# Test API
curl http://localhost:8080/api/v1/health
# Should return: {"status":"ok","version":"0.89"}
```bash

### 400 Bad Request - Invalid VM Name

**Symptoms**:

- API returns `{"error":"Invalid VM name format"}`
- 400 status code
- VM operations fail

**Diagnosis**:

```bash
# Test API with VM name
curl http://localhost:8080/api/v1/vms/test-vm
# Valid: alphanumeric, hyphens, underscores

curl http://localhost:8080/api/v1/vms/test%20vm
# Invalid: contains space

curl http://localhost:8080/api/v1/vms/../etc/passwd
# Invalid: path traversal attempt
```bash

**Solution**:

VM names must match pattern: `^[a-zA-Z0-9_-]+$`

**Valid names**:

- `web-1`
- `db_server`
- `test-vm-01`

**Invalid names**:

- `test vm` (space)
- `vm@host` (@ symbol)
- `../etc/passwd` (path traversal)

```bash
# Fix VM name in request
curl http://localhost:8080/api/v1/vms/web-server-1  # Valid

# List all VMs to see valid names
curl http://localhost:8080/api/v1/vms
```bash

### API Returns HTML Instead of JSON

**Symptoms**:

- Expected JSON response
- Got HTML error page
- Content-Type is text/html

**Diagnosis**:

```bash
# Check response headers
curl -i http://localhost:8080/api/v1/vms

# Should see:
# Content-Type: application/json

# If you see text/html, wrong endpoint
```bash

**Solution**:

Ensure you're using the correct API path:

**Correct** (API endpoints):

- `http://localhost:8080/api/v1/health`
- `http://localhost:8080/api/v1/vms`
- `http://localhost:8080/api/v1/vms/web-1`

**Incorrect** (will return HTML):

- `http://localhost:8080/` (root - no web UI here)
- `http://localhost:8080/vms` (missing /api/v1 prefix)
- `http://localhost:9090/` (that's Cockpit, not the API)

### Rate Limiting / Too Many Requests

**Symptoms**:

- API starts failing after many requests
- Connection timeouts
- Server becomes unresponsive

**Diagnosis**:

```bash
# Check API process resource usage
ps aux | grep virtos-api

# Check system load
uptime

# Check connection count
sudo netstat -an | grep 8080 | wc -l
```bash

**Solution**:

**Short-term** - Reduce request frequency:

```bash
# Add delays between requests
for vm in $(curl -s http://localhost:8080/api/v1/vms | jq -r '.vms[].name'); do
  curl http://localhost:8080/api/v1/vms/$vm
  sleep 1  # Wait 1 second between requests
done
```bash

**Long-term** - Implement rate limiting with NGINX:

```nginx
# /etc/nginx/conf.d/virtos-api.conf
limit_req_zone $binary_remote_addr zone=virtos_api:10m rate=10r/s;

server {
    listen 80;
    server_name virtos.example.com;

    location /api/ {
        limit_req zone=virtos_api burst=20;
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```bash

```bash
# Restart NGINX
sudo systemctl restart nginx

# Access API through NGINX
curl http://virtos.example.com/api/v1/health
```bash

---

## Getting Help

If issues persist:

1. **Check Logs**:
   - `/var/log/virtos/virtos.log`
   - `sudo journalctl -u libvirtd`
   - `dmesg | tail`

2. **GitHub Issues**: <https://github.com/FlossWare/VirtOS/issues>

3. **Documentation**:
   - [README.md](../README.md)
   - [ARCHITECTURE.md](ARCHITECTURE.md)
   - [CLAUDE.md](../CLAUDE.md)

4. **Community**:
   - GitHub Discussions
   - File detailed bug reports with logs

---

**Last Updated**: 2026-05-29  
**Version**: 0.89
