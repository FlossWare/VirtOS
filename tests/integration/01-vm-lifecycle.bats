#!/usr/bin/env bats
# Integration tests for VM lifecycle
#
# Requirements:
# - libvirt-daemon installed and running
# - qemu-kvm installed
# - virtos-* scripts in PATH or loaded from source
# - User in libvirt/kvm groups
# - Sufficient disk space (/var/lib/libvirt/images)

load '../test_helper'

setup() {
    # Check for required dependencies
    if ! command -v virsh >/dev/null 2>&1; then
        skip "libvirt not available (install: apt install libvirt-daemon-system qemu-kvm)"
    fi

    if ! systemctl is-active --quiet libvirtd 2>/dev/null; then
        skip "libvirtd not running (start: sudo systemctl start libvirtd)"
    fi

    if ! command -v qemu-img >/dev/null 2>&1; then
        skip "qemu-img not available (install: apt install qemu-utils)"
    fi

    # Add virtos scripts to PATH if testing from source
    if [ -d "$BATS_TEST_DIRNAME/../../config/custom-scripts" ]; then
        export PATH="$BATS_TEST_DIRNAME/../../config/custom-scripts:$PATH"
    fi

    # Verify virtos-create-vm is available
    if ! command -v virtos-create-vm >/dev/null 2>&1; then
        skip "virtos-create-vm not in PATH"
    fi

    # Test VM name (unique per test run)
    TEST_VM="bats-test-vm-$$"

    # VM configuration
    TEST_CPU=1
    TEST_RAM=512
    TEST_DISK="2G"

    # Backup/snapshot names
    BACKUP_DIR="/tmp/virtos-test-backups-$$"
    SNAPSHOT_NAME="test-snapshot-$$"
}

teardown() {
    # Cleanup test VM
    if virsh list --all --name 2>/dev/null | grep -q "^${TEST_VM}\$"; then
        virsh destroy "$TEST_VM" 2>/dev/null || true
        virsh undefine "$TEST_VM" --remove-all-storage 2>/dev/null || true
    fi

    # Cleanup backup directory
    if [ -d "$BACKUP_DIR" ]; then
        rm -rf "$BACKUP_DIR"
    fi

    # Cleanup any test disk images in default location
    if [ -f "/var/lib/libvirt/images/${TEST_VM}.qcow2" ]; then
        sudo rm -f "/var/lib/libvirt/images/${TEST_VM}.qcow2" 2>/dev/null || true
    fi
}

# ==============================================================================
# Prerequisites
# ==============================================================================

@test "virsh is available and functional" {
    run virsh version
    [ "$status" -eq 0 ]
}

@test "libvirtd service is running" {
    run systemctl is-active libvirtd
    [ "$status" -eq 0 ]
}

@test "qemu-img is available" {
    run qemu-img --version
    [ "$status" -eq 0 ]
}

# ==============================================================================
# VM Creation
# ==============================================================================

@test "create VM with basic parameters" {
    run virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK"
    echo "Output: $output" >&3
    [ "$status" -eq 0 ]

    # Verify VM exists in virsh
    run virsh list --all --name
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^${TEST_VM}\$"
}

@test "create VM fails with duplicate name" {
    # Create first VM
    virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK"

    # Try to create duplicate
    run virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK"
    echo "Output: $output" >&3
    [ "$status" -ne 0 ]
}

@test "create VM with custom network type" {
    run virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK" --network nat
    echo "Output: $output" >&3
    [ "$status" -eq 0 ]

    # Verify VM XML contains network configuration
    run virsh dumpxml "$TEST_VM"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "<interface"
}

@test "dry-run does not create VM" {
    run virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK" --dry-run
    echo "Output: $output" >&3
    [ "$status" -eq 0 ]

    # Verify VM does NOT exist
    run virsh list --all --name
    [ "$status" -eq 0 ]
    ! echo "$output" | grep -q "^${TEST_VM}\$"
}

# ==============================================================================
# VM State Management
# ==============================================================================

@test "start VM after creation" {
    # Create VM first
    virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK"

    # Start VM
    run virsh start "$TEST_VM"
    echo "Output: $output" >&3
    [ "$status" -eq 0 ]

    # Verify state is running
    run virsh domstate "$TEST_VM"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "running" ]]
}

@test "stop running VM" {
    # Create and start VM
    virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK" --auto-start

    # Give VM time to start
    sleep 2

    # Stop VM
    run virsh shutdown "$TEST_VM"
    echo "Output: $output" >&3
    [ "$status" -eq 0 ]

    # Wait for shutdown (graceful)
    sleep 3

    # Verify state (should be shut off or shutting down)
    run virsh domstate "$TEST_VM"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "shut off" ]] || [[ "$output" =~ "in shutdown" ]]
}

@test "force destroy running VM" {
    # Create and start VM
    virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK" --auto-start

    # Give VM time to start
    sleep 2

    # Force destroy
    run virsh destroy "$TEST_VM"
    echo "Output: $output" >&3
    [ "$status" -eq 0 ]

    # Verify state
    run virsh domstate "$TEST_VM"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "shut off" ]]
}

# ==============================================================================
# VM Snapshots
# ==============================================================================

@test "create snapshot of stopped VM" {
    # Create VM
    virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK"

    # Create snapshot
    run virtos-snapshot create "$TEST_VM" "Test snapshot"
    echo "Output: $output" >&3
    [ "$status" -eq 0 ]

    # Verify snapshot exists
    run virsh snapshot-list "$TEST_VM" --name
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "list snapshots for VM" {
    # Create VM
    virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK"

    # Create two snapshots
    virtos-snapshot create "$TEST_VM" "Snapshot 1"
    virtos-snapshot create "$TEST_VM" "Snapshot 2"

    # List snapshots
    run virtos-snapshot list "$TEST_VM"
    echo "Output: $output" >&3
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Snapshot" ]]
}

@test "revert VM to snapshot" {
    # Create VM
    virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK"

    # Create snapshot
    virtos-snapshot create "$TEST_VM" "Pre-change snapshot"

    # Get snapshot name
    snapshot_name=$(virsh snapshot-list "$TEST_VM" --name | head -1)

    # Revert to snapshot
    run virtos-snapshot revert "$TEST_VM" "$snapshot_name"
    echo "Output: $output" >&3
    [ "$status" -eq 0 ]
}

@test "delete snapshot" {
    # Create VM
    virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK"

    # Create snapshot
    virtos-snapshot create "$TEST_VM" "Temporary snapshot"

    # Get snapshot name
    snapshot_name=$(virsh snapshot-list "$TEST_VM" --name | head -1)

    # Delete snapshot
    run virtos-snapshot delete "$TEST_VM" "$snapshot_name"
    echo "Output: $output" >&3
    [ "$status" -eq 0 ]

    # Verify snapshot is gone
    run virsh snapshot-list "$TEST_VM" --name
    [ "$status" -eq 0 ]
    ! echo "$output" | grep -q "$snapshot_name"
}

# ==============================================================================
# VM Backup and Restore
# ==============================================================================

@test "backup VM to directory" {
    # Create backup directory
    mkdir -p "$BACKUP_DIR"

    # Create VM
    virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK"

    # Backup VM
    run virtos-backup backup "$TEST_VM" --path "$BACKUP_DIR"
    echo "Output: $output" >&3
    [ "$status" -eq 0 ]

    # Verify backup files exist
    [ -d "$BACKUP_DIR/$TEST_VM" ]
    [ -f "$BACKUP_DIR/$TEST_VM/${TEST_VM}.xml" ]
}

@test "restore VM from backup" {
    # Create backup directory
    mkdir -p "$BACKUP_DIR"

    # Create VM
    virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK"

    # Backup VM
    virtos-backup backup "$TEST_VM" --path "$BACKUP_DIR"

    # Delete original VM
    virsh destroy "$TEST_VM" 2>/dev/null || true
    virsh undefine "$TEST_VM" --remove-all-storage 2>/dev/null || true

    # Verify VM is gone
    run virsh list --all --name
    ! echo "$output" | grep -q "^${TEST_VM}\$"

    # Restore from backup
    run virtos-backup restore "$BACKUP_DIR/$TEST_VM" "$TEST_VM"
    echo "Output: $output" >&3
    [ "$status" -eq 0 ]

    # Verify VM exists again
    run virsh list --all --name
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^${TEST_VM}\$"
}

# ==============================================================================
# VM Information and Monitoring
# ==============================================================================

@test "get VM configuration" {
    # Create VM
    virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK"

    # Get VM XML
    run virsh dumpxml "$TEST_VM"
    echo "Output: $output" >&3
    [ "$status" -eq 0 ]
    [[ "$output" =~ "<domain" ]]
    [[ "$output" =~ "$TEST_VM" ]]
}

@test "get VM domain info" {
    # Create VM
    virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK"

    # Get domain info
    run virsh dominfo "$TEST_VM"
    echo "Output: $output" >&3
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Name:" ]]
    [[ "$output" =~ "$TEST_VM" ]]
}

# NOTE: Following tests require multi-host setup or additional infrastructure
# They are placeholders for future implementation when test environment supports them

@test "VM migration workflow (requires multi-host)" {
    skip "Requires multi-host libvirt setup"

    # This test would work in a multi-host environment:
    # virtos-create-vm --name "$TEST_VM" --cpu "$TEST_CPU" --ram "$TEST_RAM" --disk "$TEST_DISK"
    # virsh start "$TEST_VM"
    # run virtos-migrate "$TEST_VM" --to other-host
    # [ "$status" -eq 0 ]
}
