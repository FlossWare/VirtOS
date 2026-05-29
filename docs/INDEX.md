# VirtOS Documentation Index

Complete documentation for FlossWare VirtOS.

## Quick Start

- **[README.md](../README.md)** - Project overview and quick start
- **[GETTING-STARTED.md](GETTING-STARTED.md)** - Build your first VirtOS ISO
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Command cheat sheet

## Business & Planning

- **[EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md)** - One-page overview for decision makers
- **[BUSINESS_CASE.md](BUSINESS_CASE.md)** - Complete ROI analysis and cost savings
  - Cost scenarios (10/50/200 hosts)
  - 5-year TCO comparison vs VMware/Proxmox/Hyper-V
  - Time savings analysis (308-358 hours/year)
  - Elevator pitches (30s/60s/90s)
  - Target markets and use cases
  - Risk mitigation strategies
  - Implementation roadmap

## Core Documentation

### System Design

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - 7-layer system design and components
- **[AI-ARCHITECTURE.md](AI-ARCHITECTURE.md)** - AI capabilities split (VirtOS vs platform-java)
- **[AI-MODULARITY.md](AI-MODULARITY.md)** - Modular AI design (optional packages, profiles)
- **[SCRIPT-DEPENDENCIES.md](SCRIPT-DEPENDENCIES.md)** - Script-to-script dependencies and initialization order
- **[DEPENDENCIES.md](DEPENDENCIES.md)** - External command dependencies
- **[PACKAGES.md](PACKAGES.md)** - Required packages and size estimates
- **[TCZ_PACKAGES.md](TCZ_PACKAGES.md)** - Complete TCZ package strategy and profile breakdown
- **[ROADMAP.md](ROADMAP.md)** - Development phases and status

### Configuration

- **[CONFIGURATION.md](CONFIGURATION.md)** - 30+ configuration options
- **[BUILD-CONFIGURATOR.md](BUILD-CONFIGURATOR.md)** - Interactive TUI for build configuration
- **[BUILD.md](BUILD.md)** - Build system documentation and procedures
- **[BUILD_DEPENDENCIES.md](BUILD_DEPENDENCIES.md)** - Build-time dependency tracking
- **[PROFILES.md](PROFILES.md)** - 7 build profiles comparison
- **[BRANDING.md](BRANDING.md)** - VirtOS naming and branding
- **[STORAGE.md](STORAGE.md)** - Storage options and filesystems

## Virtualization Technologies

### VMs and Containers

- **[CLOUD-INIT.md](CLOUD-INIT.md)** - Automated VM configuration on first boot ☁️
- **[CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md)** - Docker vs Podman vs containerd
- **[KUBERNETES.md](KUBERNETES.md)** - K3s orchestration (optional)
- **[MICROSERVICES.md](MICROSERVICES.md)** - Deploying microservices on VirtOS

## Multi-Host Features

- **[CLUSTERING.md](CLUSTERING.md)** - Multi-host discovery and coordination
- **[IAAS.md](IAAS.md)** - Automated VM placement and scheduling
- **[REMOTE-ACCESS.md](REMOTE-ACCESS.md)** - virt-manager and SSH setup
- **[LIBVIRT-PERMISSIONS.md](LIBVIRT-PERMISSIONS.md)** - Libvirt authentication and permissions configuration
- **[API.md](API.md)** - REST API reference (virtos-api endpoints)
- **[API_REFERENCE.md](API_REFERENCE.md)** - ⭐ NEW: Complete REST API v1 documentation (all endpoints, examples, security)
- **[API_VERSIONING.md](API_VERSIONING.md)** - API versioning strategy and backward compatibility
- **[FEDERATION.md](FEDERATION.md)** - Multi-cloud federation and cross-cluster management
- **[COCKPIT-MODULE.md](COCKPIT-MODULE.md)** - Cockpit web UI module design

## User Interface

- **[TUI.md](TUI.md)** - Text user interface (ncurses setup wizard and management console)
- **[TUI_TECHNOLOGY.md](TUI_TECHNOLOGY.md)** - Why VirtOS uses dialog vs platform-java using Lanterna
- **[WEB-UI.md](WEB-UI.md)** - Web-based management interface (Cockpit integration)

## Reference

- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - All commands in one place
- **[QUICK-START.md](QUICK-START.md)** - Fast-track getting started guide
- **[COMPARISON.md](COMPARISON.md)** - VirtOS vs similar projects (Proxmox, ESXi, etc.)
- **[MISSING-FEATURES.md](MISSING-FEATURES.md)** - What VirtOS lacks (honest assessment)
- **[EXPERIMENTAL_FEATURES.md](EXPERIMENTAL_FEATURES.md)** - ⭐ NEW: Experimental vs functional scripts (comprehensive guide)
- **[EXPERIMENTAL.md](EXPERIMENTAL.md)** - Research prototypes explained (AI, quantum, blockchain, etc.)
- **[EXAMPLES-INTEGRATION.md](EXAMPLES-INTEGRATION.md)** - VirtOS-Examples repository integration plan
- **[EXAMPLES.md](EXAMPLES.md)** - Example configurations and use cases
- **[PLATFORM-JAVA_INTEGRATION.md](PLATFORM-JAVA_INTEGRATION.md)** - platform-java integration and workload orchestration
- **[MIGRATION-FROM-PROXMOX.md](MIGRATION-FROM-PROXMOX.md)** - Migration guide from Proxmox VE
- **[COMMUNITY.md](COMMUNITY.md)** - ⭐ NEW: Community resources, discussions, support channels
- **[CONTRIBUTING.md](../CONTRIBUTING.md)** - How to contribute
- **[CODING_STANDARDS.md](CODING_STANDARDS.md)** - ⭐ NEW: Official coding standards (shell, security, testing, git)
- **[DEPRECATION_POLICY.md](DEPRECATION_POLICY.md)** - ⭐ NEW: Official deprecation policy (6-month timeline, semver)
- **[PLUGIN_API.md](PLUGIN_API.md)** - ⭐ NEW: Plugin development guide (templates, security, packaging)
- **[VERSIONING.md](VERSIONING.md)** - Version numbering and release strategy

## Operations & Security

- **[AUDIT_LOGGING.md](AUDIT_LOGGING.md)** - ⭐ NEW: Audit logging guide (compliance, security, troubleshooting)
- **[SECURITY-HARDENING.md](SECURITY-HARDENING.md)** - Security best practices and hardening guide
- **[SECURITY_HARDENING.md](SECURITY_HARDENING.md)** - Alternative security hardening reference (same content, different filename)
- **[SECURITY_ENHANCEMENTS_SUMMARY.md](SECURITY_ENHANCEMENTS_SUMMARY.md)** - ⭐ NEW: Security improvements summary (Issue #116)
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - ⭐ ENHANCED: Complete troubleshooting (CLI, TUI, Web UI, API)
- **[MONITORING-SETUP.md](MONITORING-SETUP.md)** - System monitoring configuration and setup
- **[DR-PROCEDURES.md](DR-PROCEDURES.md)** - Disaster recovery procedures and planning
- **[UPGRADE-PROCEDURES.md](UPGRADE-PROCEDURES.md)** - System upgrade and update procedures
- **[INSTALLATION.md](INSTALLATION.md)** - Installation guide and requirements
- **[ROLLBACK.md](ROLLBACK.md)** - Rollback procedures for failed deployments
- **[PRE_COMMIT_HOOKS.md](PRE_COMMIT_HOOKS.md)** - Pre-commit hook setup and configuration

## Testing & Quality

- **[TESTING_ROADMAP.md](../TESTING_ROADMAP.md)** - ⭐ NEW: Three-phase testing execution plan
- **[ISO_TESTING_STATUS.md](../ISO_TESTING_STATUS.md)** - ISO validation checklist (47 tests)
- **[RUNTIME_TESTING_PLAN.md](../RUNTIME_TESTING_PLAN.md)** - Runtime testing procedures
- **[TESTING.md](../TESTING.md)** - Testing guide
- **[TESTING_METRICS.md](TESTING_METRICS.md)** - Test metrics

## Roadmap & Planning

- **[ROADMAP.md](ROADMAP.md)** - Development phases and status (already listed above in System Design)
- **[ROADMAP-v1.0.md](ROADMAP-v1.0.md)** - Detailed v1.0 release planning
- **[V1_0_ROADMAP.md](V1_0_ROADMAP.md)** - Alternative v1.0 roadmap document

## Documentation by Use Case

### I want to

#### Build VirtOS

1. [GETTING-STARTED.md](GETTING-STARTED.md) - Initial setup
2. [PROFILES.md](PROFILES.md) - Choose a profile
3. [CONFIGURATION.md](CONFIGURATION.md) - Customize build

#### Run Virtual Machines

1. [GETTING-STARTED.md](GETTING-STARTED.md) - Boot VirtOS
2. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - KVM/QEMU commands
3. [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - Use virt-manager
4. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Backup, templates, snapshots

#### Run Containers

1. [CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md) - Choose runtime
2. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Container commands
3. [KUBERNETES.md](KUBERNETES.md) - Add orchestration (optional)

#### Set Up Multiple Hosts

1. [CLUSTERING.md](CLUSTERING.md) - Multi-host setup
2. [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - Remote management
3. [KUBERNETES.md](KUBERNETES.md) - K3s cluster (optional)

#### Manage Remotely

1. [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - SSH and virt-manager setup
2. [CLUSTERING.md](CLUSTERING.md) - virtos-cluster commands
3. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - All commands

#### Deploy Microservices

1. [MICROSERVICES.md](MICROSERVICES.md) - Complete microservices guide
2. [CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md) - Choose runtime
3. [CLUSTERING.md](CLUSTERING.md) - Set up cluster
4. [KUBERNETES.md](KUBERNETES.md) - Deploy with K3s

#### Use IaaS Automation

1. [CLUSTERING.md](CLUSTERING.md) - Set up multi-host cluster
2. [IAAS.md](IAAS.md) - Enable automated placement
3. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - virtos-create-vm commands

#### Configure VirtOS (First Boot)

1. [TUI.md](TUI.md) - Run virtos-setup wizard
2. [STORAGE.md](STORAGE.md) - Choose filesystem (if advanced storage)
3. [CLUSTERING.md](CLUSTERING.md) - Join cluster (if multi-host)

#### Manage VirtOS (Daily)

1. [TUI.md](TUI.md) - Use virtos-tui management console
2. [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - SSH access
3. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - CLI commands

#### Configure Advanced Storage

1. [STORAGE.md](STORAGE.md) - Choose filesystem (Btrfs/LVM/ZFS)
2. [PROFILES.md](PROFILES.md) - Use storage profile
3. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Storage commands

#### Backup and Protect VMs

1. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - virtos-backup commands
2. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - virtos-snapshot commands
3. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - virtos-template commands

## Documentation by Profile

### Minimal Profile

- [PROFILES.md](PROFILES.md#minimal-profile)
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - KVM commands
- Minimal docs needed - it's simple!

### Standard Profile (Default)

- [PROFILES.md](PROFILES.md#standard-profile-default)
- [CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md) - All 3 runtimes
- [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - libvirt management

### Full Profile

- [PROFILES.md](PROFILES.md#full-profile)
- All documentation applies!

### Containers Profile

- [PROFILES.md](PROFILES.md#containers-profile)
- [CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md)
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Container commands

### Developer Profile

- [PROFILES.md](PROFILES.md#developer-profile)
- [CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md)
- [KUBERNETES.md](KUBERNETES.md)

### Kubernetes Profile

- [PROFILES.md](PROFILES.md#kubernetes-profile)
- [KUBERNETES.md](KUBERNETES.md) - Complete K3s guide
- [CLUSTERING.md](CLUSTERING.md) - Multi-node setup

### Storage Profile

- [PROFILES.md](PROFILES.md#storage-profile)
- [STORAGE.md](STORAGE.md) - Complete storage guide
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Storage commands

## Feature Matrix

| Feature | Documentation |
|---------|---------------|
| KVM/QEMU VMs | QUICK-REFERENCE.md, GETTING-STARTED.md |
| LXC Containers | QUICK-REFERENCE.md |
| Docker | CONTAINER-RUNTIMES.md, QUICK-REFERENCE.md |
| Podman | CONTAINER-RUNTIMES.md, QUICK-REFERENCE.md |
| containerd | CONTAINER-RUNTIMES.md, QUICK-REFERENCE.md |
| K3s/Kubernetes | KUBERNETES.md |
| Microservices | MICROSERVICES.md |
| libvirt | REMOTE-ACCESS.md, QUICK-REFERENCE.md |
| virt-manager | REMOTE-ACCESS.md |
| Clustering | CLUSTERING.md |
| IaaS Placement | IAAS.md |
| Remote Access | REMOTE-ACCESS.md |
| Storage (Btrfs/LVM/ZFS/NFS) | STORAGE.md, QUICK-REFERENCE.md |
| Text UI (ncurses) | TUI.md |
| Build Profiles | PROFILES.md |
| Configuration | CONFIGURATION.md |
| Backup & Restore | QUICK-REFERENCE.md (virtos-backup) |
| VM Templates | QUICK-REFERENCE.md (virtos-template) |
| Snapshots | QUICK-REFERENCE.md (virtos-snapshot) |
| Monitoring & Alerts | QUICK-REFERENCE.md (virtos-monitor) |
| High Availability | QUICK-REFERENCE.md (virtos-ha) |
| Live Migration | QUICK-REFERENCE.md (virtos-migrate) |
| Resource Quotas | QUICK-REFERENCE.md (virtos-quota) |
| Authentication/RBAC | QUICK-REFERENCE.md (virtos-auth) |
| Cloud-init | QUICK-REFERENCE.md (virtos-cloud-init) |
| REST API | QUICK-REFERENCE.md (virtos-api) |
| System Updates | QUICK-REFERENCE.md (virtos-update) |
| Disaster Recovery | QUICK-REFERENCE.md (virtos-dr) |
| Distributed Storage | QUICK-REFERENCE.md (virtos-storage) |
| Network Virtualization | QUICK-REFERENCE.md (virtos-network) |
| GPU Passthrough | QUICK-REFERENCE.md (virtos-gpu) |
| USB Device Management | QUICK-REFERENCE.md (virtos-usb) |
| Metrics & Telemetry | QUICK-REFERENCE.md (virtos-telemetry) |
| Security Hardening | QUICK-REFERENCE.md (virtos-security) |
| Billing & Cost Tracking | QUICK-REFERENCE.md (virtos-billing) |
| Service Mesh | QUICK-REFERENCE.md (virtos-mesh) |
| Multi-Datacenter | QUICK-REFERENCE.md (virtos-datacenter) |
| Analytics & Reporting | QUICK-REFERENCE.md (virtos-analytics) |
| Edge Computing | QUICK-REFERENCE.md (virtos-edge) |
| Automation & Orchestration | QUICK-REFERENCE.md (virtos-automation) |
| AI Optimization | QUICK-REFERENCE.md (virtos-ai) |
| Quantum Computing | QUICK-REFERENCE.md (virtos-quantum) |
| Blockchain Auditing | QUICK-REFERENCE.md (virtos-blockchain) |
| Cloud Federation | QUICK-REFERENCE.md (virtos-federation) |
| Advanced AI | QUICK-REFERENCE.md (virtos-ai-advanced) |
| Quantum Hardware | QUICK-REFERENCE.md (virtos-quantum-hardware) |
| Blockchain DeFi | QUICK-REFERENCE.md (virtos-blockchain-advanced) |
| Extended Federation | QUICK-REFERENCE.md (virtos-federation-extended) |
| Advanced Security | QUICK-REFERENCE.md (virtos-security-advanced) |
| Performance Optimization | QUICK-REFERENCE.md (virtos-performance) |
| Observability | QUICK-REFERENCE.md (virtos-observability) |
| Advanced DR | QUICK-REFERENCE.md (virtos-dr-advanced) |
| Web UI | QUICK-REFERENCE.md (virtos-web) |
| DevOps Integration | QUICK-REFERENCE.md (virtos-devops) |
| Directory Services | QUICK-REFERENCE.md (virtos-directory) |
| Governance & Policy | QUICK-REFERENCE.md (virtos-governance) |
| Site Reliability (SRE) | QUICK-REFERENCE.md (virtos-sre) |
| Multi-Cloud Management | QUICK-REFERENCE.md (virtos-multicloud) |
| Advanced Networking | QUICK-REFERENCE.md (virtos-networking-advanced) |
| Application Performance (APM) | QUICK-REFERENCE.md (virtos-apm) |

## Total Documentation

- **80+ Documentation Files** (including business case, technical guides, operations, security, development)
- **40,000+ Lines** of comprehensive documentation
- **Complete and Honest Coverage** - including what's missing
- **Business Value Analysis** - ROI, cost savings, competitive comparison
- **Recent Additions** (May 2026):
  - ⭐ Coding Standards (791 lines) - Official shell scripting standards
  - ⭐ API Reference (554 lines) - Complete REST API v1 documentation
  - ⭐ Plugin API Guide (742 lines) - Third-party extension development
  - ⭐ Deprecation Policy (381 lines) - Official feature lifecycle policy
  - ⭐ Troubleshooting enhancements (~450 lines) - Web UI & API sections
  - ⭐ Pre-commit Hooks Guide - Development workflow automation
  - ⭐ API Versioning - Backward compatibility strategy
  - ⭐ Rollback Procedures - Deployment safety
  - Experimental features guide (600+ lines)
  - Audit logging guide (800+ lines)
  - Testing roadmap (1,100+ lines)

## Getting Help

1. Check relevant documentation above
2. See [QUICK-REFERENCE.md](QUICK-REFERENCE.md) for commands
3. Review [ROADMAP.md](ROADMAP.md) for feature status
4. Open issue: <https://github.com/FlossWare/VirtOS/issues>

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for:

- How to contribute code
- Documentation improvements
- Bug reports
- Feature requests
