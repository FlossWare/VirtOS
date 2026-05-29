# Contributing to FlossWare VirtOS

Thank you for considering contributing! This project aims to create a minimal, efficient virtualization platform based on Tiny Core Linux.

## Community Resources

New to VirtOS? Check out our [Community Guide](docs/COMMUNITY.md) for:

- 📢 Communication channels (GitHub Discussions, Issues)
- 💬 How to ask questions and get help
- 🙌 Community guidelines and Code of Conduct
- 🎯 Recognition and contributor highlights

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to <https://github.com/FlossWare/VirtOS/issues> (use the "code-of-conduct" label).

## Project Philosophy

- **Minimal**: Only include what's necessary
- **Modular**: Use Tiny Core's extension system
- **Flexible**: Support multiple virtualization technologies
- **Open**: Community-driven development

## How to Contribute

### Reporting Issues

- Check existing issues first
- Provide system info (CPU, RAM, Tiny Core version)
- Include steps to reproduce
- Share relevant logs/error messages

### Suggesting Features

- Align with minimal/modular philosophy
- Consider if it belongs in core or as optional extension
- Explain use case and benefits
- Check roadmap first (docs/ROADMAP.md)

### Code Contributions

1. **Fork the repository**
2. **Create a feature branch**

   ```bash
   git checkout -b feature/my-feature
   ```

3. **Make your changes**
   - Follow our [Coding Standards](docs/CODING_STANDARDS.md)
   - Test thoroughly
   - Update documentation

4. **Commit with clear messages**

   ```bash
   git commit -m "Add support for XYZ virtualization"
   ```

5. **Push and create pull request**

   ```bash
   git push origin feature/my-feature
   ```

### Building Custom Packages

If you're adding a new TCZ extension:

1. Place build scripts in `packages/`
2. Document dependencies
3. Include .tcz.info file
4. Test installation and functionality
5. Add to appropriate phase in ROADMAP.md

### Documentation

- Keep docs concise and clear
- Use examples liberally
- Update relevant .md files with changes
- Spell check and proofread

## Development Setup Guide

This section provides step-by-step instructions to set up your VirtOS development environment, from initial clone to running your first build.

### Prerequisites

**For script development:**

- Linux system (preferably Fedora, Ubuntu, or Tiny Core)
- Bash 4.0+
- Git
- Text editor (vim, nano, VS Code, etc.)
- Python 3.8+ (for pre-commit hooks)
- shellcheck (for linting)
- pre-commit (recommended - see below)

**For building VirtOS ISO:**

- Tiny Core Linux build environment
- 4GB+ RAM
- 20GB+ free disk space
- QEMU/KVM for testing

### Step 1: Clone and Environment Setup

Clone the repository and install required development tools:

```bash
# Clone the repository
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS

# Install development dependencies (Fedora/RHEL)
sudo dnf install -y shellcheck git python3 python3-pip

# Install development dependencies (Ubuntu/Debian)
sudo apt install -y shellcheck git python3 python3-pip

# Install Python development tools
pip install --user pre-commit

# Verify installations
shellcheck --version
pre-commit --version
git --version
```

### Step 2: Pre-commit Hook Installation

VirtOS uses automated code quality checks to catch issues before commit. **This step is highly recommended**.

```bash
# Install pre-commit hooks (one-time setup)
pre-commit install
pre-commit install --hook-type commit-msg

# Verify hooks are installed
ls -la .git/hooks/
# Should see: pre-commit, commit-msg

# Test hooks on all files (optional)
pre-commit run --all-files
```

**What the hooks enforce:**

- ✅ ShellCheck (shell script linting)
- ✅ shfmt (shell script formatting)
- ✅ YAML/JSON validation
- ✅ Secret detection (prevents committing passwords/keys)
- ✅ Conventional commit messages (feat:, fix:, docs:, etc.)
- ✅ Trailing whitespace removal
- ✅ Mixed line endings detection

**Hook behavior:**

```bash
# Hooks run automatically on 'git commit'
git commit -m "feat: add new feature"
# Hook runs, fails if issues found

# To skip hooks (NOT recommended - only for emergencies)
git commit -m "feat: add feature" --no-verify

# Run hooks manually without committing
pre-commit run --all-files

# Run specific hook
pre-commit run shellcheck --all-files
```

See [docs/PRE_COMMIT_HOOKS.md](docs/PRE_COMMIT_HOOKS.md) for complete guide and troubleshooting.

### Step 3: Running Tests Locally

VirtOS has comprehensive testing at multiple levels. Run tests before submitting PRs.

#### Quick Validation (Recommended for all PRs)

```bash
# Comprehensive validation (8 checks per script)
./ci/validate-scripts.sh --report

# Check specific script
./ci/validate-scripts.sh packages/virtos-tools/src/usr/local/bin/virtos-vm

# Validate error handling compliance
./ci/migrate-error-handling.sh --report
```

#### Manual Testing

```bash
# Test syntax of all scripts
for script in packages/virtos-tools/src/usr/local/bin/virtos-*; do
  bash -n "$script" && echo "✓ $script" || echo "✗ $script FAILED"
done

# Run shellcheck on all scripts
shellcheck packages/virtos-tools/src/usr/local/bin/virtos-*

# Test specific script
bash -n config/custom-scripts/virtos-vm
shellcheck config/custom-scripts/virtos-vm
```

#### Unit Tests (BATS Framework)

```bash
# Install BATS (if not present)
git clone https://github.com/bats-core/bats-core.git /tmp/bats
sudo /tmp/bats/install.sh /usr/local

# Run all unit tests
bats tests/*.bats

# Run specific test file
bats tests/virtos-vm.bats

# Run with verbose output
bats -t tests/virtos-vm.bats
```

#### Integration Tests

```bash
# Integration tests require VirtOS runtime environment
# See TESTING.md for full procedures

# Run integration test suite (when VirtOS is running)
cd tests/integration
bats 01-vm-lifecycle.bats
bats 02-network-management.bats
```

See [TESTING.md](TESTING.md) for complete testing procedures.

### Step 4: Building Packages

Build VirtOS packages locally to test your changes.

#### Build All Packages

```bash
# Build all TCZ packages
cd packages
./build-all.sh

# Check build output
ls -lh output/
# Should see: virtos-tools.tcz, virtos-platform-java.tcz, etc.

# Verify package contents
unsquashfs -ll output/virtos-tools.tcz
```

#### Build Specific Package

```bash
# Build virtos-tools only
cd packages/virtos-tools
./build.sh

# Build platform-java integration
cd packages/virtos-platform-java
./build.sh

# Verify package metadata
cat virtos-tools.tcz.info
cat virtos-tools.tcz.dep  # Dependencies
```

#### Package Testing

```bash
# Extract package for inspection
cd packages/output
unsquashfs virtos-tools.tcz

# Check extracted files
ls -R squashfs-root/

# Verify script permissions
find squashfs-root/ -name "virtos-*" -exec ls -lh {} \;

# Clean up
rm -rf squashfs-root/
```

#### Build ISO (Advanced)

```bash
# Build VirtOS ISO (requires Tiny Core build environment)
cd build
./build.sh

# Build specific profile
./build.sh --profile minimal

# Check ISO output
ls -lh output/
file output/virtos-*.iso

# Test ISO in QEMU
qemu-system-x86_64 -cdrom output/virtos-minimal.iso -m 2048
```

See [ISO_TESTING_STATUS.md](ISO_TESTING_STATUS.md) for ISO validation checklist.

### Step 5: Common Development Workflows

#### Workflow 1: Fix a Bug

```bash
# Create branch
git checkout -b fix/vm-creation-bug

# Make changes to script
vim packages/virtos-tools/src/usr/local/bin/virtos-vm

# Test locally
bash -n packages/virtos-tools/src/usr/local/bin/virtos-vm
shellcheck packages/virtos-tools/src/usr/local/bin/virtos-vm
./ci/validate-scripts.sh packages/virtos-tools/src/usr/local/bin/virtos-vm

# Build package to verify
cd packages/virtos-tools && ./build.sh

# Commit (pre-commit hooks run automatically)
git add packages/virtos-tools/src/usr/local/bin/virtos-vm
git commit -m "fix: correct VM creation error handling

Fixes issue where VM creation failed silently when disk
quota was exceeded.

Fixes #123"

# Push and create PR
git push origin fix/vm-creation-bug
```

#### Workflow 2: Add New Feature

```bash
# Create branch
git checkout -b feature/add-backup-encryption

# Add new feature to existing script
vim packages/virtos-tools/src/usr/local/bin/virtos-backup

# Add tests
vim tests/virtos-backup.bats

# Validate
./ci/validate-scripts.sh --report
bats tests/virtos-backup.bats

# Update documentation
vim docs/guides/BACKUP.md

# Commit and push
git add packages/virtos-tools/src/usr/local/bin/virtos-backup
git add tests/virtos-backup.bats
git add docs/guides/BACKUP.md
git commit -m "feat: add encryption support to virtos-backup

Implements AES-256 encryption for backup files with
configurable passphrase management.

Closes #456"
git push origin feature/add-backup-encryption
```

#### Workflow 3: Create New Management Script

```bash
# Create branch
git checkout -b feature/add-virtos-monitoring

# Create new script
cat > packages/virtos-tools/src/usr/local/bin/virtos-monitoring <<'EOF'
#!/bin/sh
# virtos-monitoring - System monitoring and alerting
set -e
VERSION="0.1"
# ... implementation ...
EOF

# Make executable
chmod +x packages/virtos-tools/src/usr/local/bin/virtos-monitoring

# Add to package file list
vim packages/virtos-tools/virtos-tools.tcz.list

# Create tests
vim tests/virtos-monitoring.bats

# Validate
bash -n packages/virtos-tools/src/usr/local/bin/virtos-monitoring
shellcheck packages/virtos-tools/src/usr/local/bin/virtos-monitoring
bats tests/virtos-monitoring.bats

# Build package
cd packages/virtos-tools && ./build.sh

# Commit and push
git add packages/virtos-tools/src/usr/local/bin/virtos-monitoring
git add packages/virtos-tools/virtos-tools.tcz.list
git add tests/virtos-monitoring.bats
git commit -m "feat: add virtos-monitoring for system alerts"
git push origin feature/add-virtos-monitoring
```

#### Workflow 4: Update Documentation

```bash
# Create branch
git checkout -b docs/improve-testing-guide

# Update documentation
vim TESTING.md

# Validate markdown (pre-commit hook does this)
pre-commit run --files TESTING.md

# Commit
git add TESTING.md
git commit -m "docs: add BATS testing examples to TESTING.md"
git push origin docs/improve-testing-guide
```

### Troubleshooting Development Setup

#### Pre-commit hooks fail

```bash
# Update hooks to latest version
pre-commit autoupdate

# Clear hook cache
pre-commit clean

# Reinstall hooks
pre-commit uninstall
pre-commit install
pre-commit install --hook-type commit-msg
```

#### shellcheck not found

```bash
# Fedora/RHEL
sudo dnf install shellcheck

# Ubuntu/Debian
sudo apt install shellcheck

# macOS
brew install shellcheck

# Or disable shellcheck hook temporarily
SKIP=shellcheck git commit -m "message"
```

#### Package build fails

```bash
# Check dependencies
cat packages/virtos-tools/virtos-tools.tcz.dep

# Verify file permissions
find packages/virtos-tools/src -type f -name "virtos-*" ! -perm -111

# Check for syntax errors
bash -n packages/virtos-tools/src/usr/local/bin/virtos-*

# Review build script
cat packages/virtos-tools/build.sh
```

#### BATS tests fail

```bash
# Install BATS
git clone https://github.com/bats-core/bats-core.git /tmp/bats
sudo /tmp/bats/install.sh /usr/local

# Verify installation
bats --version

# Run single test for debugging
bats -t tests/virtos-vm.bats

# Check test file syntax
bash -n tests/virtos-vm.bats
```

### Next Steps

After completing the setup:

1. Read [TESTING.md](TESTING.md) for complete testing procedures
2. Review [docs/CODING_STANDARDS.md](docs/CODING_STANDARDS.md) for code style
3. Check [docs/ROADMAP.md](docs/ROADMAP.md) for areas needing help
4. Browse existing issues for good first contributions
5. Join discussions in GitHub Discussions

### Quick Start Summary

```bash
# Complete setup in 5 commands
git clone https://github.com/FlossWare/VirtOS.git && cd VirtOS
pip install --user pre-commit && pre-commit install && pre-commit install --hook-type commit-msg
git checkout -b feature/my-feature
./ci/validate-scripts.sh --report  # Verify everything works
cd packages && ./build-all.sh      # Build packages
```

### Development Workflow

1. **Create an issue** (for features/bugs)
2. **Fork and clone** the repository
3. **Create a branch** from `main`
4. **Make changes** following our [Coding Standards](docs/CODING_STANDARDS.md)
5. **Test thoroughly** (see Testing section)
6. **Commit** with descriptive messages
7. **Push** to your fork
8. **Open a pull request**

### Branch Naming

Use descriptive branch names:

- `feature/add-xyz-support` - New features
- `fix/vm-creation-bug` - Bug fixes
- `docs/update-readme` - Documentation
- `refactor/cleanup-scripts` - Code refactoring
- `test/add-unit-tests` - Testing additions

## Testing

**See [TESTING.md](TESTING.md) for comprehensive testing guide.**

### Pre-submission Checklist

Before submitting a PR, ensure:

- [ ] All shell scripts pass syntax check: `bash -n script.sh`
- [ ] shellcheck passes: `shellcheck script.sh`
- [ ] Scripts have execute permissions: `chmod +x script.sh`
- [ ] No sensitive data in commits (.env files, passwords, keys)
- [ ] Documentation updated for new features
- [ ] Commit messages are clear and descriptive
- [ ] Code follows project style guidelines
- [ ] No merge conflicts with main branch

### Quick Validation

**Using our validation tools** (recommended):

```bash
# Comprehensive script validation (8 quality checks per script)
./ci/validate-scripts.sh --report

# Check error handling compliance
./ci/migrate-error-handling.sh --report

# Validate specific script
./ci/validate-scripts.sh packages/virtos-tools/src/usr/local/bin/virtos-yourscript
```

**Manual validation**:

```bash
# Validate all scripts
for script in packages/virtos-tools/src/usr/local/bin/virtos-*; do
  bash -n "$script" && echo "✓ $script" || echo "✗ $script FAILED"
done

# Run shellcheck on all scripts
shellcheck packages/virtos-tools/src/usr/local/bin/virtos-*

# Check for common issues
grep -r "password\s*=" packages/  # Should not find hardcoded passwords
grep -r "TODO\|FIXME" packages/   # Find items needing attention
```

### Testing Levels

**Level 0: Syntax validation** (required for all PRs)

```bash
bash -n your-script.sh
shellcheck your-script.sh
```

**Level 1: Script execution** (test commands work)

```bash
./config/custom-scripts/virtos-yourscript --help
./config/custom-scripts/virtos-yourscript status
```

**Level 2: Integration testing** (test with VirtOS system)

- Build ISO and boot
- Run script in VirtOS environment
- Verify expected behavior

**Level 3: System testing** (end-to-end workflows)

- Complete user workflows
- Test with actual VMs/containers
- Verify clustering, HA, backup, etc.

See [TESTING.md](TESTING.md) for detailed procedures.

## Areas Needing Help

Current priorities (see ROADMAP.md):

**Core System**:

- [ ] Custom kernel configuration optimization
- [ ] TCZ package building automation
- [ ] Build script improvements
- [ ] Testing on various hardware

**Advanced Features**:

- [ ] Web UI integration (Cockpit/Portainer)
- [ ] GPU passthrough support
- [ ] USB passthrough
- [ ] Live VM migration
- [ ] High availability implementation
- [ ] Advanced networking (OVS, VLANs)

**Documentation**:

- [ ] Video tutorials
- [ ] More examples and use cases
- [ ] Troubleshooting guides
- [ ] Performance tuning guides
- [ ] Translation to other languages

**Testing**:

- [ ] Automated testing
- [ ] Integration tests
- [ ] Performance benchmarks
- [ ] Hardware compatibility list

**Community**:

- [ ] Sample configurations
- [ ] Template library
- [ ] Blog posts / articles
- [ ] Community support

## Code Style

All VirtOS code must follow our **[Official Coding Standards](docs/CODING_STANDARDS.md)**.

### Quick Reference

**Shell Scripts:**

- Use `#!/bin/sh` shebang for POSIX compliance (Tiny Core Linux uses BusyBox ash)
- Use 4 spaces for indentation (no tabs)
- Line length: 80 characters target, 120 maximum
- Always enable `set -e` for error handling
- Always quote variables: `"$variable"` not `$variable`
- Use `[` for conditionals (POSIX), not `[[` (bash-specific)
- Use `$(command)` for command substitution (not backticks)

**Naming:**

- Constants: `UPPER_CASE` (readonly)
- Global variables: `UPPER_CASE`
- Local variables: `snake_case`
- Functions: `snake_case`
- Scripts: `virtos-kebab-case`

**Security:**

- Validate all user input
- Prevent command injection (quote variables)
- Prevent path traversal (no `../`)
- Use `mktemp` for temporary files

See **[docs/CODING_STANDARDS.md](docs/CODING_STANDARDS.md)** for complete guidelines including:

- Error handling patterns
- Security best practices
- Testing requirements
- Git workflow
- Complete examples

**Example Script (POSIX-compliant):**

```bash
#!/bin/sh
# virtos-example - Brief description of what this does
#
# Usage: virtos-example [command] [options]

set -e  # Exit on error

VERSION="1.0"

# Load common libraries
if [ -f /usr/local/lib/virtos-common.sh ]; then
    . /usr/local/lib/virtos-common.sh
fi

show_help() {
    cat <<EOF
Usage: virtos-example [OPTIONS] <command>

Commands:
    start   Start the service
    stop    Stop the service
    status  Show status

Options:
    -h, --help      Show this help
    -v, --version   Show version

Examples:
    virtos-example start
    virtos-example status
EOF
}

main() {
    local command="$1"

    case "$command" in
        start)
            echo "Starting..."
            ;;
        stop)
            echo "Stopping..."
            ;;
        status)
            echo "Checking status..."
            ;;
        *)
            echo "Error: Unknown command '$command'" >&2
            show_help
            exit 1
            ;;
    esac
}

# Argument parsing
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -v|--version)
        echo "virtos-example version $VERSION"
        exit 0
        ;;
esac

# Execute main
main "$@"
```

For complete examples and best practices, see **[docs/CODING_STANDARDS.md](docs/CODING_STANDARDS.md)**.

### Linting

All scripts must pass shellcheck:

```bash
# Install shellcheck
# Fedora: sudo dnf install shellcheck
# Ubuntu: sudo apt install shellcheck
# macOS: brew install shellcheck

# Run on your script
shellcheck config/custom-scripts/virtos-yourscript

# Fix issues or disable specific checks with comments
# shellcheck disable=SC2086
echo $VAR  # Intentionally unquoted
```

### Documentation Standards

**Inline Documentation:**

- All `virtos-*` commands must have `--help` option
- Help text should include examples
- Version info should be available

**Markdown Files:**

- Use proper heading hierarchy (# ## ###)
- Include code blocks with syntax highlighting
- Add table of contents for long documents
- Keep line length reasonable (80-100 chars)
- Use relative links within repo

**Code Blocks:**

```bash
# Use bash syntax highlighting
command --option value

# Show expected output
# Output:
# Expected result here
```

## Pull Request Process

### Before Opening a PR

1. **Ensure your code works**
   - Test locally
   - Run syntax checks
   - Verify no regressions

2. **Update documentation**
   - README.md if adding features
   - Relevant docs/ files
   - Inline code comments
   - ROADMAP.md if completing phases

3. **Clean commit history**
   - Use descriptive commit messages
   - Squash "fix typo" commits
   - One logical change per commit

### Commit Message Format

```text
<type>: <short description>

<optional longer description>

<optional footer>
```

**Types:**

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `refactor:` Code refactoring
- `test:` Adding tests
- `chore:` Maintenance tasks
- `perf:` Performance improvements

**Examples:**

```text
feat: Add virtos-backup-orchestration script

Implements automated backup workflows with policy management,
retention enforcement, and verification.

Closes #42

---

fix: Correct virtos-tui permissions issue

virtos-tui was not executable after build, preventing users
from launching the management interface.

---

docs: Update TESTING.md with new test levels

Added Level 5 and 6 testing procedures for performance
and stress testing.
```

### PR Description Template

When opening a PR, include:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement

## Testing
- [ ] Syntax check passed
- [ ] shellcheck passed
- [ ] Manual testing completed
- [ ] Integration tests passed

## Related Issues
Fixes #123

## Checklist
- [ ] Code follows project style
- [ ] Documentation updated
- [ ] No merge conflicts
- [ ] CI checks pass

## Screenshots (if applicable)
```

### Review Process

1. **Automated Checks**
   - CI runs syntax validation
   - shellcheck linting
   - Documentation checks
   - All must pass

2. **Code Review**
   - At least one maintainer review
   - Address feedback promptly
   - Make requested changes

3. **Testing**
   - Verify changes work as described
   - Check for side effects
   - Validate documentation accuracy

4. **Merge**
   - Approved PRs are merged by maintainers
   - Commits may be squashed
   - Branch deleted after merge

### Getting Your PR Merged Faster

- **Small, focused changes** - Easier to review
- **Good description** - Explain the why
- **Tests included** - Show it works
- **Documentation updated** - Keep docs in sync
- **Respond to feedback** - Address comments quickly
- **Rebase if needed** - Keep up with main branch

## Communication

### Where to Go

- **GitHub Issues** - Bug reports, feature requests (use templates)
- **GitHub Discussions** - Questions, ideas, general help
- **Pull Requests** - Code contributions
- **Email** - For security issues or private matters

### Response Times

This is a community project. Please be patient:

- Issues: Triage within 3-5 days
- PRs: Initial review within 1 week
- Discussions: Best effort, community-driven

### Community Standards

Be respectful and constructive:

- Assume good faith
- Be patient with newcomers
- Provide helpful feedback
- Focus on ideas, not individuals
- Keep discussions on-topic

## Recognition

Contributors are recognized in several ways:

- Listed in CONTRIBUTORS.md (if you'd like)
- Git commit history
- Release notes for significant contributions
- Special thanks in README for major features

## Implementation Status

VirtOS is in active development. Please read the **Implementation Status** section in README.md to understand:

- What's fully implemented
- What's prototype/demonstration
- What needs backend integration
- Where help is most needed

## Areas Needing Help (Priority Order)

### 🔴 Critical (Core Functionality)

1. **Backend Integration** - Connect management scripts to libvirt/QEMU/LXC
2. **ISO Building** - Complete bootable ISO generation process
3. **Kernel Configuration** - Test and refine KVM kernel configs
4. **Package Building** - Create TCZ packages for all components
5. **Basic Testing** - Boot-to-VM workflow validation

### 🟠 High Priority (Production Features)

1. **Backup Integration** - Connect virtos-backup to actual VM snapshots
2. **HA Implementation** - Real failover detection and VM migration
3. **Clustering** - Implement actual cluster communication
4. **Storage Management** - Btrfs/LVM/ZFS backend integration
5. **Network Integration** - Bridge/VLAN/OVS actual configuration

### 🟡 Medium Priority (Advanced Features)

1. **GPU Passthrough** - VFIO configuration and testing
2. **Live Migration** - Implement VM migration between hosts
3. **Monitoring** - Prometheus/Grafana integration
4. **Security** - SELinux/AppArmor profiles
5. **Web UI** - Optional Cockpit/Portainer integration

### 🟢 Low Priority (Nice to Have)

1. **AI/ML Features** - Actual ML-based optimization
2. **Quantum Integration** - Real quantum computer access
3. **Blockchain Features** - DeFi/NFT implementation
4. **Advanced Federation** - Multi-cloud orchestration
5. **Additional Platforms** - More cloud provider support

### 📚 Documentation

- [ ] Video tutorials
- [ ] More real-world examples
- [ ] Troubleshooting guides (common issues)
- [ ] Performance tuning guides
- [ ] Hardware compatibility testing
- [ ] Translation to other languages

### 🧪 Testing

- [ ] Unit tests (BATS framework)
- [ ] Integration tests
- [ ] Performance benchmarks
- [ ] Hardware compatibility list
- [ ] Automated ISO build testing

## License

By contributing, you agree that your contributions will be licensed under the GNU General Public License v3.0, the same license as the project. See [LICENSE](LICENSE) file for details.

## Questions?

- Check [docs/INDEX.md](docs/INDEX.md) for documentation
- Search existing issues
- Open a GitHub Discussion
- Create an issue with the question label

We're here to help - don't hesitate to ask!
