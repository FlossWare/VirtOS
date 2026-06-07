// Auto-Review Brutal - Multi-Model Code Review with Consensus
// Combines: auto-review-brutal + code-review
// Uses shared consensus engine and platform detection
// Review-only mode: NO AUTO-FIX, only creates issues

import { ISSUE_SCHEMA, REVIEW_SCHEMA, ARBITER_SCHEMA } from './shared/schemas.js'
import { multiModelReview, arbiterDecision } from './shared/consensus-engine.js'
import { formatAIAttribution } from './shared/ai-attribution.js'
import { detectPlatform, syncWithRemote, createIssue } from './shared/platform-detector.js'
import { calculateQualityScore, formatQualityReport } from './shared/quality-scorer.js'
// Issue #511: Import sanitization for defense-in-depth on arbiter context
import { sanitizePromptInput } from './shared/prompt-sanitizer.js'

export const meta = {
  name: 'auto-review-brutal',
  description: 'Brutal multi-model code review with arbiter consensus (review-only, no auto-fix)',
  whenToUse: 'When user wants comprehensive multi-AI code review with consensus voting',
  phases: [
    { title: 'Sync', detail: 'Fetch and fast-forward merge from remote' },
    { title: 'Scan Issues', detail: 'Find problems in code' },
    { title: 'Multi-Model Review', detail: 'Opus, Sonnet, Haiku review', model: 'opus' },
    { title: 'Arbiter Decision', detail: 'Vote on real vs false positive' },
    { title: 'Create Issues', detail: 'Generate issues with AI attribution' },
  ],
}

// PHASE 1: Sync with remote
phase('Sync')

log('📥 Fetching latest changes from remote...')
const platform = await detectPlatform(agent)
log(`✅ Platform: ${platform.platform} (using ${platform.cli})`)

const syncResult = await syncWithRemote(agent)

if (syncResult.status === 'not_clean') {
  log(`⚠️ Working tree has uncommitted changes: ${syncResult.message}`)
  return {
    status: 'not_clean',
    message: 'Commit or stash changes before syncing'
  }
}

if (syncResult.status === 'branch_mismatch') {
  log(`⚠️ Branch mismatch: ${syncResult.message}`)
  return {
    status: 'branch_mismatch',
    message: syncResult.message
  }
}

if (syncResult.status === 'diverged') {
  log(`⚠️ Local and remote have diverged: ${syncResult.message}`)
  return {
    status: 'diverged',
    message: 'Local and remote branches have diverged. Resolve manually.'
  }
}

if (syncResult.status === 'failed') {
  log(`❌ Failed to sync with remote: ${syncResult.message}`)
  return {
    status: 'failed',
    error: syncResult.message
  }
}

log(`✅ ${syncResult.status === 'up_to_date' ? 'Already up to date' : 'Synced with remote'}`)

// PHASE 2: Scan for issues
phase('Scan Issues')

log('🔍 Scanning codebase for potential issues...')
const scanResult = await agent(`Scan the codebase for potential issues.

FOCUS ON:
- Security vulnerabilities (command injection, path traversal, etc.)
- Code quality issues (unused code, duplicates, etc.)
- Bug patterns (off-by-one, null pointer, etc.)
- Style violations (if critical)

Return a list of issues found with evidence and confidence scores.
IMPORTANT: Be thorough but avoid false positives.`, {
  label: 'Scan Codebase',
  schema: {
    type: 'object',
    properties: {
      issues: { type: 'array', items: ISSUE_SCHEMA },
      total_files_scanned: { type: 'number' },
      scan_duration_seconds: { type: 'number' },
    },
    required: ['issues', 'total_files_scanned'],
  }
})

const issues = scanResult.issues || []
log(`Found ${issues.length} potential issues`)

if (issues.length === 0) {
  log('✅ No issues found - codebase looks clean!')
  return {
    status: 'success',
    issues_found: 0,
    issues_created: 0,
  }
}

// PHASE 3: Multi-Model Review (Brutal Consensus)
phase('Multi-Model Review')

log(`🤖 Running brutal multi-model consensus review on ${issues.length} issues...`)

const multiModelReviews = await pipeline(
  issues.slice(0, 10), // Limit to top 10 issues for cost control
  issue => multiModelReview(
    `Review this potential issue and determine if it's real or a false positive:

**Issue**: ${issue.description}
**File**: ${issue.file_path}${issue.line_number ? `:${issue.line_number}` : ''}
**Severity**: ${issue.severity}
**Evidence**: ${issue.evidence || 'See code'}

Analyze thoroughly and provide your assessment with confidence score.`,
    REVIEW_SCHEMA,
    {
      phase: 'Multi-Model Review',
      labelPrefix: issue.category,
    }
  ).then(reviews => ({
    issue,
    reviews,
  }))
)

const reviewedIssues = multiModelReviews.filter(Boolean)
log(`✅ Multi-model review complete for ${reviewedIssues.length} issues`)

// PHASE 4: Arbiter Decision
phase('Arbiter Decision')

log('⚖️ Arbiter reviewing consensus...')

// Issue #511: Sanitize issue context before passing to arbiter (defense-in-depth;
// issue.description may contain code comments which are user-controlled)
// Issue #609: Wrap arbiterDecision in try-catch to handle arbiter selection failures
// (e.g., selectArbiter() returning undefined from pool degradation). Without this,
// the Error thrown at consensus-engine.js:288 propagates uncaught and crashes the workflow.
const arbiterDecisions = await pipeline(
  reviewedIssues,
  ({ issue, reviews }) => {
    try {
      return arbiterDecision(
        `${sanitizePromptInput(issue.description, 500)} (${sanitizePromptInput(issue.file_path, 200)})`,
        reviews,
        {
          decisionType: 'issue',
          phase: 'Arbiter Decision',
        }
      ).then(decision => ({
        issue,
        reviews,
        arbiterDecision: decision,
      })).catch(error => {
        log(`❌ Arbiter decision failed for issue "${issue.description}": ${error.message}`)
        return {
          issue,
          reviews,
          arbiterDecision: null,
        }
      })
    } catch (error) {
      log(`❌ Arbiter decision failed for issue "${issue.description}": ${error.message}`)
      return {
        issue,
        reviews,
        arbiterDecision: null,
      }
    }
  }
)

const finalDecisions = arbiterDecisions.filter(Boolean)
log(`✅ Arbiter decisions complete for ${finalDecisions.length} issues`)

// PHASE 5: Create Issues
phase('Create Issues')

const issuesToCreate = finalDecisions.filter(d => d.arbiterDecision?.create_issue)
log(`📝 Creating ${issuesToCreate.length} GitHub issues with AI attribution...`)

const createdIssues = await pipeline(
  issuesToCreate,
  ({ issue, reviews, arbiterDecision }) => {
    const attribution = formatAIAttribution(reviews, arbiterDecision, {
      includeVerboseDetails: true,
    })

    const title = `[${arbiterDecision.issue_priority}] ${issue.description}`

    const body = `## Issue Details

**Category**: ${issue.category}
**Severity**: ${issue.severity}
**File**: ${issue.file_path}${issue.line_number ? `:${issue.line_number}` : ''}
**Confidence**: ${issue.confidence}%

### Evidence

${issue.evidence || 'See code location above'}

---

${attribution}
`

    return createIssue(agent, platform, title, body, [
      arbiterDecision.issue_priority,
      'ai-review',
      issue.category,
      issue.severity
    ]).then(result => result.issue_url || null)
  }
)

const issueUrls = createdIssues.filter(Boolean)
log(`✅ Created ${issueUrls.length} issues with AI attribution`)

// Summary
log('')
log('═══════════════════════════════════════')
log('📊 Brutal Multi-Model Review Complete')
log('═══════════════════════════════════════')
log(`Total Issues Scanned: ${issues.length}`)
log(`Multi-Model Reviews: ${reviewedIssues.length}`)
log(`Arbiter Decisions: ${finalDecisions.length}`)
log(`Real Issues (validated): ${issuesToCreate.length}`)
log(`GitHub Issues Created: ${issueUrls.length}`)
log('')

const realIssues = finalDecisions.filter(d => d.arbiterDecision?.final_decision === 'real_issue')
const falsePositives = finalDecisions.filter(d => d.arbiterDecision?.final_decision === 'false_positive')
const needsHuman = finalDecisions.filter(d => d.arbiterDecision?.final_decision === 'needs_human')

log(`Breakdown:`)
log(`  ✅ Real Issues: ${realIssues.length}`)
log(`  ❌ False Positives: ${falsePositives.length}`)
log(`  ⚠️ Needs Human Review: ${needsHuman.length}`)
log('')

if (issueUrls.length > 0) {
  log('Created Issues:')
  issueUrls.forEach((url, i) => {
    log(`  ${i + 1}. ${url}`)
  })
}

return {
  status: 'success',
  mode: 'brutal-review',
  total_issues: issues.length,
  reviewed: reviewedIssues.length,
  real_issues: realIssues.length,
  false_positives: falsePositives.length,
  needs_human: needsHuman.length,
  created_issues: issueUrls.length,
  issue_urls: issueUrls,
}
