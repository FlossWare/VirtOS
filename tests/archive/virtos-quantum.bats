#!/usr/bin/env bats
# Unit tests for virtos-quantum (Quantum computing integration - EXPERIMENTAL)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-quantum"

setup() {
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-quantum script not found"
    fi
}

@test "virtos-quantum exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-quantum shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-quantum --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-quantum --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-quantum is marked as experimental" {
    skip "EXPERIMENTAL - Quantum computing demonstration"
}
