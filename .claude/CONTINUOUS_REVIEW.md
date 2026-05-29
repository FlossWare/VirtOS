# VirtOS Continuous Code Review System

**Status**: 🟢 Active  
**Schedule**: Every 10 minutes (`*/10 * * * *`)  
**Auto-expires**: 7 days from activation  
**Created**: $(date)

---

## Overview

Automated multi-language code review system that runs every 10 minutes, checking:

- **Python**: mypy, flake8, bandit, security scans, TODO checks
- **Java**: Security scans, TODO checks
- **Shell Scripts**: Security scans, TODO checks (via automated-review.sh)

## Features

### 1. Multi-Language Support

**Python Checks**:

- ✅ `mypy` - Type checking
- ✅ `flake8` - Style and code quality
- ✅ `bandit` - Security vulnerability scanning
- ✅ TODO/FIXME detection
- ✅ Auto-formatting with `black` (if installed)
- ✅ Auto-import sorting with `isort` (if installed)

**Java Checks**:

- ✅ Security pattern detection:
  - Runtime.exec usage
  - ProcessBuilder usage
  - Reflection setAccessible(true)
  - Unsafe File path construction
  - Non-prepared SQL statements
  - Hardcoded passwords
- ✅ TODO/FIXME detection

**Shell Scripts**:

- ✅ Security scans (via automated-review.sh)
- ✅ TODO/FIXME detection
- ✅ Unsafe command pattern detection
- ✅ Hardcoded secret detection

### 2. Auto-Accept Configuration

**File**: `.claude/settings.json`

```json
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "Write(**/*)",
      "Edit(**/*)",
      "Read(**/*)",
      "TaskCreate",
      "TaskUpdate",
      "Workflow",
      "Agent",
      "CronCreate"
    ],
    "defaultMode": "dontAsk"
  }
}
```

**What this enables**:

- ✅ No prompts for bash commands
- ✅ No prompts for file operations
- ✅ No prompts for git operations
- ✅ Fully automated execution

### 3. Auto-Push Workflow

**Automatic Actions**:

1. 🔍 **Scan**: Multi-language code analysis
2. 🐛 **Detect**: Find issues and TODOs
3. 📝 **Issue**: Create GitHub issues via `gh` CLI
4. 🔧 **Fix**: Auto-fix safe issues (formatting, imports)
5. 💾 **Commit**: Git commit with co-authored signature
6. 🚀 **Push**: Push to `main` branch

**Co-Authored Commits**:

```text
style: auto-format Python files with black

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### 4. Stop Condition

The review **automatically stops** when:

- ✅ No new issues found
- ✅ No auto-fixes applied
- ✅ Exit code 0 returned

The review **continues running** when:

- ⚡ New issues detected
- ⚡ Auto-fixes were applied
- ⚡ Exit code 1 returned

---

## Configuration

### Review Script

**Location**: `.claude/continuous-review.sh`  
**Permissions**: Executable (`chmod +x`)  
**Logging**: `/tmp/virtos-continuous-review-YYYYMMDD-HHMMSS.log`

### Cron Job

**Job ID**: `9d1bbba3`  
**Cron Expression**: `*/10 * * * *` (every 10 minutes)  
**Durable**: Yes (persisted to `.claude/scheduled_tasks.json`)  
**Auto-Expires**: After 7 days

---

## Usage

### Manual Execution

```bash
cd /home/sfloess/Development/github/FlossWare/VirtOS
./.claude/continuous-review.sh
```

### View Scheduled Jobs

```bash
# In Claude Code:
/tasks

# Or check the file:
cat .claude/scheduled_tasks.json
```

### Cancel Recurring Review

```bash
# Using CronDelete with job ID:
# CronDelete 9d1bbba3
```

### View Review Logs

```bash
# Latest logs:
ls -lt /tmp/virtos-continuous-review-*.log | head -5

# Follow live:
tail -f /tmp/virtos-continuous-review-*.log
```

---

## Issue Creation

Issues are automatically created via GitHub CLI (`gh`) with the following format:

**Issue Title Examples**:

- `[Python] mypy type checking issues`
- `[Python Security] bandit security scan findings`
- `[Java Security] Potential security issues detected`
- `[Shell] Security issues detected`

**Issue Body Includes**:

- Detailed findings with file paths and line numbers
- Code snippets showing the issue
- Priority level (P1-P3)
- Auto-detection timestamp
- Tool name used for detection

---

## Auto-Fix Capabilities

### Safe Auto-Fixes (Automatically Applied)

**Python**:

- ✅ Code formatting (`black`)
- ✅ Import sorting (`isort`)

**Future Auto-Fixes**:

- Shell script formatting (`shfmt`)
- Java formatting (`google-java-format`)
- Markdown linting fixes

### Manual Review Required

**NOT Auto-Fixed** (require human judgment):

- Security vulnerabilities
- Type errors
- Logic bugs
- TODO items
- Breaking changes

---

## Monitoring

### Review Metrics

Track via logs:

```bash
# Count issues created per review
grep "Issues created:" /tmp/virtos-continuous-review-*.log

# Count auto-fixes applied
grep "Auto-fixes applied:" /tmp/virtos-continuous-review-*.log

# Most recent review status
tail -20 /tmp/virtos-continuous-review-*.log | grep "Review"
```

### GitHub Integration

All issues visible at:

```text
https://github.com/FlossWare/VirtOS/issues
```

Filter by labels:

- `[Python]` - Python-specific issues
- `[Java]` - Java-specific issues  
- `[Shell]` - Shell script issues
- `Security` - Security-related issues

---

## Tool Installation

### Python Tools

```bash
# Install Python linting/security tools
pip install mypy flake8 bandit black isort

# Or via package manager
sudo dnf install python3-mypy python3-flake8 bandit
```

### Java Tools

Java security scanning is built-in (pattern-based).
For advanced scanning, install:

```bash
# SpotBugs (optional)
# FindSecBugs (optional)
```

### Shell Tools

Already included:

- ✅ `automated-review.sh` (existing)
- ✅ `grep` for pattern matching
- ✅ `gh` CLI for GitHub integration

---

## Troubleshooting

### Review Not Running

**Check cron job**:

```bash
cat .claude/scheduled_tasks.json | grep -A 5 "9d1bbba3"
```

**Check if expired** (7 days max):

- Jobs auto-expire after 7 days
- Re-create with CronCreate if needed

### Permission Errors

**Verify settings**:

```bash
cat .claude/settings.json | jq '.permissions'
```

**Should show**:

```json
{
  "allow": ["Bash(*)", "Write(**/*)", "Edit(**/*)", "Read(**/*)"],
  "defaultMode": "dontAsk"
}
```

### Tools Not Found

**Install missing tools**:

```bash
# Python
pip install mypy flake8 bandit black isort

# Check installation
which mypy flake8 bandit black isort
```

### GitHub CLI Not Working

**Authenticate**:

```bash
gh auth login
gh auth status
```

---

## Security Considerations

### What's Scanned

**Python**:

- Unsafe deserialization (pickle, eval)
- SQL injection vulnerabilities
- Command injection
- Hardcoded secrets
- Insecure random usage

**Java**:

- Runtime.exec / ProcessBuilder
- Reflection abuse
- SQL injection
- Path traversal
- Hardcoded credentials

**Shell**:

- Unsafe eval usage
- Unquoted variables
- rm -rf patterns
- Command injection
- Hardcoded secrets

### What's NOT Scanned

- Compiled binaries
- Third-party dependencies
- Network security
- Infrastructure configuration
- Access control

---

## Roadmap

### Planned Enhancements

**Short-term**:

- [ ] Add Python pytest auto-runner
- [ ] Add Java JUnit test detection
- [ ] Integrate shellcheck findings
- [ ] Add commit message linting

**Medium-term**:

- [ ] Dependency vulnerability scanning
- [ ] Code coverage tracking
- [ ] Performance regression detection
- [ ] Documentation completeness check

**Long-term**:

- [ ] Machine learning-based bug prediction
- [ ] Auto-generate unit tests
- [ ] Intelligent code suggestions
- [ ] Security fix proposals

---

## Related Documentation

- [Automated Review System](.claude/README.md)
- [Shell Script Review](.claude/automated-review.sh)
- [Settings Configuration](.claude/settings.json)
- [Contributing Guidelines](../CONTRIBUTING.md)

---

## Status

**Current State**: 🟢 **ACTIVE**

- ✅ Multi-language support enabled
- ✅ Auto-accept configured
- ✅ Recurring execution every 10 minutes
- ✅ GitHub integration working
- ✅ Auto-fix capabilities enabled
- ✅ Stop condition configured

**Next Review**: Within 10 minutes

**Auto-Expires**: $(date -d '+7 days')

---

**Created**: $(date)  
**Last Updated**: $(date)  
**Version**: 1.0  
**Status**: Production
