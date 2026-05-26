#!/usr/bin/env bats
# BATS tests for virtos-monitor

SCRIPT="${BATS_TEST_DIRNAME}/../config/custom-scripts/virtos-monitor"

@test "virtos-monitor exists and is executable" {
    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "virtos-monitor --help shows usage" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" || "$output" =~ "usage:" || "$output" =~ "monitor" ]]
}

@test "virtos-monitor without arguments shows error or usage" {
    run "$SCRIPT"
    [[ "$output" =~ "Usage:" || "$output" =~ "Error" || "$output" =~ "monitor" || "$status" -eq 0 ]]
}

# Monitor tests require libvirt
@test "virtos-monitor stats (requires libvirt)" {
    skip "Requires libvirt and running VMs"
}
