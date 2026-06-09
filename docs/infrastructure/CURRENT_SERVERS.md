# VirtOS Infrastructure - Current Server Status

**Last Updated**: 2026-06-09

## Active Servers

| Server | IP | CPU | RAM | Status | Notes |
|--------|-----|-----|-----|--------|-------|
| server-01 | 192.168.1.244 | Core i7-3630QM | 15GB | Unknown | Last seen: 2026-06-06 |
| server-02 | 192.168.1.15 | Xeon X5365 | 31GB | Unknown | Last seen: 2026-06-06 |
| server-03 | 192.168.1.16 | Xeon X5460 | 31GB | Unknown | Last seen: 2026-06-06 |
| aio-01 | 192.168.1.11 | AMD E2-1800 | 7GB | Unknown | Last seen: 2026-06-06 |

## Decommissioned Servers

| Server | IP | CPU | RAM | Decommission Date | Notes |
|--------|-----|-----|-----|-------------------|-------|
| server-04 | 192.168.1.17 | Core i7-8665U | 31GB | 2026-06-09 | Hardware no longer available |

## Historical Deployments

### 2026-06-06 Deployment (5-node cluster)
- **Duration**: 44 minutes
- **Success Rate**: 100% (5/5 nodes)
- **Total Resources**: 30GB RAM, 15 vCPUs
- **Status**: Validated infrastructure, features pending console access

### Current Infrastructure Capacity (4 remaining servers)
- **Total RAM**: 84GB physical (can allocate ~21GB to VMs safely)
- **Total CPU Cores**: ~12-16 cores
- **Potential VMs**: 4 VirtOS nodes
- **Network**: All on 192.168.1.0/24 subnet

## Server Access Status Check

**Command to verify**:
```bash
for ip in 192.168.1.244 192.168.1.15 192.168.1.16 192.168.1.11; do
    echo -n "Server $ip: "
    timeout 2 ssh -o ConnectTimeout=1 root@$ip "hostname" 2>&1 || echo "unreachable"
done
```

**Last Check**: 2026-06-09 - All servers unreachable (possibly powered off or network changed)

## Next Steps

1. **Verify remaining servers are accessible**
   - Check if servers are powered on
   - Verify network configuration
   - Confirm SSH access

2. **Deploy to available servers**
   - 4-node cluster (excluding server-04)
   - Adjust resource allocation accordingly

3. **Update deployment scripts**
   - Remove server-04 from deployment targets
   - Update automated scripts

## For New Deployments

If you have different servers available, provide:
- IP addresses
- SSH credentials (or confirm passwordless root SSH)
- Approximate CPU/RAM specs (for auto-sizing)

---

**Maintained By**: VirtOS Development Team
**Status**: Active infrastructure tracking
