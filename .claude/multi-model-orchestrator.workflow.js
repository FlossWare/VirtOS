export const meta = {
  name: 'multi-model-code-review',
  description: 'Brutal code review using Opus, Sonnet, and Haiku in parallel',
  phases: [
    { title: 'Scan', detail: 'Find all issues across Python, Java, Shell', model: 'sonnet' },
    { title: 'Analyze', detail: 'Multi-model analysis of each issue', model: 'opus' },
    { title: 'Fix', detail: 'Generate fixes with all models', model: 'opus' },
    { title: 'Select', detail: 'Choose best fix and document decision' },
    { title: 'Test', detail: 'Run tests and create issues for failures' },
  ],
}

// Project rating schema
const PROJECT_RATING_SCHEMA = {
  type: 'object',
  properties: {
    overall_score: { type: 'number', minimum: 0, maximum: 10 },
    code_quality: { type: 'number', minimum: 0, maximum: 10 },
    security: { type: 'number', minimum: 0, maximum: 10 },
    maintainability: { type: 'number', minimum: 0, maximum: 10 },
    documentation: { type: 'number', minimum: 0, maximum: 10 },
    test_coverage: { type: 'number', minimum: 0, maximum: 10 },
    critical_issues: { type: 'array', items: { type: 'string' } },
    major_issues: { type: 'array', items: { type: 'string' } },
    recommendations: { type: 'array', items: { type: 'string' } },
    brutal_assessment: { type: 'string' },
  },
  required: ['overall_score', 'brutal_assessment'],
}

// Issue analysis schema
const ISSUE_SCHEMA = {
  type: 'object',
  properties: {
    severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
    category: { type: 'string' },
    file_path: { type: 'string' },
    line_number: { type: 'number' },
    description: { type: 'string' },
    impact: { type: 'string' },
    recommendation: { type: 'string' },
  },
  required: ['severity', 'description', 'recommendation'],
}

// Fix proposal schema
const FIX_SCHEMA = {
  type: 'object',
  properties: {
    approach: { type: 'string' },
    code_changes: { type: 'string' },
    test_plan: { type: 'string' },
    risks: { type: 'array', items: { type: 'string' } },
    confidence: { type: 'number', minimum: 0, maximum: 100 },
    reasoning: { type: 'string' },
  },
  required: ['approach', 'code_changes', 'confidence', 'reasoning'],
}

// PHASE 1: Brutal project rating
phase('Scan')
log('Starting brutal code review - no mercy!')

const rating = await agent(
  'Rate the VirtOS project brutally. Be harsh and critical. Find EVERY flaw. Check Python, Java, and Shell code. Look for security issues, code smells, technical debt, poor practices, missing tests, bad documentation. Give scores 0-10 (10 = perfect, rarely deserved). Be specific about what is wrong.',
  { schema: PROJECT_RATING_SCHEMA, model: 'opus', label: 'Project Rating' }
)

log(`Project rated: ${rating.overall_score}/10 - ${rating.critical_issues.length} critical issues found`)

// PHASE 2: Find all issues using multiple scanners in parallel
phase('Analyze')

const scanners = [
  {
    name: 'Python Security',
    prompt: 'Scan ALL Python files for security vulnerabilities. Use bandit-level scrutiny. Find: SQL injection, command injection, path traversal, hardcoded secrets, insecure crypto, XXE, SSRF, unsafe deserialization, etc. Be paranoid.',
    model: 'opus',
  },
  {
    name: 'Python Quality',
    prompt: 'Review ALL Python files for code quality issues. Find: type errors, unused imports, dead code, complexity violations, naming issues, missing docstrings, poor error handling, etc. Be picky.',
    model: 'sonnet',
  },
  {
    name: 'Java Security',
    prompt: 'Scan ALL Java files for security vulnerabilities. Find: injection flaws, XXE, insecure deserialization, broken auth, sensitive data exposure, broken access control, etc. Be thorough.',
    model: 'opus',
  },
  {
    name: 'Java Quality',
    prompt: 'Review ALL Java files for code quality. Find: null pointer risks, resource leaks, concurrency issues, exception handling problems, code duplication, etc. Be critical.',
    model: 'sonnet',
  },
  {
    name: 'Shell Security',
    prompt: 'Scan ALL shell scripts for security issues. Find: command injection, path traversal, privilege escalation, unsafe eval, hardcoded credentials, race conditions, etc. Be paranoid.',
    model: 'opus',
  },
  {
    name: 'Shell Quality',
    prompt: 'Review ALL shell scripts for quality issues. Find: missing error handling, unsafe variable usage, shellcheck violations, poor quoting, missing validation, etc. Be strict.',
    model: 'sonnet',
  },
]

const allIssues = await pipeline(
  scanners,
  scanner => agent(scanner.prompt, {
    schema: { type: 'object', properties: { issues: { type: 'array', items: ISSUE_SCHEMA } } },
    model: scanner.model,
    label: scanner.name,
    phase: 'Analyze',
  })
)

const flatIssues = allIssues.filter(Boolean).flatMap(r => r.issues || [])
log(`Found ${flatIssues.length} total issues across all scanners`)

// PHASE 3: For each issue, get fix proposals from ALL models
phase('Fix')

const issueFixes = await pipeline(
  flatIssues.slice(0, 20), // Limit to first 20 issues to conserve budget
  issue => parallel([
    () => agent(
      `Fix this ${issue.severity} issue: ${issue.description}. File: ${issue.file_path}. Provide a complete fix with code changes.`,
      { schema: FIX_SCHEMA, model: 'opus', label: `Opus fix: ${issue.description.substring(0, 40)}`, phase: 'Fix' }
    ),
    () => agent(
      `Fix this ${issue.severity} issue: ${issue.description}. File: ${issue.file_path}. Provide a complete fix with code changes.`,
      { schema: FIX_SCHEMA, model: 'sonnet', label: `Sonnet fix: ${issue.description.substring(0, 40)}`, phase: 'Fix' }
    ),
    () => agent(
      `Fix this ${issue.severity} issue: ${issue.description}. File: ${issue.file_path}. Provide a complete fix with code changes.`,
      { schema: FIX_SCHEMA, model: 'haiku', label: `Haiku fix: ${issue.description.substring(0, 40)}`, phase: 'Fix' }
    ),
  ]).then(fixes => ({ issue, opusFix: fixes[0], sonnetFix: fixes[1], haikuFix: fixes[2] }))
)

// PHASE 4: Select best fix for each issue
phase('Select')

const decisions = await pipeline(
  issueFixes,
  ({ issue, opusFix, sonnetFix, haikuFix }) => agent(
    `Compare these 3 fixes for: ${issue.description}

Opus approach: ${opusFix?.approach || 'FAILED'} (confidence: ${opusFix?.confidence || 0}%)
Sonnet approach: ${sonnetFix?.approach || 'FAILED'} (confidence: ${sonnetFix?.confidence || 0}%)
Haiku approach: ${haikuFix?.approach || 'FAILED'} (confidence: ${haikuFix?.confidence || 0}%)

Choose the BEST fix. Explain which model's solution to accept and why. Explain which models to reject and why.`,
    {
      schema: {
        type: 'object',
        properties: {
          selected_model: { type: 'string', enum: ['opus', 'sonnet', 'haiku'] },
          accepted_reasoning: { type: 'string' },
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
      },
      label: `Select best fix: ${issue.description.substring(0, 30)}`,
      phase: 'Select',
    }
  ).then(decision => ({ issue, opusFix, sonnetFix, haikuFix, decision }))
)

// PHASE 5: Create GitHub issues with model decision documentation
phase('Test')

const issuesCreated = []

for (const item of decisions.filter(Boolean)) {
  const { issue, opusFix, sonnetFix, haikuFix, decision } = item
  const selectedFix = decision.selected_model === 'opus' ? opusFix :
                      decision.selected_model === 'sonnet' ? sonnetFix : haikuFix

  const issueBody = `## Issue
**Severity**: ${issue.severity}
**Category**: ${issue.category || 'General'}
**File**: \`${issue.file_path || 'unknown'}\`${issue.line_number ? ` (line ${issue.line_number})` : ''}

${issue.description}

**Impact**: ${issue.impact || 'Not specified'}

## Multi-Model Fix Analysis

### ✅ ACCEPTED: ${decision.selected_model.toUpperCase()}
**Reasoning**: ${decision.accepted_reasoning}

**Approach**: ${selectedFix?.approach || 'N/A'}
**Confidence**: ${selectedFix?.confidence || 0}%

\`\`\`
${selectedFix?.code_changes || 'No code provided'}
\`\`\`

### ❌ REJECTED MODELS
${decision.rejected_models.map(r => `- **${r.model.toUpperCase()}**: ${r.rejection_reason}`).join('\n')}

## Test Plan
${selectedFix?.test_plan || 'Manual verification required'}

## Risks
${selectedFix?.risks?.map(r => `- ${r}`).join('\n') || 'None identified'}

---
**Auto-generated**: Multi-Model Code Review
**Models used**: Opus, Sonnet, Haiku
**Selected**: ${decision.selected_model}
**Priority**: P${issue.severity === 'critical' ? '0' : issue.severity === 'high' ? '1' : issue.severity === 'medium' ? '2' : '3'}

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
`

  issuesCreated.push({
    title: `[${issue.severity.toUpperCase()}] ${issue.description.substring(0, 80)}`,
    body: issueBody,
    severity: issue.severity,
    selected_model: decision.selected_model,
  })
}

log(`Prepared ${issuesCreated.length} issues for creation`)

// Return results for orchestrator to handle
return {
  rating,
  total_issues: flatIssues.length,
  issues_created: issuesCreated,
  summary: `Project Score: ${rating.overall_score}/10. Found ${flatIssues.length} issues, created ${issuesCreated.length} detailed issue reports with multi-model analysis.`,
}
