// Platform Detection and Git Operations
// Auto-detects GitHub/GitLab/Bitbucket and provides unified interface
// Used by: ALL workflows (100%)

/**
 * Sanitize a string for safe interpolation into double-quoted shell arguments.
 * Strips characters that enable command injection rather than escaping them,
 * because this string passes through multiple interpretation layers
 * (JS template literal -> AI agent prompt -> shell command) where escape
 * sequences can be misinterpreted or double-processed.
 *
 * Removed characters:
 *   " (ends double-quote), ` (command substitution),
 *   $ (variable/command expansion), \ (escape sequences),
 *   ; (command separator), & (background/AND chaining),
 *   | (pipe), < > (I/O redirection),
 *   ( ) (subshell execution), ' (single-quote context break),
 *   ! (bash history expansion), { } (brace expansion),
 *   # (comment / truncation), ~ (tilde expansion),
 *   [ ] (glob patterns),
 *   \0 (null byte), \n and \r (newline injection / argument splitting).
 *
 * A length limit prevents excessively long strings from causing issues.
 */
function sanitizeForShell(str, maxLength = 512) {
  if (typeof str !== 'string') {
    return ''
  }
  return str
    .replace(/[\\"$`;\x00\n\r&|<>()'!{}#~[\]]/g, '')
    .slice(0, maxLength)
}

/**
 * Sanitize a branch name for safe use in shell commands.
 * Branch names should only contain alphanumeric chars, hyphens, underscores,
 * dots, and forward slashes. Anything else is stripped.
 */
function sanitizeBranchName(name) {
  if (typeof name !== 'string') {
    return 'main'
  }
  const cleaned = name.replace(/[^a-zA-Z0-9._\-/]/g, '')
  return cleaned || 'main'
}

/**
 * Generate a cryptographically secure temporary file path.
 * Uses Node.js crypto for unpredictability and validates the path is safe.
 *
 * Security measures:
 * - Uses os.tmpdir() for portable temp directory detection
 * - Sanitizes purpose to alphanumeric/hyphens/underscores only (strips path
 *   separators, dots, and shell metacharacters to prevent directory traversal)
 * - Generates 128 bits of cryptographic randomness for the filename suffix
 * - Canonicalizes the result with path.resolve() to collapse any traversal
 * - Validates the final path is a direct child of the temp directory (no subdirectories)
 * - Validates the resolved temp directory itself is safe (no symlink, no traversal)
 *
 * @param {string} purpose - Short label for the temp file (e.g., 'issue-body').
 *   Only alphanumeric chars, hyphens, and underscores are kept; all other
 *   characters (including '/', '.', '..') are stripped before path construction.
 * @returns {string} A canonicalized, unpredictable temp file path under the system temp directory
 * @throws {Error} If purpose is invalid or the generated path fails validation
 */
function generateSecureTempPath(purpose) {
  const crypto = require('crypto')
  const path = require('path')
  const os = require('os')
  const fs = require('fs')

  // Validate and sanitize purpose: allow only alphanumeric, hyphens, underscores.
  // This prevents path separators, directory traversal sequences, and shell
  // metacharacters from being injected through the purpose parameter.
  if (typeof purpose !== 'string' || purpose.length === 0) {
    throw new Error('generateSecureTempPath: purpose must be a non-empty string')
  }
  const sanitizedPurpose = purpose.replace(/[^a-zA-Z0-9_-]/g, '')
  if (sanitizedPurpose.length === 0) {
    throw new Error(
      `generateSecureTempPath: purpose contains no valid characters (after sanitization of "${purpose}")`
    )
  }

  // Use os.tmpdir() for portability, then resolve to canonical absolute path.
  // Validate the temp directory itself is safe: it must exist, be a directory,
  // and not be a symlink (to prevent an attacker from controlling TMPDIR to
  // redirect writes to an arbitrary location).
  const tmpDir = path.resolve(os.tmpdir())
  try {
    const stat = fs.lstatSync(tmpDir)
    if (!stat.isDirectory()) {
      throw new Error(`System temp directory "${tmpDir}" is not a directory`)
    }
    if (stat.isSymbolicLink()) {
      throw new Error(`System temp directory "${tmpDir}" is a symlink (unsafe)`)
    }
  } catch (err) {
    if (err.code === 'ENOENT') {
      throw new Error(`System temp directory "${tmpDir}" does not exist`)
    }
    throw err
  }

  // Generate a cryptographically secure random suffix (32 hex chars = 128 bits entropy)
  const randomSuffix = crypto.randomBytes(16).toString('hex')

  // Create path with unpredictable suffix that prevents symlink attacks
  const tmpPath = path.join(tmpDir, `virtos-${sanitizedPurpose}-${randomSuffix}`)

  // Canonicalize the path using path.resolve() to collapse any traversal
  // sequences that might have slipped through, then validate it is a direct
  // child of the temp directory (not a subdirectory or symlinked location).
  const resolved = path.resolve(tmpPath)
  if (!resolved.startsWith(tmpDir + '/') || resolved.includes('..')) {
    throw new Error('Invalid temp file path generated (safety check failed)')
  }
  if (path.dirname(resolved) !== tmpDir) {
    throw new Error('Temp file path must be a direct child of the temp directory (no subdirectories)')
  }

  return resolved
}

/**
 * Write content to a temp file securely on the host side.
 * The host creates the file atomically with restricted permissions, eliminating
 * the entire class of TOCTOU vulnerabilities and content-boundary confusion
 * that arise from delegating file creation to the AI agent.
 *
 * Security measures:
 * - File is created exclusively (O_EXCL) to prevent symlink/race attacks
 * - Permissions are set to 0600 (owner read/write only) from creation
 * - Content is written directly by the host -- never passed through an agent prompt
 * - Path is validated against the system temp directory
 * - Computes SHA256 hash for post-hoc verification
 *
 * @param {string} tmpFilePath - The secure temporary file path (from generateSecureTempPath)
 * @param {string} content - The content to write to the file
 * @returns {{ path: string, hash: string }} The written file path and its SHA256 hash
 * @throws {Error} If the file already exists, path is invalid, or write fails
 */
function writeSecureTempFile(tmpFilePath, content) {
  const fs = require('fs')
  const path = require('path')
  const crypto = require('crypto')
  const os = require('os')

  // Validate inputs
  if (!tmpFilePath || typeof tmpFilePath !== 'string') {
    throw new Error('writeSecureTempFile: tmpFilePath must be a non-empty string')
  }
  if (typeof content !== 'string') {
    throw new Error('writeSecureTempFile: content must be a string')
  }

  // Resolve and validate path is within the system temp directory
  const tmpDir = path.resolve(os.tmpdir())
  const resolved = path.resolve(tmpFilePath)

  if (!resolved.startsWith(tmpDir + '/') || resolved.includes('..')) {
    throw new Error(
      `writeSecureTempFile: path must be inside the temp directory ("${tmpDir}") ` +
      `and contain no directory traversal sequences`
    )
  }
  if (path.dirname(resolved) !== tmpDir) {
    throw new Error(
      'writeSecureTempFile: path must be a direct child of the temp directory (no subdirectories)'
    )
  }

  // Defense-in-depth: validate the resolved path contains only safe characters.
  // This prevents shell metacharacter injection if the path is later interpolated
  // into a shell command by the agent (e.g., in --body-file arguments).
  if (!/^[a-zA-Z0-9/_.-]+$/.test(resolved)) {
    throw new Error(
      'writeSecureTempFile: path contains shell-unsafe characters. ' +
      'Path must contain only alphanumeric characters, hyphens, underscores, dots, and slashes.'
    )
  }

  // Atomically create and write the file with exclusive flag (O_EXCL).
  // This fails if the file already exists, preventing symlink attacks and
  // race conditions. The mode 0o600 restricts access to owner only.
  const fd = fs.openSync(resolved, fs.constants.O_WRONLY | fs.constants.O_CREAT | fs.constants.O_EXCL, 0o600)
  try {
    fs.writeSync(fd, content, 0, 'utf8')
  } finally {
    fs.closeSync(fd)
  }

  // Post-creation safety: verify the path is a regular file, not a symlink.
  // lstatSync does NOT follow symlinks, so if the path is a symlink it will
  // report isSymbolicLink() === true.
  const stat = fs.lstatSync(resolved)
  if (stat.isSymbolicLink()) {
    // Attempt cleanup before throwing
    try { fs.unlinkSync(resolved) } catch (_) { /* best-effort */ }
    throw new Error('writeSecureTempFile: created path is a symlink (possible race attack)')
  }
  if (!stat.isFile()) {
    try { fs.unlinkSync(resolved) } catch (_) { /* best-effort */ }
    throw new Error('writeSecureTempFile: created path is not a regular file')
  }

  // Compute SHA256 hash of the written content for verification
  const hash = crypto.createHash('sha256').update(content, 'utf8').digest('hex')

  return { path: resolved, hash }
}

/**
 * Clean up a temp file created by writeSecureTempFile.
 * Validates the path before deletion to prevent arbitrary file removal.
 *
 * @param {string} tmpFilePath - Path to the temp file to remove
 */
function cleanupTempFile(tmpFilePath) {
  const fs = require('fs')
  const path = require('path')
  const os = require('os')

  if (!tmpFilePath || typeof tmpFilePath !== 'string') {
    return // Nothing to clean up
  }

  const tmpDir = path.resolve(os.tmpdir())
  const resolved = path.resolve(tmpFilePath)

  // Only delete files that are direct children of the temp directory
  // and match the virtos- naming convention
  if (!resolved.startsWith(tmpDir + '/') || path.dirname(resolved) !== tmpDir) {
    return // Refuse to delete files outside temp directory
  }
  if (!/^virtos-[a-zA-Z0-9_-]+-[a-f0-9]{32}$/.test(path.basename(resolved))) {
    return // Refuse to delete files that do not match expected naming pattern
  }

  try {
    fs.unlinkSync(resolved)
  } catch (_) {
    // Best-effort cleanup; file may already be gone
  }
}

/**
 * Build secure temp file instructions for agent prompts.
 * The host has ALREADY created the temp file with the content written securely.
 * The agent only needs to verify the file exists, run the CLI command, and clean up.
 *
 * This eliminates the TOCTOU vulnerability window: the host creates the file
 * atomically with O_EXCL + mode 0600, writes the content directly, and computes
 * the SHA256 hash. The agent receives a pre-populated file path and only needs
 * to execute the CLI command that consumes it.
 *
 * Security measures:
 * - Host creates the file (agent never writes content, eliminating boundary confusion)
 * - File already has mode 0600 and correct content when agent receives the path
 * - Agent verifies the file is not a symlink and is a regular file before use
 * - Agent sets EXIT trap for guaranteed cleanup
 * - SHA256 hash provided for verification
 *
 * @param {string} tmpFilePath - The secure temporary file path (generated by host)
 * @param {string} cliCommand - The CLI command that uses the temp file via --body-file
 * @param {string} content - The content to write into the temp file (written by host)
 * @returns {string} Shell instructions for the agent prompt
 */
function secureTempFileInstructions(tmpFilePath, cliCommand, content) {
  const path = require('path')
  const os = require('os')

  // Validate inputs
  if (!tmpFilePath || typeof tmpFilePath !== 'string') {
    throw new Error('Invalid temp file path: must be a non-empty string')
  }
  if (!cliCommand || typeof cliCommand !== 'string') {
    throw new Error('Invalid CLI command: must be a non-empty string')
  }
  if (typeof content !== 'string') {
    throw new Error('Invalid content: must be a string')
  }

  // Validate the path is safe: canonicalize to collapse any traversal sequences,
  // then verify it is a direct child of the system temp directory.
  const tmpDir = path.resolve(os.tmpdir())
  const resolved = path.resolve(tmpFilePath)
  if (!resolved.startsWith(tmpDir + '/') || resolved.includes('..')) {
    throw new Error(
      `Invalid temp file path: must be inside the temp directory ("${tmpDir}") ` +
      `and contain no directory traversal sequences`
    )
  }
  if (path.dirname(resolved) !== tmpDir) {
    throw new Error('Invalid temp file path: must be a direct child of the temp directory (no subdirectories)')
  }

  // Defense-in-depth: validate that the resolved path contains only safe characters.
  if (!/^[a-zA-Z0-9/_.-]+$/.test(resolved)) {
    throw new Error(
      'Invalid temp file path: contains shell-unsafe characters. ' +
      'Path must contain only alphanumeric characters, hyphens, underscores, dots, and slashes.'
    )
  }

  // Write the file on the HOST side. This eliminates the TOCTOU window and
  // content-boundary confusion that arise from embedding content in the prompt.
  const { hash } = writeSecureTempFile(resolved, content)

  return `CRITICAL SECURITY REQUIREMENT: You MUST follow these steps EXACTLY.

The host system has securely created and populated the temp file at:
SAFE_TMPFILE="${resolved}"

The file was created by the host with these security properties:
- Created atomically with O_EXCL (fails if path already exists, preventing symlink attacks)
- Permissions: 0600 (owner read/write only, set at creation time via open flags)
- Content written directly by the host process (not passed through agent prompts)
- SHA256 hash of content: ${hash}

Execute these commands in this exact order:

1. Set a trap FIRST to ensure cleanup on error or exit:
   trap 'rm -f "$SAFE_TMPFILE"' EXIT

2. Verify the file is NOT a symlink (safety check):
   if [ -L "$SAFE_TMPFILE" ]; then echo "SECURITY ERROR: File is a symlink (attack detected)" >&2; rm -f "$SAFE_TMPFILE"; exit 1; fi

3. Verify it is a regular file with correct permissions:
   if [ ! -f "$SAFE_TMPFILE" ]; then echo "SECURITY ERROR: File does not exist or is not a regular file" >&2; exit 1; fi

4. Verify the content hash matches (detects tampering):
   EXPECTED_HASH="${hash}"
   ACTUAL_HASH="$(sha256sum "$SAFE_TMPFILE" | cut -d' ' -f1)"
   if [ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]; then echo "SECURITY ERROR: File content hash mismatch (expected $EXPECTED_HASH, got $ACTUAL_HASH)" >&2; rm -f "$SAFE_TMPFILE"; exit 1; fi

5. Run the CLI command:
${cliCommand}

6. After the CLI command succeeds, clean up the temp file:
   rm -f "$SAFE_TMPFILE"
   trap - EXIT

7. Report back with this JSON structure:
{
  "status": "success",
  "tmpfile_hash": "$ACTUAL_HASH",
  "commands_executed": true
}

SECURITY VALIDATION:
- The host system created and wrote this file: ${resolved}
- The content was written securely by the host (never embedded in the prompt)
- You MUST use EXACTLY this path, never create a different path
- You MUST NOT modify the file content before running the CLI command
- You MUST verify the SHA256 hash matches: ${hash}
- You MUST clean up the file after use
- Failure to follow any step constitutes a security violation and the operation will be retried`
}

/**
 * Validates that a platform object has a usable CLI configured.
 * Ensures the CLI is not 'none', is one of the known valid values,
 * and that the CLI tool actually exists and is executable on the system.
 *
 * Validation steps:
 * 1. Platform object is a valid object
 * 2. CLI value is not 'none' or missing
 * 3. CLI value is one of the known valid tools: ['gh', 'glab', 'bb']
 * 4. CLI tool exists and is executable on the system
 *
 * @param {Object} platform - Platform detection result
 * @throws {Error} If any validation fails
 * @returns {string} The validated CLI name
 */
function validatePlatformCLI(platform) {
  if (!platform || typeof platform !== 'object') {
    throw new Error('Invalid platform object provided')
  }

  const { cli, platform: platformName } = platform

  if (!cli || cli === 'none') {
    throw new Error(
      `No compatible CLI tool available for ${platformName || 'the repository'} platform. ` +
      `Please install 'gh' (GitHub), 'glab' (GitLab), or 'bb' (Bitbucket).`
    )
  }

  // Validate that cli is one of the known valid values
  const validCLIs = ['gh', 'glab', 'bb']
  if (!validCLIs.includes(cli)) {
    throw new Error(
      `Invalid or corrupted CLI value: "${cli}". ` +
      `Must be one of: ${validCLIs.join(', ')}`
    )
  }

  // Verify the CLI tool exists and is executable on the system
  // Using synchronous check to fail fast before attempting any CLI commands
  const { execSync } = require('child_process')
  try {
    // 'which' returns the path if the command exists and is executable
    // Redirect stderr to prevent error output if command is not found
    execSync(`which ${cli}`, { stdio: 'pipe', encoding: 'utf8' })
  } catch (error) {
    throw new Error(
      `CLI tool "${cli}" is not installed or not accessible on this system. ` +
      `Please install the tool and ensure it is in your PATH. ` +
      `(Error: ${error.message})`
    )
  }

  return cli
}

export async function detectPlatform(agent) {
  const result = await agent(`Detect the repository platform and return details.

Execute these commands:
git remote get-url origin
which gh
which glab

Based on the remote URL and available CLIs, determine:
- Platform (github, gitlab, or bitbucket)
- CLI tool available (gh, glab, or bb)
- Repository owner/name

Return structured data.`, {
    label: 'Detect Platform',
    schema: {
      type: 'object',
      properties: {
        platform: { type: 'string', enum: ['github', 'gitlab', 'bitbucket', 'unknown'] },
        cli: { type: 'string', enum: ['gh', 'glab', 'bb', 'none'] },
        remote_url: { type: 'string' },
        repo_owner: { type: 'string' },
        repo_name: { type: 'string' },
      },
      required: ['platform', 'cli', 'remote_url'],
    }
  })

  return result
}

export async function syncWithRemote(agent, options = {}) {
  const result = await agent(`Sync with remote repository safely.

CRITICAL SAFETY RULES:
- NEVER run "git rebase" under any circumstances
- NEVER rewrite local commit history
- Only use fast-forward merges (git pull --ff-only)
- If fast-forward is not possible, STOP and report - do not force or merge

Execute these steps in order:

1. Detect the current branch:
   git branch --show-current

2. Check for uncommitted changes:
   git status --porcelain

3. If there are uncommitted changes, return status "not_clean" with the list of changed files.
   DO NOT proceed with sync if there are uncommitted changes.

4. If working tree is clean, check if the current branch has a remote tracking branch:
   git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null

   If there is no remote tracking branch (command fails), return status "success" with
   message "No remote tracking branch configured - skipping sync" and include current_branch.
   This is normal for new local branches that have not been pushed yet.

5. Fetch the latest remote:
   git fetch origin

6. Check if local and remote have diverged (local has commits not on remote AND remote has commits not on local):
   LOCAL_AHEAD=$(git rev-list @{u}..HEAD --count 2>/dev/null || echo "0")
   REMOTE_AHEAD=$(git rev-list HEAD..@{u} --count 2>/dev/null || echo "0")

   - If REMOTE_AHEAD is 0, the branch is already up to date. Return status "up_to_date".
   - If LOCAL_AHEAD > 0 AND REMOTE_AHEAD > 0, the branches have diverged.
     Return status "diverged" with message explaining that there are LOCAL_AHEAD unpushed
     local commits and REMOTE_AHEAD new remote commits. The user must resolve this manually.
   - If LOCAL_AHEAD is 0 AND REMOTE_AHEAD > 0, safe to fast-forward. Continue to step 7.

7. Perform a fast-forward-only pull (safe sync, no rebase, no merge commit):
   git pull --ff-only

8. Capture the result:
   - If the pull succeeds, return status "success"
   - If it fails with "fatal: Not possible to fast-forward", return status "diverged"
   - If it fails for another reason, return status "failed"

Return the sync operation result with:
- status: one of 'success', 'not_clean', 'diverged', 'failed', or 'up_to_date'
- message: Detailed message explaining the result
- uncommitted_files: Array of files with uncommitted changes (only if status is "not_clean")
- current_branch: The branch that was detected in step 1
- unpushed_commits: Number of local commits not yet pushed (0 if none)`, {
    label: 'Sync with Remote (Safe)',
    schema: {
      type: 'object',
      properties: {
        status: { type: 'string', enum: ['success', 'not_clean', 'diverged', 'failed', 'up_to_date'] },
        message: { type: 'string' },
        uncommitted_files: { type: 'array', items: { type: 'string' } },
        current_branch: { type: 'string' },
        unpushed_commits: { type: 'number' },
      },
      required: ['status', 'message'],
    }
  })

  return result
}

export async function createIssue(agent, platform, title, body, labels = []) {
  const cli = validatePlatformCLI(platform)

  // Strip dangerous shell metacharacters from title and labels.
  // Stripping is safer than escaping when the string crosses multiple
  // interpretation layers (JS -> AI prompt -> shell command).
  const sanitizedTitle = sanitizeForShell(String(title))
  const sanitizedLabels = labels.map(label => sanitizeForShell(String(label)))
  const labelStr = sanitizedLabels.length > 0 ? sanitizedLabels.join(',') : ''

  // DO NOT pre-sanitize body content. The secureTempFileInstructions function
  // will write it as a literal string to the temp file, bypassing shell interpretation.
  // Pre-sanitization would strip legitimate content characters.
  const bodyContent = String(body)

  // Generate a cryptographically secure temp file path on the host system.
  // This prevents symlink attacks by ensuring the path is unpredictable
  // and cannot be pre-exploited before the agent creates the file.
  const secureFilePath = generateSecureTempPath('issue-body')

  const cliCommand = `${cli} issue create --title "${sanitizedTitle}" --body-file "$SAFE_TMPFILE" ${labelStr ? `--label "${labelStr}"` : ''}`
  const tempInstructions = secureTempFileInstructions(secureFilePath, cliCommand, bodyContent)

  const result = await agent(`Create a GitHub/GitLab issue.

Platform: ${platform.platform}
CLI: ${cli}

${tempInstructions}

Return the issue URL.`, {
    label: 'Create Issue',
    schema: {
      type: 'object',
      properties: {
        issue_url: { type: 'string' },
        issue_number: { type: 'number' },
        status: { type: 'string', enum: ['created', 'failed'] },
      },
      required: ['status'],
    }
  })

  return result
}

export async function createPR(agent, platform, title, body, options = {}) {
  const {
    baseBranch = 'main',
    headBranch = 'current',
    labels = [],
    draft = false
  } = options

  const cli = validatePlatformCLI(platform)

  // Strip dangerous shell metacharacters from title and labels.
  // Stripping is safer than escaping when the string crosses multiple
  // interpretation layers (JS -> AI prompt -> shell command).
  const sanitizedTitle = sanitizeForShell(String(title))
  const sanitizedLabels = labels.map(label => sanitizeForShell(String(label)))
  const labelStr = sanitizedLabels.length > 0 ? sanitizedLabels.join(',') : ''

  // DO NOT pre-sanitize body content. The secureTempFileInstructions function
  // will write it as a literal string to the temp file, bypassing shell interpretation.
  // Pre-sanitization would strip legitimate content characters.
  const bodyContent = String(body)

  // Validate branch name with strict allowlist (alphanumeric, hyphens,
  // underscores, dots, slashes only)
  const sanitizedBaseBranch = sanitizeBranchName(String(baseBranch))

  const draftFlag = draft ? '--draft' : ''

  // Generate a cryptographically secure temp file path on the host system.
  // This prevents symlink attacks by ensuring the path is unpredictable
  // and cannot be pre-exploited before the agent creates the file.
  const secureFilePath = generateSecureTempPath('pr-body')

  const cliCommand = `${cli} pr create --title "${sanitizedTitle}" --body-file "$SAFE_TMPFILE" --base ${sanitizedBaseBranch} ${labelStr ? `--label "${labelStr}"` : ''} ${draftFlag}`
  const tempInstructions = secureTempFileInstructions(secureFilePath, cliCommand, bodyContent)

  const result = await agent(`Create a Pull Request / Merge Request.

Platform: ${platform.platform}
CLI: ${cli}

${tempInstructions}

Return the PR URL.`, {
    label: 'Create PR',
    schema: {
      type: 'object',
      properties: {
        pr_url: { type: 'string' },
        pr_number: { type: 'number' },
        status: { type: 'string', enum: ['created', 'failed'] },
      },
      required: ['status'],
    }
  })

  return result
}

export async function fetchIssue(agent, platform, issueNumber) {
  // FIX #410: Strict validation using regex instead of parseInt + isNaN.
  // parseInt('42abc') returns 42 and isNaN returns false, so '42abc' would be
  // treated as valid. The regex /^\d+$/ ensures the entire string is purely
  // numeric with no trailing content.
  const issueNumStr = String(issueNumber).trim()
  if (!/^\d+$/.test(issueNumStr)) {
    throw new Error(`Invalid issue number: "${issueNumber}". Must be a positive integer (digits only).`)
  }
  const num = parseInt(issueNumStr, 10)

  const cli = validatePlatformCLI(platform)

  const result = await agent(`Fetch issue details.

Platform: ${platform.platform}
Issue Number: ${num}

Execute:
${cli} issue view ${num} --json title,body,labels,state,author,url

Parse and return the issue details.`, {
    label: `Fetch Issue #${num}`,
    schema: {
      type: 'object',
      properties: {
        number: { type: 'number' },
        title: { type: 'string' },
        body: { type: 'string' },
        state: { type: 'string' },
        author: { type: 'string' },
        url: { type: 'string' },
        labels: { type: 'array', items: { type: 'string' } },
      },
      required: ['number', 'title', 'body', 'state'],
    }
  })

  return result
}

export async function fetchPR(agent, platform, prNumber) {
  // FIX #410: Strict validation using regex instead of parseInt + isNaN.
  // parseInt('42abc') returns 42 and isNaN returns false, so '42abc' would be
  // treated as valid. The regex /^\d+$/ ensures the entire string is purely
  // numeric with no trailing content.
  const prNumStr = String(prNumber).trim()
  if (!/^\d+$/.test(prNumStr)) {
    throw new Error(`Invalid PR number: "${prNumber}". Must be a positive integer (digits only).`)
  }
  const num = parseInt(prNumStr, 10)

  const cli = validatePlatformCLI(platform)

  const result = await agent(`Fetch PR/MR details.

Platform: ${platform.platform}
PR Number: ${num}

Execute:
${cli} pr view ${num} --json title,body,labels,state,author,url,headRefName,baseRefName,headRefOid

Parse and return the PR details. If headRefName or baseRefName are missing from the response (e.g., for draft PRs), use sensible defaults like 'main' for baseRefName. Map headRefOid to head_sha if present.`, {
    label: `Fetch PR #${num}`,
    schema: {
      type: 'object',
      properties: {
        number: { type: 'number' },
        title: { type: 'string' },
        body: { type: 'string' },
        state: { type: 'string' },
        author: { type: 'string' },
        url: { type: 'string' },
        head_branch: { type: 'string' },
        base_branch: { type: 'string' },
        head_sha: { type: 'string' },
        labels: { type: 'array', items: { type: 'string' } },
      },
      required: ['number', 'title', 'body', 'state', 'head_branch', 'base_branch'],
    }
  })

  return result
}

export async function postComment(agent, platform, issueOrPR, number, comment) {
  const validatedNumber = parseInt(String(number), 10)
  if (isNaN(validatedNumber) || validatedNumber <= 0) {
    throw new Error(`Invalid ${issueOrPR} number: "${number}". Must be a positive integer.`)
  }

  const cli = validatePlatformCLI(platform)
  const type = issueOrPR === 'issue' ? 'issue' : 'pr'

  // DO NOT pre-sanitize comment content. The secureTempFileInstructions function
  // will write it as a literal string to the temp file, bypassing shell interpretation.
  // Pre-sanitization would strip legitimate content characters.
  const commentContent = String(comment)

  // Generate a cryptographically secure temp file path on the host system.
  // This prevents symlink attacks by ensuring the path is unpredictable
  // and cannot be pre-exploited before the agent creates the file.
  const secureFilePath = generateSecureTempPath('comment')

  const cliCommand = `${cli} ${type} comment ${validatedNumber} --body-file "$SAFE_TMPFILE"`
  const tempInstructions = secureTempFileInstructions(secureFilePath, cliCommand, commentContent)

  const result = await agent(`Post a comment to ${type} #${validatedNumber}.

Platform: ${platform.platform}

${tempInstructions}

Return success status.`, {
    label: `Comment on ${type} #${validatedNumber}`,
    schema: {
      type: 'object',
      properties: {
        status: { type: 'string', enum: ['posted', 'failed'] },
      },
      required: ['status'],
    }
  })

  return result
}

// Export security helpers for testing and reuse by other workflow modules
export {
  sanitizeForShell,
  sanitizeBranchName,
  generateSecureTempPath,
  writeSecureTempFile,
  cleanupTempFile,
  secureTempFileInstructions,
  validatePlatformCLI,
}
