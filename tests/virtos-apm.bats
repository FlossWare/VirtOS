#!/usr/bin/env bats
# Unit tests for virtos-apm (Application Performance Monitoring)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-apm"

setup() {
    # Skip if virtos-apm not available
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-apm script not found"
    fi
}

@test "virtos-apm exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-apm shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-apm --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-apm --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-apm help shows APM commands" {
    run "$SCRIPT_PATH" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "monitor" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-apm is marked as experimental/demonstration" {
    skip "Experimental feature - requires APM backend implementation"
    # This is an experimental/demonstration script
    # Full implementation would require APM tools (Prometheus, Grafana, etc.)
}
