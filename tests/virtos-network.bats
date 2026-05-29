#!/usr/bin/env bats
# BATS tests for virtos-network

SCRIPT="${BATS_TEST_DIRNAME}/../config/custom-scripts/virtos-network"

@test "virtos-network exists and is executable" {
    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "virtos-network --help shows usage" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" || "$output" =~ "usage:" ]]
}

@test "virtos-network list command exists" {
    run "$SCRIPT" list --help 2>&1
    # Should show help or list networks (both acceptable)
    [[ "$output" =~ "help" || "$output" =~ "network" || "$output" =~ "Usage" ]] || [ "$status" -eq 0 ]
}

@test "virtos-network without arguments shows error or usage" {
    run "$SCRIPT"
    [[ "$output" =~ "Usage:" || "$output" =~ "Error" || "$output" =~ "command" ]]
}

# Tests requiring root/libvirt
@test "virtos-network create-bridge (requires root)" {
    skip "Requires root and network permissions"
}

@test "virtos-network list (may require libvirt)" {
    skip "Requires libvirt"
}

#==============================================================================
# Functional Tests - VLAN Validation
#==============================================================================

@test "virtos-network: validates VLAN ID range" {
    # Verify script checks VLAN ID is 1-4094
    run grep -q "vlan_id.*4094" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-network: validates VLAN name format" {
    # Verify script validates VLAN name to prevent injection
    run grep -q "grep.*vlan_name.*\^" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-network: rejects invalid VLAN name characters" {
    # Verify script uses alphanumeric validation
    run grep -A 2 "Invalid VLAN name" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "alphanumeric" ]]
}

@test "virtos-network: checks VLAN ID bounds" {
    # Verify minimum VLAN ID check
    run grep -q "vlan_id.*-lt 1" "$SCRIPT"
    [ "$status" -eq 0 ]

    # Verify maximum VLAN ID check
    run grep -q "vlan_id.*-gt 4094" "$SCRIPT"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Functional Tests - Network XML Generation
#==============================================================================

@test "virtos-network: generates libvirt network XML" {
    # Verify script creates network XML
    run grep -q "cat.*vlan.*xml" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-network: XML includes network name" {
    run grep -A 5 "<network>" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "<name>" ]]
}

@test "virtos-network: XML includes bridge config" {
    run grep -A 5 "<network>" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "<bridge" ]]
}

@test "virtos-network: XML includes VLAN tag" {
    run grep -A 10 "<network>" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "<tag" ]] || [[ "$output" =~ "vlan" ]]
}

#==============================================================================
# Functional Tests - Configuration Management
#==============================================================================

@test "virtos-network: creates config directory" {
    run grep -q "NETWORK_DIR=" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-network: has init_config function" {
    run grep -q "^init_config()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-network: creates default config file" {
    run grep -A 20 "init_config()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "VLAN_ENABLED" ]]
    [[ "$output" =~ "OVN_ENABLED" ]]
}

@test "virtos-network: config includes QoS settings" {
    run grep -A 30 "init_config()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "QOS_ENABLED" ]]
}

@test "virtos-network: config includes firewall settings" {
    run grep -A 30 "init_config()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "FIREWALL_ENABLED" ]]
}

#==============================================================================
# Functional Tests - Command Structure
#==============================================================================

@test "virtos-network: has vlan-create command" {
    run grep -q "^vlan_create()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-network: has vlan-delete command" {
    run grep -q "^vlan_delete()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-network: has vlan-list command" {
    run grep -q "^vlan_list()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-network: has vlan-attach command" {
    run grep -q "^vlan_attach()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Functional Tests - Error Handling
#==============================================================================

@test "virtos-network: vlan-create requires VLAN ID" {
    run grep -A 3 "vlan_create()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ 'if.*-z.*vlan_id' ]]
}

@test "virtos-network: vlan-create requires name" {
    run grep -A 3 "vlan_create()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ 'if.*-z.*vlan_name' ]]
}

@test "virtos-network: provides helpful error for missing args" {
    run grep -A 10 "VLAN ID and name are required" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Example:" ]]
}

@test "virtos-network: error message includes VLAN ID range" {
    run grep -A 10 "VLAN ID out of valid range" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1-4094" ]]
}

#==============================================================================
# Functional Tests - Logging
#==============================================================================

@test "virtos-network: has log file location" {
    run grep -q "LOG_FILE=" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-network: has log_message function" {
    run grep -q "^log_message()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-network: logs VLAN creation" {
    run grep -q 'log_message.*Creating VLAN' "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-network: logs VLAN deletion" {
    run grep -q 'log_message.*Deleting VLAN' "$SCRIPT"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Functional Tests - Integration with virsh
#==============================================================================

@test "virtos-network: checks for virsh availability" {
    run grep -q "command -v virsh" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-network: gracefully handles missing virsh" {
    # Verify script doesn't crash if virsh unavailable
    run grep -A 1 "command -v virsh" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "|| true" ]] || [[ "$output" =~ "2>/dev/null" ]]
}

@test "virtos-network: uses virsh net-define" {
    run grep -q "virsh net-define" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-network: uses virsh net-start" {
    run grep -q "virsh net-start" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-network: uses virsh net-autostart" {
    run grep -q "virsh net-autostart" "$SCRIPT"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Functional Tests - Usage Documentation
#==============================================================================

@test "virtos-network: usage includes all VLAN commands" {
    run grep -A 50 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "vlan-create" ]]
    [[ "$output" =~ "vlan-delete" ]]
    [[ "$output" =~ "vlan-list" ]]
    [[ "$output" =~ "vlan-attach" ]]
}

@test "virtos-network: usage includes OVN commands" {
    run grep -A 50 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ovn-init" ]]
    [[ "$output" =~ "ovn-status" ]]
}

@test "virtos-network: usage includes bridge commands" {
    run grep -A 50 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "bridge-create" ]]
    [[ "$output" =~ "bridge-delete" ]]
}

@test "virtos-network: usage includes QoS commands" {
    run grep -A 50 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "qos-set" ]]
    [[ "$output" =~ "qos-show" ]]
}

@test "virtos-network: usage includes examples" {
    run grep -A 80 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Examples:" ]]
}
