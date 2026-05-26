#!/usr/bin/env bats
# Unit tests for virtos-directory (Directory service integration)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-directory"

setup() {
    # Skip if virtos-directory not available
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-directory script not found"
    fi
}

@test "virtos-directory exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-directory shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-directory --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "virtos-directory --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-directory help shows directory commands" {
    run "$SCRIPT_PATH" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "search" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-directory search requires query" {
    skip "Requires directory service backend"
    run "$SCRIPT_PATH" search
    [ "$status" -ne 0 ]
}

@test "virtos-directory user-info requires username" {
    skip "Requires directory service backend"
    run "$SCRIPT_PATH" user-info
    [ "$status" -ne 0 ]
}

@test "virtos-directory group-list returns successfully" {
    skip "Requires directory service backend"
    run "$SCRIPT_PATH" group-list
    [ "$status" -eq 0 ]
}

@test "virtos-directory sync command exists" {
    skip "Requires directory service backend"
    run "$SCRIPT_PATH" sync
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "virtos-directory configure-ldap command exists" {
    skip "Requires LDAP configuration"
    run "$SCRIPT_PATH" configure-ldap
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "virtos-directory directory service workflow (placeholder)" {
    skip "Requires directory service backend"
    # Full workflow test would:
    # 1. Configure directory service
    # 2. Search for users
    # 3. Retrieve user info
    # 4. List groups
    # 5. Sync with directory
    # 6. Clean up
}
