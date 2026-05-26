#!/usr/bin/env bats
# Integration tests for VirtOS storage management
#
# Requirements:
# - libvirt-daemon installed and running
# - virtos-storage script functional
# - qemu-img command available

load '../test_helper'

setup() {
    # Check for required dependencies
    if ! command -v virsh >/dev/null 2>&1; then
        skip "libvirt not available"
    fi

    if ! systemctl is-active --quiet libvirtd 2>/dev/null; then
        skip "libvirtd not running"
    fi

    if ! command -v qemu-img >/dev/null 2>&1; then
        skip "qemu-img not available"
    fi

    # Add virtos scripts to PATH
    if [ -d "$BATS_TEST_DIRNAME/../../config/custom-scripts" ]; then
        export PATH="$BATS_TEST_DIRNAME/../../config/custom-scripts:$PATH"
    fi

    # Test pool and volume names
    TEST_POOL="bats-test-pool-$$"
    TEST_VOLUME="bats-test-vol-$$"
    TEST_POOL_DIR="/tmp/${TEST_POOL}"
}

teardown() {
    # Cleanup test volumes
    if virsh vol-list "$TEST_POOL" 2>/dev/null | grep -q "$TEST_VOLUME"; then
        virsh vol-delete "$TEST_VOLUME" --pool "$TEST_POOL" 2>/dev/null || true
    fi

    # Cleanup test pool
    if virsh pool-list --all --name 2>/dev/null | grep -q "^${TEST_POOL}\$"; then
        virsh pool-destroy "$TEST_POOL" 2>/dev/null || true
        virsh pool-undefine "$TEST_POOL" 2>/dev/null || true
    fi

    # Cleanup pool directory
    rm -rf "$TEST_POOL_DIR"
}

@test "virsh storage commands are available" {
    run virsh pool-list
    [ "$status" -eq 0 ]
}

@test "qemu-img command is available" {
    run qemu-img --version
    [ "$status" -eq 0 ]
}

# NOTE: Following tests require virtos-storage to be functional
# They are currently placeholders demonstrating the testing approach

@test "create directory-based storage pool (placeholder)" {
    skip "Requires functional virtos-storage script"

    mkdir -p "$TEST_POOL_DIR"

    # Create storage pool
    run virtos-storage create-pool "$TEST_POOL" --type dir --path "$TEST_POOL_DIR"
    [ "$status" -eq 0 ]

    # Verify pool exists
    virsh pool-list --all --name | grep -q "^${TEST_POOL}\$"

    # Start pool
    run virtos-storage start-pool "$TEST_POOL"
    [ "$status" -eq 0 ]

    # Set pool to autostart
    run virtos-storage autostart-pool "$TEST_POOL"
    [ "$status" -eq 0 ]

    # Verify pool is active
    run virsh pool-info "$TEST_POOL"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "State.*running" ]]
}

@test "create volume in storage pool (placeholder)" {
    skip "Requires functional virtos-storage script"

    # Setup pool
    mkdir -p "$TEST_POOL_DIR"
    virtos-storage create-pool "$TEST_POOL" --type dir --path "$TEST_POOL_DIR"
    virtos-storage start-pool "$TEST_POOL"

    # Create volume (10GB)
    run virtos-storage create-volume "$TEST_POOL" "$TEST_VOLUME" --size 10G --format qcow2
    [ "$status" -eq 0 ]

    # Verify volume exists
    virsh vol-list "$TEST_POOL" | grep -q "$TEST_VOLUME"

    # Check volume info
    run virsh vol-info "$TEST_VOLUME" --pool "$TEST_POOL"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Type.*file" ]]
    [[ "$output" =~ "Capacity.*10" ]]
}

@test "resize volume (placeholder)" {
    skip "Requires functional virtos-storage script"

    # Setup pool and volume
    mkdir -p "$TEST_POOL_DIR"
    virtos-storage create-pool "$TEST_POOL" --type dir --path "$TEST_POOL_DIR"
    virtos-storage start-pool "$TEST_POOL"
    virtos-storage create-volume "$TEST_POOL" "$TEST_VOLUME" --size 10G --format qcow2

    # Resize volume to 20GB
    run virtos-storage resize-volume "$TEST_POOL" "$TEST_VOLUME" 20G
    [ "$status" -eq 0 ]

    # Verify new size
    run virsh vol-info "$TEST_VOLUME" --pool "$TEST_POOL"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Capacity.*20" ]]
}

@test "clone volume (placeholder)" {
    skip "Requires functional virtos-storage script"

    # Setup pool and source volume
    mkdir -p "$TEST_POOL_DIR"
    virtos-storage create-pool "$TEST_POOL" --type dir --path "$TEST_POOL_DIR"
    virtos-storage start-pool "$TEST_POOL"
    virtos-storage create-volume "$TEST_POOL" "$TEST_VOLUME" --size 5G --format qcow2

    # Clone volume
    CLONE_NAME="${TEST_VOLUME}-clone"
    run virtos-storage clone-volume "$TEST_POOL" "$TEST_VOLUME" "$CLONE_NAME"
    [ "$status" -eq 0 ]

    # Verify clone exists
    virsh vol-list "$TEST_POOL" | grep -q "$CLONE_NAME"

    # Cleanup clone
    virsh vol-delete "$CLONE_NAME" --pool "$TEST_POOL" 2>/dev/null || true
}

@test "attach volume to VM (placeholder)" {
    skip "Requires functional virtos-storage and test VM"

    TEST_VM="bats-storage-vm-$$"

    # Setup pool and volume
    mkdir -p "$TEST_POOL_DIR"
    virtos-storage create-pool "$TEST_POOL" --type dir --path "$TEST_POOL_DIR"
    virtos-storage start-pool "$TEST_POOL"
    virtos-storage create-volume "$TEST_POOL" "$TEST_VOLUME" --size 5G --format qcow2

    # Create test VM
    virtos-create-vm "$TEST_VM" --memory 512 --disk 5G

    # Attach volume to VM
    run virtos-storage attach-disk "$TEST_VM" "$TEST_POOL/$TEST_VOLUME" --target vdb
    [ "$status" -eq 0 ]

    # Verify attachment in VM config
    run virsh dumpxml "$TEST_VM"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "$TEST_VOLUME" ]]
    [[ "$output" =~ "vdb" ]]

    # Cleanup VM
    virsh destroy "$TEST_VM" 2>/dev/null || true
    virsh undefine "$TEST_VM" --remove-all-storage 2>/dev/null || true
}

@test "snapshot volume (placeholder)" {
    skip "Requires functional virtos-storage script"

    # Setup pool and volume
    mkdir -p "$TEST_POOL_DIR"
    virtos-storage create-pool "$TEST_POOL" --type dir --path "$TEST_POOL_DIR"
    virtos-storage start-pool "$TEST_POOL"
    virtos-storage create-volume "$TEST_POOL" "$TEST_VOLUME" --size 5G --format qcow2

    # Create snapshot
    SNAPSHOT_NAME="${TEST_VOLUME}-snap1"
    run virtos-storage snapshot-volume "$TEST_POOL" "$TEST_VOLUME" "$SNAPSHOT_NAME"
    [ "$status" -eq 0 ]

    # Verify snapshot exists
    virsh vol-list "$TEST_POOL" | grep -q "$SNAPSHOT_NAME"
}

@test "list storage pools and volumes (placeholder)" {
    skip "Requires functional virtos-storage script"

    # Create multiple pools
    mkdir -p "${TEST_POOL_DIR}-1" "${TEST_POOL_DIR}-2"
    virtos-storage create-pool "${TEST_POOL}-1" --type dir --path "${TEST_POOL_DIR}-1"
    virtos-storage create-pool "${TEST_POOL}-2" --type dir --path "${TEST_POOL_DIR}-2"
    virtos-storage start-pool "${TEST_POOL}-1"
    virtos-storage start-pool "${TEST_POOL}-2"

    # Create volumes in each pool
    virtos-storage create-volume "${TEST_POOL}-1" "vol1" --size 5G --format qcow2
    virtos-storage create-volume "${TEST_POOL}-2" "vol2" --size 10G --format qcow2

    # List all pools
    run virtos-storage list-pools
    [ "$status" -eq 0 ]
    [[ "$output" =~ "${TEST_POOL}-1" ]]
    [[ "$output" =~ "${TEST_POOL}-2" ]]

    # List volumes in specific pool
    run virtos-storage list-volumes "${TEST_POOL}-1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "vol1" ]]

    # Cleanup
    for pool in "${TEST_POOL}-1" "${TEST_POOL}-2"; do
        virsh pool-destroy "$pool" 2>/dev/null || true
        virsh pool-undefine "$pool" 2>/dev/null || true
    done
    rm -rf "${TEST_POOL_DIR}-1" "${TEST_POOL_DIR}-2"
}

@test "storage pool refresh (placeholder)" {
    skip "Requires functional virtos-storage script"

    # Setup pool
    mkdir -p "$TEST_POOL_DIR"
    virtos-storage create-pool "$TEST_POOL" --type dir --path "$TEST_POOL_DIR"
    virtos-storage start-pool "$TEST_POOL"

    # Create a volume file directly (not via libvirt)
    qemu-img create -f qcow2 "$TEST_POOL_DIR/external-vol.qcow2" 1G

    # Refresh pool to detect external volume
    run virtos-storage refresh-pool "$TEST_POOL"
    [ "$status" -eq 0 ]

    # Verify external volume is now listed
    run virsh vol-list "$TEST_POOL"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "external-vol.qcow2" ]]
}

@test "delete storage pool and volumes (placeholder)" {
    skip "Requires functional virtos-storage script"

    # Setup pool with volumes
    mkdir -p "$TEST_POOL_DIR"
    virtos-storage create-pool "$TEST_POOL" --type dir --path "$TEST_POOL_DIR"
    virtos-storage start-pool "$TEST_POOL"
    virtos-storage create-volume "$TEST_POOL" "vol1" --size 5G --format qcow2
    virtos-storage create-volume "$TEST_POOL" "vol2" --size 5G --format qcow2

    # Delete volumes
    run virtos-storage delete-volume "$TEST_POOL" "vol1"
    [ "$status" -eq 0 ]
    run virtos-storage delete-volume "$TEST_POOL" "vol2"
    [ "$status" -eq 0 ]

    # Stop and delete pool
    run virtos-storage stop-pool "$TEST_POOL"
    [ "$status" -eq 0 ]
    run virtos-storage delete-pool "$TEST_POOL"
    [ "$status" -eq 0 ]

    # Verify pool no longer exists
    ! virsh pool-list --all --name | grep -q "^${TEST_POOL}\$"
}
