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
│  7  Monitoring & Alerts                            │
│  8  High Availability (HA)                         │
│  9  VM Migration                                   │
│  10 Resource Quotas                                │
│  11 User Management (RBAC)                         │
│  12 Cloud-Init                                     │
│  13 REST API                                       │
│  14 System Updates                                 │
│  15 Disaster Recovery                              │
│  16 Containers                                     │
│  17 Storage Management                             │
│  18 Cluster Status                                 │
│  19 Networking                                     │
│  20 Services                                       │
│  21 System Logs                                    │
│  22 Settings                                       │
│  23 Distributed Storage                            │
│  24 Network Virtualization                         │
│  25 GPU Passthrough                                │
│  26 USB Devices                                    │
│  0  Exit                                           │
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

### 7. Monitoring & Alerts

Automated monitoring and alerting using virtos-monitor:

#### Submenu Options:
- **Show Monitoring Status** - View daemon status and alert history
- **View Active Alerts** - List current alerts
- **Run Health Checks Now** - Execute manual health check
- **Start Monitoring Daemon** - Begin continuous monitoring
- **Stop Monitoring Daemon** - Stop monitoring
- **Configure CPU Threshold** - Set CPU warning level (%)
- **Configure Memory Threshold** - Set memory warning level (%)
- **Configure Email Alerts** - Set email address for alerts

#### Example: Start Monitoring
```
1. Select "Start Monitoring Daemon"
2. Daemon starts with default thresholds
3. Monitors CPU, memory, disk, VMs, hosts, services
4. Sends alerts when thresholds exceeded
```

**Use cases:**
- Automated infrastructure monitoring
- Alert on resource issues
- Track system health
- Email/webhook notifications

### 8. High Availability (HA)

Automatic VM failover using virtos-ha:

#### Submenu Options:
- **List HA-Enabled VMs** - Show VMs with HA configured
- **Enable HA for VM** - Configure automatic restart/failover
- **Disable HA for VM** - Remove HA protection
- **Show HA Status** - View HA daemon and VM status
- **Manual Failover** - Force VM to different host
- **Start HA Daemon** - Begin HA monitoring
- **Stop HA Daemon** - Stop HA monitoring

#### Example: Enable HA
```
1. Select "Enable HA for VM"
2. Enter VM name: web-server-1
3. Choose priority: high/medium/low
4. HA configured with auto-restart
5. If VM fails, automatically restarts or fails over
```

**Use cases:**
- Protect critical VMs
- Automatic recovery from failures
- Minimize downtime
- Cluster-aware failover

### 9. VM Migration

Live and offline VM migration using virtos-migrate:

#### Submenu Options:
- **Live Migration (Shared Storage)** - Migrate running VM with shared disk
- **Block Migration** - Migrate VM without shared storage
- **Offline Migration** - Migrate stopped VM
- **Migration with Bandwidth Limit** - Control network usage
- **Compressed Migration** - Reduce transfer size

#### Example: Live Migration
```
1. Select "Live Migration (Shared Storage)"
2. Enter VM name: web-1
3. Enter target host: virtos-2
4. Watch migration progress
5. VM now running on virtos-2
```

**Use cases:**
- Load balancing
- Hardware maintenance
- Resource optimization
- Zero-downtime relocation

### 10. Resource Quotas

Resource limits and quotas using virtos-quota:

#### Submenu Options:
- **List All Quotas** - Show configured limits
- **Set VM Quota** - Limit CPU/memory/disk for VM
- **Check VM Compliance** - Verify VM within limits
- **Show Resource Usage** - Cluster-wide resource summary
- **Set Cluster Quota** - Global resource caps
- **Enable/Disable Enforcement** - Toggle quota enforcement

#### Example: Set VM Limits
```
1. Select "Set VM Quota"
2. Enter VM name: dev-vm
3. Set CPU limit: 4 cores
4. Set memory limit: 8192 MB
5. Set disk limit: 100 GB
6. Quota configured
```

**Use cases:**
- Resource fairness
- Prevent resource hogging
- Capacity planning
- Multi-tenant environments

### 11. User Management (RBAC)

Authentication and role-based access control using virtos-auth:

#### Submenu Options:
- **List Users** - Show all VirtOS users
- **Add User** - Create new user with role
- **Delete User** - Remove user
- **Assign Role** - Change user role
- **List Roles** - Show available roles
- **Show Role Permissions** - View role capabilities
- **Check User Permission** - Verify user access
- **Create Custom Role** - Define new role

#### Example: Add User
```
1. Select "Add User"
2. Enter username: alice
3. Choose role: operator
4. User created with operator permissions
5. Can start/stop VMs but not delete
```

**Roles:**
- **admin** - Full access to all resources
- **operator** - Manage VMs, limited admin
- **viewer** - Read-only access
- **backup-admin** - Backup/restore only

**Use cases:**
- Multi-user environments
- Least-privilege access
- Audit and compliance
- Team collaboration

### 12. Cloud-Init

VM provisioning with cloud-init using virtos-cloud-init:

#### Submenu Options:
- **Create Config** - Generate cloud-init configuration
- **Generate ISO** - Build cloud-init ISO
- **Attach ISO to VM** - Mount cloud-init disk
- **List Templates** - Show example configurations
- **Show Template** - View template example
- **Quick Setup (SSH)** - Fast VM setup with SSH key

#### Example: Quick VM Setup
```
1. Select "Quick Setup (SSH)"
2. Enter VM name: ubuntu-vm
3. Enter hostname: web-server
4. Enter username: admin
5. Select SSH key: ~/.ssh/id_rsa.pub
6. Cloud-init config created
7. ISO generated and attached
8. Start VM - auto-configured!
```

**Configuration options:**
- Hostname and users
- SSH keys
- Static IP networking
- Package installation
- Custom scripts

**Use cases:**
- Automated VM provisioning
- Consistent VM configuration
- Infrastructure as Code
- Template-based deployment

### 13. REST API

REST API server for programmatic access using virtos-api:

#### Submenu Options:
- **Start API Server** - Launch HTTP API on port 8080
- **Stop API Server** - Shutdown API
- **Show API Status** - View server state
- **Test API** - Run connectivity tests
- **Show Endpoints** - List available API routes

#### Example: Start API
```
1. Select "Start API Server"
2. Choose port (default: 8080)
3. Server starts
4. Access: http://virtos:8080/api/v1/health
5. Manage VMs via HTTP/JSON
```

**API Endpoints:**
- GET /api/v1/health - Health check
- GET /api/v1/vms - List VMs
- GET /api/v1/vms/<name> - VM details
- POST /api/v1/vms/<name>/start - Start VM
- POST /api/v1/vms/<name>/stop - Stop VM
- GET /api/v1/cluster - Cluster status

**Use cases:**
- Programmatic VM management
- Integration with tools
- Automation scripts
- Web dashboards

### 14. System Updates

VirtOS update management using virtos-update:

#### Submenu Options:
- **Check for Updates** - Scan for new versions
- **List Available Updates** - Show pending updates
- **Install Update** - Apply specific update
- **Install All Updates** - Apply all updates
- **Rollback Update** - Revert to previous version
- **View Update History** - Show past updates
- **Enable Auto-Updates** - Schedule automatic updates

#### Example: Update System
```
1. Select "Check for Updates"
2. View available updates
3. Select "Install All Updates"
4. Automatic backup created
5. Updates applied
6. Rollback available if needed
```

**Features:**
- Automatic backups before update
- Rollback capability
- Update history tracking
- Scheduled automatic updates (cron)
- Keep last 5 backups

**Use cases:**
- Keep VirtOS current
- Security patches
- Feature updates
- Safe update with rollback

### 15. Disaster Recovery

DR planning and orchestration using virtos-dr:

#### Submenu Options:
- **List DR Plans** - Show configured plans
- **Create DR Plan** - Define recovery plan with RPO/RTO
- **Show Plan Details** - View plan configuration
- **Test DR Plan** - Dry-run without changes
- **Execute DR Plan** - Run actual recovery
- **Start VM Replication** - Replicate to DR site
- **Check Replication Status** - View replication state
- **Failover to DR Site** - Switch to disaster recovery site
- **Cluster Backup** - Backup entire cluster

#### Example: Create DR Plan
```
1. Select "Create DR Plan"
2. Enter plan name: production
3. Set priority: 1 (highest)
4. Set RPO: 15 minutes (data loss tolerance)
5. Set RTO: 30 minutes (recovery time goal)
6. Enable auto-failover: yes
7. Plan created
```

#### Example: Failover
```
1. Select "Failover to DR Site"
2. Enter DR site: dr-site.example.com
3. Confirm failover (prompts for 'yes')
4. VMs stopped on primary
5. VMs started on DR site
6. Services restored
```

**DR Concepts:**
- **RPO** (Recovery Point Objective) - Max data loss tolerance
- **RTO** (Recovery Time Objective) - Target recovery time
- **Replication** - Continuous data sync to DR site
- **Failover** - Switch to DR site during disaster
- **Failback** - Return to primary site

**Use cases:**
- Business continuity planning
- Disaster preparedness
- Site-to-site replication
- Compliance requirements

### 23. Distributed Storage

Distributed storage management using virtos-storage:

#### Submenu Options:
- **List All Storage Pools** - Show all configured pools
- **Initialize Ceph Cluster** - Set up Ceph distributed storage
- **Ceph Status** - View Ceph cluster health
- **Create Ceph Pool** - Create replicated pool
- **Initialize GlusterFS** - Set up GlusterFS
- **GlusterFS Status** - View GlusterFS cluster
- **Create GlusterFS Volume** - Create replicated volume
- **List GlusterFS Volumes** - Show all volumes
- **Initialize Clustered NFS** - Set up NFS cluster
- **Add NFS Export** - Export directory
- **List NFS Exports** - Show exported directories
- **Replication Status** - View replication health

#### Example: Initialize Ceph
```
1. Select "Initialize Ceph Cluster"
2. Wait for initialization
3. Ceph cluster ready
4. Create pools with option 4
```

#### Example: Create GlusterFS Volume
```
1. Select "Create GlusterFS Volume"
2. Enter volume name: vm-storage
3. Set replicas (default: 3)
4. Volume created
5. Start with "Start GlusterFS Volume"
```

**Storage Types:**
- **Ceph** - Distributed object/block storage with replication
- **GlusterFS** - Distributed file system
- **Clustered NFS** - High-availability NFS exports

**Use cases:**
- HA storage for VMs
- Distributed VM images
- Shared storage for live migration
- Multi-host storage pools

### 24. Network Virtualization

Software-defined networking using virtos-network:

#### Submenu Options:
- **List VLANs** - Show configured VLANs
- **Create VLAN** - Create VLAN with ID
- **Attach VM to VLAN** - Assign VM to VLAN
- **Initialize OVN** - Set up Open Virtual Network
- **OVN Status** - View OVN state
- **Create Virtual Network** - Create isolated network
- **List Bridges** - Show virtual bridges
- **Create Bridge** - Create new bridge
- **Create Firewall Rule** - Per-VM firewall
- **List Firewall Rules** - Show VM rules
- **Set QoS Limit** - Bandwidth limiting
- **Show QoS Settings** - View QoS config
- **Enable SDN** - Enable SDN mode
- **SDN Status** - View SDN state

#### Example: Create VLAN
```
1. Select "Create VLAN"
2. Enter VLAN ID: 100
3. Enter name: dmz-network
4. VLAN created
5. Attach VMs with option 3
```

#### Example: Set QoS Limit
```
1. Select "Set QoS Limit"
2. Enter VM name: download-vm
3. Enter bandwidth (Mbps): 100
4. QoS limit applied
```

**Features:**
- VLAN tagging (802.1Q)
- OVN logical networks
- Per-VM firewall rules
- Bandwidth QoS
- Software-defined networking

**Use cases:**
- Network isolation
- Multi-tenant networking
- Bandwidth management
- Virtual network overlays

### 25. GPU Passthrough

GPU passthrough wizard using virtos-gpu:

#### Submenu Options:
- **Detect GPUs** - Scan for GPUs
- **List GPUs with IOMMU Groups** - Show GPU details
- **Check IOMMU Status** - Verify VT-d/IOMMU
- **Check VFIO Status** - Verify VFIO driver
- **Run Passthrough Wizard** - Interactive setup
- **Isolate GPU for Passthrough** - Bind to VFIO
- **Release GPU to Host** - Unbind from VFIO
- **Attach GPU to VM** - Assign GPU
- **Detach GPU from VM** - Remove GPU
- **Enable vGPU Support** - Virtual GPU
- **List vGPU Instances** - Show vGPUs
- **Schedule Auto-Attach** - Automatic assignment

#### Example: Interactive Wizard
```
1. Select "Run Passthrough Wizard"
2. Wizard checks IOMMU
3. Lists available GPUs
4. Enter PCI ID: 0000:01:00.0
5. GPU isolated
6. Enter VM name: gaming-vm
7. GPU attached
8. Start VM to use GPU
```

#### Example: Manual Passthrough
```
1. Select "Check IOMMU Status"
2. Verify IOMMU enabled
3. Select "Detect GPUs"
4. Note PCI ID (e.g., 0000:01:00.0)
5. Select "Isolate GPU for Passthrough"
6. Enter PCI ID
7. GPU isolated (bound to VFIO)
8. Select "Attach GPU to VM"
9. Enter VM name and PCI ID
10. GPU attached persistently
```

**Requirements:**
- IOMMU/VT-d enabled in BIOS
- Kernel parameters: intel_iommu=on (or amd_iommu=on)
- vfio-pci kernel module
- GPU in separate IOMMU group

**vGPU Support:**
- NVIDIA GRID (enterprise GPUs)
- Intel GVT-g (integrated graphics)
- SR-IOV capable GPUs

**Use cases:**
- Gaming VMs
- GPU compute workloads
- Graphics workstations
- AI/ML in VMs

### 26. USB Device Management

USB passthrough and management using virtos-usb:

#### Submenu Options:
- **List USB Devices** - Show connected USB devices
- **Attach USB to VM** - Assign USB device
- **Detach USB from VM** - Remove USB device
- **Hot-Plug USB Device** - Attach to running VM
- **Create USB Filter** - Device filter rule
- **List USB Filters** - Show filter rules
- **Enable USB Redirection** - Enable redirection
- **Redirection Status** - View redirection state
- **Start USB Monitor** - Monitor USB changes
- **Stop USB Monitor** - Stop monitoring
- **Monitor Status** - View monitor state
- **Setup Auto-Attach** - Automatic attachment

#### Example: Attach USB
```
1. Select "List USB Devices"
2. Note BUS:DEV (e.g., 001:004)
3. Select "Attach USB to VM"
4. Enter VM name: workstation-vm
5. Enter BUS:DEV: 001:004
6. USB attached (permanent)
7. Device available in VM
```

#### Example: Create USB Filter
```
1. Select "Create USB Filter"
2. Enter VM name: desktop-vm
3. Enter pattern: 046d:0825
4. Filter created
5. All Logitech webcams auto-allowed
```

#### Example: Hot-Plug
```
1. VM must be running
2. Select "Hot-Plug USB Device"
3. Enter VM name
4. Enter BUS:DEV
5. Device instantly available in VM
6. Non-persistent (removed on shutdown)
```

**Addressing:**
- BUS:DEV format (from lsusb)
- Example: 001:004
- Vendor:Product ID filtering

**Features:**
- USB 2.0 and 3.0 support
- Hot-plug for running VMs
- Device filtering by vendor/product
- USB redirection (SPICE)
- Auto-attachment rules
- USB monitoring daemon

**Use cases:**
- USB security keys
- Webcams in VMs
- USB printers
- Hardware dongles
- Development boards

### 27. Metrics & Telemetry

Metrics collection and monitoring using virtos-telemetry:

#### Submenu Options:
- **Initialize Prometheus** - Setup Prometheus server
- **Start Prometheus** - Start Prometheus service
- **Stop Prometheus** - Stop Prometheus service
- **Prometheus Status** - View Prometheus state
- **Initialize Grafana** - Setup Grafana server
- **Start Grafana** - Start Grafana service (port 3000)
- **Stop Grafana** - Stop Grafana service
- **Grafana Status** - View Grafana state
- **Install Exporter** - Add metrics exporter
- **Add Scrape Target** - Add monitoring target
- **View Metrics** - Query metrics (PromQL)
- **Create Alert Rule** - Define alert conditions
- **List Alerts** - Show alert rules
- **Dashboard List** - View Grafana dashboards
- **Import Dashboard** - Import from Grafana.com
- **Run Setup Wizard** - Guided telemetry setup

#### Example: Setup Monitoring
```
1. Select "Run Setup Wizard"
2. Choose Prometheus + Grafana
3. Select exporters to install
4. System configures everything
5. Access Grafana at http://virtos:3000
```

#### Example: Add Custom Target
```
1. Select "Add Scrape Target"
2. Enter target: 192.168.1.50:9100
3. Enter job name: remote-node
4. Target added to Prometheus config
5. Metrics scraped every 15s
```

#### Example: View Metrics
```
1. Select "View Metrics"
2. Enter query: up
3. See all targets and their status
4. Press OK to return
```

**Exporters:**
- node - System metrics (CPU, RAM, disk)
- libvirt - VM metrics
- cAdvisor - Container metrics
- blackbox - Network probes

**Features:**
- Prometheus time-series database
- Grafana dashboards
- Alert manager integration
- PromQL query language
- Dashboard templates
- Multi-target scraping

**Use cases:**
- Infrastructure monitoring
- VM performance tracking
- Container resource usage
- Alerting on issues
- Capacity planning
- SLA monitoring

### 28. Security Hardening

Security policy and hardening using virtos-security:

#### Submenu Options:
- **Initialize SELinux** - Setup SELinux (enforcing/permissive/disabled)
- **Create SELinux Policy** - New SELinux policy template
- **Compile SELinux Policy** - Compile and install policy
- **Initialize AppArmor** - Setup AppArmor (enforce/complain)
- **Create AppArmor Profile** - New AppArmor profile
- **Load AppArmor Profile** - Activate profile
- **Harden SSH** - Apply SSH hardening rules
- **Initialize Firewall** - Setup iptables firewall
- **Add Firewall Rule** - Allow/deny ports
- **Run Vulnerability Scan** - Lynis security audit
- **Compliance Check** - Check standards (CIS/NIST/PCI/HIPAA)
- **Enable Audit Logging** - Start auditd logging
- **View Audit Logs** - Show security audit logs
- **Security Status** - Complete security overview
- **Security Wizard** - Guided security setup

#### Example: Harden System
```
1. Select "Security Wizard"
2. Choose SELinux mode: Enforcing
3. Initialize firewall: Drop default
4. Apply SSH hardening: Yes
5. Enable audit logging: Yes
6. Select compliance: CIS Benchmarks
7. System hardened automatically
```

#### Example: Add Firewall Rule
```
1. Select "Add Firewall Rule"
2. Choose protocol: TCP
3. Enter port: 8080
4. Rule added and active
5. Port 8080 now accessible
```

#### Example: Compliance Check
```
1. Select "Compliance Check"
2. Choose framework: CIS Benchmarks
3. System scans configuration
4. Report shows PASS/FAIL for each check
5. Recommendations displayed
```

**Security Features:**
- SELinux mandatory access control
- AppArmor application confinement
- SSH key-only authentication
- iptables firewall
- Vulnerability scanning (Lynis)
- Compliance checking
- Audit logging

**Compliance Frameworks:**
- CIS Benchmarks
- NIST 800-53
- PCI-DSS
- HIPAA

**Use cases:**
- Regulatory compliance
- Security hardening
- Access control
- Intrusion prevention
- Audit trails
- Penetration testing

### 29. Billing & Cost Tracking

Resource usage and billing using virtos-billing:

#### Submenu Options:
- **Initialize Billing** - Setup billing database
- **Track VM Usage** - Record VM resource usage
- **Calculate Costs** - Compute resource costs
- **Cost Report** - Generate cost reports (day/week/month/year)
- **Generate Invoice** - Create customer invoice
- **List Invoices** - Show all/pending/paid invoices
- **View Invoice** - Display invoice details
- **Mark Invoice Paid** - Update payment status
- **Set Pricing** - Configure resource prices
- **Show Pricing** - Display current rates
- **Setup Wizard** - Guided billing setup

#### Example: Track Costs
```
1. Select "Track VM Usage"
2. Enter VM name: web-server
3. System records:
   - vCPU count and hours
   - RAM GB and hours
   - Disk GB usage
4. Usage tracked in database
```

#### Example: Generate Monthly Invoice
```
1. Select "Generate Invoice"
2. Enter customer: Acme Corp
3. Start date: 2026-05-01
4. End date: 2026-05-31
5. Invoice created: INV-20260531-123456
6. View or email invoice
```

#### Example: Cost Report
```
1. Select "Cost Report"
2. Choose period: Month
3. Report shows:
   - Cost by VM
   - CPU/RAM/Disk breakdown
   - Total costs
```

**Pricing Model:**
- CPU: $ per vCPU hour
- RAM: $ per GB hour
- Disk: $ per GB month
- Network: $ per GB transfer

**Features:**
- SQLite database for tracking
- Customizable pricing
- Invoice generation
- Cost reports by period
- Multi-VM tracking
- Tax calculation
- Payment status tracking

**Use cases:**
- Service provider billing
- Internal cost allocation
- Budget tracking
- Chargeback reporting
- Resource optimization
- Cost forecasting

### 30. Service Mesh

Microservices mesh integration using virtos-mesh:

#### Submenu Options:
- **Install Istio** - Deploy Istio service mesh
- **Install Linkerd** - Deploy Linkerd service mesh
- **Install Consul Connect** - Deploy Consul Connect mesh
- **Inject Sidecar** - Add proxy to deployment
- **Enable mTLS** - Activate mutual TLS
- **Create Virtual Service** - Traffic routing rules
- **Create Destination Rule** - Load balancing policies
- **Traffic Split** - Canary/blue-green deployments
- **Fault Injection** - Chaos engineering (delay/abort)
- **Circuit Breaker** - Failure handling
- **Mesh Status** - View mesh state
- **Open Dashboard** - Launch mesh UI
- **Setup Wizard** - Guided mesh installation

#### Example: Deploy Istio
```
1. Select "Install Istio"
2. System downloads Istio
3. Control plane deployed to K3s
4. Istio injector configured
5. Access Kiali dashboard
```

#### Example: Canary Deployment
```
1. Select "Traffic Split"
2. Enter service: my-app
3. Version A: v1 (90%)
4. Version B: v2 (10%)
5. 10% of traffic routes to new version
6. Monitor metrics
7. Adjust split as needed
```

#### Example: Enable mTLS
```
1. Select "Enable mTLS"
2. System configures strict mTLS
3. All service-to-service traffic encrypted
4. Certificate rotation automatic
```

**Service Mesh Options:**
- Istio - Feature-rich, production-grade
- Linkerd - Lightweight, simple
- Consul Connect - Multi-platform

**Features:**
- Mutual TLS (mTLS)
- Traffic management
- Load balancing
- Circuit breakers
- Fault injection
- Observability (metrics, tracing)
- Service discovery

**Traffic Management:**
- Canary deployments
- Blue-green deployments
- A/B testing
- Traffic splitting by percentage
- Header-based routing
- URL path routing

**Use cases:**
- Microservices security
- Zero-trust networking
- Gradual rollouts
- Chaos engineering
- Service monitoring
- Multi-cluster communication

### 22. Settings

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
- ✓ Phase 6 Tools (virtos-backup, virtos-template, virtos-snapshot)
- ✓ Phase 7 Tools (virtos-monitor, virtos-ha, virtos-migrate, virtos-quota)
- ✓ Phase 8 Tools (virtos-auth, virtos-cloud-init, virtos-api, virtos-update, virtos-dr)
- ✓ Phase 9 Tools (virtos-storage, virtos-network, virtos-gpu, virtos-usb)
- ✓ Phase 10 Tools (virtos-telemetry, virtos-security, virtos-billing, virtos-mesh)

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
