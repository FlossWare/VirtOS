// Code Solve - Auto-Resolve GitHub/GitLab Issues
// Uses shared consensus engine for multi-model fix generation
// Review-only mode by default: creates PRs, doesn't push directly
// SECURITY: --apply flag is removed. All changes go through PR review workflow.

import { ISSUE_SCHEMA, FIX_SCHEMA, ARBITER_SCHEMA } from './shared/schemas.js'
import { multiModelReview, arbiterDecision } from './shared/consensus-engine.js'
import { formatAIAttribution } from './shared/ai-attribution.js'
import { detectPlatform, syncWithRemote, fetchIssue, createPR, postComment, createSecureCommit, validateAndFilterFiles } from './shared/platform-detector.js'
import { continuousMonitor } from './shared/loop-controller.js'
// Issue #511: Import sanitization to prevent prompt injection from issue metadata
import { sanitizePromptInput } from './shared/prompt-sanitizer.js'
// Issue #613: Import centralized security validators (single source of truth)
import { sanitizeForShell, isValidBranchName } from './shared/security-validators.js'

// ISSUE #604: Continuous monitoring configuration
// ================================================
// Configuration for continuous issue resolution loop. These values match
// pr-review.js constants for consistency across all monitoring workflows.
// - Rate limiting: Most platforms enforce 60 requests/hour
// - Resource exhaustion: Prevents runaway monitoring sessions
// - User workflow: Provides reasonable cadence for issue discovery
const MONITORING_POLL_INTERVAL_MS = 600000    // 10 minutes (rate limit protection)
const MONITORING_MAX_RUNS = 100               // ~16.7 hours max session before restart
const MAX_ISSUES_PER_BATCH = 3               // Limit issues resolved per iteration

export const meta = {
  name: 'code-solve',
  description: 'Auto-resolve GitHub/GitLab issues with multi-model consensus',
  whenToUse: 'When user wants to automatically fix issues with AI',
  phases: [
    { title: 'Setup', detail: 'Detect platform and sync' },
    { title: 'Fetch Issue', detail: 'Get issue details' },
    { title: 'Generate Fixes', detail: 'Opus, Sonnet, Haiku propose solutions', model: 'opus' },
    { title: 'Arbiter Decision', detail: 'Select best fix' },
    { title: 'Create PR', detail: 'Generate pull request with fix' },
  ],
}

// Parse arguments
const issueNumber = args?.[0]
const isLoopMode = issueNumber === 'loop' || args?.loop
const shouldCreatePR = args?.['create-pr'] !== false // Default: true

// SECURITY: --apply flag has been permanently removed (Issue #550).
// Emit a clear warning if the user tries to use the old flag.
if (args?.apply || args?.['--apply']) {
  log('SECURITY: The --apply flag has been removed for security reasons.')
  log('   Direct application of AI-generated code without human review is unsafe.')
  log('   Changes will be submitted as a PR for review instead.')
  log('')
}

// Validation
if (!isLoopMode && !issueNumber) {
  log('Error: Issue number required')
  log('Usage: /code-solve <issue_number> [--create-pr]')
  log('   or: /code-solve loop')
  return { status: 'error', message: 'Issue number required' }
}

if (!isLoopMode && (!/^\d+$/.test(String(issueNumber)) || parseInt(String(issueNumber), 10) <= 0)) {
  log(`Error: Invalid issue number: "${issueNumber}"`)
  log('Issue number must be a positive integer (e.g., 42)')
  log('Usage: /code-solve <issue_number> [--create-pr]')
  return { status: 'error', message: `Invalid issue number: "${issueNumber}". Must be a positive integer.` }
}

// PHASE 1: Setup
phase('Setup')

log('Detecting platform and syncing...')
const platform = await detectPlatform(agent)
log(`Platform: ${platform.platform} (using ${platform.cli})`)

const syncResult = await syncWithRemote(agent)
if (syncResult.status === 'not_clean') {
  log(`Working tree has uncommitted changes: ${syncResult.message}`)
  return { status: 'not_clean', message: 'Commit or stash changes before syncing' }
}
if (syncResult.status === 'branch_mismatch') {
  log(`Branch mismatch: ${syncResult.message}`)
  return { status: 'branch_mismatch', message: syncResult.message }
}
if (syncResult.status === 'diverged') {
  log(`Local and remote have diverged: ${syncResult.message}`)
  return { status: 'diverged', message: 'Local and remote branches have diverged. Resolve manually.' }
}
if (syncResult.status === 'failed') {
  log(`Failed to sync with remote: ${syncResult.message}`)
  return { status: 'failed', error: syncResult.message }
}
log(`${syncResult.status === 'up_to_date' ? 'Already up to date' : 'Synced with remote'}`)

// Loop mode or single issue
if (isLoopMode) {
  log('Starting continuous issue resolution...')

  const monitorResult = await continuousMonitor(
    // Check function: fetch open issues
    async (run) => {
      log('Checking for open issues...')

      const result = await agent(`List all open issues.

Platform: ${platform.platform}
CLI: ${platform.cli}

Execute:
${platform.cli} issue list --json number,title,labels,state --limit 50

Return array of issue numbers that are:
- Open
- Not already being worked on (check for PR references)
- Labeled as 'bug' or 'enhancement' (priority)

Sort by priority: bugs first, then enhancements.`, {
        label: 'List Open Issues',
        schema: {
          type: 'object',
          properties: {
            issues: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  number: { type: 'number' },
                  title: { type: 'string' },
                  priority: { type: 'number' },
                },
                required: ['number', 'priority']
              }
            }
          },
          required: ['issues']
        }
      })

      return result.issues
        .sort((a, b) => b.priority - a.priority)
        .slice(0, MAX_ISSUES_PER_BATCH) // Resolve max issues per iteration
        .map(i => i.number)
    },

    // Action function: resolve issues
    async (issueNumbers) => {
      const results = []

      for (const num of issueNumbers) {
        log(`\n=== Resolving Issue #${num} ===`)

        const resolveResult = await resolveSingleIssue(num, platform, shouldCreatePR)
        results.push(resolveResult)
      }

      return results
    },

    {
      interval: MONITORING_POLL_INTERVAL_MS,
      maxRuns: MONITORING_MAX_RUNS,
      stopOnNoWork: true,
    }
  )

  return monitorResult

} else {
  // Single issue resolution
  return await resolveSingleIssue(parseInt(String(issueNumber), 10), platform, shouldCreatePR)
}

// Helper function to resolve a single issue
async function resolveSingleIssue(num, platform, shouldCreatePR) {
  // PHASE 2: Fetch Issue
  phase('Fetch Issue')

  log(`Fetching issue #${num}...`)
  const issue = await fetchIssue(agent, platform, num)
  log(`Issue: "${issue.title}"`)
  log(`   Author: ${issue.author}`)
  log(`   Labels: ${issue.labels?.join(', ') || 'none'}`)

  // PHASE 3: Generate Fixes
  phase('Generate Fixes')

  log('Generating fixes with multi-model consensus...')

  const fixPrompt = `Generate a fix for this issue:

**Issue #${num}**: ${issue.title}

**Description**:
${issue.body || 'No description'}

**Labels**: ${issue.labels?.join(', ') || 'none'}

Analyze the issue and provide:
1. Approach - How to fix this issue
2. Code changes - Actual code/files to modify
3. Files modified - List of files that will change
4. Rationale - Why this fix works
5. Confidence - How confident you are (0-100)
6. Risks - Potential issues with this fix
7. Test plan - How to verify the fix

Provide a complete, implementable solution.`

  const fixes = await multiModelReview(fixPrompt, FIX_SCHEMA, {
    phase: 'Generate Fixes',
    labelPrefix: `Issue #${num}`,
    includeGemini: false,
  })

  log(`Generated fixes from ${fixes.allReviews.length} models`)

  // PHASE 4: Arbiter Decision
  phase('Arbiter Decision')

  log('Arbiter selecting best fix...')

  // Issue #511: Sanitize issue title before passing as arbiter context (defense-in-depth;
  // buildArbiterPrompt also sanitizes, but callers should not pass raw user input)
  // Issue #609: Wrap arbiterDecision in try-catch to handle arbiter selection failures
  // (e.g., selectArbiter() returning undefined from pool degradation). Without this,
  // the Error thrown at consensus-engine.js:288 propagates uncaught and crashes the workflow.
  let decision
  try {
    decision = await arbiterDecision(
      `Issue #${num}: "${sanitizePromptInput(issue.title, 500)}"`,
      fixes,
      {
        decisionType: 'fix',
        phase: 'Arbiter Decision',
      }
    )
  } catch (error) {
    log(`Arbiter decision failed for issue #${num}: ${error.message}`)
    return {
      status: 'error',
      issue_number: num,
      phase: 'Arbiter Decision',
      message: `Arbiter decision failed: ${error.message}`,
      error: error.stack,
    }
  }

  log(`Selected: ${decision.accepted_model}'s fix (${decision.consensus_score}% consensus)`)

  // Get the accepted fix
  const acceptedFix = fixes[decision.accepted_model.toLowerCase()]

  if (!acceptedFix || !acceptedFix.code_changes) {
    log('No valid fix selected')
    return {
      status: 'failed',
      issue_number: num,
      reason: 'No valid fix generated'
    }
  }

  log(`Fix approach: ${acceptedFix.approach}`)
  log(`Files to modify: ${acceptedFix.files_modified?.join(', ') || 'unspecified'}`)

  // PHASE 5: Apply Fix and Create PR
  phase('Create PR')

  // SECURITY (Issues #494, #509, #550): Direct apply mode has been permanently removed.
  // Issue #494: The old applyDirectly path committed on the current branch BEFORE
  // creating the fix branch, polluting main with AI-generated commits. This was a
  // critical logic bug where the branch creation (git checkout -b) happened AFTER
  // the commit, meaning the fix landed on whatever branch was checked out (usually main).
  // Resolution: The applyDirectly code path has been entirely removed. All changes
  // now go through the PR review workflow below, which creates the branch FIRST.
  // All changes MUST go through the PR review workflow below. This ensures:
  // 1. AI-generated code is reviewed by a human before merging
  // 2. No arbitrary filenames are passed to 'git add' without validation
  // 3. No secrets or sensitive files are accidentally staged
  // 4. Changes are isolated on a feature branch, never committed to main directly

  if (shouldCreatePR) {
    log('Creating pull request...')

    // IMPORTANT (Issues #494, #509): The branch MUST be created BEFORE any commits are made.
    // Creating the branch first ensures commits only land on the feature branch,
    // not on main. Issue #494 identified that the old code committed to the current
    // branch before creating the fix branch, polluting main with AI-generated code.
    const branchName = `fix/issue-${num}`

    // Record the current branch so we can restore on failure
    const currentBranchResult = await agent(`Get the current git branch name.

Execute:
git rev-parse --abbrev-ref HEAD

Return the branch name.`, {
      label: 'Get Current Branch',
      schema: {
        type: 'object',
        properties: {
          branch: { type: 'string' },
        },
        required: ['branch'],
      }
    })
    const rawBranch = currentBranchResult.branch || 'main'
    // SECURITY: Validate branch name from agent output to prevent command injection.
    // The agent returns whatever git outputs, but we must verify it is a safe branch name
    // before using it in subsequent git commands (cleanup on failure paths).
    if (!isValidBranchName(rawBranch)) {
      log(`SECURITY: Invalid branch name returned from git: "${sanitizeForShell(rawBranch)}"`)
      return {
        status: 'failed',
        issue_number: num,
        reason: 'Could not determine current branch safely'
      }
    }
    const originalBranch = rawBranch

    await agent(`Create a new branch for the fix.

Execute:
git checkout -b "${branchName}"`, {
      label: `Create Branch ${branchName}`,
    })

    // Apply the fix on the NEW branch, validate files, and commit with sanitized message
    log('Applying fix to branch...')

    const applyResult = await agent(`Apply this fix to the codebase:

**Fix for Issue #${num}**:
${acceptedFix.code_changes}

Apply the changes to the appropriate files.
Create/modify files as needed.
Do NOT run git add or git commit - just apply the file changes.
Return list of files actually modified.`, {
      label: `Apply Fix #${num}`,
      schema: {
        type: 'object',
        properties: {
          files_modified: { type: 'array', items: { type: 'string' } },
          status: { type: 'string', enum: ['applied', 'failed'] },
          message: { type: 'string' },
        },
        required: ['status'],
      }
    })

    if (applyResult.status === 'failed') {
      log(`Failed to apply fix: ${applyResult.message}`)
      // Clean up: switch back to original branch and delete the fix branch
      await agent(`Restore the original branch after failed fix application.

Execute:
git checkout -- .
git checkout "${originalBranch}"
git branch -D "${branchName}"`, {
        label: `Cleanup Branch ${branchName}`,
      })
      return {
        status: 'failed',
        issue_number: num,
        reason: sanitizeForShell(applyResult.message || 'Apply failed')
      }
    }

    // SECURITY: Validate all file paths before staging
    // Issue #614: Use centralized validateAndFilterFiles (single source of truth)
    const MAX_FILES_PER_FIX = 20
    const { validFiles, error: fileValidationError } = validateAndFilterFiles(
      applyResult.files_modified || [], log, { maxFiles: MAX_FILES_PER_FIX }
    )

    if (fileValidationError || validFiles.length === 0) {
      const reason = fileValidationError || 'No valid files to commit after path validation'
      log(reason)
      // Clean up: switch back to original branch and delete the fix branch
      await agent(`Restore the original branch after failed validation.

Execute:
git checkout -- .
git checkout "${originalBranch}"
git branch -D "${branchName}"`, {
        label: `Cleanup Branch ${branchName}`,
      })
      return {
        status: 'failed',
        issue_number: num,
        reason
      }
    }

    // SECURITY: Sanitize user-controlled strings used in commit message
    const safeTitle = sanitizeForShell(issue.title)
    const safeApproach = sanitizeForShell(acceptedFix.approach)

    // Use shared createSecureCommit function (single source of truth)
    const commitMessage = `fix: resolve issue #${num} - ${safeTitle}

${safeApproach}

Fixes #${num}`

    const commitResult = await createSecureCommit(agent, branchName, validFiles, commitMessage)

    if (commitResult.status === 'success') {
      log(`Applied and committed fix (${validFiles.length} file(s))`)
      log(`Pushed branch ${branchName}`)
    } else {
      log(`Failed to commit: ${commitResult.error}`)
      // Clean up on failure
      await agent(`Restore the original branch after commit failure.

Execute:
git checkout -- .
git checkout "${originalBranch}"
git branch -D "${branchName}"`, {
        label: `Cleanup Branch ${branchName}`,
      })
      return {
        status: 'failed',
        issue_number: num,
        reason: sanitizeForShell(commitResult.error || 'Commit failed')
      }
    }

    // Create PR body with AI attribution
    const attribution = formatAIAttribution(fixes, decision, {
      includeVerboseDetails: true,
    })

    const prBody = `## Fix for Issue #${num}

**Approach**: ${acceptedFix.approach}

**Rationale**: ${acceptedFix.rationale}

**Files Modified**:
${validFiles.length > 0 ? validFiles.map(f => `- \`${f}\``).join('\n') : '- (see commits)'}

**Test Plan**:
${acceptedFix.test_plan || 'Manual testing required'}

**Risks**:
${acceptedFix.risks && acceptedFix.risks.length > 0
  ? acceptedFix.risks.map(r => `- ${r}`).join('\n')
  : '- None identified'}

---

${attribution}

Closes #${num}
`

    // Create the PR
    const prResult = await createPR(agent, platform, `Fix: ${issue.title}`, prBody, {
      baseBranch: 'main',
      headBranch: branchName,
      labels: ['automated-fix', 'ai-generated'],
    })

    if (prResult.status === 'created') {
      log(`PR created: ${prResult.pr_url}`)

      // Post comment on original issue
      await postComment(agent, platform, 'issue', num,
        `**Automated Fix Generated**\n\nA fix has been proposed in ${prResult.pr_url}\n\nPlease review and merge if acceptable.`
      )

      log(`Commented on issue #${num}`)

      return {
        status: 'success',
        issue_number: num,
        pr_url: prResult.pr_url,
        pr_number: prResult.pr_number,
        fix_approach: acceptedFix.approach,
        confidence: acceptedFix.confidence,
      }
    } else {
      log(`Failed to create PR`)
      return {
        status: 'failed',
        issue_number: num,
        reason: 'PR creation failed'
      }
    }
  } else {
    log('Skipping PR creation (use --create-pr to create)')
    return {
      status: 'fix_generated',
      issue_number: num,
      fix_approach: acceptedFix.approach,
      confidence: acceptedFix.confidence,
    }
  }
}
