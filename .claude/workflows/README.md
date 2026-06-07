# Global AI Workflows

**Universal workflows for AI-powered code review, PR review, issue resolution, and quality improvement**

## Overview

This directory contains **global workflows** that work across ALL projects (GitHub, GitLab, Bitbucket).

### 🎯 Core Workflows

1. **code-review.js** - Multi-model code review with configurable consensus strategies
2. **pr-review.js** - Auto PR review with quality scoring and approval
3. **code-solve.js** - Auto-resolve GitHub/GitLab issues
4. **ai-prompt.js** - Multi-model consensus for any user question

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

# Auto-approve if quality >= 90 (--approve implies --post)
/pr-review 42 --post --approve --threshold=90

# Continuous monitoring with auto-approval
/pr-review loop --post --approve --threshold=95
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

#### 4. Code Simplification (Quality Enhancement)
```bash
# Review and simplify code
/simplify

# Simplify with specific effort level
/simplify --effort=high

# Use code-review for comprehensive analysis
/code-review --path packages/virtos-tools
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
├── code-review.js                  ← Unified multi-model code review
├── pr-review.js                    ← PR review with auto-approve
├── code-solve.js                   ← Auto-resolve issues
└── ai-prompt.js                    ← Multi-model consensus Q&A
```

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

### Important: Cost Methodology and Variability

**Disclaimer**: The cost estimates below are approximations based on typical usage patterns with default configurations. **Actual costs will vary significantly** based on:

- **Model Selection**: Different Claude models have different pricing. These estimates assume Claude 3.5 Opus pricing (~$15/MTok input, ~$60/MTok output)
- **PR/Code Size**: Small diffs (100 lines) cost much less; large diffs (5000+ lines) cost significantly more
- **Diff Complexity**: Complex changes require more tokens for analysis
- **Worker Configuration**: Using more models (e.g., 4 workers instead of 3) increases costs proportionally
- **Consensus Strategy**: Different strategies have different token usage:
  - `majority`: Lowest cost (parallel voting)
  - `rotating`: Medium cost (parallel + arbiter)
  - `weighted`: Medium-high cost (parallel + analysis)
  - `pairwise`: High cost (multiple review rounds)
- **Loop Iterations**: Continuous mode (`loop`) may run multiple iterations, multiplying costs
- **Actual Token Counts**: Token usage depends on Claude's tokenizer and may vary between API versions

### Typical Cost Ranges

| Workflow | Min Cost | Typical Cost | Max Cost | Notes |
|----------|----------|--------------|----------|-------|
| code-review (rotating) | $0.80 | $3.00 | $8.00+ | 3 workers + arbiter; scales with diff size |
| code-review (majority) | $0.50 | $1.50 | $5.00+ | 2-3 workers; no arbiter overhead |
| pr-review | $0.60 | $2.40 | $6.00+ | Varies with PR size and complexity |
| code-solve | $0.40 | $1.50 | $4.00+ | Issue-dependent; includes PR creation |
| simplify | $0.30 | $1.20 | $3.00+ | Code complexity dependent |
| ai-prompt | $0.40 | $1.80 | $4.00+ | Question length dependent |

### Cost Estimation Formula

For a single `code-review` run with default configuration:

```
Base Cost = Input Tokens × $0.003 + Output Tokens × $0.012
Worker Cost = Base Cost × Number of Workers
Arbiter Cost = Base Cost × 0.5 (arbiter uses cached input)
Total Cost = (Worker Cost) + (Arbiter Cost for rotating/weighted strategies)
```

**Example**: A typical 2KB diff review
- Estimated input tokens: 8,000 (varies by complexity)
- Estimated output tokens: 2,000 per worker
- 3 workers + arbiter (rotating strategy):
  - Workers: (8000 × $0.003 + 2000 × $0.012) × 3 = $0.096 × 3 = $0.29
  - Arbiter: (8000 × $0.003 + 2000 × $0.012) × 0.5 = $0.048
  - **Total: ~$0.34**

### Weekly Cost Examples

**Conservative Usage** (small diffs, quality strategy):
- 5 PRs reviewed (majority strategy): ~$7.50
- 5 issues resolved: ~$7.50
- 1 simplification run: ~$1.20
- **Total**: ~$16/week

**Moderate Usage** (typical diffs, rotating strategy):
- 10 PRs reviewed (rotating strategy): ~$30
- 10 issues resolved: ~$15
- 2 simplification runs: ~$2.40
- **Total**: ~$47/week

**Continuous Mode** (aggressive monitoring):
- 20 PRs reviewed (4-model review): ~$96
- 20 issues auto-resolved: ~$30
- Daily simplification: ~$8.40
- **Total**: ~$134+/week (depends on loop frequency and max-runs)

### Cost Control Strategies

To keep costs reasonable:

1. **Use Majority Strategy**: `--strategy=majority` saves 40-50% vs rotating
2. **Limit Workers**: `--workers=opus,sonnet` saves 33% vs 3 workers
3. **Target Specific Paths**: `--path src/` reduces unnecessary analysis
4. **Set Loop Limits**: `--max-runs=5 --batch=3` prevents runaway loops
5. **Monitor in Background**: Run continuous mode during off-hours
6. **Use Webhooks**: Trigger reviews only on PR creation, not every push

### ROI Comparison

**Time Value** (assuming $100/hr productivity):
- 1 hour code review saved = $100 ROI vs $2-3 cost = **40x ROI**
- 1 hour debugging saved = $100 ROI vs $1.50 cost = **67x ROI**
- Manual issue resolution = $50+ cost/issue vs $1.50 AI = **30x savings**

**Breakeven Analysis**:
- 30 minutes saved/week at $100/hr = $50/week value
- Cost: ~$16-47/week with moderate usage
- **Breakeven**: 3-5 hours saved per week

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

### Example 4: Simplify All Scripts
```bash
cd ~/VirtOS
/simplify --effort=high --path packages/virtos-tools
# Reviews for reuse, simplification, and efficiency
# Applies improvements automatically
```

### Example 5: Monitor PRs Continuously
```bash
cd ~/any-project
/pr-review loop --post --approve --threshold=95
# Checks every 10 minutes
# Auto-approves clean PRs (quality >= 95)
# Runs until limits reached or stopped (Ctrl+C)
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

- **README.md** - This file (comprehensive workflow guide)
- **shared/README.md** - Shared module documentation  
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
