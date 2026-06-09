#!/usr/bin/env bats
# Unit tests for virtos-ai-advanced (Advanced AI/ML features - EXPERIMENTAL)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-ai-advanced"

setup() {
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-ai-advanced script not found"
    fi
}

@test "virtos-ai-advanced exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-ai-advanced shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-ai-advanced --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-ai-advanced --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-ai-advanced is marked as experimental" {
    skip "EXPERIMENTAL - Advanced AI/ML demonstration"
}
