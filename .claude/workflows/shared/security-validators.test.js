// Tests for shared/security-validators.js
// Issue #613: Validates the single-source-of-truth security validation functions
//
// Run: node .claude/workflows/shared/security-validators.test.js

import assert from 'node:assert'

// Inline the functions for testing (same pattern used by platform-detector.test.js)
// These must be kept in sync with security-validators.js

function sanitizeForShell(str, maxLength = 512) {
  if (typeof str !== 'string') {
    return ''
  }
  return str
    .replace(/[\\"$`;\x00\n\r&|<>()'!{}#~[\]]/g, '')
    .slice(0, maxLength)
}

function isValidFilePath(f) {
  if (typeof f !== 'string') return false
  if (f.trim().length === 0) return false
  if (f.length > 512) return false
  if (f.startsWith('/')) return false
  if (f.includes('..')) return false
  if (!/^[a-zA-Z0-9._/\-]+$/.test(f)) return false
  const segments = f.split('/')
  const sensitiveDirectories = /^(\.env.*|\.ssh|\.git|\.gnupg|\.aws|\.kube|\.docker|\.config)$/i
  for (const segment of segments.slice(0, -1)) {
    if (sensitiveDirectories.test(segment)) return false
  }
  const sensitiveFilePatterns = /(?:^|\/)\.env(?:\.|$)|credentials|secrets?\.|\.pem$|\.key$|\.p12$|\.pfx$|\.jks$|id_rsa|id_ed25519|id_ecdsa|\.token|\.secret|\.password|\.htpasswd|\.pgpass|\.netrc/i
  if (sensitiveFilePatterns.test(f)) return false
  return true
}

function isValidBranchName(name) {
  if (typeof name !== 'string') return false
  if (name.length === 0 || name.length > 128) return false
  if (!/^[a-zA-Z0-9._/\-]+$/.test(name)) return false
  if (name.includes('..')) return false
  if (name.startsWith('-')) return false
  return true
}

// ============================================================
// sanitizeForShell tests
// ============================================================

function testSanitizeForShell() {
  // Basic sanitization
  const testCases = [
    { input: 'hello world', expected: 'hello world' },
    { input: 'test; rm -rf /', expected: 'test rm -rf /' },
    { input: '$(whoami)', expected: 'whoami' },
    { input: '`whoami`', expected: 'whoami' },
    { input: 'a"b\'c', expected: 'abc' },
    { input: 'test\ninjection', expected: 'testinjection' },
    { input: 'test\x00null', expected: 'testnull' },
    { input: 'a & b | c', expected: 'a  b  c' },
    { input: 'a > /etc/passwd', expected: 'a  /etc/passwd' },
    { input: 'a#comment', expected: 'acomment' },
    { input: 'a~expansion', expected: 'aexpansion' },
    { input: 'a[glob]', expected: 'aglob' },
    { input: 123, expected: '' },
    { input: null, expected: '' },
    { input: undefined, expected: '' },
  ]

  testCases.forEach(({ input, expected }) => {
    const result = sanitizeForShell(input)
    assert.strictEqual(
      result, expected,
      `sanitizeForShell(${JSON.stringify(input)}) should be "${expected}", got "${result}"`
    )
  })

  // Test default max length (512)
  const longStr = 'a'.repeat(1000)
  assert.strictEqual(
    sanitizeForShell(longStr).length, 512,
    'sanitizeForShell should truncate to default maxLength of 512'
  )

  // Test custom max length
  assert.strictEqual(
    sanitizeForShell(longStr, 200).length, 200,
    'sanitizeForShell should respect custom maxLength'
  )

  console.log('PASS: sanitizeForShell')
}

// ============================================================
// isValidFilePath tests
// ============================================================

function testIsValidFilePath() {
  // Valid paths
  const validPaths = [
    'src/main.js',
    'package.json',
    '.claude/settings.json',
    '.github/workflows/ci.yml',
    'a/b/c/d.txt',
    'file-with-dashes.ts',
    'file_with_underscores.py',
  ]

  validPaths.forEach(p => {
    assert.strictEqual(isValidFilePath(p), true, `"${p}" should be valid`)
  })

  // Invalid paths
  const invalidPaths = [
    { path: '/etc/passwd', reason: 'absolute path' },
    { path: '../secret', reason: 'path traversal' },
    { path: 'a/../b', reason: 'path traversal mid-path' },
    { path: '.env', reason: 'sensitive file' },
    { path: '.env.production', reason: 'sensitive file variant' },
    { path: 'subdir/.env.local', reason: 'sensitive file in subdir' },
    { path: '.ssh/id_rsa', reason: 'SSH key directory' },
    { path: '.git/config', reason: 'git directory' },
    { path: '.aws/credentials', reason: 'AWS directory' },
    { path: 'server.key', reason: 'private key file' },
    { path: 'cert.pem', reason: 'PEM file' },
    { path: 'file with spaces.txt', reason: 'spaces in path' },
    { path: 'file;injection.txt', reason: 'semicolon' },
    { path: '', reason: 'empty string' },
    { path: '   ', reason: 'whitespace only' },
    { path: 123, reason: 'non-string' },
    { path: null, reason: 'null' },
    { path: 'a'.repeat(600), reason: 'path too long (>512)' },
  ]

  invalidPaths.forEach(({ path, reason }) => {
    assert.strictEqual(isValidFilePath(path), false, `"${path}" should be invalid (${reason})`)
  })

  console.log('PASS: isValidFilePath')
}

// ============================================================
// isValidBranchName tests
// ============================================================

function testIsValidBranchName() {
  // Valid branch names
  const validNames = [
    'main',
    'feature/issue-123',
    'fix/bug-456',
    'release/1.0.0',
    'my-branch',
    'my_branch',
    'my.branch',
  ]

  validNames.forEach(name => {
    assert.strictEqual(isValidBranchName(name), true, `"${name}" should be valid`)
  })

  // Invalid branch names
  const invalidNames = [
    { name: '', reason: 'empty' },
    { name: 'a'.repeat(129), reason: 'too long' },
    { name: '-starts-with-dash', reason: 'starts with dash' },
    { name: 'has spaces', reason: 'contains spaces' },
    { name: 'has;semicolon', reason: 'contains semicolon' },
    { name: 'has$dollar', reason: 'contains dollar' },
    { name: 'a..b', reason: 'path traversal' },
    { name: 123, reason: 'non-string' },
    { name: null, reason: 'null' },
  ]

  invalidNames.forEach(({ name, reason }) => {
    assert.strictEqual(isValidBranchName(name), false, `"${name}" should be invalid (${reason})`)
  })

  console.log('PASS: isValidBranchName')
}

// ============================================================
// Run all tests
// ============================================================

console.log('Running security-validators tests...\n')

testSanitizeForShell()
testIsValidFilePath()
testIsValidBranchName()

console.log('\nAll security-validators tests passed!')
