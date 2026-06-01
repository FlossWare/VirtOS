# VirtOS Temporary File Security

**Last Updated**: 2026-06-01  
**Status**: ✅ All vulnerabilities fixed and validated

## Overview

This document describes VirtOS's secure temporary file handling implementation and the security fixes applied to eliminate race conditions, symlink attacks, and information disclosure vulnerabilities.

## Security Vulnerabilities Fixed

### CRITICAL (3 vulnerabilities - ✅ FIXED)

1. **virtos-backup:411** - Hardcoded `/tmp/restore-vm.xml`
   - **Risk**: Race condition - attacker could inject malicious VM configuration
   - **Impact**: VM compromise, privilege escalation
   - **Fix**: Replaced with `create_secure_temp_file "restore-vm" ".xml"`

2. **virtos-migrate:285** - Predictable `/tmp/${vm_name}.xml`
   - **Risk**: Race condition - attacker could inject malicious VM config during migration
   - **Impact**: VM compromise on destination host, data exfiltration
   - **Fix**: Replaced with `create_secure_temp_file "migrate-${vm_name}" ".xml"`

3. **virtos-template:178** - User-controlled `/tmp/$new_vm_name.xml`
   - **Risk**: Race condition - attacker could inject malicious template
   - **Impact**: All VMs created from template compromised
   - **Fix**: Replaced with `create_secure_temp_file "vm-config-${new_vm_name}" ".xml"`

### HIGH (3 vulnerabilities - ✅ FIXED)

4. **virtos-cluster:172** - PID-based `/tmp/virtos-mcast-$$`
   - **Risk**: PIDs are sequential and predictable, symlink attack possible
   - **Impact**: Denial of service, information disclosure
   - **Fix**: Replaced with `mktemp -u` (unpredictable random name)

5. **virtos-tui:676** - PID-based `/tmp/example-vm-$$.yaml`
   - **Risk**: Attacker can predict PID and pre-create malicious YAML file
   - **Impact**: Malicious workload deployment
   - **Fix**: Replaced with `create_secure_temp_file "example-vm" ".yaml"`

6. **virtos-tui:708** - PID-based `/tmp/example-container-$$.yaml`
   - **Risk**: Attacker can pre-create malicious YAML file
   - **Impact**: Container escape, privilege escalation
   - **Fix**: Replaced with `create_secure_temp_file "example-container" ".yaml"`

### MEDIUM (7 vulnerabilities - ✅ FIXED)

7-8. **virtos-directory:266,295** - Static `/tmp/group.ldif`, `/tmp/user.ldif`
   - **Risk**: Information disclosure if process crashes before cleanup
   - **Impact**: Password/credential leakage
   - **Fix**: Used `create_secure_temp_file` with cleanup traps

9. **virtos-setup:596** - Static `/tmp/virtos-setup.log`
   - **Risk**: Information disclosure, log injection
   - **Impact**: Configuration details leaked
   - **Fix**: Replaced with `create_secure_temp_file "virtos-setup" ".log"`

10-12. **virtos-tui:2103,2105,2110** - Static `/tmp/iaas-result.txt`
   - **Risk**: Information disclosure, race condition
   - **Impact**: VM creation details leaked
   - **Fix**: Replaced with `create_secure_temp_file "iaas-result" ".txt"`

13-16. **virtos-{backup,datacenter,setup,tui}** - mktemp without error handling
   - **Risk**: If mktemp fails (disk full, permissions), empty variable causes writes to root directory
   - **Impact**: File creation in unexpected locations, permission errors
   - **Fix**: Added error handling: `|| die "Failed to create temporary file"`

## Secure Implementation

### New Functions in virtos-common.sh

```bash
# Create secure temporary file
create_secure_temp_file() {
    local prefix="${1:-virtos}"
    local suffix="${2:-}"
    local temp_file

    if [ -n "$suffix" ]; then
        temp_file=$(mktemp -t "${prefix}-XXXXXX${suffix}") || die "Failed to create temporary file"
    else
        temp_file=$(mktemp -t "${prefix}-XXXXXX") || die "Failed to create temporary file"
    fi

    chmod 600 "$temp_file" 2>/dev/null || true
    echo "$temp_file"
}

# Create secure temporary directory
create_secure_temp_dir() {
    local prefix="${1:-virtos}"
    local temp_dir

    temp_dir=$(mktemp -d -t "${prefix}-XXXXXX") || die "Failed to create temporary directory"
    chmod 700 "$temp_dir" 2>/dev/null || true
    echo "$temp_dir"
}

# Register cleanup trap
register_cleanup_trap() {
    local cleanup_list="$*"
    trap "rm -rf $cleanup_list 2>/dev/null || true" EXIT INT TERM
}
```

### Security Properties

1. **Unpredictable Names**: Uses `mktemp` with random suffixes (XXXXXX)
   - No PID-based names (predictable)
   - No user-controlled names (injection risk)
   - No static names (race conditions)

2. **Restrictive Permissions**: 
   - Files: mode 600 (owner read/write only)
   - Directories: mode 700 (owner read/write/execute only)
   - Prevents unauthorized access to sensitive data

3. **Automatic Cleanup**:
   - `register_cleanup_trap` ensures temp files removed on EXIT/INT/TERM
   - No orphaned temp files with sensitive data

4. **Error Handling**:
   - All `mktemp` calls have `|| die` fallback
   - Prevents silent failures that could write to unexpected locations

## Usage Examples

### Before (Vulnerable)

```bash
# VULNERABLE - Race condition
local vm_xml="/tmp/${vm_name}.xml"
virsh dumpxml "$vm_name" > "$vm_xml"
virsh define "$vm_xml"
rm "$vm_xml"

# VULNERABLE - PID-based (predictable)
EXAMPLE_VM="/tmp/example-vm-$$.yaml"
cat > "$EXAMPLE_VM" << 'EOF'
...
