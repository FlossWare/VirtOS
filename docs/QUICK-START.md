# VirtOS Quick Start Guide

**Time to complete**: 15-20 minutes  
**Prerequisites**: VirtOS installed and running (see [INSTALLATION.md](INSTALLATION.md))

## Your First Virtual Machine

This guide walks you through creating and managing your first VM on VirtOS.

## Step 1: Verify VirtOS is Ready

```bash
# Check VirtOS status
virtos-version
# Expected: VirtOS 0.83

# Check virtualization
virsh version
# Expected: libvirt 9.0.0+, QEMU 7.2.0+

# Verify resources
virtos-monitor resources
# Expected: CPU, RAM, disk available
```

## Step 2: Prepare VM Installation Media

For this example, we'll create an Ubuntu Server VM.

### Download Ubuntu ISO

```bash
# Create ISO directory
mkdir -p ~/iso

# Download Ubuntu Server (adjust version as needed)
cd ~/iso
wget https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso

# Verify checksum (optional but recommended)
wget https://releases.ubuntu.com/22.04/SHA256SUMS
sha256sum -c SHA256SUMS 2>&1 | grep ubuntu-22.04-live-server-amd64.iso
```

## Step 3: Create the Virtual Machine

### Using virtos-create-vm (Recommended)

```bash
# Create VM with virtos-create-vm helper
virtos-create-vm \
    --name ubuntu-server-01 \
    --cpu 2 \
    --ram 4096 \
    --disk 20G \
    --os linux \
    --iso ~/iso/ubuntu-22.04-live-server-amd64.iso

# Output:
# Creating VM: ubuntu-server-01
# CPU: 2 cores
# RAM: 4096 MB
# Disk: 20 GB
# Creating disk image...
# Defining VM...
# VM created successfully
#
# Next steps:
# - Start VM: virsh start ubuntu-server-01
# - Console: virsh console ubuntu-server-01 (or VNC)
# - VNC port: 5900
```

### Using virtos-tui (Interactive Menu)

Alternatively, use the text-based menu system:

```bash
# Launch VirtOS menu
sudo virtos-tui
```

Navigate to:

1. **VM Management** → **Create New VM**
2. Fill in the form:

   ```
   VM Name: ubuntu-server-01
   CPUs: 2
   Memory (MB): 4096
   Disk Size (GB): 20
   OS Type: linux
   ISO Path: /home/admin/iso/ubuntu-22.04-live-server-amd64.iso
   ```

3. Select **Create** → **Confirm**

## Step 4: Start the VM

```bash
# Start the VM
virsh start ubuntu-server-01

# Verify it's running
virsh list
# Output:
# Id   Name                State
# ----------------------------------
# 1    ubuntu-server-01    running
```

## Step 5: Connect to the VM

### Option 1: VNC Console (GUI)

```bash
# Get VNC port
virsh vncdisplay ubuntu-server-01
# Output: :0 (which is port 5900)

# From your workstation, connect with VNC viewer
# Server: 192.168.1.100:5900
# (Replace with your VirtOS host IP)
```

### Option 2: Serial Console (Text)

```bash
# Connect to serial console
virsh console ubuntu-server-01

# Note: Press ENTER a few times if you don't see output
# To exit console: Ctrl + ]
```

## Step 6: Install Ubuntu in the VM

Follow the Ubuntu installation prompts:

1. **Language**: Select English
2. **Keyboard**: Select your layout
3. **Network**: DHCP (automatic)
4. **Storage**: Use entire disk (the 20GB virtual disk)
5. **Profile**:
   - Name: Ubuntu Admin
   - Server name: ubuntu-server-01
   - Username: ubuntu
   - Password: ********
6. **SSH**: Install OpenSSH server
7. **Packages**: Skip for now
8. **Complete**: Reboot (VM will reboot automatically)

Wait for installation to complete (~5-10 minutes).

## Step 7: Access Your VM via SSH

After the VM reboots and boots into Ubuntu:

```bash
# Find VM IP address
# Method 1: From VirtOS host
virsh domifaddr ubuntu-server-01
# Output: 192.168.122.100 (example)

# Method 2: From VM console
# Login and run: ip addr show

# SSH from VirtOS host
ssh ubuntu@192.168.122.100

# SSH from your workstation (if VirtOS has bridged network)
ssh ubuntu@192.168.122.100
```

## Step 8: Manage Your VM

### View VM Information

```bash
# Show VM details
virsh dominfo ubuntu-server-01
# Output: CPU count, memory, state, etc.

# Show VM statistics
virtos-monitor status ubuntu-server-01
# Output: CPU usage, memory usage, disk I/O, network I/O
```

### Common VM Operations

```bash
# Stop VM (graceful shutdown)
virsh shutdown ubuntu-server-01

# Force stop (like pulling power)
virsh destroy ubuntu-server-01

# Start VM
virsh start ubuntu-server-01

# Restart VM
virsh reboot ubuntu-server-01

# Pause VM (suspend to RAM)
virsh suspend ubuntu-server-01

# Resume paused VM
virsh resume ubuntu-server-01

# Delete VM (WARNING: Destructive!)
virsh destroy ubuntu-server-01
virsh undefine ubuntu-server-01 --remove-all-storage
```

## Step 9: Create a Snapshot

Snapshots let you save VM state and revert if needed.

```bash
# Create snapshot
virtos-snapshot create ubuntu-server-01 fresh-install

# List snapshots
virtos-snapshot list ubuntu-server-01
# Output:
# Snapshots for ubuntu-server-01:
# Name           Created               Description
# fresh-install  2026-05-26 10:30:00   -

# Revert to snapshot (if you break something)
virtos-snapshot revert ubuntu-server-01 fresh-install

# Delete snapshot
virtos-snapshot delete ubuntu-server-01 fresh-install
```

## Step 10: Create a Backup

```bash
# Create backup
virtos-backup create-backup ubuntu-server-01 daily

# List backups
virtos-backup list-backups ubuntu-server-01
# Output:
# Backups for ubuntu-server-01:
# 2026-05-26-daily  (20 GB)  fresh-install

# Restore from backup (if needed)
virtos-backup restore-backup ubuntu-server-01 2026-05-26-daily
```

## Next Steps

Congratulations! You've created and managed your first VM on VirtOS.

### Learn More

- **Clone this VM**: Use `virtos-template` to create template and clone
- **Network customization**: Create isolated networks with `virtos-network`
- **Storage pools**: Organize VM disks with `virtos-storage`
- **Monitoring**: Set up dashboards with `virtos-monitor`
- **High availability**: Cluster multiple hosts with `virtos-cluster`

### Common Workflows

#### Create a Windows VM

```bash
# Download Windows Server ISO (you need a license)
# Create VM with more resources
virtos-create-vm \
    --name windows-server-01 \
    --cpu 4 \
    --ram 8192 \
    --disk 60G \
    --os windows \
    --iso ~/iso/windows-server-2022.iso

# Windows needs VirtIO drivers for best performance
# Download from: https://fedorapeople.org/groups/virt/virtio-win/
```

#### Create Multiple VMs from Template

```bash
# After creating and configuring a VM
# Create template
virtos-template create-template ubuntu-server-01 ubuntu-template

# Clone from template
virtos-template instantiate ubuntu-template web-server-01
virtos-template instantiate ubuntu-template web-server-02
virtos-template instantiate ubuntu-template web-server-03

# Now you have 3 identical VMs
```

#### Set Up Isolated Network

```bash
# Create private network for web servers
virtos-network bridge-create web-tier

# Attach VMs
virtos-network bridge-attach web-server-01 web-tier
virtos-network bridge-attach web-server-02 web-tier
virtos-network bridge-attach web-server-03 web-tier

# VMs can now communicate on isolated network
```

## Common Tasks Cheat Sheet

### VM Management

```bash
virsh list --all                        # List all VMs
virsh start <vm>                        # Start VM
virsh shutdown <vm>                     # Shutdown VM
virsh destroy <vm>                      # Force stop
virsh console <vm>                      # Connect to console
virsh dominfo <vm>                      # Show VM details
```

### Networking

```bash
virtos-network list                     # List networks
virtos-network create-nat <name> <cidr> # Create NAT network
virtos-network bridge-create <name>     # Create bridge
virsh domifaddr <vm>                    # Get VM IP address
```

### Storage

```bash
virtos-storage list-pools               # List storage pools
virtos-storage create-pool <name> dir <path>  # Create pool
virtos-storage list-volumes <pool>      # List volumes
```

### Snapshots & Backups

```bash
virtos-snapshot create <vm> <name>      # Create snapshot
virtos-snapshot list <vm>               # List snapshots
virtos-snapshot revert <vm> <name>      # Revert to snapshot
virtos-backup create-backup <vm> <tag>  # Create backup
```

### Monitoring

```bash
virtos-monitor status <vm>              # VM metrics
virtos-monitor resources                # Host resources
virsh domstats <vm>                     # Detailed stats
```

## Troubleshooting

### VM Won't Start

```bash
# Check error
virsh start <vm>

# Check logs
sudo tail -f /var/log/libvirt/qemu/<vm>.log

# Common issues:
# - Insufficient memory: Reduce VM RAM or stop other VMs
# - Disk full: Clean up with virtos-storage
# - Network conflict: Check virtos-network list
```

### Can't Connect to VM

```bash
# Verify VM is running
virsh list

# Check network
virsh domifaddr <vm>
ping <vm-ip>

# Check firewall (on VirtOS host)
sudo iptables -L -n

# Verify VM network inside VM
virsh console <vm>
# Then: ip addr show, ping 8.8.8.8
```

### Poor VM Performance

```bash
# Check resource usage
virtos-monitor status <vm>

# Check host resources
virtos-monitor resources

# Solutions:
# - Add more vCPUs: virsh setvcpus <vm> 4 --config
# - Add more RAM: virsh setmem <vm> 8388608 --config
# - Use virtio drivers (Linux VMs have these by default)
```

## Getting Help

- **Full documentation**: `ls /usr/share/doc/virtos/` or [docs/](../docs/)
- **Administrator guide**: [ADMIN-GUIDE.md](ADMIN-GUIDE.md)
- **Troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **GitHub issues**: [github.com/FlossWare/VirtOS/issues](https://github.com/FlossWare/VirtOS/issues)

---

**Quick Start Guide Version**: 1.0 (2026-05-26)  
**Compatible with**: VirtOS 0.80+  
**Next**: [Administrator Guide](ADMIN-GUIDE.md)
