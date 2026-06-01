#!/bin/bash
# VirtOS Keyring Usage Examples
# Copyright (c) 2026 FlossWare - GNU GPL v3.0

set -e

echo "=== VirtOS Keyring Usage Examples ==="
echo ""

# Load libraries
if [ -f /usr/local/lib/virtos-common.sh ]; then
    # shellcheck source=/dev/null
    source /usr/local/lib/virtos-common.sh
else
    echo "Error: virtos-common.sh not found (not in VirtOS environment)"
    exit 1
fi

if [ -f /usr/local/lib/virtos-audit.sh ]; then
    # shellcheck source=/dev/null
    source /usr/local/lib/virtos-audit.sh
fi

if [ -f /usr/local/lib/virtos-keyring.sh ]; then
    # shellcheck source=/dev/null
    source /usr/local/lib/virtos-keyring.sh
else
    echo "Error: virtos-keyring.sh not found"
    exit 1
fi

#==============================================================================
# Example 1: Basic Password Storage
#==============================================================================

echo "Example 1: Basic Password Storage"
echo "=================================="

# Store VM admin password (expires in 1 hour)
if keyring_store "vm.admin.password" "MySecretPass123" "password" 3600; then
    echo "✓ Stored VM admin password"
fi

# Retrieve password
vm_password=$(keyring_get "vm.admin.password")
if [ -n "$vm_password" ]; then
    echo "✓ Retrieved password: $vm_password"
fi

# Delete credential
if keyring_delete "vm.admin.password"; then
    echo "✓ Deleted credential"
fi

echo ""

#==============================================================================
# Example 2: API Token Management
#==============================================================================

echo "Example 2: API Token Management"
echo "==============================="

# Store GitHub API token (24 hours)
github_token="ghp_example123456789"
if keyring_store "github.api.token" "$github_token" "api-key" 86400; then
    echo "✓ Stored GitHub API token (valid for 24 hours)"
fi

# Retrieve and use token
token=$(keyring_get "github.api.token" "api-key")
if [ -n "$token" ]; then
    echo "✓ Retrieved token: ${token:0:10}... (truncated)"
    # Use token for API call
    # curl -H "Authorization: Bearer $token" https://api.github.com/user
fi

# Clean up
keyring_delete "github.api.token" "api-key"

echo ""

#==============================================================================
# Example 3: Credential Rotation
#==============================================================================

echo "Example 3: Credential Rotation"
echo "==============================="

# Store initial credential
keyring_store "service.password" "OldPassword123" "password" 3600
echo "✓ Stored initial password"

# Rotate credential (atomic update)
if keyring_rotate "service.password" "NewPassword456" "password" 3600; then
    echo "✓ Rotated password successfully"
fi

# Verify new password
new_pass=$(keyring_get "service.password")
if [ "$new_pass" = "NewPassword456" ]; then
    echo "✓ Verified new password is active"
fi

# Clean up
keyring_delete "service.password"

echo ""

#==============================================================================
# Example 4: Multiple Credential Types
#==============================================================================

echo "Example 4: Multiple Credential Types"
echo "====================================="

# Store different types of credentials
keyring_store "db.password" "dbpass123" "password" 7200
keyring_store "api.token" "tok_abc123" "token" 14400
keyring_store "ssh.key" "ssh-rsa AAAA..." "key" 3600
keyring_store "tls.cert" "-----BEGIN CERTIFICATE-----" "certificate" 86400

echo "✓ Stored 4 different credential types"

# List all credentials
echo ""
echo "Current credentials:"
keyring_list

# Clean up
keyring_delete "db.password" "password"
keyring_delete "api.token" "token"
keyring_delete "ssh.key" "key"
keyring_delete "tls.cert" "certificate"

echo ""

#==============================================================================
# Example 5: Secure VM Creation Workflow
#==============================================================================

echo "Example 5: Secure VM Creation Workflow"
echo "======================================="

# Simulate VM creation with credentials
vm_name="test-vm"

# Prompt for password (not visible in shell history)
echo -n "Enter VM admin password: "
read -rs admin_password
echo ""

# Store password in keyring (4 hours)
if keyring_store "vm.${vm_name}.admin.password" "$admin_password" "password" 14400; then
    echo "✓ Stored VM admin password in keyring"
fi

# Clear from shell variable
unset admin_password

# Later, retrieve for VM configuration
vm_password=$(keyring_get "vm.${vm_name}.admin.password")
if [ -n "$vm_password" ]; then
    echo "✓ Retrieved password for VM configuration"
    # Configure VM with password
    # virsh set-user-password "$vm_name" admin "$vm_password"
fi

# Clean up
unset vm_password
keyring_delete "vm.${vm_name}.admin.password"

echo ""

#==============================================================================
# Example 6: Audit Log Integration
#==============================================================================

echo "Example 6: Audit Log Integration"
echo "================================="

# All keyring operations are automatically audited
keyring_store "audit.test.password" "secret123" "password" 600
echo "✓ Stored credential (audited)"

keyring_get "audit.test.password" >/dev/null
echo "✓ Retrieved credential (audited)"

keyring_delete "audit.test.password"
echo "✓ Deleted credential (audited)"

echo ""
echo "Check audit log: virtos-audit query action keyring.store"

echo ""
echo "=== Examples Complete ==="
