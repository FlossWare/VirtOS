# IaaS - Automated VM Placement

VirtOS provides Infrastructure as a Service (IaaS) capabilities - request a VM and the cluster automatically places it on the best host.

## Overview

Instead of manually choosing which host to run a VM on, simply request the resources you need and VirtOS's scheduler finds the optimal placement.

```
Traditional Approach:
  You: "Create VM on virtos-2 with 4 vCPU, 8GB RAM"
  System: Creates VM on virtos-2 (even if virtos-3 has more free resources)

IaaS Approach:
  You: "Create VM with 4 vCPU, 8GB RAM"
  System: Analyzes cluster → Places on virtos-3 (best fit)
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│  User Request                                   │
│  "I need: 4 vCPU, 8GB RAM, 50GB disk"          │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  VirtOS Scheduler (virtos-schedule)             │
│  1. Query all cluster nodes                     │
│  2. Check available resources                   │
│  3. Apply placement policy                      │
│  4. Select optimal host                         │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  Cluster Nodes                                  │
│                                                 │
│  virtos-1          virtos-2          virtos-3   │
│  2/4 CPU free     6/8 CPU free      14/16 free  │
│  2/8 GB free      10/16 GB free     24/32 free  │
│                                     ▲           │
│                                     └─ Selected!│
└─────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  VM Created on virtos-3                         │
│  4 vCPU, 8GB RAM, 50GB disk                     │
└─────────────────────────────────────────────────┘
```

## Quick Start

### 1. Enable IaaS Mode

```bash
# In build/build.conf
ENABLE_IAAS="yes"
IAAS_SCHEDULER="balanced"  # balanced, packed, spread
```

### 2. Request a VM (No Host Specified!)

```bash
# Instead of manually choosing host:
# virsh -c qemu+ssh://vmadmin@virtos-2.local/system define vm.xml

# Just request what you need:
virtos-create-vm \
  --name myapp \
  --cpu 4 \
  --ram 8192 \
  --disk 50G \
  --os ubuntu-22.04

# System responds:
# Analyzing cluster...
# Best host: virtos-3 (94% fit score)
# Creating VM on virtos-3...
# VM 'myapp' created successfully
# Connect: virsh -c qemu+ssh://vmadmin@virtos-3.local/system console myapp
```

## Scheduling Policies

### 1. Balanced (Default)

Distributes VMs evenly across cluster for best overall utilization.

```bash
IAAS_SCHEDULER="balanced"
```

**Use when**: General purpose, mixed workloads

**Algorithm**:

- Calculate utilization percentage per node
- Prefer nodes with lowest utilization
- Ensures even distribution

**Example**:

```
Before:
  virtos-1: 80% CPU, 75% RAM (4 VMs)
  virtos-2: 40% CPU, 50% RAM (2 VMs)
  virtos-3: 30% CPU, 25% RAM (1 VM)

New VM request: 2 vCPU, 4GB RAM
Placement: virtos-3 (lowest utilization)
```

### 2. Packed (Bin Packing)

Fills up nodes before using new ones - minimizes number of active hosts.

```bash
IAAS_SCHEDULER="packed"
```

**Use when**: Power saving, cost optimization, consolidation

**Algorithm**:

- Try to fit VM on existing highly-utilized nodes first
- Only use new nodes when necessary
- Enables powering off unused nodes

**Example**:

```
Before:
  virtos-1: 80% CPU, 75% RAM (4 VMs)
  virtos-2: 40% CPU, 50% RAM (2 VMs)
  virtos-3: 10% CPU, 5% RAM (0 VMs)

New VM request: 2 vCPU, 4GB RAM
Placement: virtos-1 (pack more VMs, could power off virtos-3)
```

### 3. Spread (Anti-Affinity)

Spreads VMs across as many hosts as possible for fault tolerance.

```bash
IAAS_SCHEDULER="spread"
```

**Use when**: High availability, fault tolerance, redundancy

**Algorithm**:

- Prefer nodes with fewest VMs
- Maximizes survival of cluster node failures
- Reduces blast radius

**Example**:

```
Before:
  virtos-1: 50% CPU, 50% RAM (5 VMs)
  virtos-2: 50% CPU, 50% RAM (3 VMs)
  virtos-3: 50% CPU, 50% RAM (1 VM)

New VM request: 2 vCPU, 4GB RAM
Placement: virtos-3 (fewest VMs for redundancy)
```

### 4. Custom (User-Defined)

Define custom placement rules.

```bash
IAAS_SCHEDULER="custom"
IAAS_CUSTOM_SCRIPT="/etc/virtos/custom-scheduler.sh"
```

## Resource Tracking

VirtOS tracks resources across the cluster in real-time:

### Tracked Metrics

- **CPU**: Total cores, used cores, free cores
- **RAM**: Total memory, used memory, free memory
- **Storage**: Total disk, used disk, free disk
- **VMs**: Count per node
- **Network**: Bandwidth usage (optional)

### Resource Database

```bash
# Cached in /var/run/virtos/cluster-resources.db
# Updated every 30 seconds (configurable)

# View current state
virtos-cluster resources

# Force refresh
virtos-cluster refresh

# Show specific node
virtos-cluster info virtos-2
```

## VM Creation Commands

### virtos-create-vm

Simple VM creation with automatic placement:

```bash
# Basic usage
virtos-create-vm \
  --name myvm \
  --cpu 2 \
  --ram 4096 \
  --disk 20G

# With OS template
virtos-create-vm \
  --name webserver \
  --cpu 4 \
  --ram 8192 \
  --disk 50G \
  --os ubuntu-22.04 \
  --network bridged

# With placement hints
virtos-create-vm \
  --name dbserver \
  --cpu 8 \
  --ram 16384 \
  --disk 100G \
  --prefer virtos-2 \
  --anti-affinity webserver

# Production-critical VM
virtos-create-vm \
  --name prod-api \
  --cpu 4 \
  --ram 8192 \
  --disk 50G \
  --policy spread \
  --priority high
```

### Options Reference

```bash
virtos-create-vm [options]

Required:
  --name <name>          VM name
  --cpu <count>          Number of vCPUs
  --ram <MB>             RAM in MB
  --disk <size>          Disk size (e.g., 20G, 500M)

Optional:
  --os <template>        OS template (ubuntu-22.04, debian-12, etc.)
  --network <type>       Network type (bridged, nat, isolated)
  --prefer <host>        Prefer this host (soft constraint)
  --avoid <host>         Avoid this host
  --require <host>       Must use this host (override scheduler)
  --anti-affinity <vm>   Don't place on same host as <vm>
  --affinity <vm>        Prefer same host as <vm>
  --policy <policy>      Override scheduler (balanced, packed, spread)
  --priority <level>     Priority (low, normal, high)
  --auto-start           Start VM after creation
  --storage-pool <pool>  Use specific storage pool
```

## Placement Constraints

### Soft Constraints (Preferences)

System tries to honor these but may ignore if impossible:

```bash
# Prefer a specific host
virtos-create-vm --name test --cpu 2 --ram 4096 --disk 20G \
  --prefer virtos-3

# Prefer same host as another VM (affinity)
virtos-create-vm --name web-2 --cpu 2 --ram 4096 --disk 20G \
  --affinity web-1
```

### Hard Constraints (Requirements)

System must honor these or fail:

```bash
# Must run on specific host
virtos-create-vm --name special --cpu 2 --ram 4096 --disk 20G \
  --require virtos-2

# Must NOT run on same host (anti-affinity)
virtos-create-vm --name db-replica --cpu 4 --ram 8192 --disk 100G \
  --anti-affinity db-primary --hard
```

## Scheduling Algorithm

### Decision Process

```
1. Query Cluster
   ├─ Get all active nodes
   ├─ Check node health
   └─ Collect resource metrics

2. Filter Nodes
   ├─ Remove unhealthy nodes
   ├─ Remove nodes with insufficient resources
   ├─ Apply hard constraints (--require, --avoid)
   └─ Check anti-affinity rules

3. Score Nodes
   ├─ Calculate resource fit (CPU, RAM, disk)
   ├─ Apply policy weights (balanced, packed, spread)
   ├─ Apply soft constraints (--prefer, --affinity)
   ├─ Consider priority level
   └─ Calculate final score (0-100)

4. Select Best
   ├─ Sort by score (highest first)
   ├─ Pick top node
   └─ Create VM

5. Update Cluster
   ├─ Mark resources as used
   ├─ Update cluster database
   └─ Notify other nodes
```

### Scoring Formula

**Balanced Policy**:

```
score = 100 - (cpu_utilization + ram_utilization) / 2
      + preference_bonus
      - vm_count_penalty
```

**Packed Policy**:

```
score = (cpu_utilization + ram_utilization) / 2
      + preference_bonus
      + vm_count_bonus
```

**Spread Policy**:

```
score = 100 - vm_count * 10
      + preference_bonus
      + resource_headroom_bonus
```

## Configuration

### Global Settings (build.conf)

```bash
#==============================================================================
# IAAS / AUTOMATED PLACEMENT
#==============================================================================

# Enable IaaS features
ENABLE_IAAS="yes"

# Default scheduler policy
IAAS_SCHEDULER="balanced"    # balanced, packed, spread, custom

# Resource update interval (seconds)
IAAS_REFRESH_INTERVAL="30"

# Resource thresholds
IAAS_CPU_OVERCOMMIT="1.5"    # Allow 150% CPU overcommit
IAAS_RAM_OVERCOMMIT="1.0"    # No RAM overcommit
IAAS_MIN_FREE_RAM_MB="1024"  # Reserve 1GB per host

# Placement preferences
IAAS_PREFER_LOCAL="no"       # Prefer node where command is run
IAAS_AVOID_SINGLE_NODE="yes" # Warn if all VMs on one node

# HA settings
IAAS_HA_ENABLED="no"         # High availability (auto-restart)
IAAS_MAX_VMS_PER_NODE="0"    # 0 = unlimited
```

### Per-Node Configuration (/etc/virtos/iaas.conf)

```bash
# Node-specific IaaS settings

# Resource limits
MAX_VMS=20                   # Max VMs on this node
RESERVED_CPU_PERCENT=10      # Reserve 10% CPU for host
RESERVED_RAM_MB=2048         # Reserve 2GB RAM for host

# Node attributes (for custom scheduling)
NODE_ATTRIBUTES="ssd,gpu"    # Comma-separated tags
NODE_ZONE="rack1"            # Physical location
NODE_TIER="production"       # Environment tier

# Accept workloads
ACCEPT_PLACEMENT="yes"       # Allow scheduler to place VMs here
ACCEPT_PRIORITY="all"        # all, high, normal (reject low priority)
```

## Advanced Features

### 1. VM Templates

Pre-defined VM configurations:

```bash
# Create template
virtos-template create web-small \
  --cpu 2 \
  --ram 4096 \
  --disk 20G \
  --os ubuntu-22.04 \
  --network bridged

# Use template
virtos-create-vm --name web-1 --template web-small

# List templates
virtos-template list
```

### 2. Resource Quotas

Limit resources per user/project:

```bash
# Set quota
virtos-quota set \
  --user developer \
  --max-vms 10 \
  --max-cpu 32 \
  --max-ram 65536

# Check quota
virtos-quota show developer

# User tries to exceed quota
virtos-create-vm --name test --cpu 40 --ram 16384
# Error: Quota exceeded. User 'developer' limit: 32 vCPU
```

### 3. Auto-Scaling (Future)

Automatically adjust cluster size:

```bash
# Enable auto-scaling
IAAS_AUTOSCALE="yes"
IAAS_SCALE_UP_THRESHOLD="80"   # Add node if >80% utilized
IAAS_SCALE_DOWN_THRESHOLD="30" # Remove if <30% utilized

# Manual scaling
virtos-cluster scale up --count 2    # Add 2 nodes
virtos-cluster scale down --node virtos-4  # Remove node
```

### 4. VM Migration

Move VMs between hosts:

```bash
# Manual migration
virtos-migrate myvm --from virtos-1 --to virtos-2

# Automatic rebalancing
virtos-rebalance \
  --policy balanced \
  --dry-run  # Show what would happen

# Live migration (requires shared storage)
virtos-migrate myvm --to virtos-3 --live
```

### 5. Reservation System

Reserve resources for future use:

```bash
# Reserve resources
virtos-reserve \
  --name deployment-2024-06 \
  --cpu 16 \
  --ram 32768 \
  --start "2024-06-01 00:00" \
  --end "2024-06-30 23:59"

# Scheduler accounts for reservations
# Won't overcommit reserved resources
```

## Integration Examples

### With Terraform

```hcl
# virtos.tf
resource "virtos_vm" "web_servers" {
  count = 3

  name = "web-${count.index}"
  cpu  = 2
  ram  = 4096
  disk = 20

  os_template = "ubuntu-22.04"

  # Let VirtOS scheduler decide placement
  placement_policy = "spread"

  # Anti-affinity with other web servers
  anti_affinity = [
    for i in range(count.index) : "web-${i}"
  ]
}
```

### With Ansible

```yaml
# playbook.yml
- name: Deploy application VMs
  hosts: localhost
  tasks:
    - name: Create web tier VMs
      virtos_vm:
        name: "{{ item }}"
        cpu: 4
        ram: 8192
        disk: 50
        os: ubuntu-22.04
        policy: spread
        anti_affinity: true
      loop:
        - web-1
        - web-2
        - web-3

    - name: Create database VM
      virtos_vm:
        name: db-1
        cpu: 8
        ram: 16384
        disk: 200
        os: ubuntu-22.04
        policy: balanced
        priority: high
```

### With REST API (Future)

```bash
# API endpoint
curl -X POST http://virtos-1.local:8080/api/v1/vms \
  -H "Content-Type: application/json" \
  -d '{
    "name": "api-server",
    "cpu": 4,
    "ram": 8192,
    "disk": 50,
    "os": "ubuntu-22.04",
    "policy": "balanced"
  }'

# Response
{
  "vm": "api-server",
  "host": "virtos-3",
  "status": "creating",
  "score": 94,
  "reason": "Best fit: 14/16 CPU free, 24/32 GB RAM free"
}
```

## Monitoring & Observability

### Cluster Dashboard

```bash
# Real-time cluster view
virtos-dashboard

# Output:
╔═══════════════════════════════════════════════════════════╗
║ VirtOS IaaS Cluster Dashboard                            ║
╠═══════════════════════════════════════════════════════════╣
║ Cluster: homelab          Policy: balanced               ║
║ Nodes: 3 (3 up, 0 down)   VMs: 12 total                 ║
║ CPU: 28/84 cores (33%)    RAM: 48/96 GB (50%)            ║
╠═══════════════════════════════════════════════════════════╣
║ Node       Status  VMs  CPU      RAM       Disk          ║
╠═══════════════════════════════════════════════════════════╣
║ virtos-1   UP      4    8/28     12/32GB   50/500GB      ║
║ virtos-2   UP      5    12/28    20/32GB   80/500GB      ║
║ virtos-3   UP      3    8/28     16/32GB   30/500GB      ║
╠═══════════════════════════════════════════════════════════╣
║ Recent Placements:                                        ║
║  • web-4 → virtos-3 (score: 92, reason: balanced)        ║
║  • db-2  → virtos-1 (score: 88, reason: anti-affinity)   ║
║  • test  → virtos-2 (score: 85, reason: preferred)       ║
╚═══════════════════════════════════════════════════════════╝
```

### Placement History

```bash
# View placement decisions
virtos-placement-log --last 10

# Output:
Timestamp           VM       Host      Score  Policy    Reason
2024-05-22 10:15    web-4    virtos-3  92     balanced  Most free resources
2024-05-22 10:10    db-2     virtos-1  88     balanced  Anti-affinity with db-1
2024-05-22 09:55    test     virtos-2  85     balanced  User preference
```

### Metrics Export

```bash
# Prometheus metrics
curl http://virtos-1.local:9090/metrics

# Output:
virtos_cluster_nodes_total 3
virtos_cluster_nodes_up 3
virtos_cluster_vms_total 12
virtos_cluster_cpu_usage_percent 33
virtos_cluster_ram_usage_percent 50
virtos_node_vms_count{node="virtos-1"} 4
virtos_node_cpu_usage{node="virtos-1"} 8
...
```

## Comparison: IaaS vs Manual

| Aspect | Manual Placement | IaaS Automated |
|--------|-----------------|----------------|
| **User effort** | High - pick host manually | Low - just specify resources |
| **Optimization** | Depends on user knowledge | Algorithmic, consistent |
| **Cluster balance** | Manual effort to balance | Automatic balancing |
| **Resource waste** | Can waste resources | Optimizes utilization |
| **Scalability** | Hard with many VMs | Easy, scales automatically |
| **Fault tolerance** | Manual anti-affinity | Built-in spread policy |
| **Learning curve** | Need to know cluster state | Simple resource request |

## Use Cases

### 1. Development Environment

```bash
# Developers just request VMs, don't care about placement
virtos-create-vm --name dev-alice --cpu 2 --ram 4096 --disk 20G
virtos-create-vm --name dev-bob --cpu 2 --ram 4096 --disk 20G
virtos-create-vm --name dev-charlie --cpu 2 --ram 4096 --disk 20G

# System distributes across cluster automatically
```

### 2. HA Database Cluster

```bash
# Primary and replicas on different hosts
virtos-create-vm --name db-primary --cpu 8 --ram 16384 --disk 200G \
  --policy spread

virtos-create-vm --name db-replica-1 --cpu 8 --ram 16384 --disk 200G \
  --anti-affinity db-primary --policy spread

virtos-create-vm --name db-replica-2 --cpu 8 --ram 16384 --disk 200G \
  --anti-affinity db-primary,db-replica-1 --policy spread

# Guaranteed on 3 different hosts
```

### 3. Cost Optimization

```bash
# Pack VMs to minimize active hosts
export IAAS_SCHEDULER="packed"

# Create many small VMs
for i in {1..20}; do
  virtos-create-vm --name test-$i --cpu 1 --ram 2048 --disk 10G
done

# System packs onto fewest nodes, others can power down
```

### 4. Web Farm Auto-Scale

```bash
# Scale up during traffic spike
virtos-create-vm --name web-{5..8} --cpu 4 --ram 8192 --disk 30G \
  --policy spread --template web-server

# Scale down during low traffic
virtos-delete-vm web-{5..8}

# Resources automatically reclaimed
```

## Troubleshooting

### No Suitable Host Found

```bash
$ virtos-create-vm --name huge --cpu 32 --ram 65536 --disk 500G

Error: No suitable host found
Reasons:
  - virtos-1: Insufficient CPU (need 32, have 4 total)
  - virtos-2: Insufficient RAM (need 64GB, have 32GB total)
  - virtos-3: Insufficient CPU (need 32, have 16 total)

Suggestions:
  1. Reduce resource request
  2. Add more cluster nodes
  3. Enable CPU overcommit (caution!)
```

### Scheduler Not Working

```bash
# Check scheduler status
systemctl status virtos-scheduler

# Check logs
journalctl -u virtos-scheduler -f

# Manually trigger scheduling
virtos-schedule --vm myvm --debug
```

### Unbalanced Cluster

```bash
# Check balance
virtos-cluster balance-check

# Output:
Warning: Cluster is unbalanced
  virtos-1: 90% CPU (overloaded)
  virtos-2: 20% CPU (underutilized)
  virtos-3: 15% CPU (underutilized)

Recommendation: Run rebalancing
  virtos-rebalance --policy balanced --dry-run

# Rebalance
virtos-rebalance --policy balanced
```

## Future Enhancements

### Phase 1 (Current)

- ✅ Basic resource tracking
- ✅ Simple scheduling policies
- ✅ Manual VM creation with placement

### Phase 2 (Near-term)

- [ ] Auto-rebalancing
- [ ] VM templates
- [ ] Resource quotas
- [ ] Placement history/logging
- [ ] REST API

### Phase 3 (Future)

- [ ] Live migration
- [ ] Auto-scaling
- [ ] Reservation system
- [ ] Advanced policies (cost, power, affinity zones)
- [ ] Integration with K3s (unified scheduling)

## Comparison to Other Solutions

| Feature | VirtOS IaaS | OpenStack | Proxmox | oVirt |
|---------|-------------|-----------|---------|-------|
| **Base Size** | ~200MB | ~10GB | ~1GB | ~2GB |
| **Complexity** | Low | High | Medium | High |
| **Learning Curve** | Easy | Steep | Moderate | Steep |
| **Home Lab Fit** | Perfect | Overkill | Good | Overkill |
| **Auto Placement** | ✅ | ✅ | ✅ | ✅ |
| **VM + Containers** | ✅ | ✅ | ✅ | ❌ |
| **Minimal** | ✅ | ❌ | ❌ | ❌ |

VirtOS IaaS = Lightweight OpenStack alternative for home labs!

## Quick Reference

| Task | Command |
|------|---------|
| Create VM (auto-place) | `virtos-create-vm --name test --cpu 2 --ram 4096 --disk 20G` |
| View cluster resources | `virtos-cluster resources` |
| Check placement decision | `virtos-schedule --vm test --dry-run --verbose` |
| Set scheduler policy | `IAAS_SCHEDULER="balanced"` in build.conf |
| View placement history | `virtos-placement-log --last 10` |
| Rebalance cluster | `virtos-rebalance --policy balanced` |
| Dashboard | `virtos-dashboard` |

## See Also

- [CLUSTERING.md](CLUSTERING.md) - Multi-host setup (required for IaaS)
- [KUBERNETES.md](KUBERNETES.md) - K3s also does automated scheduling
- [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - Remote management
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design
