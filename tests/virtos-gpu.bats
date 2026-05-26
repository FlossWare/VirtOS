#!/usr/bin/env bats
# Unit tests for virtos-gpu (GPU passthrough and vGPU)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-gpu"

setup() {
    # Skip if virtos-gpu not available
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-gpu script not found"
    fi

    # Skip if virsh not available
    if ! command -v virsh >/dev/null 2>&1; then
        skip "virsh not installed"
    fi
}

@test "virtos-gpu exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-gpu shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-gpu --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "virtos-gpu --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-gpu help shows GPU commands" {
    run "$SCRIPT_PATH" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "list" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-gpu list returns successfully" {
    skip "Requires GPU hardware and permissions"
    run "$SCRIPT_PATH" list
    [ "$status" -eq 0 ]
}

@test "virtos-gpu attach requires VM name and GPU ID" {
    skip "Requires GPU hardware and libvirt"
    run "$SCRIPT_PATH" attach
    [ "$status" -ne 0 ]
}

@test "virtos-gpu detach requires VM name" {
    skip "Requires GPU hardware and libvirt"
    run "$SCRIPT_PATH" detach
    [ "$status" -ne 0 ]
}

@test "virtos-gpu status returns successfully" {
    skip "Requires GPU hardware"
    run "$SCRIPT_PATH" status
    [ "$status" -eq 0 ]
}

@test "virtos-gpu passthrough workflow (placeholder)" {
    skip "Requires GPU hardware, IOMMU, and permissions"
    # Full workflow test would:
    # 1. List available GPUs
    # 2. Attach GPU to VM
    # 3. Verify GPU attached
    # 4. Start VM
    # 5. Detach GPU
    # 6. Clean up
}
