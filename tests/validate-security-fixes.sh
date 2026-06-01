#!/bin/bash
# Validation script for /tmp security fixes

set -e

echo "=== VirtOS Security Fix Validation ==="
echo ""

# Load common library
source config/custom-scripts/lib/virtos-common.sh

passed=0
failed=0

test_passed() {
    echo "✓ $1"
    passed=$((passed + 1))
}

test_failed() {
    echo "✗ $1"
    failed=$((failed + 1))
}

# Test 1: create_secure_temp_file creates file with 600 permissions
echo "Test 1: create_secure_temp_file creates secure files"
temp_file=$(create_secure_temp_file "test")
if [ -f "$temp_file" ]; then
    perms=$(stat -c "%a" "$temp_file")
    if [ "$perms" = "600" ]; then
        test_passed "Temp file has secure permissions (600)"
    else
        test_failed "Temp file has wrong permissions: $perms (expected 600)"
    fi
    rm -f "$temp_file"
else
    test_failed "create_secure_temp_file did not create file"
fi

# Test 2: create_secure_temp_dir creates directory with 700 permissions
echo "Test 2: create_secure_temp_dir creates secure directories"
temp_dir=$(create_secure_temp_dir "test")
if [ -d "$temp_dir" ]; then
    perms=$(stat -c "%a" "$temp_dir")
    if [ "$perms" = "700" ]; then
        test_passed "Temp directory has secure permissions (700)"
    else
        test_failed "Temp directory has wrong permissions: $perms (expected 700)"
    fi
    rm -rf "$temp_dir"
else
    test_failed "create_secure_temp_dir did not create directory"
fi

# Test 3: Temp files are unique (no collisions)
echo "Test 3: Temp files are unique"
temp1=$(create_secure_temp_file "test")
temp2=$(create_secure_temp_file "test")
if [ "$temp1" != "$temp2" ]; then
    test_passed "Temp files are unique (no collision)"
else
    test_failed "Temp files collided: $temp1"
fi
rm -f "$temp1" "$temp2"

# Test 4: Temp files are not predictable (no PID)
echo "Test 4: Temp files are not predictable"
temp_file=$(create_secure_temp_file "test")
if [[ "$temp_file" != *"$$"* ]]; then
    test_passed "Temp file does not contain PID"
else
    test_failed "Temp file contains predictable PID: $temp_file"
fi
rm -f "$temp_file"

# Test 5: Suffix support
echo "Test 5: Temp files support custom suffix"
temp_file=$(create_secure_temp_file "vm-config" ".xml")
if [[ "$temp_file" == *.xml ]]; then
    test_passed "Temp file has correct suffix (.xml)"
else
    test_failed "Temp file missing suffix: $temp_file"
fi
rm -f "$temp_file"

# Test 6: Cleanup trap works
echo "Test 6: Cleanup trap removes files"
result=$(bash -c '
    source config/custom-scripts/lib/virtos-common.sh
    temp_file=$(create_secure_temp_file "trap-test")
    register_cleanup_trap "$temp_file"
    echo "$temp_file"
')
if [ ! -f "$result" ]; then
    test_passed "Cleanup trap removed temp file"
else
    test_failed "Cleanup trap did not remove: $result"
    rm -f "$result"
fi

# Test 7: No hardcoded /tmp paths in CRITICAL scripts
echo "Test 7: CRITICAL vulnerabilities fixed"
if ! grep -q '/tmp/restore-vm\.xml' config/custom-scripts/virtos-backup; then
    test_passed "virtos-backup: no hardcoded /tmp/restore-vm.xml"
else
    test_failed "virtos-backup: still contains /tmp/restore-vm.xml"
fi

if ! grep -q '/tmp/\${vm_name}\.xml' config/custom-scripts/virtos-migrate; then
    test_passed "virtos-migrate: no hardcoded /tmp/\${vm_name}.xml"
else
    test_failed "virtos-migrate: still contains /tmp/\${vm_name}.xml"
fi

if ! grep -q '/tmp/\$new_vm_name\.xml' config/custom-scripts/virtos-template; then
    test_passed "virtos-template: no hardcoded /tmp/\$new_vm_name.xml"
else
    test_failed "virtos-template: still contains /tmp/\$new_vm_name.xml"
fi

# Test 8: No PID-based temp files in HIGH severity scripts
echo "Test 8: HIGH severity vulnerabilities fixed"
if ! grep -q '/tmp/virtos-mcast-\$\$' config/custom-scripts/virtos-cluster; then
    test_passed "virtos-cluster: no PID-based FIFO"
else
    test_failed "virtos-cluster: still contains /tmp/virtos-mcast-\$\$"
fi

if ! grep -q '/tmp/example-vm-\$\$\.yaml' config/custom-scripts/virtos-tui; then
    test_passed "virtos-tui: no PID-based example-vm.yaml"
else
    test_failed "virtos-tui: still contains /tmp/example-vm-\$\$.yaml"
fi

if ! grep -q '/tmp/example-container-\$\$\.yaml' config/custom-scripts/virtos-tui; then
    test_passed "virtos-tui: no PID-based example-container.yaml"
else
    test_failed "virtos-tui: still contains /tmp/example-container-\$\$.yaml"
fi

# Test 9: MEDIUM severity fixes
echo "Test 9: MEDIUM severity vulnerabilities fixed"
if ! grep -q 'cat > /tmp/group\.ldif' config/custom-scripts/virtos-directory; then
    test_passed "virtos-directory: no hardcoded group.ldif"
else
    test_failed "virtos-directory: still contains /tmp/group.ldif"
fi

if ! grep -q 'cat > /tmp/user\.ldif' config/custom-scripts/virtos-directory; then
    test_passed "virtos-directory: no hardcoded user.ldif"
else
    test_failed "virtos-directory: still contains /tmp/user.ldif"
fi

if ! grep -q '/tmp/dialogrc\.setup\.\$\$' config/custom-scripts/virtos-setup; then
    test_passed "virtos-setup: no PID-based DIALOGRC"
else
    test_failed "virtos-setup: still contains /tmp/dialogrc.setup.\$\$"
fi

if ! grep -q '/tmp/dialogrc\.\$\$' config/custom-scripts/virtos-tui; then
    test_passed "virtos-tui: no PID-based DIALOGRC"
else
    test_failed "virtos-tui: still contains /tmp/dialogrc.\$\$"
fi

if ! grep -q '/tmp/iaas-result\.txt' config/custom-scripts/virtos-tui; then
    test_passed "virtos-tui: no hardcoded iaas-result.txt"
else
    test_failed "virtos-tui: still contains /tmp/iaas-result.txt"
fi

# Test 10: Error handling on mktemp
echo "Test 10: mktemp calls have error handling"
mktemp_no_error_handling=$(grep -rn 'mktemp' config/custom-scripts/virtos-* 2>/dev/null | \
    grep -v create_secure_temp | \
    grep -v '||' | \
    grep -v '#' | \
    grep -v Binary | \
    wc -l)

if [ "$mktemp_no_error_handling" -eq 0 ]; then
    test_passed "All mktemp calls have error handling"
else
    test_failed "$mktemp_no_error_handling mktemp calls lack error handling"
fi

echo ""
echo "=== Test Summary ==="
echo "Passed: $passed"
echo "Failed: $failed"
echo ""

if [ "$failed" -eq 0 ]; then
    echo "✓ All security fixes validated successfully!"
    exit 0
else
    echo "✗ Some security fixes failed validation"
    exit 1
fi
