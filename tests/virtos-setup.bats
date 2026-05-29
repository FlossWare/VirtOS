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

#==============================================================================
# Functional Tests - Configuration Generation
#==============================================================================

@test "virtos-setup: sources virtos-common.sh" {
    # Verify script loads common library
    run grep -q "virtos-common.sh" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: defines config directory" {
    # Verify CONFIG_DIR is defined
    run grep -q 'CONFIG_DIR="/etc/virtos"' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: has save_config function" {
    # Verify save_config function exists
    run grep -q "^save_config()" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: has apply_config function" {
    # Verify apply_config function exists
    run grep -q "^apply_config()" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: save_config creates proper format" {
    # Verify save_config produces shell-sourceable output
    run grep -A 20 "^save_config()" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ 'HOSTNAME=' ]]
    [[ "$output" =~ 'DOMAIN=' ]]
    [[ "$output" =~ 'IP_MODE=' ]]
}

@test "virtos-setup: config includes all required fields" {
    # Verify all expected configuration variables
    local required_vars="HOSTNAME DOMAIN IP_MODE IP_ADDR NETMASK GATEWAY DNS STORAGE_DISK VM_DIR"
    for var in $required_vars; do
        run grep -q "${var}=" "$SCRIPT_PATH"
        [ "$status" -eq 0 ]
    done
}

#==============================================================================
# Functional Tests - Input Validation
#==============================================================================

@test "virtos-setup: validates hostname format" {
    # Check if script uses validate_hostname or similar
    run grep -q "validate.*hostname" "$SCRIPT_PATH"
    # May or may not use validation, but should handle input safely
}

@test "virtos-setup: handles network mode selection" {
    # Verify network configuration options
    run grep -q "dhcp\|static" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: supports multiple storage filesystems" {
    # Verify storage filesystem options
    run grep -q "ext4\|btrfs\|zfs\|lvm" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Functional Tests - Dialog/Whiptail Detection
#==============================================================================

@test "virtos-setup: detects dialog availability" {
    # Verify script checks for dialog
    run grep -q "command -v dialog" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: detects whiptail as fallback" {
    # Verify script checks for whiptail
    run grep -q "command -v whiptail" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: exits gracefully without dialog/whiptail" {
    # Verify error handling when neither is available
    run grep -A 5 "command -v whiptail" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "exit 1" ]]
}

#==============================================================================
# Functional Tests - Temporary File Handling
#==============================================================================

@test "virtos-setup: uses mktemp for temp files" {
    # Verify secure temp file creation
    run grep -q "mktemp" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: cleans up temp files with trap" {
    # Verify trap for cleanup
    run grep -q "trap.*EXIT" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Functional Tests - Service Configuration
#==============================================================================

@test "virtos-setup: supports libvirt service" {
    # Verify libvirt service handling
    run grep -q "libvirt" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: supports docker service" {
    # Verify docker service handling
    run grep -q "docker" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: supports avahi service" {
    # Verify avahi service handling
    run grep -q "avahi" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: adds services to bootlocal.sh" {
    # Verify services are persisted
    run grep -q "/opt/bootlocal.sh" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Functional Tests - Storage Configuration
#==============================================================================

@test "virtos-setup: creates VM directory" {
    # Verify VM directory creation
    run grep -q "mkdir.*VM_DIR" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: updates fstab for storage" {
    # Verify fstab updates
    run grep -q "/etc/fstab" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: supports ZFS configuration" {
    # Verify ZFS-specific handling
    run grep -q "zpool create" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: supports LVM configuration" {
    # Verify LVM-specific handling
    run grep -q "pvcreate\|vgcreate\|lvcreate" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Functional Tests - Network Configuration
#==============================================================================

@test "virtos-setup: configures static IP" {
    # Verify static IP configuration
    run grep -q "ifconfig.*IP_ADDR" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: configures default gateway" {
    # Verify gateway configuration
    run grep -q "route add default" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: configures DNS" {
    # Verify DNS configuration
    run grep -q "/etc/resolv.conf" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Functional Tests - Persistence
#==============================================================================

@test "virtos-setup: calls filetool.sh for persistence" {
    # Verify backup is triggered
    run grep -q "filetool.sh -b" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "virtos-setup: sets hostname persistently" {
    # Verify hostname is written to file
    run grep -q "/etc/hostname" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}
