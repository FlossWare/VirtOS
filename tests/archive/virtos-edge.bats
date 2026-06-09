#!/usr/bin/env bats
# Unit tests for virtos-edge (EXPERIMENTAL)

load test_helper 2>/dev/null || true
SCRIPT_PATH="../config/custom-scripts/virtos-edge"

setup() {
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-edge script not found"
    fi
}

@test "virtos-edge exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-edge shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-edge --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-edge --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-edge is marked as experimental" {
    skip "EXPERIMENTAL - Demonstration/future feature"
}
