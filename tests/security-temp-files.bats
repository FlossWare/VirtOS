#!/usr/bin/env bats
# Security tests for temporary file handling
# Tests for symlink attack prevention and race condition prevention

# Load common library for testing
setup() {
    # Source the common library
    source config/custom-scripts/lib/virtos-common.sh
}

@test "create_secure_temp_file: creates file with secure permissions (600)" {
    temp_file=$(create_secure_temp_file "test-file")
    
    # Check file exists
    [ -f "$temp_file" ]
    
    # Check permissions are 600 (owner read/write only)
    perms=$(stat -c "%a" "$temp_file")
    [ "$perms" = "600" ]
    
    # Cleanup
    rm -f "$temp_file"
}

@test "create_secure_temp_file: creates unique files (no collision)" {
    temp1=$(create_secure_temp_file "test")
    temp2=$(create_secure_temp_file "test")
    
    # Files must be different
    [ "$temp1" != "$temp2" ]
    
    # Both must exist
    [ -f "$temp1" ]
    [ -f "$temp2" ]
    
    # Cleanup
    rm -f "$temp1" "$temp2"
}

@test "create_secure_temp_file: supports custom suffix" {
    temp_file=$(create_secure_temp_file "vm-config" ".xml")
    
    # Check file has correct extension
    [[ "$temp_file" == *.xml ]]
    
    # Check file exists
    [ -f "$temp_file" ]
    
    # Cleanup
    rm -f "$temp_file"
}

@test "create_secure_temp_dir: creates directory with secure permissions (700)" {
    temp_dir=$(create_secure_temp_dir "test-dir")
    
    # Check directory exists
    [ -d "$temp_dir" ]
    
    # Check permissions are 700 (owner read/write/execute only)
    perms=$(stat -c "%a" "$temp_dir")
    [ "$perms" = "700" ]
    
    # Cleanup
    rm -rf "$temp_dir"
}

@test "create_secure_temp_dir: creates unique directories" {
    temp1=$(create_secure_temp_dir "test")
    temp2=$(create_secure_temp_dir "test")
    
    # Directories must be different
    [ "$temp1" != "$temp2" ]
    
    # Both must exist
    [ -d "$temp1" ]
    [ -d "$temp2" ]
    
    # Cleanup
    rm -rf "$temp1" "$temp2"
}

@test "register_cleanup_trap: removes temp file on exit" {
    # Create temp file in subshell to test trap
    result=$(bash -c '
        source config/custom-scripts/lib/virtos-common.sh
        temp_file=$(create_secure_temp_file "trap-test")
        register_cleanup_trap "$temp_file"
        echo "$temp_file"
    ')
    
    # After subshell exits, temp file should be removed
    [ ! -f "$result" ]
}

@test "register_cleanup_trap: removes multiple files on exit" {
    # Create multiple temp files in subshell
    result=$(bash -c '
        source config/custom-scripts/lib/virtos-common.sh
        temp1=$(create_secure_temp_file "trap-test1")
        temp2=$(create_secure_temp_file "trap-test2")
        temp_dir=$(create_secure_temp_dir "trap-test-dir")
        register_cleanup_trap "$temp1" "$temp2" "$temp_dir"
        echo "$temp1|$temp2|$temp_dir"
    ')
    
    # Parse results
    temp1=$(echo "$result" | cut -d'|' -f1)
    temp2=$(echo "$result" | cut -d'|' -f2)
    temp_dir=$(echo "$result" | cut -d'|' -f3)
    
    # All should be removed after subshell exit
    [ ! -f "$temp1" ]
    [ ! -f "$temp2" ]
    [ ! -d "$temp_dir" ]
}

@test "SECURITY: temp files are not predictable (no PID in name)" {
    temp1=$(create_secure_temp_file "test")
    temp2=$(create_secure_temp_file "test")
    
    # Files should not contain $$ (PID)
    [[ "$temp1" != *"$$"* ]]
    [[ "$temp2" != *"$$"* ]]
    
    # Files should not be sequential (predictable)
    basename1=$(basename "$temp1")
    basename2=$(basename "$temp2")
    [ "$basename1" != "$basename2" ]
    
    # Cleanup
    rm -f "$temp1" "$temp2"
}

@test "SECURITY: temp file prevents symlink attack" {
    # Attacker cannot pre-create a symlink because mktemp creates random names
    temp_file=$(create_secure_temp_file "secure-test")
    
    # Verify it's a regular file, not a symlink
    [ -f "$temp_file" ]
    [ ! -L "$temp_file" ]
    
    # Cleanup
    rm -f "$temp_file"
}

@test "SECURITY: temp file not world-readable" {
    temp_file=$(create_secure_temp_file "secret-data")
    
    # Write sensitive data
    echo "password123" > "$temp_file"
    
    # Check other users cannot read
    perms=$(stat -c "%a" "$temp_file")
    [ "$perms" = "600" ]
    
    # Verify no group/other permissions
    other_perms=$(stat -c "%A" "$temp_file" | cut -c8-10)
    [ "$other_perms" = "---" ]
    
    # Cleanup
    rm -f "$temp_file"
}

@test "SECURITY: temp directory not world-accessible" {
    temp_dir=$(create_secure_temp_dir "secure-dir")
    
    # Create file inside
    echo "secret" > "$temp_dir/secret.txt"
    
    # Check directory permissions prevent access
    perms=$(stat -c "%a" "$temp_dir")
    [ "$perms" = "700" ]
    
    # Verify no group/other permissions
    other_perms=$(stat -c "%A" "$temp_dir" | cut -c8-10)
    [ "$other_perms" = "---" ]
    
    # Cleanup
    rm -rf "$temp_dir"
}

@test "virtos-backup: uses secure temp files (not hardcoded)" {
    # Check virtos-backup doesn't contain /tmp/restore-vm.xml
    ! grep -q '/tmp/restore-vm\.xml' config/custom-scripts/virtos-backup
}

@test "virtos-migrate: uses secure temp files (not predictable)" {
    # Check virtos-migrate doesn't contain /tmp/${vm_name}.xml
    ! grep -q '/tmp/\${vm_name}\.xml' config/custom-scripts/virtos-migrate
}

@test "virtos-template: uses secure temp files (not user-controlled)" {
    # Check virtos-template doesn't contain /tmp/$new_vm_name.xml
    ! grep -q '/tmp/\$new_vm_name\.xml' config/custom-scripts/virtos-template
}

@test "virtos-cluster: uses secure FIFO (not PID-based)" {
    # Check virtos-cluster doesn't contain /tmp/virtos-mcast-$$
    ! grep -q '/tmp/virtos-mcast-\$\$' config/custom-scripts/virtos-cluster
}

@test "virtos-tui: uses secure temp files for examples" {
    # Check virtos-tui doesn't contain /tmp/example-vm-$$.yaml
    ! grep -q '/tmp/example-vm-\$\$\.yaml' config/custom-scripts/virtos-tui
    
    # Check no /tmp/example-container-$$.yaml
    ! grep -q '/tmp/example-container-\$\$\.yaml' config/custom-scripts/virtos-tui
}

@test "virtos-directory: uses secure LDIF files" {
    # Check virtos-directory doesn't contain /tmp/group.ldif
    ! grep -q 'cat > /tmp/group\.ldif' config/custom-scripts/virtos-directory
    
    # Check no /tmp/user.ldif
    ! grep -q 'cat > /tmp/user\.ldif' config/custom-scripts/virtos-directory
}

@test "virtos-setup: uses secure DIALOGRC" {
    # Check virtos-setup doesn't contain /tmp/dialogrc.setup.$$
    ! grep -q '/tmp/dialogrc\.setup\.\$\$' config/custom-scripts/virtos-setup
}

@test "All mktemp calls have error handling" {
    # Find all mktemp calls in virtos-* scripts
    mktemp_calls=$(grep -r 'mktemp' config/custom-scripts/virtos-* 2>/dev/null | grep -v create_secure_temp | grep -v '# ' | grep -v Binary || true)
    
    # Check each mktemp has error handling (|| die or || { ... })
    while IFS= read -r line; do
        if [[ "$line" =~ mktemp ]]; then
            # Should have error handling
            [[ "$line" =~ "||" ]] || [[ "$line" =~ "if" ]]
        fi
    done <<< "$mktemp_calls"
}
