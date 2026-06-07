#!/bin/bash
# Automated code review script for VirtOS
# Shell scripts: shellcheck, security patterns, action-item checks
# Python: mypy, flake8, bandit, security scans, action-item checks

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
PYTHON_COUNT=$(find . -name "*.py" -type f ! -path "./.git/*" ! -path "./.claude/*" 2>/dev/null | wc -l)
SHELL_COUNT=$(find . -type f \( -name "*.sh" -o -name "*.bash" \) ! -path "./.git/*" ! -path "./.claude/*" 2>/dev/null | wc -l)

echo "Found $PYTHON_COUNT Python files, $SHELL_COUNT shell scripts"
echo ""

# Python checks (if Python files exist)
if [ "$PYTHON_COUNT" -gt 0 ]; then
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
if [ "$SHELL_COUNT" -gt 0 ]; then
    echo "=== Shell Script Checks ==="

    # 1. ShellCheck (if available)
    if command -v shellcheck &>/dev/null; then
        echo "[1/2] Running shellcheck..."
        {
            find . -type f \( -name "*.sh" -o -name "*.bash" \) ! -path "./.git/*" ! -path "./.claude/*" -exec shellcheck -x {} \; 2>&1 || true
        } >"$REVIEW_OUTPUT_DIR/shellcheck.txt"

        SHELLCHECK_COUNT=$(wc -l <"$REVIEW_OUTPUT_DIR/shellcheck.txt" 2>/dev/null | tr -d ' \n')
        if [ "${SHELLCHECK_COUNT:-0}" -gt 0 ]; then
            echo "✗ Found $SHELLCHECK_COUNT shellcheck issues"
        else
            echo "✓ ShellCheck: PASSED"
        fi
    else
        echo "[1/2] ShellCheck not installed, skipping"
    fi

    # 2. Security patterns for shell scripts - FIXED to avoid false positives
    echo "[2/2] Running security pattern scan..."
    {
        echo "=== Shell Security Patterns ==="
        # Look for dangerous patterns using word boundaries and excluding comments
        # \beval\b = word-boundary eval (not "retrieval")
        # Filter out comment-only lines
        find . -type f \( -name "*.sh" -o -name "*.bash" \) \
            ! -path "./.git/*" ! -path "./.claude/*" ! -path "./packages/*/build.sh" \
            -exec grep -Hn -E '\beval\b|rm\s+-rf\s+/|curl[^|]*\|[^|]*sh|wget[^|]*\|[^|]*sh' {} \; 2>/dev/null \
            | grep -v '^\s*#' \
            | grep -v 'retrieval' \
            | grep -v 'SECURITY NOTE' \
            || true
    } >"$REVIEW_OUTPUT_DIR/shell-security-scans.txt"

    SHELL_SECURITY_COUNT=$(grep -c "\.sh:" "$REVIEW_OUTPUT_DIR/shell-security-scans.txt" 2>/dev/null | tr -d ' \n')
    if [ "${SHELL_SECURITY_COUNT:-0}" -gt 0 ]; then
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
if [ "$PYTHON_COUNT" -gt 0 ]; then
    echo "=== Python Security Pattern Scan ==="
    {
        echo "=== Python Security Patterns ==="
        find . -type f -name "*.py" ! -path "./.git/*" ! -path "./.claude/*" -exec grep -Hn "eval\|exec\|__import__\|pickle.loads\|yaml.load[^s]\|subprocess.call\|os.system" {} \; 2>/dev/null || true
    } >"$REVIEW_OUTPUT_DIR/python-security-scans.txt"

    PY_SECURITY_COUNT=$(grep -c ".py:" "$REVIEW_OUTPUT_DIR/python-security-scans.txt" 2>/dev/null | tr -d ' \n')
    if [ "${PY_SECURITY_COUNT:-0}" -gt 0 ]; then
        echo "✗ Found $PY_SECURITY_COUNT security patterns in Python code"
    else
        echo "✓ Python Security Patterns: PASSED"
    fi
    echo ""
fi

# Action-item checks (all languages)
echo "=== Action Item Checks ==="
{
    find . -type f \( -name "*.sh" -o -name "*.bash" -o -name "*.py" \) \
        ! -path "./.git/*" ! -path "./.claude/*" \
        -exec grep -Hn -E "\bTODO\b|\bFIXME\b|\bXXX\b|\bHACK\b" {} \; 2>/dev/null \
        | grep -v "^\s*#.*TODO\|^\s*#.*FIXME" \
        | grep -v '""".*TODO\|""".*FIXME' \
        | grep -v "'''" \
        | grep -v "create_review_issues\|code review\|pattern\|action item" \
        || true
} >"$REVIEW_OUTPUT_DIR/action-item-checks.txt"

ACTION_ITEM_COUNT=$(wc -l <"$REVIEW_OUTPUT_DIR/action-item-checks.txt" 2>/dev/null | tr -d ' \n')
echo "Found ${ACTION_ITEM_COUNT:-0} action item comments"

# Critical vulnerability checks
echo "=== Critical Vulnerability Scans ==="

# 1. Unbounded resource usage (issue #574)
echo "[1/5] Checking for unbounded loops and resource usage..."
{
    echo "=== Unbounded Resource Usage Patterns ==="
    # Check for infinite loops without safeguards
    find . -type f \( -name "*.js" -o -name "*.py" -o -name "*.sh" \) \
        ! -path "./.git/*" ! -path "./.claude/*" ! -path "./node_modules/*" \
        -exec grep -Hn -E "maxRuns:\s*Infinity|while\s+true|for\s*\(\s*;\s*;\s*\)|stopOnNoWork:\s*false" {} \; 2>/dev/null \
        || true
} >"$REVIEW_OUTPUT_DIR/unbounded-resources.txt"

UNBOUNDED_COUNT=$(grep -c ":" "$REVIEW_OUTPUT_DIR/unbounded-resources.txt" 2>/dev/null | tr -d ' \n')
if [ "${UNBOUNDED_COUNT:-0}" -gt 0 ]; then
    echo "✗ Found $UNBOUNDED_COUNT potential unbounded resource usage patterns"
else
    echo "✓ Unbounded Resources: PASSED"
fi

# 2. AI-only validation and auto-approval (issue #571)
echo "[2/5] Checking for AI-only validation patterns..."
{
    echo "=== AI-Only Validation Patterns ==="
    # Check for auto-approval without human review
    find . -type f \( -name "*.js" -o -name "*.py" -o -name "*.sh" \) \
        ! -path "./.git/*" ! -path "./.claude/*" ! -path "./node_modules/*" \
        -exec grep -Hn -E "auto.?approve|gh\s+pr\s+review.*--approve|\.approve\(\)|approve.*without.*review" {} \; 2>/dev/null \
        | grep -v "^\s*#\|^\s*//\|^\s*\*" \
        || true
} >"$REVIEW_OUTPUT_DIR/ai-only-validation.txt"

AI_VALIDATE_COUNT=$(grep -c ":" "$REVIEW_OUTPUT_DIR/ai-only-validation.txt" 2>/dev/null | tr -d ' \n')
if [ "${AI_VALIDATE_COUNT:-0}" -gt 0 ]; then
    echo "✗ Found $AI_VALIDATE_COUNT potential AI-only validation patterns"
else
    echo "✓ AI-Only Validation: PASSED"
fi

# 3. Cryptographic vulnerabilities (MD5 usage)
echo "[3/5] Checking for weak cryptographic functions..."
{
    echo "=== Weak Cryptography Patterns ==="
    # Check for MD5, SHA1, and other weak crypto
    find . -type f \( -name "*.js" -o -name "*.py" -o -name "*.sh" -o -name "*.yml" -o -name "*.yaml" \) \
        ! -path "./.git/*" ! -path "./.claude/*" ! -path "./node_modules/*" \
        -exec grep -Hn -E "\bmd5\b|\bmd5sum\b|\bsha1\b|hashlib\.md5|crypto\.createHash\('md5'\)" {} \; 2>/dev/null \
        | grep -v "^\s*#\|^\s*//\|^\s*\*\|comment\|description" \
        || true
} >"$REVIEW_OUTPUT_DIR/weak-crypto.txt"

WEAK_CRYPTO_COUNT=$(grep -c ":" "$REVIEW_OUTPUT_DIR/weak-crypto.txt" 2>/dev/null | tr -d ' \n')
if [ "${WEAK_CRYPTO_COUNT:-0}" -gt 0 ]; then
    echo "✗ Found $WEAK_CRYPTO_COUNT weak cryptography patterns (MD5/SHA1)"
else
    echo "✓ Weak Cryptography: PASSED"
fi

# 4. Command injection vulnerabilities
echo "[4/5] Checking for command injection vulnerabilities..."
{
    echo "=== Command Injection Patterns ==="
    # Check for unsafe command execution
    find . -type f \( -name "*.js" -o -name "*.py" -o -name "*.sh" \) \
        ! -path "./.git/*" ! -path "./.claude/*" ! -path "./node_modules/*" \
        -exec grep -Hn -E "child_process\.exec\(|os\.system\(|subprocess\.call\(.*shell=True|eval\s*\(.*input\|eval\s*\(.*argv" {} \; 2>/dev/null \
        | grep -v "^\s*#\|^\s*//\|^\s*\*" \
        || true
} >"$REVIEW_OUTPUT_DIR/command-injection.txt"

CMD_INJECT_COUNT=$(grep -c ":" "$REVIEW_OUTPUT_DIR/command-injection.txt" 2>/dev/null | tr -d ' \n')
if [ "${CMD_INJECT_COUNT:-0}" -gt 0 ]; then
    echo "✗ Found $CMD_INJECT_COUNT potential command injection vulnerabilities"
else
    echo "✓ Command Injection: PASSED"
fi

# 5. Path traversal vulnerabilities
echo "[5/5] Checking for path traversal vulnerabilities..."
{
    echo "=== Path Traversal Patterns ==="
    # Check for unsafe path operations
    find . -type f \( -name "*.js" -o -name "*.py" -o -name "*.sh" \) \
        ! -path "./.git/*" ! -path "./.claude/*" ! -path "./node_modules/*" \
        -exec grep -Hn -E "\.\.\/|path\.join\(.*\.\.|os\.path\.join\(.*\.\.|fs\.readFile\(.*\+\s*\w+|open\(.*\+\s*\w+" {} \; 2>/dev/null \
        | grep -v "^\s*#\|^\s*//\|^\s*\*\|cd\s+\.\." \
        || true
} >"$REVIEW_OUTPUT_DIR/path-traversal.txt"

PATH_TRAV_COUNT=$(grep -c ":" "$REVIEW_OUTPUT_DIR/path-traversal.txt" 2>/dev/null | tr -d ' \n')
if [ "${PATH_TRAV_COUNT:-0}" -gt 0 ]; then
    echo "✗ Found $PATH_TRAV_COUNT potential path traversal vulnerabilities"
else
    echo "✓ Path Traversal: PASSED"
fi

echo ""

echo ""
echo "========================================="
echo "Code Review Complete - $(date)"
echo "========================================="
echo "Review outputs saved to: $REVIEW_OUTPUT_DIR"
echo ""

# Count total issues
TOTAL_ISSUES=0
CRITICAL_ISSUES=0
for file in "$REVIEW_OUTPUT_DIR"/*.txt; do
    if [ -f "$file" ] && [ -s "$file" ]; then
        TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
        # Count critical issues
        case "$file" in
            *unbounded-resources*|*ai-only-validation*|*weak-crypto*|*command-injection*|*path-traversal*)
                CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
                ;;
        esac
    fi
done

echo "Files with findings: $TOTAL_ISSUES"
echo "Critical security findings: $CRITICAL_ISSUES"

# Exit with error code if critical issues found
if [ "$CRITICAL_ISSUES" -gt 0 ]; then
    echo ""
    echo "⚠️  CRITICAL SECURITY ISSUES DETECTED!"
    echo "Review the following files for details:"
    for file in "$REVIEW_OUTPUT_DIR"/unbounded-resources.txt \
                "$REVIEW_OUTPUT_DIR"/ai-only-validation.txt \
                "$REVIEW_OUTPUT_DIR"/weak-crypto.txt \
                "$REVIEW_OUTPUT_DIR"/command-injection.txt \
                "$REVIEW_OUTPUT_DIR"/path-traversal.txt; do
        if [ -f "$file" ] && [ -s "$file" ]; then
            echo "  - $file"
        fi
    done
    echo ""
    exit 1
fi

exit 0
