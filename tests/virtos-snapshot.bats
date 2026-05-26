#!/usr/bin/env bats
# BATS tests for virtos-snapshot

SCRIPT="${BATS_TEST_DIRNAME}/../config/custom-scripts/virtos-snapshot"

@test "virtos-snapshot exists and is executable" {
    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "virtos-snapshot --help shows usage" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" || "$output" =~ "usage:" ]]
}

@test "virtos-snapshot --version shows version" {
    skip "virtos-snapshot doesn't implement --version yet"
}

@test "virtos-snapshot without arguments shows error or usage" {
    run "$SCRIPT"
    # Should either show usage (exit 0) or error (exit non-zero)
    [[ "$output" =~ "Usage:" || "$output" =~ "Error" || "$output" =~ "requires" ]]
}

# The following tests require libvirt to be available
@test "virtos-snapshot create (requires libvirt)" {
    skip "Requires libvirt and test VM"
    # This would test: virtos-snapshot create test-vm
}

@test "virtos-snapshot list (requires libvirt)" {
    skip "Requires libvirt and test VM"
    # This would test: virtos-snapshot list test-vm
}

@test "virtos-snapshot restore (requires libvirt)" {
    skip "Requires libvirt and test VM with snapshot"
    # This would test: virtos-snapshot restore test-vm snapshot-name
}

@test "virtos-snapshot delete (requires libvirt)" {
    skip "Requires libvirt and test VM with snapshot"
    # This would test: virtos-snapshot delete test-vm snapshot-name
}
