// Code Review - Unified multi-model code review
// Unified multi-model code review with configurable consensus strategies
// Supports all consensus strategies with configurable workers/arbiter

import { ISSUE_SCHEMA, REVIEW_SCHEMA } from './shared/schemas.js'
import { multiModelReview, arbiterDecision, validateStrategy, VALID_STRATEGIES, validateArbiterModel, validateWorkers, validateWorkersAllowlist, KNOWN_MODELS, formatWorkersList } from './shared/consensus-engine.js'
import { formatAIAttribution } from './shared/ai-attribution.js'
import { detectPlatform, syncWithRemote, createIssue } from './shared/platform-detector.js'
import { calculateQualityScore, formatQualityReport } from './shared/quality-scorer.js'
// Issue #511: Import sanitization for defense-in-depth on arbiter context
import { sanitizePromptInput } from './shared/prompt-sanitizer.js'

export const meta = {
  name: 'code-review',
  description: 'Multi-model code review with configurable consensus strategies',
  whenToUse: 'When user wants code review with AI consensus voting',
  phases: [
    { title: 'Setup', detail: 'Sync and configure strategy' },
    { title: 'Scan', detail: 'Find issues in code' },
    { title: 'Multi-Model Review', detail: 'Worker models review', model: 'opus' },
    { title: 'Arbiter Decision', detail: 'Consensus voting' },
    { title: 'Results', detail: 'Create issues or report' },
  ],
}

// Parse arguments
// FIX #414: Use nullish coalescing (??) instead of OR (||) to allow falsy but valid values
const strategy = args?.strategy ?? args?.['--strategy'] ?? 'rotating'

// Validate strategy against known strategies
const strategyValidation = validateStrategy(strategy)
if (!strategyValidation.valid) {
  log(`ERROR: ${strategyValidation.message}`)
  return { status: 'error', message: strategyValidation.message }
}

// FIX #414: Use nullish coalescing (??) instead of OR (||) to allow falsy but valid values
const rawArbiterModel = args?.arbiter ?? args?.['--arbiter'] ?? null
// FIX #435: Coerce workersArg to string before .split() to prevent TypeError
// if args?.workers is a non-string type (e.g., array, number, object).
// FIX #414: Use nullish coalescing (??) instead of OR (||) to allow falsy but valid values
const workersArgRaw = args?.workers ?? args?.['--workers'] ?? 'opus,sonnet,haiku'
const workersArg = typeof workersArgRaw === 'string' ? workersArgRaw : String(workersArgRaw)

// ISSUE #527, FIX #435: Validate workers argument contains only valid model names
// =========================================================================
// The workers argument is parsed from comma-separated user input. Without
// validation, malicious model names (e.g., --workers='opus,$(evil)') could be
// injected and passed to agent() calls. The validateWorkers() function enforces
// an alphanumeric+hyphen+underscore+dot regex that rejects shell metacharacters
// ($, `, ;, |, etc.), preventing command injection. Also filters out empty strings
// from split operations (e.g., "".split(',') -> [''] instead of []).
const workersRaw = workersArg.split(',').map(w => w.trim()).filter(w => w.length > 0)

const workersValidation = validateWorkers(workersRaw)
if (!workersValidation.valid) {
  log('')
  log('═'.repeat(60))
  log('INVALID WORKERS')
  log('═'.repeat(60))
  log(`Error: ${workersValidation.message}`)
  log('')
  log(`Valid model names must contain only:`)
  log(`  - Alphanumeric characters (a-z, A-Z, 0-9)`)
  log(`  - Hyphens (-), underscores (_), and dots (.)`)
  log(`  - Max 100 characters each`)
  log('')
  log('Usage Examples:')
  log(`  /code-review --workers=opus,sonnet,haiku`)
  log(`  /code-review --workers=gpt-4,claude-3.5-sonnet`)
  log(`  /code-review --workers=gemini`)
  log('═'.repeat(60))
  return {
    status: 'error',
    message: workersValidation.message,
  }
}
// FIX #421: Validate workers against the centralized KNOWN_MODELS allowlist from
// consensus-engine.js. Format validation (above) only checks syntax; this checks
// that model names are actually recognized. Provides clear upfront error messages
// instead of cryptic runtime errors from the agent infrastructure.
const allowlistValidation = validateWorkersAllowlist(workersValidation.sanitized)
if (!allowlistValidation.valid) {
  log('')
  log('═'.repeat(60))
  log('UNRECOGNIZED WORKER MODELS')
  log('═'.repeat(60))
  log(`Error: ${allowlistValidation.message}`)
  log('')
  log(`Recognized models: ${KNOWN_MODELS.join(', ')}`)
  log('')
  log('Usage Examples:')
  log(`  /code-review --workers=opus,sonnet,haiku`)
  log(`  /code-review --workers=opus,gemini`)
  log('═'.repeat(60))
  return {
    status: 'error',
    message: allowlistValidation.message,
  }
}
if (allowlistValidation.rejected.length > 0) {
  log(`WARNING: ${allowlistValidation.message}`)
}
const workers = allowlistValidation.accepted

const shouldCreateIssues = args?.['create-issues'] !== false
const shouldSync = args?.sync !== false
// FIX #414: Use nullish coalescing (??) instead of OR (||) to allow falsy but valid values
const targetPath = args?.path ?? args?.['--path'] ?? '.'

// ISSUE #510, #361 FIX: Validate arbiter model parameter to prevent log injection
// and enforce allowlist to prevent arbitrary model name injection.
// ===================================================================
// Early validation of the arbiter parameter ensures user gets immediate
// feedback if they pass invalid input. Without this, arbitrary user input
// could be logged unvalidated (log injection vector) or pass unrecognized
// model names to downstream functions.
let arbiterModel = null
if (rawArbiterModel) {
  const arbiterValidation = validateArbiterModel(rawArbiterModel)
  if (!arbiterValidation.valid) {
    log('')
    log('═'.repeat(60))
    log('INVALID ARBITER MODEL')
    log('═'.repeat(60))
    log(`Error: ${arbiterValidation.message}`)
    log('')
    log(`Arbiter model must be alphanumeric with hyphens/underscores/dots, max 100 chars`)
    log('Examples: opus, sonnet, haiku, gpt-4, claude-3.5-sonnet')
    log('═'.repeat(60))
    return {
      status: 'error',
      message: arbiterValidation.message,
    }
  }
  arbiterModel = arbiterValidation.sanitized
}

log('')
log('═'.repeat(60))
log('Multi-Model Code Review')
log('═'.repeat(60))
log(`Strategy: ${strategy}`)
// FIX #359: Use formatWorkersList for safe log output that handles empty/malformed arrays
log(`Workers: ${formatWorkersList(workers)}`)
log(`Arbiter: ${arbiterModel || 'auto (based on strategy)'}`)
log(`Path: ${targetPath}`)
log(`Create Issues: ${shouldCreateIssues ? 'YES' : 'NO'}`)
log('═'.repeat(60))
log('')

// PHASE 1: Setup
phase('Setup')

let platform = null

if (shouldCreateIssues) {
  log('🔧 Detecting platform...')
  platform = await detectPlatform(agent)
  log(`✅ Platform: ${platform.platform} (using ${platform.cli})`)
}

if (shouldSync) {
  log('📥 Syncing with remote...')
  const syncResult = await syncWithRemote(agent)

  if (syncResult.status === 'not_clean') {
    log(`⚠️ Working tree has uncommitted changes: ${syncResult.message}`)
    return { status: 'not_clean', message: 'Commit or stash changes before syncing' }
  }

  if (syncResult.status === 'branch_mismatch') {
    log(`⚠️ Branch mismatch: ${syncResult.message}`)
    return { status: 'branch_mismatch', message: syncResult.message }
  }

  if (syncResult.status === 'diverged') {
    log(`⚠️ Local and remote have diverged: ${syncResult.message}`)
    return { status: 'diverged', message: 'Local and remote branches have diverged. Resolve manually.' }
  }

  if (syncResult.status === 'failed') {
    log(`❌ Failed to sync with remote: ${syncResult.message}`)
    return { status: 'failed', error: syncResult.message }
  }

  log(`✅ ${syncResult.status === 'up_to_date' ? 'Up to date' : 'Synced'}`)
}

// PHASE 2: Scan
phase('Scan')

log(`🔍 Scanning ${targetPath}...`)

const scanResult = await agent(`Scan the code for issues.

Target: ${targetPath}

Focus on:
- Security vulnerabilities
- Code quality issues
- Bug patterns
- Critical style violations

Return structured list with evidence and confidence.
Avoid false positives.`, {
  label: 'Scan Code',
  schema: {
    type: 'object',
    properties: {
      issues: { type: 'array', items: ISSUE_SCHEMA },
      files_scanned: { type: 'number' },
    },
    required: ['issues'],
  }
})

const issues = scanResult.issues || []
log(`Found ${issues.length} potential issues`)

if (issues.length === 0) {
  log('✅ No issues found - code is clean!')
  return {
    status: 'success',
    issues_found: 0,
    strategy,
  }
}

// PHASE 3: Multi-Model Review
phase('Multi-Model Review')

log(`🤖 Running ${strategy} strategy review on ${Math.min(issues.length, 10)} issues...`)

const reviewedIssues = await pipeline(
  issues.slice(0, 10), // Limit to 10 for cost
  issue => multiModelReview(
    `Review this potential issue:

**Issue**: ${issue.description}
**File**: ${issue.file_path}:${issue.line_number || '?'}
**Severity**: ${issue.severity}
**Evidence**: ${issue.evidence || 'See code'}

Analyze: Is this real or false positive?
Provide confidence score.`,
    REVIEW_SCHEMA,
    {
      workers,
      strategy,
      arbiterModel,
      phase: 'Multi-Model Review',
      labelPrefix: issue.category,
    }
  ).then(reviews => ({ issue, reviews }))
)

log(`✅ Multi-model review complete`)

// PHASE 4: Arbiter Decision
phase('Arbiter Decision')

log(`⚖️ Arbiter making decisions (${strategy} strategy)...`)

// Issue #511: Sanitize issue context before passing to arbiter (defense-in-depth)
// Issue #609: Wrap arbiterDecision in try-catch to handle arbiter selection failures
// (e.g., selectArbiter() returning undefined from pool degradation). Without this,
// the Error thrown at consensus-engine.js:288 propagates uncaught and crashes the workflow.
const decisions = await pipeline(
  reviewedIssues.filter(Boolean),
  ({ issue, reviews }) => {
    try {
      return arbiterDecision(
        `${sanitizePromptInput(issue.description, 500)} (${sanitizePromptInput(issue.file_path, 200)})`,
        reviews,
        {
          strategy,
          arbiterModel,
          decisionType: 'issue',
          phase: 'Arbiter Decision',
        }
      ).then(decision => ({
        issue,
        reviews,
        decision,
      })).catch(error => {
        log(`❌ Arbiter decision failed for issue "${issue.description}": ${error.message}`)
        return {
          issue,
          reviews,
          decision: null,
        }
      })
    } catch (error) {
      log(`❌ Arbiter decision failed for issue "${issue.description}": ${error.message}`)
      return {
        issue,
        reviews,
        decision: null,
      }
    }
  }
)

log(`✅ Decisions complete`)

// PHASE 5: Results
phase('Results')

const realIssues = decisions.filter(d => d.decision?.final_decision === 'real_issue')
const falsePositives = decisions.filter(d => d.decision?.final_decision === 'false_positive')

log('')
log('═'.repeat(60))
log('📊 Code Review Results')
log('═'.repeat(60))
log(`Total Scanned: ${issues.length}`)
log(`Reviewed: ${reviewedIssues.length}`)
log(`Real Issues: ${realIssues.length}`)
log(`False Positives: ${falsePositives.length}`)
log(`Strategy: ${strategy}`)
log(`Consensus: ${decisions.length > 0 ? Math.round(decisions.reduce((sum, d) => sum + (d.decision?.consensus_score || 0), 0) / decisions.length) : 0}% avg`)
log('═'.repeat(60))
log('')

if (shouldCreateIssues && realIssues.length > 0) {
  log(`📝 Creating ${realIssues.length} GitHub issues...`)

  const createdIssues = await pipeline(
    realIssues.filter(d => d.decision?.create_issue),
    ({ issue, reviews, decision }) => {
      const attribution = formatAIAttribution(reviews, decision)

      const title = `[${decision.issue_priority}] ${issue.description}`
      const body = `## Issue

**Category**: ${issue.category}
**Severity**: ${issue.severity}
**File**: ${issue.file_path}:${issue.line_number || '?'}

### Evidence

${issue.evidence || 'See code'}

---

${attribution}

**Review Strategy**: ${strategy}
**Arbiter**: ${decision.arbiter || 'N/A'}
`

      return createIssue(agent, platform, title, body, [
        decision.issue_priority,
        'ai-review',
        issue.category,
      ]).then(result => result.issue_url)
    }
  )

  const urls = createdIssues.filter(Boolean)
  log(`✅ Created ${urls.length} issues`)

  if (urls.length > 0) {
    log('\nIssue URLs:')
    urls.forEach((url, i) => log(`  ${i + 1}. ${url}`))
  }

  return {
    status: 'success',
    strategy,
    issues_found: issues.length,
    real_issues: realIssues.length,
    false_positives: falsePositives.length,
    issues_created: urls.length,
    issue_urls: urls,
  }
} else {
  // Just report findings
  log('\n📋 Real Issues Found:\n')
  realIssues.forEach(({ issue, decision }, i) => {
    log(`${i + 1}. [${decision.issue_priority}] ${issue.description}`)
    log(`   File: ${issue.file_path}:${issue.line_number || '?'}`)
    log(`   Consensus: ${decision.consensus_score}%`)
    log(`   Arbiter: ${decision.arbiter}`)
    log('')
  })

  return {
    status: 'success',
    strategy,
    issues_found: issues.length,
    real_issues: realIssues.length,
    false_positives: falsePositives.length,
  }
}
