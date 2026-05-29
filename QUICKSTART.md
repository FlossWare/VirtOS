# VirtOS Quick Start Guide

Get up and running with VirtOS in 5 minutes.

## For Users: Try VirtOS

### Option 1: Build a Package (2 minutes) ✅ TESTED

Build the virtos-tools package containing all management scripts:

```bash
# 1. Clone
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS

# 2. Build package
make packages

# Done! Package built: packages/output/virtos-tools.tcz (332KB)
```

**What you get:** A working Tiny Core Linux package with 52 management tools.

### Option 2: Build Complete ISO (30-60 minutes) 🟡 UNTESTED

Build a bootable VirtOS ISO image:

```bash
# 1. Clone
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS

# 2. Validate environment
make validate

# 3. Build ISO (downloads ~500MB)
make build

# 4. Test in QEMU
qemu-system-x86_64 -enable-kvm -m 2048 \
    -cdrom build/output/VirtOS-*.iso
```

**Note:** ISO building framework complete but requires download testing.

## For Contributors: Start Developing

### Quick Setup (< 2 minutes)

```bash
# 1. Clone and enter
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS

# 2. Install dependencies (choose your OS)
make install-deps-fedora    # Fedora
# OR
make install-deps-ubuntu    # Ubuntu/Debian
# OR
make install-deps-arch      # Arch Linux

# 3. Setup development environment
make dev-setup

# 4. Validate everything works
make test
```

### Make Your First Contribution

**1. Find something to work on:**
```bash
# See what needs help
cat CONTRIBUTING.md | grep "NEEDED"

# Or check priority areas in README
```

**2. Create a feature branch:**
```bash
git checkout -b feature/my-awesome-feature
```

**3. Make changes and test:**
```bash
# Edit files
vim config/custom-scripts/virtos-mynewscript

# Test syntax
make check

# Run quick tests
make test
```

**4. Commit and push:**
```bash
git add .
git commit -m "feat: Add my awesome feature"
git push origin feature/my-awesome-feature
```

**5. Open a pull request on GitHub**

## Common Tasks

### Validate Build Environment

```bash
make validate
# Checks: disk space, RAM, tools, scripts, config
```

### Quick Test (5 seconds)

```bash
make test
# Runs: validation, syntax checks, package build test
```

### Build Packages

```bash
make packages
# Output: packages/output/virtos-tools.tcz
```

### Check Script Syntax

```bash
make check
# Validates syntax of all bash scripts
```

### Clean Build Artifacts

```bash
make clean        # Clean outputs only
make clean-all    # Clean everything including downloads
```

### View Project Stats

```bash
make stats
# Shows: docs count, scripts count, commits, package size
```

## Understanding the Project

### Directory Structure

```
VirtOS/
├── build/              # Build system
│   ├── scripts/        # Build, validation, and test scripts
│   └── build.conf      # Build configuration
├── config/             # System configuration
│   ├── custom-scripts/ # All virtos-* management tools (52 scripts)
│   └── profiles/       # Build profiles (minimal, standard, full, etc.)
├── docs/               # Documentation (19 markdown files)
├── kernel/             # Kernel configurations
├── packages/           # TCZ package definitions
│   ├── virtos-tools/   # Management tools package
│   └── output/         # Built packages
├── BUILD.md            # Detailed build guide
├── TESTING.md          # Testing procedures
├── CONTRIBUTING.md     # Contribution guidelines
└── README.md           # Project overview
```

### Key Files

- **Makefile** - Convenience targets for common operations
- **BUILD.md** - Complete build documentation and status
- **TESTING.md** - Testing guide (6 levels of testing)
- **CONTRIBUTING.md** - How to contribute
- **build/build.conf** - Build configuration (edit profiles here)

### What Works Now (May 2026)

✅ **Package Building** - Creates real TCZ packages  
✅ **Build Validation** - Checks prerequisites automatically  
✅ **Quick Testing** - 5-second validation  
✅ **Syntax Checking** - All scripts validated  
✅ **CI/CD** - GitHub Actions on every commit  
✅ **Documentation** - 15,000+ lines

See [BUILD.md](BUILD.md) for detailed status.

## Development Workflow

### Typical contribution flow:

1. **Check existing work**
   ```bash
   git pull origin main
   make test  # Ensure everything works
   ```

2. **Create branch**
   ```bash
   git checkout -b feature/your-feature
   ```

3. **Develop**
   ```bash
   # Edit files
   make check      # Check syntax
   make test       # Run tests
   ```

4. **Commit**
   ```bash
   git add .
   git commit -m "type: description"
   # Types: feat, fix, docs, refactor, test, chore
   ```

5. **Push and PR**
   ```bash
   git push origin feature/your-feature
   # Open PR on GitHub
   ```

### Commit Message Format

```
<type>: <short description>

<optional longer description>

<optional footer>
```

**Examples:**
- `feat: Add virtos-newfeature script`
- `fix: Correct syntax error in virtos-backup`
- `docs: Update BUILD.md with new instructions`
- `test: Add unit tests for virtos-cluster`

## Testing Your Changes

### Before committing:

```bash
# 1. Syntax check
make check

# 2. Quick test
make test

# 3. Build packages
make packages

# 4. Validate
make validate
```

### The git pre-commit hook (if you ran `make dev-setup`) automatically runs `make check`.

## Getting Help

### Documentation

- **Quick Start** - This file
- **Build Guide** - [BUILD.md](BUILD.md)
- **Testing** - [TESTING.md](TESTING.md)
- **Contributing** - [CONTRIBUTING.md](CONTRIBUTING.md)
- **API Docs** - [docs/](docs/)

### Commands

```bash
make help          # Show all make targets
./script --help    # Help for any virtos-* script
```

### Community

- **Issues**: https://github.com/FlossWare/VirtOS/issues
- **Discussions**: https://github.com/FlossWare/VirtOS/discussions
- **PRs**: https://github.com/FlossWare/VirtOS/pulls

## FAQs

### Q: Can I build on Windows/macOS?

A: The build system requires Linux. Use WSL (Windows) or a Linux VM (macOS).

### Q: How much disk space do I need?

A: 20GB recommended (includes download, build, and workspace).

### Q: Do I need to build the ISO to contribute?

A: No! Most contributions (scripts, docs, configs) don't require ISO building.

### Q: What if I don't have mksquashfs?

A: Install with:
```bash
sudo dnf install squashfs-tools  # Fedora
sudo apt install squashfs-tools  # Ubuntu
```

### Q: How long does building take?

A: Package build: 2-5 seconds  
   Full ISO: 30-60 minutes (first time, includes download)

### Q: Can I test without building?

A: Yes! Run `make test` or `make validate` for validation without building.

### Q: Where can I see what needs work?

A: Check CONTRIBUTING.md "Areas Needing Help" section or GitHub issues.

## Next Steps

### For Users:
1. ✅ Build a package (`make packages`)
2. 📖 Read [BUILD.md](BUILD.md) for detailed build options
3. 🧪 Read [TESTING.md](TESTING.md) for testing procedures

### For Contributors:
1. ✅ Set up development environment (`make dev-setup`)
2. 📖 Read [CONTRIBUTING.md](CONTRIBUTING.md)
3. 🎯 Pick an issue or feature to work on
4. 🔨 Make your first PR!

### For Advanced Users:
1. 🚀 Try building the full ISO
2. 🔧 Customize a profile in `build/build.conf`
3. 📦 Create additional TCZ packages
4. 🧪 Test in real hardware

## Resources

- **Documentation**: [docs/INDEX.md](docs/INDEX.md)
- **Build Guide**: [BUILD.md](BUILD.md)
- **Testing Guide**: [TESTING.md](TESTING.md)
- **Contribution Guide**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Tiny Core Linux**: https://tinycorelinux.net

## Support the Project

- ⭐ Star the repository
- 🐛 Report bugs
- 💡 Suggest features
- 🔨 Submit PRs
- 📖 Improve documentation
- 💬 Help others in discussions

---

**Welcome to VirtOS!** 🎉

Get started in 2 minutes: `make packages`
