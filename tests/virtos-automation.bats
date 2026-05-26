#!/usr/bin/env bats
# Unit tests for virtos-automation (Workflow automation)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-automation"

setup() {
    # Skip if virtos-automation not available
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-automation script not found"
    fi
}

@test "virtos-automation exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-automation shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-automation --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "virtos-automation --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-automation help shows automation commands" {
    run "$SCRIPT_PATH" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "create" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-automation list returns successfully" {
    skip "Requires automation configuration"
    run "$SCRIPT_PATH" list
    [ "$status" -eq 0 ]
}

@test "virtos-automation create requires workflow name" {
    skip "Requires automation configuration"
    run "$SCRIPT_PATH" create
    [ "$status" -ne 0 ]
}

@test "virtos-automation execute requires workflow name" {
    skip "Requires automation configuration and workflow"
    run "$SCRIPT_PATH" execute
    [ "$status" -ne 0 ]
}

@test "virtos-automation delete requires workflow name" {
    skip "Requires automation configuration"
    run "$SCRIPT_PATH" delete
    [ "$status" -ne 0 ]
}

@test "virtos-automation status returns successfully" {
    skip "Requires automation configuration"
    run "$SCRIPT_PATH" status
    [ "$status" -eq 0 ]
}

@test "virtos-automation schedule requires workflow and cron expression" {
    skip "Requires automation configuration and cron"
    run "$SCRIPT_PATH" schedule
    [ "$status" -ne 0 ]
}

@test "virtos-automation workflow creation (placeholder)" {
    skip "Requires automation engine and permissions"
    # Full workflow test would:
    # 1. Create a workflow
    # 2. Verify workflow file created
    # 3. Execute workflow
    # 4. Verify workflow ran successfully
    # 5. Delete workflow
    # 6. Clean up
}

@test "virtos-automation scheduled workflow (placeholder)" {
    skip "Requires automation engine, cron, and permissions"
    # Full workflow test would:
    # 1. Create a workflow
    # 2. Schedule it with cron
    # 3. Verify cron entry created
    # 4. Unschedule workflow
    # 5. Verify cron entry removed
    # 6. Clean up
}
