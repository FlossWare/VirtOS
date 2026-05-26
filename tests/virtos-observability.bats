#!/usr/bin/env bats
# Unit tests for virtos-observability (Monitoring, logging, and tracing)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-observability"

setup() {
    # Skip if virtos-observability not available
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-observability script not found"
    fi
}

@test "virtos-observability exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-observability shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-observability --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "virtos-observability --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-observability help shows observability commands" {
    run "$SCRIPT_PATH" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "logs" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-observability logs requires target" {
    skip "Requires logging infrastructure"
    run "$SCRIPT_PATH" logs
    [ "$status" -ne 0 ]
}

@test "virtos-observability metrics returns successfully" {
    skip "Requires metrics collection"
    run "$SCRIPT_PATH" metrics
    [ "$status" -eq 0 ]
}

@test "virtos-observability trace requires trace ID" {
    skip "Requires tracing infrastructure"
    run "$SCRIPT_PATH" trace
    [ "$status" -ne 0 ]
}

@test "virtos-observability alerts returns successfully" {
    skip "Requires alerting system"
    run "$SCRIPT_PATH" alerts
    [ "$status" -eq 0 ]
}

@test "virtos-observability dashboard command exists" {
    skip "Requires dashboard infrastructure"
    run "$SCRIPT_PATH" dashboard
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "virtos-observability observability workflow (placeholder)" {
    skip "Requires full observability stack and VMs"
    # Full workflow test would:
    # 1. Enable observability for VMs
    # 2. Collect logs and metrics
    # 3. Generate traces
    # 4. View dashboard
    # 5. Set up alerts
    # 6. Clean up
}
