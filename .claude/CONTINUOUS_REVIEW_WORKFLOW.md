# Continuous Code Review Workflow with AI Attribution

## Overview

This automated workflow runs code reviews using multiple AI models, creates GitHub issues with full model attribution, and auto-fixes safe issues.

## Workflow Steps

### 1. Multi-Model Code Review

**Execute**: Run code review with multiple AI models

```bash
# Use the multi-model review skill
/virtos-4-model-review "Review all shell scripts"
```

**Models Used**:

- **Claude Opus 4.8**: Deep security audit (most thorough)
- **Claude Sonnet 4.5**: Balanced analysis (arbiter role)
- **Claude Haiku 4.5**: Fast triage
- **Gemini 2.0 Flash Exp**: Alternative perspective (optional)

**Output**: Each model provides independent findings with severity ratings

### 2. Arbiter Decision Process

**Arbiter**: Claude Sonnet 4.5 (default)

**Decision Framework**:

#### Auto-Fix Criteria (ALL must be true)

- ✅ Low implementation risk (simple pattern or library call)
- ✅ High confidence (multi-model consensus OR clear library solution)
- ✅ No architecture changes required
- ✅ Testable without external dependencies
- ✅ No backward compatibility concerns

#### Manual Review Criteria (ANY can trigger)

- ❌ Complex logic requiring design decisions
- ❌ State management or security-critical workflows
- ❌ External dependencies or upstream coordination
- ❌ API contract changes
- ❌ Single-model finding with no validation

### 3. AI Attribution Documentation

**For Each Finding**, document:

#### Models That Found It

```python
{
  "models_found": [
    {
      "name": "Claude Opus 4.8",
      "severity": "CRITICAL",
      "details": "30+ instances with file:line refs"
    },
    {
      "name": "Claude Sonnet 4.5",
      "severity": "HIGH",
      "details": "Confirmed systemic gap"
    }
  ]
}
```

#### Models That Missed It

```python
{
  "models_missed": [
    {
      "name": "Claude Haiku 4.5",
      "reason": "Focused on different vulnerability classes"
    }
  ]
}
```

#### Arbiter Decision

```python
{
  "arbiter_decision": "auto-fix",  # or "manual-review", "partial"
  "accepted_approach": "Use parse_config_file() instead of source",
  "rejected_approaches": [
    {
      "approach": "Manual review",
      "reason": "Too simple, library function exists"
    },
    {
      "approach": "Leave as is",
      "reason": "Multi-model consensus validates severity"
    }
  ]
}
```

### 4. Create GitHub Issues with Attribution

**Script**: `.claude/scripts/create_ai_attributed_issue.py`

**Usage**:

```python
from create_ai_attributed_issue import create_issue_with_attribution

issue_data = {
    "title": "Insecure temp file creation",
    "severity": "HIGH",
    "models_found": [...],
    "models_missed": [...],
    "arbiter_decision": "auto-fix",
    "accepted_approach": "Use create_temp_file()",
    "rejected_approaches": [...],
    "body": "Full issue description..."
}

create_issue_with_attribution(issue_data)
```

**Generated Issue Includes**:

- Model findings table (who found it, severity, details)
- Consensus percentage
- Arbiter decision and reasoning
- Accepted approach with justification
- Rejected approaches with why they weren't chosen
- Timestamp and session info

### 5. Auto-Fix Safe Issues

**Execute**: Apply fixes for issues meeting auto-fix criteria

```bash
# Example: Fix temp file issues
python3 << 'FIX'
# Replace /tmp with create_temp_file()
sed -i 's|/tmp/file.txt|$(create_temp_file "prefix")|' script.sh
FIX

# Verify fix
.claude/scripts/code_review.sh

# Commit with attribution
git commit -m "fix: issue description

Resolves #300 (UNANIMOUS AI consensus)

AI Model Attribution:
- Finder: All 3 models (Opus, Sonnet, Haiku)
- Arbiter: Claude Sonnet 4.5
- Decision: Auto-fix (unanimous consensus)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

### 6. Update Issues with Results

**After Each Fix**, add comment with:

- Commit hash
- What was fixed
- Validation results
- Remaining work (if partial)

**Template**:

```markdown
## ✅ Auto-Fix Applied

**Commit**: abc1234
**Arbiter**: Claude Sonnet 4.5

### Model Attribution
- **Opus 4.8**: FOUND (CRITICAL) - Primary finder
- **Sonnet 4.5**: FOUND (HIGH) - Confirmed
- **Haiku 4.5**: FOUND (MEDIUM) - Validated

**Consensus**: UNANIMOUS (3/3 models)

### Decision Reasoning
Auto-fix applied because:
1. ✅ Simple pattern (low risk)
2. ✅ Library available (create_temp_file)
3. ✅ Unanimous consensus (high confidence)

### Validation
- ✅ ShellCheck: Passed
- ✅ Code review: 0 new issues
- ✅ Pre-commit hooks: Passed
```

## Model Performance Tracking

### After Each Session

**Create Attribution Report**: `.claude/review-output/auto-fix-ai-attribution.md`

**Include**:

- Which models found which issues
- Arbiter decisions and reasoning
- Accepted vs. rejected approaches
- Success rate of auto-fixes
- Model strengths/weaknesses observed

**Example**:

```markdown
## Model Performance

**Claude Opus 4.8**:
- Findings: 4 issues
- Auto-fixed: 2 (50%)
- Strength: Comprehensive vulnerability discovery
- Limitation: Found complex issues requiring manual review

**Claude Sonnet 4.5** (Arbiter):
- Findings: 3 confirmed
- Auto-fixed: 3 (100%)
- Strength: Balanced risk assessment
- Role: Primary implementer

**Claude Haiku 4.5**:
- Findings: 1 unanimous
- Auto-fixed: 1 (100%)
- Strength: Fast validation
- Limitation: Missed some classes
```

## Continuous Loop

### Run Until Clean

```bash
while true; do
    echo "=== Code Review Iteration ==="

    # Run review
    .claude/scripts/code_review.sh

    # Check results
    ISSUES=$(grep -c '\.sh:' .claude/review-output/*.txt 2>/dev/null || echo 0)

    if [ "$ISSUES" -eq 0 ]; then
        echo "✅ CLEAN - No new issues"
        break
    fi

    # Create issues with AI attribution
    python3 .claude/scripts/create_review_issues.py

    # Auto-fix safe issues
    # (manual step - apply fixes based on arbiter decision)

    # Verify fixes
    .claude/scripts/code_review.sh
done
```

## Decision Examples

### Example 1: Unanimous Consensus → Auto-Fix

**Finding**: Insecure temp files
**Models**: Opus (MEDIUM), Sonnet (CRITICAL), Haiku (HIGH)
**Consensus**: 100% (3/3)
**Arbiter Decision**: ✅ AUTO-FIX

**Reasoning**:
> Unanimous consensus = highest confidence.
> Library function exists = low risk.
> Simple pattern = straightforward implementation.

**Result**: Applied automatically

---

### Example 2: Partial Consensus → Selective Auto-Fix

**Finding**: Source of config files
**Models**: Opus (CRITICAL), Sonnet (confirmed), Haiku (missed)
**Consensus**: 67% (2/3)
**Arbiter Decision**: 🟡 PARTIAL AUTO-FIX

**Reasoning**:
> Opus comprehensive audit (30+ instances).
> Split by complexity:
>
> - Simple configs (4 scripts) → AUTO-FIX
> - Complex logic (8 scripts) → MANUAL REVIEW

**Result**: 33% auto-fixed, 67% manual

---

### Example 3: Single Model → Manual Review

**Finding**: Unverified downloads
**Models**: Opus (HIGH), Sonnet (missed), Haiku (missed)
**Consensus**: 33% (1/3)
**Arbiter Decision**: ❌ MANUAL REVIEW

**Reasoning**:
> Single model = lower confidence.
> External dependencies = can't automate.
> Requires vendor coordination.

**Result**: Manual implementation required

---

## Integration with CI/CD

### Pre-commit Hook

```bash
# .git/hooks/pre-commit
.claude/scripts/code_review.sh

if [ $? -ne 0 ]; then
    echo "❌ Code review failed - fix issues before commit"
    exit 1
fi
```

### GitHub Actions

```yaml
name: Continuous Code Review
on: [push, pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run code review
        run: .claude/scripts/code_review.sh
      - name: Check results
        run: |
          if [ -s .claude/review-output/shellcheck.txt ]; then
            echo "❌ ShellCheck issues found"
            exit 1
          fi
```

## Success Metrics

**Track**:

- Issues found per model
- Auto-fix success rate
- False positive rate
- Time to resolution
- Model agreement percentage

**Goal**:

- 100% automated scan coverage
- >90% auto-fix success rate (safe fixes only)
- <5% false positive rate
- Multi-model consensus on critical issues

---

**Last Updated**: 2026-06-03
**Arbiter**: Claude Sonnet 4.5
**Status**: Production-ready workflow
