# VirtOS Cloud-init Guide

**Last Updated**: 2026-05-29  
**Version: 0.89

## What is Cloud-init?

Cloud-init is the industry-standard method for configuring cloud instances on first boot. VirtOS provides full cloud-init support through the `virtos-cloud-init` script, enabling automated VM initialization with:

- User accounts and SSH keys
- Network configuration (static IP or DHCP)
- Package installation
- Custom script execution
- Hostname configuration
- DNS and timezone settings

## Quick Start

### Basic Example - SSH-ready VM

```bash
# Create cloud-init configuration
virtos-cloud-init create myvm \
  --hostname web-server \
  --user admin \
  --ssh-key ~/.ssh/id_rsa.pub

# Generate cloud-init ISO
virtos-cloud-init generate myvm

# Create VM with cloud-init
virtos-create-vm --name myvm --cpu 2 --ram 4096 --disk 20G --cloud-init

# Cloud-init runs automatically on first boot
# VM is ready with SSH access configured
```

### Verify Cloud-init Success

```bash
# Wait for cloud-init to complete (1-2 minutes)
sleep 120

# SSH into the VM
ssh admin@myvm.local

# Check cloud-init status
cloud-init status

# View cloud-init logs
sudo cat /var/log/cloud-init-output.log
```

## Common Use Cases

### Use Case 1: Web Server with Packages

```bash
# Create web server with NGINX pre-installed
virtos-cloud-init create web-server \
  --hostname production-web \
  --user webadmin \
  --ssh-key ~/.ssh/id_rsa.pub \
  --packages nginx,certbot,git \
  --run /path/to/nginx-setup.sh

virtos-cloud-init generate web-server
virtos-create-vm --name web-server --cpu 4 --ram 8192 --disk 50G --cloud-init
```

**nginx-setup.sh example**:

```bash
#!/bin/bash
# Configure NGINX on first boot
systemctl enable nginx
systemctl start nginx
echo "Welcome to production web" > /var/www/html/index.html
```

### Use Case 2: Database Server with Static IP

```bash
# Create PostgreSQL server with static IP
virtos-cloud-init create postgres-db \
  --hostname postgres-primary \
  --user dbadmin \
  --ssh-key ~/.ssh/id_rsa.pub \
  --packages postgresql-14,postgresql-contrib \
  --network static \
  --ip 192.168.1.100/24 \
  --gateway 192.168.1.1 \
  --dns 8.8.8.8,8.8.4.4

virtos-cloud-init generate postgres-db
virtos-create-vm --name postgres-db --cpu 8 --ram 16384 --disk 200G --cloud-init
```

### Use Case 3: Kubernetes Node

```bash
# Create Kubernetes worker node
virtos-cloud-init create k8s-worker-1 \
  --hostname k8s-worker-1 \
  --user k8sadmin \
  --ssh-key ~/.ssh/id_rsa.pub \
  --packages docker.io,kubeadm,kubelet,kubectl \
  --run /path/to/k8s-join.sh \
  --network dhcp

virtos-cloud-init generate k8s-worker-1
virtos-create-vm --name k8s-worker-1 --cpu 4 --ram 8192 --disk 100G --cloud-init
```

**k8s-join.sh example**:

```bash
#!/bin/bash
# Join Kubernetes cluster on first boot
kubeadm join 192.168.1.10:6443 \
  --token abcdef.0123456789abcdef \
  --discovery-token-ca-cert-hash sha256:1234567890abcdef
```

### Use Case 4: Development Environment

```bash
# Create dev VM with multiple users
virtos-cloud-init create dev-box \
  --hostname dev-environment \
  --user developer \
  --ssh-key ~/.ssh/id_rsa.pub \
  --packages build-essential,git,vim,docker.io \
  --timezone America/New_York \
  --run /path/to/dev-setup.sh

virtos-cloud-init generate dev-box
virtos-create-vm --name dev-box --cpu 4 --ram 16384 --disk 100G --cloud-init
```

## Command Reference

### virtos-cloud-init create

Create cloud-init configuration for a VM.

```bash
virtos-cloud-init create <vm-name> [OPTIONS]
```

**Options**:

| Option | Description | Example |
|--------|-------------|---------|
| `--hostname <name>` | Set VM hostname | `--hostname web-server` |
| `--user <username>` | Create user account | `--user admin` |
| `--ssh-key <path>` | Add SSH public key | `--ssh-key ~/.ssh/id_rsa.pub` |
| `--packages <list>` | Install packages (comma-separated) | `--packages nginx,git` |
| `--run <script>` | Run script on first boot | `--run /path/to/setup.sh` |
| `--network <type>` | Network type (static/dhcp) | `--network static` |
| `--ip <address>` | Static IP address with CIDR | `--ip 192.168.1.100/24` |
| `--gateway <ip>` | Network gateway | `--gateway 192.168.1.1` |
| `--dns <servers>` | DNS servers (comma-separated) | `--dns 8.8.8.8,8.8.4.4` |
| `--timezone <tz>` | Set timezone | `--timezone UTC` |

### virtos-cloud-init generate

Generate cloud-init ISO from configuration.

```bash
virtos-cloud-init generate <vm-name>
```

Creates an ISO at `/var/lib/virtos/cloud-init/<vm-name>.iso` containing:

- `meta-data`: VM metadata (hostname, instance-id)
- `user-data`: Cloud-init configuration (users, packages, scripts)

### virtos-cloud-init attach

Attach cloud-init ISO to VM.

```bash
virtos-cloud-init attach <vm-name> [ISO-PATH]
```

If ISO-PATH is omitted, uses the generated ISO at `/var/lib/virtos/cloud-init/<vm-name>.iso`.

### virtos-cloud-init list

List all cloud-init configurations.

```bash
virtos-cloud-init list
```

### virtos-cloud-init show

Show cloud-init configuration for a VM.

```bash
virtos-cloud-init show <vm-name>
```

### virtos-cloud-init delete

Delete cloud-init configuration and ISO.

```bash
virtos-cloud-init delete <vm-name>
```

## Advanced Examples

### Multiple Users with Different SSH Keys

```bash
# Create configuration file manually
cat > /var/lib/virtos/cloud-init/multi-user.yaml <<EOF
#cloud-config
hostname: multi-user-server
users:
  - name: admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-rsa AAAAB3... admin@example.com
  - name: developer
    groups: docker
    ssh_authorized_keys:
      - ssh-rsa AAAAB3... dev@example.com
  - name: readonly
    ssh_authorized_keys:
      - ssh-rsa AAAAB3... readonly@example.com
packages:
  - nginx
  - docker.io
  - git
runcmd:
  - systemctl enable docker
  - usermod -aG docker developer
EOF

# Generate ISO from custom config
virtos-cloud-init generate multi-user --config /var/lib/virtos/cloud-init/multi-user.yaml
virtos-create-vm --name multi-user --cpu 4 --ram 8192 --disk 50G --cloud-init
```

### Disk Partitioning and Formatting

```bash
cat > /var/lib/virtos/cloud-init/storage.yaml <<EOF
#cloud-config
hostname: storage-server
disk_setup:
  /dev/vdb:
    table_type: gpt
    layout: true
    overwrite: false
fs_setup:
  - device: /dev/vdb1
    filesystem: ext4
    label: data
mounts:
  - [/dev/vdb1, /data, ext4, defaults, 0, 2]
runcmd:
  - mkdir -p /data
  - mount -a
  - chown -R admin:admin /data
EOF

virtos-cloud-init generate storage-server --config /var/lib/virtos/cloud-init/storage.yaml
virtos-create-vm --name storage-server --cpu 2 --ram 4096 --disk 20G --disk 100G --cloud-init
```

### Install Docker and Run Container

```bash
cat > /var/lib/virtos/cloud-init/docker-app.yaml <<EOF
#cloud-config
hostname: docker-host
packages:
  - docker.io
runcmd:
  - systemctl enable docker
  - systemctl start docker
  - docker pull nginx:latest
  - docker run -d -p 80:80 --name web nginx:latest
EOF

virtos-cloud-init generate docker-app --config /var/lib/virtos/cloud-init/docker-app.yaml
virtos-create-vm --name docker-app --cpu 2 --ram 4096 --disk 30G --cloud-init
```

## Integration with VirtOS Features

### With Templates

```bash
# Create cloud-init config
virtos-cloud-init create web-template \
  --hostname web-server \
  --user admin \
  --ssh-key ~/.ssh/id_rsa.pub \
  --packages nginx

# Create VM from template
virtos-template create ubuntu-20.04-web --base ubuntu-20.04 --cloud-init web-template
virtos-template deploy ubuntu-20.04-web my-web-server
```

### With Clustering

```bash
# Create cloud-init for cluster node
virtos-cloud-init create cluster-node-1 \
  --hostname node-1 \
  --user clusteradmin \
  --ssh-key ~/.ssh/id_rsa.pub \
  --packages ceph,ntp \
  --run /path/to/cluster-join.sh

# Deploy on specific host
virtos-create-vm --name cluster-node-1 --cpu 4 --ram 8192 --disk 50G \
  --require virtos-host-2 --cloud-init
```

### With Snapshots

```bash
# Create VM with cloud-init
virtos-cloud-init create db-server \
  --hostname postgres-prod \
  --user dbadmin \
  --ssh-key ~/.ssh/id_rsa.pub \
  --packages postgresql-14

virtos-create-vm --name db-server --cpu 8 --ram 16384 --disk 200G --cloud-init

# Wait for cloud-init to complete
sleep 180

# Take snapshot after successful initialization
virtos-snapshot create db-server "After cloud-init setup"
```

## Troubleshooting

### Cloud-init Didn't Run

**Symptoms**: VM boots but cloud-init configuration not applied.

**Solutions**:

1. Check ISO is attached:

   ```bash
   virsh dumpxml <vm-name> | grep cloud-init
   ```

2. Verify ISO contents:

   ```bash
   sudo mount /var/lib/virtos/cloud-init/<vm-name>.iso /mnt
   cat /mnt/user-data
   cat /mnt/meta-data
   sudo umount /mnt
   ```

3. Check cloud-init logs inside VM:

   ```bash
   ssh admin@<vm-name>
   sudo cat /var/log/cloud-init.log
   sudo cat /var/log/cloud-init-output.log
   cloud-init status --long
   ```

### Packages Failed to Install

**Symptoms**: Cloud-init runs but packages not installed.

**Solutions**:

1. Check network connectivity during boot
2. Verify package names are correct for the OS
3. Check `/var/log/cloud-init-output.log` for apt/yum errors
4. Increase VM RAM if installation fails due to memory

### SSH Keys Not Working

**Symptoms**: Cannot SSH into VM with configured key.

**Solutions**:

1. Verify public key format:

   ```bash
   ssh-keygen -l -f ~/.ssh/id_rsa.pub
   ```

2. Check authorized_keys inside VM:

   ```bash
   # Via console
   cat /home/<username>/.ssh/authorized_keys
   ```

3. Verify SSH service is running:

   ```bash
   systemctl status sshd
   ```

### Custom Script Failed

**Symptoms**: Script in `--run` didn't execute successfully.

**Solutions**:

1. Check script has execute permissions
2. Verify script has correct shebang (`#!/bin/bash`)
3. Check script output in `/var/log/cloud-init-output.log`
4. Test script manually after boot

## Cloud-init YAML Reference

Complete `user-data` YAML format:

```yaml
#cloud-config

# System Configuration
hostname: my-server
fqdn: my-server.example.com
timezone: UTC

# User Configuration
users:
  - name: admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo, docker
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3... admin@example.com

# Package Management
packages:
  - nginx
  - postgresql-14
  - docker.io
  - git

package_update: true
package_upgrade: true

# Network Configuration
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses: [192.168.1.100/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

# Disk Configuration
disk_setup:
  /dev/vdb:
    table_type: gpt
    layout: true

fs_setup:
  - device: /dev/vdb1
    filesystem: ext4
    label: data

mounts:
  - [/dev/vdb1, /data, ext4, defaults, 0, 2]

# Commands to Run
runcmd:
  - systemctl enable nginx
  - systemctl start nginx
  - echo "Setup complete" > /var/log/cloud-init-done

# Files to Write
write_files:
  - path: /etc/motd
    content: |
      Welcome to my server
      Configured by VirtOS cloud-init
    permissions: '0644'

# Power State Management
power_state:
  mode: reboot
  condition: true
```

## Best Practices

### 1. Use SSH Keys, Not Passwords

```bash
# GOOD: SSH key authentication
virtos-cloud-init create myvm \
  --user admin \
  --ssh-key ~/.ssh/id_rsa.pub

# BAD: Password authentication (security risk)
# Don't set passwords in cloud-init
```

### 2. Keep Scripts Idempotent

```bash
#!/bin/bash
# Good: Check before installing
if ! command -v nginx &> /dev/null; then
    apt-get install -y nginx
fi

# Good: Use systemctl enable (idempotent)
systemctl enable nginx
systemctl start nginx
```

### 3. Test Cloud-init Configs

```bash
# Validate YAML syntax
cloud-init schema --config-file /var/lib/virtos/cloud-init/myvm.yaml

# Test on a throwaway VM first
virtos-cloud-init create test-vm --user admin --ssh-key ~/.ssh/id_rsa.pub
virtos-create-vm --name test-vm --cpu 1 --ram 2048 --disk 10G --cloud-init
```

### 4. Use Version Control for Configs

```bash
# Store cloud-init configs in git
mkdir -p ~/virtos-cloud-init-configs
cp /var/lib/virtos/cloud-init/*.yaml ~/virtos-cloud-init-configs/
cd ~/virtos-cloud-init-configs
git init
git add .
git commit -m "Add cloud-init configurations"
```

### 5. Log Everything

```yaml
#cloud-config
runcmd:
  - |
    exec > >(tee -a /var/log/my-setup.log)
    exec 2>&1
    echo "Starting custom setup..."
    # Your commands here
    echo "Setup complete"
```

## Resources

- [Cloud-init Documentation](https://cloudinit.readthedocs.io/)
- [Cloud-init Examples](https://cloudinit.readthedocs.io/en/latest/topics/examples.html)
- [VirtOS Architecture](ARCHITECTURE.md)
- [VirtOS Examples](https://github.com/FlossWare/VirtOS-Examples)

## See Also

- [VM Creation Guide](../README.md#creating-vms)
- [Networking Guide](NETWORKING.md)
- [Template Management](../README.md#templates)
- [Cluster Management](../README.md#clustering)

---

**Next Steps**: Try the [Quick Start](#quick-start) example or explore [Common Use Cases](#common-use-cases).
