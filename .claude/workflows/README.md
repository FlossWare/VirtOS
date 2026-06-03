# Global AI Workflows

**Universal workflows for AI-powered code review, PR review, issue resolution, and quality improvement**

## Overview

This directory contains **global workflows** that work across ALL projects (GitHub, GitLab, Bitbucket).

### 🎯 Core Workflows

1. **code-review.js** - Multi-model code review with configurable consensus strategies
2. **pr-review.js** - Auto PR review with quality scoring and approval
3. **code-solve.js** - Auto-resolve GitHub/GitLab issues
4. **code-improve.js** - Iterative quality improvement with target scoring
5. **ai-prompt.js** - Multi-model consensus for any user question
6. **auto-review-brutal.js** - Brutal multi-model review (legacy, use code-review.js)

### 🧩 Shared Infrastructure

All workflows use these shared modules for consistency:

- **shared/schemas.js** - Standard JSON schemas (ISSUE_SCHEMA, REVIEW_SCHEMA, etc.)
- **shared/consensus-engine.js** - Multi-model voting with 5 strategies (rotating, single, majority, weighted, pairwise)
- **shared/platform-detector.js** - Auto-detect GitHub/GitLab/Bitbucket
- **shared/ai-attribution.js** - Consistent AI attribution formatting
- **shared/quality-scorer.js** - Quality calculation (0-100 score)
- **shared/loop-controller.js** - Loop/continuous monitoring patterns

## Quick Start

### Installation

**Option 1: Global Installation** (Recommended)
```bash
# Copy to ~/.claude/workflows/ for use across ALL projects
cp -r .claude/workflows/* ~/.claude/workflows/
```

**Option 2: Per-Project Installation**
```bash
# Already in this repo at .claude/workflows/
# Works immediately in this project
```

### Usage

#### 1. Code Review (NEW - Unified with Strategies)
```bash
# Rotating arbiter (most fair, recommended)
/code-review --strategy=rotating

# Fast majority vote (no arbiter overhead)
/code-review --strategy=majority --workers=opus,sonnet

# Weighted consensus (confidence-based)
/code-review --strategy=weighted

# Custom arbiter
/code-review --strategy=single --arbiter=sonnet

# Target specific path
/code-review --path=packages/virtos-tools
```

#### 2. PR Review
```bash
# Review PR #42
/pr-review 42

# Review and post comment
/pr-review 42 --post

# Auto-approve if quality >= 90
/pr-review 42 --approve --threshold=90

# Continuous monitoring
/pr-review loop --auto-approve --threshold=95
```

#### 3. Code Solve (Issue Resolution)
```bash
# Resolve issue #326
/code-solve 326

# Create PR with fix
/code-solve 326 --create-pr

# Continuous issue resolution
/code-solve loop
```

#### 4. Code Improve (Quality Enhancement)
```bash
# Auto mode, target 95% quality
/code-improve --auto --target-score 95

# Specific path
/code-improve --path packages/virtos-tools --target-score 90

# Max 5 iterations
/code-improve --auto --max-iterations 5
```

#### 5. AI Prompt (Multi-Model Consensus)
```bash
# Get consensus answer to any question
/ai-prompt How should I architect this feature?

# Shows: consensus level, agreements, disagreements, model contributions
```

## Consensus Strategies

All workflows support 5 consensus strategies via `--strategy` parameter:

### 1. **rotating** (Most Democratic) ⭐ RECOMMENDED
- Different arbiter each time (Opus → Sonnet → Haiku → repeat)
- Prevents single-model bias
- Most fair consensus
- **Use for**: Critical code, production, high-stakes

### 2. **single** (Fastest)
- One arbiter judges all (default: Opus)
- Fastest, lowest cost
- Potential bias
- **Use for**: Quick scans, lower-risk code

### 3. **majority** (No Arbiter Overhead)
- Simple vote count, no arbiter
- Very fast, democratic
- **Use for**: Clear-cut issues, speed priority

### 4. **weighted** (Confidence-Based)
- Votes weighted by confidence scores
- Higher confidence = more influence
- Quality-aware
- **Use for**: Complex issues, uncertain cases

### 5. **pairwise** (Balanced)
- Workers review in pairs
- Cross-validation
- Balanced approach
- **Use for**: Medium complexity

## Worker Configuration

### Default Workers
```bash
/code-review  # Uses: opus, sonnet, haiku
```

### Custom Workers
```bash
/code-review --workers=opus,sonnet,haiku,gemini  # 4 models
/code-review --workers=opus,sonnet              # 2 models (faster)
/code-review --workers=opus,haiku               # Skip sonnet
```

## Architecture

```
.claude/workflows/
├── shared/                         ← Reusable infrastructure
│   ├── schemas.js                  ← Standard JSON schemas
│   ├── consensus-engine.js         ← Multi-model voting (5 strategies)
│   ├── platform-detector.js        ← GitHub/GitLab/Bitbucket detection
│   ├── ai-attribution.js           ← AI attribution formatting
│   ├── quality-scorer.js           ← Quality scoring (0-100)
│   └── loop-controller.js          ← Loop/continuous patterns
│
├── code-review.js                  ← NEW unified review (replaces auto-review-brutal)
├── pr-review.js                    ← PR review with auto-approve
├── code-solve.js                   ← Auto-resolve issues
├── code-improve.js                 ← Iterative quality improvement
├── ai-prompt.js                    ← Multi-model consensus Q&A
└── auto-review-brutal.js           ← Legacy (use code-review.js instead)
```

## Migration Guide

### From auto-review-brutal

**Before**:
```bash
/auto-review-brutal
```

**Now**:
```bash
/code-review --strategy=rotating
```

**Benefits**:
- ✅ Choose your strategy (rotating, single, majority, weighted, pairwise)
- ✅ Configure workers (opus, sonnet, haiku, gemini)
- ✅ Swap arbiter (any model can be arbiter)
- ✅ Better performance
- ✅ More control

## Features

### Platform Agnostic
- ✅ Auto-detect GitHub/GitLab/Bitbucket
- ✅ Unified API for issue/PR creation
- ✅ Works with `gh`, `glab`, or `bb` CLI tools

### Multi-Model Consensus
- ✅ Opus, Sonnet, Haiku, Gemini support
- ✅ 5 consensus strategies
- ✅ Configurable workers and arbiter
- ✅ Confidence-weighted voting

### Review-Only Mode
- ✅ Creates PRs/issues instead of pushing to main
- ✅ Safe by default
- ✅ Human approval before merge

### AI Attribution
- ✅ Full transparency (which models agreed/disagreed)
- ✅ Consensus scores
- ✅ Rejection reasoning
- ✅ Copyright notices

### Quality Scoring
- ✅ 0-100 quality score
- ✅ Formula: `100 - (critical×10 + high×5 + medium×1)`
- ✅ Convergence detection
- ✅ Target-based stopping

### Loop/Continuous Mode
- ✅ Continuous monitoring
- ✅ Auto-resolve issues while you sleep
- ✅ Auto-approve clean PRs
- ✅ Iterative improvement

## Cost Estimates

| Workflow | Tokens/Run | Cost (Opus) | Use Case |
|----------|------------|-------------|----------|
| code-review (rotating) | ~100k | ~$3.00 | Critical code review |
| code-review (majority) | ~50k | ~$1.50 | Quick scan |
| pr-review | ~80k | ~$2.40 | PR review |
| code-solve | ~50k | ~$1.50 | Issue resolution |
| code-improve (5 iter) | ~250k | ~$7.50 | Quality improvement |
| ai-prompt | ~60k | ~$1.80 | Multi-model Q&A |

### Weekly Costs (Typical)
- 5 PRs reviewed: ~$12
- 10 issues resolved: ~$15
- 1 quality improvement: ~$8
- **Total**: ~$35/week

**ROI**: 20+ hours saved/week (worth $2000+ at $100/hr)

## Real-World Examples

### Example 1: Brutal Review (Most Thorough)
```bash
cd ~/VirtOS
/code-review --strategy=rotating --workers=opus,sonnet,haiku,gemini
# 4 worker models, rotating arbiter, highest quality
```

### Example 2: Fast Review
```bash
cd ~/nexus-java
/code-review --strategy=majority --workers=opus,sonnet
# 2 workers, majority vote, fast and cheap
```

### Example 3: Clear Issue Backlog
```bash
cd ~/platform-java
/code-solve loop
# Resolves ALL open issues automatically
# Creates PRs for each fix
# Runs until backlog empty
```

### Example 4: Add Validation to All Scripts
```bash
cd ~/VirtOS
/code-improve --auto --target-score 90 --path packages/virtos-tools
# Systematically adds validation to 52 scripts
# Creates single PR with all improvements
```

### Example 5: Monitor PRs Continuously
```bash
cd ~/any-project
/pr-review loop --auto-approve --threshold=95
# Checks every 5 minutes
# Auto-approves clean PRs (quality >= 95)
# Runs forever (Ctrl+C to stop)
```

## Best Practices

### Security
- Always review AI-generated fixes before merging
- Use review-only mode (default)
- Validate input before auto-merge

### Cost Optimization
- Use `majority` strategy for quick scans
- Limit workers to 2-3 models for speed
- Use `--path` to target specific directories
- Set iteration limits with `--max-iterations`

### Quality
- Use `rotating` strategy for critical code
- Use `weighted` for complex issues
- Set high thresholds (90+) for auto-approve
- Review consensus scores before accepting

## Troubleshooting

### Issue: "Platform not detected"
```bash
# Install CLI tool
sudo apt install gh      # GitHub
sudo apt install glab    # GitLab
```

### Issue: "Rebase conflicts"
```bash
# Resolve manually
git status
git rebase --continue
# Re-run workflow
```

### Issue: "Token budget exceeded"
```bash
# Reduce workers or use faster strategy
/code-review --strategy=majority --workers=opus,sonnet
```

## Development

### Adding a New Workflow

1. Create workflow file in `.claude/workflows/`
2. Import shared modules:
   ```javascript
   import { ISSUE_SCHEMA } from './shared/schemas.js'
   import { multiModelReview } from './shared/consensus-engine.js'
   import { formatAIAttribution } from './shared/ai-attribution.js'
   import { detectPlatform } from './shared/platform-detector.js'
   ```
3. Define `meta` object with name, description, phases
4. Use `phase()`, `log()`, `agent()`, `pipeline()` functions
5. Test on real project

### Modifying Shared Modules

Changes to `shared/*.js` affect **all workflows** globally. Test thoroughly!

## Documentation

- **code-review-unified.md** - Comprehensive code review guide
- **START_HERE.md** - VirtOS-specific setup (in parent dir)
- **MULTI_MODEL_SETUP.md** - Multi-model consensus architecture

## License

Copyright 2026 FlossWare  
Part of VirtOS AI Review infrastructure

---

**Version**: 2.0 (Unified with Strategies)  
**Last Updated**: 2026-06-03  
**Status**: Production Ready ✅

**Global**: Works on ALL projects (VirtOS, nexus-java, platform-java, etc.)
