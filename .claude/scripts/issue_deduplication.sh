#!/bin/bash
# Issue Deduplication Library
# Prevents duplicate GitHub issues by content-based hashing

set -euo pipefail

# Directory to store issue hashes
HASH_DIR="${HASH_DIR:-/home/sfloess/Development/github/FlossWare/VirtOS/.claude/issue-hashes}"
mkdir -p "$HASH_DIR"

# Generate content hash for an issue
# Args: $1=title, $2=body_excerpt (first 500 chars normalized)
generate_issue_hash() {
    local title="$1"
    local body_excerpt="$2"

    # Normalize content: lowercase, remove dates/timestamps, remove whitespace variations
    local normalized_title
    local normalized_body

    normalized_title=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}//g' | sed 's/[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}//g')
    normalized_body=$(echo "$body_excerpt" | tr '[:upper:]' '[:lower:]' | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}//g' | sed 's/[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}//g' | tr -s ' \n' ' ')

    # Generate SHA256 hash
    echo -n "${normalized_title}::${normalized_body}" | sha256sum | awk '{print $1}'
}

# Check if an issue with this content already exists
# Args: $1=title, $2=body
is_duplicate_issue() {
    local title="$1"
    local body="$2"

    # Extract first 500 chars of body for hash (enough to identify unique content)
    local body_excerpt
    body_excerpt=$(echo "$body" | head -c 500)

    # Generate hash
    local content_hash
    content_hash=$(generate_issue_hash "$title" "$body_excerpt")

    # Check if hash file exists
    local hash_file="$HASH_DIR/${content_hash}.txt"
    if [ -f "$hash_file" ]; then
        local existing_issue
        existing_issue=$(cat "$hash_file")
        echo "DUPLICATE: Issue hash already exists: $existing_issue" >&2
        return 0 # Is duplicate
    fi

    return 1 # Not duplicate
}

# Record an issue hash after creation
# Args: $1=title, $2=body, $3=issue_number
record_issue_hash() {
    local title="$1"
    local body="$2"
    local issue_number="$3"

    # Extract first 500 chars of body
    local body_excerpt
    body_excerpt=$(echo "$body" | head -c 500)

    # Generate hash
    local content_hash
    content_hash=$(generate_issue_hash "$title" "$body_excerpt")

    # Record hash with issue number and timestamp
    local hash_file="$HASH_DIR/${content_hash}.txt"
    echo "issue_number=$issue_number" >"$hash_file"
    echo "created_at=$(date -Iseconds)" >>"$hash_file"
    echo "title=$title" >>"$hash_file"

    echo "Recorded issue hash: $content_hash -> #$issue_number" >&2
}

# Clean up old hashes (optional maintenance - remove hashes for closed issues)
# Args: none
clean_old_hashes() {
    echo "Cleaning up hashes for closed issues..." >&2

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

    echo "Issue Deduplication Statistics:"
    echo "  Hash directory: $HASH_DIR"
    echo "  Total hashes stored: $total_hashes"
    echo "  Disk usage: $(du -sh "$HASH_DIR" 2>/dev/null | awk '{print $1}')"
}

# Export functions for use in other scripts
export -f generate_issue_hash
export -f is_duplicate_issue
export -f record_issue_hash
export -f clean_old_hashes
export -f hash_stats
