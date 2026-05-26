#!/usr/bin/env bats
# Unit tests for virtos-cloud-init (Cloud-init integration)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-cloud-init"

setup() {
    # Skip if virtos-cloud-init not available
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-cloud-init script not found"
    fi
}

@test "virtos-cloud-init exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-cloud-init shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-cloud-init --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "virtos-cloud-init --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-cloud-init help shows cloud-init commands" {
    run "$SCRIPT_PATH" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "generate" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-cloud-init generate requires output file" {
    skip "Requires cloud-init configuration"
    run "$SCRIPT_PATH" generate
    [ "$status" -ne 0 ]
}

@test "virtos-cloud-init validate requires config file" {
    skip "Requires cloud-init"
    run "$SCRIPT_PATH" validate
    [ "$status" -ne 0 ]
}

@test "virtos-cloud-init attach requires VM name and ISO" {
    skip "Requires cloud-init and libvirt"
    run "$SCRIPT_PATH" attach
    [ "$status" -ne 0 ]
}

@test "virtos-cloud-init template-list returns successfully" {
    skip "Requires cloud-init templates"
    run "$SCRIPT_PATH" template-list
    [ "$status" -eq 0 ]
}

@test "virtos-cloud-init cloud-init workflow (placeholder)" {
    skip "Requires cloud-init, libvirt, and VM"
    # Full workflow test would:
    # 1. Generate cloud-init config
    # 2. Validate configuration
    # 3. Create cloud-init ISO
    # 4. Attach to VM
    # 5. Boot VM with cloud-init
    # 6. Verify cloud-init applied
    # 7. Clean up
}
