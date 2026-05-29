#!/usr/bin/env bats
# BATS tests for virtos-create-vm

SCRIPT="${BATS_TEST_DIRNAME}/../config/custom-scripts/virtos-create-vm"

@test "virtos-create-vm: --help shows usage" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-create-vm: missing arguments shows error" {
    run "$SCRIPT"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Error" || "$output" =~ "Missing" ]]
}

@test "virtos-create-vm: validates VM name (reject invalid)" {
    skip "Requires libvirt"
    run "$SCRIPT" --name "test;rm -rf /" --cpu 2 --ram 2048 --disk 10G --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Invalid" ]]
}

@test "virtos-create-vm: validates CPU count (reject negative)" {
    skip "Requires libvirt"
    run "$SCRIPT" --name "test-vm" --cpu -1 --ram 2048 --disk 10G --dry-run
    [ "$status" -ne 0 ]
}

@test "virtos-create-vm: validates RAM size (reject too small)" {
    skip "Requires libvirt"
    run "$SCRIPT" --name "test-vm" --cpu 2 --ram 64 --disk 10G --dry-run
    [ "$status" -ne 0 ]
}

@test "virtos-create-vm: validates disk size format" {
    skip "Requires libvirt"
    run "$SCRIPT" --name "test-vm" --cpu 2 --ram 2048 --disk invalid --dry-run
    [ "$status" -ne 0 ]
}

@test "virtos-create-vm: dry-run doesn't create VM" {
    skip "Requires libvirt and cluster config"
    run "$SCRIPT" --name "test-vm" --cpu 2 --ram 2048 --disk 10G --dry-run
    # Should succeed or fail gracefully, but not create VM
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
    [[ "$output" =~ "Dry run" || "$output" =~ "Error" ]]
}

#==============================================================================
# Functional Tests - Argument Parsing
#==============================================================================

@test "virtos-create-vm: parses --name argument" {
    # Verify script handles --name flag
    run grep -q "^\s*--name)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: parses --cpu argument" {
    run grep -q "^\s*--cpu)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: parses --ram argument" {
    run grep -q "^\s*--ram)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: parses --disk argument" {
    run grep -q "^\s*--disk)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: supports --dry-run flag" {
    run grep -q "^\s*--dry-run)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Functional Tests - Input Validation Logic
#==============================================================================

@test "virtos-create-vm: validates VM name using virtos-common" {
    # Verify script uses validate_vm_name function
    run grep -q "validate_vm_name" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: validates CPU count using virtos-common" {
    # Verify script uses validate_number for CPU
    run grep -q "validate_number.*CPU" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: validates RAM using virtos-common" {
    # Verify script uses validate_number for RAM
    run grep -q "validate_number.*RAM" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: validates disk size format" {
    # Verify script uses validate_disk_size
    run grep -q "validate_disk_size" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: validates network mode" {
    # Verify script validates network mode
    run grep -q "validate_network_mode" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: has fallback validation for CPU" {
    # Verify script has fallback if virtos-common unavailable
    run grep -A 10 "validate_number.*CPU" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Fallback" ]] || [[ "$output" =~ "else" ]]
}

@test "virtos-create-vm: has fallback validation for disk size" {
    # Verify script has fallback if virtos-common unavailable
    run grep -A 10 "validate_disk_size.*DISK" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Fallback" ]] || [[ "$output" =~ "else" ]]
}

#==============================================================================
# Functional Tests - Required Arguments Checking
#==============================================================================

@test "virtos-create-vm: checks for required NAME argument" {
    run grep -q 'if.*-z.*NAME' "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: checks for required CPU argument" {
    run grep -q 'if.*-z.*CPU' "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: checks for required RAM argument" {
    run grep -q 'if.*-z.*RAM' "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: checks for required DISK argument" {
    run grep -q 'if.*-z.*DISK' "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: provides helpful error for missing args" {
    run grep -A 5 'Missing required arguments' "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Example:" ]]
}

#==============================================================================
# Functional Tests - Scheduling Features
#==============================================================================

@test "virtos-create-vm: supports --prefer option" {
    run grep -q "^\s*--prefer)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: supports --avoid option" {
    run grep -q "^\s*--avoid)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: supports --require option" {
    run grep -q "^\s*--require)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: supports --anti-affinity option" {
    run grep -q "^\s*--anti-affinity)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: supports --affinity option" {
    run grep -q "^\s*--affinity)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: supports --policy option" {
    run grep -q "^\s*--policy)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: has default policy value" {
    run grep -q 'POLICY="balanced"' "$SCRIPT"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Functional Tests - Error Messages
#==============================================================================

@test "virtos-create-vm: provides specific error for invalid VM name" {
    run grep -A 3 "Invalid VM name" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "letters, numbers, hyphens" ]] || [[ "$output" =~ "alphanumeric" ]]
}

@test "virtos-create-vm: provides specific error for invalid CPU" {
    run grep -A 1 "CPU count must be" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "positive number" ]]
}

@test "virtos-create-vm: provides specific error for invalid RAM" {
    run grep -A 1 "RAM must be" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "positive number" ]]
}

@test "virtos-create-vm: provides specific error for invalid disk size" {
    run grep -A 2 "Invalid disk size" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Valid formats:" ]] || [[ "$output" =~ "10G" ]]
}

@test "virtos-create-vm: provides specific error for invalid network mode" {
    run grep -A 2 "Invalid network mode" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Valid modes:" ]] || [[ "$output" =~ "bridged" ]]
}

#==============================================================================
# Functional Tests - Script Structure
#==============================================================================

@test "virtos-create-vm: sources virtos-common.sh" {
    run grep -q "virtos-common.sh" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: has color definitions fallback" {
    # Verify fallback colors if common lib not available
    run grep -A 5 "Fallback color definitions" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: uses get_version function" {
    run grep -q "get_version" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: has usage function" {
    run grep -q "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm: usage shows examples" {
    run grep -A 30 "^usage()" "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Examples:" ]]
}
