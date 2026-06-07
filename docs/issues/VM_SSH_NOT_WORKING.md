# Issue: SSH Not Working on Created VMs

**Created**: 2026-06-06  
**Severity**: Critical  
**Component**: virtos-create-vm  
**Status**: Root cause identified, fix implemented

## Problem Description

VMs created with `virtos-create-vm` do not have SSH access working. Attempts to SSH into created VMs fail because there is no SSH server running.

## Root Cause Analysis

### Core Issue

**`virtos-create-vm` creates VMs with empty hard disk images that have no operating system installed.**

The script performs the following:

1. **Line 681**: Creates a blank qcow2 disk image: `qemu-img create -f qcow2 "$VM_DIR/$NAME.qcow2" "$DISK"`
2. **Lines 546-675**: Generates VM XML configuration with `<boot dev='hd'/>` pointing to the empty disk
3. **Line 688**: Defines the VM in libvirt with the empty disk

### Why SSH Doesn't Work

1. **No OS installed**: The hard disk is completely empty (no filesystem, no kernel, nothing)
2. **No boot capability**: VM cannot boot because there's nothing to boot from
3. **No SSH daemon**: Even if it could boot, no SSH server software is installed
4. **No network configuration**: No network stack configured

This is equivalent to:
- Buying a brand new computer with a blank hard drive
- Turning it on
- Expecting to SSH into it

Without an operating system, there's nothing to run SSH.

## Current Behavior

```bash
$ virtos-create-vm --name test-vm --cpu 2 --ram 4096 --disk 20G
# Creates VM successfully
# VM defined in libvirt

$ virsh start test-vm
# VM starts but...
# - No OS boots
# - Black screen / boot failure
# - No SSH service available
# - Cannot connect via SSH

$ ssh test-vm
# Connection refused or timeout (no SSH server)
```

## Expected Behavior

```bash
$ virtos-create-vm --name test-vm --cpu 2 --ram 4096 --disk 20G --iso /path/to/virtos.iso --ssh-key ~/.ssh/id_rsa.pub
# Creates VM with VirtOS ISO attached
# VM defined in libvirt with CDROM boot

$ virsh start test-vm
# VM starts
# Boots from VirtOS ISO (Tiny Core Linux)
# SSH daemon starts automatically
# SSH key is pre-configured

$ ssh tc@<vm-ip>
# Successfully connects via SSH!
```

## Solution Implemented

### Changes to `virtos-create-vm`

**1. Added `--iso` parameter** (lines 42, 116):
```bash
--iso <path>           ISO file to boot from (e.g., VirtOS ISO)
```

**2. Added `--ssh-key` parameter** (lines 43, 117):
```bash
--ssh-key <path>       SSH public key to install (default: ~/.ssh/id_rsa.pub)
```

**3. Modified VM XML to boot from CDROM first** (line 657):
```xml
<boot dev='cdrom'/>  <!-- Boot from ISO first -->
<boot dev='hd'/>     <!-- Fall back to hard disk -->
```

**4. Added CDROM device to VM XML** (lines 670-677):
```xml
<disk type='file' device='cdrom'>
  <driver name='qemu' type='raw'/>
  <source file='$BOOT_ISO'/>
  <target dev='hdc' bus='ide'/>
  <readonly/>
</disk>
```

**5. Added serial console support** (lines 686-692):
```xml
<serial type='pty'>
  <target port='0'/>
</serial>
<console type='pty'>
  <target type='serial' port='0'/>
</console>
```

### Usage After Fix

**Option 1: Boot from VirtOS ISO** (Recommended)
```bash
# Build VirtOS ISO (if not already built)
cd build && ./scripts/build-all.sh

# Create VM with VirtOS ISO
virtos-create-vm \
  --name web-1 \
  --cpu 2 \
  --ram 4096 \
  --disk 20G \
  --iso /path/to/virtos-0.1.iso \
  --ssh-key ~/.ssh/id_rsa.pub \
  --auto-start
```

**Option 2: Use cloud-init for SSH configuration**
```bash
# Create cloud-init configuration with SSH key
virtos-cloud-init create web-1 \
  --hostname web-server \
  --user admin \
  --ssh-key ~/.ssh/id_rsa.pub

# Generate cloud-init ISO
virtos-cloud-init generate web-1

# Create VM with cloud-init ISO
virtos-create-vm \
  --name web-1 \
  --cpu 2 \
  --ram 4096 \
  --disk 20G \
  --iso /var/lib/virtos/cloud-init/web-1-cloud-init.iso \
  --auto-start
```

**Option 3: Use OS template (when available)**
```bash
# Use pre-built OS template
virtos-create-vm \
  --name web-1 \
  --cpu 2 \
  --ram 4096 \
  --disk 20G \
  --os ubuntu-22.04 \
  --auto-start
```

## Remaining Work

### Short Term (Critical)

- [ ] **Test the fix**: Verify VMs boot from VirtOS ISO successfully
- [ ] **Validate SSH access**: Confirm SSH connections work after boot
- [ ] **Document new parameters**: Update user guide with `--iso` and `--ssh-key` usage
- [ ] **Update examples**: Add working examples to documentation

### Medium Term (Important)

- [ ] **Integrate cloud-init automatically**: Auto-generate cloud-init ISO if `--ssh-key` specified
- [ ] **Auto-detect VirtOS ISO**: If `--iso` not specified, look for VirtOS ISO in standard locations:
  - `/var/lib/virtos/iso/virtos-latest.iso`
  - `/opt/virtos/virtos.iso`
  - `$PROJECT_ROOT/build/output/virtos-*.iso`
- [ ] **Add warning for missing ISO**: Warn users if creating VM without bootable media

### Long Term (Enhancement)

- [ ] **Create VM template system**: Build library of pre-configured OS images
  - Ubuntu Server templates
  - Debian templates
  - Alpine Linux templates
  - VirtOS base template
- [ ] **Implement PXE boot option**: Network boot for automated OS installation
- [ ] **Add `--download-iso` option**: Auto-download cloud images:
  ```bash
  virtos-create-vm --name web-1 --cpu 2 --ram 4096 --disk 20G --download-iso ubuntu-22.04
  ```

## Verification Steps

1. **Build VirtOS ISO** (if not already built):
   ```bash
   cd build
   ./scripts/build-all.sh
   ls -lh output/virtos-*.iso
   ```

2. **Create test VM with ISO**:
   ```bash
   virtos-create-vm \
     --name ssh-test \
     --cpu 1 \
     --ram 2048 \
     --disk 10G \
     --iso build/output/virtos-0.1.iso \
     --ssh-key ~/.ssh/id_rsa.pub \
     --auto-start \
     --require localhost
   ```

3. **Wait for boot** (30-60 seconds)

4. **Find VM IP address**:
   ```bash
   virsh domifaddr ssh-test
   # or
   virsh net-dhcp-leases default
   ```

5. **Test SSH connection**:
   ```bash
   ssh tc@<vm-ip>
   # Should connect successfully!
   ```

6. **Verify VirtOS commands available**:
   ```bash
   ssh tc@<vm-ip> 'virtos-tui --version'
   ssh tc@<vm-ip> 'virtos-cluster --version'
   ```

## Related Issues

- Issue #1: Runtime testing documentation (needs ISO for testing)
- Issue #3: ISO build testing (ISO is prerequisite for VM SSH)
- Issue #51: Integration test framework (tests need bootable VMs)
- PR #XXXX: Fix virtos-create-vm SSH support (this fix)

## Technical Details

### Files Modified

- `config/custom-scripts/virtos-create-vm` (lines 34-43, 90-130, 651-695)

### Dependencies

- **VirtOS ISO**: Required for boot (built via `build/scripts/build-all.sh`)
- **libvirt**: VM management (already required)
- **qemu-img**: Disk image creation (already required)
- **virtos-cloud-init**: Optional, for advanced SSH/user configuration

### Compatibility

- **Backwards compatible**: Old command syntax still works (but creates non-bootable VMs)
- **New parameters are optional**: If `--iso` not specified, VM is created as before (empty disk)
- **No breaking changes**: Existing workflows unaffected

## References

- [VirtOS Build System](../BUILD_SYSTEM.md)
- [VirtOS Cloud-Init Integration](../CLOUD_INIT_GUIDE.md)
- [VM Creation Guide](../guides/VM_CREATION.md)
- [Tiny Core Linux Documentation](http://tinycorelinux.net/)
- [libvirt Domain XML Format](https://libvirt.org/formatdomain.html)

---

**Status**: ✅ Fix implemented, pending testing  
**Priority**: P0 (Critical - blocks all VM functionality)  
**Assignee**: Pending  
**Labels**: bug, critical, vm-management, ssh, documentation
