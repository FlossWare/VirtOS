# Testing Guide for VirtOS

This document describes how to test VirtOS at various stages of development.

## Testing Levels

### Level 0: Pre-Build Validation

Verify project structure and dependencies before building.

```bash
# Check all required directories exist
test -d build && test -d config && test -d docs && echo "✓ Structure OK" || echo "✗ Missing directories"

# Verify build scripts are executable
test -x build/scripts/build-all.sh && echo "✓ Build scripts executable" || echo "✗ Fix permissions"

# Check for required tools (on build host)
command -v git >/dev/null 2>&1 && echo "✓ git installed" || echo "✗ Install git"
command -v bash >/dev/null 2>&1 && echo "✓ bash installed" || echo "✗ Install bash"

# Validate script syntax
for script in config/custom-scripts/virtos-*; do
    bash -n "$script" && echo "✓ $script syntax OK" || echo "✗ $script has syntax errors"
done
```

### Level 1: Build Tests

Validate the build process completes successfully.

```bash
# Test build configuration
cd build
./scripts/prepare.sh
echo "✓ Preparation completed"

# Validate build.conf
test -f build.conf && source build.conf && echo "✓ build.conf valid" || echo "✗ build.conf missing/invalid"

# Test profile loading
for profile in ../config/profiles/*.conf; do
    source "$profile" && echo "✓ $(basename $profile) loads" || echo "✗ $(basename $profile) failed"
done

# Full build test (requires Tiny Core Linux build environment)
# ./scripts/build-all.sh
# test -f output/FlossWare-Virt-*.iso && echo "✓ ISO built" || echo "✗ Build failed"
```

### Level 2: Smoke Tests

Verify the ISO boots and basic functionality works.

#### Boot Test
```bash
# Boot ISO in QEMU (no KVM for compatibility)
qemu-system-x86_64 -m 2048 -cdrom output/FlossWare-Virt-*.iso -boot d

# Expected results:
# - System boots in < 30 seconds
# - Login prompt appears
# - Default credentials work (tc/tc or as configured)
```

#### Basic Commands Test
```bash
# After booting, test basic commands exist
command -v virtos-setup && echo "✓ virtos-setup present" || echo "✗ Missing"
command -v virtos-tui && echo "✓ virtos-tui present" || echo "✗ Missing"
command -v virtos-cluster && echo "✓ virtos-cluster present" || echo "✗ Missing"

# Check KVM module
lsmod | grep kvm && echo "✓ KVM module loaded" || echo "✗ KVM not available"

# Check for /dev/kvm
test -e /dev/kvm && echo "✓ /dev/kvm exists" || echo "✗ KVM device missing"
```

### Level 3: Integration Tests

Test actual virtualization functionality.

#### KVM/QEMU Test
```bash
# Test QEMU installation
qemu-system-x86_64 --version && echo "✓ QEMU installed" || echo "✗ QEMU missing"

# Test libvirt
virsh --version && echo "✓ libvirt installed" || echo "✗ libvirt missing"

# List VMs (should work even if empty)
virsh list --all && echo "✓ libvirt functional" || echo "✗ libvirt not working"

# Create test VM (requires ISO or disk image)
# virsh define test-vm.xml
# virsh start test-vm
# virsh destroy test-vm
# virsh undefine test-vm
```

#### LXC Test
```bash
# Check LXC installation
lxc-info --version && echo "✓ LXC installed" || echo "✗ LXC missing"

# Test LXC bridge
ip link show lxcbr0 && echo "✓ LXC bridge exists" || echo "✗ LXC bridge missing"

# Create test container
# sudo lxc-create -n test-container -t download -- -d alpine -r 3.18 -a amd64
# sudo lxc-start -n test-container
# sudo lxc-stop -n test-container
# sudo lxc-destroy -n test-container
```

#### Container Runtime Test
```bash
# Test Docker (if included)
if command -v docker >/dev/null 2>&1; then
    docker --version && echo "✓ Docker installed"
    docker ps && echo "✓ Docker functional" || echo "✗ Docker not working"
    # docker run --rm hello-world && echo "✓ Docker can run containers"
fi

# Test Podman (if included)
if command -v podman >/dev/null 2>&1; then
    podman --version && echo "✓ Podman installed"
    podman ps && echo "✓ Podman functional" || echo "✗ Podman not working"
fi

# Test containerd (if included)
if command -v ctr >/dev/null 2>&1; then
    ctr --version && echo "✓ containerd installed"
fi
```

### Level 4: System Tests

Test complete workflows end-to-end.

#### Setup Wizard Test
```bash
# Run setup wizard in test mode
# sudo virtos-setup

# Expected:
# - TUI launches successfully
# - Can navigate all menus
# - Configuration saves to /etc/virtos/
# - Services can be enabled/disabled
```

#### Management TUI Test
```bash
# Launch management TUI
# virtos-tui

# Test each menu:
# 1. System Status - displays CPU, RAM, disk
# 2. VM Management - can list VMs
# 3. Container Management - can list containers
# 4. Storage - shows storage pools
# 5. Cluster Status - shows cluster state
# 6. Services - lists services
# 7. Logs - displays logs
```

#### Clustering Test
```bash
# On first host
virtos-cluster init
virtos-cluster status

# On second host (requires two VirtOS instances)
# virtos-cluster join virtos-1.local
# virtos-cluster list
```

#### Backup/Restore Test
```bash
# Create a test VM first
# virsh define test-vm.xml

# Backup test
# virtos-backup backup test-vm
# virtos-backup list
# virtos-backup verify <backup-id>

# Restore test
# virtos-backup restore test-vm <backup-id>
```

### Level 5: Performance Tests

Measure boot time, resource usage, and throughput.

```bash
# Boot time measurement
# time qemu-system-x86_64 ... (measure to login prompt)
# Target: < 10 seconds

# Memory footprint
free -h
# Target: Base system < 200MB RAM

# Disk usage
df -h /
# Target: Base system < 400MB disk

# VM creation time
# time virsh create test-vm.xml
# Target: < 5 seconds

# Container creation time
# time docker run -d nginx
# Target: < 2 seconds
```

### Level 6: Stress Tests

Test system under load.

```bash
# Create multiple VMs
# for i in {1..10}; do
#     virsh define vm-$i.xml
#     virsh start vm-$i
# done

# Create multiple containers
# for i in {1..20}; do
#     docker run -d --name web-$i nginx
# done

# Monitor system resources
# watch -n 1 "free -h && echo && virsh list --all && echo && docker ps"
```

## Automated Testing

### Unit Tests (To Be Added)

```bash
# Test individual functions in scripts
# Uses BATS (Bash Automated Testing System)

# bats tests/unit/virtos-cluster.bats
# bats tests/unit/virtos-backup.bats
```

### Integration Tests (To Be Added)

```bash
# Test component interactions
# Uses custom test framework

# tests/integration/vm-lifecycle.sh
# tests/integration/container-networking.sh
```

### CI/CD Tests

See `.github/workflows/ci.yml` for automated testing on every commit.

## Test Environments

### Minimal Test Environment
- **Purpose**: Quick validation
- **Resources**: 2GB RAM, 10GB disk
- **Profile**: minimal
- **Tests**: Levels 0-2

### Standard Test Environment
- **Purpose**: Full feature testing
- **Resources**: 4GB RAM, 50GB disk
- **Profile**: standard
- **Tests**: Levels 0-4

### Cluster Test Environment
- **Purpose**: Multi-host testing
- **Resources**: 3 hosts × 4GB RAM
- **Profile**: kubernetes
- **Tests**: Levels 0-5

## Test Checklist

Before each release:

- [ ] All build tests pass
- [ ] ISO boots successfully
- [ ] KVM module loads
- [ ] Can create a VM
- [ ] Can create a container
- [ ] TUI launches and is navigable
- [ ] Documentation is up to date
- [ ] No untracked files in git
- [ ] All scripts have execute permissions
- [ ] Syntax validation passes
- [ ] Boot time < 10 seconds
- [ ] Memory usage < 200MB idle

## Known Issues

Track testing issues here:

- **Build system**: Not yet fully implemented - requires Tiny Core build environment
- **KVM module**: Needs kernel configuration in `kernel/` directory
- **Management scripts**: Interfaces defined, backend integration pending
- **Clustering**: mDNS discovery needs Avahi configuration
- **Backup**: virtos-backup needs libvirt integration

## Contributing Tests

We need help with:
1. Creating BATS unit tests for individual scripts
2. Writing integration tests for VM/container workflows
3. Performance benchmarking scripts
4. Multi-host cluster testing procedures
5. Automated ISO build validation

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Test Reporting

When reporting test results, include:
- VirtOS version/commit hash
- Test environment (resources, profile)
- Test level attempted
- Expected vs. actual results
- Error messages and logs
- Steps to reproduce

File issues at: https://github.com/FlossWare/VirtOS/issues
