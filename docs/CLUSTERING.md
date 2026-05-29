# VirtOS Clustering

VirtOS supports automatic discovery and coordination between multiple instances.

## Overview

Run multiple VirtOS hosts that automatically:

- **Discover** each other on the network
- **Share** resource information (CPU, RAM, VMs)
- **Coordinate** VM placement and migration
- **Provide** unified management view

```
Your Network:
┌─────────────────────────────────────────────────┐
│                                                 │
│  virtos-1.local     virtos-2.local     virtos-3.local
│  192.168.1.101      192.168.1.102      192.168.1.103
│  ├─ 4 VMs          ├─ 2 VMs           ├─ 1 VM
│  ├─ 8GB RAM        ├─ 16GB RAM        ├─ 32GB RAM
│  └─ 4 vCPU         └─ 8 vCPU          └─ 16 vCPU
│                                                 │
│          All discoverable via mDNS/Avahi       │
└─────────────────────────────────────────────────┘
```

## Architecture

### Discovery Layer

- **Avahi/mDNS**: Automatic hostname resolution (virtos-1.local)
- **Broadcast**: Announce presence on network
- **Health Checks**: Periodic status updates

### Information Sharing

- CPU/RAM availability
- Running VMs count
- Storage capacity
- Network configuration

### Coordination (Optional)

- VM placement recommendations
- Load balancing
- Migration support
- Shared storage integration

## Quick Start

### 1. Enable Clustering

Edit `build/build.conf`:

```bash
# Enable clustering features
ENABLE_CLUSTERING="yes"
INCLUDE_AVAHI="yes"
CLUSTER_NAME="homelab"
```

### 2. Build with Clustering

```bash
cd build/scripts
./build-all.sh
```

### 3. Boot Multiple Hosts

Each VirtOS instance needs:

- Unique hostname (virtos-1, virtos-2, virtos-3)
- Same cluster name
- Network connectivity

### 4. Verify Discovery

On any VirtOS host:

```bash
# List all VirtOS instances on network
virtos-cluster list

# Example output:
# Hostname      IP              Status  VMs  CPU   RAM
# virtos-1      192.168.1.101   up      4    4c    8GB
# virtos-2      192.168.1.102   up      2    8c    16GB
# virtos-3      192.168.1.103   up      1    16c   32GB
```

## Configuration

### Cluster Settings (build.conf)

```bash
#==============================================================================
# CLUSTERING (yes/no)
#==============================================================================

# Enable cluster discovery and coordination
ENABLE_CLUSTERING="yes"

# Service discovery
INCLUDE_AVAHI="yes"          # mDNS/Avahi for .local domains
INCLUDE_MDNS="yes"           # Multicast DNS

# Cluster name (all hosts in same cluster must match)
CLUSTER_NAME="homelab"

# Cluster features
CLUSTER_SHARED_STORAGE="no"  # NFS/Ceph shared storage
CLUSTER_VM_MIGRATION="no"    # Live migration support (future)
CLUSTER_HA="no"              # High availability (future)

# Discovery method
CLUSTER_DISCOVERY="avahi"    # avahi, multicast, static
CLUSTER_BROADCAST_PORT="5900"
```

### Per-Host Configuration

Edit on each VirtOS instance at `/etc/virtos/cluster.conf`:

```bash
# Unique hostname for this node
NODE_HOSTNAME="virtos-1"

# Cluster membership
CLUSTER_NAME="homelab"

# Node role (optional)
NODE_ROLE="compute"          # compute, storage, mixed

# Resource limits (optional, for placement decisions)
MAX_VMS="10"
RESERVED_RAM_MB="2048"       # Reserve for host OS
RESERVED_CPU_PERCENT="10"
```

## Discovery Methods

### Method 1: Avahi/mDNS (Recommended)

**Pros**: Zero-config, automatic .local domains  
**Cons**: Requires multicast support on network

Hosts automatically available as:

- `virtos-1.local`
- `virtos-2.local`
- `virtos-3.local`

**Connect from anywhere**:

```bash
ssh vmadmin@virtos-2.local
virt-manager -c qemu+ssh://vmadmin@virtos-1.local/system
ping virtos-3.local
```

### Method 2: Multicast Broadcast

**Pros**: Works on simple networks  
**Cons**: May not cross VLANs/subnets

Periodic broadcasts announce:

```json
{
  "hostname": "virtos-1",
  "ip": "192.168.1.101",
  "cluster": "homelab",
  "vms": 4,
  "cpu_cores": 4,
  "ram_mb": 8192,
  "timestamp": 1234567890
}
```

### Method 3: Static Configuration

**Pros**: Reliable, works anywhere  
**Cons**: Manual configuration

Edit `/etc/virtos/cluster-members.conf`:

```bash
virtos-1 192.168.1.101
virtos-2 192.168.1.102
virtos-3 192.168.1.103
```

## Cluster Management Commands

### virtos-cluster

```bash
# List all cluster members
virtos-cluster list

# Show detailed info about a node
virtos-cluster info virtos-2

# Check cluster health
virtos-cluster health

# Show resource summary
virtos-cluster resources

# Add node manually (static discovery)
virtos-cluster add virtos-4 192.168.1.104

# Remove node
virtos-cluster remove virtos-4
```

### Example Output

```bash
$ virtos-cluster list

VirtOS Cluster: homelab
================================================

Hostname      IP              Status  Uptime   VMs  CPU    RAM
virtos-1      192.168.1.101   up      2d 5h    4    4/4    6/8GB
virtos-2      192.168.1.102   up      1d 3h    2    3/8    10/16GB
virtos-3      192.168.1.103   up      5h       1    2/16   8/32GB

Total: 3 nodes, 7 VMs, 9/28 CPUs used, 24/56 GB RAM used
```

```bash
$ virtos-cluster resources

Cluster Resources (homelab)
================================================

Total Capacity:
  Nodes:      3
  CPU Cores:  28 (9 used, 19 free)
  RAM:        56 GB (24 used, 32 free)
  VMs:        7 running

Per-Node Breakdown:
  virtos-1:   4/4 CPU,   6/8 GB    (75% loaded)
  virtos-2:   3/8 CPU,   10/16 GB  (38% loaded)  ← Best for new VMs
  virtos-3:   2/16 CPU,  8/32 GB   (12% loaded)  ← Best for new VMs

Recommendation: virtos-3 has most free resources
```

## Unified Management

### virt-manager - All Hosts

Connect to all VirtOS instances from one virt-manager:

```bash
# Connect to each host
virt-manager \
  -c qemu+ssh://vmadmin@virtos-1.local/system \
  -c qemu+ssh://vmadmin@virtos-2.local/system \
  -c qemu+ssh://vmadmin@virtos-3.local/system
```

Or add connections in GUI - all hosts appear in left panel!

### virsh - Query All Hosts

```bash
# List VMs on all cluster nodes
for host in virtos-1 virtos-2 virtos-3; do
  echo "=== $host ==="
  virsh -c qemu+ssh://vmadmin@$host.local/system list --all
done

# Or use cluster helper:
virtos-cluster vms --all
```

## VM Placement Recommendations

VirtOS can suggest optimal placement:

```bash
# Where should I place a new VM?
virtos-cluster recommend --cpu 2 --ram 4096

# Output:
# Recommended hosts for VM (2 vCPU, 4GB RAM):
# 1. virtos-3 (score: 95) - 14/16 CPU free, 24/32 GB free
# 2. virtos-2 (score: 72) - 5/8 CPU free, 6/16 GB free
# 3. virtos-1 (score: 30) - 0/4 CPU free, 2/8 GB free
#
# Suggested: Create VM on virtos-3
```

Then create VM on recommended host:

```bash
virsh -c qemu+ssh://vmadmin@virtos-3.local/system \
  create myvm.xml
```

## Shared Storage (Optional)

For VM migration and shared access:

### NFS Setup

**On storage server (can be one VirtOS node)**:

```bash
# Install NFS
tce-load -i nfs-utils

# Export directory
mkdir -p /mnt/sda1/vm-storage
cat >> /etc/exports << EOF
/mnt/sda1/vm-storage 192.168.1.0/24(rw,sync,no_root_squash)
EOF

# Start NFS
/usr/local/etc/init.d/nfs start
```

**On all VirtOS nodes**:

```bash
# Mount shared storage
mkdir -p /mnt/cluster-storage
mount -t nfs virtos-1.local:/mnt/sda1/vm-storage /mnt/cluster-storage

# Add to fstab for persistence
echo "virtos-1.local:/mnt/sda1/vm-storage /mnt/cluster-storage nfs defaults 0 0" >> /etc/fstab

# Configure libvirt storage pool
virsh pool-define-as cluster-pool dir --target /mnt/cluster-storage
virsh pool-start cluster-pool
virsh pool-autostart cluster-pool
```

Now all nodes can access VMs stored on shared storage!

## Advanced Features (Future)

### Live Migration

Move running VMs between hosts (requires shared storage):

```bash
# Migrate VM from virtos-1 to virtos-2
virsh migrate --live myvm \
  qemu+ssh://vmadmin@virtos-2.local/system

# Using cluster helper:
virtos-cluster migrate myvm --from virtos-1 --to virtos-2
```

### High Availability

Automatic failover if a host goes down:

```bash
# Enable HA for critical VMs
virtos-cluster ha enable myvm --failover-to virtos-2

# If virtos-1 fails, myvm automatically starts on virtos-2
```

### Load Balancing

Automatically rebalance VMs across cluster:

```bash
# Analyze current distribution
virtos-cluster balance analyze

# Perform rebalancing
virtos-cluster balance execute
```

## Network Considerations

### Same Subnet (Simple)

All VirtOS hosts on same network - discovery works automatically.

```
192.168.1.0/24
├─ virtos-1: 192.168.1.101
├─ virtos-2: 192.168.1.102
└─ virtos-3: 192.168.1.103
```

### VLANs (Requires Routing)

If hosts are on different VLANs, ensure:

- Multicast routing enabled (for mDNS)
- Or use static discovery method

### Multiple Sites (Advanced)

For geographically distributed hosts:

- Use static discovery
- VPN between sites
- Configure firewall rules

## Security

### Trusted Network

Clustering assumes trusted network:

- All hosts should be on secure LAN
- Use firewall to isolate from internet
- SSH keys for authentication

### Cluster Authentication

Optional: shared secret for cluster membership:

```bash
# Generate cluster secret
openssl rand -hex 32 > /etc/virtos/cluster.secret
chmod 600 /etc/virtos/cluster.secret

# Copy same secret to all nodes
# Only nodes with matching secret join cluster
```

### Firewall Rules

Allow cluster communication:

```bash
# Avahi/mDNS
iptables -A INPUT -p udp --dport 5353 -j ACCEPT

# Cluster broadcast (custom port)
iptables -A INPUT -p udp --dport 5900 -j ACCEPT

# libvirt (already allowed for remote access)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```

## Troubleshooting

### Nodes Not Discovering Each Other

**Check Avahi is running**:

```bash
ps aux | grep avahi
/usr/local/etc/init.d/avahi status
```

**Test mDNS resolution**:

```bash
ping virtos-1.local
avahi-browse -a
```

**Check multicast**:

```bash
# Ensure multicast not blocked
ip maddr show
```

**Verify cluster name matches**:

```bash
# On each host
cat /etc/virtos/cluster.conf | grep CLUSTER_NAME
# Must be identical
```

### Node Shows as Down

**Check network connectivity**:

```bash
ping virtos-2
ssh vmadmin@virtos-2 echo "test"
```

**Check node is actually up**:

```bash
ssh vmadmin@virtos-2 uptime
```

**Check cluster daemon**:

```bash
ssh vmadmin@virtos-2 ps aux | grep virtos-cluster
```

### VM Placement Incorrect

**Update cluster cache**:

```bash
virtos-cluster refresh
```

**Check resource reporting**:

```bash
virtos-cluster info virtos-1 --verbose
```

## Use Cases

### Home Lab - 3 Nodes

- Small cluster for development
- Each node different specs
- Automatic discovery with Avahi
- Manual VM placement based on resource needs

### Production - 5+ Nodes

- Shared storage (NFS or Ceph)
- Load balancing
- HA for critical VMs
- Centralized monitoring

### Edge Computing

- Distributed VirtOS nodes
- Static discovery
- Local storage
- Minimal coordination

## Migration Path

### Phase 1: Discovery (Current)

- Avahi/mDNS for hostname resolution
- Basic status sharing
- Manual VM placement
- **Available now**

### Phase 2: Coordination

- Resource tracking
- Placement recommendations
- Health monitoring
- **Coming soon**

### Phase 3: Automation

- Live migration
- Load balancing
- High availability
- **Future**

## Quick Reference

| Task | Command |
|------|---------|
| List cluster members | `virtos-cluster list` |
| Show resources | `virtos-cluster resources` |
| Node details | `virtos-cluster info virtos-1` |
| Health check | `virtos-cluster health` |
| Placement recommendation | `virtos-cluster recommend --cpu 2 --ram 4096` |
| Connect virt-manager | `virt-manager -c qemu+ssh://vmadmin@virtos-1.local/system` |
| List VMs on all hosts | `virtos-cluster vms --all` |
| Resolve hostname | `ping virtos-1.local` |

## See Also

- [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - Remote management setup
- [CONFIGURATION.md](CONFIGURATION.md) - Build configuration
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design

## Example Setup

```bash
# Build 3 VirtOS ISOs with clustering
ENABLE_CLUSTERING="yes" CLUSTER_NAME="homelab" ./build-all.sh

# Boot each instance:
# - virtos-1 on machine 1
# - virtos-2 on machine 2  
# - virtos-3 on machine 3

# On virtos-1:
virtos-cluster list
# Shows all 3 nodes

# On your desktop:
virt-manager -c qemu+ssh://vmadmin@virtos-1.local/system

# All 3 VirtOS instances visible and manageable!
```
