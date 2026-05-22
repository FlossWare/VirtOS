# Remote Access to VirtOS

VirtOS supports remote management via SSH, virt-manager, and virsh.

## Overview

- **SSH Access**: Full shell access to VirtOS host
- **virt-manager**: Graphical VM management (via SSH tunnel)
- **virsh**: Command-line VM management (via SSH)
- **Cockpit** (optional): Web-based management UI

All connections use SSH for security - no extra ports needed!

## Prerequisites

### On VirtOS Host
✅ SSH server running (enabled by default)  
✅ libvirtd running (enabled by default)  
✅ Network accessible from your desktop

### On Your Desktop
- SSH client (Linux/Mac: built-in, Windows: PuTTY or OpenSSH)
- virt-manager (for GUI management)
- virsh (command-line, part of libvirt-client)

## Setting Up Access

### Step 1: Boot VirtOS

VirtOS automatically starts:
- SSH server (port 22)
- libvirtd (for VM management)
- Networking with DHCP

Find the IP address:
```bash
# On VirtOS console
ip addr show eth0
```

Or if you have DHCP server with hostname support:
```bash
# Default hostname
ping virtos
```

### Step 2: Create User (Optional but Recommended)

For security, create a non-root user:

```bash
# On VirtOS console or via SSH as root
sudo adduser vmadmin
sudo passwd vmadmin

# Add to libvirt group for VM management
sudo adduser vmadmin libvirt

# Add to sudo group (optional, for admin tasks)
sudo adduser vmadmin sudo
```

**Or use root** (less secure but simpler for home lab):
```bash
# Set root password
sudo passwd root
```

### Step 3: Set Up SSH Keys (Recommended)

From your desktop:

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy to VirtOS
ssh-copy-id vmadmin@<virtos-ip>
# or for root:
ssh-copy-id root@<virtos-ip>
```

Now you can SSH without password!

## Remote Management Methods

## 1. SSH Shell Access

### Basic Connection
```bash
# As user
ssh vmadmin@<virtos-ip>

# As root
ssh root@<virtos-ip>

# Custom port (if you changed SSH port)
ssh -p 2222 vmadmin@<virtos-ip>
```

### Example Session
```bash
ssh root@192.168.1.100

# On VirtOS
virsh list --all           # List VMs
virsh start myvm           # Start a VM
virsh console myvm         # Connect to VM console
htop                       # Monitor resources
```

## 2. virt-manager (Graphical)

### Install virt-manager on Desktop

**Debian/Ubuntu:**
```bash
sudo apt install virt-manager
```

**Fedora/RHEL:**
```bash
sudo dnf install virt-manager
```

**Arch:**
```bash
sudo pacman -S virt-manager
```

**macOS:**
```bash
brew install virt-manager
```

### Connect to VirtOS

#### Method A: GUI
1. Open virt-manager
2. **File** → **Add Connection**
3. Select **QEMU/KVM**
4. Check **Connect to remote host over SSH**
5. **Username**: `vmadmin` (or `root`)
6. **Hostname**: `<virtos-ip>` or `virtos`
7. Click **Connect**

#### Method B: Command Line
```bash
# User connection
virt-manager -c qemu+ssh://vmadmin@virtos/system

# Root connection
virt-manager -c qemu+ssh://root@virtos/system

# By IP
virt-manager -c qemu+ssh://vmadmin@192.168.1.100/system
```

### What You Can Do

Once connected in virt-manager:
- ✅ Create/delete VMs
- ✅ Start/stop/pause VMs
- ✅ Access VM console
- ✅ Configure VM hardware
- ✅ Manage virtual networks
- ✅ Manage storage pools
- ✅ Monitor performance
- ✅ Take snapshots (if storage supports it)

## 3. virsh (Command Line)

### From Your Desktop

```bash
# Connect and run commands
virsh -c qemu+ssh://vmadmin@virtos/system list --all

# Interactive session
virsh -c qemu+ssh://vmadmin@virtos/system
virsh # Now you're in virsh shell on remote VirtOS
```

### Common Commands

```bash
# List VMs
virsh -c qemu+ssh://vmadmin@virtos/system list --all

# Start VM
virsh -c qemu+ssh://vmadmin@virtos/system start myvm

# VM info
virsh -c qemu+ssh://vmadmin@virtos/system dominfo myvm

# Create VM from XML
virsh -c qemu+ssh://vmadmin@virtos/system define myvm.xml

# Connect to console
virsh -c qemu+ssh://vmadmin@virtos/system console myvm
```

### Alias for Convenience

Add to your desktop's `~/.bashrc`:

```bash
# VirtOS aliases
alias virsh-vos='virsh -c qemu+ssh://vmadmin@virtos/system'
alias virt-vos='virt-manager -c qemu+ssh://vmadmin@virtos/system &'
```

Then simply:
```bash
virsh-vos list --all
virt-vos
```

## 4. Cockpit Web UI (Optional)

If you enabled Cockpit in build.conf:

```bash
# Access in browser
https://virtos:9090
# or
https://<virtos-ip>:9090

# Login with vmadmin or root credentials
```

Features:
- Web-based VM management
- System monitoring
- Container management
- Storage management
- Network configuration

## Connection URI Reference

### Connection URI Format
```
qemu+ssh://[username@]hostname[:port]/system
```

### Examples
```bash
# Standard user connection
qemu+ssh://vmadmin@virtos/system

# Root connection
qemu+ssh://root@virtos/system

# By IP
qemu+ssh://vmadmin@192.168.1.100/system

# Custom SSH port
qemu+ssh://vmadmin@virtos:2222/system

# Session mode (user VMs, not system VMs)
qemu+ssh://vmadmin@virtos/session
```

## Troubleshooting

### Cannot Connect

**Check SSH is running on VirtOS:**
```bash
# On VirtOS console
/usr/local/etc/init.d/openssh status
# or
ps aux | grep sshd
```

**Check libvirtd is running:**
```bash
# On VirtOS console
/usr/local/etc/init.d/libvirtd status
# or
ps aux | grep libvirtd
```

**Check network connectivity:**
```bash
# From desktop
ping <virtos-ip>
ssh vmadmin@<virtos-ip> echo "SSH works"
```

### Permission Denied

**Ensure user is in libvirt group:**
```bash
# On VirtOS
groups vmadmin
# Should show: vmadmin : vmadmin libvirt

# If not, add:
sudo adduser vmadmin libvirt
```

**Check SSH key setup:**
```bash
# From desktop
ssh -v vmadmin@<virtos-ip>
# Look for "Offering public key" messages
```

### Connection Refused

**Firewall blocking SSH:**
```bash
# On VirtOS, check iptables
iptables -L -n | grep 22

# Allow SSH if blocked
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```

**SSH not listening:**
```bash
# Check SSH config
cat /etc/ssh/sshd_config | grep Port
netstat -tlnp | grep ssh
```

### libvirt Socket Error

```bash
# On VirtOS, check socket exists
ls -l /var/run/libvirt/libvirt-sock

# Restart libvirtd
/usr/local/etc/init.d/libvirtd restart
```

## Security Best Practices

### 1. Use SSH Keys, Not Passwords
```bash
# Disable password authentication (after setting up keys!)
# Edit /etc/ssh/sshd_config:
PasswordAuthentication no
```

### 2. Change Default SSH Port (Optional)
```bash
# Edit /etc/ssh/sshd_config:
Port 2222

# Then connect with:
ssh -p 2222 vmadmin@virtos
```

### 3. Restrict SSH Access
```bash
# Allow only specific users
# Edit /etc/ssh/sshd_config:
AllowUsers vmadmin

# Or allow only from specific IPs
# In iptables:
iptables -A INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j DROP
```

### 4. Use Non-Root User
- Create dedicated user for VM management
- Add to libvirt group
- Avoid using root for day-to-day access

### 5. Keep SSH Keys Secure
```bash
# Proper permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

## Advanced: Multiple VirtOS Hosts

Managing multiple VirtOS servers:

### SSH Config (~/.ssh/config)
```
Host virtos1
    HostName 192.168.1.100
    User vmadmin
    Port 22

Host virtos2
    HostName 192.168.1.101
    User vmadmin
    Port 22

Host virtos3
    HostName 192.168.1.102
    User vmadmin
    Port 22
```

Then connect simply:
```bash
ssh virtos1
virt-manager -c qemu+ssh://virtos1/system
virsh -c qemu+ssh://virtos2/system list --all
```

### virt-manager Multiple Connections

In virt-manager GUI:
1. Keep all connections visible
2. File → Add Connection for each host
3. Switch between hosts in left panel

## Network Scenarios

### Same LAN (Easiest)
```
Desktop (192.168.1.50) ←→ VirtOS (192.168.1.100)
Direct connection, no special setup needed
```

### Different Networks (VPN/Port Forwarding)
```
Desktop (anywhere) ←VPN→ Home Network ←→ VirtOS
Or use SSH port forwarding
```

### Port Forwarding Example
```bash
# Forward local port 2222 to VirtOS SSH
ssh -L 2222:virtos:22 jumphost

# Then connect
virt-manager -c qemu+ssh://vmadmin@localhost:2222/system
```

## Quick Reference

| Task | Command |
|------|---------|
| Connect virt-manager | `virt-manager -c qemu+ssh://vmadmin@virtos/system` |
| List VMs remotely | `virsh -c qemu+ssh://vmadmin@virtos/system list --all` |
| Start VM remotely | `virsh -c qemu+ssh://vmadmin@virtos/system start vmname` |
| SSH to VirtOS | `ssh vmadmin@virtos` |
| Set up SSH key | `ssh-copy-id vmadmin@virtos` |
| Check SSH status | `systemctl status sshd` or `ps aux \| grep sshd` |
| Check libvirt status | `systemctl status libvirtd` or `ps aux \| grep libvirtd` |

## See Also

- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Command cheat sheet
- [CONFIGURATION.md](CONFIGURATION.md) - Build configuration
- [GETTING-STARTED.md](GETTING-STARTED.md) - Initial setup

## Support

For issues with remote access:
- Check VirtOS is on network: `ping virtos`
- Verify SSH works: `ssh vmadmin@virtos echo "test"`
- Test libvirt locally first: `virsh -c qemu:///system list`
- Check logs on VirtOS: `dmesg | tail`, `/var/log/messages`
