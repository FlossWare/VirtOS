#!/usr/bin/env bats
# Unit tests for virtos-container-security (Container security scanning)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-container-security"

setup() {
    # Skip if virtos-container-security not available
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-container-security script not found"
    fi
}

@test "virtos-container-security exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-container-security shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-container-security --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "virtos-container-security --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-container-security help shows security commands" {
    run "$SCRIPT_PATH" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "scan" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-container-security scan requires image name" {
    skip "Requires container runtime and security scanner"
    run "$SCRIPT_PATH" scan
    [ "$status" -ne 0 ]
}

@test "virtos-container-security list returns successfully" {
    skip "Requires container runtime"
    run "$SCRIPT_PATH" list
    [ "$status" -eq 0 ]
}

@test "virtos-container-security report requires scan ID or image" {
    skip "Requires previous security scan"
    run "$SCRIPT_PATH" report
    [ "$status" -ne 0 ]
}

@test "virtos-container-security policy-check requires image and policy" {
    skip "Requires security policies"
    run "$SCRIPT_PATH" policy-check
    [ "$status" -ne 0 ]
}

@test "virtos-container-security container security workflow (placeholder)" {
    skip "Requires container runtime, security scanner, and images"
    # Full workflow test would:
    # 1. Scan container image for vulnerabilities
    # 2. Generate security report
    # 3. Check against security policy
    # 4. Block/allow based on policy
    # 5. Export scan results
    # 6. Clean up
}
