# Pre-commit Hooks Guide

**Version**: 1.0  
**Last Updated**: 2026-05-29  
**Related**: Issue #112 (Code Quality Improvements)

## Overview

VirtOS uses [pre-commit](https://pre-commit.com) hooks to automatically enforce code quality standards before commits. This ensures consistent code style, prevents common errors, and catches security issues early.

## Quick Start

### Installation

```bash
# Install pre-commit (choose one method)
pip install pre-commit              # Python pip
brew install pre-commit             # macOS Homebrew
apt-get install pre-commit          # Debian/Ubuntu
dnf install pre-commit              # Fedora

# Install hooks in VirtOS repository
cd /path/to/VirtOS
pre-commit install

# Install commit-msg hook (for conventional commits)
pre-commit install --hook-type commit-msg
```

### Usage

#### Automatic (Recommended)

Once installed, hooks run automatically on `git commit`:

```bash
git add file.sh
git commit -m "fix: improve error handling"
# Hooks run automatically before commit completes
```

#### Manual

Run hooks on all files without committing:

```bash
# Run all hooks on all files
pre-commit run --all-files

# Run specific hook
pre-commit run shellcheck --all-files

# Run on specific files
pre-commit run --files config/custom-scripts/virtos-create-vm
```

#### Bypass (Not Recommended)

Skip hooks in emergencies (use sparingly):

```bash
git commit --no-verify -m "emergency fix"
```

## Hooks Configured

### 1. General File Checks

**Large Files**: Prevents files >500KB

- **Why**: Large files slow down repository
- **Fix**: Use Git LFS or external storage

**Case Conflicts**: Detects case-sensitive filename issues

- **Why**: Prevents Windows/macOS compatibility issues
- **Fix**: Rename files to be uniquely cased

**Merge Conflicts**: Prevents committing merge conflict markers

- **Why**: Broken code in repository
- **Fix**: Resolve conflicts properly

**Executables**: Ensures executables have shebangs

- **Why**: Scripts won't run without shebang
- **Fix**: Add `#!/bin/bash` or `#!/bin/sh`

**JSON/YAML**: Validates syntax

- **Why**: Broken configs cause runtime errors
- **Fix**: Fix syntax errors reported

**Private Keys**: Detects accidentally committed keys

- **Why**: Security vulnerability
- **Fix**: Remove keys, rotate credentials

**Trailing Whitespace**: Removes trailing spaces

- **Why**: Cleaner diffs, consistent formatting
- **Fix**: Automatic

**Line Endings**: Enforces LF line endings

- **Why**: Consistent across platforms
- **Fix**: Automatic

### 2. ShellCheck

**What**: Shell script linting
**Severity**: Warnings and errors
**Files**: `*.sh`, `*.bash`, `virtos-*` scripts

**Common Issues**:

- SC2006: Use `$(...)` instead of backticks
- SC2086: Quote variables to prevent word splitting
- SC2046: Quote command substitutions
- SC2034: Unused variables
- SC2181: Check exit code directly instead of `$?`

**Fix**:

```bash
# Bad
files=`ls *.txt`
for f in $files; do echo $f; done

# Good
files=$(ls *.txt)
for f in "$files"; do echo "$f"; done
```

**Disable false positives**:

```bash
# shellcheck disable=SC2034
UNUSED_VAR="value"  # Used by sourced script
```

### 3. shfmt

**What**: Shell script formatter
**Style**: 4-space indent, switch case indent, binary ops on new line

**Example**:

```bash
# Before
if [ "$x" = "y" ];then
echo "match"
fi

# After (auto-formatted)
if [ "$x" = "y" ]; then
    echo "match"
fi
```

**Configuration** (`.editorconfig`):

- Indent: 4 spaces
- Case indent: Yes
- Binary operators: New line before
- Max line length: 120

### 4. Bashate

**What**: OpenStack shell style checker
**Checks**: Bash-specific style issues

**Rules**:

- E001: Trailing whitespace
- E002: Tab indent
- E003: Indent not multiple of 4
- E004: File too long (>1000 lines)
- E005: Line too long (>79 chars) - ignored for now
- E006: Line too long (>120 chars)

### 5. Markdown Linting

**What**: Markdown style checker
**Auto-fix**: Yes

**Common Issues**:

- MD001: Heading levels should increment by one
- MD013: Line length (disabled)
- MD033: No inline HTML
- MD041: First line should be top-level heading

**Configuration**:

```yaml
# .markdownlint.yaml (if needed)
MD013: false  # Line length
MD033: false  # Allow HTML in docs
```

### 6. YAML Linting

**What**: YAML style checker
**Max line length**: 120

**Common Issues**:

- Indentation (must be 2 spaces)
- Trailing spaces
- Document start markers

### 7. Detect Secrets

**What**: Prevents committing secrets
**Baseline**: `.secrets.baseline`

**Detects**:

- AWS keys
- Private keys
- GitHub tokens
- JWT tokens
- API keys
- Passwords in code

**False Positives**:
Update `.secrets.baseline`:

```bash
detect-secrets scan --baseline .secrets.baseline
```

### 8. Conventional Commits

**What**: Enforces commit message format
**Format**: `<type>(<scope>): <subject>`

**Types**:

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Tests
- `chore`: Maintenance
- `ci`: CI/CD changes

**Examples**:

```bash
# Good
git commit -m "feat: add input validation to virtos-create-vm"
git commit -m "fix(security): prevent command injection in VM names"
git commit -m "docs: update security hardening guide"

# Bad
git commit -m "updates"
git commit -m "Fixed stuff"
git commit -m "WIP"
```

## Troubleshooting

### Hook Fails

**Issue**: Hook reports errors
**Solution**:

1. Read error message carefully
2. Fix reported issues
3. Stage fixed files: `git add <file>`
4. Retry commit: `git commit`

### Hook Won't Run

**Issue**: Hooks not triggering on commit
**Solution**:

```bash
# Reinstall hooks
pre-commit uninstall
pre-commit install
pre-commit install --hook-type commit-msg

# Verify installation
ls -la .git/hooks/
# Should see pre-commit and commit-msg
```

### Too Slow

**Issue**: Hooks take too long
**Solution**:

```bash
# Run only fast hooks
pre-commit run --hook-stage manual

# Skip specific hook temporarily
SKIP=shellcheck git commit -m "message"

# Update hook cache
pre-commit clean
pre-commit install-hooks
```

### False Positives

**ShellCheck**:

```bash
# Disable specific check
# shellcheck disable=SC2034
VARIABLE="value"

# Disable for whole file (top of file)
# shellcheck disable=SC1090,SC2034
```

**Detect Secrets**:

```bash
# Update baseline
detect-secrets scan --baseline .secrets.baseline

# Review and commit updated baseline
git add .secrets.baseline
git commit -m "chore: update secrets baseline"
```

### Emergency Bypass

**Last Resort Only**:

```bash
# Skip all hooks (use sparingly!)
git commit --no-verify -m "emergency: critical production fix"
```

**When to bypass**:

- Critical production hotfix
- Fixing broken CI/CD
- Reverting bad commit

**Never bypass for**:

- "Just this once"
- Avoiding fixing style issues
- Time pressure on features

## Best Practices

### 1. Fix Issues Early

Don't accumulate hook violations. Fix as you go:

```bash
# Before committing, run hooks manually
pre-commit run --files <files-you-changed>

# Fix issues immediately
# Then commit
```

### 2. Understand Errors

Don't blindly disable checks. Understand what they're catching:

- Read ShellCheck wiki: <https://www.shellcheck.net/wiki/>
- Ask in code review if unsure
- Document why you're disabling a check

### 3. Update Hooks Regularly

```bash
# Update hook versions
pre-commit autoupdate

# Review changes
git diff .pre-commit-config.yaml

# Test updated hooks
pre-commit run --all-files

# Commit updates
git add .pre-commit-config.yaml
git commit -m "chore: update pre-commit hooks"
```

### 4. Team Consistency

- All contributors should install hooks
- Don't commit hook-violating code
- Fix hook issues in your PRs, not maintainer's job

## CI Integration

Pre-commit hooks also run in CI (`.github/workflows/ci.yml`):

```yaml
- name: Run pre-commit hooks
  run: |
    pip install pre-commit
    pre-commit run --all-files
```

**Why CI?**

- Catches issues if contributor didn't install hooks
- Enforces standards on all PRs
- Provides feedback in PR checks

## Configuration Files

### `.pre-commit-config.yaml`

Main configuration file defining all hooks.

### `.editorconfig`

Editor/IDE configuration for consistent formatting.

### `.secrets.baseline`

Baseline for detect-secrets (known false positives).

### `.shellcheckrc` (optional)

ShellCheck-specific configuration:

```bash
# .shellcheckrc
disable=SC1090  # Can't follow non-constant source
disable=SC2034  # Unused variables exported by sourced files
```

## Customization

### Skip Specific Hooks

In `.pre-commit-config.yaml`:

```yaml
- id: shellcheck
  exclude: '^legacy/'  # Skip legacy scripts
```

### Add Custom Hook

```yaml
- repo: local
  hooks:
    - id: custom-check
      name: Custom VirtOS Check
      entry: ./scripts/custom-check.sh
      language: script
      files: ^config/custom-scripts/
```

### Adjust Hook Behavior

```yaml
- id: shellcheck
  args: ['-x', '-S', 'warning', '--exclude=SC2034']
```

## Migration Guide

### Existing Repository

If VirtOS repository already has commits:

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install
pre-commit install --hook-type commit-msg

# Run on all existing files (may find many issues)
pre-commit run --all-files > violations.txt

# Review violations
less violations.txt

# Option 1: Fix all at once (recommended for new repo)
# Fix issues file by file
# Commit fixes

# Option 2: Gradual migration
# Add violations to exceptions
# Fix over time in separate PRs
```

### New Contributors

Add to `CONTRIBUTING.md`:

```markdown
## Setup Development Environment

1. Install pre-commit:
   ```bash
   pip install pre-commit
   ```

2. Install hooks:

   ```bash
   pre-commit install
   pre-commit install --hook-type commit-msg
   ```

3. (Optional) Run on all files:

   ```bash
   pre-commit run --all-files
   ```

4. Hooks now run automatically on commit!

```

## Resources

- **pre-commit**: https://pre-commit.com
- **ShellCheck**: https://www.shellcheck.net
- **shfmt**: https://github.com/mvdan/sh
- **Conventional Commits**: https://www.conventionalcommits.org
- **detect-secrets**: https://github.com/Yelp/detect-secrets

## FAQ

**Q: Do I need Python to use pre-commit?**  
A: Yes, pre-commit requires Python 3.8+.

**Q: Can I use pre-commit with other Git hooks?**  
A: Yes, pre-commit manages `.git/hooks/` but preserves custom hooks.

**Q: What if a hook is broken?**  
A: Disable temporarily: `SKIP=hook-id git commit -m "message"`

**Q: How often should I update hooks?**  
A: Monthly via `pre-commit autoupdate`

**Q: Can I run hooks in CI only?**  
A: Yes, but local hooks catch issues faster.

**Q: Do hooks work on Windows?**  
A: Yes, but some hooks (shfmt, shellcheck) may need WSL.

## Support

- **Issues**: https://github.com/FlossWare/VirtOS/issues
- **Discussions**: https://github.com/FlossWare/VirtOS/discussions
- **Contributing**: See [CONTRIBUTING.md](../CONTRIBUTING.md)

---

**Last Updated**: 2026-05-29  
**Version**: 1.0  
**Related Issues**: #112 (Code Quality)  
**Related Docs**: [CONTRIBUTING.md](../CONTRIBUTING.md)
