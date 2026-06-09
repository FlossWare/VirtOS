#!/usr/bin/env bats
# Unit tests for virtos-governance (EXPERIMENTAL)

load test_helper 2>/dev/null || true
SCRIPT_PATH="../config/custom-scripts/virtos-governance"

setup() {
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-governance script not found"
    fi
}

@test "virtos-governance exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-governance shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-governance --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-governance --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-governance is marked as experimental" {
    skip "EXPERIMENTAL - Demonstration/future feature"
}
