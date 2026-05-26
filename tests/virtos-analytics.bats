#!/usr/bin/env bats
# Unit tests for virtos-analytics (Performance analytics and insights)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-analytics"

setup() {
    # Skip if virtos-analytics not available
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-analytics script not found"
    fi
}

@test "virtos-analytics exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-analytics shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-analytics --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "virtos-analytics --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-analytics help shows analytics commands" {
    run "$SCRIPT_PATH" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "report" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-analytics report returns successfully" {
    skip "Requires analytics data and permissions"
    run "$SCRIPT_PATH" report
    [ "$status" -eq 0 ]
}

@test "virtos-analytics analyze requires VM name" {
    skip "Requires analytics tools and VMs"
    run "$SCRIPT_PATH" analyze
    [ "$status" -ne 0 ]
}

@test "virtos-analytics trend requires metric name" {
    skip "Requires analytics data"
    run "$SCRIPT_PATH" trend
    [ "$status" -ne 0 ]
}

@test "virtos-analytics dashboard command exists" {
    skip "Requires analytics tools and web server"
    run "$SCRIPT_PATH" dashboard
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "virtos-analytics export returns successfully" {
    skip "Requires analytics data"
    run "$SCRIPT_PATH" export
    [ "$status" -eq 0 ]
}

@test "virtos-analytics analytics workflow (placeholder)" {
    skip "Requires analytics tools, VMs with metrics, and permissions"
    # Full workflow test would:
    # 1. Collect VM metrics
    # 2. Analyze performance data
    # 3. Generate trend report
    # 4. Export analytics data
    # 5. Verify report accuracy
    # 6. Clean up
}
