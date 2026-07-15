#!/usr/bin/env bats
# Security tests for dead error recovery code (Issue #251)

setup() {
    :
}

@test "virtos-backup has no dead error recovery code" {
    SCRIPT_PATH="../config/custom-scripts/virtos-backup"
    # Should not have command followed by $? check under set -e
    ! grep -A1 "virsh\|qemu-img" "$SCRIPT_PATH" | grep -E "^\s*if \[ \$\? -eq 0 \]"
}

@test "virtos-migrate has no dead error recovery code" {
    SCRIPT_PATH="../config/custom-scripts/virtos-migrate"
    ! grep -A1 "virsh\|ssh\|scp" "$SCRIPT_PATH" | grep -E "^\s*if \[ \$\? -eq 0 \]"
}

@test "virtos-snapshot has no dead error recovery code" {
    SCRIPT_PATH="../config/custom-scripts/virtos-snapshot"
    ! grep -A1 "virsh" "$SCRIPT_PATH" | grep -E "^\s*if \[ \$\? -eq 0 \]"
}

@test "virtos-billing has no dead error recovery code" {
    SCRIPT_PATH="../config/custom-scripts/virtos-billing"
    ! grep -A1 "sqlite3\|virsh" "$SCRIPT_PATH" | grep -E "^\s*if \[ \$\? -eq 0 \]"
}

@test "virtos-cloud-init has no dead error recovery code" {
    SCRIPT_PATH="../config/custom-scripts/virtos-cloud-init"
    ! grep -A1 "genisoimage\|virsh" "$SCRIPT_PATH" | grep -E "^\s*if \[ \$\? -eq 0 \]"
}

@test "virtos-ha has no dead error recovery code" {
    SCRIPT_PATH="../config/custom-scripts/virtos-ha"
    ! grep -A1 "virsh" "$SCRIPT_PATH" | grep -E "^\s*if \[ \$\? -eq 0 \]"
}

@test "virtos-secrets has no dead error recovery code" {
    SCRIPT_PATH="../config/custom-scripts/virtos-secrets"
    ! grep -A1 "vault\|aws\|kubectl" "$SCRIPT_PATH" | grep -E "^\s*if \[ \$\? -eq 0 \]"
}

@test "virtos-security has no dead error recovery code" {
    SCRIPT_PATH="../config/custom-scripts/virtos-security"
    ! grep -A1 "checkmodule\|semodule_package" "$SCRIPT_PATH" | grep -E "^\s*if \[ \$\? -eq 0 \]"
}

@test "virtos-setup has no dead error recovery code" {
    SCRIPT_PATH="../config/custom-scripts/virtos-setup"
    ! grep -A1 "dialog\|whiptail" "$SCRIPT_PATH" | grep -E "^\s*if \[ \$\? -eq 0 \]"
}

@test "virtos-template has no dead error recovery code" {
    SCRIPT_PATH="../config/custom-scripts/virtos-template"
    ! grep -A1 "curl\|wget" "$SCRIPT_PATH" | grep -E "^\s*if \[ \$\? -eq 0 \]"
}

@test "virtos-tui has no dead error recovery code" {
    SCRIPT_PATH="../config/custom-scripts/virtos-tui"
    ! grep -A1 "dialog\|whiptail" "$SCRIPT_PATH" | grep -E "^\s*if \[ \$\? -eq 0 \]"
}

@test "virtos-backup uses direct if-testing pattern" {
    SCRIPT_PATH="../config/custom-scripts/virtos-backup"
    # Should use 'if command; then' pattern
    grep -q "if virsh\|if qemu-img" "$SCRIPT_PATH"
}

@test "virtos-migrate uses direct if-testing pattern" {
    SCRIPT_PATH="../config/custom-scripts/virtos-migrate"
    grep -q "if virsh\|if ssh" "$SCRIPT_PATH"
}

@test "virtos-snapshot uses direct if-testing pattern" {
    SCRIPT_PATH="../config/custom-scripts/virtos-snapshot"
    grep -q "if virsh" "$SCRIPT_PATH"
}
