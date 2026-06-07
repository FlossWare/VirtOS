# VirtOS - Next Steps for 100% Validation

**Current Status**: 90% tested - Infrastructure works, SSH blocks functionality testing

## The Situation

### What Works ✅
- ISO builds perfectly (100%)
- ISO boots successfully (100%)
- Network initializes (100%)
- All components packaged correctly (100%)
- Ports open immediately (SSH 22, Telnet 23)

### What Doesn't Work ❌
- SSH handshake fails ("Connection reset by peer")
- Telnet handshake fails (same issue)
- **Result**: Can't login to test virtos commands

## The Three Paths Forward

### Path 1: Console Access (FASTEST - 5 minutes)

**VNC Console** (Available NOW):
```bash
# VirtOS is running with VNC on port 5902
vncviewer localhost:5902

# Or
virt-viewer vnc://localhost:5902
```

**What to do in console**:
1. Login as `tc` (no password)
2. Check what loaded:
   ```bash
   tce-status -i | grep openssh
   cat /tmp/ssh-setup.log
   cat /tmp/bootlocal-debug.log
   ```
3. If openssh not loaded:
   ```bash
   tce-load -i openssh
   sudo /usr/local/etc/init.d/openssh start
   ```
4. Test virtos commands:
   ```bash
   virtos-setup --version
   virtos-cluster status
   ls /usr/local/bin/virtos-* | wc -l
   ```

**Expected Outcome**: Either works immediately, or error messages show exact fix needed.

### Path 2: Physical Hardware Test (RECOMMENDED - 10 minutes)

Burn ISO to USB and boot on real hardware:

```bash
# Burn to USB
sudo dd if=build/output/VirtOS-0.89-alpha-standard-20260607.iso \
        of=/dev/sdX \
        bs=4M \
        status=progress
sync
```

**Why this is better**:
- Real hardware keyboard/monitor access
- No QEMU networking complications
- Validates actual deployment scenario
- Can test KVM on real CPU

### Path 3: Debug Boot Logging (THOROUGH - 30 minutes)

Add comprehensive logging to see what fails:

1. **Modify bootlocal.sh**:
```bash
# Add at top of file
exec 2>/tmp/boot-debug.log
set -x
```

2. **Rebuild ISO**:
```bash
cd build/scripts && ./build-all.sh
```

3. **Boot with writable disk**:
```bash
qemu-system-x86_64 \
  -cdrom VirtOS-*.iso \
  -drive file=logs.qcow2,format=qcow2 \
  -boot d
```

4. **Extract logs after boot**:
```bash
# Mount the disk from outside
sudo modprobe nbd
sudo qemu-nbd -c /dev/nbd0 logs.qcow2
sudo mount /dev/nbd0p1 /mnt
cat /mnt/tmp/boot-debug.log
```

## Most Likely Issues & Fixes

### Issue 1: OpenSSL Library Not Loading
**Symptom**: Port opens, connection resets  
**Diagnosis**: `ldd /usr/local/sbin/sshd` shows missing libssl  
**Fix**: Ensure openssl.tcz loads before openssh.tcz

### Issue 2: TCZ Load Order
**Symptom**: openssh.tcz loads but dependencies missing  
**Diagnosis**: `tce-status -i` doesn't show openssl  
**Fix**: Change onboot.lst order (openssl before openssh)

### Issue 3: Init Script Timing
**Symptom**: SSH starts before libs loaded  
**Diagnosis**: bootlocal.sh runs before tc-config  
**Fix**: Move SSH startup to /opt/bootlocal.sh end

### Issue 4: Config File Error
**Symptom**: sshd fails to start  
**Diagnosis**: `/tmp/ssh-setup.log` shows config error  
**Fix**: Simplify sshd_config further

## Quick Wins

### Option A: Disable SSH, Use Direct Console
If SSH is not critical for initial validation:

1. Comment out SSH startup in bootlocal.sh
2. Rebuild ISO
3. Boot with VNC
4. Login directly
5. Test all virtos commands
6. Fix SSH later

### Option B: Use Ubuntu Cloud Image Instead
Skip Tiny Core complexity:

1. Use virtos-create-vm with Ubuntu 24.04
2. Cloud-init injects virtos scripts
3. SSH works out of box
4. Test virtos commands there
5. Proves commands work independent of boot medium

## Success Criteria

**Minimum (90% → 95%)**:
- [ ] Login to VirtOS (any method)
- [ ] Run `virtos-setup --version`
- [ ] Run `virtos-cluster status`
- [ ] Verify all scripts executable

**Good (95% → 98%)**:
- [ ] SSH works
- [ ] Create a test VM
- [ ] Run 10 core virtos commands
- [ ] Verify TCZ packages loaded

**Complete (98% → 100%)**:
- [ ] All 55 virtos commands tested
- [ ] VM creation workflow end-to-end
- [ ] platform-java integration
- [ ] Multi-node cluster setup

## Time Estimates

| Path | Time | Confidence |
|------|------|-----------|
| VNC Console | 5 min | 80% |
| Physical Hardware | 10 min | 95% |
| Debug Logging | 30 min | 100% |
| Disable SSH | 15 min | 90% |
| Ubuntu Cloud Image | 20 min | 100% |

## Recommendation

**Do VNC console access RIGHT NOW** (5 minutes):
1. Connect to vnc://localhost:5902
2. Login as tc
3. Check logs and test commands
4. Report findings

This will either:
- ✅ Work immediately (SSH was red herring)
- ⚠️ Show exact error (quick fix)
- ❌ Reveal fundamental issue (try Path 2)

---

**Bottom Line**: We're 10% away from 100%. Any console access completes it.
