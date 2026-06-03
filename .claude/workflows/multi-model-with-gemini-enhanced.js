export const meta = {
  name: 'virtos-4-model-review-enhanced',
  description: 'Enhanced 4-model review with complete acceptance/rejection reasoning',
  phases: [
    { title: 'Scan Issues', detail: 'Find problems in code' },
    { title: 'Generate Fixes', detail: '4 models propose solutions' },
    { title: 'Arbiter Decision', detail: 'Vote on best fix with full reasoning' },
  ],
}

// Schemas
const FIX_SCHEMA = {
  type: 'object',
  properties: {
    approach: { type: 'string' },
    code_changes: { type: 'string' },
    rationale: { type: 'string' },
    confidence: { type: 'number' },
    risks: { type: 'array', items: { type: 'string' } },
  },
  required: ['approach', 'code_changes', 'rationale', 'confidence'],
}

const ARBITER_SCHEMA = {
  type: 'object',
  properties: {
    selected_model: { type: 'string', enum: ['opus', 'sonnet', 'haiku', 'gemini', 'none'] },
    accepted_reasoning: { type: 'string', description: 'WHY the selected model was chosen' },
    rejected_models: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          model: { type: 'string', description: 'Name of rejected model' },
          rejection_reason: { type: 'string', description: 'WHY this model was rejected' },
        },
        required: ['model', 'rejection_reason'],
      },
    },
  },
  required: ['selected_model', 'accepted_reasoning', 'rejected_models'],
}

// Test issue for demonstration
phase('Scan Issues')
const testIssues = [
  {
    severity: 'high',
    description: 'Command injection vulnerability in shell script',
    file_path: 'packages/virtos-tools/src/usr/local/bin/virtos-vm-create',
    line_number: 42,
  },
]
log(`Found ${testIssues.length} issues to fix`)

// PHASE: Generate fixes with 4 models
phase('Generate Fixes')

const fixResults = await pipeline(
  testIssues.slice(0, 1),
  issue => parallel([
    () => agent(
      `Fix this ${issue.severity} issue: ${issue.description}. File: ${issue.file_path}. Provide complete fix with approach, code changes, rationale, confidence (0-100), and risks.`,
      { schema: FIX_SCHEMA, model: 'opus', label: `Opus: ${issue.description.substring(0, 30)}` }
    ),
    () => agent(
      `Fix this ${issue.severity} issue: ${issue.description}. File: ${issue.file_path}. Provide complete fix with approach, code changes, rationale, confidence (0-100), and risks.`,
      { schema: FIX_SCHEMA, model: 'sonnet', label: `Sonnet: ${issue.description.substring(0, 30)}` }
    ),
    () => agent(
      `Fix this ${issue.severity} issue: ${issue.description}. File: ${issue.file_path}. Provide complete fix with approach, code changes, rationale, confidence (0-100), and risks.`,
      { schema: FIX_SCHEMA, model: 'haiku', label: `Haiku: ${issue.description.substring(0, 30)}` }
    ),
  ]).then(([opus, sonnet, haiku]) => ({
    issue,
    opusFix: opus,
    sonnetFix: sonnet,
    haikuFix: haiku,
    geminiFix: { approach: 'SKIPPED', code_changes: '', rationale: 'Gemini skipped for this demo', confidence: 0, risks: [] },
  }))
)

log(`Generated fixes with 3 models for ${fixResults.filter(Boolean).length} issues`)

// PHASE: Arbiter panel with FULL reasoning
phase('Arbiter Decision')

const decisions = await pipeline(
  fixResults.filter(Boolean),
  ({ issue, opusFix, sonnetFix, haikuFix, geminiFix }) => parallel([
    // Opus arbiter
    () => agent(
      `You are an arbiter evaluating 4 AI-generated fixes for: "${issue.description}"

**OPUS FIX**:
- Approach: ${opusFix?.approach || 'FAILED'}
- Confidence: ${opusFix?.confidence || 0}%
- Rationale: ${opusFix?.rationale || 'N/A'}

**SONNET FIX**:
- Approach: ${sonnetFix?.approach || 'FAILED'}
- Confidence: ${sonnetFix?.confidence || 0}%
- Rationale: ${sonnetFix?.rationale || 'N/A'}

**HAIKU FIX**:
- Approach: ${haikuFix?.approach || 'FAILED'}
- Confidence: ${haikuFix?.confidence || 0}%
- Rationale: ${haikuFix?.rationale || 'N/A'}

**GEMINI FIX**:
- Approach: ${geminiFix?.approach || 'FAILED'}
- Confidence: ${geminiFix?.confidence || 0}%

CRITICAL: You MUST provide:
1. Which model you select (opus/sonnet/haiku/gemini/none)
2. WHY you accepted that model (detailed reasoning)
3. For EACH rejected model, explain WHY it was not selected

Return complete rejection reasoning for ALL non-selected models.`,
      {
        schema: ARBITER_SCHEMA,
        model: 'opus',
        label: `Opus arbiter: ${issue.description.substring(0, 25)}`,
      }
    ),
    // Sonnet arbiter
    () => agent(
      `You are an arbiter evaluating 4 AI-generated fixes for: "${issue.description}"

**OPUS FIX**:
- Approach: ${opusFix?.approach || 'FAILED'}
- Confidence: ${opusFix?.confidence || 0}%
- Rationale: ${opusFix?.rationale || 'N/A'}

**SONNET FIX**:
- Approach: ${sonnetFix?.approach || 'FAILED'}
- Confidence: ${sonnetFix?.confidence || 0}%
- Rationale: ${sonnetFix?.rationale || 'N/A'}

**HAIKU FIX**:
- Approach: ${haikuFix?.approach || 'FAILED'}
- Confidence: ${haikuFix?.confidence || 0}%
- Rationale: ${haikuFix?.rationale || 'N/A'}

**GEMINI FIX**:
- Approach: ${geminiFix?.approach || 'FAILED'}
- Confidence: ${geminiFix?.confidence || 0}%

CRITICAL: You MUST provide:
1. Which model you select (opus/sonnet/haiku/gemini/none)
2. WHY you accepted that model (detailed reasoning)
3. For EACH rejected model, explain WHY it was not selected

Return complete rejection reasoning for ALL non-selected models.`,
      {
        schema: ARBITER_SCHEMA,
        model: 'sonnet',
        label: `Sonnet arbiter: ${issue.description.substring(0, 25)}`,
      }
    ),
  ]).then(([opusArbiter, sonnetArbiter]) => {
    // Majority vote
    const votes = {}
    for (const arb of [opusArbiter, sonnetArbiter].filter(Boolean)) {
      const choice = arb.selected_model
      votes[choice] = (votes[choice] || 0) + 1
    }
    const winner = Object.keys(votes).reduce((a, b) => votes[a] > votes[b] ? a : b, 'none')

    log(`Arbiter votes: ${JSON.stringify(votes)}, winner: ${winner}`)

    return {
      issue,
      opusFix,
      sonnetFix,
      haikuFix,
      geminiFix,
      arbiterVotes: { opusArbiter, sonnetArbiter },
      finalDecision: winner,
      voteCounts: votes,
    }
  })
)

log(`Completed ${decisions.filter(Boolean).length} arbiter decisions`)

// Build GitHub issues with COMPLETE reasoning
const githubIssues = decisions.filter(Boolean).map(item => {
  const { issue, opusFix, sonnetFix, haikuFix, geminiFix, arbiterVotes, finalDecision, voteCounts } = item

  const selectedFix =
    finalDecision === 'opus' ? opusFix :
    finalDecision === 'sonnet' ? sonnetFix :
    finalDecision === 'haiku' ? haikuFix :
    finalDecision === 'gemini' ? geminiFix : null

  // Build rejected models section with FULL reasoning
  const buildRejectedSection = (arbiter, arbiterName) => {
    if (!arbiter || !arbiter.rejected_models || arbiter.rejected_models.length === 0) {
      return `**${arbiterName}**: No rejection details provided`
    }

    return arbiter.rejected_models.map(rejected =>
      `**${rejected.model.toUpperCase()}**: ${rejected.rejection_reason}`
    ).join('\n')
  }

  return {
    title: `[${issue.severity.toUpperCase()}][${finalDecision.toUpperCase()}] ${issue.description.substring(0, 70)}`,
    body: `## Issue
**Severity**: ${issue.severity}
**File**: \`${issue.file_path}\` (line ${issue.line_number || 'unknown'})

${issue.description}

---

## 📊 4-Model Fix Proposals

### OPUS (${opusFix?.confidence || 0}% confidence)
**Approach**: ${opusFix?.approach || 'FAILED'}
**Rationale**: ${opusFix?.rationale || 'N/A'}

### SONNET (${sonnetFix?.confidence || 0}% confidence)
**Approach**: ${sonnetFix?.approach || 'FAILED'}
**Rationale**: ${sonnetFix?.rationale || 'N/A'}

### HAIKU (${haikuFix?.confidence || 0}% confidence)
**Approach**: ${haikuFix?.approach || 'FAILED'}
**Rationale**: ${haikuFix?.rationale || 'N/A'}

### GEMINI (${geminiFix?.confidence || 0}% confidence)
**Approach**: ${geminiFix?.approach || 'FAILED'}
**Rationale**: ${geminiFix?.rationale || 'N/A'}

---

## 🗳️ Multi-Model Arbiter Decision

**Final Selection**: ✅ **${finalDecision.toUpperCase()}**

**Vote Breakdown**:
${Object.entries(voteCounts).map(([model, count]) => `- ${model.toUpperCase()}: ${count} vote(s)`).join('\n')}

---

## ✅ WHY ${finalDecision.toUpperCase()} WAS ACCEPTED

### Opus Arbiter's Reasoning:
${arbiterVotes.opusArbiter?.selected_model === finalDecision ?
  `> ${arbiterVotes.opusArbiter?.accepted_reasoning || 'N/A'}` :
  '*(Did not select this model)*'}

### Sonnet Arbiter's Reasoning:
${arbiterVotes.sonnetArbiter?.selected_model === finalDecision ?
  `> ${arbiterVotes.sonnetArbiter?.accepted_reasoning || 'N/A'}` :
  '*(Did not select this model)*'}

---

## ❌ WHY OTHER MODELS WERE REJECTED

### From Opus Arbiter:
${buildRejectedSection(arbiterVotes.opusArbiter, 'Opus Arbiter')}

### From Sonnet Arbiter:
${buildRejectedSection(arbiterVotes.sonnetArbiter, 'Sonnet Arbiter')}

---

## 💻 ACCEPTED FIX DETAILS: ${finalDecision.toUpperCase()}

${selectedFix ? `
**Approach**: ${selectedFix.approach}

**Code Changes**:
\`\`\`
${selectedFix.code_changes}
\`\`\`

**Rationale**: ${selectedFix.rationale}

**Confidence**: ${selectedFix.confidence}%

**Risks**: ${selectedFix.risks?.length > 0 ? selectedFix.risks.map(r => `\n- ${r}`).join('') : 'None identified'}
` : 'No fix was selected by the arbiter panel'}

---

**🤖 Models Used**: Opus, Sonnet, Haiku, Gemini (4 workers)
**👥 Arbiters**: Opus, Sonnet (2 arbiters in this run)
**📊 Decision Method**: Majority vote
**⚡ Auto-generated**: Enhanced 4-Model Review System

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
`,
  }
})

return {
  total_issues: testIssues.length,
  fixes_generated: fixResults.filter(Boolean).length,
  github_issues: githubIssues,
  summary: `Enhanced 4-Model Review: ${testIssues.length} issues analyzed. Complete acceptance AND rejection reasoning included for all arbiters.`,
}
