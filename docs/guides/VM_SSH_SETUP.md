# VirtOS VM SSH Setup Guide

**Last Updated**: 2026-06-06  
**Status**: Production Ready

## Quick Start

### Create VM with SSH Access

```bash
# Option 1: Using VirtOS ISO (Recommended)
virtos-create-vm \
  --name web-server \
  --cpu 2 \
  --ram 4096 \
  --disk 20G \
  --iso /path/to/virtos-0.1.iso \
  --ssh-key ~/.ssh/id_rsa.pub \
  --auto-start

# Option 2: Using cloud-init
virtos-cloud-init create web-server --ssh-key ~/.ssh/id_rsa.pub
virtos-cloud-init generate web-server
virtos-create-vm \
  --name web-server \
  --cpu 2 \
  --ram 4096 \
  --disk 20G \
  --iso /var/lib/virtos/cloud-init/web-server-cloud-init.iso \
  --auto-start
```

### Connect via SSH

```bash
# Find VM IP address
virsh domifaddr web-server
# or
virsh net-dhcp-leases default

# Connect
ssh tc@<vm-ip>
```

## Understanding the Problem

### Why SSH Didn't Work Before

Previous versions of `virtos-create-vm` created VMs with **empty hard disk images**:

```bash
# Old behavior (BROKEN)
virtos-create-vm --name test --cpu 2 --ram 4096 --disk 20G
# Result: VM with blank disk, nothing boots, no SSH
```

**Root cause**: The command only created a blank qcow2 disk image without installing any operating system. VMs couldn't boot, so no SSH server could run.

### How It Works Now

The fixed version supports bootable ISOs:

```bash
# New behavior (WORKING)
virtos-create-vm --name test --cpu 2 --ram 4096 --disk 20G --iso virtos.iso
# Result: VM boots from ISO, SSH server starts, SSH works!
```

**How it works**:
1. Creates blank disk for persistent storage
2. Attaches bootable ISO as CDROM device
3. Configures VM to boot from CDROM first
4. VM boots from ISO → OS loads → SSH starts
5. After install, boots from hard disk

## Prerequisites

### 1. Build VirtOS ISO

```bash
cd VirtOS
./build/scripts/build-all.sh

# Verify ISO exists
ls -lh build/output/virtos-*.iso
```

### 2. Generate SSH Key (if needed)

```bash
# Check for existing key
ls ~/.ssh/id_rsa.pub

# Generate new key if needed
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "your-email@example.com"
```

## Usage Examples

### Example 1: Simple Web Server

```bash
# Create VM
virtos-create-vm \
  --name web-1 \
  --cpu 2 \
  --ram 4096 \
  --disk 20G \
  --iso build/output/virtos-0.1.iso \
  --ssh-key ~/.ssh/id_rsa.pub \
  --auto-start

# Wait 30-60 seconds for boot

# Get IP address
VM_IP=$(virsh domifaddr web-1 | awk '/ipv4/ {print $4}' | cut -d/ -f1)

# Connect via SSH
ssh tc@$VM_IP

# Install web server
tce-load -wi nginx
sudo /usr/local/etc/init.d/nginx start
```

### Example 2: Database Server with Static IP

```bash
# Create cloud-init with static IP
virtos-cloud-init create db-1 \
  --hostname database \
  --network static \
  --ip 192.168.122.100/24 \
  --gateway 192.168.122.1 \
  --dns 8.8.8.8 \
  --ssh-key ~/.ssh/id_rsa.pub

# Generate cloud-init ISO
virtos-cloud-init generate db-1

# Create VM
virtos-create-vm \
  --name db-1 \
  --cpu 4 \
  --ram 8192 \
  --disk 100G \
  --iso /var/lib/virtos/cloud-init/db-1-cloud-init.iso \
  --auto-start

# Connect with fixed IP
ssh tc@192.168.122.100
```

### Example 3: High-Performance VM

```bash
# Use performance profile
virtos-create-vm \
  --name app-server \
  --cpu 8 \
  --ram 16384 \
  --disk 200G \
  --os performance \
  --iso build/output/virtos-0.1.iso \
  --ssh-key ~/.ssh/id_rsa.pub \
  --policy spread \
  --auto-start
```

### Example 4: Secure VM

```bash
# Use secure profile (encrypted disk)
virtos-create-vm \
  --name secure-vm \
  --cpu 4 \
  --ram 8192 \
  --disk 50G \
  --os secure \
  --iso build/output/virtos-0.1.iso \
  --ssh-key ~/.ssh/id_rsa.pub \
  --network isolated \
  --auto-start
```

## Troubleshooting

### VM Won't Boot

**Symptom**: VM starts but nothing happens

**Cause**: ISO path is incorrect or ISO doesn't exist

**Solution**:
```bash
# Verify ISO exists
ls -lh /path/to/virtos.iso

# Use absolute path
virtos-create-vm --name test --cpu 2 --ram 4096 --disk 20G \
  --iso $(pwd)/build/output/virtos-0.1.iso
```

### SSH Connection Refused

**Symptom**: `ssh: connect to host <ip> port 22: Connection refused`

**Cause**: VM hasn't finished booting yet

**Solution**:
```bash
# Wait 30-60 seconds after starting VM
sleep 60

# Check VM is running
virsh list --all | grep web-1

# Try again
ssh tc@<vm-ip>
```

### No IP Address

**Symptom**: `virsh domifaddr` returns no IP

**Cause**: VM network not configured or DHCP not working

**Solution**:
```bash
# Check network is running
virsh net-list --all

# Start default network if needed
virsh net-start default
virsh net-autostart default

# Restart VM
virsh destroy web-1
virsh start web-1

# Wait and check again
sleep 30
virsh domifaddr web-1
```

### SSH Key Not Working

**Symptom**: SSH asks for password instead of using key

**Cause**: SSH key not properly installed in cloud-init

**Solution**:
```bash
# Verify public key exists
cat ~/.ssh/id_rsa.pub

# Recreate cloud-init with correct key
virtos-cloud-init create web-1 --ssh-key ~/.ssh/id_rsa.pub --hostname web-server
virtos-cloud-init generate web-1

# Manually connect with password first
ssh tc@<vm-ip>  # password: tc (default)

# Inside VM, check authorized_keys
cat ~/.ssh/authorized_keys

# Exit and test key auth
ssh -i ~/.ssh/id_rsa tc@<vm-ip>
```

### Can't Find VirtOS ISO

**Symptom**: ISO file not found error

**Cause**: VirtOS ISO not built yet

**Solution**:
```bash
# Build VirtOS ISO
cd VirtOS
./build/scripts/build-all.sh

# Wait for build to complete (~5-10 minutes)

# Find ISO
find build/output -name "*.iso"

# Use full path
virtos-create-vm --name test --cpu 2 --ram 4096 --disk 20G \
  --iso build/output/virtos-0.1.iso
```

## Advanced Configuration

### Custom Boot Order

```bash
# Edit VM XML after creation
virsh edit web-1

# Change boot order
<os>
  <type arch='x86_64'>hvm</type>
  <boot dev='hd'/>      <!-- Boot from hard disk first -->
  <boot dev='cdrom'/>   <!-- Fall back to CDROM -->
  <boot dev='network'/> <!-- PXE boot as last resort -->
</os>
```

### Multiple SSH Keys

```bash
# Create cloud-init config file
cat > /tmp/ssh-keys.txt <<EOF
ssh-rsa AAAAB3... user1@host1
ssh-rsa AAAAB3... user2@host2
ssh-ed25519 AAAAC3... user3@host3
EOF

# Add all keys
while read -r key; do
  virtos-cloud-init create web-1 --ssh-key <(echo "$key")
done < /tmp/ssh-keys.txt
```

### Password + SSH Key

```bash
# Enable both password and key authentication
virtos-cloud-init create web-1 \
  --user admin \
  --password 'SecureP@ssw0rd!' \
  --ssh-key ~/.ssh/id_rsa.pub

virtos-cloud-init generate web-1
```

## Best Practices

### 1. Always Use SSH Keys

**Don't do this**:
```bash
# Password-only authentication (insecure)
virtos-create-vm --name web-1 --cpu 2 --ram 4096 --disk 20G --iso virtos.iso
# Then connect with default password
ssh tc@<vm-ip>  # password: tc
```

**Do this instead**:
```bash
# SSH key authentication (secure)
virtos-create-vm --name web-1 --cpu 2 --ram 4096 --disk 20G \
  --iso virtos.iso --ssh-key ~/.ssh/id_rsa.pub
ssh tc@<vm-ip>  # No password needed
```

### 2. Use Cloud-Init for Production

**Don't do this**:
```bash
# Manually configure each VM
virtos-create-vm --name web-1 --cpu 2 --ram 4096 --disk 20G --iso virtos.iso
ssh tc@<vm-ip>
# Manually run commands...
```

**Do this instead**:
```bash
# Automated configuration with cloud-init
cat > /tmp/setup.sh <<'EOF'
#!/bin/sh
tce-load -wi nginx git
sudo /usr/local/etc/init.d/nginx start
git clone https://github.com/myapp/repo /opt/myapp
EOF

virtos-cloud-init create web-1 \
  --ssh-key ~/.ssh/id_rsa.pub \
  --packages nginx,git \
  --run /tmp/setup.sh

virtos-cloud-init generate web-1
virtos-create-vm --name web-1 --cpu 2 --ram 4096 --disk 20G \
  --iso /var/lib/virtos/cloud-init/web-1-cloud-init.iso --auto-start
```

### 3. Test Before Production

```bash
# Create test VM first
virtos-create-vm --name test-web --cpu 1 --ram 2048 --disk 10G \
  --iso virtos.iso --ssh-key ~/.ssh/id_rsa.pub --auto-start

# Verify SSH works
ssh tc@<test-vm-ip> 'echo "SSH works!"'

# Test application install
ssh tc@<test-vm-ip> 'tce-load -wi nginx && sudo /usr/local/etc/init.d/nginx start'

# If test passes, create production VM
virtos-create-vm --name prod-web --cpu 4 --ram 8192 --disk 50G \
  --iso virtos.iso --ssh-key ~/.ssh/id_rsa.pub --policy spread --auto-start
```

## Security Considerations

### 1. Protect SSH Private Keys

```bash
# Verify correct permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Never share private key
# Only install public key (.pub) on VMs
```

### 2. Disable Password Authentication

```bash
# After SSH key is working, disable password auth
ssh tc@<vm-ip>

# Edit sshd_config
sudo vi /usr/local/etc/ssh/sshd_config

# Change:
PasswordAuthentication no
PermitEmptyPasswords no

# Restart SSH
sudo /usr/local/etc/init.d/openssh restart
```

### 3. Use Firewall Rules

```bash
# Restrict SSH to specific IPs
virtos-network create secure-net --isolated
virtos-network firewall add secure-net --rule "allow from 192.168.1.0/24 to any port 22"
virtos-network firewall add secure-net --rule "deny from any to any port 22"
```

## Related Documentation

- [virtos-create-vm Manual](../man/virtos-create-vm.md)
- [virtos-cloud-init Guide](../CLOUD_INIT_GUIDE.md)
- [VirtOS Networking](../NETWORKING.md)
- [Security Hardening](../SECURITY_HARDENING.md)

## See Also

- `virtos-create-vm --help` - Full command reference
- `virtos-cloud-init --help` - Cloud-init options
- `virtos-network --help` - Network configuration
- `virsh help` - libvirt commands
