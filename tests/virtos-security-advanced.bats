#!/usr/bin/env bats
# Unit tests for virtos-security-advanced (Advanced security features)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-security-advanced"

setup() {
    # Skip if virtos-security-advanced not available
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-security-advanced script not found"
    fi
}

@test "virtos-security-advanced exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-security-advanced shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-security-advanced --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "virtos-security-advanced --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-security-advanced help shows security commands" {
    run "$SCRIPT_PATH" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "encrypt" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-security-advanced encrypt-disk requires VM name" {
    skip "Requires encryption tools and VMs"
    run "$SCRIPT_PATH" encrypt-disk
    [ "$status" -ne 0 ]
}

@test "virtos-security-advanced selinux command exists" {
    skip "Requires SELinux and permissions"
    run "$SCRIPT_PATH" selinux
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "virtos-security-advanced apparmor command exists" {
    skip "Requires AppArmor and permissions"
    run "$SCRIPT_PATH" apparmor
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "virtos-security-advanced seccomp command exists" {
    skip "Requires seccomp tools"
    run "$SCRIPT_PATH" seccomp
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "virtos-security-advanced tpm requires VM name" {
    skip "Requires TPM support and VMs"
    run "$SCRIPT_PATH" tpm
    [ "$status" -ne 0 ]
}

@test "virtos-security-advanced audit-log returns successfully" {
    skip "Requires audit logging"
    run "$SCRIPT_PATH" audit-log
    [ "$status" -eq 0 ]
}

@test "virtos-security-advanced intrusion-detection command exists" {
    skip "Requires IDS tools"
    run "$SCRIPT_PATH" intrusion-detection
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "virtos-security-advanced disk encryption workflow (placeholder)" {
    skip "Requires encryption tools, VMs, and permissions"
    # Full workflow test would:
    # 1. Create test VM with disk
    # 2. Encrypt disk
    # 3. Verify encryption enabled
    # 4. Start VM with encrypted disk
    # 5. Decrypt disk
    # 6. Clean up
}

@test "virtos-security-advanced MAC policy workflow (placeholder)" {
    skip "Requires SELinux/AppArmor and permissions"
    # Full workflow test would:
    # 1. Apply MAC policy to VM
    # 2. Verify policy active
    # 3. Test policy enforcement
    # 4. Remove policy
    # 5. Clean up
}
