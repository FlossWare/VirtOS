#!/usr/bin/env bats
# BATS tests for virtos-backup

SCRIPT="${BATS_TEST_DIRNAME}/../config/custom-scripts/virtos-backup"

@test "virtos-backup exists and is executable" {
    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "virtos-backup --help shows usage" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" || "$output" =~ "usage:" || "$output" =~ "backup" ]]
}

@test "virtos-backup without arguments shows error or usage" {
    run "$SCRIPT"
    [[ "$output" =~ "Usage:" || "$output" =~ "Error" || "$output" =~ "command" || "$status" -ne 0 ]]
}

# Backup tests require libvirt
@test "virtos-backup create (requires libvirt)" {
    skip "Requires libvirt and test VM"
}

@test "virtos-backup restore (requires libvirt)" {
    skip "Requires libvirt and backup file"
}
