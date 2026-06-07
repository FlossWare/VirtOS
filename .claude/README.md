# VirtOS Automated Code Review System

**Status**: Active  
**Schedule**: Every 10 minutes  
**Auto-expires**: 7 days from activation

---

## Overview

Automated code review system that runs comprehensive checks every 10 minutes and automatically creates GitHub issues for findings.

## Components

### 1. automated-review.sh

Main review script that runs all checks:

- **ShellCheck**: Linting for shell scripts (if installed)
- **TODO/FIXME/XXX/HACK**: Finds action items in code
- **Security Scans**: Detects hardcoded secrets, unsafe patterns
- **Documentation**: Checks for missing --help text
- **Code Quality**: Ensures scripts have `set -e` error handling

### 2. create_review_issues.py

Python script for creating GitHub issues from review findings:

- Uses `gh` CLI to create issues
- Checks for duplicates before creating
- Adds co-authored signatures
- Supports JSON input format

### 3. settings.json

Auto-accept configuration for Claude Code:

- All Bash commands auto-approved
- All Read/Write/Edit operations auto-approved
- No permission prompts during automated reviews

### 4. Scheduled Task

Cron job running every 10 minutes:

- Executes `automated-review.sh`
- Creates GitHub issues for findings
- Attempts to fix issues automatically (where safe)
- Commits and pushes fixes with co-authored signatures

---

## First Run Results

**Date**: 2026-05-29 09:37:39 EDT  
**Duration**: 5 seconds  
**Issues Created**: 4

### Issues Created

1. **Issue #150** - [Code Review] TODO/FIXME items found in codebase
   - **Priority**: P3 (Low-Medium)
   - **Count**: 38 TODO/FIXME/XXX items found
   - **Action**: Review and convert to specific issues or implement

2. **Issue #151** - [Security] Potential security issues detected
   - **Priority**: P1 (High)
   - **Findings**: Hardcoded passwords, unsafe eval usage
   - **Action**: Review and fix security issues

3. **Issue #152** - [Documentation] Scripts missing --help text
   - **Priority**: P3 (Low)
   - **Count**: 1 script (virtos-setup)
   - **Action**: Add --help documentation

4. **Issue #153** - [Code Quality] Scripts missing error handling (set -e)
   - **Priority**: P2 (Medium)
   - **Count**: 51 scripts
   - **Action**: Add `set -e` to all scripts

---

## Recurring Schedule

**Cron Expression**: `*/10 * * * *` (every 10 minutes)

**Schedule Details**:

- Runs at: :00, :10, :20, :30, :40, :50 of every hour
- Auto-expires: 7 days (2026-06-05)
- Durable: Yes (survives Claude Code restarts)

**Next Runs**:

- 09:40, 09:50, 10:00, 10:10, 10:20... (every 10 minutes)

---

## Stop Condition

The review will stop creating issues when:

- No new issues are found
- All checks pass clean
- Review exits with code 0

**Current State**: Active - issues found, will continue

---

## Manual Operations

### Run Review Manually

```bash
cd /home/sfloess/Development/github/FlossWare/VirtOS
./.claude/automated-review.sh
```

### View Scheduled Tasks

```bash
# In Claude Code, run:
/tasks
# Or check the file:
cat .claude/scheduled_tasks.json
```

### Cancel Recurring Review

```bash
# Get job ID from /tasks or:
# CronDelete 71605b8c
```

### View Review Logs

```bash
ls -lt /tmp/virtos-review-*.log | head -5
tail -f /tmp/virtos-review-*.log
```

---

## Auto-Fix Strategy

When safe to auto-fix, the system will:

1. **Add `set -e` to scripts**
   - Low risk
   - Improves error handling
   - Auto-commit: ✅ Yes

2. **Add --help text**
   - Template-based generation
   - Low risk
   - Auto-commit: ✅ Yes

3. **Remove obvious TODOs**
   - Only if marked as "cleanup" or "remove this"
   - Medium risk
   - Auto-commit: ⚠️ Selective

4. **Security fixes**
   - HIGH RISK
   - Auto-commit: ❌ No (issue only)

5. **ShellCheck fixes**
   - Depends on severity
   - Auto-commit: ⚠️ Selective (SC2086, SC2068 only)

---

## Permissions

**Auto-accepted operations** (.claude/settings.json):

- All Bash commands
- All file Read operations
- All file Write operations
- All file Edit operations
- Git commands (commit, push)

**Still require approval**:

- Destructive operations (git reset --hard, rm -rf /)
- Branch changes
- Force pushes

---

## Integration with CI/CD

The automated review system integrates with:

- **GitHub Actions**: Issues visible in GitHub
- **Git History**: Auto-fixes committed with co-authored signatures
- **Issue Tracking**: All findings tracked as GitHub issues
- **Metrics**: Review logs track trends over time

---

## Configuration

### Adjust Review Frequency

Edit the cron schedule:

```bash
# Every 10 minutes (current)
*/10 * * * *

# Every 30 minutes
*/30 * * * *

# Every hour
0 * * * *

# Twice daily (9am, 5pm)
0 9,17 * * *
```

### Customize Checks

Edit `.claude/automated-review.sh`:

- Comment out sections you don't want
- Add new security patterns
- Adjust priority levels
- Change issue templates

### Add New Checks

Example - add dependency check:

```bash
# 6. Dependency checks
echo "=== 6. Checking Dependencies ===" | tee -a "$REVIEW_LOG"
missing_deps=$(./build/scripts/validate-build.sh 2>&1 | grep "not found" || true)

if [ -n "$missing_deps" ]; then
    create_issue "[Dependencies] Missing build dependencies" "$missing_deps"
fi
```

---

## Metrics & Reporting

### Current Stats

- **Total runs**: 1
- **Issues created**: 4 (150-153)
- **Auto-fixes applied**: 0 (not yet implemented)
- **Success rate**: 100% (all checks ran)

### Review Trends

Track over time:

```bash
# Count issues created per review
grep "Issues created:" /tmp/virtos-review-*.log

# Most common findings
grep "Creating issue:" /tmp/virtos-review-*.log | cut -d: -f2 | sort | uniq -c | sort -rn
```

---

## Troubleshooting

### Review Not Running

1. Check cron job: `cat .claude/scheduled_tasks.json`
2. Check if expired (7 days max)
3. Re-create with `CronCreate`

### Too Many Issues

1. Increase review interval (30 min instead of 10 min)
2. Disable some checks in automated-review.sh
3. Fix high-priority issues first

### Permission Denied

1. Check `.claude/settings.json` permissions
2. Verify `gh` CLI is authenticated
3. Check file permissions: `chmod +x .claude/*.sh .claude/*.py`

---

## Future Enhancements

**Planned**:

- ShellCheck auto-fixes for simple warnings
- Automated `set -e` addition to all scripts
- Dependency checking
- License header validation
- Markdown linting
- YAML validation

**Under Consideration**:

- Integration with external security scanners (Trivy, Bandit)
- Code coverage tracking
- Performance regression detection
- Breaking change detection

---

## Related Documentation

- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
- [CODING_STANDARDS.md](../docs/CODING_STANDARDS.md) - Official coding standards
- [docs/TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md) - Troubleshooting guide

---

## Questions?

- **GitHub Issues**: <https://github.com/FlossWare/VirtOS/issues>
- **Review Logs**: `/tmp/virtos-review-*.log`
- **Scheduled Tasks**: `.claude/scheduled_tasks.json`

---

**Created**: 2026-05-29  
**Last Updated**: 2026-05-29  
**Status**: Active (expires 2026-06-05)
