# VirtOS - AI Development Guide

## Project Overview

VirtOS is a minimal virtualization OS based on Tiny Core Linux, designed for unified management of VMs, containers, and cloud resources. The project integrates JPlatform for workload orchestration and emphasizes comprehensive design and documentation.

**Key Philosophy**: Prototype interfaces first, then implement backends. Many features are interface prototypes awaiting backend integration.

## Architecture

### Current Implementation Status

#### ✅ Fully Working
- Package build system (TCZ format)
- Documentation framework (20+ markdown files)
- Build validation and CI/CD pipelines
- Version management (X.Y auto-increment)
- JPlatform integration package
- Multi-tier application examples

#### 🔷 Interface Prototypes
- Most virtos-* management scripts (52 scripts)
- VM management commands (interface defined, awaiting libvirt backend)
- Container management commands (interface defined, awaiting Docker/Podman backend)
- Clustering commands (interface defined, awaiting implementation)

#### ⚠️ Untested
- ISO building system (framework exists, not validated)
- VirtOS TUI (code exists, needs real environment testing)

#### ❌ Not Started
- Backend integration with libvirt/QEMU/KVM
- Backend integration with Docker/Podman/LXC
- Cluster management backend
- Real hardware/VM testing

### Key Directories

```
VirtOS/
├── packages/               # TCZ package sources and build scripts
│   ├── virtos-tools/      # Core management scripts (52 scripts)
│   ├── virtos-jplatform/  # JPlatform integration
│   └── output/            # Built TCZ packages (ignored in git)
├── build/                 # ISO build system (untested)
│   ├── scripts/           # Build automation scripts
│   └── profiles/          # Build profiles (minimal, standard, full, etc.)
├── config/                # System configuration templates
│   ├── bootloader/        # Bootloader configs
│   ├── network/           # Network configs
│   └── custom-scripts/    # virtos-tui and other runtime scripts
├── docs/                  # Comprehensive documentation
│   ├── architecture/      # Architecture diagrams and design
│   └── guides/            # User and developer guides
├── .github/workflows/     # CI/CD pipelines
│   ├── ci.yml            # Continuous Integration
│   └── cd.yml            # Continuous Deployment to packagecloud.io
└── VERSION                # X.Y version (auto-incremented in CD)
```

### Important Files

#### Core Build Files
- `packages/build-all.sh` - Build all TCZ packages
- `packages/virtos-tools/build.sh` - Build virtos-tools package
- `packages/virtos-jplatform/build.sh` - Build JPlatform integration
- `VERSION` - Current version (0.1)

#### Management Scripts
- `packages/virtos-tools/src/usr/local/bin/virtos-*` - 52 management scripts
- `config/custom-scripts/virtos-tui` - Text user interface (menu system)

#### Configuration
- `build/build.conf` - Build configuration with 7 profiles
- `.github/workflows/cd.yml` - Auto-version bump and deployment

#### Documentation
- `README.md` - Project overview and quick start
- `INTEGRATION_TEST_REPORT.md` - Build verification status
- `docs/ARCHITECTURE.md` - Detailed architecture
- `docs/ROADMAP.md` - Development roadmap

## Development Guidelines

### Implementation Philosophy

1. **Minimal**: Only include necessary features, avoid bloat
2. **Modular**: Use Tiny Core extension (.tcz) system
3. **Prototype First**: Define interfaces before implementing backends
4. **Document Heavily**: Comprehensive docs guide implementation
5. **Test Thoroughly**: Syntax validation, unit tests, integration tests

### Script Development

All management scripts follow these conventions:

```bash
#!/bin/sh
# virtos-<name> - Brief description
#
# Usage: virtos-<name> [options] [arguments]
# Description of what the script does

set -e  # Exit on error

# Version from package
VERSION="0.1"

# Help function
show_help() {
    cat <<EOF
Usage: virtos-<name> [OPTIONS] [ARGUMENTS]

Description of the command

OPTIONS:
    -h, --help      Show this help message
    -v, --version   Show version

EXAMPLES:
    virtos-<name> example-arg
    virtos-<name> --help
EOF
}

# Main logic
main() {
    # Implementation
    echo "Prototype - backend integration needed"
}

# Parse arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -v|--version)
        echo "virtos-<name> version $VERSION"
        exit 0
        ;;
esac

main "$@"
```

### Testing Requirements

#### Syntax Validation
```bash
# All scripts must pass
bash -n virtos-script-name
shellcheck virtos-script-name  # If available
```

#### Unit Tests (Desired)
```bash
# Use BATS framework
# tests/virtos-script-name.bats
@test "virtos-script-name shows help" {
    run virtos-script-name --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}
```

#### Integration Tests
```bash
# Test workflows end-to-end
# Example: VM creation workflow
virtos-vm-create test-vm
virtos-vm-start test-vm
virtos-vm-status test-vm | grep RUNNING
virtos-vm-stop test-vm
virtos-vm-delete test-vm
```

### Security Considerations

**CRITICAL**: Many scripts run with sudo privileges

1. **Input Validation**: Always validate user input before shell commands
2. **Temporary Files**: Use `mktemp` for temporary files, not hardcoded paths
3. **Escaping**: Escape user input before shell evaluation
4. **Credentials**: Never hardcode credentials or API keys
5. **Permissions**: Minimal permissions, no unnecessary sudo

Example:
```bash
# BAD - Unsafe user input
vm_name="$1"
virsh start "$vm_name"  # Could be: "test; rm -rf /"

# GOOD - Validated input
vm_name="$1"
if ! echo "$vm_name" | grep -qE '^[a-zA-Z0-9_-]+$'; then
    echo "Error: Invalid VM name" >&2
    exit 1
fi
virsh start "$vm_name"
```

### Build System

```bash
# Build all packages
cd packages && ./build-all.sh

# Build specific package
cd packages/virtos-tools && ./build.sh

# Quick validation
build/scripts/quick-test.sh

# Full validation (when available)
build/scripts/validate-build.sh

# Check package contents
unsquashfs -ll packages/output/virtos-tools.tcz
```

### Version Management

```bash
# Current version
cat VERSION  # Shows: 0.1

# Version is auto-incremented in CD pipeline
# ci/rev-version.sh bumps version
# .github/workflows/cd.yml deploys new version

# All package .tcz.info files should match VERSION
grep Version: packages/*/virtos-*.tcz.info
```

## JPlatform Integration

VirtOS integrates JPlatform for unified workload orchestration:

### Architecture
```
┌─────────────────────────────────────┐
│   VirtOS (Virtualization OS)       │
│                                     │
│  ┌───────────────────────────────┐ │
│  │    JPlatform (Orchestrator)   │ │
│  │                               │ │
│  │  ┌────┐ ┌────┐ ┌────┐ ┌────┐│ │
│  │  │VMs │ │Cont│ │Java│ │Bin ││ │
│  │  └────┘ └────┘ └────┘ └────┘│ │
│  │                               │ │
│  │  Unified API, quotas, deps   │ │
│  └───────────────────────────────┘ │
│          ↓                          │
│  ┌──────────────┐  ┌──────────┐   │
│  │libvirt/QEMU │  │Docker/LXC│   │
│  └──────────────┘  └──────────┘   │
└─────────────────────────────────────┘
```

### Key Integration Points

1. **virtos-jplatform.tcz** - JPlatform integration package
2. **jplatform command** - CLI for workload management
3. **virtos-tui** - Includes JPlatform menu (option 17)
4. **Multi-tier examples** - Database VM + Java app + NGINX container

### Example Workflow
```bash
# Deploy multi-tier application
jplatform deploy examples/multi-tier/three-tier-webapp/1-database-tier.yaml
jplatform deploy examples/multi-tier/three-tier-webapp/2-app-tier.yaml
jplatform deploy examples/multi-tier/three-tier-webapp/3-web-tier.yaml

# Start in dependency order (automatic)
jplatform start nginx-web  # Starts database → app → web

# Monitor
jplatform status
jplatform metrics postgres-db
jplatform logs spring-app
```

## Known Issues

See [GitHub Issues](https://github.com/FlossWare/VirtOS/issues) for current work items:

### Critical (P0)
- **Issue #1**: Runtime testing needed for VirtOS-JPlatform integration
- **Issue #6**: Security review of virtos-* scripts
- **Issue #7**: Backend integration for libvirt/QEMU connectivity

### High Priority (P1)
- **Issue #3**: ISO build system untested
- **Issue #4**: Unit tests for management scripts
- **Issue #5**: CI/CD workflows don't run actual tests

### Medium Priority (P2)
- **Issue #2**: Documentation claims need accuracy review
- **Issue #8**: Verify packagecloud.io deployment
- **Issue #10**: Improve error messages and validation

### Low Priority (P3)
- **Issue #12**: Version synchronization verification
- **Issue #13**: Validate VirtOS-Examples repository

## Contributing

### Workflow for New Features

1. **Design Interface** (if not already done)
   - Create script with help output
   - Define command-line arguments
   - Document expected behavior

2. **Implement Backend**
   - Add actual integration (libvirt, Docker, etc.)
   - Replace "Prototype" placeholders
   - Add error handling

3. **Add Tests**
   - Syntax validation (bash -n)
   - Unit tests (BATS)
   - Integration tests

4. **Update Documentation**
   - README.md if user-facing
   - ARCHITECTURE.md if design changed
   - Code comments for complex logic

5. **Submit PR**
   - Clear description of changes
   - Reference related issues
   - Include test results

### Example PR Template
```markdown
## Summary
Brief description of changes

## Related Issues
Fixes #X, Addresses #Y

## Changes
- Added backend integration for virtos-vm-create
- Implemented libvirt XML generation
- Added unit tests for VM configuration

## Testing
- ✅ Syntax validation passed
- ✅ Unit tests: 15/15 passed
- ✅ Integration test: Created and started VM successfully
- ⚠️ Security review needed

## Documentation
- Updated README.md with VM creation examples
- Added troubleshooting section for libvirt errors
```

## Context for AI Assistants

### Don't Be Fooled By

- **"52 management scripts"** - Most are interface prototypes, not full implementations
- **"✅ Fully Implemented"** - Often refers to docs/interfaces, not backends
- **"ISO building framework complete"** - Framework exists but is untested
- **Feature lists in README** - Many are planned/prototyped, not working

### Real Implementation Status

| Component | Interface | Backend | Tests | Status |
|-----------|-----------|---------|-------|--------|
| Package building | ✅ | ✅ | ✅ | **Working** |
| VM management | ✅ | ❌ | ❌ | **Prototype** |
| Container management | ✅ | ❌ | ❌ | **Prototype** |
| Clustering | ✅ | ❌ | ❌ | **Prototype** |
| JPlatform integration | ✅ | ✅ | ⚠️ | **Partial** |
| ISO building | ✅ | ⚠️ | ❌ | **Untested** |

**Legend**: ✅ Complete, ⚠️ Partial, ❌ Not started

### Priority Work Items

When asked to help with VirtOS development, prioritize:

1. **Backend Integration** (Issue #7) - Most critical
   - Implement libvirt/QEMU connectivity
   - Implement Docker/Podman connectivity
   - Replace prototype placeholders with real implementations

2. **Security Review** (Issue #6) - High risk
   - Review sudo usage in scripts
   - Add input validation
   - Fix unsafe shell practices

3. **Testing** (Issues #3, #4, #5) - Quality
   - Add unit tests for scripts
   - Test ISO building end-to-end
   - Add integration tests to CI/CD

4. **Runtime Validation** (Issue #1) - Proof of concept
   - Test on real VirtOS instance
   - Validate JPlatform integration
   - Document real-world usage

5. **Documentation Accuracy** (Issue #2) - Clarity
   - Review implementation claims
   - Mark prototypes clearly
   - Update feature status

### Common Questions

**Q: Why are there so many scripts if they're not implemented?**
A: Interface-first design. Scripts define the desired API, backends come later.

**Q: Can I use VirtOS in production?**
A: No. Most features are prototypes. Suitable for development/testing only.

**Q: What works right now?**
A: Package building, documentation generation, and JPlatform integration package.

**Q: What's the fastest path to a working system?**
A: Implement backend integration (Issue #7) for core VM/container management.

**Q: Should I add more features or implement existing ones?**
A: Implement existing prototypes. We have enough interfaces defined.

## Additional Resources

- [Main Repository](https://github.com/FlossWare/VirtOS)
- [JPlatform Repository](https://github.com/FlossWare/jplatform)
- [Integration Test Report](INTEGRATION_TEST_REPORT.md)
- [Architecture Documentation](docs/ARCHITECTURE.md)
- [Development Roadmap](docs/ROADMAP.md)
- [Package Repository](https://packagecloud.io/flossware/virtos)

## Getting Help

- **Issues**: File bugs and feature requests on GitHub
- **Discussions**: Use GitHub Discussions for questions
- **Security**: Report security issues privately to maintainers

---

**Last Updated**: 2026-05-25
**Version**: 0.1
**Status**: Alpha (Prototype Phase)
