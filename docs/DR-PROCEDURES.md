# VirtOS Disaster Recovery Procedures

**Last Updated**: 2026-05-26  
**Applies to**: VirtOS 0.80+

## Overview

This document describes disaster recovery (DR) procedures for VirtOS, including backup strategies, failover processes, recovery procedures, and testing requirements.

## Disaster Recovery Objectives

### Recovery Time Objective (RTO)

**RTO** = Maximum acceptable downtime after a disaster

| Tier | Description | RTO Target | Examples |
|------|-------------|------------|----------|
| Tier 0 | Critical | 1 hour | Payment processing, authentication |
| Tier 1 | Important | 4 hours | Web applications, databases |
| Tier 2 | Standard | 24 hours | Development environments, internal tools |
| Tier 3 | Low Priority | 7 days | Archives, reporting systems |

### Recovery Point Objective (RPO)

**RPO** = Maximum acceptable data loss

| Tier | Description | RPO Target | Backup Frequency |
|------|-------------|------------|------------------|
| Tier 0 | Critical | 15 minutes | Every 15 minutes |
| Tier 1 | Important | 1 hour | Hourly |
| Tier 2 | Standard | 24 hours | Daily |
| Tier 3 | Low Priority | 7 days | Weekly |

## DR Scenarios

### 1. Single Host Failure

**Cause**: Hardware failure, power loss, OS corruption

**Impact**: All VMs on that host offline

**Recovery Procedure**:

```bash
# 1. Verify host is down
ping virtos-host-01
# No response

# 2. If HA configured, automatic failover occurs
virtos-ha status
# Output: host-01 OFFLINE, VMs migrated to host-02

# 3. If no HA, manual recovery
# Restore VMs to backup host
virtos-dr execute-dr-plan host-01-failure

# 4. Or restore individual VMs
for vm in $(virsh list --name --all); do
    virtos-backup restore-backup $vm latest --target virtos-host-02
done

# 5. Verify recovery
virsh list --all  # On backup host
virtos-monitor resources

# 6. Update DNS/load balancers if needed
```

**RTO**: 1-4 hours (depending on HA setup)  
**RPO**: Last backup (up to 24 hours for standard tier)

### 2. Complete Datacenter Failure

**Cause**: Natural disaster, extended power outage, fire

**Impact**: All hosts and VMs offline

**Recovery Procedure**:

```bash
# 1. Declare disaster (notify stakeholders)
echo "DISASTER DECLARED: Primary datacenter offline" | \
    mail -s "DR ACTIVATION" ops@example.com

# 2. Activate DR site
virtos-dr activate-dr-site

# Steps performed:
# - Verify DR site connectivity
# - Mount backup storage
# - Verify network configuration
# - Check resource availability

# 3. Restore Tier 0 VMs first (critical)
virtos-dr restore-tier 0
# This restores:
# - payment-api
# - auth-server
# - database-primary

# 4. Verify Tier 0 operational
for vm in payment-api auth-server database-primary; do
    virsh start $vm
    sleep 60
    virtos-monitor status $vm
    # Test application connectivity
done

# 5. Restore Tier 1 VMs (important)
virtos-dr restore-tier 1

# 6. Update DNS to point to DR site
virtos-dr update-dns-to-dr

# 7. Restore remaining tiers as resources allow

# 8. Monitor and stabilize
virtos-monitor resources --watch
```

**RTO**: 4-8 hours  
**RPO**: Varies by tier (15 min to 24 hours)

### 3. Ransomware Attack

**Cause**: Ransomware encrypts VM disks

**Impact**: VMs inaccessible, data encrypted

**Recovery Procedure**:

```bash
# 1. Immediately isolate infected VMs
virsh destroy infected-vm
virtos-network bridge-detach infected-vm all-networks

# 2. Preserve evidence (for forensics)
virtos-snapshot create infected-vm ransomware-forensics-$(date +%s)

# 3. Identify clean backup (before infection)
virtos-backup list-backups infected-vm
# Identify last known good backup

# 4. Restore from clean backup
virtos-backup restore-backup infected-vm 2026-05-20-daily

# 5. Verify VM is clean
# Scan for malware before starting
virsh start infected-vm --paused
# Mount disk and scan
clamscan -r /var/lib/libvirt/images/infected-vm.qcow2

# 6. If clean, resume
virsh resume infected-vm

# 7. Update all credentials
virtos-secrets rotate-all

# 8. Patch vulnerabilities
virtos-update security-patch-all
```

**RTO**: 2-4 hours per VM  
**RPO**: Last clean backup (varies)

### 4. Storage System Failure

**Cause**: SAN/NAS failure, disk corruption

**Impact**: VM disks inaccessible

**Recovery Procedure**:

```bash
# 1. Verify storage failure
virtos-storage list-pools
# Output: default UNAVAILABLE

# 2. Stop all VMs gracefully
for vm in $(virsh list --name); do
    virsh shutdown $vm
done

# 3. If shared storage, failover to replica
virtos-storage failover-pool default default-replica

# 4. If local storage, restore VMs from backup
virtos-dr restore-all-vms --from-backup --target alternate-pool

# 5. Start VMs on recovered storage
for vm in $(virsh list --name --inactive); do
    virsh start $vm
done
```

**RTO**: 2-6 hours  
**RPO**: Last backup (up to 24 hours)

### 5. Accidental VM Deletion

**Cause**: Human error, automation bug

**Impact**: Single VM lost

**Recovery Procedure**:

```bash
# 1. Verify VM is deleted
virsh list --all | grep deleted-vm
# Output: (empty)

# 2. Check if snapshot exists
virtos-snapshot list deleted-vm
# Error: Domain not found

# 3. Restore from latest backup
virtos-backup restore-backup deleted-vm latest

# 4. Verify restoration
virsh dominfo deleted-vm
virsh start deleted-vm

# 5. Test application
# SSH, check services, verify data
```

**RTO**: 30 minutes  
**RPO**: Last backup (up to 24 hours)

### 6. Network Partition (Split-Brain)

**Cause**: Network failure between cluster nodes

**Impact**: Cluster split, both sides think they're primary

**Recovery Procedure**:

```bash
# 1. Identify split-brain condition
virtos-cluster status
# Output: WARNING: Split-brain detected
#         host-01: PRIMARY (3 VMs)
#         host-02: PRIMARY (5 VMs)

# 2. Stop VMs on secondary (less VMs or lower priority)
ssh host-01
for vm in $(virsh list --name); do
    virsh destroy $vm
done

# 3. Fence secondary node
virtos-cluster fence-node host-01

# 4. Fix network partition
# Repair network switch, cables, etc.

# 5. Rejoin cluster
virtos-cluster rejoin-node host-01

# 6. Verify cluster health
virtos-cluster status
# Output: All nodes: HEALTHY, host-02: PRIMARY

# 7. Start VMs on rejoined node
ssh host-01
virtos-cluster rebalance
```

**RTO**: 1-2 hours  
**RPO**: 0 (no data loss if handled correctly)

## Backup Infrastructure

### Backup Storage

#### Local Backups (On-site)

```bash
# Configure local backup storage
mkdir -p /mnt/backup-local
virtos-backup configure \
    --backend local \
    --path /mnt/backup-local \
    --retention 30

# Pros: Fast restore, no network dependency
# Cons: Lost in site-wide disaster
```

#### Remote Backups (Off-site)

```bash
# Configure NFS remote backup
sudo mount -t nfs backup.remote.example.com:/virtos-backups /mnt/backup-remote

virtos-backup configure \
    --backend nfs \
    --path /mnt/backup-remote \
    --retention 90 \
    --encryption enabled

# Pros: Survives site disaster
# Cons: Slower restore, network dependency
```

#### Cloud Backups

```bash
# Configure S3 backup
virtos-backup configure \
    --backend s3 \
    --bucket virtos-backups \
    --region us-east-1 \
    --retention 365 \
    --encryption enabled

# Pros: Durable, geographically distributed
# Cons: Slowest restore, egress costs
```

### Backup Schedule

#### Daily Backups (Tier 2-3)

```bash
# Configure daily backup job
virtos-backup schedule \
    --vms "web-*,app-*,dev-*" \
    --frequency daily \
    --time "02:00" \
    --retention 30

# Cron job (alternative)
echo "0 2 * * * /usr/local/bin/virtos-backup create-all-backups daily" | crontab -
```

#### Hourly Backups (Tier 1)

```bash
# Configure hourly backup job
virtos-backup schedule \
    --vms "database-*,api-*" \
    --frequency hourly \
    --retention 168  # 7 days of hourly

# Cron job
echo "0 * * * * /usr/local/bin/virtos-backup create-backup database-prod hourly" | crontab -
```

#### Continuous Replication (Tier 0)

```bash
# Configure real-time replication to DR site
virtos-dr setup-replication \
    --primary virtos-prod-01 \
    --secondary virtos-dr-01 \
    --vms "payment-api,auth-server" \
    --interval 15min \
    --async

# Verify replication
virtos-dr check-replication-status
# Output: payment-api: Synced (lag: 12 seconds)
#         auth-server: Synced (lag: 8 seconds)
```

### Backup Verification

```bash
# Weekly backup verification
# Restore random backup to test environment
RANDOM_VM=$(virsh list --name | shuf -n 1)
RANDOM_BACKUP=$(virtos-backup list-backups $RANDOM_VM | tail -1)

virtos-backup restore-backup $RANDOM_VM $RANDOM_BACKUP --target test-host
virsh start $RANDOM_VM

# Test VM boots and functions
# Document results
echo "Backup verification: $RANDOM_VM from $RANDOM_BACKUP - SUCCESS" | \
    mail -s "Backup Verification Report" ops@example.com
```

## DR Site Configuration

### Minimum DR Site Requirements

```
Primary Site                    DR Site
─────────────────              ──────────────────
3 VirtOS hosts                 1 VirtOS host (minimum)
64 GB RAM per host             64 GB RAM
1 TB NVMe SSD                  1 TB SSD
10 Gbps network                1 Gbps network (minimum)
Shared NFS storage             Local storage + NFS backup
```

### DR Site Setup

```bash
# 1. Install VirtOS on DR host
# Follow: INSTALLATION.md

# 2. Configure replication from primary
virtos-dr setup-replication \
    --primary-cluster virtos-prod \
    --dr-host virtos-dr-01 \
    --replication-schedule hourly

# 3. Create DR network matching production
virtos-network bridge-create virbr0
virtos-network create-nat default 192.168.122.0/24

# 4. Mount backup storage
sudo mount -t nfs backup.example.com:/backups /mnt/dr-backups

# 5. Test DR failover
virtos-dr test-failover --dry-run

# 6. Document DR procedures
virtos-dr generate-runbook > /root/DR-RUNBOOK.md
```

### DR Testing Schedule

#### Monthly DR Drill (Partial)

```bash
# First Saturday of each month

# 1. Select non-critical VM
TEST_VM="dev-web-01"

# 2. "Fail" VM on primary
virsh destroy $TEST_VM

# 3. Restore on DR site
ssh virtos-dr-01
virtos-backup restore-backup $TEST_VM latest
virsh start $TEST_VM

# 4. Verify functionality
virtos-monitor status $TEST_VM

# 5. Measure RTO
# Expected: < 30 minutes

# 6. Failback
virsh destroy $TEST_VM
ssh virtos-prod-01
virsh start $TEST_VM

# 7. Document results
```

#### Quarterly Full DR Test

```bash
# Scheduled maintenance window

# 1. Activate full DR site
virtos-dr activate-dr-site

# 2. Failover all Tier 0 and Tier 1 VMs
virtos-dr failover-tier 0
virtos-dr failover-tier 1

# 3. Run production traffic through DR for 4 hours
# Update DNS to point to DR
# Monitor performance and stability

# 4. Measure RTO for each tier
# Document any issues

# 5. Failback to primary
virtos-dr failback-to-primary

# 6. Generate report
virtos-dr generate-test-report > /root/DR-TEST-$(date +%Y%m%d).pdf
```

## DR Runbook Template

```markdown
# VirtOS Disaster Recovery Runbook

## Emergency Contacts

| Role | Name | Phone | Email |
|------|------|-------|-------|
| Primary On-Call | John Doe | +1-555-1234 | john@example.com |
| Secondary On-Call | Jane Smith | +1-555-5678 | jane@example.com |
| Manager | Bob Johnson | +1-555-9999 | bob@example.com |
| Vendor Support | VirtOS Support | +1-555-0000 | support@flossware.org |

## Disaster Declaration Criteria

Declare disaster if ANY of the following occur:

- [ ] Primary datacenter offline > 1 hour
- [ ] >50% of VMs unavailable
- [ ] Critical Tier 0 VMs down > 15 minutes
- [ ] Data corruption detected
- [ ] Ransomware attack confirmed
- [ ] Unrecoverable hardware failure

## DR Activation Steps

### Step 1: Assessment (5 minutes)

```bash
# Verify primary site is down
ping -c 10 virtos-prod-01.example.com
ssh virtos-prod-01.example.com

# Check cluster status
virtos-cluster status

# Estimate RTO/RPO impact
virtos-dr estimate-impact
```

### Step 2: Notification (5 minutes)

```bash
# Notify stakeholders
cat > /tmp/dr-notification.txt <<EOF
DISASTER RECOVERY ACTIVATION

Time: $(date)
Cause: [Primary datacenter offline]
Impact: [All production VMs offline]
Estimated RTO: [4 hours]
Estimated RPO: [1 hour]

DR Team Activated.
Updates every 30 minutes.
EOF

# Send notifications
mail -s "DR ACTIVATED" stakeholders@example.com < /tmp/dr-notification.txt
# Also: Slack, PagerDuty, phone calls
```

### Step 3: DR Site Activation (15 minutes)

```bash
# 1. Verify DR site resources
ssh virtos-dr-01
virtos-monitor resources
# Verify: Sufficient CPU, RAM, disk

# 2. Mount backup storage
sudo mount -t nfs backup.example.com:/backups /mnt/dr-backups
df -h /mnt/dr-backups

# 3. Verify network configuration
ip addr show
virtos-network list
```

### Step 4: Restore Tier 0 VMs (60 minutes)

```bash
# Critical VMs (RTO: 1 hour)

# payment-api
virtos-backup restore-backup payment-api latest
virsh start payment-api
# Wait for boot
sleep 120
# Test
curl http://payment-api:8080/health

# auth-server
virtos-backup restore-backup auth-server latest
virsh start auth-server
sleep 120
curl http://auth-server:8081/health

# database-primary
virtos-backup restore-backup database-primary latest
virsh start database-primary
sleep 180
# Verify database
virsh console database-primary
# mysql -u root -p -e "SHOW DATABASES;"
```

### Step 5: Update DNS (10 minutes)

```bash
# Point production DNS to DR site

# payment-api.example.com: 192.168.1.10 → 192.168.2.10
# auth-server.example.com: 192.168.1.11 → 192.168.2.11

# Update DNS
virtos-dr update-dns-to-dr

# Verify propagation
dig payment-api.example.com
# Should show DR IP: 192.168.2.10

# Update monitoring
# Point monitoring to DR instances
```

### Step 6: Restore Tier 1 VMs (120 minutes)

```bash
# Important VMs (RTO: 4 hours)

for vm in web-app database-read-replica api-gateway; do
    echo "Restoring $vm..."
    virtos-backup restore-backup $vm latest
    virsh start $vm
    sleep 60
    virtos-monitor status $vm
done
```

### Step 7: Validation (30 minutes)

```bash
# Test critical workflows

# 1. User authentication
curl -X POST http://auth-server:8081/login \
    -d '{"username":"test","password":"test"}'

# 2. Payment processing
curl -X POST http://payment-api:8080/payment \
    -d '{"amount":10.00,"currency":"USD"}'

# 3. Web application
curl http://web-app:80/

# 4. Database queries
virsh console database-primary
# Run test queries
```

### Step 8: Monitoring (Ongoing)

```bash
# Monitor DR environment

# Resource usage
watch -n 60 'virtos-monitor resources'

# VM health
watch -n 60 'virsh list --all'

# Application metrics
# Check dashboards, logs, alerts

# Notify users service is restored
echo "Service restored on DR site. Monitoring for stability." | \
    mail -s "DR: Service Restored" stakeholders@example.com
```

## Failback Procedure

When primary site is restored:

```bash
# 1. Verify primary site is healthy
ping virtos-prod-01
ssh virtos-prod-01 virtos-monitor resources

# 2. Synchronize data from DR to primary
virtos-dr sync-dr-to-primary

# 3. Stop VMs on DR site (planned maintenance window)
for vm in $(virsh list --name); do
    virsh shutdown $vm
done

# 4. Restore VMs on primary from DR backups
for vm in payment-api auth-server database-primary; do
    virtos-backup restore-backup $vm dr-latest --target virtos-prod-01
done

# 5. Start VMs on primary
ssh virtos-prod-01
for vm in $(virsh list --name --inactive); do
    virsh start $vm
    sleep 60
done

# 6. Update DNS back to primary
virtos-dr update-dns-to-primary

# 7. Verify functionality

# 8. Notify users failback complete
```

```

## Recovery Validation Checklist

After DR activation, verify:

### Infrastructure

- [ ] All hosts accessible
- [ ] Sufficient resources (CPU, RAM, disk)
- [ ] Network connectivity functional
- [ ] Storage pools available
- [ ] Backup storage mounted

### VMs

- [ ] All VMs restored (compare count with pre-disaster)
- [ ] All VMs started successfully
- [ ] No VM errors in logs

### Applications

- [ ] Web applications accessible
- [ ] Databases accepting connections
- [ ] APIs responding correctly
- [ ] Authentication working
- [ ] Critical workflows function

### Data Integrity

- [ ] Database consistency checks pass
- [ ] No data corruption detected
- [ ] Transaction logs intact
- [ ] Application data complete

### Performance

- [ ] Response times acceptable
- [ ] No resource bottlenecks
- [ ] Network latency normal
- [ ] Disk I/O performance adequate

## Documentation and Reporting

### Incident Report Template

```markdown
# DR Incident Report

**Date**: 2026-05-26
**Incident ID**: DR-2026-001

## Summary
[Brief description of disaster and response]

## Timeline
- 10:00 AM: Primary datacenter power failure
- 10:05 AM: Disaster declared
- 10:15 AM: DR site activation began
- 11:00 AM: Tier 0 VMs restored
- 12:30 PM: Tier 1 VMs restored
- 01:00 PM: Service fully operational on DR site

## Impact
- **Duration**: 3 hours
- **Affected VMs**: 24
- **Users impacted**: All (500)
- **Revenue impact**: $X,XXX

## RTO/RPO Achievement
| Tier | Target RTO | Actual RTO | Target RPO | Actual RPO |
|------|------------|------------|------------|------------|
| 0    | 1 hour     | 1 hour     | 15 min     | 20 min     |
| 1    | 4 hours    | 2.5 hours  | 1 hour     | 1.5 hours  |

## What Went Well
- DR site activation smooth
- Backups all restored successfully
- Team executed runbook effectively
- Communication clear

## What Could Improve
- Tier 0 RPO exceeded by 5 minutes
- DNS propagation took longer than expected
- One VM failed to start (manual intervention required)

## Action Items
- [ ] Increase backup frequency for Tier 0 (15min → 10min)
- [ ] Automate DNS failover
- [ ] Add pre-start VM validation
- [ ] Update runbook with lessons learned

## Conclusion
DR successfully executed. Service restored within acceptable RTO for all tiers.
```

## Getting Help

- **DR Planning**: <consulting@flossware.org>
- **Emergency DR Support**: +1-555-DR-HELP (24/7)
- **Documentation**: [docs/DR-PROCEDURES.md](DR-PROCEDURES.md)

---

**DR Procedures Version**: 1.0 (2026-05-26)  
**Applies to**: VirtOS 0.80+  
**Related**: [QUICK-REFERENCE.md](QUICK-REFERENCE.md), [MONITORING-SETUP.md](MONITORING-SETUP.md)
