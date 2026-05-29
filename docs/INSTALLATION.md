# VirtOS Installation Guide

## Overview

This guide walks you through installing VirtOS from ISO to a working virtualization host in approximately 30-45 minutes.

## Prerequisites

### Hardware Requirements

**Minimum**:
- CPU: 4+ cores with VT-x (Intel) or AMD-V (AMD)
- RAM: 8 GB
- Disk: 100 GB free space
- Network: 1 Gigabit Ethernet

**Recommended**:
- CPU: 8+ cores with VT-x/AMD-V
- RAM: 32 GB or more
- Disk: 500 GB SSD
- Network: 1+ Gigabit Ethernet, static IP

**Production**:
- CPU: 16+ cores with VT-x/AMD-V
- RAM: 64 GB or more
- Disk: 1+ TB NVMe SSD
- Network: 10 Gigabit Ethernet, redundant NICs
- IPMI/BMC for remote management

### BIOS Settings

Before installation, verify these BIOS settings:

1. **Enable Virtualization**:
   - Intel: Enable "Intel VT-x" and "Intel VT-d"
   - AMD: Enable "AMD-V" and "AMD IOMMU"

2. **Boot Options**:
   - Enable "USB Boot"
   - Set boot order: USB/CD first

3. **Power Management**:
   - Disable "C-States" (for consistent performance)
   - Set performance mode if available

### Network Requirements

- Static IP address (recommended for production)
- Internet access for package downloads
- Firewall rules allowing:
  - SSH (port 22)
  - VNC/SPICE for VM consoles (ports 5900-5999)
  - libvirt migration (port 49152-49215)

## Download VirtOS

### Latest Release

```bash
# Download ISO
wget https://github.com/FlossWare/VirtOS/releases/latest/download/VirtOS.iso

# Download checksum
wget https://github.com/FlossWare/VirtOS/releases/latest/download/VirtOS.iso.sha256

# Verify checksum
sha256sum -c VirtOS.iso.sha256
```

### Build from Source (Alternative)

```bash
# Clone repository
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS

# Build ISO
cd build/scripts
./build-all.sh

# ISO is in build/output/
ls -lh ../output/VirtOS-*.iso
```

## Create Bootable Media

### USB Drive (Linux)

```bash
# Find USB device (usually /dev/sdb or /dev/sdc)
lsblk

# Write ISO to USB (replace /dev/sdX with your USB device)
sudo dd if=VirtOS.iso of=/dev/sdX bs=4M status=progress
sync

# Make it hybrid bootable (BIOS + UEFI)
sudo isohybrid --uefi VirtOS.iso
```

### USB Drive (Windows)

Use [Rufus](https://rufus.ie/):
1. Select VirtOS.iso
2. Partition scheme: GPT
3. Target system: UEFI (or BIOS)
4. Click "START"

### USB Drive (macOS)

```bash
# Find disk number
diskutil list

# Unmount (replace N with disk number)
diskutil unmountDisk /dev/diskN

# Write ISO
sudo dd if=VirtOS.iso of=/dev/rdiskN bs=4m
```

## Installation Steps

### Step 1: Boot from ISO

1. Insert USB drive or mount ISO in VM
2. Power on system
3. Press boot menu key (usually F12, F11, or ESC)
4. Select USB drive or CD/DVD
5. Wait for boot menu to appear

### Step 2: Boot Menu Selection

You'll see the Isolinux boot menu:

```
VirtOS Boot Menu
================
1. Boot VirtOS (Default)
2. Boot VirtOS (Safe Mode)
3. Boot VirtOS (Recovery Mode)
4. Memory Test
5. Boot from Hard Disk

Press ENTER or wait for automatic boot...
```

Select option 1 (or wait 10 seconds for automatic boot).

### Step 3: Desktop Environment

After boot completes (~30 seconds), you'll see:

- Tiny Core Linux desktop (FLWM window manager)
- Terminal icon
- File manager icon
- Network icon (showing connection status)

### Step 4: Run VirtOS Setup

Open a terminal and run the setup wizard:

```bash
# Launch setup wizard
sudo virtos-setup
```

The wizard will guide you through:

1. **Welcome Screen**:
   - Press ENTER to continue

2. **Network Configuration**:
   ```
   Configure Network
   =================
   [X] DHCP (automatic)
   [ ] Static IP
   
   DHCP is recommended for initial setup.
   You can configure static IP later.
   ```

3. **Hostname**:
   ```
   Enter hostname: [virtos-host-01]
   
   Hostname will be used for:
   - System identification
   - Cluster discovery
   - Management interface
   ```

4. **Storage Configuration**:
   ```
   Select VM storage location:
   
   [ ] /var/lib/libvirt/images (default)
   [ ] /mnt/vm-storage (custom)
   
   Free space: 450 GB
   ```

5. **User Account**:
   ```
   Create admin user:
   
   Username: [admin]
   Password: ********
   Confirm:  ********
   
   This user will have sudo privileges.
   ```

6. **Install System**:
   ```
   Ready to install VirtOS
   =======================
   
   Hostname: virtos-host-01
   Network:  DHCP (192.168.1.100)
   Storage:  /var/lib/libvirt/images
   User:     admin
   
   Install? [Yes/No]: Yes
   ```

7. **Installation Progress**:
   ```
   Installing VirtOS...
   [=====>              ] 35% - Installing packages...
   
   Steps:
   ✓ Partitioning disk
   ✓ Installing base system
   ✓ Installing libvirt/QEMU
   → Installing virtos-tools
   - Configuring network
   - Setting up storage
   ```

8. **Installation Complete**:
   ```
   Installation Complete!
   ======================
   
   Remove installation media and reboot.
   
   After reboot:
   - Login as: admin
   - Run: virtos-tui (menu system)
   - Or use: virtos-* commands
   
   Documentation: /usr/share/doc/virtos/
   
   [Press ENTER to reboot]
   ```

### Step 5: First Boot

1. Remove USB drive
2. System will reboot automatically
3. Login with credentials created during setup
4. Verify installation:

```bash
# Check version
virtos-version
# Output: VirtOS 0.89

# Check services
sudo systemctl status libvirtd
# Output: ● libvirtd.service - Virtualization daemon
#         Active: active (running)

# List VMs (should be empty)
virsh list --all
# Output: Id   Name   State
#         ----  ----   -----
```

## Post-Installation Configuration

### Configure Package Repository (Optional)

If you want to install additional VirtOS packages from the online repository:

```bash
# Add VirtOS packagecloud.io repository to Tiny Core mirror list
echo "https://packagecloud.io/flossware/virtos/packages/tiny_core_linux/15/x86_64/" | sudo tee -a /opt/tcemirror

# Now you can install packages with tce-load
tce-load -wi virtos-platform-java    # Platform-java integration
tce-load -wi virtos-experimental      # Experimental features (if available)

# Verify package availability
tce-ab -l | grep virtos
```

**Note**: VirtOS packages are also available directly from [GitHub Releases](https://github.com/FlossWare/VirtOS/releases).

### Set Static IP (Optional but Recommended)

```bash
# Edit network configuration
sudo vi /opt/eth0.sh

# Add static IP configuration:
#!/bin/sh
ifconfig eth0 192.168.1.100 netmask 255.255.255.0
route add default gw 192.168.1.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Make persistent
echo "/opt/eth0.sh" >> /opt/bootlocal.sh

# Apply now
sudo /opt/eth0.sh
```

### Configure SSH Access

```bash
# Start SSH server
sudo /usr/local/etc/init.d/openssh start

# Make persistent
echo "/usr/local/etc/init.d/openssh start" >> /opt/bootlocal.sh

# Add SSH key (from your workstation)
ssh-copy-id admin@192.168.1.100
```

### Set Up Storage Pool

```bash
# Create default storage pool
virtos-storage create-pool default dir /var/lib/libvirt/images

# Verify
virtos-storage list-pools
# Output:
# Storage Pools:
# ==============
# Name     Type  Capacity  Allocation  Available
# default  dir   450 GB    0 B         450 GB
```

### Configure Networking

```bash
# Create default bridge network
virtos-network bridge-create virbr0

# Enable NAT for VM internet access
virtos-network create-nat default 192.168.122.0/24

# Verify
virtos-network list
# Output:
# Name     Type    Bridge   State    Autostart
# default  nat     virbr0   active   yes
```

### Enable Backup Storage (Optional)

```bash
# Mount backup location (NFS example)
sudo mkdir -p /mnt/backup
sudo mount -t nfs backup.example.com:/exports/virtos /mnt/backup

# Make persistent
echo "backup.example.com:/exports/virtos /mnt/backup nfs defaults 0 0" | \
    sudo tee -a /etc/fstab

# Configure virtos-backup
virtos-backup configure \
    --backend local \
    --path /mnt/backup \
    --retention 30
```

## Verify Installation

Run the verification checklist:

```bash
# 1. Check version
virtos-version

# 2. Verify libvirt
virsh version

# 3. Check QEMU
qemu-system-x86_64 --version

# 4. Verify CPU virtualization
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should show number > 0

# 5. Test VM creation (dry run)
virtos-create-vm --name test-vm --cpu 2 --ram 2048 --disk 10G --dry-run

# 6. Check networking
ip addr show virbr0

# 7. Verify storage
virsh pool-list --all

# 8. Test management interface
virtos-tui --help
```

Expected output:
```
✓ VirtOS version: 0.89
✓ libvirt version: 9.0.0
✓ QEMU version: 7.2.0
✓ Virtualization: enabled (vmx)
✓ VM creation: would succeed
✓ Network bridge: virbr0 present
✓ Storage pool: default active
✓ Management: virtos-tui available
```

## Create Your First VM

Now you're ready to create your first virtual machine. See [QUICK-START.md](QUICK-START.md) for a step-by-step tutorial.

Quick example:

```bash
# Create Ubuntu VM
virtos-create-vm \
    --name ubuntu-01 \
    --cpu 2 \
    --ram 4096 \
    --disk 20G \
    --os linux

# Start VM
virsh start ubuntu-01

# Connect to console
virsh console ubuntu-01
```

## Troubleshooting

### Installation Fails

**Problem**: Setup wizard exits with error

**Solution**:
```bash
# Check logs
sudo tail -f /var/log/virtos-setup.log

# Common issues:
# - Disk space: Need 10+ GB free
# - Network: Check internet connectivity
# - Packages: Missing dependencies

# Retry installation
sudo virtos-setup --debug
```

### Boot Hangs

**Problem**: System hangs during boot

**Solution**:
1. Reboot and select "Safe Mode" from boot menu
2. Check hardware compatibility
3. Disable problematic drivers in boot options
4. Try BIOS mode instead of UEFI (or vice versa)

### Virtualization Not Available

**Problem**: `egrep '(vmx|svm)' /proc/cpuinfo` shows nothing

**Solution**:
1. Reboot into BIOS
2. Enable VT-x (Intel) or AMD-V (AMD)
3. Save and exit
4. Reboot VirtOS
5. Verify: `lscpu | grep Virtualization`

### Network Not Working

**Problem**: No network connectivity after installation

**Solution**:
```bash
# Check network interfaces
ip link show

# Restart network
sudo /etc/init.d/network restart

# Configure manually
sudo ifconfig eth0 up
sudo dhclient eth0

# Test
ping -c 3 8.8.8.8
```

## Next Steps

- **Quick Start**: [QUICK-START.md](QUICK-START.md) - Create your first VM in 15 minutes
- **Administrator Guide**: [ADMIN-GUIDE.md](ADMIN-GUIDE.md) - Complete administration reference
- **Troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common problems and solutions
- **Best Practices**: [BEST-PRACTICES.md](BEST-PRACTICES.md) - Production deployment guidance

## Getting Help

- **Documentation**: `/usr/share/doc/virtos/` or `docs/` in repository
- **GitHub Issues**: [github.com/FlossWare/VirtOS/issues](https://github.com/FlossWare/VirtOS/issues)
- **Community**: GitHub Discussions for questions

## Security Recommendations

After installation, follow the security hardening checklist:

1. **Change default passwords**
2. **Enable firewall**: `sudo ufw enable`
3. **Configure SSH keys** (disable password auth)
4. **Enable automatic updates**: `virtos-update auto-enable`
5. **Set up backups**: `virtos-backup configure`
6. **Review security guide**: [SECURITY-HARDENING.md](SECURITY-HARDENING.md)

---

**Installation Guide Version**: 1.0 (2026-05-26)  
**Compatible with**: VirtOS 0.80+  
**Next**: [Quick Start Guide](QUICK-START.md)
