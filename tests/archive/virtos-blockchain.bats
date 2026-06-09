#!/usr/bin/env bats
# Unit tests for virtos-blockchain (EXPERIMENTAL)

load test_helper 2>/dev/null || true
SCRIPT_PATH="../config/custom-scripts/virtos-blockchain"

setup() {
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-blockchain script not found"
    fi
}

@test "virtos-blockchain exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-blockchain shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-blockchain --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-blockchain --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-blockchain is marked as experimental" {
    skip "EXPERIMENTAL - Demonstration/future feature"
}
