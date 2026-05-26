#!/usr/bin/env bats
# BATS tests for virtos-version

SCRIPT="${BATS_TEST_DIRNAME}/../config/custom-scripts/virtos-version"

@test "virtos-version exists and is executable" {
    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "virtos-version --help shows usage" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" || "$output" =~ "usage:" ]]
}

@test "virtos-version --short shows version number" {
    run "$SCRIPT" --short
    [ "$status" -eq 0 ]
    # Should output a version number or "unknown"
    [[ "$output" =~ ^[0-9]+\.[0-9]+ ]] || [[ "$output" =~ "unknown" ]]
}

@test "virtos-version shows VirtOS Release" {
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "VirtOS Release:" ]]
}

@test "virtos-version shows System section" {
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "System:" ]]
    [[ "$output" =~ "Architecture:" ]]
    [[ "$output" =~ "Hostname:" ]]
}

@test "virtos-version shows Components section" {
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Components:" ]]
    [[ "$output" =~ "Kernel:" ]]
}

@test "virtos-version --json outputs valid JSON structure" {
    run "$SCRIPT" --json
    [ "$status" -eq 0 ]
    [[ "$output" =~ "\"virtos\":" ]]
    [[ "$output" =~ "\"system\":" ]]
    [[ "$output" =~ "\"version\":" ]]
}

@test "virtos-version --json contains kernel info" {
    run "$SCRIPT" --json
    [ "$status" -eq 0 ]
    [[ "$output" =~ "\"kernel\":" ]]
    [[ "$output" =~ "\"architecture\":" ]]
}

@test "virtos-version --system shows extended info" {
    run "$SCRIPT" --system
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Extended System Information" ]]
}

@test "virtos-version detects KVM availability" {
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Virtualization:" ]]
    # Should say either "KVM enabled" or "KVM not available"
    [[ "$output" =~ "KVM" ]]
}

@test "virtos-version shows CPU information" {
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "CPU" ]]
}

@test "virtos-version without arguments shows full version" {
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    # Should have multiple sections
    [[ "$output" =~ "VirtOS Release:" ]]
    [[ "$output" =~ "Components:" ]]
    [[ "$output" =~ "System:" ]]
}

@test "virtos-version -h is same as --help" {
    run "$SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-version -s is same as --short" {
    run "$SCRIPT" -s
    [ "$status" -eq 0 ]
    # Should be brief output
    [ "${#lines[@]}" -le 3 ]
}

@test "virtos-version -j is same as --json" {
    run "$SCRIPT" -j
    [ "$status" -eq 0 ]
    [[ "$output" =~ "{" ]]
    [[ "$output" =~ "}" ]]
}
