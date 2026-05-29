#!/bin/bash
# Automated code review script for VirtOS
# Shell scripts: shellcheck, security patterns, TODO checks
# Python: mypy, flake8, bandit, security scans, TODO checks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REVIEW_OUTPUT_DIR="$PROJECT_ROOT/.claude/review-output"

mkdir -p "$REVIEW_OUTPUT_DIR"

echo "========================================="
echo "Starting Code Review - $(date)"
echo "========================================="

cd "$PROJECT_ROOT"

# Clean previous review outputs
rm -f "$REVIEW_OUTPUT_DIR"/*.txt

# Count files
PYTHON_COUNT=$(find . -name "*.py" -type f ! -path "./.git/*" ! -path "./.claude/*" | wc -l)
SHELL_COUNT=$(find . -type f \( -name "*.sh" -o -name "*.bash" \) ! -path "./.git/*" ! -path "./.claude/*" | wc -l)

echo "Found $PYTHON_COUNT Python files, $SHELL_COUNT shell scripts"
echo ""

# Python checks (if Python files exist)
if [ $PYTHON_COUNT -gt 0 ]; then
    echo "=== Python Code Checks ==="

    # 1. MyPy (type checking)
    echo "[1/3] Running mypy..."
    if find . -name "*.py" -type f ! -path "./.git/*" ! -path "./.claude/*" -print0 | xargs -0 mypy --ignore-missing-imports --no-error-summary 2>&1 | tee "$REVIEW_OUTPUT_DIR/mypy.txt"; then
        echo "✓ MyPy: PASSED"
    else
        echo "✗ MyPy: FOUND ISSUES"
    fi

    # 2. Flake8 (style and quality)
    echo "[2/3] Running flake8..."
    if find . -name "*.py" -type f ! -path "./.git/*" ! -path "./.claude/*" -print0 | xargs -0 flake8 --extend-ignore=E501 2>&1 | tee "$REVIEW_OUTPUT_DIR/flake8.txt"; then
        echo "✓ Flake8: PASSED"
    else
        echo "✗ Flake8: FOUND ISSUES"
    fi

    # 3. Bandit (security)
    echo "[3/3] Running bandit..."
    if find . -name "*.py" -type f ! -path "./.git/*" ! -path "./.claude/scripts/*" -print0 | xargs -0 bandit -q --skip B404,B602,B603,B607 2>&1 | tee "$REVIEW_OUTPUT_DIR/bandit.txt"; then
        echo "✓ Bandit: PASSED"
    else
        echo "✗ Bandit: FOUND SECURITY ISSUES"
    fi
    echo ""
else
    echo "No Python files found, skipping Python checks"
    echo ""
fi

# Shell script checks
if [ $SHELL_COUNT -gt 0 ]; then
    echo "=== Shell Script Checks ==="

    # 1. ShellCheck (if available)
    if command -v shellcheck &>/dev/null; then
        echo "[1/2] Running shellcheck..."
        {
            find . -type f \( -name "*.sh" -o -name "*.bash" \) ! -path "./.git/*" ! -path "./.claude/*" -exec shellcheck -x {} \; 2>&1 || true
        } >"$REVIEW_OUTPUT_DIR/shellcheck.txt"

        SHELLCHECK_COUNT=$(wc -l <"$REVIEW_OUTPUT_DIR/shellcheck.txt" 2>/dev/null || echo "0")
        SHELLCHECK_COUNT=$(echo "$SHELLCHECK_COUNT" | tr -d ' \n')
        if [ "$SHELLCHECK_COUNT" -gt 0 ] 2>/dev/null; then
            echo "✗ Found $SHELLCHECK_COUNT shellcheck issues"
        else
            echo "✓ ShellCheck: PASSED"
        fi
    else
        echo "[1/2] ShellCheck not installed, skipping"
    fi

    # 2. Security patterns for shell scripts
    echo "[2/2] Running security pattern scan..."
    {
        echo "=== Shell Security Patterns ==="
        # Look for dangerous patterns (exclude .claude/ and documented usage)
        find . -type f \( -name "*.sh" -o -name "*.bash" \) ! -path "./.git/*" ! -path "./.claude/*" ! -path "./packages/*/build.sh" -exec grep -Hn "eval\|rm -rf /\|curl.*|.*sh\|wget.*|.*sh" {} \; 2>/dev/null | grep -v "# SECURITY NOTE" || true
    } >"$REVIEW_OUTPUT_DIR/shell-security-scans.txt"

    SHELL_SECURITY_COUNT=$(grep -c "\\.sh:" "$REVIEW_OUTPUT_DIR/shell-security-scans.txt" 2>/dev/null || echo "0")
    SHELL_SECURITY_COUNT=$(echo "$SHELL_SECURITY_COUNT" | tr -d ' \n')
    if [ "$SHELL_SECURITY_COUNT" -gt 0 ] 2>/dev/null; then
        echo "✗ Found $SHELL_SECURITY_COUNT security patterns in shell scripts"
    else
        echo "✓ Shell Security: PASSED"
    fi
    echo ""
else
    echo "No shell scripts found, skipping shell checks"
    echo ""
fi

# Python security scans (if exists)
if [ $PYTHON_COUNT -gt 0 ]; then
    echo "=== Python Security Pattern Scan ==="
    {
        echo "=== Python Security Patterns ==="
        find . -type f -name "*.py" ! -path "./.git/*" ! -path "./.claude/*" -exec grep -Hn "eval\|exec\|__import__\|pickle.loads\|yaml.load[^s]\|subprocess.call\|os.system" {} \; 2>/dev/null || true
    } >"$REVIEW_OUTPUT_DIR/python-security-scans.txt"

    PY_SECURITY_COUNT=$(grep -c ".py:" "$REVIEW_OUTPUT_DIR/python-security-scans.txt" 2>/dev/null || echo "0")
    PY_SECURITY_COUNT=$(echo "$PY_SECURITY_COUNT" | tr -d ' \n')
    if [ "$PY_SECURITY_COUNT" -gt 0 ] 2>/dev/null; then
        echo "✗ Found $PY_SECURITY_COUNT security patterns in Python code"
    else
        echo "✓ Python Security Patterns: PASSED"
    fi
    echo ""
fi

# TODO/FIXME checks (all languages)
echo "=== TODO/FIXME Checks ==="
find . -type f \( -name "*.sh" -o -name "*.bash" -o -name "*.py" \) ! -path "./.git/*" ! -path "./.claude/*" -exec grep -Hn "TODO\|FIXME\|XXX\|HACK" {} \; 2>/dev/null | grep -v "# TODO\|# FIXME" | grep -v "code review\|pattern" || true >"$REVIEW_OUTPUT_DIR/todo-checks.txt"
TODO_COUNT=$(wc -l <"$REVIEW_OUTPUT_DIR/todo-checks.txt" || echo 0)
echo "Found $TODO_COUNT TODO/FIXME comments"

echo ""
echo "========================================="
echo "Code Review Complete - $(date)"
echo "========================================="
echo "Review outputs saved to: $REVIEW_OUTPUT_DIR"
echo ""

# Count total issues
TOTAL_ISSUES=0
for file in "$REVIEW_OUTPUT_DIR"/*.txt; do
    if [ -f "$file" ] && [ -s "$file" ]; then
        TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
    fi
done

echo "Files with findings: $TOTAL_ISSUES"
exit 0
