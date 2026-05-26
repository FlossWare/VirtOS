#!/usr/bin/env bats
# Unit tests for virtos-federation-extended (EXPERIMENTAL)

load test_helper 2>/dev/null || true
SCRIPT_PATH="../config/custom-scripts/virtos-federation-extended"

setup() {
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-federation-extended script not found"
    fi
}

@test "virtos-federation-extended exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-federation-extended shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-federation-extended --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-federation-extended --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-federation-extended is marked as experimental" {
    skip "EXPERIMENTAL - Demonstration/future feature"
}
