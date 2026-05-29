#!/usr/bin/env bats
# BATS tests for virtos-migrate

SCRIPT="${BATS_TEST_DIRNAME}/../config/custom-scripts/virtos-migrate"

@test "virtos-migrate exists and is executable" {
    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "virtos-migrate --help shows usage" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" || "$output" =~ "usage:" || "$output" =~ "migrate" ]]
}

@test "virtos-migrate without arguments shows error or usage" {
    run "$SCRIPT"
    # Should show usage or error about missing arguments
    [[ "$output" =~ "Usage:" || "$output" =~ "Error" || "$output" =~ "required" || "$status" -ne 0 ]]
}

#==============================================================================
# Structural Validation Tests
#==============================================================================

@test "virtos-migrate script has correct shebang" {
    head -n 1 "$SCRIPT" | grep -q '^#!/bin/bash'
}

@test "virtos-migrate script passes bash syntax check" {
    bash -n "$SCRIPT"
}

@test "virtos-migrate contains copyright header" {
    head -n 5 "$SCRIPT" | grep -q "Copyright"
}

@test "virtos-migrate contains license information" {
    head -n 5 "$SCRIPT" | grep -q "GNU General Public License"
}

@test "virtos-migrate sets error exit mode" {
    grep -q "^set -e" "$SCRIPT"
}

#==============================================================================
# Version Information Tests
#==============================================================================

@test "virtos-migrate --version shows version" {
    run "$SCRIPT" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]] || [[ "$output" =~ [0-9]+\.[0-9]+ ]]
}

@test "virtos-migrate uses get_version function" {
    grep -q "VERSION=\$(get_version" "$SCRIPT"
}

@test "virtos-migrate has version fallback" {
    grep -q 'get_version.*||.*echo.*[0-9]' "$SCRIPT"
}

#==============================================================================
# Usage and Help Tests
#==============================================================================

@test "virtos-migrate usage function exists" {
    grep -q "^usage()" "$SCRIPT"
}

@test "virtos-migrate usage includes migration types" {
    grep -A 50 "^usage()" "$SCRIPT" | grep -q "live"
    grep -A 50 "^usage()" "$SCRIPT" | grep -q "offline"
    grep -A 50 "^usage()" "$SCRIPT" | grep -q "block"
}

@test "virtos-migrate usage includes examples" {
    grep -A 100 "^usage()" "$SCRIPT" | grep -q "Examples:"
}

@test "virtos-migrate help flag (-h) works" {
    run "$SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-migrate help shows bandwidth option" {
    run "$SCRIPT" --help
    [[ "$output" =~ "bandwidth" ]]
}

@test "virtos-migrate help shows compression option" {
    run "$SCRIPT" --help
    [[ "$output" =~ "compressed" ]]
}

#==============================================================================
# Argument Parsing Tests (Source Code Analysis)
#==============================================================================

@test "virtos-migrate accepts --live flag" {
    grep -q '^\s*--live)' "$SCRIPT"
}

@test "virtos-migrate accepts --offline flag" {
    grep -q '^\s*--offline)' "$SCRIPT"
}

@test "virtos-migrate accepts --block flag" {
    grep -q '^\s*--block)' "$SCRIPT"
}

@test "virtos-migrate accepts --shared-storage flag" {
    grep -q '^\s*--shared-storage)' "$SCRIPT"
}

@test "virtos-migrate accepts --bandwidth option with argument" {
    grep -q '^\s*--bandwidth)' "$SCRIPT"
    grep -A 2 '^\s*--bandwidth)' "$SCRIPT" | grep -q 'shift 2'
}

@test "virtos-migrate accepts --compressed flag" {
    grep -q '^\s*--compressed)' "$SCRIPT"
}

@test "virtos-migrate accepts --auto-converge flag" {
    grep -q '^\s*--auto-converge)' "$SCRIPT"
}

@test "virtos-migrate accepts --persistent flag" {
    grep -q '^\s*--persistent)' "$SCRIPT"
}

@test "virtos-migrate accepts --undefine-source flag" {
    grep -q '^\s*--undefine-source)' "$SCRIPT"
}

@test "virtos-migrate accepts --verbose flag" {
    grep -q '^\s*--verbose)' "$SCRIPT"
}

#==============================================================================
# Default Configuration Tests
#==============================================================================

@test "virtos-migrate defaults to live migration" {
    grep -q 'MIGRATION_TYPE="live"' "$SCRIPT"
}

@test "virtos-migrate defaults shared storage to no" {
    grep -q 'SHARED_STORAGE="no"' "$SCRIPT"
}

@test "virtos-migrate defaults undefine source to no" {
    grep -q 'UNDEFINE_SOURCE="no"' "$SCRIPT"
}

@test "virtos-migrate defaults compressed to no" {
    grep -q 'COMPRESSED="no"' "$SCRIPT"
}

@test "virtos-migrate defaults auto-converge to no" {
    grep -q 'AUTO_CONVERGE="no"' "$SCRIPT"
}

@test "virtos-migrate defaults bandwidth to empty" {
    grep -q 'BANDWIDTH=""' "$SCRIPT"
}

@test "virtos-migrate defaults verbose to no" {
    grep -q 'VERBOSE="no"' "$SCRIPT"
}

#==============================================================================
# Required Arguments Tests
#==============================================================================

@test "virtos-migrate requires VM_NAME argument" {
    grep -q 'VM_NAME=.*\$1' "$SCRIPT"
}

@test "virtos-migrate requires DEST_HOST argument" {
    grep -q 'DEST_HOST=.*\$2' "$SCRIPT"
}

@test "virtos-migrate validates both arguments are provided" {
    grep -q 'if \[ -z "\$VM_NAME" \] || \[ -z "\$DEST_HOST" \]' "$SCRIPT"
}

@test "virtos-migrate shows error when arguments missing" {
    grep -A 3 'if \[ -z "\$VM_NAME" \] || \[ -z "\$DEST_HOST" \]' "$SCRIPT" | grep -q "Error.*required"
}

#==============================================================================
# Function Definitions Tests
#==============================================================================

@test "virtos-migrate has log_message function" {
    grep -q "^log_message()" "$SCRIPT"
}

@test "virtos-migrate has check_requirements function" {
    grep -q "^check_requirements()" "$SCRIPT"
}

@test "virtos-migrate has migrate_live_shared function" {
    grep -q "^migrate_live_shared()" "$SCRIPT"
}

@test "virtos-migrate has migrate_block function" {
    grep -q "^migrate_block()" "$SCRIPT"
}

@test "virtos-migrate has migrate_offline function" {
    grep -q "^migrate_offline()" "$SCRIPT"
}

#==============================================================================
# Security - Input Validation Tests
#==============================================================================

@test "virtos-migrate validates VM name using validate_vm_name" {
    grep -q "validate_vm_name.*\$vm_name" "$SCRIPT"
}

@test "virtos-migrate validates hostname using validate_hostname" {
    grep -q "validate_hostname.*\$dest_host" "$SCRIPT"
}

@test "virtos-migrate shows error message for invalid VM name" {
    grep -A 3 'validate_vm_name.*vm_name' "$SCRIPT" | grep -q "Error.*Invalid VM name"
}

@test "virtos-migrate shows error message for invalid hostname" {
    grep -A 3 'validate_hostname.*dest_host' "$SCRIPT" | grep -q "Error.*Invalid.*host"
}

@test "virtos-migrate includes security comment about validation" {
    grep -q "# SECURITY: Validate inputs" "$SCRIPT"
}

#==============================================================================
# Requirement Checking Tests
#==============================================================================

@test "virtos-migrate checks if VM exists" {
    grep -q "virsh list --all.*grep.*\$vm_name" "$SCRIPT"
}

@test "virtos-migrate checks VM state for live migration" {
    grep -q 'virsh domstate.*vm_name' "$SCRIPT"
}

@test "virtos-migrate checks destination host reachability" {
    grep -q 'ping.*\$dest_host' "$SCRIPT"
}

@test "virtos-migrate checks SSH connectivity" {
    grep -q 'ssh.*ConnectTimeout.*\$dest_host' "$SCRIPT"
}

@test "virtos-migrate checks libvirt on destination" {
    grep -q 'ssh.*virsh.*\$dest_host' "$SCRIPT"
}

@test "virtos-migrate provides helpful error for unreachable host" {
    grep -A 5 'ping.*\$dest_host' "$SCRIPT" | grep -q "unreachable"
}

@test "virtos-migrate provides SSH setup instructions on error" {
    grep -A 10 'ssh.*ConnectTimeout' "$SCRIPT" | grep -q "ssh-keygen"
}

@test "virtos-migrate provides libvirt installation instructions" {
    grep -A 10 'virsh.*\$dest_host' "$SCRIPT" | grep -q "tce-load"
}

#==============================================================================
# Live Migration with Shared Storage Tests
#==============================================================================

@test "virtos-migrate live shared uses --live flag" {
    grep -A 20 "^migrate_live_shared()" "$SCRIPT" | grep -q 'migrate_opts=.*--live'
}

@test "virtos-migrate live shared uses --persistent flag" {
    grep -A 20 "^migrate_live_shared()" "$SCRIPT" | grep -q 'migrate_opts=.*--persistent'
}

@test "virtos-migrate live shared uses --verbose flag" {
    grep -A 20 "^migrate_live_shared()" "$SCRIPT" | grep -q 'migrate_opts=.*--verbose'
}

@test "virtos-migrate live shared supports --undefinesource" {
    grep -A 25 "^migrate_live_shared()" "$SCRIPT" | grep -q 'UNDEFINE_SOURCE.*undefinesource'
}

@test "virtos-migrate live shared supports bandwidth limit" {
    grep -A 30 "^migrate_live_shared()" "$SCRIPT" | grep -q 'BANDWIDTH.*--bandwidth'
}

@test "virtos-migrate live shared supports compression" {
    grep -A 30 "^migrate_live_shared()" "$SCRIPT" | grep -q 'COMPRESSED.*--compressed'
}

@test "virtos-migrate live shared supports auto-converge" {
    grep -A 30 "^migrate_live_shared()" "$SCRIPT" | grep -q 'AUTO_CONVERGE.*--auto-converge'
}

@test "virtos-migrate live shared uses qemu+ssh URI" {
    grep -A 40 "^migrate_live_shared()" "$SCRIPT" | grep -q 'qemu+ssh://root@'
}

#==============================================================================
# Block Migration Tests
#==============================================================================

@test "virtos-migrate block uses --copy-storage-all flag" {
    grep -A 20 "^migrate_block()" "$SCRIPT" | grep -q 'copy-storage-all'
}

@test "virtos-migrate block warns about disk copying" {
    grep -A 30 "^migrate_block()" "$SCRIPT" | grep -q "copies all VM disks"
}

@test "virtos-migrate block mentions time and network speed" {
    grep -A 30 "^migrate_block()" "$SCRIPT" | grep -q "network speed"
}

@test "virtos-migrate block supports compression" {
    grep -A 30 "^migrate_block()" "$SCRIPT" | grep -q 'COMPRESSED.*--compressed'
}

@test "virtos-migrate block supports bandwidth limit" {
    grep -A 30 "^migrate_block()" "$SCRIPT" | grep -q 'BANDWIDTH.*--bandwidth'
}

#==============================================================================
# Offline Migration Tests
#==============================================================================

@test "virtos-migrate offline shutdowns running VM" {
    grep -A 20 "^migrate_offline()" "$SCRIPT" | grep -q 'virsh shutdown'
}

@test "virtos-migrate offline waits for shutdown" {
    grep -A 30 "^migrate_offline()" "$SCRIPT" | grep -q 'timeout=60'
}

@test "virtos-migrate offline forces destroy if timeout" {
    grep -A 40 "^migrate_offline()" "$SCRIPT" | grep -q 'virsh destroy'
}

@test "virtos-migrate offline exports VM XML" {
    grep -A 50 "^migrate_offline()" "$SCRIPT" | grep -q 'virsh dumpxml'
}

@test "virtos-migrate offline copies disk images" {
    grep -A 60 "^migrate_offline()" "$SCRIPT" | grep -q 'scp.*\$disk'
}

@test "virtos-migrate offline creates destination directory" {
    grep -A 60 "^migrate_offline()" "$SCRIPT" | grep -q 'mkdir -p.*dest_dir'
}

@test "virtos-migrate offline updates XML paths" {
    grep -A 70 "^migrate_offline()" "$SCRIPT" | grep -q 'sed -i.*\$vm_xml'
}

@test "virtos-migrate offline defines VM on destination" {
    grep -A 80 "^migrate_offline()" "$SCRIPT" | grep -q 'virsh define.*\$vm_xml'
}

@test "virtos-migrate offline starts VM on destination" {
    grep -A 90 "^migrate_offline()" "$SCRIPT" | grep -q 'virsh start.*\$vm_name'
}

@test "virtos-migrate offline cleans up temporary files" {
    grep -A 95 "^migrate_offline()" "$SCRIPT" | grep -q 'rm -f.*\$vm_xml'
}

#==============================================================================
# Error Handling Tests
#==============================================================================

@test "virtos-migrate shows available VMs on VM not found error" {
    grep -A 8 "VM.*not found" "$SCRIPT" | grep -q "Available VMs"
}

@test "virtos-migrate shows VM state in error messages" {
    grep -A 5 "VM must be running" "$SCRIPT" | grep -q "VM.*state:"
}

@test "virtos-migrate provides migration type alternatives" {
    grep -A 10 "VM must be running" "$SCRIPT" | grep -q "Use offline migration"
}

@test "virtos-migrate provides troubleshooting steps for network errors" {
    grep -A 8 "unreachable" "$SCRIPT" | grep -q "Troubleshooting"
}

@test "virtos-migrate validates live migration needs shared storage or block" {
    grep -q "Live migration requires --shared-storage or use --block" "$SCRIPT"
}

@test "virtos-migrate returns error code 1 on missing arguments" {
    grep -A 5 'if \[ -z "\$VM_NAME" \] || \[ -z "\$DEST_HOST" \]' "$SCRIPT" | grep -q "exit 1"
}

@test "virtos-migrate exits on failed requirements check" {
    grep -q 'if ! check_requirements.*exit 1' "$SCRIPT"
}

#==============================================================================
# Migration Type Routing Tests
#==============================================================================

@test "virtos-migrate routes to correct migration function" {
    grep -q 'case "\$MIGRATION_TYPE" in' "$SCRIPT"
}

@test "virtos-migrate handles live migration type" {
    grep -A 10 'case "\$MIGRATION_TYPE"' "$SCRIPT" | grep -q 'live)'
}

@test "virtos-migrate handles block migration type" {
    grep -A 10 'case "\$MIGRATION_TYPE"' "$SCRIPT" | grep -q 'block)'
}

@test "virtos-migrate handles offline migration type" {
    grep -A 10 'case "\$MIGRATION_TYPE"' "$SCRIPT" | grep -q 'offline)'
}

#==============================================================================
# Logging and Output Tests
#==============================================================================

@test "virtos-migrate log_message includes timestamp" {
    grep -A 3 "^log_message()" "$SCRIPT" | grep -q "date.*%Y-%m-%d %H:%M:%S"
}

@test "virtos-migrate logs migration start" {
    grep -q 'log_message "Starting.*migration' "$SCRIPT"
}

@test "virtos-migrate logs migration success" {
    grep -q 'log_message.*completed successfully' "$SCRIPT"
}

@test "virtos-migrate logs migration failure" {
    grep -q 'log_message.*failed' "$SCRIPT"
}

@test "virtos-migrate shows success indicator (checkmark)" {
    grep -q '✓.*successfully migrated' "$SCRIPT"
}

@test "virtos-migrate shows failure indicator (X mark)" {
    grep -q '✗.*failed' "$SCRIPT"
}

#==============================================================================
# Integration with virtos-common.sh Tests
#==============================================================================

@test "virtos-migrate loads virtos-common.sh library" {
    grep -q '\. /usr/local/lib/virtos-common.sh' "$SCRIPT"
}

@test "virtos-migrate checks for virtos-common.sh before loading" {
    grep -B 1 '\. /usr/local/lib/virtos-common.sh' "$SCRIPT" | grep -q 'if \[ -f'
}

@test "virtos-migrate uses get_version from common library" {
    grep -q 'get_version' "$SCRIPT"
}

#==============================================================================
# Command Structure Validation Tests
#==============================================================================

@test "virtos-migrate uses virsh for VM operations" {
    grep -q 'virsh' "$SCRIPT"
}

@test "virtos-migrate uses ssh for remote operations" {
    grep -q 'ssh.*root@' "$SCRIPT"
}

@test "virtos-migrate uses scp for file copying" {
    grep -q 'scp' "$SCRIPT"
}

@test "virtos-migrate uses ping for connectivity check" {
    grep -q 'ping -c' "$SCRIPT"
}

@test "virtos-migrate quotes variables in virsh commands" {
    grep 'virsh.*\$' "$SCRIPT" | grep -q '".*\$'
}

@test "virtos-migrate quotes variables in ssh commands" {
    grep 'ssh.*\$' "$SCRIPT" | grep -q '".*\$'
}

# Migration tests require complex setup
@test "virtos-migrate live migration (requires 2 hosts)" {
    skip "Requires 2 libvirt hosts with shared storage"
}
