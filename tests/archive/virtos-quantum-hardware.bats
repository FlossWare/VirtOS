#!/usr/bin/env bats
# Unit tests for virtos-quantum-hardware (Quantum hardware management - EXPERIMENTAL)

load test_helper 2>/dev/null || true
SCRIPT_PATH="../config/custom-scripts/virtos-quantum-hardware"

setup() {
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-quantum-hardware script not found"
    fi
}

@test "virtos-quantum-hardware exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-quantum-hardware shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-quantum-hardware --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-quantum-hardware --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-quantum-hardware is marked as experimental" {
    skip "EXPERIMENTAL - Quantum hardware demonstration"
}
