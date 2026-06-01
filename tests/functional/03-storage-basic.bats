#!/usr/bin/env bats
# Functional tests for storage pool operations

TEST_POOL_NAME="virtos-test-pool-$$"
TEST_POOL_DIR="/var/tmp/virtos-test-pool-$$"
TEST_VOL_NAME="test-vol-$$"

setup() {
    if [ "$EUID" -ne 0 ]; then
        skip "Tests require root privileges"
    fi

    if ! systemctl is-active --quiet libvirtd; then
        skip "libvirtd service not running"
    fi

    # Clean up any previous test pool
    if virsh pool-list --all --name | grep -q "^${TEST_POOL_NAME}$"; then
        virsh pool-destroy "$TEST_POOL_NAME" 2>/dev/null || true
        virsh pool-undefine "$TEST_POOL_NAME" 2>/dev/null || true
    fi
    rm -rf "$TEST_POOL_DIR"
}

teardown() {
    if virsh pool-list --all --name | grep -q "^${TEST_POOL_NAME}$"; then
        virsh pool-destroy "$TEST_POOL_NAME" 2>/dev/null || true
        virsh pool-undefine "$TEST_POOL_NAME" 2>/dev/null || true
    fi
    rm -rf "$TEST_POOL_DIR"
}

@test "can create storage pool directory" {
    mkdir -p "$TEST_POOL_DIR"
    [ -d "$TEST_POOL_DIR" ]
}

@test "can define storage pool" {
    mkdir -p "$TEST_POOL_DIR"

    # Define pool
    virsh pool-define-as "$TEST_POOL_NAME" dir - - - - "$TEST_POOL_DIR"

    # Verify pool exists
    virsh pool-list --all --name | grep -q "^${TEST_POOL_NAME}$"
}

@test "can start storage pool" {
    mkdir -p "$TEST_POOL_DIR"
    virsh pool-define-as "$TEST_POOL_NAME" dir - - - - "$TEST_POOL_DIR"

    # Start pool
    virsh pool-start "$TEST_POOL_NAME"

    # Verify pool is active
    virsh pool-list --name | grep -q "^${TEST_POOL_NAME}$"
}

@test "can create volume in pool" {
    mkdir -p "$TEST_POOL_DIR"
    virsh pool-define-as "$TEST_POOL_NAME" dir - - - - "$TEST_POOL_DIR"
    virsh pool-start "$TEST_POOL_NAME"

    # Create volume
    virsh vol-create-as "$TEST_POOL_NAME" "$TEST_VOL_NAME" 1G

    # Verify volume exists
    virsh vol-list "$TEST_POOL_NAME" --details | grep -q "$TEST_VOL_NAME"
}

@test "can delete volume from pool" {
    mkdir -p "$TEST_POOL_DIR"
    virsh pool-define-as "$TEST_POOL_NAME" dir - - - - "$TEST_POOL_DIR"
    virsh pool-start "$TEST_POOL_NAME"
    virsh vol-create-as "$TEST_POOL_NAME" "$TEST_VOL_NAME" 1G

    # Delete volume
    virsh vol-delete "$TEST_VOL_NAME" --pool "$TEST_POOL_NAME"

    # Verify volume is gone
    ! virsh vol-list "$TEST_POOL_NAME" --details | grep -q "$TEST_VOL_NAME"
}

@test "can stop and undefine pool" {
    mkdir -p "$TEST_POOL_DIR"
    virsh pool-define-as "$TEST_POOL_NAME" dir - - - - "$TEST_POOL_DIR"
    virsh pool-start "$TEST_POOL_NAME"

    # Stop pool
    virsh pool-destroy "$TEST_POOL_NAME"

    # Verify pool is inactive
    ! virsh pool-list --name | grep -q "^${TEST_POOL_NAME}$"

    # Undefine pool
    virsh pool-undefine "$TEST_POOL_NAME"

    # Verify pool is gone
    ! virsh pool-list --all --name | grep -q "^${TEST_POOL_NAME}$"
}

@test "storage pool full workflow" {
    # 1. Create directory
    mkdir -p "$TEST_POOL_DIR"
    [ -d "$TEST_POOL_DIR" ]

    # 2. Define pool
    virsh pool-define-as "$TEST_POOL_NAME" dir - - - - "$TEST_POOL_DIR"
    virsh pool-list --all --name | grep -q "^${TEST_POOL_NAME}$"

    # 3. Start pool
    virsh pool-start "$TEST_POOL_NAME"
    virsh pool-list --name | grep -q "^${TEST_POOL_NAME}$"

    # 4. Create volume
    virsh vol-create-as "$TEST_POOL_NAME" "$TEST_VOL_NAME" 1G
    virsh vol-list "$TEST_POOL_NAME" --details | grep -q "$TEST_VOL_NAME"

    # 5. Get volume path
    local vol_path=$(virsh vol-path "$TEST_VOL_NAME" --pool "$TEST_POOL_NAME")
    [ -f "$vol_path" ]

    # 6. Delete volume
    virsh vol-delete "$TEST_VOL_NAME" --pool "$TEST_POOL_NAME"
    ! virsh vol-list "$TEST_POOL_NAME" --details | grep -q "$TEST_VOL_NAME"

    # 7. Stop pool
    virsh pool-destroy "$TEST_POOL_NAME"

    # 8. Undefine pool
    virsh pool-undefine "$TEST_POOL_NAME"
    ! virsh pool-list --all --name | grep -q "^${TEST_POOL_NAME}$"
}
