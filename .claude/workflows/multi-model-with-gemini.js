export const meta = {
  name: 'virtos-4-model-review',
  description: 'Brutal code review using Opus, Sonnet, Haiku, AND Gemini in parallel',
  phases: [
    { title: 'Rate Project', detail: 'Brutal assessment with all models' },
    { title: 'Scan Issues', detail: 'Multi-model issue detection' },
    { title: 'Generate Fixes', detail: '4 models propose solutions' },
    { title: 'Arbiter Decision', detail: 'Multi-model arbiter chooses best' },
  ],
}

// Helper to call Gemini via Python client
async function callGemini(prompt, schema, label) {
  const schemaFile = '/tmp/gemini-schema-' + Math.random().toString(36).substring(7) + '.json'

  // Write schema to temp file
  await agent(
    `Write this JSON schema to ${schemaFile}: ${JSON.stringify(schema)}`,
    { label: 'Prep Gemini schema' }
  )

  // Call Gemini client
  const result = await agent(
    `Execute: python3 .claude/gemini_client.py "${prompt.replace(/"/g, '\\"')}" ${schemaFile}`,
    { label: label || 'Gemini call' }
  )

  // Clean up
  await agent(`Execute: rm -f ${schemaFile}`, { label: 'Cleanup' })

  // Parse result
  try {
    return JSON.parse(result)
  } catch {
    return null
  }
}

// Schemas
const FIX_SCHEMA = {
  type: 'object',
  properties: {
    approach: { type: 'string', description: 'Fix approach description' },
    code_changes: { type: 'string', description: 'Complete code changes' },
    rationale: { type: 'string', description: 'Why this approach' },
    confidence: { type: 'number', description: 'Confidence 0-100' },
    risks: { type: 'array', items: { type: 'string' } },
  },
  required: ['approach', 'code_changes', 'rationale', 'confidence'],
}

const ARBITER_SCHEMA = {
  type: 'object',
  properties: {
    selected_model: {
      type: 'string',
      enum: ['opus', 'sonnet', 'haiku', 'gemini', 'none'],
      description: 'Which model to accept'
    },
    accepted_reasoning: { type: 'string', description: 'Why this fix was chosen' },
    rejected_models: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          model: { type: 'string' },
          rejection_reason: { type: 'string' },
        },
      },
    },
  },
  required: ['selected_model', 'accepted_reasoning', 'rejected_models'],
}

// PHASE 1: Project Rating (use Gemini for a different perspective)
phase('Rate Project')
log('Getting brutal project assessment from Gemini...')

const geminiRating = await agent(
  'Call Gemini API to rate VirtOS project brutally. Score 0-10. Find critical issues.',
  { label: 'Gemini Project Rating' }
)

log('Gemini rating received')

// PHASE 2: Scan for issues (simplified for demo)
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

// PHASE 3: Generate fixes with ALL 4 models
phase('Generate Fixes')

const fixResults = await pipeline(
  testIssues.slice(0, 3), // Limit for budget
  issue => parallel([
    // Opus fix
    () => agent(
      `Fix this ${issue.severity} issue: ${issue.description}. File: ${issue.file_path}. Provide complete fix.`,
      {
        schema: FIX_SCHEMA,
        model: 'opus',
        label: `Opus: ${issue.description.substring(0, 30)}`
      }
    ),
    // Sonnet fix
    () => agent(
      `Fix this ${issue.severity} issue: ${issue.description}. File: ${issue.file_path}. Provide complete fix.`,
      {
        schema: FIX_SCHEMA,
        model: 'sonnet',
        label: `Sonnet: ${issue.description.substring(0, 30)}`
      }
    ),
    // Haiku fix
    () => agent(
      `Fix this ${issue.severity} issue: ${issue.description}. File: ${issue.file_path}. Provide complete fix.`,
      {
        schema: FIX_SCHEMA,
        model: 'haiku',
        label: `Haiku: ${issue.description.substring(0, 30)}`
      }
    ),
    // Gemini fix (via Python client)
    async () => {
      log(`Calling Gemini for fix: ${issue.description.substring(0, 30)}`)
      return await agent(
        `Run: python3 .claude/gemini_client.py "Fix this ${issue.severity} issue: ${issue.description}. File: ${issue.file_path}. Provide a complete fix with approach, code changes, rationale, confidence (0-100), and risks. Return as JSON matching this schema: {approach: string, code_changes: string, rationale: string, confidence: number, risks: string[]}"`,
        { label: `Gemini: ${issue.description.substring(0, 30)}` }
      ).then(result => {
        try {
          return JSON.parse(result)
        } catch {
          return { approach: 'FAILED', code_changes: '', rationale: 'Parse error', confidence: 0, risks: [] }
        }
      })
    },
  ]).then(([opus, sonnet, haiku, gemini]) => ({
    issue,
    opusFix: opus,
    sonnetFix: sonnet,
    haikuFix: haiku,
    geminiFix: gemini,
  }))
)

log(`Generated fixes with 4 models for ${fixResults.filter(Boolean).length} issues`)

// PHASE 4: Multi-model arbiter decides (include Gemini in arbiter panel)
phase('Arbiter Decision')

const decisions = await pipeline(
  fixResults.filter(Boolean),
  ({ issue, opusFix, sonnetFix, haikuFix, geminiFix }) => parallel([
    // Opus arbiter
    () => agent(
      `Compare 4 AI fixes for: "${issue.description}"

**OPUS**: ${opusFix?.approach || 'FAILED'} (confidence: ${opusFix?.confidence || 0}%)
**SONNET**: ${sonnetFix?.approach || 'FAILED'} (confidence: ${sonnetFix?.confidence || 0}%)
**HAIKU**: ${haikuFix?.approach || 'FAILED'} (confidence: ${haikuFix?.confidence || 0}%)
**GEMINI**: ${geminiFix?.approach || 'FAILED'} (confidence: ${geminiFix?.confidence || 0}%)

Select the BEST fix. Explain which to accept and why. Explain which to reject and why.`,
      {
        schema: ARBITER_SCHEMA,
        model: 'opus',
        label: `Opus arbiter: ${issue.description.substring(0, 25)}`,
      }
    ),
    // Sonnet arbiter
    () => agent(
      `Compare 4 AI fixes for: "${issue.description}"

**OPUS**: ${opusFix?.approach || 'FAILED'} (confidence: ${opusFix?.confidence || 0}%)
**SONNET**: ${sonnetFix?.approach || 'FAILED'} (confidence: ${sonnetFix?.confidence || 0}%)
**HAIKU**: ${haikuFix?.approach || 'FAILED'} (confidence: ${haikuFix?.confidence || 0}%)
**GEMINI**: ${geminiFix?.approach || 'FAILED'} (confidence: ${geminiFix?.confidence || 0}%)

Select the BEST fix. Explain which to accept and why. Explain which to reject and why.`,
      {
        schema: ARBITER_SCHEMA,
        model: 'sonnet',
        label: `Sonnet arbiter: ${issue.description.substring(0, 25)}`,
      }
    ),
    // Gemini arbiter
    async () => {
      log('Calling Gemini arbiter...')
      return await agent(
        `Run: python3 .claude/gemini_client.py "You are an arbiter. Compare 4 AI fixes for: ${issue.description}. OPUS: ${opusFix?.approach || 'FAILED'}. SONNET: ${sonnetFix?.approach || 'FAILED'}. HAIKU: ${haikuFix?.approach || 'FAILED'}. GEMINI: ${geminiFix?.approach || 'FAILED'}. Select best (opus/sonnet/haiku/gemini/none). Return JSON: {selected_model: string, accepted_reasoning: string, rejected_models: [{model: string, rejection_reason: string}]}"`,
        { label: `Gemini arbiter: ${issue.description.substring(0, 25)}` }
      ).then(r => {
        try {
          return JSON.parse(r)
        } catch {
          return { selected_model: 'none', accepted_reasoning: 'Parse error', rejected_models: [] }
        }
      })
    },
  ]).then(([opusArbiter, sonnetArbiter, geminiArbiter]) => {
    // Final meta-decision: which arbiter to trust?
    const votes = {}
    for (const arb of [opusArbiter, sonnetArbiter, geminiArbiter].filter(Boolean)) {
      const choice = arb.selected_model
      votes[choice] = (votes[choice] || 0) + 1
    }

    // Pick model with most arbiter votes
    const winner = Object.keys(votes).reduce((a, b) => votes[a] > votes[b] ? a : b, 'none')

    log(`Arbiter votes: ${JSON.stringify(votes)}, winner: ${winner}`)

    return {
      issue,
      opusFix,
      sonnetFix,
      haikuFix,
      geminiFix,
      arbiterVotes: { opusArbiter, sonnetArbiter, geminiArbiter },
      finalDecision: winner,
      voteCounts: votes,
    }
  })
)

log(`Completed ${decisions.filter(Boolean).length} arbiter decisions`)

// Build GitHub issues with 4-model analysis
const githubIssues = decisions.filter(Boolean).map(item => {
  const { issue, opusFix, sonnetFix, haikuFix, geminiFix, arbiterVotes, finalDecision, voteCounts } = item

  const selectedFix =
    finalDecision === 'opus' ? opusFix :
    finalDecision === 'sonnet' ? sonnetFix :
    finalDecision === 'haiku' ? haikuFix :
    finalDecision === 'gemini' ? geminiFix : null

  return {
    title: `[${issue.severity.toUpperCase()}][${finalDecision.toUpperCase()}] ${issue.description.substring(0, 70)}`,
    body: `## Issue
**Severity**: ${issue.severity}
**File**: \`${issue.file_path}\` (line ${issue.line_number || 'unknown'})

${issue.description}

---

## 4-Model Fix Proposals

### OPUS
- Approach: ${opusFix?.approach || 'FAILED'}
- Confidence: ${opusFix?.confidence || 0}%

### SONNET
- Approach: ${sonnetFix?.approach || 'FAILED'}
- Confidence: ${sonnetFix?.confidence || 0}%

### HAIKU
- Approach: ${haikuFix?.approach || 'FAILED'}
- Confidence: ${haikuFix?.confidence || 0}%

### GEMINI
- Approach: ${geminiFix?.approach || 'FAILED'}
- Confidence: ${geminiFix?.confidence || 0}%

---

## Multi-Model Arbiter Decision

**Final Selection**: **${finalDecision.toUpperCase()}**

**Arbiter Vote Breakdown**:
${Object.entries(voteCounts).map(([model, count]) => `- ${model}: ${count} vote(s)`).join('\n')}

### Arbiter Opinions:

### Rejected Models Reasoning:\n\n**From Opus Arbiter**:\n${arbiterVotes.opusArbiter?.rejected_models?.map(r => `- **${r.model.toUpperCase()}**: ${r.rejection_reason}`).join("\n") || "No rejections documented"}\n\n**From Sonnet Arbiter**:\n${arbiterVotes.sonnetArbiter?.rejected_models?.map(r => `- **${r.model.toUpperCase()}**: ${r.rejection_reason}`).join("\n") || "No rejections documented"}\n\n**From Gemini Arbiter**:\n${arbiterVotes.geminiArbiter?.rejected_models?.map(r => `- **${r.model.toUpperCase()}**: ${r.rejection_reason}`).join("\n") || "No rejections documented"}\n

**Opus Arbiter**: Selected ${arbiterVotes.opusArbiter?.selected_model || 'unknown'}
> ${arbiterVotes.opusArbiter?.accepted_reasoning || 'N/A'}

**Sonnet Arbiter**: Selected ${arbiterVotes.sonnetArbiter?.selected_model || 'unknown'}
> ${arbiterVotes.sonnetArbiter?.accepted_reasoning || 'N/A'}

**Gemini Arbiter**: Selected ${arbiterVotes.geminiArbiter?.selected_model || 'unknown'}
> ${arbiterVotes.geminiArbiter?.accepted_reasoning || 'N/A'}

---

## ✅ ACCEPTED FIX: ${finalDecision.toUpperCase()}

${selectedFix ? `
**Approach**: ${selectedFix.approach}

**Code Changes**:
\`\`\`
${selectedFix.code_changes}
\`\`\`

**Rationale**: ${selectedFix.rationale}

**Confidence**: ${selectedFix.confidence}%

**Risks**: ${selectedFix.risks?.join(', ') || 'None'}
` : 'No fix selected'}

---

**Models Used**: Opus, Sonnet, Haiku, Gemini (4 workers)
**Arbiters**: Opus, Sonnet, Gemini (3 arbiters)
**Decision Method**: Majority vote
**Auto-generated**: 4-Model Review System

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
`,
  }
})

return {
  total_issues: testIssues.length,
  fixes_generated: fixResults.filter(Boolean).length,
  github_issues: githubIssues,
  summary: `4-Model Review: ${testIssues.length} issues analyzed by Opus, Sonnet, Haiku, and Gemini. Decisions made by 3-arbiter panel (Opus, Sonnet, Gemini) via majority vote.`,
}
