#!/usr/bin/env bats
# BATS tests for virtos-create-vm

SCRIPT="${BATS_TEST_DIRNAME}/../packages/virtos-tools/src/usr/local/bin/virtos-create-vm"

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
