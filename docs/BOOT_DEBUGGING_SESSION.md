# VirtOS Boot Debugging Session - June 6, 2026

## Objective
Enable SSH access to VirtOS VMs for remote management and testing of virtos-* commands.

## Duration
15+ hours of intensive debugging

## Key Discoveries

### 1. Tiny Core Linux Boot Flow
- **rcS** → **tc-config** → **bootsync.sh** (line 646 of tc-config)
- **bootlocal.sh is NEVER automatically executed** by tc-config!
- Only bootsync.sh runs during boot
- dhcp.sh (called from tc-config) automatically brings up network via udhcpc

### 2. TCZ Package Loading
- Packages must be in `/tmp/tce/optional/` directory
- `onboot.lst` must be in `/tmp/tce/onboot.lst` (NOT `/opt/onboot.lst`)
- Tiny Core 15.0 does NOT auto-load from onboot.lst without boot parameters
- The `lst=` boot parameter does NOT exist in Tiny Core
- `pretce=RAM` boot parameter should work but appeared non-functional
- Manual `tce-load` calls required in bootsync.sh

### 3. Sudoers Ownership Critical
- `/etc/sudoers` MUST be owned by root:root (uid 0:gid 0)
- If owned by uid 1000, ALL `su` and `sudo` commands fail
- Error: "sudo: /etc/sudoers is owned by uid 1000, should be 0"
- Fix applied in customize.sh line 82: `sudo chown -R root:root etc/`

### 4. VM Boot Behavior
- VMs with `--cdrom` boot from disk after first boot unless `--boot cdrom` specified
- qcow2 disk is empty in VirtOS (runs 100% from RAM/tmpfs)
- ISO must be specified with `--boot cdrom` for consistent CD-ROM boot

### 5. Serial Console Limitations
- `--serial file,path=/tmp/log` creates file but captures minimal output
- Early boot messages appear, but bootsync.sh output doesn't
- `/dev/console` writes don't appear in serial log
- Serial logging unreliable for debugging boot scripts

### 6. Network Configuration
- dhcp.sh automatically runs udhcpc on all eth* interfaces
- Network comes up WITHOUT custom scripts
- Ping works even when custom services don't start
- "Connection refused" vs "timeout" indicates kernel response vs no response

## Issues Resolved

1. ✅ Sudoers file ownership (uid 1000 → root:root)
2. ✅ TCZ packages bundled in initrd at correct location (`/tmp/tce/optional/`)
3. ✅ onboot.lst created in correct location (`/tmp/tce/onboot.lst`)
4. ✅ VM boot behavior (added `--boot cdrom`)
5. ✅ Boot script location (moved from bootlocal.sh to bootsync.sh)
6. ✅ POSIX compliance (removed bash-isms like `[[` regex test)

## Issues Still Outstanding

1. ❌ TCZ packages don't load despite being in correct location
2. ❌ bootsync.sh commands don't execute (telnetd, httpd, sshd all fail)
3. ❌ Serial console logging doesn't capture boot script output
4. ❌ No way to verify what's happening inside running VM

## Root Cause Analysis

### Why TCZ Packages Don't Load
**Hypothesis**: Tiny Core 15.0 requires either:
- A specific boot parameter (pretce=RAM tested but failed)
- TCZ packages to be on persistent storage, not in initrd
- tce-load to be called as specific user (tc vs root)
- Some other TC configuration we haven't discovered

### Why bootsync.sh Commands Fail
**Hypothesis**: Either:
- bootsync.sh has execution error that stops it early
- Commands (telnetd, httpd) aren't available in base TC
- Script runs but commands fail silently
- There's a permission/environment issue

### Why Serial Logging Doesn't Work
**Confirmed**: `--serial file` only captures early kernel/init output, not runtime script output to `/dev/console`

## Attempted Solutions

### TCZ Loading Approaches (All Failed)
1. Put TCZ in `/optional/`, tc-config copies to `/tmp/tce/` - packages don't load
2. Put TCZ in `/tmp/tce/optional/` directly in initrd - packages don't load
3. Add `lst=onboot.lst` boot parameter - parameter doesn't exist
4. Add `pretce=RAM` boot parameter - appeared non-functional
5. Manual tce-load in bootsync.sh - script doesn't execute properly

### Service Starting Approaches (All Failed)
1. Start in bootlocal.sh - script never runs
2. Start in bootsync.sh - commands fail
3. Use only busybox built-ins (telnetd, httpd) - still fail
4. HTTP server on port 80 to fetch debug logs - connection refused

## Test Results Summary

| Test | Result | Evidence |
|------|--------|----------|
| VM boots | ✅ SUCCESS | virsh list shows running |
| Network up (ping) | ✅ SUCCESS | 64 bytes from X.X.X.X (intermittent) |
| Get DHCP IP | ✅ SUCCESS | virsh domifaddr shows IP |
| Serial console log | ❌ FAILED | Empty or minimal output |
| HTTP server (port 80) | ❌ FAILED | Connection refused |
| Telnet (port 23) | ❌ FAILED | Connection refused |
| SSH (port 22) | ❌ FAILED | Connection refused |
| Read debug files via HTTP | ❌ FAILED | Can't fetch /tmp/bootsync-ran.txt |

## Files Modified

### Core Changes
- `config/bootsync.sh` - Added TCZ loading and service startup (multiple iterations)
- `config/bootlocal.sh` - Initially used, then abandoned (doesn't auto-run)
- `build/scripts/customize.sh` - Fixed sudoers ownership (line 82)
- `build/scripts/customize.sh` - TCZ packages to `/tmp/tce/optional/` (line 352)
- `build/scripts/customize.sh` - onboot.lst to `/tmp/tce/` (line 378)

### Test Scripts Created
- `/tmp/redeploy-test-telnet.sh` - Automated rebuild and test script
- `/tmp/virtos-automated-debug.sh` - Comprehensive debugging automation
- `/tmp/FINAL_SOLUTION.md` - Root cause documentation (superseded by this doc)

## Recommended Next Steps

### Option 1: Use Official TC as Base
1. Download official Tiny Core 15.0 ISO
2. Test if SSH/network works out of box
3. Identify what's different in our build
4. Rebuild VirtOS using proven working base

### Option 2: Simplify Approach
1. Remove TCZ auto-loading entirely
2. Provide manual installation instructions
3. Focus on getting ONE service (telnet) working first
4. Build up from minimal working state

### Option 3: Alternative Distribution
1. Switch from Tiny Core to Alpine Linux (also minimal)
2. Alpine has better package management (apk)
3. Alpine has working SSH out of box
4. Trade-off: larger base image

### Option 4: Console Access Required
1. Accept that we need interactive console access
2. Test directly on hardware with monitor/keyboard
3. Debug why serial logging doesn't work
4. Fix serial console first, then debug services

## Lessons Learned

### What Worked
- Systematic elimination of variables
- Creating automated test scripts
- Documenting each hypothesis and result
- Breaking down complex issues into smaller tests

### What Didn't Work
- Assuming documentation was accurate (bootlocal.sh auto-runs)
- Trusting that similar setups would work the same
- Relying on serial console for debugging
- Making multiple changes without validation

### Best Practices Identified
1. Always verify boot script actually runs (marker file + HTTP serve it)
2. Test with official/vanilla images first
3. Add only ONE change at a time
4. Document every finding immediately
5. Create automated reproduction scripts early

## References

- Tiny Core Linux Wiki: http://wiki.tinycorelinux.net/
- Tiny Core Forums: http://forum.tinycorelinux.net/
- tc-config source: `/etc/init.d/tc-config` (analyzed extensively)
- This session transcript: `fe06c330-8ed9-4a75-94db-e64e4d2d6b89.jsonl`

## Status: BLOCKED

**Current blocker**: Cannot verify boot script execution without console access or working serial logging.

**Recommended action**: Test official Tiny Core ISO to establish baseline, then compare.

---

**Session End**: 2026-06-06 19:45 EDT
**Total Time**: ~15 hours
**Token Usage**: ~118K/200K
**Status**: Investigation phase complete, requires new approach
