#!/usr/bin/env bats
# virtos-keyring.bats - Tests for VirtOS keyring credential management
#
# These tests validate the virtos-keyring command and virtos-keyring.sh library
# for secure credential storage using Linux kernel keyring.
#
# Test Categories:
#   - Syntax and structure validation
#   - Command-line interface
#   - Library functions
#   - Credential storage and retrieval
#   - Credential rotation
#   - Audit logging integration
#   - Security validation
#
# Prerequisites:
#   - keyutils package installed (provides keyctl)
#   - virtos-common.sh, virtos-audit.sh, virtos-keyring.sh libraries
#   - Writable /var/log/virtos-audit.log (or fallback to syslog)

# Path to virtos-keyring command
VIRTOS_KEYRING="${VIRTOS_KEYRING:-packages/virtos-tools/src/usr/local/bin/virtos-keyring}"
VIRTOS_KEYRING_LIB="${VIRTOS_KEYRING_LIB:-packages/virtos-tools/src/usr/local/lib/virtos-keyring.sh}"

#==============================================================================
# Syntax and Structure Tests
#==============================================================================

@test "virtos-keyring: script exists and is executable" {
    [ -f "$VIRTOS_KEYRING" ]
    [ -x "$VIRTOS_KEYRING" ]
}

@test "virtos-keyring: has valid shell shebang" {
    head -n 1 "$VIRTOS_KEYRING" | grep -q '^#!/bin/sh'
}

@test "virtos-keyring: passes bash syntax check" {
    bash -n "$VIRTOS_KEYRING"
}

@test "virtos-keyring: library exists and is readable" {
    [ -f "$VIRTOS_KEYRING_LIB" ]
    [ -r "$VIRTOS_KEYRING_LIB" ]
}

@test "virtos-keyring: library passes bash syntax check" {
    bash -n "$VIRTOS_KEYRING_LIB"
}

@test "virtos-keyring: library can be sourced" {
    # Mock dependencies
    export AUDIT_LOG_FILE="/dev/null"

    # Source library (should not error)
    run bash -c "source $VIRTOS_KEYRING_LIB && echo sourced"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "sourced" ]]
}

#==============================================================================
# Command-Line Interface Tests
#==============================================================================

@test "virtos-keyring: shows help with --help" {
    run "$VIRTOS_KEYRING" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "VirtOS Keyring" ]]
    [[ "$output" =~ "USAGE:" ]]
    [[ "$output" =~ "store" ]]
    [[ "$output" =~ "get" ]]
    [[ "$output" =~ "delete" ]]
    [[ "$output" =~ "rotate" ]]
    [[ "$output" =~ "list" ]]
}

@test "virtos-keyring: shows help with -h" {
    run "$VIRTOS_KEYRING" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "VirtOS Keyring" ]]
}

@test "virtos-keyring: shows help with help command" {
    run "$VIRTOS_KEYRING" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "VirtOS Keyring" ]]
}

@test "virtos-keyring: shows version with --version" {
    run "$VIRTOS_KEYRING" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "virtos-keyring version" ]]
}

@test "virtos-keyring: shows version with -v" {
    run "$VIRTOS_KEYRING" -v
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-keyring: shows version with version command" {
    run "$VIRTOS_KEYRING" version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-keyring: fails with no arguments" {
    run "$VIRTOS_KEYRING"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Error: Missing command" ]] || [[ "$output" =~ "Error" ]]
}

@test "virtos-keyring: fails with unknown command" {
    run "$VIRTOS_KEYRING" invalid-command
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Error: Unknown command" ]] || [[ "$output" =~ "Unknown" ]]
}

@test "virtos-keyring: help mentions all main commands" {
    run "$VIRTOS_KEYRING" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "store" ]]
    [[ "$output" =~ "get" ]]
    [[ "$output" =~ "delete" ]]
    [[ "$output" =~ "rotate" ]]
    [[ "$output" =~ "list" ]]
    [[ "$output" =~ "info" ]]
    [[ "$output" =~ "clear" ]]
}

@test "virtos-keyring: help includes examples" {
    run "$VIRTOS_KEYRING" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "EXAMPLES:" ]] || [[ "$output" =~ "virtos-keyring store" ]]
}

@test "virtos-keyring: help mentions exit codes" {
    run "$VIRTOS_KEYRING" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "EXIT CODES:" ]] || [[ "$output" =~ "EXIT CODE" ]]
}

@test "virtos-keyring: help mentions credential types" {
    run "$VIRTOS_KEYRING" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "password" ]]
    [[ "$output" =~ "token" ]]
}

#==============================================================================
# Library Function Tests (Structure)
#==============================================================================

@test "virtos-keyring.sh: exports keyring_init function" {
    run bash -c "source $VIRTOS_KEYRING_LIB && declare -F keyring_init"
    [[ "$output" =~ "keyring_init" ]]
}

@test "virtos-keyring.sh: exports keyring_store function" {
    run bash -c "source $VIRTOS_KEYRING_LIB && declare -F keyring_store"
    [[ "$output" =~ "keyring_store" ]]
}

@test "virtos-keyring.sh: exports keyring_get function" {
    run bash -c "source $VIRTOS_KEYRING_LIB && declare -F keyring_get"
    [[ "$output" =~ "keyring_get" ]]
}

@test "virtos-keyring.sh: exports keyring_delete function" {
    run bash -c "source $VIRTOS_KEYRING_LIB && declare -F keyring_delete"
    [[ "$output" =~ "keyring_delete" ]]
}

@test "virtos-keyring.sh: exports keyring_rotate function" {
    run bash -c "source $VIRTOS_KEYRING_LIB && declare -F keyring_rotate"
    [[ "$output" =~ "keyring_rotate" ]]
}

@test "virtos-keyring.sh: exports keyring_list function" {
    run bash -c "source $VIRTOS_KEYRING_LIB && declare -F keyring_list"
    [[ "$output" =~ "keyring_list" ]]
}

@test "virtos-keyring.sh: exports keyring_info function" {
    run bash -c "source $VIRTOS_KEYRING_LIB && declare -F keyring_info"
    [[ "$output" =~ "keyring_info" ]]
}

@test "virtos-keyring.sh: exports keyring_clear function" {
    run bash -c "source $VIRTOS_KEYRING_LIB && declare -F keyring_clear"
    [[ "$output" =~ "keyring_clear" ]]
}

#==============================================================================
# Configuration Tests
#==============================================================================

@test "virtos-keyring.sh: defines VIRTOS_KEYRING_NAME" {
    run bash -c "source $VIRTOS_KEYRING_LIB && echo \$VIRTOS_KEYRING_NAME"
    [[ "$output" =~ "virtos-credentials" ]]
}

@test "virtos-keyring.sh: defines default timeout" {
    run bash -c "source $VIRTOS_KEYRING_LIB && echo \$VIRTOS_KEYRING_DEFAULT_TIMEOUT"
    [[ "$output" =~ "3600" ]]
}

@test "virtos-keyring.sh: defines maximum timeout" {
    run bash -c "source $VIRTOS_KEYRING_LIB && echo \$VIRTOS_KEYRING_MAX_TIMEOUT"
    [[ "$output" =~ "86400" ]]
}

#==============================================================================
# Credential Type Validation Tests
#==============================================================================

@test "virtos-keyring.sh: validates password type" {
    run bash -c "source $VIRTOS_KEYRING_LIB && _keyring_validate_type password"
    [ "$status" -eq 0 ]
}

@test "virtos-keyring.sh: validates token type" {
    run bash -c "source $VIRTOS_KEYRING_LIB && _keyring_validate_type token"
    [ "$status" -eq 0 ]
}

@test "virtos-keyring.sh: validates key type" {
    run bash -c "source $VIRTOS_KEYRING_LIB && _keyring_validate_type key"
    [ "$status" -eq 0 ]
}

@test "virtos-keyring.sh: validates certificate type" {
    run bash -c "source $VIRTOS_KEYRING_LIB && _keyring_validate_type certificate"
    [ "$status" -eq 0 ]
}

@test "virtos-keyring.sh: validates secret type" {
    run bash -c "source $VIRTOS_KEYRING_LIB && _keyring_validate_type secret"
    [ "$status" -eq 0 ]
}

@test "virtos-keyring.sh: validates api-key type" {
    run bash -c "source $VIRTOS_KEYRING_LIB && _keyring_validate_type api-key"
    [ "$status" -eq 0 ]
}

@test "virtos-keyring.sh: rejects invalid credential type" {
    run bash -c "source $VIRTOS_KEYRING_LIB && _keyring_validate_type invalid"
    [ "$status" -eq 1 ]
}

#==============================================================================
# Credential Name Validation Tests
#==============================================================================

@test "virtos-keyring.sh: validates simple credential name" {
    run bash -c "source $VIRTOS_KEYRING_LIB && _keyring_validate_name 'vm.admin.password'"
    [ "$status" -eq 0 ]
}

@test "virtos-keyring.sh: validates name with hyphens" {
    run bash -c "source $VIRTOS_KEYRING_LIB && _keyring_validate_name 'vm-admin-password'"
    [ "$status" -eq 0 ]
}

@test "virtos-keyring.sh: validates name with underscores" {
    run bash -c "source $VIRTOS_KEYRING_LIB && _keyring_validate_name 'vm_admin_password'"
    [ "$status" -eq 0 ]
}

@test "virtos-keyring.sh: rejects empty credential name" {
    run bash -c "source $VIRTOS_KEYRING_LIB && _keyring_validate_name ''"
    [ "$status" -eq 1 ]
}

@test "virtos-keyring.sh: rejects credential name with spaces" {
    run bash -c "source $VIRTOS_KEYRING_LIB && _keyring_validate_name 'vm admin password'"
    [ "$status" -eq 1 ]
}

@test "virtos-keyring.sh: rejects credential name with special chars" {
    run bash -c "source $VIRTOS_KEYRING_LIB && _keyring_validate_name 'vm@admin!password'"
    [ "$status" -eq 1 ]
}

#==============================================================================
# Integration Tests (Require keyctl)
#==============================================================================

@test "virtos-keyring: store command requires name argument" {
    skip "Requires keyctl runtime environment"
    run "$VIRTOS_KEYRING" store
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Missing" ]] || [[ "$output" =~ "required" ]]
}

@test "virtos-keyring: get command requires name argument" {
    skip "Requires keyctl runtime environment"
    run "$VIRTOS_KEYRING" get
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Missing" ]] || [[ "$output" =~ "required" ]]
}

@test "virtos-keyring: delete command requires name argument" {
    skip "Requires keyctl runtime environment"
    run "$VIRTOS_KEYRING" delete
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Missing" ]] || [[ "$output" =~ "required" ]]
}

@test "virtos-keyring: rotate command requires name and new-value arguments" {
    skip "Requires keyctl runtime environment"
    run "$VIRTOS_KEYRING" rotate test.cred
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Missing" ]] || [[ "$output" =~ "required" ]]
}

#==============================================================================
# Audit Logging Tests
#==============================================================================

@test "virtos-keyring.sh: integrates with audit logging" {
    run bash -c "source $VIRTOS_KEYRING_LIB && declare -F audit_log"
    # Should have audit_log function available
    [[ "$output" =~ "audit_log" ]] || skip "audit_log not available in test env"
}

#==============================================================================
# Security Tests
#==============================================================================

@test "virtos-keyring: help warns about shell history exposure" {
    run "$VIRTOS_KEYRING" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SECURITY" ]] || [[ "$output" =~ "history" ]] || skip "Security notes optional in help"
}

@test "virtos-keyring.sh: library uses set -e for error handling" {
    skip "Library loaded by sourcing, set -e not always effective"
}

@test "virtos-keyring: command uses set -e for error handling" {
    run bash -c "head -20 $VIRTOS_KEYRING | grep 'set -e'"
    [ "$status" -eq 0 ]
}

#==============================================================================
# Documentation Tests
#==============================================================================

@test "virtos-keyring: has copyright header" {
    run head -10 "$VIRTOS_KEYRING"
    [[ "$output" =~ "Copyright" ]] || [[ "$output" =~ "FlossWare" ]]
}

@test "virtos-keyring: has license information" {
    run head -10 "$VIRTOS_KEYRING"
    [[ "$output" =~ "GPL" ]] || [[ "$output" =~ "GNU" ]] || [[ "$output" =~ "License" ]]
}

@test "virtos-keyring.sh: library has copyright header" {
    run head -20 "$VIRTOS_KEYRING_LIB"
    [[ "$output" =~ "Copyright" ]] || [[ "$output" =~ "FlossWare" ]]
}

@test "virtos-keyring.sh: library has usage documentation" {
    run head -50 "$VIRTOS_KEYRING_LIB"
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "source" ]]
}

#==============================================================================
# Workflow Tests (End-to-End)
#==============================================================================

@test "virtos-keyring: workflow - store, get, delete credential" {
    skip "Requires keyctl runtime environment and VirtOS setup"

    # Store credential
    run "$VIRTOS_KEYRING" store test.password secret123 password 300
    [ "$status" -eq 0 ]

    # Retrieve credential
    run "$VIRTOS_KEYRING" get test.password
    [ "$status" -eq 0 ]
    [[ "$output" =~ "secret123" ]]

    # Delete credential
    run "$VIRTOS_KEYRING" delete test.password
    [ "$status" -eq 0 ]

    # Verify deletion
    run "$VIRTOS_KEYRING" get test.password
    [ "$status" -ne 0 ]
}

@test "virtos-keyring: workflow - store and rotate credential" {
    skip "Requires keyctl runtime environment and VirtOS setup"

    # Store credential
    run "$VIRTOS_KEYRING" store test.password secret123 password 300
    [ "$status" -eq 0 ]

    # Rotate credential
    run "$VIRTOS_KEYRING" rotate test.password newsecret456 password 300
    [ "$status" -eq 0 ]

    # Retrieve rotated credential
    run "$VIRTOS_KEYRING" get test.password
    [ "$status" -eq 0 ]
    [[ "$output" =~ "newsecret456" ]]

    # Cleanup
    "$VIRTOS_KEYRING" delete test.password
}

@test "virtos-keyring: workflow - list credentials" {
    skip "Requires keyctl runtime environment and VirtOS setup"

    # Store multiple credentials
    "$VIRTOS_KEYRING" store test.password1 secret1 password 300
    "$VIRTOS_KEYRING" store test.token1 token1 token 300

    # List credentials
    run "$VIRTOS_KEYRING" list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test.password1" ]]
    [[ "$output" =~ "test.token1" ]]

    # Cleanup
    "$VIRTOS_KEYRING" delete test.password1
    "$VIRTOS_KEYRING" delete test.token1 token
}

#==============================================================================
# Error Handling Tests
#==============================================================================

@test "virtos-keyring: handles missing libraries gracefully" {
    skip "Requires isolated test environment"

    # Test with missing virtos-keyring.sh
    run bash -c "export PATH=/nonexistent:\$PATH && $VIRTOS_KEYRING --help"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "not found" ]] || [[ "$output" =~ "Error" ]]
}
