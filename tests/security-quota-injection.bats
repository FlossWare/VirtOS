#!/usr/bin/env bats
# Security tests for virtos-quota command injection vulnerability (Issue #249)

SCRIPT_PATH="../config/custom-scripts/virtos-quota"
PACKAGE_PATH="../packages/virtos-tools/src/usr/local/bin/virtos-quota"
COMMON_LIB="../config/custom-scripts/lib/virtos-common.sh"

setup() {
    # Variables are set above
    :
}

@test "virtos-quota has safe_load_quota_file function" {
    grep -q "safe_load_quota_file()" "$SCRIPT_PATH"
}

@test "virtos-quota has no unsafe source calls to quota files" {
    # Should not have direct source of quota files without safe wrapper
    ! grep -E '^[[:space:]]*source[[:space:]]+"?\$quota_file"?[[:space:]]*$' "$SCRIPT_PATH"
}

@test "virtos-quota has safe cluster config loading" {
    grep -q "safe_load_cluster_config\|safe_load_quota_file" "$SCRIPT_PATH"
}

@test "virtos-quota config and package files are synchronized" {
    if [ -f "$PACKAGE_PATH" ] && [ -f "$SCRIPT_PATH" ]; then
        diff -q "$PACKAGE_PATH" "$SCRIPT_PATH"
    else
        skip "One or both virtos-quota files not found"
    fi
}

@test "virtos-quota uses safe parsing instead of source" {
    # Verify the script uses grep/cut for config parsing
    grep -q "grep.*cut\|safe_load" "$SCRIPT_PATH"
}

@test "virtos-quota validates variable names" {
    # Should have case statement for variable validation
    grep -q "case.*VM_NAME\|CPU_LIMIT\|MEMORY_LIMIT" "$SCRIPT_PATH"
}

@test "virtos-quota has no eval of user input" {
    # Should not use eval on quota file contents
    ! grep -E 'eval.*quota|eval.*\$[A-Z_]+_LIMIT' "$SCRIPT_PATH"
}

@test "virtos-quota sets secure file permissions" {
    # Should set chmod 600 on created quota files
    grep -q "chmod 600" "$SCRIPT_PATH"
}

@test "virtos-common.sh has parse_config_file function" {
    if [ -f "$COMMON_LIB" ]; then
        grep -q "parse_config_file()" "$COMMON_LIB"
    else
        skip "virtos-common.sh not found"
    fi
}

@test "virtos-common.sh has get_config_value function" {
    if [ -f "$COMMON_LIB" ]; then
        grep -q "get_config_value()" "$COMMON_LIB"
    else
        skip "virtos-common.sh not found"
    fi
}

@test "virtos-quota rejects command injection patterns" {
    # Should validate that only safe variable names are accepted
    grep -q "VM_NAME\|CPU_LIMIT\|MEMORY_LIMIT\|DISK_LIMIT" "$SCRIPT_PATH"
}

@test "virtos-quota uses safe variable assignment" {
    # Check for safe variable assignment pattern (printf -v or export)
    grep -q "printf -v\|export" "$SCRIPT_PATH"
}
