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
