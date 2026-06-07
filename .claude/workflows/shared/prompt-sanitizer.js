/**
 * Prompt Sanitizer - Prevents prompt injection attacks in AI review prompts
 * Used by: pr-review, code-review, and other workflows that interpolate user content into AI prompts
 *
 * Issue #432: Security - Prompt Injection Vulnerability
 * Protects against malicious PR metadata being used to manipulate AI review assessments.
 *
 * Defense-in-depth strategy:
 * 1. Neutralize instruction-like patterns that attempt to override the system prompt
 * 2. Enforce per-field length limits to prevent payload smuggling via truncation
 * 3. Structured prompt formatting with explicit data delimiters (<user-data> tags)
 *    that clearly separate system instructions from user-controlled content
 * 4. Truncate diff at line boundaries (not mid-line) to avoid splitting payloads
 *
 * Design decisions:
 * - Patterns match multi-word PHRASES, not single words, to avoid false positives
 *   on legitimate code content (e.g., "override" alone is fine, but "override all
 *   previous instructions" is an injection attempt)
 * - Diff content preserves code formatting (backticks, angle brackets) because
 *   diffs are already wrapped in code fences in the prompt; mangling them would
 *   reduce review quality
 * - Replaced content is marked with [SANITIZED:reason] so reviewers can see
 *   that an injection attempt was detected
 */

/**
 * Sanitize user-controlled text before interpolation into AI review prompts.
 * Removes multi-word patterns commonly used in prompt injection attacks while
 * preserving legitimate single-word usage (e.g., "override" in code comments).
 *
 * @param {*} input - The input to sanitize (should be a string)
 * @param {number} maxLength - Maximum length before truncation (default: 3000)
 * @returns {string} Sanitized string safe for prompt interpolation
 */
export function sanitizePromptInput(input, maxLength = 3000) {
  // Handle non-string inputs
  if (!input || typeof input !== 'string') {
    return ''
  }

  let sanitized = input

  // 1. Remove null bytes and control characters (keep newlines and tabs for formatting)
  sanitized = sanitized.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '')

  // 2. Neutralize multi-word prompt injection phrases (case-insensitive).
  //    These match PHRASES, not individual words, to avoid false positives.
  //    Each pattern targets a specific injection technique.
  const injectionPatterns = [
    // Instruction override attempts
    { pattern: /ignore\s+(all\s+)?(previous|above|prior|earlier|preceding)\s+(instructions|prompts?|rules|guidelines|context)/gi, reason: 'instruction-override' },
    { pattern: /disregard\s+(all\s+)?(previous|above|prior|earlier|preceding)\s+(instructions|prompts?|rules|guidelines|context)/gi, reason: 'instruction-override' },
    { pattern: /forget\s+(all\s+)?(your|the|my)?\s*(previous|above|prior|earlier)?\s*(instructions|prompts?|rules|guidelines|context)/gi, reason: 'instruction-override' },
    { pattern: /override\s+(all\s+)?(your|the|my)?\s*(previous|above|prior|earlier)?\s*(instructions|prompts?|rules|guidelines|context)/gi, reason: 'instruction-override' },
    // Role/identity hijacking
    { pattern: /new\s+instructions?\s*:/gi, reason: 'role-hijack' },
    { pattern: /system\s+prompt\s*:/gi, reason: 'role-hijack' },
    { pattern: /you\s+are\s+now\s+a\s/gi, reason: 'role-hijack' },
    { pattern: /act\s+as\s+if\s+you\s/gi, reason: 'role-hijack' },
    { pattern: /pretend\s+(you\s+are|to\s+be)\s+a\s/gi, reason: 'role-hijack' },
    { pattern: /your\s+new\s+role\s+is/gi, reason: 'role-hijack' },
    // Score/approval manipulation
    { pattern: /approve\s+this\s+(pr|pull\s+request|merge\s+request)\s+(with\s+)?(score|rating)\s+\d+/gi, reason: 'score-manipulation' },
    { pattern: /set\s+(the\s+)?(quality\s+)?(score|rating)\s+to\s+\d+/gi, reason: 'score-manipulation' },
    { pattern: /always\s+(approve|accept|merge)\s+(this|the|all|every)/gi, reason: 'approval-manipulation' },
    { pattern: /must\s+(approve|accept|merge)\s+(this|the|all|every)/gi, reason: 'approval-manipulation' },
    // Suppression of findings
    { pattern: /do\s+not\s+(report|flag|mention|find|list)\s+(any\s+)?(issues?|bugs?|problems?|vulnerabilities|errors?|flaws?)/gi, reason: 'finding-suppression' },
    { pattern: /skip\s+(the\s+)?(security|code|quality)\s+(review|check|scan|analysis)/gi, reason: 'finding-suppression' },
    // Security bypass phrases
    { pattern: /(ignore|disregard|override|bypass|skip)\s+(all\s+)?(security|safety|approval|authentication|authorization)\s+(checks?|rules?|restrictions?|safeguards?|guidelines?|policies?|requirements?)/gi, reason: 'security-bypass' },
  ]

  for (const { pattern, reason } of injectionPatterns) {
    sanitized = sanitized.replace(pattern, `[SANITIZED:${reason}]`)
  }

  // 3. Enforce length limit with truncation at word boundary when possible
  if (sanitized.length > maxLength) {
    sanitized = sanitized.substring(0, maxLength)
    // Try to truncate at last space for cleaner output
    const lastSpace = sanitized.lastIndexOf(' ', maxLength)
    if (lastSpace > maxLength * 0.8) {
      sanitized = sanitized.substring(0, lastSpace)
    }
    sanitized += '\n[TRUNCATED at ' + maxLength + ' chars]'
  }

  return sanitized.trim()
}

/**
 * Validates a string before interpolating it into prompts.
 * Detects suspicious patterns that might indicate injection attempts.
 * This is a detection-only function (does not modify input).
 *
 * @param {*} input - The input to validate
 * @param {object} options - Validation options
 * @returns {object} - { valid: boolean, warnings: string[] }
 */
export function validatePromptInput(input, options = {}) {
  const { maxLength = 5000 } = options
  const warnings = []

  // Type check
  if (!input || typeof input !== 'string') {
    return { valid: false, warnings: ['Input is empty or not a string'] }
  }

  // Pattern detection (detect but don't modify)
  const suspiciousPatterns = [
    { regex: /\\u[0-9a-f]{4}/gi, name: 'Unicode escape sequences' },
    { regex: /eval\s*\(/gi, name: 'JavaScript eval() calls' },
    { regex: /exec\s*\(/gi, name: 'Code execution keywords' },
    { regex: /system\s*\(/gi, name: 'System command execution' },
    { regex: /\$\{[^}]*\}/g, name: 'Template injection patterns' },
    { regex: /<!--[\s\S]*?-->/g, name: 'HTML comments (potential instruction hiding)' },
    { regex: /<script[\s\S]*?<\/script>/gi, name: 'Script tags' },
  ]

  suspiciousPatterns.forEach(({ regex, name }) => {
    if (regex.test(input)) {
      warnings.push(`Contains ${name}`)
    }
  })

  // Length check
  if (input.length > maxLength) {
    warnings.push(`Very long input (${input.length} chars) exceeds maximum of ${maxLength} - potential context exhaustion attack`)
  }

  return {
    valid: warnings.length === 0,
    warnings: warnings.length > 0 ? warnings : undefined
  }
}

/**
 * Sanitize PR metadata before interpolating into review prompts.
 * Applies field-specific length limits and injection sanitization.
 *
 * @param {object} pr - The PR object with title, author, body fields
 * @returns {object} - Sanitized PR object safe for prompt interpolation
 */
export function sanitizePRMetadata(pr) {
  if (!pr || typeof pr !== 'object') {
    return {
      title: '[invalid PR data]',
      author: '[invalid PR data]',
      body: '[invalid PR data]',
      head_branch: '[invalid PR data]',
      base_branch: '[invalid PR data]',
    }
  }

  return {
    // Title: short, no code blocks expected - tight limit
    title: sanitizePromptInput(pr.title, 500),
    // Author: username/email - very tight limit
    author: sanitizePromptInput(pr.author, 200),
    // Body: can be long with markdown - moderate limit
    body: sanitizePromptInput(pr.body, 5000),
    // Branch names: should be short identifiers
    head_branch: sanitizeBranchForPrompt(pr.head_branch),
    base_branch: sanitizeBranchForPrompt(pr.base_branch),
    // Preserve numeric fields as-is
    ...(pr.number !== undefined && { number: pr.number }),
  }
}

/**
 * Sanitize a branch name for prompt inclusion.
 * Branch names should contain only safe characters.
 *
 * @param {string} name - Raw branch name
 * @returns {string} Sanitized branch name
 */
function sanitizeBranchForPrompt(name) {
  if (typeof name !== 'string' || name.length === 0) {
    return '[unknown]'
  }
  // Allow only alphanumeric, hyphens, underscores, dots, slashes
  const cleaned = name.replace(/[^a-zA-Z0-9._\-/]/g, '').substring(0, 200)
  return cleaned || '[invalid-branch]'
}

/**
 * Sanitize diff content before interpolating into review prompts.
 * Preserves code formatting (backticks, angle brackets) since diffs are
 * wrapped in code fences in the prompt. Applies injection pattern filtering
 * and truncates at line boundaries.
 *
 * @param {string} diff - The diff content to sanitize
 * @param {number} maxChars - Maximum characters to include (default: 50000)
 * @returns {string} Sanitized diff safe for prompt interpolation
 */
export function sanitizeDiffContent(diff, maxChars = 50000) {
  if (!diff || typeof diff !== 'string') {
    return '[no diff content]'
  }

  // Apply prompt injection pattern filtering (but not format escaping -
  // diffs need their original formatting preserved for review quality)
  let sanitized = sanitizePromptInput(diff, maxChars)

  // Truncate at the last complete line boundary if over limit
  if (sanitized.length > maxChars) {
    const lastNewline = sanitized.lastIndexOf('\n', maxChars)
    if (lastNewline > 0) {
      sanitized = sanitized.substring(0, lastNewline) + '\n[DIFF TRUNCATED AT LINE BOUNDARY]'
    }
  }

  return sanitized
}

/**
 * Pre-flight check for all PR review inputs.
 * Validates and sanitizes PR metadata and diff content before processing.
 * Returns sanitized versions of all inputs plus any warnings detected.
 *
 * @param {object} pr - The PR object
 * @param {string} diff - The diff content
 * @param {object} options - Options for validation
 * @returns {object} - { valid: boolean, pr: object, diff: string, warnings: string[] }
 */
export function validateAndSanitizePRContent(pr, diff, options = {}) {
  const warnings = []

  // Validate PR object
  if (!pr || typeof pr !== 'object') {
    return {
      valid: false,
      pr: null,
      diff: null,
      warnings: ['Invalid PR object provided']
    }
  }

  // Validate and collect warnings from PR fields
  const prFields = ['title', 'author', 'body']
  prFields.forEach(field => {
    const validation = validatePromptInput(pr[field], { maxLength: 5000 })
    if (!validation.valid && validation.warnings) {
      warnings.push(`PR.${field}: ${validation.warnings.join(', ')}`)
    }
  })

  // Validate diff
  const diffValidation = validatePromptInput(diff, { maxLength: 60000 })
  if (!diffValidation.valid && diffValidation.warnings) {
    warnings.push(`Diff: ${diffValidation.warnings.join(', ')}`)
  }

  // Sanitize all content
  const sanitizedPR = sanitizePRMetadata(pr)
  const sanitizedDiff = sanitizeDiffContent(diff)

  return {
    valid: warnings.length === 0,
    pr: sanitizedPR,
    diff: sanitizedDiff,
    warnings: warnings.length > 0 ? warnings : undefined
  }
}
