#!/usr/bin/env bats
# BATS tests for virtos-backup

SCRIPT="${BATS_TEST_DIRNAME}/../config/custom-scripts/virtos-backup"

#==============================================================================
# Basic Script Tests
#==============================================================================

@test "virtos-backup exists and is executable" {
    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "virtos-backup has correct shebang" {
    run head -n 1 "$SCRIPT"
    [[ "$output" =~ ^#!/bin/bash ]]
}

@test "virtos-backup uses set -e for error handling" {
    grep -q "^set -e" "$SCRIPT"
}

#==============================================================================
# Help and Version Tests
#==============================================================================

@test "virtos-backup --help shows usage" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" || "$output" =~ "usage:" || "$output" =~ "backup" ]]
}

@test "virtos-backup -h shows help" {
    run "$SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-backup help shows help" {
    run "$SCRIPT" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-backup --version shows version" {
    run "$SCRIPT" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-backup -v shows version" {
    run "$SCRIPT" -v
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-backup version shows version" {
    run "$SCRIPT" version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-backup without arguments shows usage" {
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

#==============================================================================
# Command Structure Tests
#==============================================================================

@test "virtos-backup defines backup command handler" {
    grep -q "backup)" "$SCRIPT"
}

@test "virtos-backup defines restore command handler" {
    grep -q "restore)" "$SCRIPT"
}

@test "virtos-backup defines list command handler" {
    grep -q "list)" "$SCRIPT"
}

@test "virtos-backup defines schedule command handler" {
    grep -q "schedule)" "$SCRIPT"
}

@test "virtos-backup defines cleanup command handler" {
    grep -q "cleanup)" "$SCRIPT"
}

@test "virtos-backup defines verify command handler" {
    grep -q "verify)" "$SCRIPT"
}

@test "virtos-backup has main case statement" {
    grep -q 'case "$COMMAND" in' "$SCRIPT"
}

@test "virtos-backup handles unknown commands" {
    grep -q "Unknown command" "$SCRIPT"
}

#==============================================================================
# Function Definition Tests
#==============================================================================

@test "virtos-backup defines backup_vm function" {
    grep -q "^backup_vm()" "$SCRIPT"
}

@test "virtos-backup defines restore_vm function" {
    grep -q "^restore_vm()" "$SCRIPT"
}

@test "virtos-backup defines list_backups function" {
    grep -q "^list_backups()" "$SCRIPT"
}

@test "virtos-backup defines schedule_backup function" {
    grep -q "^schedule_backup()" "$SCRIPT"
}

@test "virtos-backup defines cleanup_backups function" {
    grep -q "^cleanup_backups()" "$SCRIPT"
}

@test "virtos-backup defines usage function" {
    grep -q "^usage()" "$SCRIPT"
}

@test "virtos-backup defines log function" {
    grep -q "^log()" "$SCRIPT"
}

@test "virtos-backup defines error function" {
    grep -q "^error()" "$SCRIPT"
}

@test "virtos-backup defines success function" {
    grep -q "^success()" "$SCRIPT"
}

@test "virtos-backup defines warn function" {
    grep -q "^warn()" "$SCRIPT"
}

#==============================================================================
# Configuration Validation Tests
#==============================================================================

@test "virtos-backup defines BACKUP_DIR variable" {
    grep -q 'BACKUP_DIR=' "$SCRIPT"
}

@test "virtos-backup defines RETENTION_DAYS variable" {
    grep -q 'RETENTION_DAYS=' "$SCRIPT"
}

@test "virtos-backup defines COMPRESSION variable" {
    grep -q 'COMPRESSION=' "$SCRIPT"
}

@test "virtos-backup defines REMOTE_DEST variable" {
    grep -q 'REMOTE_DEST=' "$SCRIPT"
}

@test "virtos-backup defines VERSION variable" {
    grep -q 'VERSION=' "$SCRIPT"
}

@test "virtos-backup uses get_version function" {
    grep -q 'get_version' "$SCRIPT"
}

@test "virtos-backup creates backup directory" {
    grep -q 'mkdir -p.*BACKUP_DIR' "$SCRIPT"
}

#==============================================================================
# Backup Argument Validation Tests
#==============================================================================

@test "virtos-backup backup command requires VM name" {
    grep -A 5 'backup)' "$SCRIPT" | grep -q 'VM name required'
}

@test "virtos-backup validates VM exists before backup" {
    grep -q 'if ! virsh list --all' "$SCRIPT"
}

@test "virtos-backup checks VM state before backup" {
    grep -q 'virsh domstate' "$SCRIPT"
}

@test "virtos-backup gets disk list" {
    grep -q 'virsh domblklist' "$SCRIPT"
}

@test "virtos-backup checks for empty disk list" {
    grep -q 'No disks found' "$SCRIPT"
}

#==============================================================================
# Restore Argument Validation Tests
#==============================================================================

@test "virtos-backup restore requires VM name and date" {
    grep -A 5 'restore)' "$SCRIPT" | grep -q 'VM name and backup date required'
}

@test "virtos-backup restore checks if backup exists" {
    grep -q 'Backup not found' "$SCRIPT"
}

@test "virtos-backup restore verifies checksums" {
    grep -q 'sha256sum -c' "$SCRIPT"
}

@test "virtos-backup restore checks if target VM exists" {
    grep -A 3 'virsh list --all' "$SCRIPT" | grep -q 'already exists'
}

@test "virtos-backup restore handles target name option" {
    grep -q 'target_name=' "$SCRIPT"
}

#==============================================================================
# Schedule Argument Validation Tests
#==============================================================================

@test "virtos-backup schedule handles --daily option" {
    grep -q '\--daily' "$SCRIPT"
}

@test "virtos-backup schedule handles --weekly option" {
    grep -q '\--weekly' "$SCRIPT"
}

@test "virtos-backup schedule handles --retention option" {
    grep -q '\--retention' "$SCRIPT"
}

@test "virtos-backup schedule requires schedule type" {
    grep -q 'Schedule type required' "$SCRIPT"
}

@test "virtos-backup schedule validates day names" {
    grep -q 'case.*schedule_day' "$SCRIPT"
}

@test "virtos-backup schedule handles invalid day" {
    grep -q 'Invalid day' "$SCRIPT"
}

#==============================================================================
# Backup Options Tests
#==============================================================================

@test "virtos-backup help shows --full option" {
    run "$SCRIPT" --help
    [[ "$output" =~ "--full" ]]
}

@test "virtos-backup help shows --incremental option" {
    run "$SCRIPT" --help
    [[ "$output" =~ "--incremental" ]]
}

@test "virtos-backup help shows --compress option" {
    run "$SCRIPT" --help
    [[ "$output" =~ "--compress" ]]
}

@test "virtos-backup help shows --no-compress option" {
    run "$SCRIPT" --help
    [[ "$output" =~ "--no-compress" ]]
}

@test "virtos-backup help shows --destination option" {
    run "$SCRIPT" --help
    [[ "$output" =~ "--destination" ]]
}

@test "virtos-backup help shows --remote option" {
    run "$SCRIPT" --help
    [[ "$output" =~ "--remote" ]]
}

@test "virtos-backup help shows --exclude-disk option" {
    run "$SCRIPT" --help
    [[ "$output" =~ "--exclude-disk" ]]
}

#==============================================================================
# Restore Options Tests
#==============================================================================

@test "virtos-backup help shows --target option" {
    run "$SCRIPT" --help
    [[ "$output" =~ "--target" ]]
}

@test "virtos-backup help shows --disk-only option" {
    run "$SCRIPT" --help
    [[ "$output" =~ "--disk-only" ]]
}

@test "virtos-backup help shows --verify option" {
    run "$SCRIPT" --help
    [[ "$output" =~ "--verify" ]]
}

#==============================================================================
# Backup Operation Tests (Source Analysis)
#==============================================================================

@test "virtos-backup creates timestamped backup directory" {
    grep -q 'timestamp.*date.*%Y%m%d' "$SCRIPT"
}

@test "virtos-backup saves VM state to file" {
    grep -q 'vm-state.txt' "$SCRIPT"
}

@test "virtos-backup dumps VM XML definition" {
    grep -q 'virsh dumpxml' "$SCRIPT"
}

@test "virtos-backup creates snapshot for running VMs" {
    grep -q 'virsh snapshot-create-as' "$SCRIPT"
}

@test "virtos-backup handles snapshot failure gracefully" {
    grep -q 'Snapshot failed, backing up live disk' "$SCRIPT"
}

@test "virtos-backup uses qemu-img convert for compression" {
    grep -q 'qemu-img convert -c' "$SCRIPT"
}

@test "virtos-backup saves disk mapping information" {
    grep -q 'disk-mapping.txt' "$SCRIPT"
}

@test "virtos-backup saves disk info" {
    grep -q 'qemu-img info' "$SCRIPT"
}

@test "virtos-backup creates backup manifest" {
    grep -q 'Backup Manifest' "$SCRIPT"
}

@test "virtos-backup creates checksums" {
    grep -q 'sha256sum \* > checksums.sha256' "$SCRIPT"
}

@test "virtos-backup creates tar.gz archive" {
    grep -q 'tar -czf' "$SCRIPT"
}

@test "virtos-backup deletes snapshot after backup" {
    grep -q 'virsh snapshot-delete' "$SCRIPT"
}

#==============================================================================
# Remote Backup Tests (Source Analysis)
#==============================================================================

@test "virtos-backup handles S3 destinations" {
    grep -q 's3://' "$SCRIPT"
}

@test "virtos-backup uses aws CLI for S3" {
    grep -q 'aws s3 cp' "$SCRIPT"
}

@test "virtos-backup uses scp for remote destinations" {
    grep -q 'scp -r' "$SCRIPT"
}

@test "virtos-backup handles remote copy failures" {
    grep -q 'Failed to copy to remote' "$SCRIPT"
}

#==============================================================================
# Restore Operation Tests (Source Analysis)
#==============================================================================

@test "virtos-backup restore handles compressed backups" {
    grep -q 'tar -xzf' "$SCRIPT"
}

@test "virtos-backup restore uses temporary directory" {
    grep -q 'mktemp -d' "$SCRIPT"
}

@test "virtos-backup restore updates VM name in XML" {
    grep -q 'sed.*<name>' "$SCRIPT"
}

@test "virtos-backup restore generates new UUID" {
    grep -q 'uuidgen' "$SCRIPT"
}

@test "virtos-backup restore converts disk images" {
    grep -q 'qemu-img convert -O qcow2' "$SCRIPT"
}

@test "virtos-backup restore updates disk paths in XML" {
    grep -q "sed.*source file=" "$SCRIPT"
}

@test "virtos-backup restore defines VM in libvirt" {
    grep -q 'virsh define' "$SCRIPT"
}

@test "virtos-backup restore cleans up temporary files" {
    grep -q 'rm -rf.*temp_dir' "$SCRIPT"
}

#==============================================================================
# List Operation Tests (Source Analysis)
#==============================================================================

@test "virtos-backup list handles single VM" {
    grep -A 10 '^list_backups()' "$SCRIPT" | grep -q 'vm_name='
}

@test "virtos-backup list displays table headers" {
    grep -q 'BACKUP DATE.*SIZE.*TYPE' "$SCRIPT"
}

@test "virtos-backup list uses printf for formatting" {
    grep -q 'printf.*%-20s' "$SCRIPT"
}

@test "virtos-backup list calculates backup size" {
    grep -q 'du -sh' "$SCRIPT"
}

@test "virtos-backup list shows backup count" {
    grep -q 'backups)' "$SCRIPT"
}

@test "virtos-backup list iterates over all VMs" {
    grep -q 'for vm_dir in.*BACKUP_DIR' "$SCRIPT"
}

#==============================================================================
# Schedule Operation Tests (Source Analysis)
#==============================================================================

@test "virtos-backup schedule creates cron file" {
    grep -q '/etc/cron.d/virtos-backup-' "$SCRIPT"
}

@test "virtos-backup schedule parses time format" {
    grep -q "cut -d: -f1" "$SCRIPT"
}

@test "virtos-backup schedule converts day names to numbers" {
    grep -q 'sun.*) day_num=0' "$SCRIPT"
}

@test "virtos-backup schedule creates daily cron job" {
    grep -q 'Daily backup scheduled' "$SCRIPT"
}

@test "virtos-backup schedule creates weekly cron job" {
    grep -q 'Weekly backup scheduled' "$SCRIPT"
}

@test "virtos-backup schedule creates cleanup cron job" {
    grep -q 'virtos-backup cleanup' "$SCRIPT"
}

#==============================================================================
# Cleanup Operation Tests (Source Analysis)
#==============================================================================

@test "virtos-backup cleanup uses retention policy" {
    grep -q 'RETENTION_DAYS' "$SCRIPT"
}

@test "virtos-backup cleanup calculates backup age" {
    grep -q 'stat -c %Y' "$SCRIPT"
}

@test "virtos-backup cleanup removes old backups" {
    grep -q 'Removing old backup' "$SCRIPT"
}

@test "virtos-backup cleanup counts removed backups" {
    grep -q 'Removed.*old backups' "$SCRIPT"
}

@test "virtos-backup cleanup handles no backups to remove" {
    grep -q 'No old backups to remove' "$SCRIPT"
}

#==============================================================================
# Verify Operation Tests (Source Analysis)
#==============================================================================

@test "virtos-backup verify requires backup path" {
    grep -A 5 'verify)' "$SCRIPT" | grep -q 'Backup path required'
}

@test "virtos-backup verify checks for checksums file" {
    grep -q 'checksums.sha256' "$SCRIPT"
}

@test "virtos-backup verify handles missing checksums" {
    grep -q 'No checksums found' "$SCRIPT"
}

#==============================================================================
# Error Handling Tests
#==============================================================================

@test "virtos-backup handles non-existent VM" {
    grep -q "VM.*not found" "$SCRIPT"
}

@test "virtos-backup handles missing VM XML" {
    grep -q "VM XML not found" "$SCRIPT"
}

@test "virtos-backup handles backup integrity failure" {
    grep -q "Backup integrity check failed" "$SCRIPT"
}

@test "virtos-backup handles disk backup failure" {
    grep -q "Failed to backup disk" "$SCRIPT"
}

@test "virtos-backup handles disk restore failure" {
    grep -q "Failed to restore disk" "$SCRIPT"
}

@test "virtos-backup handles VM definition failure" {
    grep -q "Failed to define VM" "$SCRIPT"
}

@test "virtos-backup handles S3 copy failure" {
    grep -q "Failed to copy to S3" "$SCRIPT"
}

#==============================================================================
# Logging and Output Tests
#==============================================================================

@test "virtos-backup logs backup start" {
    grep -q "Starting backup of VM" "$SCRIPT"
}

@test "virtos-backup logs VM state" {
    grep -q "VM state:" "$SCRIPT"
}

@test "virtos-backup logs configuration backup" {
    grep -q "Backing up VM configuration" "$SCRIPT"
}

@test "virtos-backup logs disk backup" {
    grep -q "Backing up disk" "$SCRIPT"
}

@test "virtos-backup logs compression" {
    grep -q "Compressing disk image" "$SCRIPT"
}

@test "virtos-backup logs checksum creation" {
    grep -q "Creating checksums" "$SCRIPT"
}

@test "virtos-backup logs archive creation" {
    grep -q "Creating backup archive" "$SCRIPT"
}

@test "virtos-backup logs remote copy" {
    grep -q "Copying to remote destination" "$SCRIPT"
}

@test "virtos-backup logs backup completion" {
    grep -q "Backup completed" "$SCRIPT"
}

@test "virtos-backup displays backup size" {
    grep -q "Backup size:" "$SCRIPT"
}

@test "virtos-backup logs restore start" {
    grep -q "Starting restore of VM" "$SCRIPT"
}

@test "virtos-backup logs extraction" {
    grep -q "Extracting backup" "$SCRIPT"
}

@test "virtos-backup logs integrity verification" {
    grep -q "Verifying backup integrity" "$SCRIPT"
}

#==============================================================================
# Usage Examples Tests
#==============================================================================

@test "virtos-backup help shows backup example" {
    run "$SCRIPT" --help
    [[ "$output" =~ "virtos-backup backup" ]]
}

@test "virtos-backup help shows remote backup example" {
    run "$SCRIPT" --help
    [[ "$output" =~ "--remote" ]]
}

@test "virtos-backup help shows schedule example" {
    run "$SCRIPT" --help
    [[ "$output" =~ "virtos-backup schedule" ]]
}

@test "virtos-backup help shows restore example" {
    run "$SCRIPT" --help
    [[ "$output" =~ "virtos-backup restore" ]]
}

@test "virtos-backup help shows list example" {
    run "$SCRIPT" --help
    [[ "$output" =~ "virtos-backup list" ]]
}

@test "virtos-backup help shows cleanup example" {
    run "$SCRIPT" --help
    [[ "$output" =~ "virtos-backup cleanup" ]]
}
