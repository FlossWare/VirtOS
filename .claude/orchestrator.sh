#!/bin/bash
# VirtOS Continuous Multi-Model Review Orchestrator
# Manages the full review cycle with multi-model analysis

set -e

REPO_ROOT="/home/sfloess/Development/github/FlossWare/VirtOS"
ITERATION=0
MAX_ITERATIONS=100

cd "$REPO_ROOT"

echo "=== VirtOS Multi-Model Continuous Review Orchestrator ==="
echo "Started: $(date)"
echo ""

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))

    echo "========================================="
    echo "ITERATION $ITERATION - $(date)"
    echo "========================================="

    # Sync with remote
    echo "Fetching latest changes..."
    git fetch origin

    BEHIND=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "0")
    if [ "$BEHIND" -gt 0 ]; then
        echo "Rebasing $BEHIND commits..."
        git rebase origin/main || {
            echo "ERROR: Rebase failed"
            exit 1
        }
    fi

    # Run continuous review
    echo "Running continuous review..."
    if ./.claude/continuous-review.sh; then
        echo "✅ No issues found - waiting 10 minutes..."
        sleep 600
    else
        echo "⚡ Issues found - continuing immediately..."
        sleep 30
    fi
done

echo "Max iterations reached - stopping"
