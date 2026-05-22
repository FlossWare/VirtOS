# VirtOS TUI - Text User Interface

ncurses-based interfaces for VirtOS - setup wizard and management console.

## Overview

VirtOS provides two ncurses-based TUI applications:

### 1. virtos-setup - Setup Wizard

**First-time configuration wizard** for initial VirtOS setup:
- Hostname and networking
- Storage configuration
- Clustering setup
- Service enablement  
- Admin user creation

**Run once** on first boot or when reconfiguring.

### 2. virtos-tui - Management Console

**Comprehensive management interface** for day-to-day operations:
- System monitoring (CPU, RAM, disk, uptime)
- Virtual machine management
- Container management (Docker, Podman, LXC)
- Storage administration (Btrfs, LVM, ZFS, NFS)
- Cluster status and coordination
- Network configuration
- Service management
- System logs

**Use regularly** for remote management over SSH.

## virtos-setup - Setup Wizard

### Purpose

Interactive first-time configuration for VirtOS. Guides you through essential setup steps with smart defaults.

### When to Use

- **First boot** - Initial VirtOS configuration
- **Reconfiguration** - Change hostname, networking, storage
- **New hardware** - Configure after adding disks
- **Cluster setup** - Join or create a cluster

### Quick Start

```bash
# Run setup wizard (requires root)
sudo virtos-setup
```

### Setup Wizard Flow

#### 1. Welcome Screen

```
┌──────────────────────────────────────────┐
│        Welcome to VirtOS Setup Wizard    │
├──────────────────────────────────────────┤
│                                          │
│  This wizard will configure:             │
│   • Hostname and networking              │
│   • Storage for VMs                      │
│   • Clustering (optional)                │
│   • Services to enable                   │
│   • Admin user account                   │
│                                          │
│  Setup takes 5-10 minutes.               │
│                                          │
│          Ready to begin?                 │
│                                          │
│      < Yes >          < No >             │
└──────────────────────────────────────────┘
```

#### 2. Hostname Configuration

**Prompts:**
- Hostname (e.g., `virtos-1`)
- Domain name (e.g., `local`)

**Result:** Sets system hostname

#### 3. Network Configuration

**Choose networking mode:**

**DHCP (Recommended)**
- Automatic IP assignment
- No manual configuration
- Works immediately

**Static IP**
- Manual IP address
- Netmask
- Gateway
- DNS server

**Result:** Configures network interfaces

#### 4. Storage Configuration

**Detects available disks:**
```
/dev/sda  238G
/dev/sdb  1.8T
/dev/sdc  1.8T
```

**Configure dedicated storage for VMs?**
- Yes → Choose disk and filesystem
- No → Skip (use default storage)

**Filesystem options:**
- **ext4** - Simple and reliable
- **btrfs** - Snapshots (recommended)
- **lvm** - Flexible volumes
- **zfs** - Enterprise features (needs 4GB+ RAM)

**Mount point:** Default `/var/lib/vms`

**⚠ WARNING:** Selected disk will be formatted!

**Result:** Creates and mounts VM storage

#### 5. Clustering Setup

**Enable multi-host clustering?**

If yes:
- **Cluster name** - All hosts must match (e.g., `homelab`)
- **NFS role:**
  - **None** - No shared storage
  - **Server** - Share VMs to other hosts
  - **Client** - Mount from another host

**Result:** Enables cluster discovery and coordination

#### 6. Service Auto-start

**Select services to enable at boot:**

[ ] libvirt - VM management
[ ] docker - Docker containers
[ ] avahi - Cluster discovery
[ ] k3s - Kubernetes

**Result:** Services start automatically on boot

#### 7. Admin User

**Create admin user for remote access?**

If yes:
- **Username** (default: `vmadmin`)
- **Password** (hidden input)

User gets:
- SSH access
- libvirt permissions (for virt-manager)
- sudo access

**Result:** User created with proper permissions

#### 8. Review Configuration

**Configuration Summary:**
```
Hostname: virtos-1.local
Network: dhcp
Storage: btrfs on /dev/sdb → /var/lib/vms
Clustering: yes (homelab)
NFS: server
Services: libvirt docker avahi
Admin user: vmadmin
```

**Apply this configuration?**
- Yes → Proceed
- No → Cancel (no changes)

#### 9. Apply Configuration

**Progress:**
```
Applying configuration...

✓ Hostname set to virtos-1
✓ DHCP enabled (default)
✓ Storage configured: btrfs on /dev/sdb
✓ Clustering enabled: homelab
✓ NFS server configured
✓ Service enabled: libvirt
✓ Service enabled: docker
✓ Service enabled: avahi
✓ Admin user created: vmadmin

Configuration complete!
```

#### 10. Completion Screen

**Setup Complete!**
```
Your VirtOS instance is now configured:

 • Hostname: virtos-1
 • IP: 192.168.1.101

Remote Access:
 ssh vmadmin@virtos-1.local
 virt-manager -c qemu+ssh://vmadmin@virtos-1.local/system

Management Tools:
 virtos-tui       - Text UI management console
 virtos-cluster   - Cluster management
 virtos-create-vm - Create VMs with IaaS placement

Configuration saved to: /etc/virtos/setup.conf
```

**Reboot now?**
- Yes → System reboots
- No → Continue

### Setup Features

#### Smart Defaults
- DHCP networking (most common)
- No dedicated storage (works immediately)
- Clustering disabled (simple single-host)
- Minimal services (save resources)

#### Safety Warnings
- Disk format warning (data loss prevention)
- Configuration review (verify before applying)
- Already-configured check (prevent overwrite)

#### Validation
- Checks for required tools
- Detects available hardware
- Verifies disk availability
- Confirms service availability

#### Configuration Persistence
- Saves to `/etc/virtos/setup.conf`
- Backed up via `filetool.sh`
- Survives reboot
- Can be re-run to reconfigure

### Re-running Setup

Setup can be run multiple times:

```bash
sudo virtos-setup
```

**Warning shown:**
```
VirtOS appears to be already configured.

Configuration file exists: /etc/virtos/setup.conf

Run setup again?
(This will overwrite existing configuration)
```

### Setup Use Cases

#### First-Time Installation

```bash
# Boot VirtOS ISO
# Login as tc

# Run setup
sudo virtos-setup

# Follow wizard
# Reboot when complete
```

#### Add Storage After Installation

```bash
# Connect new disk
# Run setup
sudo virtos-setup

# Skip to storage configuration
# Select new disk and filesystem
```

#### Join Cluster

```bash
# Run setup
sudo virtos-setup

# Enable clustering
# Enter same cluster name as other hosts
# Set NFS role (if shared storage needed)
```

#### Create Admin User Later

```bash
# Run setup
sudo virtos-setup

# Skip to admin user section
# Create user with SSH access
```

### Configuration Files

#### /etc/virtos/setup.conf

Generated by setup wizard:

```bash
# VirtOS Configuration - Generated by virtos-setup
# 2026-05-22 10:30:15

HOSTNAME="virtos-1"
DOMAIN="local"
IP_MODE="dhcp"
STORAGE_FS="btrfs"
STORAGE_DISK="/dev/sdb"
VM_DIR="/var/lib/vms"
CLUSTERING="yes"
CLUSTER_NAME="homelab"
NFS_ROLE="server"
SERVICES="libvirt docker avahi"
ADMIN_USER="vmadmin"
```

Can be sourced by scripts or edited manually.

#### /opt/bootlocal.sh

Setup adds boot commands:

```bash
# Static IP configuration (if configured)
ifconfig eth0 192.168.1.100 netmask 255.255.255.0 up
route add default gw 192.168.1.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Service auto-start
/usr/local/etc/init.d/libvirtd start
/usr/local/etc/init.d/docker start
/usr/local/etc/init.d/avahi-daemon start
```

### Troubleshooting Setup

#### "dialog or whiptail required"

Setup TUI not available.

**Solution:**
```bash
tce-load -i dialog
sudo virtos-setup
```

#### "Setup must be run as root"

Permissions issue.

**Solution:**
```bash
sudo virtos-setup
# Not: virtos-setup
```

#### Storage disk not detected

Disk not recognized.

**Solutions:**
- Check cable connections
- Run `lsblk` to verify disk visibility
- Try different port/cable
- Check BIOS settings

#### "Clustering not available"

Build doesn't include clustering.

**Solution:**
Rebuild ISO with:
```bash
ENABLE_CLUSTERING="yes" in build.conf
```

#### NFS export fails

NFS server not starting.

**Solutions:**
- Check `/etc/exports` syntax
- Run `exportfs -av` manually
- Check firewall (allow NFS ports)
- Verify NFS packages installed

---

## virtos-tui - Management Console

**Comprehensive text-based user interface** for managing all aspects of VirtOS:

- System monitoring (CPU, RAM, disk, uptime)
- Virtual machine management
- **VM backups and restore** (Phase 6)
- **VM templates and cloning** (Phase 6)
- **VM snapshots** (Phase 6)
- **IaaS VM creation** with automatic placement (Phase 6)
- Container management (Docker, Podman, LXC)
- Storage administration (Btrfs, LVM, ZFS, NFS)
- Cluster status and coordination
- Network configuration
- Service management
- System logs

## Features

- **Text-based** - Works over SSH, no GUI needed
- **Full-featured** - Manage VMs, containers, storage, networking
- **Lightweight** - Uses dialog/whiptail (ncurses)
- **Keyboard-driven** - Fast navigation
- **Real-time info** - Current system status
- **Safe** - Confirmation prompts for destructive actions

## Requirements

VirtOS with dialog enabled:

```bash
# In build.conf
INCLUDE_DIALOG="yes"
INCLUDE_NCURSES="yes"
```

Both enabled by default in standard profile.

## Quick Start

### Launch TUI

```bash
# From VirtOS console or SSH
virtos-tui
```

### Navigation

- **Arrow keys** - Move between menu items
- **Enter** - Select item
- **Tab** - Switch between buttons
- **Esc** - Go back / cancel
- **Space** - Select checkboxes

### Root Access

Some features require root access:

```bash
# Run as root
sudo virtos-tui

# Or switch to root
sudo su
virtos-tui
```

## Main Menu

```
┌─────────────────────────────────────────────────────┐
│             VirtOS Management Console               │
├─────────────────────────────────────────────────────┤
│                                                     │
│  System: virtos                                     │
│  CPU: 8 cores | Load: 0.15, 0.10, 0.05            │
│  RAM: 4.2G / 16G | Disk: 45G / 200G (23%)         │
│  Uptime: up 2 days, 4 hours, 32 minutes           │
│                                                     │
│  Select an option:                                 │
│                                                     │
│  1  System Overview                                │
│  2  Virtual Machines (VMs)                         │
│  3  VM Backups & Restore                           │
│  4  VM Templates                                   │
│  5  VM Snapshots                                   │
│  6  IaaS VM Creation                               │
│  7  Containers                                     │
│  8  Storage Management                             │
│  9  Cluster Status                                 │
│  10 Networking                                     │
│  11 Services                                       │
│  12 System Logs                                    │
│  13 Settings                                       │
│  0 Exit                                            │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Menu Functions

### 1. System Overview

Displays comprehensive system information:

- **Hardware**: CPU model, cores, load averages
- **Memory**: Total, used, free
- **Disk**: Usage and capacity
- **Uptime**: System running time
- **VMs**: Running vs total count
- **Containers**: Running containers across all runtimes

**Use cases:**
- Quick health check
- Resource availability
- System status at a glance

### 2. Virtual Machines (VMs)

Manage KVM/QEMU virtual machines:

#### Submenu Options:
- **List All VMs** - Show all VMs with status
- **Start VM** - Boot a VM
- **Shutdown VM** - Graceful shutdown
- **Force Stop VM** - Hard stop (destroy)
- **VM Console** - Attach to VM serial console
- **VM Info** - Detailed VM information
- **Create New VM** - Launch via IaaS (virtos-create-vm)

#### Example: Start VM
```
1. Select "Start VM"
2. Enter VM name: web-1
3. VM starts
4. Returns to VM menu
```

#### Example: VM Console
```
1. Select "VM Console"
2. Enter VM name: web-1
3. Connects to serial console
4. Press Ctrl+] to exit
```

**Use cases:**
- Quick VM management over SSH
- Check VM status remotely
- Emergency VM console access

### 3. VM Backups & Restore

Automated backup and restore for VMs using virtos-backup:

#### Submenu Options:
- **List All Backups** - Show available backups
- **Backup a VM** - Create VM backup (local or remote)
- **Restore a VM** - Restore from backup by date
- **Schedule Automatic Backups** - Set up recurring backups
- **Cleanup Old Backups** - Remove old backups per retention policy
- **View Backup Statistics** - Backup summary and status

#### Example: Backup a VM
```
1. Select "Backup a VM"
2. Enter VM name: web-server-1
3. Choose destination (local or remote)
4. For remote: enter scp://user@host:/path or s3://bucket/path
5. Watch backup progress
6. Backup created with timestamp
```

#### Example: Schedule Backups
```
1. Select "Schedule Automatic Backups"
2. Enter VM name: db-server
3. Choose frequency: Daily
4. Enter time: 02:00
5. Schedule configured in cron
```

**Use cases:**
- Protect critical VMs
- Automated backup workflows
- Remote backup to off-site storage
- Point-in-time recovery

### 4. VM Templates

VM template library and cloning using virtos-template:

#### Submenu Options:
- **List Templates** - Show available templates
- **Create Template from VM** - Convert VM to reusable template
- **Clone VM from Template** - Fast VM creation via copy-on-write
- **Import Cloud Image** - Download and import cloud images
- **Delete Template** - Remove template

#### Example: Create Template
```
1. Select "Create Template from VM"
2. Enter source VM name: ubuntu-base (must be shut down)
3. Enter template name: ubuntu-22.04-template
4. Template created with disk copy
```

#### Example: Clone from Template
```
1. Select "Clone VM from Template"
2. See available templates
3. Enter template name: ubuntu-22.04-template
4. Enter new VM name: web-server-2
5. VM cloned instantly (copy-on-write)
6. Start with: virsh start web-server-2
```

**Use cases:**
- Fast VM provisioning
- Consistent base images
- Dev/test VM creation
- Golden image management

### 5. VM Snapshots

Point-in-time VM snapshots using virtos-snapshot:

#### Submenu Options:
- **List Snapshots for VM** - Show all snapshots
- **Create Snapshot** - Take VM snapshot (disk-only or with RAM)
- **Revert to Snapshot** - Restore VM to snapshot state
- **Delete Snapshot** - Remove specific snapshot
- **Schedule Automatic Snapshots** - Recurring snapshots
- **Cleanup Old Snapshots** - Remove old snapshots with retention

#### Example: Create Snapshot
```
1. Select "Create Snapshot"
2. Enter VM name: web-server-1
3. Enter description: Before upgrade
4. Choose type:
   - Disk-only (faster, no RAM state)
   - Full (includes RAM, can resume)
5. Snapshot created with timestamp
```

#### Example: Revert Snapshot
```
1. Select "Revert to Snapshot"
2. Enter VM name: web-server-1
3. See available snapshots
4. Enter snapshot name: snapshot-20260522-120000
5. Confirm revert (current state lost)
6. VM restored to snapshot state
```

**Use cases:**
- Pre-upgrade snapshots
- Development checkpoints
- Quick rollback capability
- Testing and experimentation

### 6. IaaS VM Creation

Guided VM creation with automatic cluster placement using virtos-create-vm:

#### Wizard Steps:
1. **VM Name** - Unique VM identifier
2. **CPU Cores** - Number of vCPUs
3. **Memory (RAM)** - RAM in MB
4. **Disk Size** - Disk size (e.g., 20G, 50G)
5. **Scheduling Policy**:
   - Balanced - Even distribution (default)
   - Packed - Maximize host utilization
   - Spread - Minimize VMs per host
6. **Priority Level**:
   - Normal (default)
   - High - Prefers hosts with more resources
   - Low - Uses less-capable hosts first
7. **OS Template** - Optional base image
8. **Dry Run Preview** - See placement before creating
9. **Confirmation** - Create VM on selected host

#### Example: Create VM
```
1. Select "IaaS VM Creation"
2. Enter VM name: app-server-1
3. CPU cores: 4
4. RAM: 8192 MB
5. Disk size: 50G
6. Policy: Balanced
7. Priority: High
8. OS template: ubuntu-22.04 (optional)
9. Dry run: Yes
10. See: "Best host: virtos-3 (94% fit)"
11. Confirm: Yes
12. VM created on optimal host
```

**Use cases:**
- Hands-free VM placement
- Multi-host resource optimization
- IaaS-style VM provisioning
- Balanced cluster utilization

### 7. Containers

Manage containers across all runtimes:

#### Submenu Options:
- **Docker Containers** - View Docker containers
- **Podman Containers** - View Podman containers
- **LXC Containers** - View LXC containers
- **All Containers (overview)** - Combined view

Displays:
- Container names
- Status (running, stopped, exited)
- Runtime (Docker/Podman/LXC)

**Use cases:**
- Check container status
- Overview of all container workloads
- Quick runtime comparison

### 8. Storage Management

Comprehensive storage administration:

#### Submenu Options:
- **Disk Usage Overview** - `df -h` output
- **Mounted Filesystems** - All mounts
- **Btrfs Subvolumes/Snapshots** - Btrfs management
- **LVM Volumes** - Volume groups and logical volumes
- **ZFS Pools/Datasets** - ZFS status
- **NFS Mounts** - Network mounts
- **All Storage Info** - Combined view

#### Btrfs View
Shows:
- All Btrfs mount points
- Subvolumes list
- Snapshot information

#### LVM View
Shows:
- Volume groups with sizes
- Logical volumes
- Free space

#### ZFS View
Shows:
- Pool status and health
- Datasets and compression ratios
- Available space

**Use cases:**
- Monitor disk space
- Check filesystem health
- Verify snapshots exist
- Review storage configuration

### 9. Cluster Status

Multi-host cluster management:

#### Submenu Options:
- **List Cluster Members** - All VirtOS nodes
- **Cluster Resources** - Aggregated capacity
- **Node Details** - Specific node information
- **Refresh Discovery** - Update cluster cache

Shows:
- Node names and IP addresses
- Status (up/down)
- VM count per node
- Available resources

**Use cases:**
- Cluster health monitoring
- Resource planning
- Node status verification
- Quick cluster overview

### 10. Networking

Network configuration and status:

#### Submenu Options:
- **Network Interfaces** - All NICs
- **IP Addresses** - IP configuration
- **Routing Table** - Routes
- **Bridges** - Network bridges (br0, etc.)
- **Firewall Rules** - iptables rules

**Use cases:**
- Network troubleshooting
- Verify bridge configuration
- Check firewall rules
- Review IP assignments

### 11. Services

Manage VirtOS services:

#### Available Services:
- **libvirtd** - Status and restart
- **Docker** - Status and restart
- **K3s** - Kubernetes status (if installed)
- **Avahi** - Clustering discovery
- **NFS** - Network file system
- **All processes** - Running processes view

**Use cases:**
- Service health checks
- Restart failed services
- Verify clustering services
- Process monitoring

### 12. System Logs

View system and service logs:

#### Log Options:
- **System Messages** - dmesg output
- **Kernel Errors** - Error/warning messages
- **libvirt Logs** - Virtualization logs
- **Docker Logs** - Container runtime logs
- **System Log** - syslog/messages

Shows last 50 lines by default.

**Use cases:**
- Troubleshooting errors
- Service debugging
- System diagnostics
- Kernel message review

### 13. Settings

VirtOS configuration and information:

#### Options:
- **About VirtOS** - Version and info
- **System Info** - Detailed system info (same as #1)
- **Installed Components** - Show what's included
- **Backup Configuration** - Run filetool.sh -b

#### Installed Components View
Shows checkmarks for:
- ✓ KVM/QEMU
- ✓ libvirt
- ✓ Docker
- ✓ Podman
- ✓ containerd
- ✓ LXC
- ✓ K3s
- ✓ Btrfs, LVM, ZFS
- ✓ Clustering tools

**Use cases:**
- Verify installation
- Check VirtOS version
- Backup before changes
- Component inventory

## Use Cases

### Remote Management

**SSH into VirtOS:**
```bash
ssh vmadmin@virtos.local
virtos-tui
```

Full management without GUI - perfect for:
- Headless servers
- Remote datacenters
- Low-bandwidth connections
- Terminal-only access

### Quick Health Check

```
1. Launch virtos-tui
2. Main menu shows immediate status
3. Press 1 for detailed overview
4. Exit
```

Takes 5 seconds to see complete system status.

### Emergency VM Control

```
1. SSH to VirtOS
2. virtos-tui
3. Option 2: Virtual Machines
4. Option 3: Shutdown VM (graceful)
   OR
   Option 4: Force Stop VM (emergency)
```

No need for virt-manager or virsh commands.

### Cluster Monitoring

```
1. virtos-tui
2. Option 5: Cluster Status
3. Option 1: List Cluster Members
4. View all nodes at a glance
```

Perfect for quick cluster health check.

### Storage Verification

```
1. virtos-tui
2. Option 4: Storage Management
3. Option 3: Btrfs Subvolumes
4. Verify snapshots exist
```

Confirm backups without remembering commands.

### Log Troubleshooting

```
1. virtos-tui
2. Option 8: System Logs
3. Option 2: Last 50 kernel messages
4. Review errors
```

Quick diagnostics without grep/tail commands.

## Keyboard Shortcuts

### Global Navigation
- **↑/↓ arrows** - Move between items
- **←/→ arrows** - Switch between buttons
- **Enter** - Select/OK
- **Esc** - Cancel/Back
- **Tab** - Next button
- **Shift+Tab** - Previous button

### Menu Shortcuts
- **Number key** - Direct selection (1-9, 0)
- **First letter** - Jump to item (when available)

### Text Input
- **Backspace** - Delete character
- **Ctrl+U** - Clear line
- **Ctrl+W** - Delete word

## Tips and Tricks

### Fast Navigation

Use number keys for direct menu access:
```
virtos-tui
Press 2 → VM menu
Press 1 → List VMs
```

### Check Status Quickly

The main menu updates system stats each time it displays:
```
ESC back to main menu → See updated stats
```

### Multiple Windows

Open multiple SSH sessions for comparison:
```bash
# Terminal 1
ssh vmadmin@virtos-1.local
virtos-tui
# View logs

# Terminal 2
ssh vmadmin@virtos-1.local
virtos-tui
# Monitor VMs
```

### Copy Output

For dialog-based TUI, output can be captured:
```bash
# Run specific command instead
virsh list --all
docker ps -a
zpool status
```

TUI is for viewing, CLI for scripting.

## Customization

### Color Scheme

Edit `/tmp/dialogrc` in the virtos-tui script to customize colors:

```bash
use_colors = ON
screen_color = (WHITE,BLUE,ON)      # Main background
title_color = (YELLOW,BLUE,ON)      # Title bar
button_active_color = (WHITE,RED,ON)  # Selected button
```

### Add Custom Menu Items

Edit `virtos-tui` script and add to appropriate menu function:

```bash
# In vm_management_menu() function
8 "Your Custom Action" \
```

Then add case statement:

```bash
case $CHOICE in
    ...
    8) your_custom_function ;;
esac
```

## Troubleshooting

### TUI won't start

**Error:** `dialog or whiptail required`

**Solution:**
```bash
# Load dialog package
tce-load -i dialog

# Or rebuild ISO with INCLUDE_DIALOG="yes"
```

### No VM information

**Issue:** "virsh not available"

**Solution:**
```bash
# Ensure libvirt is installed
INCLUDE_LIBVIRT="yes" in build.conf

# Or load dynamically
tce-load -i libvirt
```

### Garbled display

**Issue:** Terminal size too small or wrong encoding

**Solution:**
```bash
# Resize terminal to at least 80x25
# Set proper locale
export LANG=en_US.UTF-8
```

### Permissions denied

**Issue:** Some features require root

**Solution:**
```bash
sudo virtos-tui
# Or add user to libvirt group
sudo adduser vmadmin libvirt
```

## Comparison with Other Tools

### vs virt-manager (GUI)

| Feature | virtos-tui | virt-manager |
|---------|------------|--------------|
| **Interface** | Text (ncurses) | Graphical (GTK) |
| **Network** | Works over SSH | Needs X forwarding |
| **Resources** | <1MB RAM | ~100MB+ RAM |
| **Features** | VM+containers+storage+cluster | VMs only |
| **Speed** | Very fast | Slower over network |

**Use virtos-tui for:**
- Remote SSH access
- Low bandwidth
- Terminal preference
- Comprehensive management

**Use virt-manager for:**
- GUI preference
- VNC viewer integrated
- Visual VM installation

### vs virsh/CLI commands

| Feature | virtos-tui | virsh/CLI |
|---------|-----------|-----------|
| **Learning curve** | Easy (menus) | Harder (syntax) |
| **Speed** | Medium | Fast (if you know commands) |
| **Discovery** | Built-in (menus) | Need to know commands |
| **Scripting** | Not designed for it | Perfect for scripts |

**Use virtos-tui for:**
- Interactive management
- Quick overview
- Learning VirtOS
- Infrequent tasks

**Use CLI for:**
- Automation/scripts
- Very specific tasks
- Advanced operations
- Integration

### vs Web UI (Cockpit)

| Feature | virtos-tui | Cockpit |
|---------|-----------|---------|
| **Interface** | Text | Web browser |
| **Access** | SSH | HTTPS port |
| **Size** | ~1MB | ~50MB+ |
| **Features** | VirtOS-specific | General system |
| **Customization** | Easy (shell script) | Harder (plugins) |

**Use virtos-tui for:**
- Minimal footprint
- SSH-only access
- VirtOS-optimized
- No web server needed

## Integration with Other VirtOS Tools

### Works alongside:

**virt-manager:**
```bash
# Use TUI for quick checks
virtos-tui → Check VM status

# Use virt-manager for VM creation
virt-manager -c qemu+ssh://...
```

**virtos-cluster:**
```bash
# TUI shows cluster status
virtos-tui → Option 5

# CLI for detailed queries
virtos-cluster resources
```

**virtos-create-vm:**
```bash
# TUI provides quick access
virtos-tui → VMs → Create

# CLI for automation
virtos-create-vm --name web --cpu 2 --ram 4096 --disk 20G
```

## Future Enhancements

Planned features:
- [ ] Live VM monitoring (CPU/RAM graphs)
- [ ] Container start/stop actions
- [ ] Storage snapshot creation
- [ ] K3s pod management
- [ ] Network bridge creation
- [ ] Color themes
- [ ] Mouse support
- [ ] Configuration export

See [ROADMAP.md](ROADMAP.md) for development status.

## Getting Help

**In the TUI:**
- Navigate menus to discover features
- Most screens are informational
- Confirmation prompts before destructive actions

**Outside the TUI:**
```bash
# CLI help
man virsh
docker --help
zpool help

# VirtOS docs
cat /usr/local/share/doc/virtos/README.md
```

## Quick Reference

```bash
# Launch TUI
virtos-tui

# Launch as root
sudo virtos-tui

# Enable TUI in build
INCLUDE_DIALOG="yes" in build.conf

# Load dialog manually
tce-load -i dialog

# Customize colors
Edit /tmp/dialogrc in virtos-tui script
```

## Related Documentation

- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - CLI commands
- [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - SSH setup
- [CLUSTERING.md](CLUSTERING.md) - Multi-host management
- [STORAGE.md](STORAGE.md) - Storage management

## Summary

**virtos-tui** provides:
- ✓ Full-featured text interface
- ✓ Works over SSH
- ✓ Manages VMs, containers, storage, cluster
- ✓ Lightweight and fast
- ✓ Easy to learn
- ✓ Perfect for remote management

**Launch it:**
```bash
virtos-tui
```

Navigate with arrow keys, select with Enter. That's it!
