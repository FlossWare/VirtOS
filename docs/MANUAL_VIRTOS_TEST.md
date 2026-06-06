# Manual VirtOS Testing Instructions

## The Problem

Automated serial console testing doesn't work well because:
- Tiny Core doesn't output to serial by default (needs kernel param `console=ttyS0`)
- Interactive shell needs TTY
- Expect/pexpect not installed on this system

## The Solution: Manual Testing

Test VirtOS by actually using it. Here's how:

### Option 1: Graphical QEMU (Easiest)

```bash
cd /home/sfloess/Development/github/FlossWare/VirtOS

qemu-system-x86_64 \
  -enable-kvm \
  -m 2048 \
  -cdrom build/output/VirtOS-0.89-alpha-standard-20260606.iso \
  -boot d
```

This opens a window with the VirtOS display.

**What to do:**
1. Window opens showing "FlossWare VirtOS v0.89-alpha"
2. Press **Enter** to boot
3. Wait ~15 seconds for Tiny Core to load
4. You'll see a desktop OR a terminal prompt
5. If desktop: Right-click → System Tools → Terminal
6. If terminal: You're already at the prompt (user: tc)

### Test Commands

Once you have a shell prompt, run:

```bash
# Test 1: Check version file
cat /etc/virtos/version.txt

# Expected:
# FlossWare VirtOS
# Version: 0.89
# Build Date: Thu Jun  6 12:45:23 PM PDT 2026
# Based on: Tiny Core Linux 15.x


# Test 2: Count VirtOS scripts
ls -1 /usr/local/bin/virtos-* | wc -l

# Expected: 55


# Test 3: Test version consistency
virtos-create-vm --version
virtos-network --version  
virtos-backup --version

# Expected for all:
# VirtOS <Command Name> v0.89


# Test 4: Test help output
virtos-create-vm --help

# Expected: Full usage text with examples


# Test 5: Test security validation
virtos-create-vm --name "test;rm -rf /"

# Expected:
# Error: Invalid VM name: test;rm -rf /
# VM names can only contain: letters, numbers, hyphens, underscores, dots


# Test 6: Test library loading
echo "Testing library is loaded..." && \
virtos-create-vm --help | grep -q "Usage:" && \
echo "✅ Library loaded successfully"

# Expected: ✅ Library loaded successfully


# Test 7: Check libvirt
which virsh
virsh --version

# Expected: 
# /usr/local/bin/virsh (or path to virsh)
# 12.0.0 (or version number)


# Test 8: Check QEMU
which qemu-system-x86_64
qemu-system-x86_64 --version

# Expected:
# Path to qemu
# QEMU emulator version ...


# Test 9: Test dry run (won't create actual VM)
virtos-create-vm \
  --name test-vm \
  --cpu 2 \
  --ram 1024 \
  --disk 10G \
  --os ubuntu-22.04 \
  --dry-run

# Expected: Shows what it would do without actually doing it
```

### What We're Validating

| Test | What It Proves | Status |
|------|----------------|--------|
| Version file | Build customization worked | ⏳ |
| Script count | All scripts installed | ⏳ |
| Version flags | Systematic fix #1 worked | ⏳ |
| Help output | Scripts are functional | ⏳ |
| Security validation | virtos-common.sh loaded | ⏳ |
| Library loading | Multi-path resolution works | ⏳ |
| virsh present | libvirt integration | ⏳ |
| QEMU present | Backend tools available | ⏳ |
| Dry run | Actual VM creation logic | ⏳ |

### Success Criteria

For runtime testing to be "COMPLETE":
- [ ] Shell prompt accessible
- [ ] virtos-* scripts present (55 expected)
- [ ] Version numbers correct (0.89)
- [ ] Security validation works (rejects malicious input)
- [ ] Help system works
- [ ] Library loading works
- [ ] virsh available
- [ ] QEMU available
- [ ] Can run virtos-create-vm in dry-run mode

**Current:** 0/9 complete (boot works, shell not yet tested)

### Alternative: VNC Access

If you're on a headless server:

```bash
qemu-system-x86_64 \
  -enable-kvm \
  -m 2048 \
  -cdrom build/output/VirtOS-0.89-alpha-standard-20260606.iso \
  -boot d \
  -vnc :1 \
  -daemonize

# Then connect with VNC viewer to localhost:5901
```

### What to Report Back

After testing, let me know:

1. **Did it boot to a shell?** (Yes/No)
2. **Script count:** (number from `ls -1 /usr/local/bin/virtos-* | wc -l`)
3. **Version check:** (output of `virtos-create-vm --version`)
4. **Security test:** (does it reject `"test;rm -rf /"`?)
5. **Any errors:** (paste any error messages)

### Next Steps

After manual testing confirms everything works:
1. Document the results
2. Update CLAUDE.md to remove "untested" warnings
3. Create runtime test report
4. Plan hardware testing

---

**Why Manual Testing:**

Automated serial console testing is hard because:
- Needs kernel parameter changes (`console=ttyS0`)
- Requires rebuilding ISO
- Adds complexity

Manual testing is:
- Fast (2 minutes to run tests)
- Reliable (you see exactly what happens)
- Complete (tests the actual user experience)

**The ISO boots. Now we need a human to use it.**
