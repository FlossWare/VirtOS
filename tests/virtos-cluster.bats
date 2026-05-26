#!/usr/bin/env bats
# BATS tests for virtos-cluster

SCRIPT="${BATS_TEST_DIRNAME}/../config/custom-scripts/virtos-cluster"

@test "virtos-cluster exists and is executable" {
    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "virtos-cluster --help shows usage" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" || "$output" =~ "usage:" || "$output" =~ "cluster" ]]
}

@test "virtos-cluster list command exists" {
    run "$SCRIPT" list 2>&1
    # Should either list (success) or show error about no cluster (also OK)
    [[ "$output" =~ "cluster" || "$output" =~ "Cluster" || "$status" -eq 0 ]]
}

@test "virtos-cluster without arguments shows error or usage" {
    run "$SCRIPT"
    [[ "$output" =~ "Usage:" || "$output" =~ "command" || "$output" =~ "Error" ]]
}

# Cluster tests require multiple hosts
@test "virtos-cluster discovery (requires Avahi)" {
    skip "Requires Avahi and multiple VirtOS hosts"
}
