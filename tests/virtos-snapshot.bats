#!/usr/bin/env bats
# BATS tests for virtos-snapshot

SCRIPT="${BATS_TEST_DIRNAME}/../config/custom-scripts/virtos-snapshot"

#==============================================================================
# Basic Script Validation Tests
#==============================================================================

@test "virtos-snapshot exists and is executable" {
    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "virtos-snapshot has valid shebang" {
    head -n 1 "$SCRIPT" | grep -q '^#!/bin/bash'
}

@test "virtos-snapshot has 'set -e' for error handling" {
    grep -q '^set -e' "$SCRIPT"
}

#==============================================================================
# Help and Version Tests
#==============================================================================

@test "virtos-snapshot --help shows usage" {
    run grep -A 30 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-snapshot help includes all commands" {
    run grep -A 30 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "create" ]]
    [[ "$output" =~ "list" ]]
    [[ "$output" =~ "revert" ]]
    [[ "$output" =~ "delete" ]]
    [[ "$output" =~ "schedule" ]]
    [[ "$output" =~ "cleanup" ]]
}

@test "virtos-snapshot help includes examples" {
    run grep -A 40 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Examples:" ]]
}

@test "virtos-snapshot --version flag exists" {
    grep -q '\--version|-v|version)' "$SCRIPT"
}

@test "virtos-snapshot version uses get_version function" {
    grep -q 'VERSION=.*get_version' "$SCRIPT"
}

#==============================================================================
# Command Structure Tests
#==============================================================================

@test "virtos-snapshot has create_snapshot function" {
    grep -q '^create_snapshot() {' "$SCRIPT"
}

@test "virtos-snapshot has list_snapshots function" {
    grep -q '^list_snapshots() {' "$SCRIPT"
}

@test "virtos-snapshot has revert_snapshot function" {
    grep -q '^revert_snapshot() {' "$SCRIPT"
}

@test "virtos-snapshot has delete_snapshot function" {
    grep -q '^delete_snapshot() {' "$SCRIPT"
}

@test "virtos-snapshot has schedule_snapshots function" {
    grep -q '^schedule_snapshots() {' "$SCRIPT"
}

@test "virtos-snapshot has cleanup_snapshots function" {
    grep -q '^cleanup_snapshots() {' "$SCRIPT"
}

@test "virtos-snapshot has btrfs_snapshot function" {
    grep -q '^btrfs_snapshot() {' "$SCRIPT"
}

@test "virtos-snapshot has zfs_snapshot function" {
    grep -q '^zfs_snapshot() {' "$SCRIPT"
}

@test "virtos-snapshot has lvm_snapshot function" {
    grep -q '^lvm_snapshot() {' "$SCRIPT"
}

#==============================================================================
# Input Validation Tests
#==============================================================================

@test "virtos-snapshot create validates VM name" {
    grep -A 10 '^create_snapshot() {' "$SCRIPT" | grep -q 'validate_vm_name'
}

@test "virtos-snapshot create shows error for invalid VM name" {
    grep -A 15 '^create_snapshot() {' "$SCRIPT" | grep -q 'Error: Invalid VM name'
}

@test "virtos-snapshot list validates VM name" {
    grep -A 10 '^list_snapshots() {' "$SCRIPT" | grep -q 'validate_vm_name'
}

@test "virtos-snapshot revert validates VM name" {
    grep -A 10 '^revert_snapshot() {' "$SCRIPT" | grep -q 'validate_vm_name'
}

@test "virtos-snapshot revert validates snapshot name" {
    grep -A 15 '^revert_snapshot() {' "$SCRIPT" | grep -q 'validate_vm_name.*snapshot_name'
}

@test "virtos-snapshot delete validates VM name" {
    grep -A 10 '^delete_snapshot() {' "$SCRIPT" | grep -q 'validate_vm_name'
}

@test "virtos-snapshot delete validates snapshot name" {
    grep -A 15 '^delete_snapshot() {' "$SCRIPT" | grep -q 'validate_vm_name.*snapshot_name'
}

#==============================================================================
# Security Tests - Command Injection Prevention
#==============================================================================

@test "virtos-snapshot uses validation before virsh commands" {
    # Check that validate_vm_name is called before virsh in create_snapshot
    local create_func=$(sed -n '/^create_snapshot() {/,/^}/p' "$SCRIPT")
    # Ensure validation happens before virsh
    echo "$create_func" | grep -B 5 'virsh snapshot-create-as' | grep -q 'validate_vm_name'
}

@test "virtos-snapshot revert validates before virsh snapshot-revert" {
    local revert_func=$(sed -n '/^revert_snapshot() {/,/^}/p' "$SCRIPT")
    echo "$revert_func" | grep -B 5 'virsh snapshot-revert' | grep -q 'validate_vm_name'
}

@test "virtos-snapshot delete validates before virsh snapshot-delete" {
    local delete_func=$(sed -n '/^delete_snapshot() {/,/^}/p' "$SCRIPT")
    echo "$delete_func" | grep -B 5 'virsh snapshot-delete' | grep -q 'validate_vm_name'
}

@test "virtos-snapshot validation prevents command injection in create" {
    # Ensure early return on validation failure prevents command execution
    grep -A 10 'validate_vm_name "$vm_name"' "$SCRIPT" | grep -q 'return 1'
}

#==============================================================================
# Snapshot Creation Tests
#==============================================================================

@test "virtos-snapshot create generates timestamp-based snapshot names" {
    grep -A 20 '^create_snapshot() {' "$SCRIPT" | grep -q 'snapshot-$(date'
}

@test "virtos-snapshot create supports disk-only snapshots" {
    grep -A 30 '^create_snapshot() {' "$SCRIPT" | grep -q '\--disk-only'
}

@test "virtos-snapshot create supports memory snapshots" {
    grep -A 30 '^create_snapshot() {' "$SCRIPT" | grep -q 'memory'
}

@test "virtos-snapshot create uses atomic flag for disk-only" {
    grep -A 30 '^create_snapshot() {' "$SCRIPT" | grep -q '\--atomic'
}

@test "virtos-snapshot create accepts description parameter" {
    grep -A 5 '^create_snapshot() {' "$SCRIPT" | grep -q 'description="\${2:-'
}

@test "virtos-snapshot create provides default description" {
    grep -A 5 '^create_snapshot() {' "$SCRIPT" | grep -q 'Snapshot created at'
}

#==============================================================================
# VM Existence Checks
#==============================================================================

@test "virtos-snapshot create checks VM exists" {
    grep -A 20 '^create_snapshot() {' "$SCRIPT" | grep -q "VM.*not found"
}

@test "virtos-snapshot list checks VM exists" {
    grep -A 20 '^list_snapshots() {' "$SCRIPT" | grep -q "VM.*not found"
}

@test "virtos-snapshot revert checks VM exists" {
    grep -A 20 '^revert_snapshot() {' "$SCRIPT" | grep -q "VM.*not found"
}

@test "virtos-snapshot delete checks VM exists" {
    grep -A 20 '^delete_snapshot() {' "$SCRIPT" | grep -q "VM.*not found"
}

@test "virtos-snapshot cleanup checks VM exists" {
    grep -A 20 '^cleanup_snapshots() {' "$SCRIPT" | grep -q "VM.*not found"
}

#==============================================================================
# Snapshot Existence Checks
#==============================================================================

@test "virtos-snapshot revert checks snapshot exists" {
    grep -A 25 '^revert_snapshot() {' "$SCRIPT" | grep -q "Snapshot.*not found"
}

@test "virtos-snapshot revert uses virsh snapshot-list to verify" {
    grep -A 25 '^revert_snapshot() {' "$SCRIPT" | grep -q 'virsh snapshot-list'
}

#==============================================================================
# List Functionality Tests
#==============================================================================

@test "virtos-snapshot list shows tree view" {
    grep -A 15 '^list_snapshots() {' "$SCRIPT" | grep -q '\--tree'
}

@test "virtos-snapshot list shows detailed information" {
    grep -A 25 '^list_snapshots() {' "$SCRIPT" | grep -q 'snapshot-info'
}

@test "virtos-snapshot list displays creation time" {
    grep -A 25 '^list_snapshots() {' "$SCRIPT" | grep -q 'Creation'
}

@test "virtos-snapshot list displays state" {
    grep -A 25 '^list_snapshots() {' "$SCRIPT" | grep -q 'State'
}

#==============================================================================
# Cleanup Functionality Tests
#==============================================================================

@test "virtos-snapshot cleanup has default keep count" {
    grep -A 5 '^cleanup_snapshots() {' "$SCRIPT" | grep -q 'keep_count="\${2:-7}'
}

@test "virtos-snapshot cleanup uses topological ordering" {
    grep -A 20 '^cleanup_snapshots() {' "$SCRIPT" | grep -q '\--topological'
}

@test "virtos-snapshot cleanup deletes oldest snapshots first" {
    grep -A 30 '^cleanup_snapshots() {' "$SCRIPT" | grep -q 'delete_count=\$((total - keep_count))'
}

@test "virtos-snapshot cleanup skips deletion when count is within limit" {
    grep -A 20 '^cleanup_snapshots() {' "$SCRIPT" | grep -q 'nothing to delete'
}

@test "virtos-snapshot cleanup counts deleted snapshots" {
    grep -A 40 '^cleanup_snapshots() {' "$SCRIPT" | grep -q 'deleted=\$((deleted + 1))'
}

#==============================================================================
# Schedule Functionality Tests
#==============================================================================

@test "virtos-snapshot schedule creates cron file" {
    grep -A 10 '^schedule_snapshots() {' "$SCRIPT" | grep -q '/etc/cron.d/'
}

@test "virtos-snapshot schedule supports hourly snapshots" {
    grep -A 20 '^schedule_snapshots() {' "$SCRIPT" | grep -q 'hourly'
}

@test "virtos-snapshot schedule supports daily snapshots" {
    grep -A 25 '^schedule_snapshots() {' "$SCRIPT" | grep -q 'daily'
}

@test "virtos-snapshot schedule includes cleanup job" {
    grep -A 35 '^schedule_snapshots() {' "$SCRIPT" | grep -q 'Cleanup old snapshots'
}

@test "virtos-snapshot schedule uses keep count in cleanup" {
    grep -A 35 '^schedule_snapshots() {' "$SCRIPT" | grep -q '\--keep.*keep_count'
}

@test "virtos-snapshot schedule runs as root" {
    grep -A 25 '^schedule_snapshots() {' "$SCRIPT" | grep -q 'root /usr/local/bin/virtos-snapshot'
}

#==============================================================================
# Storage Backend Tests
#==============================================================================

@test "virtos-snapshot supports Btrfs snapshots" {
    grep -q '^btrfs_snapshot() {' "$SCRIPT"
}

@test "virtos-snapshot supports ZFS snapshots" {
    grep -q '^zfs_snapshot() {' "$SCRIPT"
}

@test "virtos-snapshot supports LVM snapshots" {
    grep -q '^lvm_snapshot() {' "$SCRIPT"
}

@test "virtos-snapshot btrfs uses btrfs subvolume snapshot" {
    grep -A 20 '^btrfs_snapshot() {' "$SCRIPT" | grep -q 'btrfs subvolume snapshot'
}

@test "virtos-snapshot zfs uses zfs snapshot command" {
    grep -A 20 '^zfs_snapshot() {' "$SCRIPT" | grep -q 'zfs snapshot'
}

@test "virtos-snapshot lvm uses lvcreate with snapshot" {
    grep -A 20 '^lvm_snapshot() {' "$SCRIPT" | grep -q 'lvcreate.*-s'
}

@test "virtos-snapshot btrfs finds VM disks" {
    grep -A 10 '^btrfs_snapshot() {' "$SCRIPT" | grep -q 'virsh domblklist'
}

@test "virtos-snapshot zfs handles zvol paths" {
    grep -A 15 '^zfs_snapshot() {' "$SCRIPT" | grep -q '/dev/zvol/'
}

#==============================================================================
# Option Parsing Tests
#==============================================================================

@test "virtos-snapshot parses --disk-only option" {
    grep -A 60 'Parse options' "$SCRIPT" | grep -q '\--disk-only)'
}

@test "virtos-snapshot parses --memory option" {
    grep -A 60 'Parse options' "$SCRIPT" | grep -q '\--memory)'
}

@test "virtos-snapshot parses --hourly option" {
    grep -A 60 'Parse options' "$SCRIPT" | grep -q '\--hourly)'
}

@test "virtos-snapshot parses --daily option" {
    grep -A 60 'Parse options' "$SCRIPT" | grep -q '\--daily)'
}

@test "virtos-snapshot parses --keep option" {
    grep -A 60 'Parse options' "$SCRIPT" | grep -q '\--keep)'
}

@test "virtos-snapshot --daily requires time argument" {
    grep -A 65 'Parse options' "$SCRIPT" | grep -A 2 '\--daily)' | grep -q 'shift 2'
}

@test "virtos-snapshot --keep requires count argument" {
    grep -A 65 'Parse options' "$SCRIPT" | grep -A 2 '\--keep)' | grep -q 'shift 2'
}

#==============================================================================
# Command Dispatch Tests
#==============================================================================

@test "virtos-snapshot dispatches create command" {
    grep -A 50 'case "\$COMMAND"' "$SCRIPT" | grep -q 'create)'
}

@test "virtos-snapshot dispatches list command" {
    grep -A 50 'case "\$COMMAND"' "$SCRIPT" | grep -q 'list)'
}

@test "virtos-snapshot dispatches revert command" {
    grep -A 50 'case "\$COMMAND"' "$SCRIPT" | grep -q 'revert)'
}

@test "virtos-snapshot dispatches delete command" {
    grep -A 50 'case "\$COMMAND"' "$SCRIPT" | grep -q 'delete)'
}

@test "virtos-snapshot dispatches schedule command" {
    grep -A 50 'case "\$COMMAND"' "$SCRIPT" | grep -q 'schedule)'
}

@test "virtos-snapshot dispatches cleanup command" {
    grep -A 50 'case "\$COMMAND"' "$SCRIPT" | grep -q 'cleanup)'
}

@test "virtos-snapshot dispatches btrfs command" {
    grep -A 55 'case "\$COMMAND"' "$SCRIPT" | grep -q 'btrfs)'
}

@test "virtos-snapshot dispatches zfs command" {
    grep -A 55 'case "\$COMMAND"' "$SCRIPT" | grep -q 'zfs)'
}

@test "virtos-snapshot dispatches lvm command" {
    grep -A 55 'case "\$COMMAND"' "$SCRIPT" | grep -q 'lvm)'
}

@test "virtos-snapshot handles help command" {
    grep -A 60 'case "\$COMMAND"' "$SCRIPT" | grep -q '\--help|-h|help'
}

@test "virtos-snapshot handles version command" {
    grep -A 60 'case "\$COMMAND"' "$SCRIPT" | grep -q '\--version|-v|version'
}

@test "virtos-snapshot handles unknown command" {
    grep -A 65 'case "\$COMMAND"' "$SCRIPT" | grep -q '*)'
}

@test "virtos-snapshot shows error for unknown command" {
    grep -A 68 'case "\$COMMAND"' "$SCRIPT" | grep -q 'Unknown command'
}

#==============================================================================
# Error Handling Tests
#==============================================================================

@test "virtos-snapshot create returns error code on failure" {
    grep -A 35 '^create_snapshot() {' "$SCRIPT" | grep -q 'return 1'
}

@test "virtos-snapshot list returns error code on failure" {
    grep -A 20 '^list_snapshots() {' "$SCRIPT" | grep -q 'return 1'
}

@test "virtos-snapshot revert returns error code on failure" {
    grep -A 35 '^revert_snapshot() {' "$SCRIPT" | grep -q 'return 1'
}

@test "virtos-snapshot delete returns error code on failure" {
    grep -A 30 '^delete_snapshot() {' "$SCRIPT" | grep -q 'return 1'
}

@test "virtos-snapshot create shows error message on invalid VM" {
    grep -A 15 '^create_snapshot() {' "$SCRIPT" | grep -q 'Error: Invalid VM name'
}

@test "virtos-snapshot schedule requires schedule type" {
    grep -A 10 'schedule)' "$SCRIPT" | grep -q 'Schedule type required'
}

@test "virtos-snapshot provides informative error messages" {
    # Check for multiple error message patterns
    grep -c 'Error:' "$SCRIPT" | grep -q '[5-9]\|[1-9][0-9]'  # At least 5 error messages
}

#==============================================================================
# virtos-common.sh Integration Tests
#==============================================================================

@test "virtos-snapshot sources virtos-common.sh" {
    grep -q '. /usr/local/lib/virtos-common.sh' "$SCRIPT"
}

@test "virtos-snapshot checks if virtos-common.sh exists before sourcing" {
    grep -B 1 '. /usr/local/lib/virtos-common.sh' "$SCRIPT" | grep -q 'if \[ -f'
}

@test "virtos-snapshot uses validate_vm_name from virtos-common.sh" {
    grep -q 'validate_vm_name' "$SCRIPT"
}

#==============================================================================
# Configuration and Defaults Tests
#==============================================================================

@test "virtos-snapshot has default snapshot type" {
    grep -q 'SNAPSHOT_TYPE="disk-only"' "$SCRIPT"
}

@test "virtos-snapshot has default keep count of 7" {
    grep -q 'KEEP_COUNT=7' "$SCRIPT"
}

@test "virtos-snapshot schedule default keep is 7" {
    grep -A 5 '^schedule_snapshots() {' "$SCRIPT" | grep -q 'keep_count="\${4:-7}'
}

#==============================================================================
# Output Formatting Tests
#==============================================================================

@test "virtos-snapshot create shows progress messages" {
    grep -A 20 '^create_snapshot() {' "$SCRIPT" | grep -q 'Creating snapshot'
}

@test "virtos-snapshot create shows success message" {
    grep -A 35 '^create_snapshot() {' "$SCRIPT" | grep -q 'Snapshot created:'
}

@test "virtos-snapshot list has section headers" {
    grep -A 15 '^list_snapshots() {' "$SCRIPT" | grep -q 'Snapshots for VM:'
}

@test "virtos-snapshot cleanup shows deletion count" {
    grep -A 45 '^cleanup_snapshots() {' "$SCRIPT" | grep -q 'Deleted.*snapshots'
}

@test "virtos-snapshot schedule shows confirmation messages" {
    grep -A 35 '^schedule_snapshots() {' "$SCRIPT" | grep -q 'scheduled'
}

#==============================================================================
# Argument Count Tests
#==============================================================================

@test "virtos-snapshot create requires VM name" {
    grep -A 5 '^create_snapshot() {' "$SCRIPT" | grep -q 'vm_name="$1"'
}

@test "virtos-snapshot list requires VM name" {
    grep -A 5 '^list_snapshots() {' "$SCRIPT" | grep -q 'vm_name="$1"'
}

@test "virtos-snapshot revert requires VM and snapshot name" {
    grep -A 5 '^revert_snapshot() {' "$SCRIPT" | grep -q 'snapshot_name="$2"'
}

@test "virtos-snapshot delete requires VM and snapshot name" {
    grep -A 5 '^delete_snapshot() {' "$SCRIPT" | grep -q 'snapshot_name="$2"'
}
