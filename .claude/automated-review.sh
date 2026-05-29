#!/bin/bash
# VirtOS Automated Code Review Script
# Runs shellcheck, security scans, TODO checks, and creates GitHub issues

set -e

REVIEW_LOG="/tmp/virtos-review-$(date +%Y%m%d-%H%M%S).log"
ISSUES_CREATED=0
REPO_ROOT="/home/sfloess/Development/github/FlossWare/VirtOS"

cd "$REPO_ROOT"

echo "=== VirtOS Automated Code Review ===" | tee -a "$REVIEW_LOG"
echo "Started: $(date)" | tee -a "$REVIEW_LOG"
echo "" | tee -a "$REVIEW_LOG"

# Function to create GitHub issue
create_issue() {
    local title="$1"
    local body="$2"

    echo "Creating issue: $title" | tee -a "$REVIEW_LOG"

    if gh issue create --title "$title" --body "$body" 2>&1 | tee -a "$REVIEW_LOG"; then
        ISSUES_CREATED=$((ISSUES_CREATED + 1))
        echo "✅ Issue created successfully" | tee -a "$REVIEW_LOG"
    else
        echo "❌ Failed to create issue" | tee -a "$REVIEW_LOG"
    fi
}

# 1. ShellCheck - Lint all shell scripts
echo "=== 1. Running ShellCheck ===" | tee -a "$REVIEW_LOG"
SHELLCHECK_ISSUES=""

if command -v shellcheck >/dev/null 2>&1; then
    # Find all shell scripts
    while IFS= read -r script; do
        if shellcheck_output=$(shellcheck -f gcc "$script" 2>&1); then
            echo "✅ $script - OK" | tee -a "$REVIEW_LOG"
        else
            echo "❌ $script - Issues found:" | tee -a "$REVIEW_LOG"
            echo "$shellcheck_output" | tee -a "$REVIEW_LOG"
            SHELLCHECK_ISSUES="${SHELLCHECK_ISSUES}\n\n**File**: \`$script\`\n\`\`\`\n$shellcheck_output\n\`\`\`"
        fi
    done < <(find . -type f \( -name "*.sh" -o -name "*.bash" -o -name "virtos-*" \) ! -name "*.bats" ! -path "./.git/*" ! -path "./build/workspace/*" ! -path "./tests/*")

    if [ -n "$SHELLCHECK_ISSUES" ]; then
        create_issue "[ShellCheck] Shell script linting issues found" "## ShellCheck Findings

The following shell scripts have linting issues:

$SHELLCHECK_ISSUES

## Priority
P2 (Medium) - Code quality improvement

## Action Required
Review and fix ShellCheck warnings to improve code quality and prevent bugs.

**Auto-detected**: $(date)
**Review log**: $REVIEW_LOG"
    fi
else
    echo "⚠️  ShellCheck not installed - skipping" | tee -a "$REVIEW_LOG"
fi

# 2. TODO/FIXME/XXX/HACK checks
echo "" | tee -a "$REVIEW_LOG"
echo "=== 2. Searching for TODO/FIXME/XXX/HACK ===" | tee -a "$REVIEW_LOG"
TODO_FINDINGS=""

while IFS= read -r finding; do
    file=$(echo "$finding" | cut -d: -f1)
    line=$(echo "$finding" | cut -d: -f2)
    content=$(echo "$finding" | cut -d: -f3-)

    # Skip if in documentation (examples) or changelog
    if [[ "$file" =~ CONTRIBUTING\.md|CHANGELOG\.md ]]; then
        continue
    fi

    echo "Found: $finding" | tee -a "$REVIEW_LOG"
    TODO_FINDINGS="${TODO_FINDINGS}\n- **$file:$line**: $content"
done < <(grep -rn "TODO\|FIXME\|XXX\|HACK" . \
    --include="*.sh" \
    --include="*.bash" \
    --include="virtos-*" \
    --include="*.md" \
    --include="*.yml" \
    --include="*.yaml" \
    --exclude="*.bats" \
    --exclude-dir=.git \
    --exclude-dir=workspace \
    --exclude-dir=tests \
    2>/dev/null || true)

if [ -n "$TODO_FINDINGS" ]; then
    # Check if we already created issues for these TODOs (avoid duplicates)
    existing_todo_issues=$(gh issue list --search "TODO FIXME" --json number,title --limit 50 2>/dev/null || echo "[]")

    if ! echo "$existing_todo_issues" | grep -q "TODO\|FIXME"; then
        create_issue "[Code Review] TODO/FIXME items found in codebase" "## Action Items Found

The following TODO/FIXME/XXX/HACK items need attention:

$TODO_FINDINGS

## Priority
P3 (Low-Medium) - Depends on item

## Action Required
Review each item and either:
1. Create specific GitHub issue for the task
2. Implement the TODO
3. Remove if no longer needed

**Auto-detected**: $(date)
**Review log**: $REVIEW_LOG"
    else
        echo "ℹ️  TODO issues already exist - skipping duplicate" | tee -a "$REVIEW_LOG"
    fi
fi

# 3. Security Scans
echo "" | tee -a "$REVIEW_LOG"
echo "=== 3. Security Scans ===" | tee -a "$REVIEW_LOG"

# Check for common security issues in shell scripts
SECURITY_ISSUES=""

# 3a. Check for hardcoded secrets (basic pattern matching)
echo "Checking for hardcoded secrets..." | tee -a "$REVIEW_LOG"
SECRET_PATTERNS=(
    "password\s*=\s*['\"][^\$][^'\"]+['\"]" # Exclude variables starting with $
    "api[_-]?key\s*=\s*['\"][^\$][^'\"]+['\"]"
    "secret\s*=\s*['\"][^\$][^'\"]+['\"]"
    "token\s*=\s*['\"][^\$][^'\"]+['\"]"
)

for pattern in "${SECRET_PATTERNS[@]}"; do
    if findings=$(grep -rn -iE "$pattern" . \
        --include="*.sh" \
        --include="*.bash" \
        --include="virtos-*" \
        --exclude="*.bats" \
        --exclude-dir=.git \
        --exclude-dir=workspace \
        --exclude-dir=tests \
        2>/dev/null | grep -v '=\s*""\|=\s*'\'''\'''); then # Exclude empty strings

        if [ -n "$findings" ]; then
            # Further filter out variable assignments from parameters
            # shellcheck disable=SC2016
            findings=$(echo "$findings" | grep -v '=\s*"\$'"[0-9]"'\|=\s*"\$\{[^}]*\}' || true)

            if [ -n "$findings" ]; then
                echo "⚠️  Potential secrets found:" | tee -a "$REVIEW_LOG"
                echo "$findings" | tee -a "$REVIEW_LOG"
                SECURITY_ISSUES="${SECURITY_ISSUES}\n\n**Pattern**: \`$pattern\`\n\`\`\`\n$findings\n\`\`\`"
            fi
        fi
    fi
done

# 3b. Check for unsafe command usage
echo "Checking for unsafe command patterns..." | tee -a "$REVIEW_LOG"
UNSAFE_PATTERNS=(
    "^[^#]*\beval\s+"                      # Match eval but not in comments, will filter DB CLI usage
    "rm\s+-rf\s+/(home|root|var|tmp)/[^/]" # Only flag dangerous paths, not /usr/local
    "\$\(.*curl.*\)\s*\|.*sh"
    "wget.*\|.*sh"
)

for pattern in "${UNSAFE_PATTERNS[@]}"; do
    if findings=$(grep -rn -E "$pattern" . \
        --include="*.sh" \
        --include="*.bash" \
        --include="virtos-*" \
        --exclude="*.bats" \
        --exclude="*uninstall*" \
        --exclude-dir=.git \
        --exclude-dir=workspace \
        --exclude-dir=tests \
        2>/dev/null || true); then

        # Filter out legitimate database CLI usage (mongo --eval, mysql --execute, psql --command)
        findings=$(echo "$findings" | grep -v 'mongo --eval\|mysql --execute\|psql --command' || true)

        # Filter out documented security justifications
        # This is a simple filter - ideally we'd check preceding lines for SECURITY NOTE
        findings=$(echo "$findings" | grep -v '# SECURITY NOTE.*eval' || true)

        if [ -n "$findings" ]; then
            echo "⚠️  Unsafe command pattern found:" | tee -a "$REVIEW_LOG"
            echo "$findings" | tee -a "$REVIEW_LOG"
            SECURITY_ISSUES="${SECURITY_ISSUES}\n\n**Unsafe Pattern**: \`$pattern\`\n\`\`\`\n$findings\n\`\`\`"
        fi
    fi
done

if [ -n "$SECURITY_ISSUES" ]; then
    create_issue "[Security] Potential security issues detected" "## Security Scan Findings

The automated security scan detected potential issues:

$SECURITY_ISSUES

## Priority
**P1 (High)** - Security-related

## Action Required
1. Review each finding
2. Verify if it's a real security issue
3. Fix or document as false positive

**Note**: These are automated findings and may include false positives.

**Auto-detected**: $(date)
**Review log**: $REVIEW_LOG"
fi

# 4. Documentation checks
echo "" | tee -a "$REVIEW_LOG"
echo "=== 4. Documentation Checks ===" | tee -a "$REVIEW_LOG"

# Check for scripts without help text
echo "Checking for scripts without --help..." | tee -a "$REVIEW_LOG"
NO_HELP_SCRIPTS=""

while IFS= read -r script; do
    if ! grep -q "\-\-help\|show_help\|usage()" "$script" 2>/dev/null; then
        echo "⚠️  $script - No help text found" | tee -a "$REVIEW_LOG"
        NO_HELP_SCRIPTS="${NO_HELP_SCRIPTS}\n- \`$script\`"
    fi
done < <(find packages/virtos-tools/src/usr/local/bin -type f -name "virtos-*" 2>/dev/null || true)

if [ -n "$NO_HELP_SCRIPTS" ]; then
    create_issue "[Documentation] Scripts missing --help text" "## Missing Help Text

The following virtos-* scripts are missing --help documentation:

$NO_HELP_SCRIPTS

## Priority
P3 (Low) - Documentation improvement

## Action Required
Add help text to each script following the standard pattern:
\`\`\`bash
show_help() {
    cat <<EOF
Usage: virtos-<name> [OPTIONS] [ARGUMENTS]

Description of what the script does

OPTIONS:
    -h, --help      Show this help message
    -v, --version   Show version

EXAMPLES:
    virtos-<name> example-arg
EOF
}
\`\`\`

**Auto-detected**: $(date)
**Review log**: $REVIEW_LOG"
fi

# 5. Code quality checks
echo "" | tee -a "$REVIEW_LOG"
echo "=== 5. Code Quality Checks ===" | tee -a "$REVIEW_LOG"

# Check for scripts without 'set -e'
echo "Checking for scripts without error handling..." | tee -a "$REVIEW_LOG"
NO_SET_E=""

while IFS= read -r script; do
    if ! grep -q "^set -e" "$script" 2>/dev/null; then
        echo "⚠️  $script - No 'set -e' found" | tee -a "$REVIEW_LOG"
        NO_SET_E="${NO_SET_E}\n- \`$script\`"
    fi
done < <(find packages/virtos-tools/src/usr/local/bin -type f -name "virtos-*" 2>/dev/null || true)

if [ -n "$NO_SET_E" ]; then
    create_issue "[Code Quality] Scripts missing error handling (set -e)" "## Missing Error Handling

The following scripts are missing \`set -e\` for proper error handling:

$NO_SET_E

## Priority
P2 (Medium) - Code quality

## Background
\`set -e\` causes scripts to exit immediately if any command fails, preventing cascading errors.

## Action Required
Add \`set -e\` near the top of each script (after shebang):
\`\`\`bash
#!/bin/sh
set -e

# Rest of script...
\`\`\`

**Auto-detected**: $(date)
**Review log**: $REVIEW_LOG"
fi

# Summary
echo "" | tee -a "$REVIEW_LOG"
echo "=== Review Summary ===" | tee -a "$REVIEW_LOG"
echo "Completed: $(date)" | tee -a "$REVIEW_LOG"
echo "Issues created: $ISSUES_CREATED" | tee -a "$REVIEW_LOG"
echo "Review log: $REVIEW_LOG" | tee -a "$REVIEW_LOG"

# Return exit code based on issues found
if [ "$ISSUES_CREATED" -gt 0 ]; then
    echo "" | tee -a "$REVIEW_LOG"
    echo "❌ Review found issues - $ISSUES_CREATED GitHub issues created" | tee -a "$REVIEW_LOG"
    exit 1
else
    echo "" | tee -a "$REVIEW_LOG"
    echo "✅ Review passed - No new issues found" | tee -a "$REVIEW_LOG"
    exit 0
fi
