#!/usr/bin/env bats
# Tests for VirtOS path configuration system (virtos-paths.conf + get_virtos_path)
# Tests path loading, path retrieval, validation, and auto-creation features

# Setup - Load common library
setup() {
    # Load virtos-common.sh for testing
    if [ -f "../../config/custom-scripts/lib/virtos-common.sh" ]; then
        # shellcheck source=/dev/null
        . "../../config/custom-scripts/lib/virtos-common.sh"
    elif [ -f "/usr/local/lib/virtos-common.sh" ]; then
        # shellcheck source=/dev/null
        . /usr/local/lib/virtos-common.sh
    else
        skip "virtos-common.sh not found"
    fi
}

#==============================================================================
# Path Configuration Loading Tests
#==============================================================================

@test "virtos-paths: configuration file exists and is readable" {
    # Check development location
    local found=0
    if [ -f "../../config/custom-scripts/lib/virtos-paths.conf" ]; then
        [ -r "../../config/custom-scripts/lib/virtos-paths.conf" ]
        found=1
    fi
    # Check installed location
    if [ "$found" -eq 0 ] && [ -f "/usr/local/lib/virtos-paths.conf" ]; then
        [ -r "/usr/local/lib/virtos-paths.conf" ]
        found=1
    fi

    if [ "$found" -eq 0 ]; then
        skip "virtos-paths.conf not found"
    fi
}

@test "virtos-paths: configuration loads without errors" {
    run _load_virtos_paths
    [ "$status" -eq 0 ]
}

@test "virtos-paths: configuration defines VIRTOS_ETC_DIR" {
    _load_virtos_paths
    [ -n "$VIRTOS_ETC_DIR" ]
}

@test "virtos-paths: configuration defines VIRTOS_LOG_DIR" {
    _load_virtos_paths
    [ -n "$VIRTOS_LOG_DIR" ]
}

@test "virtos-paths: configuration defines VIRTOS_VERSION_FILE" {
    _load_virtos_paths
    [ -n "$VIRTOS_VERSION_FILE" ]
}

@test "virtos-paths: configuration loads only once (idempotent)" {
    _load_virtos_paths
    local first_value="$VIRTOS_ETC_DIR"
    _load_virtos_paths
    [ "$VIRTOS_ETC_DIR" = "$first_value" ]
}

#==============================================================================
# get_virtos_path() Basic Functionality Tests
#==============================================================================

@test "get_virtos_path: returns error if no path variable provided" {
    run get_virtos_path
    [ "$status" -ne 0 ]
}

@test "get_virtos_path: returns error for undefined path variable" {
    run get_virtos_path "NONEXISTENT_PATH_VARIABLE"
    [ "$status" -ne 0 ]
}

@test "get_virtos_path: returns ETC_DIR path successfully" {
    run get_virtos_path "ETC_DIR"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "get_virtos_path: returns LOG_DIR path successfully" {
    run get_virtos_path "LOG_DIR"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "get_virtos_path: returns VERSION_FILE path successfully" {
    run get_virtos_path "VERSION_FILE"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "get_virtos_path: returns SSH_CONFIG path successfully" {
    run get_virtos_path "SSH_CONFIG"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "get_virtos_path: returns CLUSTER_CONF path successfully" {
    run get_virtos_path "CLUSTER_CONF"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "get_virtos_path: returns STORAGE_POOL_DEFAULT path successfully" {
    run get_virtos_path "STORAGE_POOL_DEFAULT"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "get_virtos_path: returned path matches environment variable" {
    _load_virtos_paths
    local expected="$VIRTOS_ETC_DIR"
    local actual
    actual=$(get_virtos_path "ETC_DIR")
    [ "$actual" = "$expected" ]
}

#==============================================================================
# get_virtos_path() Writable Check Tests
#==============================================================================

@test "get_virtos_path: writable flag fails for non-writable path" {
    # /etc is typically not writable by non-root users
    if [ "$(id -u)" -ne 0 ]; then
        run get_virtos_path "SSH_CONFIG" "writable"
        # Should fail if parent directory (/etc/ssh) is not writable
        [ "$status" -ne 0 ] || skip "SSH_CONFIG parent is writable (unexpected)"
    else
        skip "Running as root - writable check not meaningful"
    fi
}

@test "get_virtos_path: writable flag succeeds for writable path" {
    # Create a temporary writable path
    local temp_dir
    temp_dir=$(mktemp -d)
    export VIRTOS_TEST_WRITABLE_PATH="$temp_dir/test.conf"

    # Reload paths to pick up new variable
    _virtos_paths_loaded=0
    _load_virtos_paths

    run get_virtos_path "TEST_WRITABLE_PATH" "writable"
    [ "$status" -eq 0 ]

    # Cleanup
    rm -rf "$temp_dir"
    unset VIRTOS_TEST_WRITABLE_PATH
}

#==============================================================================
# get_virtos_path() Auto-Create Tests
#==============================================================================

@test "get_virtos_path: create flag creates missing directory for file path" {
    local temp_base
    temp_base=$(mktemp -d)
    local test_path="$temp_base/newdir/test.conf"
    export VIRTOS_TEST_CREATE_PATH="$test_path"

    # Reload paths
    _virtos_paths_loaded=0
    _load_virtos_paths

    # Directory should not exist yet
    [ ! -d "$temp_base/newdir" ]

    # get_virtos_path with create should create it
    run get_virtos_path "TEST_CREATE_PATH" "" "create"
    [ "$status" -eq 0 ]
    [ -d "$temp_base/newdir" ]

    # Cleanup
    rm -rf "$temp_base"
    unset VIRTOS_TEST_CREATE_PATH
}

@test "get_virtos_path: create flag creates missing directory path" {
    local temp_base
    temp_base=$(mktemp -d)
    local test_path="$temp_base/newdir/"
    export VIRTOS_TEST_CREATE_DIR="$test_path"

    # Reload paths
    _virtos_paths_loaded=0
    _load_virtos_paths

    # Directory should not exist yet
    [ ! -d "$temp_base/newdir" ]

    # get_virtos_path with create should create it
    run get_virtos_path "TEST_CREATE_DIR" "" "create"
    [ "$status" -eq 0 ]
    [ -d "$temp_base/newdir" ]

    # Cleanup
    rm -rf "$temp_base"
    unset VIRTOS_TEST_CREATE_DIR
}

@test "get_virtos_path: create flag succeeds if directory already exists" {
    local temp_dir
    temp_dir=$(mktemp -d)
    export VIRTOS_TEST_EXISTING_DIR="$temp_dir/"

    # Reload paths
    _virtos_paths_loaded=0
    _load_virtos_paths

    # Directory already exists
    [ -d "$temp_dir" ]

    # Should succeed without error
    run get_virtos_path "TEST_EXISTING_DIR" "" "create"
    [ "$status" -eq 0 ]

    # Cleanup
    rm -rf "$temp_dir"
    unset VIRTOS_TEST_EXISTING_DIR
}

#==============================================================================
# ensure_virtos_path() Convenience Function Tests
#==============================================================================

@test "ensure_virtos_path: creates directory and returns path" {
    local temp_base
    temp_base=$(mktemp -d)
    local test_path="$temp_base/ensuredir/test.log"
    export VIRTOS_TEST_ENSURE_PATH="$test_path"

    # Reload paths
    _virtos_paths_loaded=0
    _load_virtos_paths

    # Directory should not exist yet
    [ ! -d "$temp_base/ensuredir" ]

    # ensure_virtos_path should create and return path
    run ensure_virtos_path "TEST_ENSURE_PATH"
    [ "$status" -eq 0 ]
    [ "$output" = "$test_path" ]
    [ -d "$temp_base/ensuredir" ]

    # Cleanup
    rm -rf "$temp_base"
    unset VIRTOS_TEST_ENSURE_PATH
}

@test "ensure_virtos_path: fails for undefined path variable" {
    run ensure_virtos_path "NONEXISTENT_ENSURE_PATH"
    [ "$status" -ne 0 ]
}

#==============================================================================
# validate_virtos_path_writable() Function Tests
#==============================================================================

@test "validate_virtos_path_writable: returns 0 for writable path" {
    local temp_dir
    temp_dir=$(mktemp -d)
    export VIRTOS_TEST_WRITABLE_VALIDATE="$temp_dir/test.conf"

    # Reload paths
    _virtos_paths_loaded=0
    _load_virtos_paths

    run validate_virtos_path_writable "TEST_WRITABLE_VALIDATE"
    [ "$status" -eq 0 ]

    # Cleanup
    rm -rf "$temp_dir"
    unset VIRTOS_TEST_WRITABLE_VALIDATE
}

@test "validate_virtos_path_writable: returns non-zero for non-writable path" {
    if [ "$(id -u)" -ne 0 ]; then
        run validate_virtos_path_writable "SSH_CONFIG"
        # Should fail if /etc/ssh is not writable
        [ "$status" -ne 0 ] || skip "SSH_CONFIG parent is writable (unexpected)"
    else
        skip "Running as root - writable check not meaningful"
    fi
}

@test "validate_virtos_path_writable: returns non-zero for undefined path" {
    run validate_virtos_path_writable "NONEXISTENT_WRITABLE_PATH"
    [ "$status" -ne 0 ]
}

#==============================================================================
# Path Override Tests (Environment Variable Priority)
#==============================================================================

@test "get_virtos_path: respects environment variable override" {
    # Set custom override
    export VIRTOS_ETC_DIR="/custom/etc/path"

    # Reload paths to pick up override
    _virtos_paths_loaded=0
    _load_virtos_paths

    # Should return custom path
    run get_virtos_path "ETC_DIR"
    [ "$status" -eq 0 ]
    [ "$output" = "/custom/etc/path" ]

    # Cleanup
    unset VIRTOS_ETC_DIR
}

#==============================================================================
# Integration Tests with get_version()
#==============================================================================

@test "get_version: uses get_virtos_path for version file lookup" {
    # This test verifies that get_version() integrates with path system
    run get_version
    [ "$status" -eq 0 ]
    # Should return a version string (format: X.Y or X.Y.Z)
    [[ "$output" =~ ^[0-9]+\.[0-9]+ ]]
}

#==============================================================================
# Path Categories Coverage Tests
#==============================================================================

@test "get_virtos_path: log paths are defined (sample: LOG_MONITOR)" {
    run get_virtos_path "LOG_MONITOR"
    [ "$status" -eq 0 ]
    [[ "$output" =~ /var/log ]]
}

@test "get_virtos_path: cluster paths are defined (sample: CLUSTER_CONF)" {
    run get_virtos_path "CLUSTER_CONF"
    [ "$status" -eq 0 ]
    [[ "$output" =~ /etc/virtos ]]
}

@test "get_virtos_path: storage paths are defined (sample: STORAGE_ISO)" {
    run get_virtos_path "STORAGE_ISO"
    [ "$status" -eq 0 ]
    [[ "$output" =~ /var/lib ]]
}

@test "get_virtos_path: backup paths are defined (sample: BACKUP_ORCHESTRATED)" {
    run get_virtos_path "BACKUP_ORCHESTRATED"
    [ "$status" -eq 0 ]
    [[ "$output" =~ /var/backups ]]
}

@test "get_virtos_path: configuration paths are defined (sample: CONF_ANALYTICS)" {
    run get_virtos_path "CONF_ANALYTICS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ /etc/virtos ]]
}

@test "get_virtos_path: data directory paths are defined (sample: DATA_AI_MODELS)" {
    run get_virtos_path "DATA_AI_MODELS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ /var/lib/virtos ]]
}
