#!/usr/bin/env bats
# Unit tests for virtos-api (REST API server)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-api"

setup() {
    # Skip if virtos-api not available
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-api script not found"
    fi
}

@test "virtos-api exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-api shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-api --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "virtos-api --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-api help shows API commands" {
    run "$SCRIPT_PATH" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "start" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-api start command exists" {
    skip "Requires API server configuration and permissions"
    run "$SCRIPT_PATH" start
    # May succeed or fail depending on server state
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "virtos-api stop command exists" {
    skip "Requires API server configuration and permissions"
    run "$SCRIPT_PATH" stop
    # May succeed or fail depending on server state
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "virtos-api status returns successfully" {
    skip "Requires API server configuration"
    run "$SCRIPT_PATH" status
    [ "$status" -eq 0 ]
}

@test "virtos-api config command exists" {
    skip "Requires API configuration file"
    run "$SCRIPT_PATH" config
    [ "$status" -eq 0 ]
}

@test "virtos-api test command exists" {
    skip "Requires running API server"
    run "$SCRIPT_PATH" test
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "virtos-api generates config file (placeholder)" {
    skip "Requires API server and configuration setup"
    # Full workflow test would:
    # 1. Initialize API configuration
    # 2. Verify config file created
    # 3. Verify default settings
    # 4. Clean up
}

@test "virtos-api server lifecycle (placeholder)" {
    skip "Requires API server, netcat, and permissions"
    # Full workflow test would:
    # 1. Start API server
    # 2. Verify server listening on port
    # 3. Make test HTTP request
    # 4. Stop server
    # 5. Verify server stopped
    # 6. Clean up
}
