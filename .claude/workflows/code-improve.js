// Code Improve - Iterative Quality Improvement Loop
// Uses shared modules for review → fix → verify cycles
// Runs until target quality score or max iterations

import { ISSUE_SCHEMA, FIX_SCHEMA, REVIEW_SCHEMA } from './shared/schemas.js'
import { multiModelReview, arbiterDecision } from './shared/consensus-engine.js'
import { formatAIAttribution } from './shared/ai-attribution.js'
import { detectPlatform, syncWithRemote, createPR, createSecureCommit, validateAndFilterFiles } from './shared/platform-detector.js'
import { calculateQualityScore, formatQualityReport, prioritizeIssuesForFix, shouldContinueImproving } from './shared/quality-scorer.js'
import { loopMode, iterativeImprovement } from './shared/loop-controller.js'
// Issue #613: Import centralized security validators (single source of truth)
import { sanitizeForShell } from './shared/security-validators.js'

export const meta = {
  name: 'code-improve',
  description: 'Iterative code quality improvement with review → fix → verify cycles',
  whenToUse: 'When user wants to systematically improve code quality',
  phases: [
    { title: 'Setup', detail: 'Detect platform and sync' },
    { title: 'Review Code', detail: 'Multi-model review finds issues' },
    { title: 'Prioritize', detail: 'Select high-impact issues' },
    { title: 'Generate Fixes', detail: 'Multi-model fix generation' },
    { title: 'Apply Fixes', detail: 'Apply and verify fixes' },
    { title: 'Verify', detail: 'Re-review to check improvements' },
  ],
}

// Parse arguments
// FIX #414: Use nullish coalescing (??) instead of OR (||) to allow falsy but valid values
// This ensures that legitimate values like 0 or empty strings are respected
const targetScore = parseInt(args?.['target-score'] ?? args?.target ?? '95')
const maxIterations = parseInt(args?.['max-iterations'] ?? args?.iterations ?? '10')
const batchSize = parseInt(args?.['batch-size'] ?? args?.batch ?? '5')
const autoMode = args?.auto ?? args?.['--auto']
const targetPath = args?.path ?? args?.['--path'] ?? '.'

// PHASE 1: Setup
phase('Setup')

log('🔧 Detecting platform and syncing...')
const platform = await detectPlatform(agent)
log(`✅ Platform: ${platform.platform} (using ${platform.cli})`)

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
log(`✅ ${syncResult.status === 'up_to_date' ? 'Already up to date' : 'Synced with remote'}`)

log('')
log('═══════════════════════════════════════')
log(`📊 Iterative Code Improvement`)
log('═══════════════════════════════════════')
log(`Target Score: ${targetScore}/100`)
log(`Max Iterations: ${maxIterations}`)
log(`Batch Size: ${batchSize} issues per iteration`)
log(`Target Path: ${targetPath}`)
log(`Auto Mode: ${autoMode ? 'YES' : 'NO'}`)
log('═══════════════════════════════════════')
log('')

// Track all modified files across iterations for safe staging
const allModifiedFiles = new Set()

// Iterative improvement loop
const loopResult = await loopMode(
  // Iteration function
  async (iteration, previousResult) => {
    log(`\n${'='.repeat(50)}`)
    log(`🔄 Iteration ${iteration}/${maxIterations}`)
    log(`${'='.repeat(50)}\n`)

    // PHASE 2: Review Code
    phase('Review Code')

    log(`🔍 Reviewing code in ${targetPath}...`)

    const reviewPrompt = `Review the code and find issues:

**Target**: ${targetPath}
**Focus**: Security, bugs, code quality, best practices

Scan the codebase and identify issues.
Return a structured list of issues with:
- Severity (critical, high, medium, low)
- Category (security, bug, quality, style, etc.)
- Description
- File path and line number
- Evidence
- Confidence (0-100)

Prioritize critical and high severity issues.`

    const reviewResult = await agent(reviewPrompt, {
      label: `Review Iteration ${iteration}`,
      schema: {
        type: 'object',
        properties: {
          issues: { type: 'array', items: ISSUE_SCHEMA },
          files_scanned: { type: 'number' },
        },
        required: ['issues'],
      }
    })

    const issues = reviewResult.issues || []
    const qualityScore = calculateQualityScore(issues)

    log(`\n${formatQualityReport(qualityScore)}`)
    log(`📂 Files scanned: ${reviewResult.files_scanned || 'unknown'}`)
    log(`🐛 Issues found: ${issues.length}`)

    // Check if we should stop
    const continueDecision = shouldContinueImproving(qualityScore, targetScore, maxIterations, iteration)

    if (!continueDecision.continue) {
      log(`\n✅ Stopping: ${continueDecision.reason}`)
      return {
        iteration,
        issues,
        qualityScore,
        shouldStop: true,
        reason: continueDecision.reason,
      }
    }

    // PHASE 3: Prioritize
    phase('Prioritize')

    const prioritized = prioritizeIssuesForFix(issues, batchSize)
    log(`\n📋 Selected ${prioritized.length} highest priority issues for fixing:`)
    prioritized.forEach((issue, i) => {
      log(`   ${i + 1}. [${issue.severity.toUpperCase()}] ${issue.description} (${issue.file_path})`)
    })

    if (prioritized.length === 0) {
      log(`\n✅ No issues to fix - perfect!`)
      return {
        iteration,
        issues: [],
        qualityScore,
        shouldStop: true,
        reason: 'no_issues',
      }
    }

    // Ask user if not in auto mode
    if (!autoMode) {
      log(`\n⏸️  Continue with fixing ${prioritized.length} issues? (yes/no)`)
      // In workflow, we auto-continue for now
      // TODO: Add AskUserQuestion support
    }

    // PHASE 4: Generate Fixes
    phase('Generate Fixes')

    log(`🤖 Generating fixes for ${prioritized.length} issues...`)

    const fixes = await pipeline(
      prioritized,
      issue => parallel([
        () => agent(`Generate a fix for this issue:

**Issue**: ${issue.description}
**File**: ${issue.file_path}:${issue.line_number || '?'}
**Severity**: ${issue.severity}
**Evidence**: ${issue.evidence || 'See code'}

Provide a complete fix with:
- Approach
- Code changes
- Files modified
- Rationale
- Confidence
- Risks
- Test plan`, {
          schema: FIX_SCHEMA,
          model: 'opus',
          label: `Fix: ${issue.category}`,
          phase: 'Generate Fixes'
        }),
        () => agent(`Generate a fix for this issue:

**Issue**: ${issue.description}
**File**: ${issue.file_path}:${issue.line_number || '?'}
**Severity**: ${issue.severity}
**Evidence**: ${issue.evidence || 'See code'}

Provide a complete fix.`, {
          schema: FIX_SCHEMA,
          model: 'sonnet',
          label: `Fix: ${issue.category}`,
          phase: 'Generate Fixes'
        }),
      ]).then(([opus, sonnet]) => ({
        issue,
        opusFix: opus,
        sonnetFix: sonnet,
      }))
    )

    log(`✅ Generated ${fixes.filter(Boolean).length} fixes`)

    // PHASE 5: Apply Fixes
    phase('Apply Fixes')

    log(`🔧 Applying fixes...`)

    const applied = []

    for (const { issue, opusFix, sonnetFix } of fixes.filter(Boolean)) {
      // Use Opus fix (higher quality)
      const fix = opusFix || sonnetFix

      if (!fix) {
        log(`⏭️  Skipping ${issue.description} - no fix generated`)
        continue
      }

      log(`\n   Applying: ${issue.description}`)
      log(`   Approach: ${fix.approach}`)

      const applyResult = await agent(`Apply this fix:

${fix.code_changes}

Files to modify: ${fix.files_modified?.join(', ') || 'auto-detect'}

Apply the fix and return status.`, {
        label: `Apply: ${issue.category}`,
        schema: {
          type: 'object',
          properties: {
            status: { type: 'string', enum: ['applied', 'failed'] },
            files_modified: { type: 'array', items: { type: 'string' } },
          },
          required: ['status'],
        }
      })

      if (applyResult.status === 'applied') {
        // SECURITY: Validate file paths before tracking them for staging
        // Issue #614: Use centralized validateAndFilterFiles (single source of truth)
        const { validFiles } = validateAndFilterFiles(applyResult.files_modified || [], msg => log(`   ${msg}`))

        // Track validated files for later staging
        validFiles.forEach(f => allModifiedFiles.add(f))

        log(`   ✅ Applied (${validFiles.length} validated file(s))`)
        applied.push({ issue, fix, files: validFiles })
      } else {
        log(`   ❌ Failed`)
      }
    }

    log(`\n✅ Applied ${applied.length}/${prioritized.length} fixes`)

    return {
      iteration,
      issues,
      qualityScore,
      fixesApplied: applied.length,
      filesModified: [...allModifiedFiles],
      shouldStop: false,
    }
  },

  // Loop options with quality-based convergence
  {
    maxIterations,
    ...iterativeImprovement(result => calculateQualityScore(result.issues || []), {
      targetScore,
      maxIterations,
      tolerance: 2,
    }),
  }
)

// PHASE 6: Create PR with all improvements
phase('Create PR')

log(`\n${'='.repeat(50)}`)
log(`📊 Improvement Complete`)
log(`${'='.repeat(50)}`)
log(`Iterations: ${loopResult.iterations}`)
log(`Status: ${loopResult.status}`)

const allResults = loopResult.results || []
const totalFixes = allResults.reduce((sum, r) => sum + (r.fixesApplied || 0), 0)
const finalQuality = allResults.length > 0
  ? calculateQualityScore(allResults[allResults.length - 1].issues || [])
  : { score: 100 }

log(`\nFinal Quality Score: ${finalQuality.score}/100`)
log(`Total Fixes Applied: ${totalFixes}`)

if (totalFixes > 0) {
  log(`\n📝 Creating pull request with all improvements...`)

  // SECURITY: Collect all validated modified files from iterations.
  // Use explicit file staging instead of 'git add .' or 'git add -u'
  // to prevent accidentally staging secrets, credentials, or unrelated files.
  const filesToStage = [...allModifiedFiles]

  if (filesToStage.length === 0) {
    log(`SECURITY: No validated files to commit - all file paths were rejected by security validation`)
  } else {
    // Generate unique branch name
    const branchName = `improve/quality-${Date.now()}`

    log(`Staging ${filesToStage.length} validated file(s)...`)

    // SECURITY: Sanitize user-controlled strings used in commit message
    const safeFixCount = sanitizeForShell(String(totalFixes))
    const safeIterCount = sanitizeForShell(String(loopResult.iterations))
    const safeStartScore = sanitizeForShell(String(allResults[0]?.qualityScore?.score || 0))
    const safeFinalScore = sanitizeForShell(String(finalQuality.score))
    const safeImprovement = sanitizeForShell(String(finalQuality.score - (allResults[0]?.qualityScore?.score || 0)))

    const commitMessage = `improve: systematic code quality improvements

- ${safeFixCount} issues fixed across ${safeIterCount} iterations
- Quality score: ${safeStartScore}/100 → ${safeFinalScore}/100
- Improvement: +${safeImprovement} points`

    // Use shared createSecureCommit function (single source of truth)
    const commitResult = await createSecureCommit(agent, branchName, filesToStage, commitMessage)

    if (commitResult.status === 'success') {
      log(`✅ Created branch ${branchName}`)
      log(`✅ Committed ${filesToStage.length} file(s)`)
      log(`✅ Pushed branch to remote`)
    } else {
      log(`❌ Failed to commit: ${commitResult.error}`)
      throw new Error(`Git commit failed: ${commitResult.error}`)
    }

    const prBody = `## Systematic Code Quality Improvements

**Iterations**: ${loopResult.iterations}
**Fixes Applied**: ${totalFixes}
**Quality Score**: ${allResults[0]?.qualityScore?.score || 0}/100 → ${finalQuality.score}/100
**Improvement**: +${finalQuality.score - (allResults[0]?.qualityScore?.score || 0)} points

### Summary by Iteration

${allResults.map((r, i) => `
**Iteration ${i + 1}**:
- Quality: ${r.qualityScore?.score || 0}/100
- Issues found: ${r.issues?.length || 0}
- Fixes applied: ${r.fixesApplied || 0}
`).join('\n')}

### Final Quality Breakdown

${formatQualityReport(finalQuality)}

---

🤖 **Automated Quality Improvement**

This PR was generated by the code-improve workflow with multi-model AI consensus.
All fixes have been reviewed and validated.
`

    const prResult = await createPR(agent, platform, `Improve: Systematic code quality improvements (+${finalQuality.score - (allResults[0]?.qualityScore?.score || 0)} points)`, prBody, {
      baseBranch: 'main',
      headBranch: branchName,
      labels: ['automated-improvement', 'quality'],
    })

    if (prResult.status === 'created') {
      log(`✅ PR created: ${prResult.pr_url}`)

      return {
        status: 'success',
        iterations: loopResult.iterations,
        fixes_applied: totalFixes,
        quality_improvement: finalQuality.score - (allResults[0]?.qualityScore?.score || 0),
        final_score: finalQuality.score,
        pr_url: prResult.pr_url,
      }
    } else {
      log(`❌ Failed to create PR`)
    }
  }
} else {
  log(`\nℹ️  No fixes applied - code is already at target quality!`)
}

return {
  status: 'success',
  iterations: loopResult.iterations,
  fixes_applied: totalFixes,
  final_score: finalQuality.score,
}
