#!/usr/bin/env bats
# Unit tests for virtos-multicloud (EXPERIMENTAL)

load test_helper 2>/dev/null || true
SCRIPT_PATH="../config/custom-scripts/virtos-multicloud"

setup() {
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-multicloud script not found"
    fi
}

@test "virtos-multicloud exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-multicloud shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-multicloud --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-multicloud --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-multicloud is marked as experimental" {
    skip "EXPERIMENTAL - Demonstration/future feature"
}
