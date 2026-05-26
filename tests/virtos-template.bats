#!/usr/bin/env bats
# Unit tests for virtos-template

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-template"

setup() {
    # Skip if virtos-template not available
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-template script not found"
    fi

    # Skip if virsh not available
    if ! command -v virsh >/dev/null 2>&1; then
        skip "virsh not installed"
    fi

    # Skip if qemu-img not available
    if ! command -v qemu-img >/dev/null 2>&1; then
        skip "qemu-img not installed"
    fi
}

@test "virtos-template exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-template shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-template --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "virtos-template --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-template -v shows version" {
    run "$SCRIPT_PATH" -v
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-template has version command" {
    run "$SCRIPT_PATH" version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-template help shows commands" {
    run "$SCRIPT_PATH" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "create" ]]
    [[ "$output" =~ "clone" ]]
    [[ "$output" =~ "list" ]]
    [[ "$output" =~ "delete" ]]
}

@test "virtos-template list returns successfully" {
    skip "Requires functional libvirt and template directory"
    run "$SCRIPT_PATH" list
    [ "$status" -eq 0 ]
}

@test "virtos-template create requires VM name" {
    skip "Requires functional libvirt"
    run "$SCRIPT_PATH" create
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Error" ]] || [[ "$output" =~ "Usage" ]]
}

@test "virtos-template create requires template name" {
    skip "Requires functional libvirt and existing VM"
    run "$SCRIPT_PATH" create test-vm
    [ "$status" -ne 0 ]
}

@test "virtos-template create checks VM exists" {
    skip "Requires functional libvirt"
    run "$SCRIPT_PATH" create nonexistent-vm template-name
    [ "$status" -ne 0 ]
    [[ "$output" =~ "not found" ]] || [[ "$output" =~ "Error" ]]
}

@test "virtos-template clone requires template name" {
    skip "Requires functional libvirt"
    run "$SCRIPT_PATH" clone
    [ "$status" -ne 0 ]
}

@test "virtos-template clone requires new VM name" {
    skip "Requires functional libvirt and existing template"
    run "$SCRIPT_PATH" clone test-template
    [ "$status" -ne 0 ]
}

@test "virtos-template clone checks template exists" {
    skip "Requires functional libvirt"
    run "$SCRIPT_PATH" clone nonexistent-template new-vm
    [ "$status" -ne 0 ]
    [[ "$output" =~ "not found" ]] || [[ "$output" =~ "Error" ]]
}

@test "virtos-template delete requires template name" {
    skip "Requires functional libvirt"
    run "$SCRIPT_PATH" delete
    [ "$status" -ne 0 ]
}

@test "virtos-template import requires image URL" {
    skip "Requires functional libvirt and network access"
    run "$SCRIPT_PATH" import
    [ "$status" -ne 0 ]
}

@test "virtos-template import requires template name" {
    skip "Requires functional libvirt and network access"
    run "$SCRIPT_PATH" import https://example.com/image.img
    [ "$status" -ne 0 ]
}

@test "virtos-template create template workflow (placeholder)" {
    skip "Requires functional libvirt, test VM, and permissions"
    # Full workflow test would:
    # 1. Create a test VM
    # 2. Shut it down
    # 3. Create template from it
    # 4. Verify template directory created
    # 5. Verify manifest file exists
    # 6. Clean up
}

@test "virtos-template clone workflow (placeholder)" {
    skip "Requires functional libvirt, existing template, and permissions"
    # Full workflow test would:
    # 1. Clone VM from template
    # 2. Verify VM created
    # 3. Verify disks created
    # 4. Verify VM can start
    # 5. Clean up
}
