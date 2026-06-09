# VirtOS Quick Start Guide

Get up and running with VirtOS in 5 minutes.

---

## Table of Contents

- [For Users: Try VirtOS](#for-users-try-virtos) - Build packages or ISO
- [For Runtime Users: Your First VM](#for-runtime-users-your-first-vm) - Use VirtOS to create VMs
- [For Contributors: Start Developing](#for-contributors-start-developing) - Contribute to VirtOS
- [Common Tasks](#common-tasks) - Build, test, validate
- [Cheat Sheet](#cheat-sheet) - Quick reference for VM/container operations

---

## For Users: Try VirtOS

### Option 1: Build a Package (2 minutes) ✅ TESTED

Build the virtos-tools package containing all management scripts:

```bash
# 1. Clone
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS

# 2. Build package
make packages

# Done! Package built: packages/output/virtos-tools.tcz (336K)
```

**What you get:** A working Tiny Core Linux package with 38 packaged management utilities. 14 experimental scripts archived (2026-06-09 cleanup).

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

---

## For Runtime Users: Your First VM

**Prerequisites**: VirtOS installed and running on a host system.  
**Time to complete**: 15-20 minutes

### Verify VirtOS is Ready

```bash
# Check VirtOS version
virtos-setup --version
# Expected: VirtOS 0.89

# Check virtualization
virsh version
# Expected: libvirt 9.0.0+, QEMU 7.2.0+

# Verify resources
virtos-monitor resources
# Expected: CPU, RAM, disk available
```

### Create Your First VM

#### Using virtos-create-vm (Recommended)

```bash
# Create a VM for Ubuntu Server
virtos-create-vm \
    --name ubuntu-server-01 \
    --cpu 2 \
    --ram 4096 \
    --disk 20G \
    --os linux \
    --iso ~/iso/ubuntu-22.04-live-server-amd64.iso

# Output:
# Creating VM: ubuntu-server-01
# CPU: 2 cores, RAM: 4096 MB, Disk: 20 GB
# VM created successfully
#
# Next steps:
# - Start VM: virsh start ubuntu-server-01
# - Console: virsh console ubuntu-server-01
# - VNC port: 5900
```

#### Using virtos-tui (Interactive Menu)

```bash
# Launch VirtOS menu
sudo virtos-tui
```

Navigate to **VM Management** → **Create New VM** and fill in:

- VM Name: ubuntu-server-01
- CPUs: 2
- Memory (MB): 4096
- Disk Size (GB): 20
- OS Type: linux
- ISO Path: /path/to/ubuntu.iso

### Start and Connect to the VM

```bash
# Start the VM
virsh start ubuntu-server-01

# Verify it's running
virsh list

# Connect via VNC (GUI)
virsh vncdisplay ubuntu-server-01
# Output: :0 (port 5900)
# Connect from your workstation: VNC to <host-ip>:5900

# OR connect via serial console (text)
virsh console ubuntu-server-01
# To exit: Ctrl + ]
```

### Manage Your VM

```bash
# View VM details
virsh dominfo ubuntu-server-01

# Monitor VM performance
virtos-monitor status ubuntu-server-01

# Create snapshot
virtos-snapshot create ubuntu-server-01 fresh-install

# Create backup
virtos-backup create-backup ubuntu-server-01 daily

# Stop VM
virsh shutdown ubuntu-server-01

# Force stop
virsh destroy ubuntu-server-01

# Delete VM (WARNING: destructive!)
virsh undefine ubuntu-server-01 --remove-all-storage
```

### Next Steps for Runtime Users

- **Clone VMs**: Use `virtos-template` to create templates and clone VMs
- **Containers**: Run Docker/Podman containers alongside VMs
- **Cloud-Init**: Automate VM setup with `virtos-cloud-init`
- **Networks**: Create isolated networks with `virtos-network`
- **Storage**: Organize disks with `virtos-storage`
- **Clustering**: Connect multiple hosts with `virtos-cluster`

See [Cheat Sheet](#cheat-sheet) below for common commands.

---

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
│   ├── custom-scripts/ # All virtos-* management tools (38 packaged scripts)
│   └── profiles/       # Build profiles (minimal, standard, full, etc.)
├── docs/               # Documentation (19 markdown files)
├── kernel/             # Kernel configurations
├── packages/           # TCZ package definitions
│   ├── virtos-tools/   # Management tools package
│   └── output/         # Built packages
├── docs/BUILD.md       # Detailed build guide
├── TESTING.md          # Testing procedures
├── CONTRIBUTING.md     # Contribution guidelines
└── README.md           # Project overview
```

### Key Files

- **Makefile** - Convenience targets for common operations
- **docs/BUILD.md** - Complete build documentation and status
- **TESTING.md** - Testing guide (6 levels of testing)
- **CONTRIBUTING.md** - How to contribute
- **build/build.conf** - Build configuration (edit profiles here)

### What Works Now (June 2026)

✅ **Package Building** - Creates real TCZ packages  
✅ **Build Validation** - Checks prerequisites automatically  
✅ **Quick Testing** - 5-second validation  
✅ **Syntax Checking** - All scripts validated  
✅ **CI/CD** - GitHub Actions on every commit  
✅ **Infrastructure Validated** - 5-node physical cluster deployment (2026-06-06), 96% test pass rate  
✅ **Documentation** - Comprehensive guides and references

See [docs/BUILD.md](docs/BUILD.md) for detailed status.

## Development Workflow

### Typical contribution flow

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

### Before committing

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

### The git pre-commit hook (if you ran `make dev-setup`) automatically runs `make check`

## Getting Help

### Documentation

- **Quick Start** - This file
- **Build Guide** - [docs/BUILD.md](docs/BUILD.md)
- **Testing** - [TESTING.md](TESTING.md)
- **Contributing** - [CONTRIBUTING.md](CONTRIBUTING.md)
- **API Docs** - [docs/](docs/)

### Commands

```bash
make help          # Show all make targets
./script --help    # Help for any virtos-* script
```

### Community

- **Issues**: <https://github.com/FlossWare/VirtOS/issues>
- **Discussions**: <https://github.com/FlossWare/VirtOS/discussions>
- **PRs**: <https://github.com/FlossWare/VirtOS/pulls>

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

## Cheat Sheet

### VM Management

```bash
virsh list --all                        # List all VMs
virsh start <vm>                        # Start VM
virsh shutdown <vm>                     # Shutdown VM (graceful)
virsh destroy <vm>                      # Force stop
virsh reboot <vm>                       # Restart VM
virsh suspend <vm>                      # Pause VM
virsh resume <vm>                       # Resume paused VM
virsh console <vm>                      # Connect to console (Ctrl+] to exit)
virsh dominfo <vm>                      # Show VM details
virsh domifaddr <vm>                    # Get VM IP address
```

### Containers (Docker/Podman)

```bash
# Docker
docker pull nginx:latest
docker run -d --name web -p 8080:80 nginx:latest
docker ps                               # List running containers
docker logs web                         # View logs
docker stop web                         # Stop container
docker rm web                           # Remove container

# Podman (rootless)
podman pull nginx:latest
podman run -d --name web -p 8080:80 nginx:latest
podman ps
podman exec -it web /bin/bash          # Enter container shell
podman stop web
podman rm web
```

### Networking

```bash
virtos-network list                     # List networks
virtos-network create-nat <name> <cidr> # Create NAT network
virtos-network bridge-create <name>     # Create bridge
virtos-network bridge-attach <vm> <net> # Attach VM to network
```

### Storage

```bash
virtos-storage list-pools               # List storage pools
virtos-storage create-pool <name> dir <path>
virtos-storage list-volumes <pool>      # List volumes
```

### Snapshots & Backups

```bash
virtos-snapshot create <vm> <name>      # Create snapshot
virtos-snapshot list <vm>               # List snapshots
virtos-snapshot revert <vm> <name>      # Revert to snapshot
virtos-snapshot delete <vm> <name>      # Delete snapshot
virtos-backup create-backup <vm> <tag>  # Create backup
virtos-backup list-backups <vm>         # List backups
virtos-backup restore-backup <vm> <id>  # Restore backup
```

### Monitoring

```bash
virtos-monitor status <vm>              # VM metrics
virtos-monitor resources                # Host resources
virsh domstats <vm>                     # Detailed VM stats
```

### Templates & Automation

```bash
# Create template from VM
virtos-template create-template <vm> <template-name>

# Clone from template
virtos-template instantiate <template> <new-vm-name>

# Automated VM with cloud-init
virtos-cloud-init create-vm \
    --name auto-vm \
    --cpu 2 \
    --ram 2048 \
    --disk 20G \
    --cloud-init /path/to/cloud-init.yaml
```

### Clustering

```bash
virtos-cluster discover                 # Discover cluster nodes
virtos-cluster list-nodes               # List cluster members
virtos-migrate <vm> <destination>       # Live migrate VM
```

## Next Steps

### For Users

1. ✅ Build a package (`make packages`)
2. 📖 Read [docs/BUILD.md](docs/BUILD.md) for detailed build options
3. 🧪 Read [TESTING.md](TESTING.md) for testing procedures

### For Runtime Users

1. ✅ Create your first VM (see [Your First VM](#for-runtime-users-your-first-vm))
2. 📖 Read [docs/QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md) for administrator guide
3. 🐛 Report issues at [GitHub](https://github.com/FlossWare/VirtOS/issues)

### For Contributors

1. ✅ Set up development environment (`make dev-setup`)
2. 📖 Read [CONTRIBUTING.md](CONTRIBUTING.md)
3. 🎯 Pick an issue or feature to work on
4. 🔨 Make your first PR!

### For Advanced Users

1. 🚀 Try building the full ISO
2. 🔧 Customize a profile in `build/build.conf`
3. 📦 Create additional TCZ packages
4. 🧪 Test in real hardware

## Resources

- **Documentation**: [docs/INDEX.md](docs/INDEX.md)
- **Build Guide**: [docs/BUILD.md](docs/BUILD.md)
- **Testing Guide**: [TESTING.md](TESTING.md)
- **Contribution Guide**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Tiny Core Linux**: <https://tinycorelinux.net>

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
