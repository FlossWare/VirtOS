#!/usr/bin/env bats
# Unit tests for virtos-setup (Setup wizard)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-setup"

setup() {
    # Skip if virtos-setup not available
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-setup script not found"
    fi

    # Skip if dialog/whiptail not available
    if ! command -v dialog >/dev/null 2>&1 && ! command -v whiptail >/dev/null 2>&1; then
        skip "dialog or whiptail not installed"
    fi
}

@test "virtos-setup exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-setup --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Setup" ]]
}

@test "virtos-setup --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-setup version command works" {
    run "$SCRIPT_PATH" version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-setup requires dialog or whiptail" {
    skip "Requires dialog/whiptail check in script"
    # Script should fail gracefully if neither is available
    run "$SCRIPT_PATH"
    if [ "$status" -ne 0 ]; then
        [[ "$output" =~ "dialog" ]] || [[ "$output" =~ "whiptail" ]]
    fi
}

@test "virtos-setup creates config directory" {
    skip "Requires permissions to create /etc/virtos"
    # Would test that /etc/virtos is created
}

@test "virtos-setup interactive wizard (placeholder)" {
    skip "Requires interactive TUI and permissions"
    # Full workflow test would:
    # 1. Launch setup wizard non-interactively
    # 2. Configure hostname, network, storage
    # 3. Verify config file created
    # 4. Verify settings applied
    # 5. Clean up
}

@test "virtos-setup network configuration (placeholder)" {
    skip "Requires permissions and network configuration"
    # Full workflow test would:
    # 1. Configure static IP
    # 2. Configure DNS
    # 3. Verify network settings
    # 4. Restore original settings
}

@test "virtos-setup storage configuration (placeholder)" {
    skip "Requires disk access and permissions"
    # Full workflow test would:
    # 1. Configure storage pool
    # 2. Set VM directory
    # 3. Verify storage configured
    # 4. Clean up
}

@test "virtos-setup service configuration (placeholder)" {
    skip "Requires systemd and permissions"
    # Full workflow test would:
    # 1. Enable/disable services
    # 2. Verify service state
    # 3. Restore original state
}
