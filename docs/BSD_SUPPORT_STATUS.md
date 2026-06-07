# BSD Support Status

**Date**: 2026-06-06
**Status**: ❌ NOT SUPPORTED (Linux-only)
**Target**: Add BSD support in future release

## Current Situation

VirtOS is currently **Linux-only** and will NOT work on BSD systems.

### Shell Compatibility

Scripts use mixed shebangs:
- **Most scripts**: `#!/bin/bash` (Bash-specific)
- **Few scripts**: `#!/bin/sh` (POSIX-compatible)

**Issue**: BSD systems often use `/bin/sh` → dash/ash, not bash
**Fix needed**: Make all scripts POSIX sh-compliant OR ensure bash available

### Linux-Specific Commands Found

**Networking** (`virtos-network`):
```bash
ip link show
ip link add
ip link set
ip link delete
```
**BSD equivalent**: `ifconfig`

**Process/System** (various scripts):
- `/proc` filesystem → BSD uses `sysctl`
- `systemctl` → BSD uses `service` or `rc.d`

**Virtualization**:
- `libvirt/virsh` → Available on FreeBSD
- `qemu` → Available on all BSDs
- `KVM` → Linux-only (BSD uses `bhyve` on FreeBSD)

## What Works on BSD (Potentially)

✅ **Scripts with POSIX sh**:
- virtos-audit (#!/bin/sh)
- virtos-cluster (#!/bin/sh)

✅ **Technologies available on BSD**:
- QEMU (all BSDs)
- libvirt (FreeBSD, limited on OpenBSD/NetBSD)
- Docker via Linux compat layer (FreeBSD only)

## What DOES NOT Work on BSD

❌ **KVM** - Linux kernel module, no BSD equivalent
  - FreeBSD alternative: bhyve
  - OpenBSD alternative: vmm(4)
  - NetBSD alternative: nvmm

❌ **`ip` command** - iproute2 is Linux-only
  - BSD uses: ifconfig, route, netstat

❌ **`/proc` filesystem** - Linux-specific
  - BSD uses: sysctl, procstat

❌ **systemd/systemctl** - Linux init system
  - BSD uses: rc.d, service

❌ **Bash-specific scripts** (45+ scripts)
  - Need POSIX sh conversion or bash installed

## BSD Support Roadmap

### Phase 1: Make Scripts Portable (Est: 2-4 weeks)

1. **Convert shebangs** to `#!/bin/sh`
2. **Remove bashisms**:
   - `[[` → `[`
   - `$((arithmetic))` is OK
   - Arrays → alternative approach
   - Process substitution → temp files

3. **Add OS detection**:
```bash
OS="$(uname -s)"
case "$OS" in
    Linux)
        NET_CMD="ip"
        ;;
    FreeBSD|OpenBSD|NetBSD)
        NET_CMD="ifconfig"
        ;;
esac
```

4. **Abstract OS-specific commands**:
```bash
get_ip_address() {
    case "$OS" in
        Linux)
            ip addr show "$iface"
            ;;
        FreeBSD|OpenBSD|NetBSD)
            ifconfig "$iface"
            ;;
    esac
}
```

### Phase 2: Hypervisor Abstraction (Est: 4-6 weeks)

1. **Detect available hypervisor**:
   - Linux: KVM
   - FreeBSD: bhyve
   - OpenBSD: vmm
   - NetBSD: nvmm

2. **Create abstraction layer**:
   - virtos-hypervisor-kvm
   - virtos-hypervisor-bhyve
   - virtos-hypervisor-vmm
   - virtos-hypervisor-nvmm

3. **Unified API** for VM operations

### Phase 3: Testing (Est: 2-3 weeks)

1. Test on FreeBSD 14
2. Test on OpenBSD 7.x
3. Test on NetBSD 10.x
4. Document BSD-specific installation

## Immediate Actions for BSD Support

**User requested**: "make sure you supports the bsds"

**Response**: Currently NO BSD support. To add it:

1. **Audit all 54 scripts** for Linux-isms
2. **Convert to POSIX sh** (remove bashisms)
3. **Add OS detection** wrapper functions
4. **Test on FreeBSD** (most popular BSD)
5. **Document limitations** (no KVM, use bhyve instead)

**Estimated effort**: 8-13 weeks for full BSD support

## Alternative: BSD-Specific Fork

Instead of making VirtOS cross-platform, could create:
- **VirtOS-Linux** (current, KVM-based)
- **VirtOS-BSD** (bhyve-based for FreeBSD)

This avoids complexity of abstraction layer.

## Recommendation

1. **Short term**: Document as Linux-only
2. **Medium term**: Make scripts POSIX-compliant
3. **Long term**: Add hypervisor abstraction for BSD

**Priority**: LOW - Focus on Linux functionality first, BSD later

---

**Status**: BSD support is NOT currently available and requires significant work.
**Tracking**: Created task #40 for BSD support
