#!/usr/bin/env bats
# Unit tests for virtos-usb (USB device passthrough)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-usb"

setup() {
    # Skip if virtos-usb not available
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-usb script not found"
    fi

    # Skip if virsh not available
    if ! command -v virsh >/dev/null 2>&1; then
        skip "virsh not installed"
    fi
}

@test "virtos-usb exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-usb shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-usb --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "virtos-usb --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-usb help shows USB commands" {
    run "$SCRIPT_PATH" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "list" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-usb list returns successfully" {
    skip "Requires USB hardware and permissions"
    run "$SCRIPT_PATH" list
    [ "$status" -eq 0 ]
}

@test "virtos-usb attach requires VM name and device ID" {
    skip "Requires USB hardware and libvirt"
    run "$SCRIPT_PATH" attach
    [ "$status" -ne 0 ]
}

@test "virtos-usb detach requires VM name and device ID" {
    skip "Requires USB hardware and libvirt"
    run "$SCRIPT_PATH" detach
    [ "$status" -ne 0 ]
}

@test "virtos-usb status requires VM name" {
    skip "Requires libvirt"
    run "$SCRIPT_PATH" status
    [ "$status" -ne 0 ]
}

@test "virtos-usb passthrough workflow (placeholder)" {
    skip "Requires USB hardware, libvirt, and permissions"
    # Full workflow test would:
    # 1. List available USB devices
    # 2. Attach USB device to VM
    # 3. Verify device attached
    # 4. Start VM
    # 5. Detach device
    # 6. Clean up
}
