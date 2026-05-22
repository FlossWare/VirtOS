# Quick Reference Guide

## Remote Access

```bash
# virt-manager (GUI)
virt-manager -c qemu+ssh://vmadmin@virtos/system

# virsh (CLI)
virsh -c qemu+ssh://vmadmin@virtos/system list --all

# SSH
ssh vmadmin@virtos
```

See [REMOTE-ACCESS.md](REMOTE-ACCESS.md) for detailed setup.

## Cluster Management

```bash
# List all VirtOS instances on network
virtos-cluster list

# Show resources across cluster
virtos-cluster resources

# Node details
virtos-cluster info virtos-2

# Refresh discovery cache
virtos-cluster refresh
```

See [CLUSTERING.md](CLUSTERING.md) for multi-host setup.

## IaaS - Automated VM Placement

```bash
# Create VM with automatic placement
virtos-create-vm --name web-1 --cpu 2 --ram 4096 --disk 20G

# With OS template
virtos-create-vm --name app --cpu 4 --ram 8192 --disk 50G \
  --os ubuntu-22.04

# High availability (spread policy)
virtos-create-vm --name db --cpu 8 --ram 16384 --disk 200G \
  --policy spread --priority high

# Anti-affinity (different host than another VM)
virtos-create-vm --name db-replica --cpu 8 --ram 16384 --disk 200G \
  --anti-affinity db-primary

# Dry run (show where it would be placed)
virtos-create-vm --name test --cpu 2 --ram 4096 --disk 20G --dry-run

# Force specific host (skip scheduler)
virtos-create-vm --name special --cpu 2 --ram 4096 --disk 20G \
  --require virtos-2
```

See [IAAS.md](IAAS.md) for automated placement and scheduling.

## Backup & Restore

```bash
# Backup a VM
virtos-backup backup web-server-1

# Schedule daily backups at 2 AM
virtos-backup schedule web-server-1 --daily 02:00

# Schedule with retention policy (keep last 7)
virtos-backup schedule web-server-1 --daily 02:00 --keep 7

# Backup to remote location
virtos-backup backup web-server-1 --remote scp://backup@server:/backups

# List backups
virtos-backup list

# Restore from backup
virtos-backup restore web-server-1 2026-05-22

# Cleanup old backups
virtos-backup cleanup
```

## VM Templates

```bash
# Create template from existing VM (must be shut down)
virtos-template create ubuntu-vm ubuntu-22.04-template

# Clone from template
virtos-template clone ubuntu-22.04-template web-server-1

# Import cloud image as template
virtos-template import \
  https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img \
  ubuntu-2204-cloud

# List available templates
virtos-template list

# Delete template
virtos-template delete old-template
```

## VM Snapshots

```bash
# Create snapshot
virtos-snapshot create web-server-1 "Before update"

# Create disk-only snapshot (faster, no RAM state)
virtos-snapshot create web-server-1 "Pre-migration" --disk-only

# Create snapshot with memory state
virtos-snapshot create db-server "Debug state" --memory

# List snapshots
virtos-snapshot list web-server-1

# Revert to snapshot
virtos-snapshot revert web-server-1 snapshot-20260522-120000

# Delete snapshot
virtos-snapshot delete web-server-1 snapshot-20260520-080000

# Schedule daily snapshots at 2 AM, keep last 7
virtos-snapshot schedule web-server-1 --daily 02:00 --keep 7

# Cleanup old snapshots manually
virtos-snapshot cleanup web-server-1
```

## Monitoring & Alerts

```bash
# Start monitoring daemon
virtos-monitor start

# Stop monitoring daemon
virtos-monitor stop

# Check monitoring status
virtos-monitor status

# Run health checks once
virtos-monitor check

# View active alerts
virtos-monitor alerts

# Configure CPU threshold
virtos-monitor config cpu 90

# Configure memory threshold
virtos-monitor config memory 80

# Configure email alerts
virtos-monitor config email admin@example.com

# Configure webhook alerts
virtos-monitor config webhook https://hooks.example.com/alert
```

## High Availability (HA)

```bash
# Enable HA for a VM
virtos-ha enable web-server-1 --priority high

# Disable HA for a VM
virtos-ha disable web-server-1

# List HA-enabled VMs
virtos-ha list

# Check HA status
virtos-ha status

# Manual failover
virtos-ha failover db-server virtos-2

# Start HA daemon
virtos-ha start-daemon

# Stop HA daemon
virtos-ha stop-daemon
```

## VM Migration

```bash
# Live migration with shared storage
virtos-migrate --live --shared-storage web-1 virtos-2

# Block migration (no shared storage required)
virtos-migrate --block app-1 virtos-3

# Offline migration
virtos-migrate --offline db-server virtos-2

# Migration with bandwidth limit
virtos-migrate --live --bandwidth 100 web-1 virtos-2

# Compressed migration
virtos-migrate --block --compressed large-vm virtos-3

# Migration with auto-converge (for busy VMs)
virtos-migrate --live --auto-converge vm-1 virtos-2
```

## Resource Quotas

```bash
# Set VM CPU limit
virtos-quota set web-1 cpu 4

# Set VM memory limit
virtos-quota set db-server memory 8192

# Set VM disk limit
virtos-quota set app-1 disk 100

# Get VM quotas
virtos-quota get web-1

# Check VM quota compliance
virtos-quota check web-1

# List all quotas
virtos-quota list

# Show cluster resource usage
virtos-quota usage

# Set cluster-wide quotas
virtos-quota cluster-quota vms 100
virtos-quota cluster-quota cpu 256
virtos-quota cluster-quota memory 524288

# Enable quota enforcement
virtos-quota enforce on

# Disable quota enforcement
virtos-quota enforce off
```

## Authentication & RBAC

```bash
# Add user
virtos-auth user-add alice --role operator

# Delete user
virtos-auth user-delete alice

# List users
virtos-auth user-list

# Assign role to user
virtos-auth role-assign alice operator

# Create custom role
virtos-auth role-create developer

# Add permission to role
virtos-auth permission-add developer vm:create
virtos-auth permission-add developer vm:start
virtos-auth permission-add developer vm:stop

# List all roles
virtos-auth role-list

# Show role permissions
virtos-auth role-show operator

# Check user permission
virtos-auth check-permission alice vm:create

# Delete role
virtos-auth role-delete developer
```

## Cloud-Init

```bash
# Create cloud-init config with SSH key
virtos-cloud-init create ubuntu-vm \
  --hostname web-server \
  --user admin \
  --ssh-key ~/.ssh/id_rsa.pub

# Create with static IP
virtos-cloud-init create db-vm \
  --hostname database \
  --network static \
  --ip 192.168.1.100/24 \
  --gateway 192.168.1.1 \
  --dns 8.8.8.8

# Install packages on first boot
virtos-cloud-init create app-vm \
  --hostname app-server \
  --packages nginx,git,python3 \
  --run /path/to/setup.sh

# Generate cloud-init ISO
virtos-cloud-init generate web-vm

# Attach ISO to VM
virtos-cloud-init attach web-vm /var/lib/virtos/cloud-init/web-vm.iso

# List available templates
virtos-cloud-init template-list

# Show template example
virtos-cloud-init template-show ubuntu
```

## REST API

```bash
# Start API server
virtos-api start

# Start on custom port
virtos-api start --port 9090

# Stop API server
virtos-api stop

# Check API status
virtos-api status

# Test API connectivity
virtos-api test

# API endpoints (using curl)
curl http://localhost:8080/api/v1/health
curl http://localhost:8080/api/v1/vms
curl http://localhost:8080/api/v1/vms/web-1
curl -X POST http://localhost:8080/api/v1/vms/web-1/start
curl -X POST http://localhost:8080/api/v1/vms/web-1/stop
curl http://localhost:8080/api/v1/cluster
```

## System Updates

```bash
# Check for updates
virtos-update check

# List available updates
virtos-update list

# Install specific update
virtos-update install virtos-monitor-1.1

# Install all available updates
virtos-update install-all

# Rollback an update
virtos-update rollback virtos-monitor-1.1

# View update history
virtos-update history

# Enable automatic updates (daily at 3 AM)
virtos-update auto-enable

# Disable automatic updates
virtos-update auto-disable
```

## Disaster Recovery

```bash
# Create DR plan
virtos-dr plan-create production \
  --priority 1 \
  --rpo 15 \
  --rto 30 \
  --auto-failover yes

# List DR plans
virtos-dr plan-list

# Show DR plan details
virtos-dr plan-show production

# Test DR plan (dry-run)
virtos-dr plan-test production

# Execute DR plan
virtos-dr plan-execute production

# Start VM replication to DR site
virtos-dr replicate-start web-server-1 dr-site.example.com

# Stop VM replication
virtos-dr replicate-stop web-server-1

# Check replication status
virtos-dr replicate-status

# Failover to DR site
virtos-dr failover dr-site

# Failback to primary site
virtos-dr failback primary-site

# Cluster-wide backup
virtos-dr cluster-backup

# Restore entire cluster
virtos-dr cluster-restore cluster-20260522-120000
```

## Distributed Storage

```bash
# Initialize Ceph cluster
virtos-storage ceph-init

# Check Ceph status
virtos-storage ceph-status

# Create Ceph pool
virtos-storage ceph-pool-create vm-pool --replicas 3

# List Ceph pools
virtos-storage ceph-pool-list

# Initialize GlusterFS
virtos-storage gluster-init

# Check GlusterFS status
virtos-storage gluster-status

# Create GlusterFS volume
virtos-storage gluster-volume-create data-volume \
  --replicas 3 \
  --transport tcp

# Start GlusterFS volume
virtos-storage gluster-volume-start data-volume

# List GlusterFS volumes
virtos-storage gluster-volume-list

# Initialize clustered NFS
virtos-storage nfs-cluster-init

# Add NFS export
virtos-storage nfs-export-add /var/lib/virt/images

# List NFS exports
virtos-storage nfs-export-list

# List all storage pools
virtos-storage pool-list

# Create storage pool
virtos-storage pool-create distributed-vms ceph

# Check replication status
virtos-storage replication-status
```

## Network Virtualization

```bash
# Create VLAN
virtos-network vlan-create 100 dmz-network

# Delete VLAN
virtos-network vlan-delete 100

# List VLANs
virtos-network vlan-list

# Attach VM to VLAN
virtos-network vlan-attach web-server-1 100

# Initialize OVN
virtos-network ovn-init

# Check OVN status
virtos-network ovn-status

# Create virtual network
virtos-network ovn-network-create tenant-net \
  --subnet 10.10.0.0/24 \
  --gateway 10.10.0.1 \
  --dhcp 10.10.0.100-10.10.0.200

# Create bridge
virtos-network bridge-create isolated-br0

# List bridges
virtos-network bridge-list

# Create firewall rule
virtos-network firewall-create web-1 "allow tcp 80,443"

# List firewall rules
virtos-network firewall-list web-1

# Create network policy
virtos-network policy-create strict-web

# Apply policy to VM
virtos-network policy-apply web-1 strict-web

# Set QoS bandwidth limit
virtos-network qos-set download-vm 100

# Show QoS settings
virtos-network qos-show download-vm

# Enable SDN mode
virtos-network sdn-enable

# Check SDN status
virtos-network sdn-status
```

## GPU Passthrough

```bash
# Detect GPUs
virtos-gpu detect

# List GPUs with IOMMU groups
virtos-gpu list

# Check IOMMU status
virtos-gpu iommu-status

# Check VFIO driver status
virtos-gpu vfio-status

# Run interactive passthrough wizard
virtos-gpu wizard

# Isolate GPU for passthrough
virtos-gpu isolate 0000:01:00.0

# Release GPU back to host
virtos-gpu release 0000:01:00.0

# Attach GPU to VM
virtos-gpu attach gaming-vm 0000:01:00.0 --persistent

# Detach GPU from VM
virtos-gpu detach gaming-vm 0000:01:00.0

# Enable vGPU support
virtos-gpu vgpu-enable 0000:01:00.0

# List vGPU instances
virtos-gpu vgpu-list

# Schedule automatic GPU attachment
virtos-gpu schedule-attach workstation-vm 0000:01:00.0
```

## USB Device Management

```bash
# List USB devices
virtos-usb list

# Attach USB to VM
virtos-usb attach gaming-vm 001:004 --permanent

# Detach USB from VM
virtos-usb detach gaming-vm 001:004

# Hot-plug USB device (running VM)
virtos-usb hotplug workstation-vm 002:003

# Create USB filter
virtos-usb filter-create vm1 "046d:0825"

# Delete USB filter
virtos-usb filter-delete vm1 "046d:0825"

# List USB filters
virtos-usb filter-list vm1

# Enable USB redirection
virtos-usb redirect-enable desktop-vm

# Check redirection status
virtos-usb redirect-status desktop-vm

# Start USB monitoring daemon
virtos-usb monitor-start

# Stop USB monitoring daemon
virtos-usb monitor-stop

# Check monitor status
virtos-usb monitor-status

# Setup auto-attachment
virtos-usb auto-attach office-vm "046d:*"
```

## Phase 10 Commands

### Metrics & Telemetry (virtos-telemetry)

```bash
# Initialize Prometheus
virtos-telemetry prometheus-init

# Start Prometheus
virtos-telemetry prometheus-start

# Check Prometheus status
virtos-telemetry prometheus-status

# Initialize Grafana
virtos-telemetry grafana-init

# Start Grafana (available at :3000)
virtos-telemetry grafana-start

# Install exporters
virtos-telemetry exporter-install node
virtos-telemetry exporter-install libvirt
virtos-telemetry exporter-install cadvisor

# Add scrape target
virtos-telemetry target-add 192.168.1.101:9100 node-exporter

# View metrics (PromQL query)
virtos-telemetry metrics-view "up"
virtos-telemetry metrics-view "node_cpu_seconds_total"

# Create alert rule
virtos-telemetry alert-create high-cpu "node_cpu_seconds_total > 0.8"

# List alerts
virtos-telemetry alert-list

# Import Grafana dashboard
virtos-telemetry dashboard-import 1860  # Node Exporter Full

# Setup wizard
virtos-telemetry wizard
```

### Security Hardening (virtos-security)

```bash
# Initialize SELinux in enforcing mode
virtos-security selinux-init enforcing

# Create custom SELinux policy
virtos-security selinux-policy-create myapp targeted
virtos-security selinux-policy-compile myapp

# Initialize AppArmor
virtos-security apparmor-init enforce

# Create AppArmor profile
virtos-security apparmor-profile-create myapp /usr/local/bin/myapp
virtos-security apparmor-profile-load myapp

# Harden SSH configuration
virtos-security ssh-harden

# Initialize firewall
virtos-security firewall-init drop

# Add firewall rules
virtos-security firewall-rule-add tcp 80 ACCEPT
virtos-security firewall-rule-add tcp 443 ACCEPT

# Run vulnerability scan
virtos-security vulnerability-scan

# Check compliance (CIS, NIST, PCI-DSS, HIPAA)
virtos-security compliance-check cis
virtos-security compliance-check nist

# Enable audit logging
virtos-security audit-enable

# View audit logs
virtos-security audit-logs
virtos-security audit-logs root-commands

# Check security status
virtos-security status

# Security setup wizard
virtos-security wizard
```

### Billing & Cost Tracking (virtos-billing)

```bash
# Initialize billing system
virtos-billing init

# Track VM usage
virtos-billing track-usage web-server
virtos-billing track-usage database-vm

# Calculate costs
virtos-billing calculate-costs
virtos-billing calculate-costs web-server

# Cost report by period
virtos-billing cost-report "" day
virtos-billing cost-report "" week
virtos-billing cost-report "" month
virtos-billing cost-report web-server month

# Generate invoice
virtos-billing generate-invoice "Acme Corp" "2026-05-01" "2026-05-31"

# List invoices
virtos-billing list-invoices all
virtos-billing list-invoices pending
virtos-billing list-invoices paid

# View invoice
virtos-billing view-invoice INV-20260531-123456

# Mark invoice as paid
virtos-billing mark-paid INV-20260531-123456

# Set pricing (resource, price)
virtos-billing set-pricing cpu 0.10
virtos-billing set-pricing ram 0.02
virtos-billing set-pricing disk 0.15

# Show current pricing
virtos-billing show-pricing

# Billing setup wizard
virtos-billing wizard
```

### Service Mesh (virtos-mesh)

```bash
# Install service mesh
virtos-mesh istio-install
virtos-mesh linkerd-install
virtos-mesh consul-install

# Inject sidecar proxy
virtos-mesh inject-sidecar my-deployment default

# Enable mutual TLS
virtos-mesh mtls-enable

# Create virtual service (traffic routing)
virtos-mesh virtual-service-create my-svc my-app.local my-app-service 80

# Create destination rule (load balancing, connection pool)
virtos-mesh destination-rule-create my-rule my-app-service

# Traffic splitting (canary deployment)
virtos-mesh traffic-split my-service v1 v2 10  # 10% to v2

# Fault injection (chaos engineering)
virtos-mesh fault-inject my-service delay 10
virtos-mesh fault-inject my-service abort 5

# Circuit breaker
virtos-mesh circuit-breaker my-service 100 100

# Check mesh status
virtos-mesh status

# Open mesh dashboard
virtos-mesh dashboard  # Kiali/Linkerd viz/Consul UI

# Service mesh setup wizard
virtos-mesh wizard
```

## Phase 11 Commands

### Multi-Datacenter (virtos-datacenter)

```bash
# Initialize local datacenter
virtos-datacenter datacenter-init dc1 us-east

# Register remote datacenter
virtos-datacenter datacenter-register dc2 192.168.2.100 us-west
virtos-datacenter datacenter-register dc3 192.168.3.100 eu-central

# List datacenters
virtos-datacenter datacenter-list

# Remove datacenter
virtos-datacenter datacenter-remove dc3

# VM placement decision
virtos-datacenter vm-place production-db

# Setup replication between datacenters
virtos-datacenter replication-setup dc1 dc2

# Start replication
virtos-datacenter replication-start dc1 dc2

# Stop replication
virtos-datacenter replication-stop dc1 dc2

# Check replication status
virtos-datacenter replication-status

# Geographic load balancing
virtos-datacenter geo-loadbalance web-app 40.7 -74.0

# Disaster recovery failover
virtos-datacenter dr-failover dc1 dc2

# WAN optimization status
virtos-datacenter wan-status

# Setup wizard
virtos-datacenter wizard
```

### Advanced Analytics (virtos-analytics)

```bash
# Start data collection
virtos-analytics collection-start

# Stop data collection
virtos-analytics collection-stop

# Check collection status
virtos-analytics collection-status

# Resource utilization trends
virtos-analytics trends-report 7
virtos-analytics trends-report 30

# Capacity prediction
virtos-analytics capacity-predict cpu 30
virtos-analytics capacity-predict ram 60
virtos-analytics capacity-predict disk 90

# Anomaly detection
virtos-analytics anomaly-detect

# Cost optimization recommendations
virtos-analytics cost-optimize

# Performance report
virtos-analytics performance-report
virtos-analytics performance-report web-server

# Custom reports
virtos-analytics custom-report hourly
virtos-analytics custom-report daily

# Setup wizard
virtos-analytics wizard
```

### Edge Computing (virtos-edge)

```bash
# Initialize edge node
virtos-edge edge-init edge-node retail-store-1

# Initialize cloud hub
virtos-edge edge-init cloud-hub datacenter-1

# Register edge node with cloud hub
virtos-edge edge-register 192.168.1.100

# Deploy workload to edge
virtos-edge edge-deploy pos-system cloud
virtos-edge edge-deploy inventory-app cloud

# Workload placement decision
virtos-edge workload-place web-app 50
virtos-edge workload-place database 100

# Sync to cloud
virtos-edge sync-to-cloud /var/lib/virtos/edge-data/
virtos-edge sync-to-cloud /var/lib/virtos/edge-data/ incremental

# Sync from cloud
virtos-edge sync-from-cloud /var/lib/virtos/cloud-data/

# Start auto-sync (every 5 minutes)
virtos-edge sync-start 300

# Stop auto-sync
virtos-edge sync-stop

# Check sync status
virtos-edge sync-status

# Enable offline mode
virtos-edge offline-enable

# Disable offline mode
virtos-edge offline-disable

# Check offline status
virtos-edge offline-status

# Optimize bandwidth
virtos-edge bandwidth-optimize 50
virtos-edge bandwidth-optimize 100

# Test latency
virtos-edge latency-test 192.168.1.100
virtos-edge latency-test cloud-hub.example.com

# Edge status
virtos-edge edge-status

# Setup wizard
virtos-edge wizard
```

### Workflow Automation (virtos-automation)

```bash
# Create workflow
virtos-automation workflow-create nightly-backup
virtos-automation workflow-create vm-cleanup

# List workflows
virtos-automation workflow-list

# Run workflow
virtos-automation workflow-run nightly-backup

# Delete workflow
virtos-automation workflow-delete old-workflow

# Create scheduled task
virtos-automation schedule-create cleanup "find /tmp -mtime +7 -delete" "0 3 * * *"
virtos-automation schedule-create backup "virtos-backup backup-all" "0 2 * * *"

# List scheduled tasks
virtos-automation schedule-list

# Delete scheduled task
virtos-automation schedule-delete cleanup

# Enable auto-scaling
virtos-automation autoscale-enable web-app 2 10
virtos-automation autoscale-enable api-service 3 20

# Auto-scaling status
virtos-automation autoscale-status
virtos-automation autoscale-status web-app

# Trigger scale up
virtos-automation autoscale-up web-app

# Trigger scale down
virtos-automation autoscale-down web-app

# Enable self-healing for VMs
virtos-automation selfheal-enable vm

# Enable self-healing for containers
virtos-automation selfheal-enable container

# Self-healing status
virtos-automation selfheal-status

# Trigger event
virtos-automation event-trigger vm.created
virtos-automation event-trigger vm.failed

# Setup wizard
virtos-automation wizard
```

### AI Optimization (virtos-ai)

```bash
# Initialize AI engine
virtos-ai ai-init tensorflow      # Use TensorFlow
virtos-ai ai-init pytorch         # Use PyTorch
virtos-ai ai-init sklearn         # Use scikit-learn

# Train ML models
virtos-ai model-train-capacity    # Train capacity prediction model
virtos-ai model-train-placement   # Train VM placement model
virtos-ai model-train-anomaly     # Train anomaly detection model

# View model status
virtos-ai model-status

# Predict resource capacity
virtos-ai predict-capacity cpu    # CPU capacity prediction
virtos-ai predict-capacity memory # Memory capacity prediction

# AI-optimized placement
virtos-ai optimize-placement      # Find optimal host for new VMs

# Detect anomalies
virtos-ai detect-anomalies        # ML-based anomaly detection

# System auto-tuning
virtos-ai autotune-system         # AI-powered system optimization

# Workload balancing
virtos-ai balance-workload        # Intelligent workload distribution

# AI insights
virtos-ai insights-report         # Comprehensive AI analysis

# Setup wizard
virtos-ai wizard
```

### Quantum Computing (virtos-quantum)

```bash
# Initialize quantum simulator
virtos-quantum quantum-init qiskit 5        # Qiskit with 5 qubits
virtos-quantum quantum-init cirq 10         # Cirq with 10 qubits
virtos-quantum quantum-init pennylane 8     # PennyLane with 8 qubits

# Create quantum circuits
virtos-quantum circuit-create bell-state 2       # Bell state (2 qubits)
virtos-quantum circuit-create grover 4           # Grover's algorithm
virtos-quantum circuit-create qaoa 6             # QAOA circuit

# Run quantum circuits
virtos-quantum circuit-run bell-state 1000       # Run with 1000 shots
virtos-quantum circuit-run grover 5000           # Higher accuracy

# List circuits
virtos-quantum circuit-list

# Quantum algorithm optimization
virtos-quantum optimize-algorithm routing        # Network routing
virtos-quantum optimize-algorithm scheduling     # VM scheduling

# Quantum-safe encryption
virtos-quantum encryption-enable                 # Enable post-quantum crypto

# Quantum random numbers
virtos-quantum quantum-random 10                 # Generate 10 QRNs
virtos-quantum quantum-random 100                # Generate 100 QRNs

# Benchmarking
virtos-quantum benchmark-volume                  # Quantum volume test

# Error mitigation
virtos-quantum error-mitigation-enable

# Status
virtos-quantum quantum-status

# Setup wizard
virtos-quantum wizard
```

### Blockchain Auditing (virtos-blockchain)

```bash
# Initialize blockchain
virtos-blockchain blockchain-init poa virtos-chain      # PoA consensus
virtos-blockchain blockchain-init pbft enterprise-chain # PBFT consensus

# Verify blockchain integrity
virtos-blockchain blockchain-verify

# View blockchain status
virtos-blockchain blockchain-status

# List blocks
virtos-blockchain block-list

# Audit VM events (automatically creates blocks)
virtos-blockchain audit-vm web-server create "Ubuntu 22.04, 4 cores, 8GB RAM"
virtos-blockchain audit-vm web-server modify "Increased RAM to 16GB"
virtos-blockchain audit-vm web-server start "Brought online for production"
virtos-blockchain audit-vm web-server delete "End of lifecycle"

# Audit configuration changes
virtos-blockchain audit-config network "DNS change" "8.8.8.8" "1.1.1.1"
virtos-blockchain audit-config firewall "Allow port 443" "blocked" "allowed"
virtos-blockchain audit-config storage "Add NFS mount" "" "nfs1:/data"

# Smart contracts
virtos-blockchain contract-deploy quota-policy "VM resource quotas"
virtos-blockchain contract-deploy compliance "Compliance rules"
virtos-blockchain contract-execute quota-policy web-server
virtos-blockchain contract-list

# Compliance reporting
virtos-blockchain compliance-report 30        # Last 30 days
virtos-blockchain compliance-report 90        # Last 90 days

# Consensus status
virtos-blockchain consensus-status

# Setup wizard
virtos-blockchain wizard
```

### Cloud Federation (virtos-federation)

```bash
# Initialize federation
virtos-federation federation-init my-hybrid-cloud

# Register cloud providers
virtos-federation provider-register aws aws us-east-1.amazonaws.com AKIAXXXX secret
virtos-federation provider-register azure azure eastus.azure.com sub-12345 secret
virtos-federation provider-register gcp gcp us-central1.googleapis.com proj-456 secret
virtos-federation provider-register on-prem on-prem 192.168.1.100 "" ""

# Remove provider
virtos-federation provider-remove old-provider

# List providers
virtos-federation provider-list

# Deploy VMs to different clouds
virtos-federation vm-deploy web-server-1 aws t3.medium           # Deploy to AWS
virtos-federation vm-deploy web-server-2 azure Standard_D2s_v3   # Deploy to Azure
virtos-federation vm-deploy db-server gcp n1-standard-4          # Deploy to GCP
virtos-federation vm-deploy cache-server on-prem default         # Deploy on-prem

# Migrate VMs between clouds
virtos-federation vm-migrate web-server-1 aws azure              # AWS → Azure
virtos-federation vm-migrate db-server gcp on-prem               # GCP → On-prem

# Federated identity (SSO)
virtos-federation identity-setup aws              # Setup AWS SSO
virtos-federation identity-setup azure            # Setup Azure AD

# Cross-cloud networking
virtos-federation network-setup aws azure vpn                # VPN between clouds
virtos-federation network-setup gcp on-prem interconnect     # Direct interconnect

# Multi-cloud load balancing
virtos-federation loadbalance-setup global-lb aws azure gcp  # Global LB

# Hybrid orchestration
virtos-federation hybrid-orchestrate cost            # Cost-optimized placement
virtos-federation hybrid-orchestrate performance     # Performance-optimized
virtos-federation hybrid-orchestrate balanced        # Balanced approach

# Cost optimization
virtos-federation cost-optimize 30               # 30-day cost report

# Federation status
virtos-federation federation-status

# Setup wizard
virtos-federation wizard
```

## Build Commands

```bash
# Complete build (all steps)
cd build/scripts
./build-all.sh

# Individual steps
./prepare.sh      # Download and extract Tiny Core
./customize.sh    # Add FlossWare customizations  
./iso.sh          # Build bootable ISO

# Output
ls ../output/
```

## Test ISO

```bash
# In QEMU/KVM (fast)
qemu-system-x86_64 -enable-kvm -m 2048 \
    -cdrom build/output/FlossWare-Virt-*.iso

# Write to USB (DANGEROUS - verify device!)
sudo dd if=build/output/FlossWare-Virt-*.iso \
    of=/dev/sdX bs=4M status=progress && sync
```

## Helper Commands (once booted)

```bash
# First-time setup wizard (ncurses TUI)
sudo virtos-setup

# Management console (ncurses TUI)
virtos-tui

# Check KVM status
check-kvm

# Create a VM
create-vm myvm 20 /path/to/installer.iso

# Create remote user
add-user.sh vmadmin

# Check system info
cat /etc/virtos/version.txt

# Load extensions
tce-load -i qemu       # KVM/QEMU
tce-load -i lxc        # LXC containers
tce-load -i docker     # Docker
tce-load -i podman     # Podman
tce-load -i containerd # containerd
```

## KVM/QEMU

```bash
# Create disk image
qemu-img create -f qcow2 disk.qcow2 20G

# Simple VM
qemu-system-x86_64 -enable-kvm -m 2048 \
    -drive file=disk.qcow2,format=qcow2 \
    -cdrom installer.iso -boot d

# VM with networking (bridge)
qemu-system-x86_64 -enable-kvm -m 2048 \
    -drive file=disk.qcow2,format=qcow2 \
    -netdev bridge,id=net0,br=br0 \
    -device virtio-net,netdev=net0

# VM with VNC access
qemu-system-x86_64 -enable-kvm -m 2048 \
    -drive file=disk.qcow2,format=qcow2 \
    -vnc :0
# Connect with: vncviewer localhost:5900
```

## LXC

```bash
# Create container
lxc-create -n mycontainer -t download -- \
    -d ubuntu -r jammy -a amd64

# Start container
lxc-start -n mycontainer

# Attach to container
lxc-attach -n mycontainer

# List containers
lxc-ls -f

# Stop container
lxc-stop -n mycontainer

# Delete container
lxc-destroy -n mycontainer
```

## Docker

```bash
# Run container
docker run -d --name web -p 80:80 nginx

# List containers
docker ps

# View logs
docker logs web

# Execute command
docker exec -it web bash

# Stop/remove
docker stop web
docker rm web

# docker-compose
cd /path/to/compose/
docker-compose up -d
docker-compose logs
docker-compose down
```

## containerd

```bash
# Pull image
ctr image pull docker.io/library/nginx:latest

# Run container
ctr run -d docker.io/library/nginx:latest web1

# List containers
ctr task ls

# Execute command
ctr task exec --exec-id bash1 web1 bash

# Stop container
ctr task kill web1

# Remove container
ctr container delete web1
```

## Kubernetes (K3s)

```bash
# Install K3s server (first node)
curl -sfL https://get.k3s.io | sh -

# Get join token
sudo cat /var/lib/rancher/k3s/server/node-token

# Install K3s agent (other nodes)
curl -sfL https://get.k3s.io | \
  K3S_URL=https://virtos-1.local:6443 \
  K3S_TOKEN=<token> sh -

# Get nodes
sudo k3s kubectl get nodes

# Create deployment
sudo k3s kubectl create deployment nginx --image=nginx

# Scale deployment
sudo k3s kubectl scale deployment nginx --replicas=3

# Expose service
sudo k3s kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Get pods
sudo k3s kubectl get pods -o wide

# Get services
sudo k3s kubectl get svc

# Delete deployment
sudo k3s kubectl delete deployment nginx

# Uninstall K3s
sudo /usr/local/bin/k3s-uninstall.sh
```

## Networking

```bash
# Show bridges
brctl show

# Create bridge
brctl addbr br1
ifconfig br1 up

# Add interface to bridge
brctl addif br1 eth0

# Show routes
ip route

# Enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# NAT (replace eth0 with external interface)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i br0 -j ACCEPT
iptables -A FORWARD -o br0 -j ACCEPT
```

## Storage

```bash
# QEMU disk operations
qemu-img create -f qcow2 disk.qcow2 10G
qemu-img info disk.qcow2
qemu-img resize disk.qcow2 +10G
qemu-img convert -f qcow2 -O raw disk.qcow2 disk.raw

# Show mounts
mount

# Create mount point
mkdir /mnt/data
mount /dev/sdb1 /mnt/data
```

### Btrfs (if included)

```bash
# Create filesystem
mkfs.btrfs /dev/sdb1

# Mount with compression
mount -o compress=lz4 /dev/sdb1 /var/lib/vms

# Create subvolume
btrfs subvolume create /var/lib/vms/production

# Snapshot
btrfs subvolume snapshot /var/lib/vms/production \
  /var/lib/vms/backup-2026-05-22

# List subvolumes
btrfs subvolume list /var/lib/vms

# Delete snapshot
btrfs subvolume delete /var/lib/vms/backup-2026-05-22
```

### LVM (if included)

```bash
# Create physical volume
pvcreate /dev/sdb1

# Create volume group
vgcreate vg_vms /dev/sdb1

# Create logical volume
lvcreate -L 50G -n vm-disk vg_vms

# Format and mount
mkfs.ext4 /dev/vg_vms/vm-disk
mount /dev/vg_vms/vm-disk /mnt

# Extend volume
lvextend -L +50G /dev/vg_vms/vm-disk
resize2fs /dev/vg_vms/vm-disk

# Snapshot
lvcreate -L 10G -s -n vm-disk-snap /dev/vg_vms/vm-disk
```

### ZFS (if included)

```bash
# Create pool
zpool create vmpool /dev/sdb

# Create dataset with compression
zfs create vmpool/vms
zfs set compression=lz4 vmpool/vms

# Create zvol (block device)
zfs create -V 50G vmpool/vms/disk1

# Snapshot
zfs snapshot vmpool/vms@backup-2026-05-22

# Clone
zfs clone vmpool/vms@backup-2026-05-22 vmpool/test-clone

# Send to remote
zfs send vmpool/vms@backup | ssh host zfs receive pool/backup

# Pool status
zpool status
zpool iostat

# Dataset info
zfs list
zfs get compressratio vmpool/vms
```

### NFS (if included)

```bash
# Server - export directory
echo "/export/vms *(rw,sync,no_subtree_check)" >> /etc/exports
exportfs -av

# Client - mount
mount -t nfs virtos-1.local:/export/vms /var/lib/vms

# Show exports
showmount -e virtos-1.local
```

## libvirt (if installed)

```bash
# List VMs
virsh list --all

# Start VM
virsh start vmname

# Console access
virsh console vmname

# Shutdown VM
virsh shutdown vmname

# Define VM from XML
virsh define vm.xml

# Delete VM
virsh undefine vmname
```

## Persistence

```bash
# Backup configuration
filetool.sh -b

# Restore configuration
filetool.sh -r

# Edit backup list
vi /opt/.filetool.lst

# Backup now
sudo filetool.sh -b
```

## System Info

```bash
# CPU info
cat /proc/cpuinfo | grep -E "model name|vmx|svm"

# Memory
free -h

# Disk usage
df -h

# Kernel modules
lsmod

# System logs
dmesg | tail
```

## Troubleshooting

```bash
# KVM not available
lsmod | grep kvm           # Check modules loaded
check-kvm                  # Run diagnostic script
dmesg | grep kvm           # Check kernel messages

# Network issues
ip link show               # Show interfaces
brctl show                 # Show bridges
iptables -L -n -v          # Show firewall rules

# Container issues
docker info                # Docker status
systemctl status docker    # Docker service (if systemd)
journalctl -u docker       # Docker logs (if systemd)

# Disk space
du -sh /var/lib/docker     # Docker storage usage
du -sh /var/lib/lxc        # LXC storage usage
```

## File Locations

```
/opt/bootlocal.sh          - Boot script
/etc/sysctl.conf           - Kernel parameters
/etc/virtos/               - VirtOS config
/usr/local/bin/            - Helper scripts
/usr/local/share/doc/      - Documentation
/mnt/sda1/vms/             - VM storage (example)
/var/lib/lxc/              - LXC containers
/var/lib/docker/           - Docker data
```

## Boot Parameters

Edit at boot or in `/boot/grub/grub.cfg`:

```
# More memory for kernel
mem=4G

# KVM nested virtualization
kvm-intel.nested=1  # Intel
kvm-amd.nested=1    # AMD

# Console on serial
console=ttyS0,115200
```

## Performance Tuning

```bash
# CPU pinning (QEMU)
qemu-system-x86_64 -smp 4,cores=4 -cpu host

# Huge pages
echo 1024 > /proc/sys/vm/nr_hugepages

# I/O scheduler (for SSDs)
echo noop > /sys/block/sda/queue/scheduler
```
