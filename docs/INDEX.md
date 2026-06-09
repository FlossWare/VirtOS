# VirtOS Documentation Index

Complete documentation for FlossWare VirtOS.

## Quick Start

- **[README.md](../README.md)** - Project overview and quick start
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Command cheat sheet

## Business & Planning

See [CLAUDE.md](../CLAUDE.md) for business context and project status.

## Core Documentation

### System Design

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - 7-layer system design and components
- **[SCRIPT-DEPENDENCIES.md](SCRIPT-DEPENDENCIES.md)** - Script-to-script dependencies and initialization order
- **[DEPENDENCIES.md](DEPENDENCIES.md)** - External command dependencies
- **[PACKAGES.md](PACKAGES.md)** - Required packages and size estimates
- **[TCZ_PACKAGES.md](TCZ_PACKAGES.md)** - Complete TCZ package strategy and profile breakdown

### Configuration

- **[CONFIGURATION.md](CONFIGURATION.md)** - 30+ configuration options
- **[BUILD-CONFIGURATOR.md](BUILD-CONFIGURATOR.md)** - Interactive TUI for build configuration
- **[BUILD.md](BUILD.md)** - Build system documentation and procedures
- **[PROFILES.md](PROFILES.md)** - 7 build profiles comparison
- **[STORAGE.md](STORAGE.md)** - Storage options and filesystems

## Virtualization Technologies

### VMs and Containers

- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Cloud-init, container, and microservice examples

## Multi-Host Features

- **[CLUSTERING.md](CLUSTERING.md)** - Multi-host discovery and coordination
- **[IAAS.md](IAAS.md)** - Automated VM placement and scheduling
- **[REMOTE-ACCESS.md](REMOTE-ACCESS.md)** - virt-manager and SSH setup
- **[LIBVIRT-PERMISSIONS.md](LIBVIRT-PERMISSIONS.md)** - Libvirt authentication and permissions configuration
- **[API_REFERENCE.md](API_REFERENCE.md)** - Complete REST API v1 documentation (all endpoints, examples, security)
- **[COCKPIT-MODULE.md](COCKPIT-MODULE.md)** - Cockpit web UI module design

## User Interface

- **[TUI.md](TUI.md)** - Text user interface (ncurses setup wizard and management console)
- **[TUI_TECHNOLOGY.md](TUI_TECHNOLOGY.md)** - Why VirtOS uses dialog vs platform-java using Lanterna
- **[WEB-UI.md](WEB-UI.md)** - Web-based management interface (Cockpit integration)

## Reference

- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - All commands in one place
- **[QUICK-START.md](QUICK-START.md)** - Fast-track getting started guide
- **[EXPERIMENTAL_FEATURES.md](EXPERIMENTAL_FEATURES.md)** - Experimental vs functional scripts (comprehensive guide)
- **[EXAMPLES-INTEGRATION.md](EXAMPLES-INTEGRATION.md)** - VirtOS-Examples repository integration plan
- **[EXAMPLES.md](EXAMPLES.md)** - Example configurations and use cases
- **[PLATFORM-JAVA_INTEGRATION.md](PLATFORM-JAVA_INTEGRATION.md)** - platform-java integration and workload orchestration
- **[COMMUNITY.md](COMMUNITY.md)** - Community resources, discussions, support channels
- **[CONTRIBUTING.md](../CONTRIBUTING.md)** - How to contribute
- **[CODING_STANDARDS.md](CODING_STANDARDS.md)** - Official coding standards (shell, security, testing, git)
- **[PLUGIN_API.md](PLUGIN_API.md)** - Plugin development guide (templates, security, packaging)

## Operations & Security

- **[AUDIT_LOGGING.md](AUDIT_LOGGING.md)** - Audit logging guide (compliance, security, troubleshooting)
- **[SECURITY-HARDENING.md](SECURITY-HARDENING.md)** - Security best practices and hardening guide
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Complete troubleshooting (CLI, TUI, Web UI, API)
- **[MONITORING-SETUP.md](MONITORING-SETUP.md)** - System monitoring configuration and setup
- **[DR-PROCEDURES.md](DR-PROCEDURES.md)** - Disaster recovery procedures and planning
- **[UPGRADE-PROCEDURES.md](UPGRADE-PROCEDURES.md)** - System upgrade and update procedures
- **[INSTALLATION.md](INSTALLATION.md)** - Installation guide and requirements
- **[ROLLBACK.md](ROLLBACK.md)** - Rollback procedures for failed deployments
- **[PRE_COMMIT_HOOKS.md](PRE_COMMIT_HOOKS.md)** - Pre-commit hook setup and configuration

## Testing & Quality

- **[TESTING.md](../TESTING.md)** - Testing guide and framework
- See [CLAUDE.md](../CLAUDE.md) for testing roadmap and validation evidence

## Documentation by Use Case

### I want to

#### Build VirtOS

1. [README.md](../README.md) - Initial setup and build instructions
2. [PROFILES.md](PROFILES.md) - Choose a profile
3. [CONFIGURATION.md](CONFIGURATION.md) - Customize build

#### Run Virtual Machines

1. [README.md](../README.md) - Boot VirtOS
2. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - KVM/QEMU commands
3. [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - Use virt-manager
4. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Backup, templates, snapshots

#### Run Containers

1. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Container and container orchestration commands

#### Set Up Multiple Hosts

1. [CLUSTERING.md](CLUSTERING.md) - Multi-host setup
2. [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - Remote management
3. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - K3s cluster commands

#### Manage Remotely

1. [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - SSH and virt-manager setup
2. [CLUSTERING.md](CLUSTERING.md) - virtos-cluster commands
3. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - All commands

#### Deploy Microservices

1. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Container and microservice deployment commands
2. [CLUSTERING.md](CLUSTERING.md) - Set up cluster
3. [PLATFORM-JAVA_INTEGRATION.md](PLATFORM-JAVA_INTEGRATION.md) - Platform-java workload orchestration

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
