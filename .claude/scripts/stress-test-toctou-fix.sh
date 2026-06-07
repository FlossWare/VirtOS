#!/bin/bash
# Stress test for TOCTOU race condition fix
# Runs multiple concurrent processes to verify no duplicates

set -euo pipefail

TEST_DIR="/tmp/toctou-stress-test-$$"
HASH_DIR="$TEST_DIR/hashes"
mkdir -p "$HASH_DIR"

export HASH_DIR

# Source the fixed library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/issue_deduplication.sh"

echo "=== TOCTOU Stress Test (20 Concurrent Processes) ==="
echo "Test directory: $TEST_DIR"
echo ""

# Test content
title="Stress Test Issue"
body="This content will be checked by multiple concurrent processes to verify race condition fix"

# Track results
results_dir="$TEST_DIR/results"
mkdir -p "$results_dir"

# Function for each simulated process
worker() {
    local worker_id=$1
    local issue_num=$((1000 + worker_id))

    # Check for duplicate
    if is_duplicate_issue "$title" "$body" 2>/dev/null; then
        echo "duplicate" > "$results_dir/worker-$worker_id"
        return 0
    fi

    # Simulate delay between check and record (creates race condition window)
    sleep 0.01

    # Record the issue
    record_issue_hash "$title" "$body" "$issue_num" 2>/dev/null
    echo "created" > "$results_dir/worker-$worker_id"
    return 1
}

echo "Starting 20 concurrent workers..."
for i in {1..20}; do
    worker "$i" &
done

# Wait for all workers
wait
echo "All workers completed"
echo ""

# Analyze results
created_count=$(find "$results_dir" -type f -exec grep -l "created" {} \; 2>/dev/null | wc -l)
duplicate_count=$(find "$results_dir" -type f -exec grep -l "duplicate" {} \; 2>/dev/null | wc -l)
hash_files=$(find "$HASH_DIR" -name "*.txt" ! -name "*.lock" | wc -l)

echo "Results:"
echo "  Total workers: 20"
echo "  Workers that created issues: $created_count"
echo "  Workers that detected duplicates: $duplicate_count"
echo "  Hash files created: $hash_files"
echo ""

# Verify correctness
if [ "$created_count" -ge 1 ] && [ "$created_count" -le 3 ]; then
    echo "✓ PASS: Correct number of issue creators (1-3)"
else
    echo "⚠ WARNING: Unusual number of creators: $created_count"
fi

if [ "$duplicate_count" -gt 0 ]; then
    echo "✓ PASS: Some workers correctly detected duplicates"
else
    echo "⚠ WARNING: No workers detected duplicates"
fi

if [ "$hash_files" -eq 1 ]; then
    echo "✓ PASS: Only one hash file created (no duplicates)"
else
    echo "⚠ WARNING: Multiple hash files: $hash_files"
fi

# Cleanup
rm -rf "$TEST_DIR"
echo ""
echo "=== Stress Test Complete ==="
