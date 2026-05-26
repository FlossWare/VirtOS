#!/usr/bin/env bats
# BATS tests for virtos-storage

SCRIPT="${BATS_TEST_DIRNAME}/../config/custom-scripts/virtos-storage"

@test "virtos-storage exists and is executable" {
    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "virtos-storage --help shows usage" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" || "$output" =~ "usage:" ]]
}

@test "virtos-storage without arguments shows error or usage" {
    run "$SCRIPT"
    [[ "$output" =~ "Usage:" || "$output" =~ "Error" || "$output" =~ "command" ]]
}

# Tests requiring libvirt
@test "virtos-storage list-pools (requires libvirt)" {
    skip "Requires libvirt"
}

@test "virtos-storage create-pool (requires libvirt)" {
    skip "Requires libvirt"
}
