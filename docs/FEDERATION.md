# VirtOS Federation Guide

Multi-cloud and hybrid cloud federation for unified infrastructure management.

## Overview

VirtOS Federation allows you to create a unified virtualization platform spanning:

- **Multiple VirtOS hosts** (on-premises cluster)
- **Public cloud providers** (AWS, Azure, GCP)
- **Hybrid deployments** (mix of on-prem and cloud)

Think of it as "one control plane, many clouds."

## What is Federation?

Federation connects disparate infrastructure into a single logical system:

```
┌─────────────────────────────────────────────────────────┐
│            VirtOS Federation Control Plane              │
│         (Unified Management & Orchestration)            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │ VirtOS   │  │   AWS    │  │  Azure   │  │  GCP   │ │
│  │ On-Prem  │  │   EC2    │  │   VMs    │  │ Compute│ │
│  └──────────┘  └──────────┘  └──────────┘  └────────┘ │
│                                                         │
│  Federated Identity • Cross-Cloud Networking           │
│  Load Balancing • Cost Optimization • Hybrid Workloads │
└─────────────────────────────────────────────────────────┘
```

## Features

### Unified Management

- **Single interface** for all infrastructure
- **One set of tools** (`virtos-*` commands work everywhere)
- **Consistent workflows** across providers

### Federated Identity (SSO)

- **SAML 2.0** integration
- **Single sign-on** across all clouds
- **Role synchronization** and attribute mapping

### Cross-Cloud Networking

- **VPN tunnels** between providers
- **Unified network namespace** (10.0.0.0/8 everywhere)
- **Service mesh** across clouds

### Multi-Cloud Load Balancing

- **Geographic distribution** of workloads
- **Automatic failover** between providers
- **Cost-aware** routing

### Workload Migration

- **Live migration** between clouds
- **Snapshot and transfer** workflow
- **Automatic format conversion**

### Cost Optimization

- **Compare provider costs** for workloads
- **Placement recommendations** (cheapest region/instance type)
- **Budget tracking** across all clouds

## Quick Start

### 1. Initialize Federation

**Via TUI:**

```bash
virtos-tui
→ 23. Cloud Federation
→ 1. Initialize Federation
→ Enter name: "my-company-fed"
```

**Via CLI:**

```bash
virtos-federation federation-init my-company-fed
```

Creates:

- Federation metadata at `/var/lib/virtos/federation/`
- Configuration at `/etc/virtos/federation.conf`
- Registers local on-premises provider automatically

### 2. Register Cloud Providers

**Register AWS:**

```bash
virtos-federation provider-register \
  aws \
  aws \
  ec2.amazonaws.com \
  <YOUR_AWS_ACCESS_KEY> \
  wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

**Register Azure:**

```bash
virtos-federation provider-register \
  azure-prod \
  azure \
  management.azure.com \
  your-client-id \
  your-client-secret
```

**Register GCP:**

```bash
virtos-federation provider-register \
  gcp-us \
  gcp \
  compute.googleapis.com \
  your-service-account \
  your-key-json
```

### 3. List Providers

```bash
virtos-federation provider-list
```

Output:

```
Name                 Type      Endpoint              Status
-------------------- --------- --------------------- ------
on-prem              local     virtos-1              active
aws                  aws       ec2.amazonaws.com     active
azure-prod           azure     management.azure.com  active
gcp-us               gcp       compute.googleapis.com active
```

### 4. Deploy VM to Cloud

```bash
virtos-federation vm-deploy web-server aws t3.medium
```

Provisions:

- EC2 instance in AWS
- Connects to federation VPN
- Registers in unified DNS
- Updates load balancer

### 5. View Federation Status

```bash
virtos-federation federation-status
```

Shows:

- All registered providers
- VM count per provider
- Network connectivity
- Identity federation status
- Cost summary

## Use Cases

### Scenario 1: Hybrid Cloud Web App

**Setup:**

- **Database**: On-premises VirtOS (compliance requirement)
- **Web tier**: AWS (auto-scaling)
- **Media processing**: GCP (GPU instances)

**Implementation:**

```bash
# Initialize federation
virtos-federation federation-init webapp-fed

# Register clouds
virtos-federation provider-register aws aws ec2.amazonaws.com KEY SECRET
virtos-federation provider-register gcp gcp compute.googleapis.com KEY SECRET

# Deploy database on-prem (already registered)
virtos-create-vm --name db-primary --cpu 8 --ram 32768 --disk 500G

# Deploy web tier to AWS
virtos-federation vm-deploy web-1 aws t3.large
virtos-federation vm-deploy web-2 aws t3.large
virtos-federation vm-deploy web-3 aws t3.large

# Deploy media workers to GCP (GPUs)
virtos-federation vm-deploy media-worker-1 gcp n1-standard-8-gpu
virtos-federation vm-deploy media-worker-2 gcp n1-standard-8-gpu

# Setup cross-cloud networking
virtos-federation network-setup on-prem aws
virtos-federation network-setup on-prem gcp

# Setup load balancer
virtos-federation loadbalance-setup web aws
```

**Result:**

- Database stays on-prem (compliance)
- Web tier auto-scales in AWS
- GPU work happens in GCP
- All communicate over VPN
- Single management interface

### Scenario 2: Geographic Distribution

**Requirements:**

- Serve users in US, EU, Asia
- Low latency everywhere
- Single deployment workflow

**Implementation:**

```bash
# Initialize
virtos-federation federation-init global-app

# Register regional providers
virtos-federation provider-register aws-us-east aws ec2.us-east-1.amazonaws.com KEY SECRET
virtos-federation provider-register aws-eu-west aws ec2.eu-west-1.amazonaws.com KEY SECRET
virtos-federation provider-register aws-ap-southeast aws ec2.ap-southeast-1.amazonaws.com KEY SECRET

# Deploy to all regions
for region in aws-us-east aws-eu-west aws-ap-southeast; do
  virtos-federation vm-deploy app-$region $region t3.medium
done

# Setup geo load balancing
virtos-federation loadbalance-setup app global --geo-routing
```

**Result:**

- VMs in 3 regions (US, EU, Asia)
- Geo-DNS routes to nearest region
- Unified monitoring and updates
- Deploy once, run everywhere

### Scenario 3: Cloud Bursting

**Scenario:**

- Normal load: On-prem capacity sufficient
- Peak load: Burst to AWS

**Implementation:**

```bash
# Setup federation
virtos-federation federation-init burst-cluster
virtos-federation provider-register aws aws ec2.amazonaws.com KEY SECRET

# Setup hybrid orchestration (auto-burst)
virtos-federation hybrid-orchestrate \
  --on-prem-capacity 100 \
  --burst-provider aws \
  --burst-threshold 80 \
  --burst-instance-type t3.large
```

**Behavior:**

- When on-prem CPU > 80%, launch AWS instances
- When load drops < 60%, terminate AWS instances
- Automatic workload migration
- Cost-optimized (pay only during peaks)

### Scenario 4: Disaster Recovery Across Clouds

**Setup:**

- **Primary**: On-premises VirtOS
- **DR**: Azure (different geographic region)
- **RPO**: 1 hour (max data loss)
- **RTO**: 4 hours (max recovery time)

**Implementation:**

```bash
# Initialize federation
virtos-federation federation-init dr-setup
virtos-federation provider-register azure-dr azure management.azure.com KEY SECRET

# Setup DR for critical VMs
virtos-dr plan-create prod-failover

# Configure replication
for vm in web-1 web-2 db-primary; do
  virtos-dr replicate-start $vm azure-dr --interval 3600
done

# Test failover
virtos-dr plan-execute prod-failover --test
```

**Failover Process:**

1. Detect primary site failure
2. Automatically start replicas in Azure
3. Update DNS to point to Azure
4. Application resumes in cloud (within RTO)

### Scenario 5: Cost Optimization

**Goal:** Run workloads on cheapest provider

**Implementation:**

```bash
# Initialize with all major clouds
virtos-federation federation-init cost-optimized
virtos-federation provider-register aws aws ec2.amazonaws.com KEY1 SECRET1
virtos-federation provider-register azure azure management.azure.com KEY2 SECRET2
virtos-federation provider-register gcp gcp compute.googleapis.com KEY3 SECRET3

# Run cost optimization analysis
virtos-federation cost-optimize --workload "4 CPU, 16GB RAM, 100GB disk"
```

Output:

```
Workload: 4 CPU, 16GB RAM, 100GB disk
Cost Analysis (per month):

Provider    Instance Type      Region        Cost/month
----------- ------------------ ------------- -----------
GCP         n1-standard-4      us-central1   $121.73  ← CHEAPEST
AWS         t3.xlarge          us-east-1     $133.44
Azure       Standard_D4s_v3    eastus        $140.16
On-Prem     4-core allocation  local         $0 (owned)

Recommendation: Deploy to GCP us-central1 (saves $18.43/month vs Azure)
```

## Configuration

### Federation Config File

Location: `/etc/virtos/federation.conf`

```bash
# VirtOS Federation Configuration

FEDERATION_ENABLED="yes"
FEDERATION_NAME="my-company-fed"

# Features
FEDERATED_IDENTITY="yes"          # SSO across clouds
CROSS_CLOUD_NETWORKING="yes"      # VPN tunnels
HYBRID_ORCHESTRATION="yes"        # Auto-burst
MULTI_CLOUD_LOADBALANCE="yes"     # Geo load balancing
COST_OPTIMIZATION="yes"           # Cost-aware placement
```

### Provider Metadata

Location: `/var/lib/virtos/federation/providers/*.provider`

Example: `aws.provider`

```json
{
  "name": "aws",
  "type": "aws",
  "endpoint": "ec2.amazonaws.com",
  "registered": "2026-05-25T10:30:00Z",
  "status": "active",
  "credentials": {
    "access_key": "<YOUR_AWS_ACCESS_KEY>",
    "secret": "***REDACTED***"
  },
  "capabilities": {
    "compute": true,
    "storage": true,
    "networking": true
  }
}
```

### Identity Federation

Location: `/var/lib/virtos/federation/identity/*.conf`

Example SAML configuration:

```json
{
  "provider": "aws",
  "identity_provider": "SAML 2.0",
  "sso_enabled": true,
  "trust_relationship": {
    "entity_id": "virtos-federation",
    "assertion_consumer_service": "https://virtos.local/saml/acs",
    "single_logout_service": "https://virtos.local/saml/logout"
  },
  "attribute_mapping": {
    "email": "user.email",
    "name": "user.displayName",
    "groups": "user.groups"
  }
}
```

## Advanced Features

### Federated Identity Setup

**Enable SSO for AWS:**

```bash
virtos-federation identity-setup aws
```

Configures:

- SAML 2.0 trust relationship
- Attribute mapping (email, name, groups)
- Role federation (admin, operator, viewer)

**Result:**

- Log in once to VirtOS
- Access AWS console without re-auth
- Permissions synchronized

### Cross-Cloud Networking

**Create VPN between on-prem and AWS:**

```bash
virtos-federation network-setup on-prem aws
```

Establishes:

- Site-to-site VPN tunnel
- Unified IP addressing (10.0.0.0/8)
- Routing between networks
- Firewall rules

**Check connectivity:**

```bash
# From on-prem VM
ping 10.1.1.10  # AWS VM

# From AWS VM
ping 10.0.1.10  # On-prem VM
```

### Multi-Cloud Load Balancing

**Setup global load balancer:**

```bash
virtos-federation loadbalance-setup web-tier global \
  --providers on-prem,aws,azure \
  --algorithm geo-proximity \
  --health-check-interval 30
```

Behavior:

- Routes users to nearest provider
- Health checks every 30 seconds
- Automatic failover if provider down
- SSL termination and routing

**Example traffic flow:**

- User in New York → AWS us-east-1
- User in London → Azure westeurope
- User in Tokyo → GCP asia-northeast1

### Hybrid Orchestration

**Auto-burst configuration:**

```bash
virtos-federation hybrid-orchestrate \
  --on-prem-capacity 100 \
  --burst-provider aws \
  --burst-threshold 80 \
  --burst-instance-type t3.large \
  --burst-max-instances 10
```

Automated behavior:

1. Monitor on-prem CPU usage
2. If usage > 80%, launch AWS instance
3. Migrate workload to cloud
4. When usage < 60%, migrate back
5. Terminate cloud instance

**Cost awareness:**

- Only burst during actual load
- Prefer on-prem (already paid for)
- Cloud is overflow capacity

### Cost Optimization Reports

**Monthly cost analysis:**

```bash
virtos-federation cost-optimize --report monthly
```

Output:

```
VirtOS Federation Cost Report (May 2026)

Provider    VMs  vCPUs  RAM(GB)  Storage(GB)  Cost
----------- ---- ------ -------- ------------ ---------
On-Prem     45   180    720      12000        $0 (owned)
AWS         12   48     192      2400         $1,234.56
Azure       8    32     128      1600         $987.65
GCP         5    20     80       1000         $543.21
----------- ---- ------ -------- ------------ ---------
TOTAL       70   280    1120     17000        $2,765.42

Optimization Opportunities:
1. Move 3 dev VMs from Azure to GCP → Save $89/month
2. Use reserved instances in AWS → Save $247/month
3. Resize oversized VMs → Save $156/month

Total potential savings: $492/month (17.8%)
```

### VM Migration Between Clouds

**Migrate from on-prem to AWS:**

```bash
virtos-federation vm-migrate database-1 on-prem aws
```

5-phase migration:

1. **Snapshot** source VM (disk + config)
2. **Transfer** to target cloud (VPN/direct connect)
3. **Deploy** on target (format conversion, provisioning)
4. **Verify** (network, data integrity, app health)
5. **Cleanup** source (optional, manual confirmation)

**Live migration** (for clustered VMs):

```bash
virtos-federation vm-migrate web-3 on-prem aws --live
```

- Near-zero downtime
- Memory state transferred
- Automatic switchover

## Command Reference

### Federation Management

```bash
# Initialize federation
virtos-federation federation-init <name>

# View federation status
virtos-federation federation-status

# Interactive setup wizard
virtos-federation federation-wizard
```

### Provider Management

```bash
# Register provider
virtos-federation provider-register <name> <type> <endpoint> <key> <secret>

# List providers
virtos-federation provider-list

# Remove provider
virtos-federation provider-remove <name>
```

### VM Operations

```bash
# Deploy VM to cloud
virtos-federation vm-deploy <vm-name> <provider> [instance-type]

# Migrate VM between clouds
virtos-federation vm-migrate <vm-name> <source> <target>

# List federated VMs
virtos-federation vm-list
```

### Networking

```bash
# Setup cross-cloud network
virtos-federation network-setup <provider1> <provider2>

# Setup load balancer
virtos-federation loadbalance-setup <service> <providers>

# Network status
virtos-federation network-status
```

### Identity

```bash
# Setup federated identity
virtos-federation identity-setup <provider>

# Test SSO
virtos-federation identity-test <provider>
```

### Cost Optimization

```bash
# Analyze workload costs
virtos-federation cost-optimize --workload "<specs>"

# Monthly cost report
virtos-federation cost-optimize --report monthly

# Provider comparison
virtos-federation cost-optimize --compare
```

### Hybrid Orchestration

```bash
# Setup auto-burst
virtos-federation hybrid-orchestrate \
  --on-prem-capacity <count> \
  --burst-provider <provider> \
  --burst-threshold <percent>

# Orchestration status
virtos-federation hybrid-status
```

## TUI Access

All federation features available in the TUI:

```bash
virtos-tui
→ 23. Cloud Federation
```

**TUI Menu Options:**

1. Initialize Federation
2. Register Cloud Provider
3. Remove Cloud Provider
4. List Cloud Providers
5. Deploy VM to Cloud
6. Migrate VM Between Clouds
7. Setup Federated Identity
8. Setup Cross-Cloud Network
9. Setup Load Balancer
10. Hybrid Orchestration
11. Cost Optimization Report
12. Federation Status
13. Setup Wizard

## Architecture

### Federation Control Plane

```
┌──────────────────────────────────────────────┐
│     virtos-federation (Control Plane)        │
├──────────────────────────────────────────────┤
│                                              │
│  ┌────────────┐  ┌────────────┐             │
│  │  Provider  │  │  Identity  │             │
│  │  Registry  │  │  Manager   │             │
│  └────────────┘  └────────────┘             │
│                                              │
│  ┌────────────┐  ┌────────────┐             │
│  │  Network   │  │    Cost    │             │
│  │  Manager   │  │  Optimizer │             │
│  └────────────┘  └────────────┘             │
│                                              │
│  ┌────────────┐  ┌────────────┐             │
│  │    Load    │  │   Hybrid   │             │
│  │  Balancer  │  │ Orchestrat.│             │
│  └────────────┘  └────────────┘             │
└──────────────────────────────────────────────┘
         ↓              ↓              ↓
    ┌────────┐    ┌────────┐    ┌────────┐
    │On-Prem │    │  AWS   │    │ Azure  │
    └────────┘    └────────┘    └────────┘
```

### Data Flow

**VM Deployment:**

1. User: `virtos-federation vm-deploy myvm aws`
2. Federation validates provider
3. Federation selects region/instance type
4. Calls AWS API to provision EC2
5. Registers VM in federation DB
6. Configures VPN routing
7. Updates load balancer
8. Returns VM details

**Cross-Cloud Migration:**

1. Snapshot source VM
2. Transfer via VPN/direct connect
3. Convert disk format if needed
4. Provision on target cloud
5. Verify connectivity and health
6. Update DNS/load balancer
7. (Optional) Cleanup source

## Troubleshooting

### Provider Registration Fails

**Error:** "Failed to register provider: authentication failed"

**Cause:** Invalid credentials

**Fix:**

```bash
# Verify credentials
aws sts get-caller-identity  # For AWS
az account show              # For Azure
gcloud auth list             # For GCP

# Re-register with correct credentials
virtos-federation provider-remove aws
virtos-federation provider-register aws aws ec2.amazonaws.com CORRECT_KEY CORRECT_SECRET
```

### VPN Not Connecting

**Error:** "Cross-cloud network setup failed: VPN timeout"

**Cause:** Firewall blocking IPsec/IKE

**Fix:**

```bash
# Check firewall rules (on-prem)
iptables -L | grep -E "500|4500"

# Allow IPsec
iptables -A INPUT -p udp --dport 500 -j ACCEPT
iptables -A INPUT -p udp --dport 4500 -j ACCEPT

# Retry network setup
virtos-federation network-setup on-prem aws
```

### VM Migration Stalls

**Error:** "Migration stuck at 45%"

**Cause:** Slow network transfer

**Fix:**

```bash
# Check transfer speed
virtos-federation network-status

# Pause and resume
pkill -STOP virtos-federation
# Verify network connectivity
pkill -CONT virtos-federation
```

### Cost Report Shows $0 for Cloud

**Error:** Cost optimization shows $0 for AWS VMs

**Cause:** No cost data available (new provider)

**Fix:**

```bash
# Cost data collected hourly, wait 1-2 hours
# Or manually refresh
virtos-federation cost-optimize --refresh

# Verify provider billing API access
aws ce get-cost-and-usage --time-period Start=2026-05-01,End=2026-05-31 --granularity MONTHLY --metrics BlendedCost
```

## Security Considerations

### Credential Storage

**Provider credentials** stored encrypted:

- Location: `/var/lib/virtos/federation/providers/*.provider`
- Secrets redacted in JSON
- Actual keys stored in secure keyring
- Use IAM roles when possible (cloud-native auth)

### Network Security

**VPN encryption:**

- IPsec with AES-256
- Perfect forward secrecy (PFS)
- Regular key rotation

**Firewall rules:**

- Minimal ports opened (500, 4500 for IPsec)
- Source IP whitelisting
- Cloud security groups configured

### Identity Security

**SSO security:**

- SAML assertions signed and encrypted
- Token expiration (1 hour default)
- Multi-factor authentication supported
- Audit logging of all logins

## Performance

### Expected Latency

**Cross-cloud communication:**

- On-prem ↔ AWS (us-east-1): 10-20ms
- On-prem ↔ Azure (eastus): 15-25ms
- On-prem ↔ GCP (us-central1): 20-30ms
- AWS ↔ Azure: 30-50ms
- AWS ↔ GCP: 40-60ms

**Migration speeds:**

- On-prem → AWS: 100-500 Mbps (depends on uplink)
- AWS → Azure: 500-1000 Mbps (cloud peering)
- Within region: 1-10 Gbps

### Scaling

**Federation limits:**

- Providers: Unlimited (tested up to 50)
- Federated VMs: 10,000+ per federation
- VPN tunnels: 100+ concurrent
- Load balancer backends: 1,000+ per service

## Best Practices

### 1. Start Small

```bash
# Begin with 2 providers
virtos-federation federation-init test-fed
virtos-federation provider-register aws aws ec2.amazonaws.com KEY SECRET

# Test with non-critical VMs
virtos-federation vm-deploy test-vm-1 aws t3.micro

# Verify networking
ping <vm-ip>
ssh <vm-ip>

# Scale up after validation
```

### 2. Cost Awareness

- Use cost reports monthly
- Set budget alerts
- Prefer on-prem for steady workloads
- Use cloud for burst/peak loads
- Reserved instances for predictable cloud workloads

### 3. Network Planning

- Plan IP address ranges (avoid overlap)
- Use /16 or /24 per provider
- Document subnet assignments
- Test VPN before production

### 4. Identity Management

- Enable SSO early
- Map roles consistently
- Use groups for permissions
- Audit access regularly

### 5. Disaster Recovery

- Replicate critical VMs to cloud
- Test failover quarterly
- Document runbooks
- Monitor replication lag

## Examples Repository

See **[VirtOS-Examples](https://github.com/FlossWare/VirtOS-Examples)** for:

- Multi-cloud web app example
- Hybrid Kubernetes cluster
- DR failover demo
- Cost optimization scripts

## Related Documentation

- [CLUSTERING.md](CLUSTERING.md) - On-premises multi-host clustering
- [MULTICLOUD.md](MULTICLOUD.md) - Multi-cloud strategies
- [NETWORKING.md](NETWORKING.md) - Network virtualization
- [IAAS.md](IAAS.md) - Infrastructure as a Service features
- [DR.md](DR.md) - Disaster recovery planning

## Getting Help

- Command help: `virtos-federation --help`
- Interactive wizard: `virtos-federation federation-wizard`
- TUI: `virtos-tui → Cloud Federation`
- Issues: <https://github.com/FlossWare/VirtOS/issues>
- Discussions: <https://github.com/FlossWare/VirtOS/discussions>

---

**Federation brings the power of multi-cloud to VirtOS - one interface for all your infrastructure.**
