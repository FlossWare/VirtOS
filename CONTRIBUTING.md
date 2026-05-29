# Contributing to FlossWare VirtOS

Thank you for considering contributing! This project aims to create a minimal, efficient virtualization platform based on Tiny Core Linux.

## Community Resources

New to VirtOS? Check out our [Community Guide](docs/COMMUNITY.md) for:
- 📢 Communication channels (GitHub Discussions, Issues)
- 💬 How to ask questions and get help
- 🙌 Community guidelines and Code of Conduct
- 🎯 Recognition and contributor highlights

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to https://github.com/FlossWare/VirtOS/issues (use the "code-of-conduct" label).

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
   - Follow existing code style
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

## Development Setup

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

### Quick Start

```bash
# Clone the repository
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS

# Install pre-commit hooks (RECOMMENDED)
pip install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg

# Check out a development branch
git checkout -b feature/my-feature

# Validate scripts before making changes
./build/scripts/prepare.sh

# Make your changes
# ...

# Pre-commit hooks run automatically on commit
# Or run manually:
pre-commit run --all-files

# Test script syntax
bash -n config/custom-scripts/virtos-yourscript

# Run shellcheck
shellcheck config/custom-scripts/virtos-yourscript
```

**Pre-commit Hooks** (Recommended):
VirtOS uses automated code quality checks via pre-commit hooks. These catch issues before you commit:

```bash
# One-time setup
pip install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg

# Hooks run automatically on 'git commit'
# Or run manually on all files:
pre-commit run --all-files
```

Hooks enforce:
- ✅ ShellCheck (shell script linting)
- ✅ shfmt (shell script formatting)
- ✅ YAML/JSON validation
- ✅ Secret detection
- ✅ Conventional commit messages
- ✅ Trailing whitespace removal

See [docs/PRE_COMMIT_HOOKS.md](docs/PRE_COMMIT_HOOKS.md) for complete guide.

### Development Workflow

1. **Create an issue** (for features/bugs)
2. **Fork and clone** the repository
3. **Create a branch** from `main`
4. **Make changes** following our coding standards
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

### Shell Script Standards

**General Guidelines:**
- Use `#!/bin/bash` shebang (not `/bin/sh`)
- Use 4 spaces for indentation (no tabs)
- Maximum line length: 120 characters
- Use `set -e` for scripts that should fail fast
- Always quote variables: `"$variable"` not `$variable`
- Use `[[` instead of `[` for conditionals
- Prefer `$(command)` over backticks

**Naming Conventions:**
- Variables: `UPPERCASE_WITH_UNDERSCORES`
- Functions: `lowercase_with_underscores`
- Scripts: `virtos-lowercase-with-hyphens`
- Temporary files: Use `mktemp`

**Comments:**
- Add file header with description, version, author
- Document complex logic and why (not what)
- Use TODO/FIXME for incomplete items
- Keep comments up-to-date with code

**Error Handling:**
```bash
# Always check exit codes
if ! command; then
    echo "Error: command failed" >&2
    exit 1
fi

# Or use set -e
set -e
command  # Script exits if this fails

# Trap cleanup
cleanup() {
    rm -f "$TEMP_FILE"
}
trap cleanup EXIT
```

**Example Script Structure:**
```bash
#!/bin/bash
# VirtOS Example Script
# Brief description of what this does

VERSION="1.0"
set -e

# Configuration
CONFIG_DIR="/etc/virtos"
LOG_FILE="/var/log/virtos-example.log"

# Functions
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

show_usage() {
    cat <<EOF
Usage: $(basename "$0") [command] [options]

Commands:
  start   - Start the service
  stop    - Stop the service
  status  - Show status

Options:
  -h, --help     Show this help
  -v, --version  Show version

Examples:
  $(basename "$0") start
  $(basename "$0") status
EOF
}

# Main logic
main() {
    case "$1" in
        start)
            log_message "Starting..."
            ;;
        stop)
            log_message "Stopping..."
            ;;
        status)
            log_message "Checking status..."
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# Execute
main "$@"
```

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

```
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
```
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

### Code of Conduct

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
