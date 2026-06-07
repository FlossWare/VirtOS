#!/bin/bash
# Issue Deduplication Library
# Prevents duplicate GitHub issues by content-based hashing
#
# Uses atomic lock-based reservation to prevent TOCTOU race conditions.
# Protocol: is_duplicate_issue() atomically checks AND reserves the hash.
#           record_issue_hash() finalizes the reservation after issue creation.
#           release_issue_reservation() cleans up if issue creation fails.
#
# Stale locks older than LOCK_TIMEOUT_SECONDS are automatically cleaned up
# to handle crashed processes.

set -euo pipefail

# Directory to store issue hashes
# Default to XDG_RUNTIME_DIR or system temp directory to avoid hardcoded paths
# This allows the script to work on any machine/repo configuration
#
# Priority:
#   1. HASH_DIR environment variable (explicit override)
#   2. XDG_RUNTIME_DIR/issue-dedup (Linux standard temp, per-user)
#   3. TMPDIR/issue-dedup (POSIX standard fallback)
#   4. /tmp/issue-dedup (final fallback - should not reach here on normal systems)
#
# Important: We use a repo-agnostic path to prevent cross-repo corruption
# if multiple related repos exist on the same machine.
if [ -z "${HASH_DIR:-}" ]; then
    # Try XDG_RUNTIME_DIR first (most secure, per-user runtime directory)
    if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -d "$XDG_RUNTIME_DIR" ]; then
        HASH_DIR="$XDG_RUNTIME_DIR/issue-dedup"
    # Fall back to TMPDIR if set and valid
    elif [ -n "${TMPDIR:-}" ] && [ -d "$TMPDIR" ]; then
        HASH_DIR="$TMPDIR/issue-dedup"
    # Final fallback to /tmp (should work on any POSIX system)
    else
        HASH_DIR="/tmp/issue-dedup"
    fi
fi

mkdir -p "$HASH_DIR"

# Lock timeout in seconds - locks older than this are considered stale
# Default: 300 seconds (5 minutes), enough for gh issue create to complete
LOCK_TIMEOUT_SECONDS="${LOCK_TIMEOUT_SECONDS:-300}"

# Generate content hash for an issue
# Args: $1=title, $2=body_excerpt (first 500 chars normalized)
generate_issue_hash() {
    local title="$1"
    local body_excerpt="$2"

    # Normalize content: lowercase, remove dates/timestamps, collapse whitespace
    # Apply consistent normalization to both title and body
    local normalized_title
    local normalized_body

    # Normalize title: lowercase -> remove dates -> remove times -> collapse whitespace -> trim
    normalized_title=$(printf '%s' "$title" | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}//g' | \
        sed 's/[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}//g' | \
        tr -s ' \n' ' ' | \
        sed 's/^ *//; s/ *$//')

    # Normalize body: lowercase -> remove dates -> remove times -> collapse whitespace -> trim
    normalized_body=$(printf '%s' "$body_excerpt" | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}//g' | \
        sed 's/[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}//g' | \
        tr -s ' \n' ' ' | \
        sed 's/^ *//; s/ *$//')

    # Generate SHA256 hash using printf to avoid platform-specific newline issues
    printf '%s' "${normalized_title}::${normalized_body}" | sha256sum | awk '{print $1}'
}

# Internal: compute hash file path from title and body
# Args: $1=title, $2=body
# Outputs: hash_file path to stdout
_compute_hash_file() {
    local title="$1"
    local body="$2"

    # Extract first 500 chars of body for hash (enough to identify unique content)
    # Use printf to avoid echo adding platform-specific trailing newlines
    local body_excerpt
    body_excerpt=$(printf '%s' "$body" | head -c 500)

    local content_hash
    content_hash=$(generate_issue_hash "$title" "$body_excerpt")

    printf '%s' "$HASH_DIR/${content_hash}.txt"
}

# Internal: clean up a stale lock if the owning process is no longer running
# Args: $1=lock_dir path
# Returns: 0 if lock was stale and cleaned, 1 if lock is still valid
_cleanup_stale_lock() {
    local lock_dir="$1"
    local pid_file="$lock_dir/pid"

    # Check if the lock directory exists
    if [ ! -d "$lock_dir" ]; then
        return 0
    fi

    # Check lock age using the pid file modification time
    if [ -f "$pid_file" ]; then
        local lock_age
        lock_age=$(( $(date +%s) - $(stat -c %Y "$pid_file" 2>/dev/null || echo "0") ))

        if [ "$lock_age" -gt "$LOCK_TIMEOUT_SECONDS" ]; then
            echo "WARNING: Cleaning up stale lock (age: ${lock_age}s, timeout: ${LOCK_TIMEOUT_SECONDS}s): $lock_dir" >&2
            rm -rf "$lock_dir"
            return 0
        fi

        # Check if the process that holds the lock is still running
        local lock_pid
        lock_pid=$(cat "$pid_file" 2>/dev/null || echo "")
        if [ -n "$lock_pid" ] && ! kill -0 "$lock_pid" 2>/dev/null; then
            echo "WARNING: Cleaning up orphaned lock (pid $lock_pid no longer running): $lock_dir" >&2
            rm -rf "$lock_dir"
            return 0
        fi
    else
        # No pid file in lock dir - corrupted lock, clean it up
        echo "WARNING: Cleaning up corrupted lock (no pid file): $lock_dir" >&2
        rm -rf "$lock_dir"
        return 0
    fi

    return 1  # Lock is still valid
}

# Check if an issue with this content already exists, and atomically reserve
# the hash if it does not exist yet.
#
# This function prevents TOCTOU race conditions by using mkdir as an atomic
# lock primitive. If the hash is not a duplicate, a lock directory is created
# that prevents concurrent processes from also passing the duplicate check.
#
# The caller MUST call either record_issue_hash() (on success) or
# release_issue_reservation() (on failure) after this function returns 1.
#
# Args: $1=title, $2=body
# Returns: 0 if duplicate (do NOT create issue), 1 if not duplicate (proceed)
is_duplicate_issue() {
    local title="$1"
    local body="$2"

    local hash_file
    hash_file=$(_compute_hash_file "$title" "$body")
    local lock_dir="${hash_file}.lock"

    # Phase 1: Check if the hash file already exists (fast path for known duplicates)
    if [ -f "$hash_file" ]; then
        local existing_issue
        existing_issue=$(cat "$hash_file")
        echo "DUPLICATE: Issue hash already exists: $existing_issue" >&2
        return 0
    fi

    # Phase 2: Try to atomically reserve this hash using mkdir
    # mkdir is atomic on all POSIX filesystems - it either succeeds or fails,
    # making it ideal for lock-free mutual exclusion
    if mkdir "$lock_dir" 2>/dev/null; then
        # We acquired the lock - write our PID for stale lock detection
        echo "$$" > "$lock_dir/pid"

        # Double-check: hash file could have been created between our check
        # and acquiring the lock
        if [ -f "$hash_file" ]; then
            # Another process completed between our check and lock acquisition
            rm -rf "$lock_dir"
            local existing_issue
            existing_issue=$(cat "$hash_file")
            echo "DUPLICATE: Issue hash already exists (late check): $existing_issue" >&2
            return 0
        fi

        # Reservation acquired - caller should proceed to create the issue
        # Lock remains in place until record_issue_hash() or release_issue_reservation()
        return 1
    fi

    # Phase 3: Lock already exists - another process is working on this hash
    # First, try to clean up stale locks from crashed processes
    if _cleanup_stale_lock "$lock_dir"; then
        # Stale lock was cleaned up - retry the reservation
        if mkdir "$lock_dir" 2>/dev/null; then
            echo "$$" > "$lock_dir/pid"

            if [ -f "$hash_file" ]; then
                rm -rf "$lock_dir"
                local existing_issue
                existing_issue=$(cat "$hash_file")
                echo "DUPLICATE: Issue hash already exists (after stale cleanup): $existing_issue" >&2
                return 0
            fi

            return 1  # Reservation acquired after stale cleanup
        fi
    fi

    # Another active process holds the lock - wait for it to complete
    local retry_count=0
    local max_retries=60  # 30 seconds max (500ms * 60)
    while [ $retry_count -lt $max_retries ]; do
        sleep 0.5

        # Check if the hash file appeared (other process completed successfully)
        if [ -f "$hash_file" ]; then
            local existing_issue
            existing_issue=$(cat "$hash_file")
            echo "DUPLICATE: Issue hash already exists (after wait): $existing_issue" >&2
            return 0
        fi

        # Check if the lock was released (other process failed)
        if [ ! -d "$lock_dir" ]; then
            # Lock gone, hash file not created - other process failed
            # Try to acquire the lock ourselves
            if mkdir "$lock_dir" 2>/dev/null; then
                echo "$$" > "$lock_dir/pid"
                return 1  # Reservation acquired after other process failed
            fi
        fi

        retry_count=$((retry_count + 1))
    done

    # Timeout waiting for other process - treat as duplicate to be safe
    # (better to skip a legitimate issue than create a duplicate)
    echo "DUPLICATE: Timed out waiting for lock, treating as duplicate to prevent races: $lock_dir" >&2
    return 0
}

# Record an issue hash after successful creation.
# This finalizes the reservation made by is_duplicate_issue() by writing the
# hash file and removing the lock directory.
#
# Args: $1=title, $2=body, $3=issue_number
record_issue_hash() {
    local title="$1"
    local body="$2"
    local issue_number="$3"

    local hash_file
    hash_file=$(_compute_hash_file "$title" "$body")
    local lock_dir="${hash_file}.lock"

    # Write to temp file first, then atomic rename to prevent partial reads
    local temp_file
    temp_file=$(mktemp "$HASH_DIR/.tmp.XXXXXX")

    echo "issue_number=$issue_number" >"$temp_file"
    echo "created_at=$(date -Iseconds)" >>"$temp_file"
    echo "title=$title" >>"$temp_file"

    # Atomic rename - on same filesystem this is guaranteed atomic
    mv "$temp_file" "$hash_file"

    # Remove the lock directory now that the hash file is in place
    rm -rf "$lock_dir"

    echo "Recorded issue hash: $(basename "$hash_file" .txt) -> #$issue_number" >&2
}

# Release a reservation without recording a hash.
# Call this if issue creation fails after is_duplicate_issue() returned 1.
# This allows other processes (or future retries) to attempt creating the issue.
#
# Args: $1=title, $2=body
release_issue_reservation() {
    local title="$1"
    local body="$2"

    local hash_file
    hash_file=$(_compute_hash_file "$title" "$body")
    local lock_dir="${hash_file}.lock"

    if [ -d "$lock_dir" ]; then
        rm -rf "$lock_dir"
        echo "Released issue reservation for: $(basename "$hash_file" .txt)" >&2
    fi
}

# Clean up old hashes (optional maintenance - remove hashes for closed issues)
# Also cleans up any stale lock directories.
# Args: none
clean_old_hashes() {
    echo "Cleaning up hashes for closed issues..." >&2

    # Clean up stale locks first
    local stale_cleaned=0
    for lock_dir in "$HASH_DIR"/*.lock; do
        [ -d "$lock_dir" ] || continue
        if _cleanup_stale_lock "$lock_dir"; then
            stale_cleaned=$((stale_cleaned + 1))
        fi
    done

    if [ "$stale_cleaned" -gt 0 ]; then
        echo "Cleaned up $stale_cleaned stale lock(s)" >&2
    fi

    # Get list of all open issue numbers
    local open_issues
    open_issues=$(gh issue list --limit 1000 --json number --jq '.[].number' 2>/dev/null || echo "")

    if [ -z "$open_issues" ]; then
        echo "Warning: Could not fetch open issues, skipping cleanup" >&2
        return 0
    fi

    # Check each hash file
    local cleaned=0
    for hash_file in "$HASH_DIR"/*.txt; do
        [ -f "$hash_file" ] || continue

        local issue_number
        issue_number=$(grep "^issue_number=" "$hash_file" | cut -d= -f2)

        # If issue is not in open list, remove hash
        if ! echo "$open_issues" | grep -q "^${issue_number}$"; then
            echo "Removing hash for closed issue #$issue_number" >&2
            rm -f "$hash_file"
            cleaned=$((cleaned + 1))
        fi
    done

    echo "Cleaned up $cleaned hash files for closed issues" >&2
}

# Get statistics about stored hashes
hash_stats() {
    local total_hashes
    total_hashes=$(find "$HASH_DIR" -name "*.txt" -type f 2>/dev/null | wc -l)

    local total_locks
    total_locks=$(find "$HASH_DIR" -name "*.lock" -type d 2>/dev/null | wc -l)

    echo "Issue Deduplication Statistics:"
    echo "  Hash directory: $HASH_DIR"
    echo "  Total hashes stored: $total_hashes"
    echo "  Active locks: $total_locks"
    echo "  Disk usage: $(du -sh "$HASH_DIR" 2>/dev/null | awk '{print $1}')"
}

# Export functions for use in other scripts
export -f generate_issue_hash
export -f is_duplicate_issue
export -f record_issue_hash
export -f release_issue_reservation
export -f clean_old_hashes
export -f hash_stats
export -f _compute_hash_file
export -f _cleanup_stale_lock
