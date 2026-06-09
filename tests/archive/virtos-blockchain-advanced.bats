#!/usr/bin/env bats
# Unit tests for virtos-blockchain-advanced (EXPERIMENTAL)

load test_helper 2>/dev/null || true
SCRIPT_PATH="../config/custom-scripts/virtos-blockchain-advanced"

setup() {
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-blockchain-advanced script not found"
    fi
}

@test "virtos-blockchain-advanced exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-blockchain-advanced shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-blockchain-advanced --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-blockchain-advanced --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-blockchain-advanced is marked as experimental" {
    skip "EXPERIMENTAL - Demonstration/future feature"
}
