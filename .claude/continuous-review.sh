#!/bin/bash
# VirtOS Continuous Code Review System
# Multi-language: Shell, Python, Java
# Runs automated checks, creates issues, auto-fixes, and pushes

set -e

REVIEW_LOG="/tmp/virtos-continuous-review-$(date +%Y%m%d-%H%M%S).log"
ISSUES_CREATED=0
FIXES_APPLIED=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$REPO_ROOT"

# Load deduplication library
# shellcheck source=.claude/scripts/issue_deduplication.sh
source "$REPO_ROOT/.claude/scripts/issue_deduplication.sh"
ISSUES_SKIPPED=0

echo "=== VirtOS Continuous Code Review ===" | tee -a "$REVIEW_LOG"
echo "Started: $(date)" | tee -a "$REVIEW_LOG"
echo "" | tee -a "$REVIEW_LOG"

# Function to create GitHub issue with deduplication
create_issue() {
    local title="$1"
    local body="$2"

    # Check for duplicate
    if is_duplicate_issue "$title" "$body"; then
        echo "⏭️  SKIPPED (duplicate): $title" | tee -a "$REVIEW_LOG"
        ISSUES_SKIPPED=$((ISSUES_SKIPPED + 1))
        return 0
    fi

    echo "Creating issue: $title" | tee -a "$REVIEW_LOG"

    # Write body to temp file to avoid "argument list too long"
    local body_file
    body_file=$(mktemp)
    echo "$body" >"$body_file"

    local issue_url
    if issue_url=$(gh issue create --title "$title" --body-file "$body_file" 2>&1); then
        echo "$issue_url" | tee -a "$REVIEW_LOG"
        rm -f "$body_file"

        # Extract issue number from URL (only match the last line containing the URL)
        local issue_number
        issue_number=$(echo "$issue_url" | grep -oE "/issues/[0-9]+$" | tail -1 | grep -oE "[0-9]+$")

        if [ -n "$issue_number" ]; then
            # Record hash to prevent future duplicates (finalizes the reservation)
            record_issue_hash "$title" "$body" "$issue_number"
            ISSUES_CREATED=$((ISSUES_CREATED + 1))
            echo "✅ Issue #$issue_number created and recorded" | tee -a "$REVIEW_LOG"
        else
            # Could not extract number - release reservation since we cannot track
            release_issue_reservation "$title" "$body"
            ISSUES_CREATED=$((ISSUES_CREATED + 1))
            echo "✅ Issue created successfully (could not extract number)" | tee -a "$REVIEW_LOG"
        fi
        return 0
    else
        echo "$issue_url" | tee -a "$REVIEW_LOG"
        rm -f "$body_file"
        # Release the reservation so future attempts can retry
        release_issue_reservation "$title" "$body"
        echo "❌ Failed to create issue" | tee -a "$REVIEW_LOG"
        return 1
    fi
}

# Function to commit and push changes
auto_commit_push() {
    local message="$1"
    local files="$2"
    local current_branch

    if [ -n "$(git status --porcelain)" ]; then
        echo "Committing changes: $message" | tee -a "$REVIEW_LOG"

        # Add files safely: expand glob patterns properly
        # shellcheck disable=SC2086
        git add $files 2>&1 | tee -a "$REVIEW_LOG" || {
            echo "❌ Error: Failed to stage files matching pattern: $files" | tee -a "$REVIEW_LOG"
            return 1
        }

        git commit -m "$message

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>" 2>&1 | tee -a "$REVIEW_LOG"

        # Verify we're on main branch before pushing
        current_branch=$(git rev-parse --abbrev-ref HEAD)
        if [ "$current_branch" != "main" ]; then
            echo "❌ Error: Not on main branch (currently on: $current_branch)" | tee -a "$REVIEW_LOG"
            echo "⚠️  Changes committed locally but NOT pushed to protect main branch" | tee -a "$REVIEW_LOG"
            return 1
        fi

        echo "Pushing to remote..." | tee -a "$REVIEW_LOG"
        git push origin main 2>&1 | tee -a "$REVIEW_LOG" || {
            echo "❌ Error: Failed to push to origin main" | tee -a "$REVIEW_LOG"
            return 1
        }
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
        return 0
    else
        echo "No changes to commit" | tee -a "$REVIEW_LOG"
        return 1
    fi
}

# =============================================================================
# PYTHON CHECKS
# =============================================================================
echo "=== Python Code Review ===" | tee -a "$REVIEW_LOG"

# Find all Python files
PYTHON_FILES=$(find . -name "*.py" ! -path "./.git/*" ! -path "./build/*" ! -path "./.venv/*" ! -path "./venv/*" 2>/dev/null || true)

if [ -n "$PYTHON_FILES" ]; then
    echo "Found Python files, running checks..." | tee -a "$REVIEW_LOG"

    # 1. mypy - Type checking
    if command -v mypy >/dev/null 2>&1; then
        echo "Running mypy..." | tee -a "$REVIEW_LOG"
        MYPY_ISSUES=""
        for file in $PYTHON_FILES; do
            if ! mypy_output=$(mypy "$file" 2>&1); then
                MYPY_ISSUES="${MYPY_ISSUES}\n**File**: \`$file\`\n\`\`\`\n$mypy_output\n\`\`\`\n"
            fi
        done

        if [ -n "$MYPY_ISSUES" ]; then
            create_issue "[Python] mypy type checking issues" "## Type Checking Issues

$MYPY_ISSUES

**Priority**: P2 (Medium)
**Auto-detected**: $(date)
**Tool**: mypy"
        fi
    else
        echo "⚠️  mypy not installed - skipping" | tee -a "$REVIEW_LOG"
    fi

    # 2. flake8 - Style and quality
    if command -v flake8 >/dev/null 2>&1; then
        echo "Running flake8..." | tee -a "$REVIEW_LOG"
        FLAKE8_ISSUES=""
        for file in $PYTHON_FILES; do
            if ! flake8_output=$(flake8 "$file" 2>&1); then
                FLAKE8_ISSUES="${FLAKE8_ISSUES}\n**File**: \`$file\`\n\`\`\`\n$flake8_output\n\`\`\`\n"
            fi
        done

        if [ -n "$FLAKE8_ISSUES" ]; then
            create_issue "[Python] flake8 style/quality issues" "## Code Quality Issues

$FLAKE8_ISSUES

**Priority**: P3 (Low)
**Auto-detected**: $(date)
**Tool**: flake8"
        fi
    else
        echo "⚠️  flake8 not installed - skipping" | tee -a "$REVIEW_LOG"
    fi

    # 3. bandit - Security scanning
    if command -v bandit >/dev/null 2>&1; then
        echo "Running bandit..." | tee -a "$REVIEW_LOG"
        BANDIT_ISSUES=""
        for file in $PYTHON_FILES; do
            if ! bandit_output=$(bandit -r "$file" 2>&1 | grep -v "No issues identified" || true); then
                if [ -n "$bandit_output" ]; then
                    BANDIT_ISSUES="${BANDIT_ISSUES}\n**File**: \`$file\`\n\`\`\`\n$bandit_output\n\`\`\`\n"
                fi
            fi
        done

        if [ -n "$BANDIT_ISSUES" ]; then
            create_issue "[Python Security] bandit security scan findings" "## Security Scan Results

$BANDIT_ISSUES

**Priority**: P1 (High) - Security
**Auto-detected**: $(date)
**Tool**: bandit"
        fi
    else
        echo "⚠️  bandit not installed - skipping" | tee -a "$REVIEW_LOG"
    fi

    # 4. TODO/FIXME in Python files
    echo "Scanning Python files for TODO/FIXME..." | tee -a "$REVIEW_LOG"
    PYTHON_TODOS=$(grep -rn "TODO\|FIXME\|XXX\|HACK" $PYTHON_FILES 2>/dev/null || true)
    if [ -n "$PYTHON_TODOS" ]; then
        create_issue "[Python] TODO/FIXME items found" "## Python Action Items

\`\`\`
$PYTHON_TODOS
\`\`\`

**Priority**: P3 (Low)
**Auto-detected**: $(date)"
    fi
else
    echo "No Python files found" | tee -a "$REVIEW_LOG"
fi

# =============================================================================
# JAVA CHECKS
# =============================================================================
echo "" | tee -a "$REVIEW_LOG"
echo "=== Java Code Review ===" | tee -a "$REVIEW_LOG"

# Find all Java files
JAVA_FILES=$(find . -name "*.java" ! -path "./.git/*" ! -path "./build/*" ! -path "./target/*" 2>/dev/null || true)

if [ -n "$JAVA_FILES" ]; then
    echo "Found Java files, running checks..." | tee -a "$REVIEW_LOG"

    # 1. Security patterns in Java
    echo "Scanning Java for security issues..." | tee -a "$REVIEW_LOG"
    JAVA_SECURITY=""

    # Common Java security anti-patterns
    SECURITY_PATTERNS=(
        "Runtime\.exec"
        "ProcessBuilder"
        "\.setAccessible\(true\)"
        "new\s+File\s*\([^)]*\+[^)]*\)" # String concatenation in File paths
        "Statement\.execute[^d]"        # Non-prepared statements
        "password\s*=\s*[\"'][^\"']+[\"']"
    )

    for pattern in "${SECURITY_PATTERNS[@]}"; do
        if findings=$(grep -rn -E "$pattern" $JAVA_FILES 2>/dev/null || true); then
            if [ -n "$findings" ]; then
                JAVA_SECURITY="${JAVA_SECURITY}\n**Pattern**: \`$pattern\`\n\`\`\`\n$findings\n\`\`\`\n"
            fi
        fi
    done

    if [ -n "$JAVA_SECURITY" ]; then
        create_issue "[Java Security] Potential security issues detected" "## Security Scan Results

$JAVA_SECURITY

**Priority**: P1 (High) - Security
**Auto-detected**: $(date)"
    fi

    # 2. TODO/FIXME in Java files
    echo "Scanning Java files for TODO/FIXME..." | tee -a "$REVIEW_LOG"
    JAVA_TODOS=$(grep -rn "TODO\|FIXME\|XXX\|HACK" "$JAVA_FILES" 2>/dev/null || true 2>/dev/null || true)
    if [ -n "$JAVA_TODOS" ]; then
        create_issue "[Java] TODO/FIXME items found" "## Java Action Items

\`\`\`
$JAVA_TODOS
\`\`\`

**Priority**: P3 (Low)
**Auto-detected**: $(date)"
    fi
else
    echo "No Java files found" | tee -a "$REVIEW_LOG"
fi

# =============================================================================
# SHELL SCRIPT CHECKS (Enhanced from existing)
# =============================================================================
echo "" | tee -a "$REVIEW_LOG"
echo "=== Shell Script Review ===" | tee -a "$REVIEW_LOG"

# Run the existing automated-review.sh for shell scripts
if [ -f "$REPO_ROOT/.claude/automated-review.sh" ]; then
    echo "Running existing shell script review..." | tee -a "$REVIEW_LOG"
    "$REPO_ROOT/.claude/automated-review.sh" 2>&1 | tee -a "$REVIEW_LOG" || true
else
    echo "⚠️  Shell script review not found" | tee -a "$REVIEW_LOG"
fi

# =============================================================================
# AUTO-FIX SAFE ISSUES
# =============================================================================
echo "" | tee -a "$REVIEW_LOG"
echo "=== Auto-Fix Safe Issues ===" | tee -a "$REVIEW_LOG"

# Example: Auto-fix Python formatting with black (if available)
if command -v black >/dev/null 2>&1 && [ -n "$PYTHON_FILES" ]; then
    echo "Auto-formatting Python files with black..." | tee -a "$REVIEW_LOG"
    for file in $PYTHON_FILES; do
        black "$file" 2>&1 | tee -a "$REVIEW_LOG" || true
    done

    if [ -n "$(git status --porcelain -- '*.py')" ]; then
        auto_commit_push "style: auto-format Python files with black" "*.py"
    fi
fi

# Example: Auto-fix Python imports with isort (if available)
if command -v isort >/dev/null 2>&1 && [ -n "$PYTHON_FILES" ]; then
    echo "Auto-sorting Python imports with isort..." | tee -a "$REVIEW_LOG"
    for file in $PYTHON_FILES; do
        isort "$file" 2>&1 | tee -a "$REVIEW_LOG" || true
    done

    if [ -n "$(git status --porcelain -- '*.py')" ]; then
        auto_commit_push "style: auto-sort Python imports with isort" "*.py"
    fi
fi

# =============================================================================
# SUMMARY
# =============================================================================
echo "" | tee -a "$REVIEW_LOG"
echo "=== Review Summary ===" | tee -a "$REVIEW_LOG"
echo "Completed: $(date)" | tee -a "$REVIEW_LOG"
echo "Issues created: $ISSUES_CREATED" | tee -a "$REVIEW_LOG"
echo "Auto-fixes applied: $FIXES_APPLIED" | tee -a "$REVIEW_LOG"
echo "Review log: $REVIEW_LOG" | tee -a "$REVIEW_LOG"

# Exit code determines if review should continue
if [ "$ISSUES_CREATED" -gt 0 ] || [ "$FIXES_APPLIED" -gt 0 ]; then
    echo "" | tee -a "$REVIEW_LOG"
    echo "⚡ Review found issues or applied fixes - will continue" | tee -a "$REVIEW_LOG"
    exit 1
else
    echo "" | tee -a "$REVIEW_LOG"
    echo "✅ Review passed - No new issues or fixes - STOPPING" | tee -a "$REVIEW_LOG"
    exit 0
fi
