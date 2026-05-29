# VirtOS Examples Integration Plan

**Last Updated**: 2026-05-29  
**Version: 0.89  
**Status**: Integration Plan (Not Yet Implemented)

## Overview

Plan to integrate the VirtOS-Examples repository into the main VirtOS repository as an `examples/` directory for better user experience and maintainability.

## Current State

**VirtOS-Examples Repository**: https://github.com/FlossWare/VirtOS-Examples

**Status**: Active, separate repository  
**Purpose**: Ready-to-deploy examples and templates for VirtOS

**Current Content**:
- platform-java workload examples
- Multi-tier application examples
- Microservices deployments
- Kubernetes examples
- API Gateway patterns
- Observability stacks

**Problem**: Examples are separated from main codebase, causing:
- Version synchronization issues
- Difficulty discovering examples
- No automated testing of examples
- Extra clone step for users
- Examples may drift out of sync with VirtOS changes

## Benefits of Integration

### 1. User Experience Improvements

**Before** (Separate Repository):
```bash
# User must clone two repositories
git clone https://github.com/FlossWare/VirtOS.git
git clone https://github.com/FlossWare/VirtOS-Examples.git

# Navigate between repos
cd VirtOS-Examples
# Run example
cd ../VirtOS
# Back to main code
```

**After** (Integrated):
```bash
# Single clone
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS

# Examples right there
ls examples/
# 01-quickstart/ 02-platform-java/ 03-networking/ ...

# Run example
cd examples/01-quickstart
./first-vm.sh
```

**Benefits**:
- ✅ Single clone includes everything
- ✅ Examples versioned with VirtOS
- ✅ No confusion about compatibility
- ✅ Simpler getting-started experience

### 2. Development Workflow

**Before**:
- Update VirtOS API → Examples break
- No automated detection of broken examples
- Manual sync between repositories
- Examples may lag behind features

**After**:
- Examples tested in CI pipeline
- Breaking changes caught immediately
- Examples stay in sync automatically
- Examples updated with features

**Benefits**:
- ✅ Examples validate API changes
- ✅ CI catches broken examples
- ✅ Examples always compatible
- ✅ Examples serve as integration tests

### 3. Documentation Integration

**Before**:
- Examples in separate repo
- Docs link to external repository
- Examples hard to discover
- No inline examples in docs

**After**:
- Examples inline with documentation
- Docs can reference `examples/` directly
- Better discoverability
- Code and examples co-located

**Benefits**:
- ✅ Better documentation
- ✅ Easier to find relevant examples
- ✅ Examples complement docs
- ✅ Improved learning experience

### 4. Testing & Quality

**Before**:
- No automated example validation
- Examples may be outdated
- No syntax checking
- Manual testing only

**After**:
- Automated syntax validation
- YAML linting
- Integration test suite
- Examples as test fixtures

**Benefits**:
- ✅ Examples always work
- ✅ CI validates examples
- ✅ Higher quality examples
- ✅ Examples double as tests

## Proposed Directory Structure

```
VirtOS/
├── examples/                              # ← NEW: Integrated examples
│   ├── README.md                         # Examples overview and index
│   │
│   ├── 01-quickstart/                    # Getting started examples
│   │   ├── README.md                     # Quick start guide
│   │   ├── first-vm.sh                   # Create your first VM
│   │   ├── basic-network.sh              # Network setup
│   │   ├── simple-storage.sh             # Storage pool creation
│   │   └── vm-lifecycle.sh               # Full VM lifecycle
│   │
│   ├── 02-platform-java/                 # platform-java examples
│   │   ├── README.md                     # platform-java overview
│   │   ├── simple-webapp/                # Single-tier webapp
│   │   │   ├── webapp.yaml
│   │   │   └── deploy.sh
│   │   ├── multi-tier/                   # Three-tier application
│   │   │   ├── README.md
│   │   │   ├── 1-database-tier.yaml      # PostgreSQL VM
│   │   │   ├── 2-app-tier.yaml           # Spring Boot app
│   │   │   ├── 3-web-tier.yaml           # NGINX container
│   │   │   ├── deploy.sh                 # Deploy all tiers
│   │   │   └── test.sh                   # Integration test
│   │   └── microservices/                # Microservices example
│   │       ├── README.md
│   │       ├── service-a.yaml
│   │       ├── service-b.yaml
│   │       ├── api-gateway.yaml
│   │       └── deploy-all.sh
│   │
│   ├── 03-networking/                    # Networking examples
│   │   ├── README.md                     # Networking guide
│   │   ├── bridge-setup.sh               # Create virtual bridge
│   │   ├── nat-network.sh                # NAT network configuration
│   │   ├── vlan-config.sh                # VLAN setup
│   │   ├── firewall-rules.sh             # Per-VM firewall
│   │   └── multi-host-network.sh         # Cluster networking
│   │
│   ├── 04-storage/                       # Storage examples
│   │   ├── README.md                     # Storage guide
│   │   ├── lvm-pool.sh                   # LVM storage pool
│   │   ├── btrfs-pool.sh                 # Btrfs storage pool
│   │   ├── zfs-pool.sh                   # ZFS storage pool (8GB+ RAM)
│   │   ├── nfs-storage.sh                # NFS client setup
│   │   └── distributed-storage.sh        # Ceph/GlusterFS
│   │
│   ├── 05-ha-dr/                         # High Availability & DR
│   │   ├── README.md                     # HA/DR guide
│   │   ├── ha-cluster.sh                 # HA cluster setup
│   │   ├── dr-backup.sh                  # Disaster recovery backup
│   │   ├── failover-test.sh              # Test failover
│   │   ├── live-migration.sh             # Live VM migration
│   │   └── snapshot-schedule.sh          # Automated snapshots
│   │
│   ├── 06-monitoring/                    # Monitoring & Observability
│   │   ├── README.md                     # Monitoring guide
│   │   ├── prometheus-setup.sh           # Prometheus deployment
│   │   ├── grafana-setup.sh              # Grafana deployment
│   │   ├── dashboards/                   # Grafana dashboards
│   │   │   ├── vm-metrics.json
│   │   │   └── cluster-overview.json
│   │   └── alerting-rules.yaml           # Alert definitions
│   │
│   ├── 07-advanced/                      # Advanced features
│   │   ├── README.md                     # Advanced guide
│   │   ├── gpu-passthrough.sh            # GPU passthrough setup
│   │   ├── sr-iov.sh                     # SR-IOV networking
│   │   ├── custom-templates/             # VM templates
│   │   │   ├── ubuntu-template.sh
│   │   │   ├── centos-template.sh
│   │   │   └── windows-template.sh
│   │   ├── cloud-init-examples/          # Cloud-init configs
│   │   │   ├── web-server.yaml
│   │   │   ├── k8s-node.yaml
│   │   │   └── database.yaml
│   │   └── automation/                   # Automation examples
│   │       ├── ansible-playbooks/
│   │       └── terraform/
│   │
│   └── 08-testing/                       # Test examples (for CI)
│       ├── README.md                     # Testing guide
│       ├── integration/                  # Integration tests
│       │   ├── vm-lifecycle-test.sh
│       │   ├── network-test.sh
│       │   └── storage-test.sh
│       └── fixtures/                     # Test fixtures
│           ├── test-vm.yaml
│           └── test-workload.yaml
│
├── packages/                             # Existing structure
├── build/
├── config/
├── docs/
└── tests/
```

## Migration Process

### Phase 1: Preparation (Week 1)

**Tasks**:
1. Clone VirtOS-Examples repository locally
2. Audit all examples for:
   - Compatibility with current VirtOS (0.87)
   - Outdated references (already completed: jplatform → platform-java)
   - Missing documentation
   - Broken scripts
3. Categorize examples into 8 categories
4. Create migration mapping document

**Deliverables**:
- [ ] Local clone of VirtOS-Examples
- [ ] Example audit report
- [ ] Category mapping
- [ ] Migration checklist

### Phase 2: Directory Setup (Week 2, Days 1-2)

**Tasks**:
1. Create `examples/` directory structure
2. Create category README.md files
3. Set up .gitignore rules for examples/
4. Create main examples/README.md

**Commands**:
```bash
cd VirtOS

# Create directory structure
mkdir -p examples/{01-quickstart,02-platform-java,03-networking,04-storage,05-ha-dr,06-monitoring,07-advanced,08-testing}

# Create README templates
for dir in examples/*/; do
  cat > "$dir/README.md" <<EOF
# $(basename $dir)

Examples for $(basename $dir | sed 's/^[0-9]*-//' | tr '-' ' ')

## Overview

## Examples

## Usage

## Related Documentation
EOF
done
```

**Deliverables**:
- [ ] examples/ directory created
- [ ] All 8 category directories
- [ ] README.md templates
- [ ] .gitignore updated

### Phase 3: Content Migration (Week 2, Days 3-5)

**Tasks**:
1. Copy examples from VirtOS-Examples
2. Reorganize into new structure
3. Update all references:
   - Paths to match new structure
   - Version numbers
   - (Note: jplatform → platform-java already completed)
4. Add missing documentation
5. Update scripts for consistency

**Example Migration**:
```bash
# From VirtOS-Examples
examples/multi-tier/three-tier-webapp/
├── 1-database-tier.yaml
├── 2-app-tier.yaml
└── 3-web-tier.yaml

# To VirtOS
examples/02-platform-java/multi-tier/
├── README.md                    # NEW
├── 1-database-tier.yaml         # Updated
├── 2-app-tier.yaml              # Updated
├── 3-web-tier.yaml              # Updated
├── deploy.sh                    # NEW - Convenience script
└── test.sh                      # NEW - Test script
```

**Deliverables**:
- [ ] All examples migrated
- [ ] References updated
- [ ] Documentation added
- [ ] Helper scripts created

### Phase 4: Validation (Week 3, Days 1-3)

**Tasks**:
1. Test each example manually
2. Add syntax validation to CI
3. Add YAML linting to CI
4. Create example test suite
5. Document how to run examples

**CI Integration** (.github/workflows/examples.yml):
```yaml
name: Validate Examples

on:
  push:
    paths:
      - 'examples/**'
  pull_request:
    paths:
      - 'examples/**'

jobs:
  validate-syntax:
    name: Validate Shell Scripts
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Validate Bash syntax
        run: |
          find examples -name "*.sh" -type f | while read script; do
            echo "Checking $script..."
            bash -n "$script" || exit 1
          done
      
      - name: Run shellcheck
        run: |
          sudo apt-get install -y shellcheck
          find examples -name "*.sh" -type f -exec shellcheck {} +
  
  validate-yaml:
    name: Validate YAML Files
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Install yamllint
        run: pip install yamllint
      
      - name: Validate YAML
        run: |
          find examples -name "*.yaml" -o -name "*.yml" | while read yaml; do
            echo "Checking $yaml..."
            yamllint "$yaml" || exit 1
          done
  
  test-examples:
    name: Test Examples
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Install dependencies
        run: |
          # Install libvirt, QEMU, etc.
          sudo apt-get update
          sudo apt-get install -y qemu-kvm libvirt-daemon-system
      
      - name: Run example tests
        run: |
          cd examples/08-testing/integration
          ./run-all-tests.sh
```

**Deliverables**:
- [ ] All examples tested manually
- [ ] CI validation configured
- [ ] Test suite created
- [ ] Test documentation

### Phase 5: Documentation Update (Week 3, Days 4-5)

**Tasks**:
1. Create comprehensive examples/README.md
2. Update main README.md
3. Add "Examples" section to docs/
4. Link examples from relevant docs
5. Create examples index

**examples/README.md**:
```markdown
# VirtOS Examples

Ready-to-use examples demonstrating VirtOS features and workflows.

## Quick Start

```bash
# Create your first VM
cd examples/01-quickstart
./first-vm.sh

# Deploy multi-tier application
cd examples/02-platform-java/multi-tier
./deploy.sh
```

## Categories

### 01-quickstart/
Getting started examples for new users.

### 02-platform-java/
platform-java workload deployments (VMs, containers, applications).

### 03-networking/
Network configuration examples (bridges, VLANs, NAT).

### 04-storage/
Storage pool examples (LVM, Btrfs, ZFS, NFS, Ceph, GlusterFS).

### 05-ha-dr/
High availability and disaster recovery examples.

### 06-monitoring/
Monitoring and observability setups (Prometheus, Grafana).

### 07-advanced/
Advanced features (GPU passthrough, SR-IOV, templates, automation).

### 08-testing/
Integration tests and test fixtures (used by CI).

## Usage

All examples are self-contained and include:
- README.md with overview and instructions
- Working scripts or YAML files
- Helper scripts for deployment
- Test scripts for validation

## Testing

Examples are automatically validated in CI:
- Bash syntax checking
- YAML linting
- Integration test execution

## Related Documentation

- [Getting Started](../docs/GETTING-STARTED.md)
- [platform-java Integration](../docs/PLATFORM-JAVA_INTEGRATION.md)
- [Quick Reference](../docs/QUICK-REFERENCE.md)
```

**Deliverables**:
- [ ] examples/README.md created
- [ ] Main README.md updated
- [ ] Docs updated with example links
- [ ] Examples index

### Phase 6: Repository Cleanup (Week 4)

**Tasks**:
1. Add deprecation notice to VirtOS-Examples
2. Update VirtOS-Examples README to redirect
3. Optionally archive VirtOS-Examples
4. Update all external references

**VirtOS-Examples Deprecation Notice**:
```markdown
# VirtOS-Examples (DEPRECATED)

⚠️ **This repository has been integrated into the main VirtOS repository.**

## New Location

All examples are now located at:
**https://github.com/FlossWare/VirtOS/tree/main/examples**

## Migration

Instead of:
```bash
git clone https://github.com/FlossWare/VirtOS-Examples.git
```

Use:
```bash
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS/examples
```

## Timeline

- **2026-05-29**: Examples integrated into VirtOS
- **2026-06-30**: This repository will be archived

## Questions

Please file issues at: https://github.com/FlossWare/VirtOS/issues
```

**Deliverables**:
- [ ] Deprecation notice added
- [ ] README updated
- [ ] Archive scheduled
- [ ] External links updated

## Estimated Effort

| Phase | Duration | Effort |
|-------|----------|--------|
| 1. Preparation | 1 week | 8 hours |
| 2. Directory Setup | 2 days | 4 hours |
| 3. Content Migration | 3 days | 16 hours |
| 4. Validation | 3 days | 12 hours |
| 5. Documentation | 2 days | 8 hours |
| 6. Cleanup | 1 week | 4 hours |
| **Total** | **4 weeks** | **52 hours** |

## Success Criteria

- [ ] All examples migrated to `examples/`
- [ ] Examples organized into 8 categories
- [ ] All path references updated
- [ ] CI validates examples automatically
- [ ] Documentation updated with example links
- [ ] VirtOS-Examples deprecated
- [ ] Zero broken examples
- [ ] All examples tested manually
- [ ] Examples serve as integration tests

## Risks & Mitigation

### Risk 1: Breaking Existing Users

**Risk**: Users relying on VirtOS-Examples URL  
**Impact**: High - Broken links, confusion  
**Mitigation**:
- Add deprecation notice immediately
- Keep VirtOS-Examples active for 1 month
- Redirect users to new location
- Update all documentation

### Risk 2: Example Incompatibility

**Risk**: Examples don't work with current VirtOS  
**Impact**: Medium - User frustration  
**Mitigation**:
- Test all examples before migration
- Update examples to current API
- Add CI validation
- Document known issues

### Risk 3: Maintenance Burden

**Risk**: Examples become stale over time  
**Impact**: Medium - Outdated examples  
**Mitigation**:
- Automate example validation in CI
- Use examples as integration tests
- Regular example audits
- Community contributions

## Benefits Summary

### For Users
✅ **Single clone** - Everything in one repository  
✅ **Always compatible** - Examples match VirtOS version  
✅ **Better discovery** - Examples easy to find  
✅ **Tested examples** - CI validates all examples  
✅ **Inline docs** - Examples complement documentation

### For Developers
✅ **Integration tests** - Examples validate features  
✅ **CI coverage** - Automated example testing  
✅ **Sync maintenance** - Examples update with code  
✅ **API validation** - Examples catch breaking changes

### For Project
✅ **Better UX** - Simpler getting-started  
✅ **Higher quality** - Validated examples  
✅ **Less confusion** - Single source of truth  
✅ **Easier maintenance** - One repository to manage

## Related Issues

- Issue #120 - Integrate VirtOS-Examples into Main Repository
- Issue #13 - VirtOS-Examples validation

## References

- [VirtOS-Examples Repository](https://github.com/FlossWare/VirtOS-Examples)
- [CI/CD Best Practices](https://docs.github.com/en/actions)

---

**Status**: Integration plan approved  
**Timeline**: 4 weeks  
**Effort**: 52 hours  
**Priority**: P2 (Medium) - Quality of life improvement  
**Next Steps**: Begin Phase 1 (Preparation)
