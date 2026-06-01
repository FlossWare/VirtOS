#!/bin/bash
# shellcheck disable=SC2001,SC2004,SC2016,SC2027,SC2034,SC2046,SC2050,SC2064,SC2140,SC2144,SC2155
# Copyright (c) 2026 FlossWare
# Licensed under the GNU General Public License v3.0. See LICENSE file in the project root.
# VirtOS Keyring Library - Secure credential management using Linux kernel keyring
#
# This library provides secure credential storage and retrieval using the Linux
# kernel keyring subsystem. It integrates with VirtOS audit logging and provides
# automatic credential expiration.
#
# Features:
#   - Linux kernel keyring integration (keyctl)
#   - Automatic credential expiration
#   - Audit logging for all credential operations
#   - Type-safe credential storage (password, token, key, certificate)
#   - Session-scoped and persistent keyrings
#   - Secure credential rotation
#
# Usage:
#   source /usr/local/lib/virtos-common.sh
#   source /usr/local/lib/virtos-audit.sh
#   source /usr/local/lib/virtos-keyring.sh
#
#   # Store credential with 1 hour expiration
#   keyring_store "vm.admin.password" "secret123" "password" 3600
#
#   # Retrieve credential
#   password=$(keyring_get "vm.admin.password")
#
#   # List credentials
#   keyring_list
#
#   # Rotate credential
#   keyring_rotate "vm.admin.password" "newsecret456" 3600
#
#   # Delete credential
#   keyring_delete "vm.admin.password"
#
# See: https://github.com/FlossWare/VirtOS/issues/108
# See: https://man7.org/linux/man-pages/man1/keyctl.1.html

# Load dependencies
if [ -f /usr/local/lib/virtos-common.sh ]; then
    # shellcheck source=/dev/null
    . /usr/local/lib/virtos-common.sh
fi

if [ -f /usr/local/lib/virtos-audit.sh ]; then
    # shellcheck source=/dev/null
    . /usr/local/lib/virtos-audit.sh
fi

#==============================================================================
# Configuration
#==============================================================================

# Keyring name for VirtOS credentials
VIRTOS_KEYRING_NAME="virtos-credentials"

# Default credential timeout (1 hour)
VIRTOS_KEYRING_DEFAULT_TIMEOUT=3600

# Maximum credential timeout (24 hours)
VIRTOS_KEYRING_MAX_TIMEOUT=86400

# Keyring type (user, session, process, thread, persistent)
VIRTOS_KEYRING_TYPE="${VIRTOS_KEYRING_TYPE:-session}"

# Enable audit logging for keyring operations
VIRTOS_KEYRING_AUDIT="${VIRTOS_KEYRING_AUDIT:-1}"

#==============================================================================
# Keyring Initialization
#==============================================================================

# Check if keyctl is available
_keyring_check_keyctl() {
    if ! command -v keyctl >/dev/null 2>&1; then
        if [ -n "$BASH_VERSION" ]; then
            die "keyctl command not found. Install: apt install keyutils" 127
        else
            echo "Error: keyctl command not found. Install: apt install keyutils" >&2
            return 127
        fi
    fi
}

# Initialize VirtOS keyring
# Returns: 0 on success, 1 on failure
keyring_init() {
    _keyring_check_keyctl

    # Check if VirtOS keyring already exists
    local keyring_id
    keyring_id=$(keyctl search @s keyring "$VIRTOS_KEYRING_NAME" 2>/dev/null || echo "")

    if [ -z "$keyring_id" ]; then
        # Create new keyring
        keyring_id=$(keyctl newring "$VIRTOS_KEYRING_NAME" @s 2>/dev/null)
        if [ -z "$keyring_id" ]; then
            warn "Failed to create VirtOS keyring"
            if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
                audit_fail "keyring.init" "$VIRTOS_KEYRING_NAME" "failed to create keyring"
            fi
            return 1
        fi

        # Set keyring permissions (read/write for owner only)
        keyctl setperm "$keyring_id" 0x3f000000 2>/dev/null || true

        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_success "keyring.init" "$VIRTOS_KEYRING_NAME" "keyring_id=$keyring_id"
        fi
    fi

    echo "$keyring_id"
    return 0
}

#==============================================================================
# Credential Type Validation
#==============================================================================

# Validate credential type
# Args: $1 - credential type
# Returns: 0 if valid, 1 if invalid
_keyring_validate_type() {
    local cred_type="$1"

    case "$cred_type" in
        password|token|key|certificate|secret|api-key)
            return 0
            ;;
        *)
            warn "Invalid credential type: $cred_type"
            echo "Valid types: password, token, key, certificate, secret, api-key" >&2
            return 1
            ;;
    esac
}

#==============================================================================
# Credential Name Validation
#==============================================================================

# Validate credential name
# Args: $1 - credential name
# Returns: 0 if valid, 1 if invalid
_keyring_validate_name() {
    local name="$1"

    # Must be non-empty
    if [ -z "$name" ]; then
        warn "Credential name cannot be empty"
        return 1
    fi

    # Must be alphanumeric with dots, hyphens, underscores (max 253 chars)
    if ! echo "$name" | grep -qE '^[a-zA-Z0-9._-]{1,253}$'; then
        warn "Invalid credential name: $name"
        echo "Name must be alphanumeric with dots, hyphens, underscores (max 253 chars)" >&2
        return 1
    fi

    return 0
}

#==============================================================================
# Credential Storage
#==============================================================================

# Store credential in keyring
# Args:
#   $1 - credential name (e.g., "vm.admin.password")
#   $2 - credential value (password, token, etc.)
#   $3 - credential type (password|token|key|certificate|secret|api-key)
#   $4 - timeout in seconds (optional, default: 3600)
# Returns: key ID on success, empty on failure
keyring_store() {
    local name="$1"
    local value="$2"
    local cred_type="${3:-password}"
    local timeout="${4:-$VIRTOS_KEYRING_DEFAULT_TIMEOUT}"

    # Validate inputs
    if ! _keyring_validate_name "$name"; then
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.store" "$name" "invalid credential name"
        fi
        return 1
    fi

    if [ -z "$value" ]; then
        warn "Credential value cannot be empty"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.store" "$name" "empty credential value"
        fi
        return 1
    fi

    if ! _keyring_validate_type "$cred_type"; then
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.store" "$name" "invalid credential type: $cred_type"
        fi
        return 1
    fi

    # Validate timeout
    if ! validate_number "$timeout"; then
        warn "Invalid timeout: $timeout (must be a positive integer)"
        timeout="$VIRTOS_KEYRING_DEFAULT_TIMEOUT"
    fi

    # Cap timeout at maximum
    if [ "$timeout" -gt "$VIRTOS_KEYRING_MAX_TIMEOUT" ]; then
        warn "Timeout exceeds maximum ($VIRTOS_KEYRING_MAX_TIMEOUT seconds), capping"
        timeout="$VIRTOS_KEYRING_MAX_TIMEOUT"
    fi

    # Initialize keyring
    local keyring_id
    keyring_id=$(keyring_init)
    if [ -z "$keyring_id" ]; then
        warn "Failed to initialize keyring"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.store" "$name" "keyring initialization failed"
        fi
        return 1
    fi

    # Check if credential already exists (revoke old key)
    local old_key_id
    old_key_id=$(keyctl search "@$keyring_id" user "virtos:$cred_type:$name" 2>/dev/null || echo "")
    if [ -n "$old_key_id" ]; then
        keyctl revoke "$old_key_id" 2>/dev/null || true
        keyctl unlink "$old_key_id" "@$keyring_id" 2>/dev/null || true
    fi

    # Store credential in keyring
    local key_id
    key_id=$(echo -n "$value" | keyctl padd user "virtos:$cred_type:$name" "@$keyring_id" 2>/dev/null)

    if [ -z "$key_id" ]; then
        warn "Failed to store credential in keyring"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.store" "$name" "keyctl padd failed"
        fi
        return 1
    fi

    # Set timeout on key
    if ! keyctl timeout "$key_id" "$timeout" 2>/dev/null; then
        warn "Failed to set timeout on credential (key=$key_id)"
    fi

    # Set key permissions (read by owner only)
    keyctl setperm "$key_id" 0x3f000000 2>/dev/null || true

    # Audit log
    if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
        audit_success "keyring.store" "$name" "type=$cred_type timeout=${timeout}s key_id=$key_id"
    fi

    echo "$key_id"
    return 0
}

#==============================================================================
# Credential Retrieval
#==============================================================================

# Retrieve credential from keyring
# Args:
#   $1 - credential name
#   $2 - credential type (optional, default: password)
# Returns: credential value on success, empty on failure
keyring_get() {
    local name="$1"
    local cred_type="${2:-password}"

    # Validate inputs
    if ! _keyring_validate_name "$name"; then
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.get" "$name" "invalid credential name"
        fi
        return 1
    fi

    if ! _keyring_validate_type "$cred_type"; then
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.get" "$name" "invalid credential type: $cred_type"
        fi
        return 1
    fi

    # Initialize keyring
    local keyring_id
    keyring_id=$(keyring_init)
    if [ -z "$keyring_id" ]; then
        warn "Failed to initialize keyring"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.get" "$name" "keyring initialization failed"
        fi
        return 1
    fi

    # Search for credential
    local key_id
    key_id=$(keyctl search "@$keyring_id" user "virtos:$cred_type:$name" 2>/dev/null || echo "")

    if [ -z "$key_id" ]; then
        warn "Credential not found: $name (type: $cred_type)"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.get" "$name" "credential not found"
        fi
        return 1
    fi

    # Read credential value
    local value
    value=$(keyctl pipe "$key_id" 2>/dev/null)

    if [ -z "$value" ]; then
        warn "Failed to read credential: $name (key_id: $key_id)"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.get" "$name" "keyctl pipe failed (key_id=$key_id)"
        fi
        return 1
    fi

    # Audit log (successful retrieval)
    if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
        audit_success "keyring.get" "$name" "type=$cred_type key_id=$key_id"
    fi

    echo "$value"
    return 0
}

#==============================================================================
# Credential Deletion
#==============================================================================

# Delete credential from keyring
# Args:
#   $1 - credential name
#   $2 - credential type (optional, default: password)
# Returns: 0 on success, 1 on failure
keyring_delete() {
    local name="$1"
    local cred_type="${2:-password}"

    # Validate inputs
    if ! _keyring_validate_name "$name"; then
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.delete" "$name" "invalid credential name"
        fi
        return 1
    fi

    if ! _keyring_validate_type "$cred_type"; then
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.delete" "$name" "invalid credential type: $cred_type"
        fi
        return 1
    fi

    # Initialize keyring
    local keyring_id
    keyring_id=$(keyring_init)
    if [ -z "$keyring_id" ]; then
        warn "Failed to initialize keyring"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.delete" "$name" "keyring initialization failed"
        fi
        return 1
    fi

    # Search for credential
    local key_id
    key_id=$(keyctl search "@$keyring_id" user "virtos:$cred_type:$name" 2>/dev/null || echo "")

    if [ -z "$key_id" ]; then
        warn "Credential not found: $name (type: $cred_type)"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.delete" "$name" "credential not found"
        fi
        return 1
    fi

    # Revoke and unlink key
    if ! keyctl revoke "$key_id" 2>/dev/null; then
        warn "Failed to revoke credential: $name (key_id: $key_id)"
    fi

    if ! keyctl unlink "$key_id" "@$keyring_id" 2>/dev/null; then
        warn "Failed to unlink credential: $name (key_id: $key_id)"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.delete" "$name" "keyctl unlink failed (key_id=$key_id)"
        fi
        return 1
    fi

    # Audit log
    if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
        audit_success "keyring.delete" "$name" "type=$cred_type key_id=$key_id"
    fi

    return 0
}

#==============================================================================
# Credential Rotation
#==============================================================================

# Rotate credential (atomic update with audit trail)
# Args:
#   $1 - credential name
#   $2 - new credential value
#   $3 - credential type (optional, default: password)
#   $4 - timeout in seconds (optional, default: 3600)
# Returns: new key ID on success, empty on failure
keyring_rotate() {
    local name="$1"
    local new_value="$2"
    local cred_type="${3:-password}"
    local timeout="${4:-$VIRTOS_KEYRING_DEFAULT_TIMEOUT}"

    # Validate inputs
    if ! _keyring_validate_name "$name"; then
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.rotate" "$name" "invalid credential name"
        fi
        return 1
    fi

    if [ -z "$new_value" ]; then
        warn "New credential value cannot be empty"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.rotate" "$name" "empty credential value"
        fi
        return 1
    fi

    if ! _keyring_validate_type "$cred_type"; then
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.rotate" "$name" "invalid credential type: $cred_type"
        fi
        return 1
    fi

    # Check if credential exists
    local old_key_id
    old_key_id=$(keyctl search "@s" user "virtos:$cred_type:$name" 2>/dev/null || echo "")

    if [ -z "$old_key_id" ]; then
        warn "Credential not found for rotation: $name"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.rotate" "$name" "credential not found"
        fi
        return 1
    fi

    # Store new credential (automatically revokes old one)
    local new_key_id
    new_key_id=$(keyring_store "$name" "$new_value" "$cred_type" "$timeout")

    if [ -z "$new_key_id" ]; then
        warn "Failed to rotate credential: $name"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.rotate" "$name" "failed to store new credential"
        fi
        return 1
    fi

    # Audit log (rotation event)
    if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
        audit_success "keyring.rotate" "$name" "type=$cred_type old_key=$old_key_id new_key=$new_key_id"
    fi

    echo "$new_key_id"
    return 0
}

#==============================================================================
# Credential Listing
#==============================================================================

# List all VirtOS credentials in keyring
# Returns: list of credential names (one per line)
keyring_list() {
    # Initialize keyring
    local keyring_id
    keyring_id=$(keyring_init)
    if [ -z "$keyring_id" ]; then
        warn "Failed to initialize keyring"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.list" "all" "keyring initialization failed"
        fi
        return 1
    fi

    # List keys in keyring
    local keys
    keys=$(keyctl rlist "@$keyring_id" 2>/dev/null || echo "")

    if [ -z "$keys" ]; then
        echo "No credentials stored in keyring"
        return 0
    fi

    # Parse key IDs and get descriptions
    echo "=== VirtOS Credentials ==="
    echo ""
    printf "%-8s %-12s %-40s %-10s\n" "KEY_ID" "TYPE" "NAME" "TIMEOUT"
    printf "%-8s %-12s %-40s %-10s\n" "------" "----" "----" "-------"

    echo "$keys" | tr ' ' '\n' | while read -r key_id; do
        if [ -z "$key_id" ]; then
            continue
        fi

        # Get key description
        local desc
        desc=$(keyctl describe "$key_id" 2>/dev/null || echo "")

        if [ -z "$desc" ]; then
            continue
        fi

        # Parse description format: "user;UID;GID;PERM;virtos:TYPE:NAME"
        local key_name
        key_name=$(echo "$desc" | awk -F';' '{print $5}')

        # Check if this is a VirtOS credential
        if ! echo "$key_name" | grep -q '^virtos:'; then
            continue
        fi

        # Parse virtos:TYPE:NAME
        local cred_type
        local cred_name
        cred_type=$(echo "$key_name" | cut -d: -f2)
        cred_name=$(echo "$key_name" | cut -d: -f3-)

        # Get timeout
        local timeout_info
        timeout_info=$(keyctl timeout "$key_id" 2>&1 || echo "unknown")

        # Extract timeout value from error message (e.g., "keyctl_set_timeout: Invalid argument")
        # Or use keyctl describe output
        local remaining
        remaining=$(keyctl describe "$key_id" 2>/dev/null | grep -oP '\d+s' | head -1 || echo "N/A")

        printf "%-8s %-12s %-40s %-10s\n" "$key_id" "$cred_type" "$cred_name" "$remaining"
    done

    # Audit log
    if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
        audit_success "keyring.list" "all" "keyring_id=$keyring_id"
    fi

    return 0
}

#==============================================================================
# Credential Information
#==============================================================================

# Get detailed information about a credential
# Args:
#   $1 - credential name
#   $2 - credential type (optional, default: password)
# Returns: 0 on success, 1 on failure
keyring_info() {
    local name="$1"
    local cred_type="${2:-password}"

    # Validate inputs
    if ! _keyring_validate_name "$name"; then
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.info" "$name" "invalid credential name"
        fi
        return 1
    fi

    if ! _keyring_validate_type "$cred_type"; then
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.info" "$name" "invalid credential type: $cred_type"
        fi
        return 1
    fi

    # Initialize keyring
    local keyring_id
    keyring_id=$(keyring_init)
    if [ -z "$keyring_id" ]; then
        warn "Failed to initialize keyring"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.info" "$name" "keyring initialization failed"
        fi
        return 1
    fi

    # Search for credential
    local key_id
    key_id=$(keyctl search "@$keyring_id" user "virtos:$cred_type:$name" 2>/dev/null || echo "")

    if [ -z "$key_id" ]; then
        warn "Credential not found: $name (type: $cred_type)"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.info" "$name" "credential not found"
        fi
        return 1
    fi

    # Get key description
    local desc
    desc=$(keyctl describe "$key_id" 2>/dev/null || echo "")

    echo "=== Credential Information ==="
    echo "Name:       $name"
    echo "Type:       $cred_type"
    echo "Key ID:     $key_id"
    echo "Keyring ID: $keyring_id"
    echo ""
    echo "Key Description:"
    echo "$desc"
    echo ""

    # Get key permissions
    local perms
    perms=$(echo "$desc" | awk -F';' '{print $4}')
    echo "Permissions: $perms"

    # Audit log
    if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
        audit_success "keyring.info" "$name" "type=$cred_type key_id=$key_id"
    fi

    return 0
}

#==============================================================================
# Keyring Cleanup
#==============================================================================

# Clear all VirtOS credentials from keyring
# Returns: 0 on success, 1 on failure
keyring_clear() {
    # Confirm destructive operation
    if [ -n "$BASH_VERSION" ] && command -v confirm_destructive >/dev/null 2>&1; then
        confirm_destructive "Clear all VirtOS credentials" "all credentials in keyring"
    else
        echo "WARNING: This will delete ALL VirtOS credentials from the keyring"
        printf "Are you sure? [y/N]: "
        read -r response
        case "$response" in
            [Yy]|[Yy][Ee][Ss]) ;;
            *) echo "Operation cancelled."; return 0 ;;
        esac
    fi

    # Initialize keyring
    local keyring_id
    keyring_id=$(keyring_init)
    if [ -z "$keyring_id" ]; then
        warn "Failed to initialize keyring"
        if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
            audit_fail "keyring.clear" "all" "keyring initialization failed"
        fi
        return 1
    fi

    # Revoke all keys in keyring
    local keys
    keys=$(keyctl rlist "@$keyring_id" 2>/dev/null || echo "")

    if [ -z "$keys" ]; then
        echo "No credentials to clear"
        return 0
    fi

    local count=0
    echo "$keys" | tr ' ' '\n' | while read -r key_id; do
        if [ -z "$key_id" ]; then
            continue
        fi

        # Check if this is a VirtOS credential
        local desc
        desc=$(keyctl describe "$key_id" 2>/dev/null || echo "")
        if echo "$desc" | grep -q 'virtos:'; then
            keyctl revoke "$key_id" 2>/dev/null || true
            keyctl unlink "$key_id" "@$keyring_id" 2>/dev/null || true
            count=$((count + 1))
        fi
    done

    echo "Cleared $count credentials from keyring"

    # Audit log
    if [ -n "$VIRTOS_KEYRING_AUDIT" ]; then
        audit_success "keyring.clear" "all" "count=$count keyring_id=$keyring_id"
    fi

    return 0
}

#==============================================================================
# Export functions (if running in bash)
#==============================================================================

if [ -n "$BASH_VERSION" ]; then
    export -f keyring_init 2>/dev/null || true
    export -f keyring_store 2>/dev/null || true
    export -f keyring_get 2>/dev/null || true
    export -f keyring_delete 2>/dev/null || true
    export -f keyring_rotate 2>/dev/null || true
    export -f keyring_list 2>/dev/null || true
    export -f keyring_info 2>/dev/null || true
    export -f keyring_clear 2>/dev/null || true
fi
