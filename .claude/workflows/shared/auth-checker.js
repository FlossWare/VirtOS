// Authorization Checker Module
// Validates user permissions and repository policies before auto-approval
// Used by: pr-review.js (Issue #452 fix)

// FIX #390: Import sanitization helpers to prevent command injection
// when user-controlled values (branch names, usernames) are interpolated
// into agent prompts containing shell commands.
import { sanitizeForShell, sanitizeBranchName } from './platform-detector.js'

/**
 * Check if a user has write or maintain permissions on a repository
 * @param {Object} agent - The agent function for executing commands
 * @param {Object} platform - Platform detection result (github/gitlab/bitbucket)
 * @param {string} username - Username to check permissions for
 * @returns {Promise<Object>} { hasPermission: boolean, role: string, error: string|null }
 */
export async function checkUserPermissions(agent, platform, username) {
  if (!platform || !platform.cli) {
    return {
      hasPermission: false,
      role: 'unknown',
      error: 'Invalid platform configuration',
    }
  }

  if (!username || typeof username !== 'string') {
    return {
      hasPermission: false,
      role: 'unknown',
      error: 'Invalid username',
    }
  }

  // FIX #390: Sanitize username before interpolating into agent prompts containing
  // shell commands. Although username typically comes from getCurrentUser() (trusted),
  // defense-in-depth requires sanitization at the point of use, not the point of origin.
  const safeUsername = sanitizeForShell(username, 128)
  if (!safeUsername || safeUsername.length === 0) {
    return {
      hasPermission: false,
      role: 'unknown',
      error: `Username contains only unsafe characters: "${username}"`,
    }
  }

  try {
    const result = await agent(`Check repository permissions for user "${safeUsername}".

Platform: ${platform.platform}
CLI: ${platform.cli}

Execute the appropriate command based on platform:

For GitHub (gh):
${platform.cli} api repos/{owner}/{repo}/collaborators/${safeUsername}/permission --jq '.permission'

For GitLab (glab):
${platform.cli} api /projects/{id}/members --search ${safeUsername} --jq '.[0].access_level'

For Bitbucket (bb):
${platform.cli} api repositories/{workspace}/{repo}/permissions-config/users

Return structured data with:
- permission: The user's permission level (admin, maintain, write, triage, read, or equivalent)
- role: Simplified role (maintainer, contributor, viewer, unknown)
- can_approve: Boolean indicating if the user can approve PRs
- can_modify: Boolean indicating if the user can modify repository settings`, {
      label: `Check User Permissions for ${safeUsername}`,
      schema: {
        type: 'object',
        properties: {
          permission: { type: 'string' },
          role: { type: 'string', enum: ['maintainer', 'contributor', 'viewer', 'unknown'] },
          can_approve: { type: 'boolean' },
          can_modify: { type: 'boolean' },
          status: { type: 'string' },
        },
        required: ['role', 'can_approve', 'status'],
      }
    })

    const hasPermission = result.can_approve === true
    const role = result.role || 'unknown'

    if (!hasPermission) {
      return {
        hasPermission: false,
        role: role,
        error: `User ${safeUsername} does not have permission to approve PRs (role: ${role})`,
      }
    }

    return {
      hasPermission: true,
      role: role,
      error: null,
    }
  } catch (error) {
    return {
      hasPermission: false,
      role: 'unknown',
      error: `Error checking permissions: ${error.message}`,
    }
  }
}

/**
 * Check if auto-approval is enabled in repository settings
 * @param {Object} agent - The agent function for executing commands
 * @param {Object} platform - Platform detection result
 * @returns {Promise<Object>} { autoApprovalEnabled: boolean, enforcedRules: Array, error: string|null }
 */
export async function checkRepositoryAutoApprovalPolicy(agent, platform) {
  if (!platform || !platform.cli) {
    return {
      autoApprovalEnabled: false,
      enforcedRules: [],
      error: 'Invalid platform configuration',
    }
  }

  try {
    const result = await agent(`Check if auto-approval is enabled in repository settings.

Platform: ${platform.platform}
CLI: ${platform.cli}

Check branch protection rules and repository settings:

For GitHub (gh):
1. ${platform.cli} api repos/{owner}/{repo}/branches/main --jq '.protection'
2. Look for: required_status_checks, required_pull_request_reviews, dismiss_stale_reviews
3. Check if repository allows bots or automation in branch protection rules

For GitLab (glab):
1. ${platform.cli} api /projects/{id}/protected_branches --jq '.'
2. Check for approval requirements

For Bitbucket (bb):
1. ${platform.cli} api repositories/{workspace}/{repo}/default-reviewers

Return structured data with:
- auto_approval_allowed: Boolean indicating if auto-approval is permitted
- requires_human_review: Boolean if human review is mandatory
- required_reviewers: Number of required reviewers
- dismiss_stale_reviews: Boolean if stale reviews are auto-dismissed
- enforced_rules: Array of branch protection rules
- warnings: Array of any policy warnings`, {
      label: 'Check Repository Auto-Approval Policy',
      schema: {
        type: 'object',
        properties: {
          auto_approval_allowed: { type: 'boolean' },
          requires_human_review: { type: 'boolean' },
          required_reviewers: { type: 'number' },
          dismiss_stale_reviews: { type: 'boolean' },
          enforced_rules: {
            type: 'array',
            items: { type: 'string' }
          },
          warnings: {
            type: 'array',
            items: { type: 'string' }
          },
          status: { type: 'string' },
        },
        required: ['auto_approval_allowed', 'status'],
      }
    })

    const autoApprovalEnabled = result.auto_approval_allowed !== false
    const enforcedRules = result.enforced_rules || []
    const warnings = result.warnings || []

    if (!autoApprovalEnabled || result.requires_human_review === true) {
      return {
        autoApprovalEnabled: false,
        enforcedRules: enforcedRules,
        warnings: warnings,
        error: 'Auto-approval is not permitted by repository policy',
      }
    }

    return {
      autoApprovalEnabled: true,
      enforcedRules: enforcedRules,
      warnings: warnings,
      error: null,
    }
  } catch (error) {
    return {
      autoApprovalEnabled: false,
      enforcedRules: [],
      warnings: [],
      error: `Error checking policy: ${error.message}`,
    }
  }
}

/**
 * Check branch protection rules that may block auto-approval
 * @param {Object} agent - The agent function for executing commands
 * @param {Object} platform - Platform detection result
 * @param {string} baseBranch - The target branch (usually 'main' or 'master')
 * @returns {Promise<Object>} { protectionEnabled: boolean, blockers: Array, error: string|null }
 */
export async function checkBranchProtectionRules(agent, platform, baseBranch = 'main') {
  if (!platform || !platform.cli) {
    return {
      protectionEnabled: false,
      blockers: [],
      error: 'Invalid platform configuration',
    }
  }

  if (!baseBranch || typeof baseBranch !== 'string') {
    baseBranch = 'main'
  }

  // FIX #390: Sanitize baseBranch before interpolating into agent prompts containing
  // shell commands. Branch names are user-controlled (e.g., PR base_branch) and could
  // contain shell metacharacters that enable command injection via the API URL path.
  const safeBranch = sanitizeBranchName(baseBranch)

  try {
    const result = await agent(`Check branch protection rules for "${safeBranch}".

Platform: ${platform.platform}
CLI: ${platform.cli}
Branch: ${safeBranch}

Execute the appropriate command based on platform:

For GitHub (gh):
${platform.cli} api repos/{owner}/{repo}/branches/${safeBranch}/protection --jq '.'

For GitLab (glab):
${platform.cli} api /projects/{id}/protected_branches/${safeBranch} --jq '.'

For Bitbucket (bb):
${platform.cli} api repositories/{workspace}/{repo}/branch-restrictions

Return structured data with:
- protection_enabled: Boolean indicating if branch protection is enabled
- required_reviews: Number of required reviews (0 if none)
- require_code_owner_reviews: Boolean
- require_status_checks: Boolean
- require_branches_to_be_up_to_date: Boolean
- enforce_admins: Boolean
- blockers: Array of blocking rules (rules that prevent auto-approval)`, {
      label: `Check Branch Protection Rules for ${safeBranch}`,
      schema: {
        type: 'object',
        properties: {
          protection_enabled: { type: 'boolean' },
          required_reviews: { type: 'number' },
          require_code_owner_reviews: { type: 'boolean' },
          require_status_checks: { type: 'boolean' },
          require_branches_to_be_up_to_date: { type: 'boolean' },
          enforce_admins: { type: 'boolean' },
          blockers: {
            type: 'array',
            items: { type: 'string' }
          },
          status: { type: 'string' },
        },
        required: ['protection_enabled', 'status'],
      }
    })

    const blockers = result.blockers || []

    // Add additional blockers based on policy
    if (result.required_reviews && result.required_reviews > 0) {
      if (!blockers.includes('required_reviews')) {
        blockers.push('required_reviews')
      }
    }

    if (result.require_code_owner_reviews === true) {
      if (!blockers.includes('code_owner_reviews')) {
        blockers.push('code_owner_reviews')
      }
    }

    if (result.enforce_admins === true) {
      if (!blockers.includes('enforce_admins')) {
        blockers.push('enforce_admins')
      }
    }

    return {
      protectionEnabled: result.protection_enabled === true,
      blockers: blockers,
      error: blockers.length > 0 ? `Branch has ${blockers.length} protection rules that may block auto-approval` : null,
    }
  } catch (error) {
    return {
      protectionEnabled: false,
      blockers: [],
      error: `Error checking branch protection: ${error.message}`,
    }
  }
}

/**
 * Get the current authenticated user
 * @param {Object} agent - The agent function for executing commands
 * @param {Object} platform - Platform detection result
 * @returns {Promise<Object>} { username: string, error: string|null }
 */
export async function getCurrentUser(agent, platform) {
  if (!platform || !platform.cli) {
    return {
      username: 'unknown',
      error: 'Invalid platform configuration',
    }
  }

  try {
    const result = await agent(`Get the current authenticated user.

Platform: ${platform.platform}
CLI: ${platform.cli}

Execute the appropriate command based on platform:

For GitHub (gh):
${platform.cli} auth status --show-token | grep -i user | awk '{print $NF}' || ${platform.cli} api user --jq '.login'

For GitLab (glab):
${platform.cli} api user --jq '.username' || glab config get -k user

For Bitbucket (bb):
${platform.cli} api user --jq '.username'

Return structured data with:
- username: The authenticated user's username
- status: success or failure`, {
      label: 'Get Current Authenticated User',
      schema: {
        type: 'object',
        properties: {
          username: { type: 'string' },
          status: { type: 'string' },
        },
        required: ['username', 'status'],
      }
    })

    if (!result.username) {
      return {
        username: 'unknown',
        error: 'Could not determine current user',
      }
    }

    return {
      username: result.username,
      error: null,
    }
  } catch (error) {
    return {
      username: 'unknown',
      error: `Error getting current user: ${error.message}`,
    }
  }
}

/**
 * FIX #411: Verify that at least one human (non-bot) review exists on the PR.
 * Auto-approval without any human oversight is a critical security risk: compromised
 * AI models or carefully crafted malicious PRs that pass quality checks could be
 * auto-merged, introducing vulnerabilities into the codebase.
 *
 * This function checks the PR's existing reviews and requires at least one approving
 * review from a human reviewer (not a bot/automation account) before allowing
 * auto-approval to proceed.
 *
 * @param {Object} agent - The agent function for executing commands
 * @param {Object} platform - Platform detection result
 * @param {number|string} prNumber - The PR number to check
 * @returns {Promise<Object>} { hasHumanReview: boolean, humanReviewers: Array, error: string|null }
 */
export async function checkHumanReviewExists(agent, platform, prNumber) {
  if (!platform || !platform.cli) {
    return {
      hasHumanReview: false,
      humanReviewers: [],
      error: 'Invalid platform configuration',
    }
  }

  if (!prNumber) {
    return {
      hasHumanReview: false,
      humanReviewers: [],
      error: 'Invalid PR number',
    }
  }

  try {
    const result = await agent(`Check if PR #${prNumber} has any human (non-bot) approving reviews.

Platform: ${platform.platform}
CLI: ${platform.cli}

Execute:
${platform.cli} pr view ${prNumber} --json reviews,reviewRequests --jq '{reviews: .reviews, reviewRequests: .reviewRequests}'

Analyze the reviews array and identify:
1. Reviews with state "APPROVED"
2. Filter OUT any reviews from bot accounts (usernames ending in [bot], github-actions, dependabot, renovate, etc.)
3. Return the list of human reviewers who approved

Return structured data with:
- human_approvals: Array of objects with {username, state} for each human approving review
- bot_approvals: Array of bot account names that approved (for logging)
- total_reviews: Total number of reviews
- has_human_approval: Boolean - true if at least one human approved`, {
      label: `Check Human Reviews for PR #${prNumber}`,
      schema: {
        type: 'object',
        properties: {
          human_approvals: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                username: { type: 'string' },
                state: { type: 'string' },
              },
            }
          },
          bot_approvals: {
            type: 'array',
            items: { type: 'string' }
          },
          total_reviews: { type: 'number' },
          has_human_approval: { type: 'boolean' },
          status: { type: 'string' },
        },
        required: ['has_human_approval', 'status'],
      }
    })

    const humanReviewers = (result.human_approvals || []).map(r => r.username).filter(Boolean)

    return {
      hasHumanReview: result.has_human_approval === true,
      humanReviewers,
      botApprovals: result.bot_approvals || [],
      totalReviews: result.total_reviews || 0,
      error: null,
    }
  } catch (error) {
    return {
      hasHumanReview: false,
      humanReviewers: [],
      error: `Error checking human reviews: ${error.message}`,
    }
  }
}

/**
 * FIX #411: Check that the PR author is NOT the same as the user performing
 * the auto-approval. Self-approval bypasses the separation-of-concerns principle
 * and allows a single compromised account to both author and approve malicious code.
 *
 * @param {string} prAuthor - The PR author's username
 * @param {string} currentUser - The currently authenticated user's username
 * @returns {Object} { isSelfApproval: boolean, error: string|null }
 */
export function checkSelfApproval(prAuthor, currentUser) {
  if (!prAuthor || typeof prAuthor !== 'string') {
    return {
      isSelfApproval: false,
      error: 'Cannot determine PR author - allowing as precaution but flagging',
    }
  }

  if (!currentUser || typeof currentUser !== 'string' || currentUser === 'unknown') {
    return {
      isSelfApproval: false,
      error: 'Cannot determine current user - allowing as precaution but flagging',
    }
  }

  // Case-insensitive comparison since GitHub usernames are case-insensitive
  const isSelf = prAuthor.toLowerCase() === currentUser.toLowerCase()

  return {
    isSelfApproval: isSelf,
    error: isSelf ? `Self-approval detected: PR author (${prAuthor}) is the same as the approver (${currentUser})` : null,
  }
}

/**
 * Comprehensive authorization check before auto-approval
 * Verifies:
 * 1. Current user has write/maintain permissions
 * 2. Repository allows auto-approval in policy
 * 3. Branch protection rules don't block approval
 * 4. No conflicting authorization requirements
 *
 * @param {Object} agent - The agent function for executing commands
 * @param {Object} platform - Platform detection result
 * @param {string} baseBranch - Target branch for approval
 * @returns {Promise<Object>} { authorized: boolean, checks: Object, blockingReasons: Array }
 */
export async function performAuthorizationCheck(agent, platform, baseBranch = 'main') {
  const blockingReasons = []
  const checks = {}

  // 1. Get current user
  const userResult = await getCurrentUser(agent, platform)
  checks.currentUser = userResult

  if (userResult.error) {
    blockingReasons.push(`Cannot determine current user: ${userResult.error}`)
  }

  // 2. Check user permissions
  const permissionsResult = await checkUserPermissions(agent, platform, userResult.username)
  checks.userPermissions = permissionsResult

  if (!permissionsResult.hasPermission) {
    blockingReasons.push(
      `Insufficient permissions: ${permissionsResult.error || 'User cannot approve PRs'}`
    )
  }

  // 3. Check repository auto-approval policy
  const policyResult = await checkRepositoryAutoApprovalPolicy(agent, platform)
  checks.autoApprovalPolicy = policyResult

  if (!policyResult.autoApprovalEnabled) {
    blockingReasons.push(
      `Auto-approval policy violation: ${policyResult.error || 'Auto-approval not permitted'}`
    )
  }

  // 4. Check branch protection rules
  const branchProtectionResult = await checkBranchProtectionRules(agent, platform, baseBranch)
  checks.branchProtection = branchProtectionResult

  if (branchProtectionResult.blockers.length > 0) {
    blockingReasons.push(
      `Branch protection rules present: ${branchProtectionResult.blockers.join(', ')}`
    )
  }

  return {
    authorized: blockingReasons.length === 0,
    checks: checks,
    blockingReasons: blockingReasons,
  }
}
