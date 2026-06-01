#!/bin/bash
# virtos-audit.sh - Centralized audit logging for VirtOS
#
# This library provides audit logging functions for tracking sensitive
# operations across all VirtOS management scripts.
#
# Usage:
#   source /usr/local/lib/virtos-audit.sh
#   audit_log "vm.delete" "myvm" "success"
#   audit_log "snapshot.create" "myvm/snap1" "failed" "disk full"

# Audit log file location
AUDIT_LOG_FILE="${AUDIT_LOG_FILE:-/var/log/virtos-audit.log}"

# Log format version (for future parsing compatibility)
AUDIT_LOG_VERSION="1.0"

# Initialize audit logging
# Creates log file with proper permissions if it doesn't exist
audit_init() {
    # Only initialize if running as root or audit log is writable
    if [ -w "$AUDIT_LOG_FILE" ] || [ "$(id -u)" -eq 0 ]; then
        if [ ! -f "$AUDIT_LOG_FILE" ]; then
            touch "$AUDIT_LOG_FILE" || return 1
            chmod 640 "$AUDIT_LOG_FILE" || return 1
            # Make readable by root and virtos group if it exists
            if getent group virtos >/dev/null 2>&1; then
                chgrp virtos "$AUDIT_LOG_FILE" 2>/dev/null || true
            fi
        fi
    fi
}

# Get current user information
# Returns: username
_audit_get_user() {
    # Try SUDO_USER first (if running via sudo)
    if [ -n "$SUDO_USER" ]; then
        echo "$SUDO_USER"
    else
        whoami 2>/dev/null || echo "unknown"
    fi
}

# Get source IP address
# Returns: IP address or "local" if not remote
_audit_get_source() {
    # Try SSH_CLIENT first (SSH sessions)
    if [ -n "$SSH_CLIENT" ]; then
        echo "${SSH_CLIENT%% *}"
    # Try SSH_CONNECTION
    elif [ -n "$SSH_CONNECTION" ]; then
        echo "${SSH_CONNECTION%% *}"
    # Local session
    else
        echo "local"
    fi
}

# Get hostname
# Returns: hostname
_audit_get_hostname() {
    hostname 2>/dev/null || echo "unknown"
}

# Log audit event
# Args:
#   $1 - action (e.g., "vm.delete", "snapshot.create")
#   $2 - resource (e.g., "myvm", "pool/volume")
#   $3 - result ("success" or "failed")
#   $4 - error message (optional, only for failed operations)
#   $5 - additional context (optional, JSON-like key=value pairs)
audit_log() {
    local action="$1"
    local resource="$2"
    local result="$3"
    local error="${4:-}"
    local context="${5:-}"

    # Validate required arguments
    if [ -z "$action" ] || [ -z "$resource" ] || [ -z "$result" ]; then
        echo "Error: audit_log requires action, resource, and result" >&2
        return 1
    fi

    # Validate result value
    case "$result" in
        success | failed | denied | skipped)
            # Valid result
            ;;
        *)
            echo "Warning: Invalid audit result '$result', using 'unknown'" >&2
            result="unknown"
            ;;
    esac

    # Get audit metadata
    local user
    local source
    local hostname
    local timestamp
    local pid

    user="$(_audit_get_user)"
    source="$(_audit_get_source)"
    hostname="$(_audit_get_hostname)"
    timestamp="$(date '+%Y-%m-%d %H:%M:%S %z' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S')"
    pid="$$"

    # Build log entry (structured format for parsing)
    local log_entry
    log_entry="[$timestamp] version=$AUDIT_LOG_VERSION host=$hostname pid=$pid user=$user source=$source action=$action resource=\"$resource\" result=$result"

    # Add error message if present
    if [ -n "$error" ]; then
        # Escape quotes in error message
        local escaped_error
        escaped_error="$(echo "$error" | sed 's/"/\\"/g')"
        log_entry="$log_entry error=\"$escaped_error\""
    fi

    # Add additional context if present
    if [ -n "$context" ]; then
        log_entry="$log_entry $context"
    fi

    # Write to audit log
    if [ -w "$AUDIT_LOG_FILE" ]; then
        echo "$log_entry" >>"$AUDIT_LOG_FILE"
    else
        # Fallback to syslog if audit log not writable
        logger -t virtos-audit -p auth.info "$log_entry" 2>/dev/null || true

        # Also try stderr for debugging
        echo "$log_entry" >&2
    fi
}

# Log successful operation
# Convenience wrapper for audit_log with result="success"
audit_success() {
    local action="$1"
    local resource="$2"
    local context="${3:-}"

    audit_log "$action" "$resource" "success" "" "$context"
}

# Log failed operation
# Convenience wrapper for audit_log with result="failed"
audit_fail() {
    local action="$1"
    local resource="$2"
    local error="${3:-unknown error}"
    local context="${4:-}"

    audit_log "$action" "$resource" "failed" "$error" "$context"
}

# Log denied operation (permission/policy violation)
# Convenience wrapper for audit_log with result="denied"
audit_deny() {
    local action="$1"
    local resource="$2"
    local reason="${3:-access denied}"
    local context="${4:-}"

    audit_log "$action" "$resource" "denied" "$reason" "$context"
}

# Query audit log
# Args:
#   $1 - filter type (user|action|resource|result|date)
#   $2 - filter value
audit_query() {
    local filter_type="$1"
    local filter_value="$2"

    if [ ! -f "$AUDIT_LOG_FILE" ]; then
        echo "Audit log not found: $AUDIT_LOG_FILE" >&2
        return 1
    fi

    if [ ! -r "$AUDIT_LOG_FILE" ]; then
        echo "Audit log not readable: $AUDIT_LOG_FILE" >&2
        return 1
    fi

    case "$filter_type" in
        user)
            grep "user=$filter_value" "$AUDIT_LOG_FILE"
            ;;
        action)
            grep "action=$filter_value" "$AUDIT_LOG_FILE"
            ;;
        resource)
            grep "resource=\"$filter_value\"" "$AUDIT_LOG_FILE"
            ;;
        result)
            grep "result=$filter_value" "$AUDIT_LOG_FILE"
            ;;
        date)
            grep "^\[$filter_value" "$AUDIT_LOG_FILE"
            ;;
        *)
            echo "Unknown filter type: $filter_type" >&2
            echo "Valid types: user, action, resource, result, date" >&2
            return 1
            ;;
    esac
}

# Get recent audit events
# Args:
#   $1 - number of events (default: 10)
audit_recent() {
    local count="${1:-10}"

    if [ ! -f "$AUDIT_LOG_FILE" ]; then
        echo "Audit log not found: $AUDIT_LOG_FILE" >&2
        return 1
    fi

    tail -n "$count" "$AUDIT_LOG_FILE"
}

# Get audit statistics
audit_stats() {
    if [ ! -f "$AUDIT_LOG_FILE" ]; then
        echo "Audit log not found: $AUDIT_LOG_FILE" >&2
        return 1
    fi

    if [ ! -r "$AUDIT_LOG_FILE" ]; then
        echo "Audit log not readable: $AUDIT_LOG_FILE" >&2
        return 1
    fi

    echo "=== VirtOS Audit Log Statistics ==="
    echo "Log file: $AUDIT_LOG_FILE"
    echo "Total entries: $(wc -l <"$AUDIT_LOG_FILE")"
    echo ""

    echo "Events by result:"
    grep -o 'result=[^ ]*' "$AUDIT_LOG_FILE" | sort | uniq -c | sort -rn
    echo ""

    echo "Events by action:"
    grep -o 'action=[^ ]*' "$AUDIT_LOG_FILE" | sort | uniq -c | sort -rn | head -10
    echo ""

    echo "Events by user:"
    grep -o 'user=[^ ]*' "$AUDIT_LOG_FILE" | sort | uniq -c | sort -rn | head -10
    echo ""

    echo "Recent errors:"
    grep 'result=failed' "$AUDIT_LOG_FILE" | tail -5
}

# Initialize audit log on library load
audit_init

# Export functions (if running in bash)
if [ -n "$BASH_VERSION" ]; then
    export -f audit_log 2>/dev/null || true
    export -f audit_success 2>/dev/null || true
    export -f audit_fail 2>/dev/null || true
    export -f audit_deny 2>/dev/null || true
    export -f audit_query 2>/dev/null || true
    export -f audit_recent 2>/dev/null || true
    export -f audit_stats 2>/dev/null || true
fi
