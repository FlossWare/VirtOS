#!/usr/bin/env bats
# Integration tests for VM lifecycle
#
# Requirements:
# - libvirt-daemon installed and running
# - qemu-kvm installed
# - virtos-* scripts in PATH or loaded from source
# - User in libvirt/kvm groups

load '../test_helper'

setup() {
    # Check for required dependencies
    if ! command -v virsh >/dev/null 2>&1; then
        skip "libvirt not available (install: apt install libvirt-daemon-system qemu-kvm)"
    fi

    if ! systemctl is-active --quiet libvirtd 2>/dev/null; then
        skip "libvirtd not running (start: sudo systemctl start libvirtd)"
    fi

    # Add virtos scripts to PATH if testing from source
    if [ -d "$BATS_TEST_DIRNAME/../../config/custom-scripts" ]; then
        export PATH="$BATS_TEST_DIRNAME/../../config/custom-scripts:$PATH"
    fi

    # Test VM name
    TEST_VM="bats-integration-test-$$"
}

teardown() {
    # Cleanup test VM
    if virsh list --all --name 2>/dev/null | grep -q "^${TEST_VM}\$"; then
        virsh destroy "$TEST_VM" 2>/dev/null || true
        virsh undefine "$TEST_VM" --remove-all-storage 2>/dev/null || true
    fi
}

@test "virsh is available and functional" {
    run virsh version
    [ "$status" -eq 0 ]
}

@test "libvirtd service is running" {
    run systemctl is-active libvirtd
    [ "$status" -eq 0 ]
}

# NOTE: Following tests require virtos-create-vm to be functional
# They are currently placeholders demonstrating the testing approach

@test "VM creation workflow (placeholder)" {
    skip "Requires functional virtos-create-vm script"

    # This test will work once virtos-create-vm is fully integrated
    run virtos-create-vm "$TEST_VM" --memory 512 --disk 5G --cpu 1
    [ "$status" -eq 0 ]

    # Verify VM exists in virsh
    virsh list --all --name | grep -q "^${TEST_VM}\$"
}

@test "VM start/stop workflow (placeholder)" {
    skip "Requires functional virtos-start/virtos-stop scripts"

    # Create test VM first
    virtos-create-vm "$TEST_VM" --memory 512 --disk 5G --cpu 1

    # Start VM
    run virtos-start "$TEST_VM"
    [ "$status" -eq 0 ]

    # Check status
    run virsh domstate "$TEST_VM"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "running" ]]

    # Stop VM
    run virtos-stop "$TEST_VM"
    [ "$status" -eq 0 ]

    # Verify stopped
    run virsh domstate "$TEST_VM"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "shut off" ]]
}

@test "VM snapshot workflow (placeholder)" {
    skip "Requires functional virtos-snapshot script"

    # Create and start test VM
    virtos-create-vm "$TEST_VM" --memory 512 --disk 5G --cpu 1
    virtos-start "$TEST_VM"

    # Create snapshot
    run virtos-snapshot create "$TEST_VM" snap1
    [ "$status" -eq 0 ]

    # List snapshots
    run virtos-snapshot list "$TEST_VM"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "snap1" ]]

    # Restore snapshot
    run virtos-snapshot restore "$TEST_VM" snap1
    [ "$status" -eq 0 ]

    # Delete snapshot
    run virtos-snapshot delete "$TEST_VM" snap1
    [ "$status" -eq 0 ]
}

@test "VM backup/restore workflow (placeholder)" {
    skip "Requires functional virtos-backup script"

    # Create test VM
    virtos-create-vm "$TEST_VM" --memory 512 --disk 5G --cpu 1

    BACKUP_FILE="/tmp/${TEST_VM}-backup.qcow2"

    # Create backup
    run virtos-backup create "$TEST_VM" "$BACKUP_FILE"
    [ "$status" -eq 0 ]
    [ -f "$BACKUP_FILE" ]

    # Delete original VM
    virtos-delete "$TEST_VM"

    # Restore from backup
    run virtos-backup restore "$BACKUP_FILE" "$TEST_VM"
    [ "$status" -eq 0 ]

    # Verify VM exists
    virsh list --all --name | grep -q "^${TEST_VM}\$"

    # Cleanup
    rm -f "$BACKUP_FILE"
}

@test "VM migration workflow (placeholder)" {
    skip "Requires functional virtos-migrate script and multiple hosts"

    # This test requires a multi-host setup
    # Placeholder for future implementation

    # virtos-create-vm "$TEST_VM" --memory 512 --disk 5G
    # virtos-start "$TEST_VM"
    # run virtos-migrate "$TEST_VM" --to other-host
    # [ "$status" -eq 0 ]
}
