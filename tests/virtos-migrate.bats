#!/usr/bin/env bats
# BATS tests for virtos-migrate

SCRIPT="${BATS_TEST_DIRNAME}/../config/custom-scripts/virtos-migrate"

@test "virtos-migrate exists and is executable" {
    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "virtos-migrate --help shows usage" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" || "$output" =~ "usage:" || "$output" =~ "migrate" ]]
}

@test "virtos-migrate without arguments shows error or usage" {
    run "$SCRIPT"
    # Should show usage or error about missing arguments
    [[ "$output" =~ "Usage:" || "$output" =~ "Error" || "$output" =~ "required" || "$status" -ne 0 ]]
}

# Migration tests require complex setup
@test "virtos-migrate live migration (requires 2 hosts)" {
    skip "Requires 2 libvirt hosts with shared storage"
}
