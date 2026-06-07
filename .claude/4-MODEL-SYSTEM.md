# 4-Model Code Review System with Gemini

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ISSUE DETECTION                          │
│  (Shell, Python, Java scans via existing scripts)          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              4 WORKER AIs GENERATE FIXES                    │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  OPUS    │  │ SONNET   │  │  HAIKU   │  │ GEMINI   │  │
│  │  Fix A   │  │  Fix B   │  │  Fix C   │  │  Fix D   │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
│                                                             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│           3 ARBITER AIs VOTE ON BEST FIX                    │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ Opus Arbiter │  │Sonnet Arbiter│  │Gemini Arbiter│    │
│  │ Chooses: B   │  │ Chooses: B   │  │ Chooses: A   │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
│         MAJORITY VOTE → Fix B (Sonnet) WINS               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              GITHUB ISSUE CREATED                           │
│                                                             │
│  - Shows all 4 proposed fixes                              │
│  - Shows 3 arbiter opinions                                │
│  - Shows vote breakdown                                    │
│  - Shows final selection with reasoning                    │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Worker AIs (4 models)

Each issue receives **4 independent fix proposals**:

- **Opus** (Claude): Highest capability, complex reasoning
- **Sonnet** (Claude): Balanced quality/speed
- **Haiku** (Claude): Fast, efficient
- **Gemini** (Google): Different training, different perspective

Each worker provides:

- Fix approach
- Complete code changes
- Rationale for approach
- Confidence level (0-100%)
- Potential risks

### 2. Arbiter Panel (3 models)

Three independent arbiters **vote** on best fix:

- **Opus Arbiter**: Evaluates all 4 fixes, selects best
- **Sonnet Arbiter**: Independent evaluation, selects best
- **Gemini Arbiter**: External perspective, selects best

**Decision Method**: Majority vote

- If 2+ arbiters agree → that fix wins
- If 3-way split → highest confidence fix wins
- Ties broken by confidence scores

### 3. Gemini Integration

**File**: `.claude/gemini_client.py`

Python client that calls Google Gemini API:

```python
call_gemini(prompt, schema=None)
```

**Environment Variable Required**:

```bash
export GEMINI_API_KEY="your-api-key"
```

**Model Used**: `gemini-1.5-pro-latest` (configurable via `GEMINI_MODEL`)

## GitHub Issue Format

Each issue shows complete transparency:

```markdown
## Issue
[Problem description]

## 4-Model Fix Proposals

### OPUS
- Approach: [description]
- Confidence: 85%

### SONNET  
- Approach: [description]
- Confidence: 90%

### HAIKU
- Approach: [description]
- Confidence: 75%

### GEMINI
- Approach: [description]
- Confidence: 88%

## Multi-Model Arbiter Decision

**Final Selection**: SONNET

**Arbiter Vote Breakdown**:
- sonnet: 2 votes
- opus: 1 vote

### Arbiter Opinions:

**Opus Arbiter**: Selected sonnet
> Sonnet's approach is more robust and handles edge cases better

**Sonnet Arbiter**: Selected sonnet  
> My own solution provides the best balance of safety and simplicity

**Gemini Arbiter**: Selected opus
> Opus solution is more comprehensive, though Sonnet's is safer

## ✅ ACCEPTED FIX: SONNET

**Code Changes**:
[Complete fix code]

**Rationale**: [Why this approach]
**Confidence**: 90%
**Risks**: [List of risks]

---
Models Used: Opus, Sonnet, Haiku, Gemini (4 workers)
Arbiters: Opus, Sonnet, Gemini (3 arbiters)  
Decision Method: Majority vote
```

## Setup Requirements

### 1. Gemini API Key

```bash
# Add to your shell profile
export GEMINI_API_KEY="AIza..."

# Or add to .claude/settings.json env vars
```

### 2. Python Dependencies

```bash
pip install requests
```

### 3. Workflow File

**Location**: `VirtOS/.claude/workflows/multi-model-with-gemini.js`

## Usage

### Run 4-Model Review

```javascript
// Via Workflow tool
Workflow({
  scriptPath: '/home/sfloess/Development/github/FlossWare/VirtOS/.claude/workflows/multi-model-with-gemini.js'
})
```

### Test Gemini Client

```bash
cd /home/sfloess/Development/github/FlossWare/VirtOS

# Simple prompt
python3 .claude/gemini_client.py "Rate this code quality 0-10"

# With JSON schema
python3 .claude/gemini_client.py \
  "Find security issues" \
  schema.json
```

## Benefits of 4-Model System

### Diversity

- **Claude models**: Different capability tiers
- **Gemini**: Different training data, architecture, perspective
- **Result**: More comprehensive coverage, fewer blind spots

### Robustness

- Single model bias eliminated
- Consensus-based decisions
- Multiple independent evaluations

### Transparency

- All proposals documented
- All arbiter opinions shown
- Vote breakdown visible
- User can verify decision quality

### Quality Control

- 3 arbiters provide checks and balances
- Majority vote prevents outlier selection
- Confidence scores influence ties

## Example Arbiter Scenarios

### Scenario 1: Clear Consensus

```
Opus Arbiter → selects Sonnet
Sonnet Arbiter → selects Sonnet
Gemini Arbiter → selects Sonnet
Result: SONNET (3/3 unanimous)
```

### Scenario 2: Split Decision

```
Opus Arbiter → selects Opus (90% confidence)
Sonnet Arbiter → selects Gemini (85% confidence)
Gemini Arbiter → selects Gemini (88% confidence)
Result: GEMINI (2/3 majority)
```

### Scenario 3: Three-Way Split

```
Opus Arbiter → selects Opus (92% confidence)
Sonnet Arbiter → selects Sonnet (88% confidence)
Gemini Arbiter → selects Gemini (85% confidence)
Result: OPUS (highest confidence wins tie)
```

## Cost Considerations

**Claude API**: Charged per token

- Opus: Most expensive, best quality
- Sonnet: Mid-tier pricing
- Haiku: Cheapest, fastest

**Gemini API**:

- Free tier: 60 requests/minute
- Paid tier: Variable pricing
- Generally cheaper than Claude Opus

**Budget Control**: Use workflow `budget` parameter to limit spending

## Continuous Review Integration

The 4-model system integrates with existing continuous review:

1. **Cron triggers** every 10 minutes
2. **Scans detect** issues (Shell, Python, Java)
3. **4 workers generate** fixes in parallel
4. **3 arbiters vote** on best fix
5. **GitHub issue created** with full transparency
6. **Auto-fix safe issues** (formatting, imports)
7. **Auto-commit and push** with co-author signature

## Monitoring

Check workflow progress:

```
/workflows
```

View logs:

```bash
tail -f /tmp/virtos-*.log
```

Check GitHub issues:

```bash
gh issue list --label "multi-model-review"
```

---

**Created**: 2026-06-03
**Status**: ✅ Active
**Worker AIs**: 4 (Opus, Sonnet, Haiku, Gemini)
**Arbiters**: 3 (Opus, Sonnet, Gemini)
**Decision Method**: Majority vote
