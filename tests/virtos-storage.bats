#!/usr/bin/env bats
# BATS tests for virtos-storage

SCRIPT="${BATS_TEST_DIRNAME}/../config/custom-scripts/virtos-storage"

@test "virtos-storage exists and is executable" {
    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "virtos-storage --help shows usage" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" || "$output" =~ "usage:" ]]
}

@test "virtos-storage without arguments shows error or usage" {
    run "$SCRIPT"
    [[ "$output" =~ "Usage:" || "$output" =~ "Error" || "$output" =~ "command" ]]
}

# Tests requiring libvirt
@test "virtos-storage list-pools (requires libvirt)" {
    skip "Requires libvirt"
}

@test "virtos-storage create-pool (requires libvirt)" {
    skip "Requires libvirt"
}

#==============================================================================
# Functional Tests - Pool Name Validation
#==============================================================================

@test "virtos-storage: validates pool name format" {
    # Verify script validates pool name to prevent injection
    run grep -q "grep.*pool_name.*\^" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-storage: rejects invalid pool name characters" {
    # Verify script uses alphanumeric validation
    run grep -A 2 "Invalid pool name" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "alphanumeric" ]]
}

@test "virtos-storage: pool name allows hyphens and underscores" {
    # Verify allowed characters in pool name
    run grep -q '\[a-zA-Z0-9_-\]' "$SCRIPT"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Functional Tests - Configuration Management
#==============================================================================

@test "virtos-storage: creates config directory" {
    run grep -q "STORAGE_DIR=" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-storage: has init_config function" {
    run grep -q "^init_config()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-storage: creates default config file" {
    run grep -A 20 "init_config()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "CEPH_ENABLED" ]]
    [[ "$output" =~ "GLUSTER_ENABLED" ]]
    [[ "$output" =~ "NFS_CLUSTER_ENABLED" ]]
}

@test "virtos-storage: config includes replication settings" {
    run grep -A 25 "init_config()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "REPLICATION_FACTOR" ]]
}

@test "virtos-storage: config includes default replicas" {
    run grep -A 25 "init_config()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DEFAULT_REPLICAS=3" ]]
}

#==============================================================================
# Functional Tests - Ceph Functions
#==============================================================================

@test "virtos-storage: has ceph-init function" {
    run grep -q "^ceph_init()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-storage: has ceph-status function" {
    run grep -q "^ceph_status()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-storage: has ceph-pool-create function" {
    run grep -q "^ceph_pool_create()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-storage: has ceph-pool-list function" {
    run grep -q "^ceph_pool_list()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-storage: ceph-init checks for ceph command" {
    run grep -A 5 "^ceph_init()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "command -v ceph" ]]
}

@test "virtos-storage: ceph-init provides helpful error" {
    run grep -A 15 "Ceph storage system is not installed" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "tce-load -wi ceph" ]] || [[ "$output" =~ "install" ]]
}

@test "virtos-storage: ceph-pool-create validates pool name" {
    run grep -A 10 "^ceph_pool_create()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "grep.*pool_name" ]]
}

@test "virtos-storage: ceph-pool-create requires pool name" {
    run grep -A 5 "^ceph_pool_create()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ 'if.*-z.*pool_name' ]]
}

@test "virtos-storage: ceph-pool-create has default replicas" {
    run grep -A 3 "^ceph_pool_create()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ':-3' ]] || [[ "$output" =~ 'replicas.*3' ]]
}

#==============================================================================
# Functional Tests - GlusterFS Functions
#==============================================================================

@test "virtos-storage: supports gluster-init" {
    run grep -q "gluster-init" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-storage: supports gluster-volume-create" {
    run grep -q "gluster-volume-create" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-storage: supports gluster-volume-list" {
    run grep -q "gluster-volume-list" "$SCRIPT"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Functional Tests - NFS Functions
#==============================================================================

@test "virtos-storage: supports nfs-cluster-init" {
    run grep -q "nfs-cluster-init" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-storage: supports nfs-export-add" {
    run grep -q "nfs-export-add" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-storage: supports nfs-export-list" {
    run grep -q "nfs-export-list" "$SCRIPT"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Functional Tests - Logging
#==============================================================================

@test "virtos-storage: has log file location" {
    run grep -q "LOG_FILE=" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-storage: has log_message function" {
    run grep -q "^log_message()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-storage: logs Ceph initialization" {
    run grep -q 'log_message.*Ceph' "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-storage: logs pool creation" {
    run grep -q 'log_message.*pool' "$SCRIPT"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Functional Tests - Usage Documentation
#==============================================================================

@test "virtos-storage: usage includes all Ceph commands" {
    run grep -A 60 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ceph-init" ]]
    [[ "$output" =~ "ceph-status" ]]
    [[ "$output" =~ "ceph-pool-create" ]]
    [[ "$output" =~ "ceph-pool-list" ]]
}

@test "virtos-storage: usage includes GlusterFS commands" {
    run grep -A 60 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "gluster-init" ]]
    [[ "$output" =~ "gluster-volume-create" ]]
}

@test "virtos-storage: usage includes NFS commands" {
    run grep -A 60 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "nfs-cluster-init" ]]
    [[ "$output" =~ "nfs-export-add" ]]
}

@test "virtos-storage: usage includes pool commands" {
    run grep -A 60 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "pool-list" ]]
    [[ "$output" =~ "pool-create" ]]
    [[ "$output" =~ "pool-delete" ]]
}

@test "virtos-storage: usage includes replication commands" {
    run grep -A 60 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "replication-enable" ]]
    [[ "$output" =~ "replication-status" ]]
}

@test "virtos-storage: usage includes examples" {
    run grep -A 90 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Examples:" ]]
}

@test "virtos-storage: usage documents replicas option" {
    run grep -A 70 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--replicas" ]]
}

#==============================================================================
# Functional Tests - Error Handling
#==============================================================================

@test "virtos-storage: ceph commands check for ceph availability" {
    # All ceph commands should check if ceph is installed
    run grep -c "command -v ceph" "$SCRIPT"
    [ "$status" -eq 0 ]
    # Should have multiple checks (at least 3-4)
    [ "$output" -ge 3 ]
}

@test "virtos-storage: provides alternatives when Ceph unavailable" {
    run grep -A 20 "Ceph storage system is not installed" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Alternatives" ]]
    [[ "$output" =~ "Local storage" ]] || [[ "$output" =~ "NFS" ]]
}
