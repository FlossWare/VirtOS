#!/usr/bin/env bats
# Unit tests for virtos-security (Security hardening and compliance)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-security"

setup() {
    # Skip if virtos-security not available
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-security script not found"
    fi
}

@test "virtos-security exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-security shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-security --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "virtos-security --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-security help shows security commands" {
    run "$SCRIPT_PATH" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "scan" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-security scan returns successfully" {
    skip "Requires security tools and permissions"
    run "$SCRIPT_PATH" scan
    [ "$status" -eq 0 ]
}

@test "virtos-security audit returns successfully" {
    skip "Requires security tools and permissions"
    run "$SCRIPT_PATH" audit
    [ "$status" -eq 0 ]
}

@test "virtos-security harden command exists" {
    skip "Requires security tools and permissions"
    run "$SCRIPT_PATH" harden
    # May succeed or fail depending on system state
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "virtos-security compliance-check returns successfully" {
    skip "Requires security tools and compliance frameworks"
    run "$SCRIPT_PATH" compliance-check
    [ "$status" -eq 0 ]
}

@test "virtos-security report returns successfully" {
    skip "Requires security tools and previous scans"
    run "$SCRIPT_PATH" report
    [ "$status" -eq 0 ]
}

@test "virtos-security policy-apply requires policy name" {
    skip "Requires security policies"
    run "$SCRIPT_PATH" policy-apply
    [ "$status" -ne 0 ]
}

@test "virtos-security security scan workflow (placeholder)" {
    skip "Requires security tools, VMs, and permissions"
    # Full workflow test would:
    # 1. Run security scan
    # 2. Verify scan results
    # 3. Generate report
    # 4. Apply hardening recommendations
    # 5. Re-scan to verify
    # 6. Clean up
}
