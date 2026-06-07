// Security Validators - Single source of truth for security validation functions
// Used by: code-improve.js, code-solve.js, platform-detector.js, and any future workflows
//
// Issue #613: Extracted from duplicated copies across workflows to ensure
// consistent security boundaries. Previously, sanitizeForShell had 3 copies
// and isValidFilePath had 2 copies with divergent behavior.
//
// Security policy decisions consolidated here:
// - sanitizeForShell: Uses the MOST restrictive character set (from platform-detector.js)
//   which strips ' # ~ [ ] \0 in addition to the base set. All callers now get
//   the same protection level.
// - isValidFilePath: Uses the MOST restrictive validation (from code-solve.js)
//   which includes length limits. All callers now get path length protection.
// - isValidBranchName: Extracted from code-solve.js for reuse.

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
 *   [ ] (glob patterns), * ? (glob wildcards),
 *   \0 (null byte), \n and \r (newline injection / argument splitting).
 *
 * A length limit prevents excessively long strings from causing issues.
 *
 * @param {*} str - The string to sanitize
 * @param {number} maxLength - Maximum output length (default: 512)
 * @returns {string} Sanitized string safe for shell interpolation
 */
export function sanitizeForShell(str, maxLength = 512) {
  if (typeof str !== 'string') {
    return ''
  }
  return str
    .replace(/[\\"$`;\x00\n\r&|<>()'!{}#~[\]*?]/g, '')
    .slice(0, maxLength)
}

/**
 * Validate a file path is safe for git operations.
 *
 * Checks:
 * - Must be a string
 * - Must not be empty or whitespace-only
 * - Must not exceed 512 characters (filesystem limit protection)
 * - Must not be an absolute path (no leading /)
 * - Must not use path traversal (../ or standalone ..)
 * - Must contain only safe characters (alphanumeric, dots, underscores, hyphens, forward slashes)
 * - Must not target sensitive directories (.env*, .ssh, .git, .gnupg, .aws, .kube, .docker, .config)
 * - Must not target sensitive files (credentials, keys, tokens, secrets, etc.)
 *
 * Allowed: .claude/ and .github/ directories.
 *
 * @param {*} f - The file path to validate
 * @returns {boolean} true if the path is safe for git operations
 */
export function isValidFilePath(f) {
  if (typeof f !== 'string') return false
  // Reject empty or whitespace-only
  if (f.trim().length === 0) return false
  // Reject overly long paths (filesystem limit is typically 255 per component, 4096 total)
  if (f.length > 512) return false
  // Reject absolute paths
  if (f.startsWith('/')) return false
  // Reject path traversal (both ../ and standalone ..)
  if (f.includes('..')) return false
  // Only allow safe characters: alphanumeric, dots, underscores, hyphens, forward slashes
  // This implicitly blocks shell metacharacters: quotes, backticks, $, ;, |, &, spaces, etc.
  if (!/^[a-zA-Z0-9._/\-]+$/.test(f)) return false
  // Reject paths that target sensitive files anywhere in the path (not just at the root).
  // Check each path segment for sensitive directory names, and the full path for sensitive
  // file patterns. Allow .claude/ and .github/ but block .env*, .ssh/, .git/, .gnupg/, .aws/, .kube/, etc.
  const segments = f.split('/')
  const sensitiveDirectories = /^(\.env.*|\.ssh|\.git|\.gnupg|\.aws|\.kube|\.docker|\.config)$/i
  for (const segment of segments.slice(0, -1)) {
    if (sensitiveDirectories.test(segment)) return false
  }
  // Check filename and full path for sensitive file patterns (no start anchors so they
  // match at any depth, e.g. "subdir/.env.production" or "certs/server.key")
  const sensitiveFilePatterns = /(?:^|\/)\.env(?:\.|$)|credentials|secrets?\.|\.pem$|\.key$|\.p12$|\.pfx$|\.jks$|id_rsa|id_ed25519|id_ecdsa|\.token|\.secret|\.password|\.htpasswd|\.pgpass|\.netrc/i
  if (sensitiveFilePatterns.test(f)) return false
  return true
}

/**
 * Validate a git branch name returned from agent output.
 * Branch names must match a strict alphanumeric pattern to prevent injection.
 *
 * Checks:
 * - Must be a string
 * - Must be between 1 and 128 characters
 * - Must contain only safe characters (alphanumeric, dots, underscores, hyphens, forward slashes)
 * - Must not contain path traversal (..)
 * - Must not start with a hyphen (could be interpreted as git flags)
 *
 * @param {*} name - The branch name to validate
 * @returns {boolean} true if the branch name is safe for git operations
 */
export function isValidBranchName(name) {
  if (typeof name !== 'string') return false
  if (name.length === 0 || name.length > 128) return false
  // Only allow safe branch name characters: alphanumeric, dots, underscores, hyphens, forward slashes
  // This blocks shell metacharacters, spaces, and other dangerous characters
  if (!/^[a-zA-Z0-9._/\-]+$/.test(name)) return false
  // Reject path traversal
  if (name.includes('..')) return false
  // Reject names starting with hyphen (could be interpreted as git flags)
  if (name.startsWith('-')) return false
  return true
}
