#!/usr/bin/env bats
# Security tests for virtos-migrate path traversal vulnerability (Issue #250)

SCRIPT_PATH="../config/custom-scripts/virtos-migrate"
PACKAGE_PATH="../packages/virtos-tools/src/usr/local/bin/virtos-migrate"

setup() {
    # Variables set above
    :
}

@test "virtos-migrate has no hardcoded /tmp paths" {
    # Should not use hardcoded /tmp for temp files
    ! grep -E '"/tmp/[^"]+\.xml"' "$SCRIPT_PATH"
}

@test "virtos-migrate uses mktemp for local temp files" {
    # Should use mktemp for creating temp files
    grep -q "mktemp.*suffix.*xml" "$SCRIPT_PATH"
}

@test "virtos-migrate uses mktemp for remote temp files" {
    # Should create remote temp files via SSH mktemp
    grep -q 'ssh.*mktemp.*suffix' "$SCRIPT_PATH"
}

@test "virtos-migrate has cleanup trap for temp files" {
    # Should register cleanup trap
    grep -q "trap.*rm.*EXIT" "$SCRIPT_PATH"
}

@test "virtos-migrate cleans up remote temp files" {
    # Should clean up remote temp files after use
    grep -q "rm -f.*remote_xml" "$SCRIPT_PATH"
}

@test "virtos-migrate config and package files are synchronized" {
    if [ -f "$PACKAGE_PATH" ] && [ -f "$SCRIPT_PATH" ]; then
        diff -q "$PACKAGE_PATH" "$SCRIPT_PATH"
    else
        skip "One or both virtos-migrate files not found"
    fi
}

@test "virtos-migrate does not use predictable temp file names" {
    # Should not use VM name in temp file path (race condition)
    ! grep -E 'vm_xml=".*/\$\{vm_name\}\.xml"' "$SCRIPT_PATH"
}

@test "virtos-migrate passes secure temp file to remote host" {
    # Should pass the secure temp file name, not hardcoded path
    grep -q 'scp.*remote_xml' "$SCRIPT_PATH"
}
