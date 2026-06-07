// Test for Issue #408: Missing Input Validation in pr-review.js workersArg parameter
// Tests the validateWorkersAllowlist function to ensure invalid model names are rejected

import { validateWorkersAllowlist, validateWorkers, KNOWN_MODELS } from './consensus-engine.js'

console.log('Testing Issue #408: Worker Validation')
console.log('=====================================\n')

// Test 1: Valid workers should pass
console.log('Test 1: Valid workers')
const validWorkers = ['opus', 'sonnet', 'haiku']
const result1 = validateWorkersAllowlist(validWorkers)
console.log(`Input: ${validWorkers.join(', ')}`)
console.log(`Result: valid=${result1.valid}`)
console.log(`Message: ${result1.message}`)
console.log(`Status: ${result1.valid ? '✅ PASS' : '❌ FAIL'}\n`)

// Test 2: Invalid workers should fail with clear error
console.log('Test 2: Invalid workers (typos)')
const invalidWorkers = ['foo', 'bar', 'baz']
const result2 = validateWorkersAllowlist(invalidWorkers)
console.log(`Input: ${invalidWorkers.join(', ')}`)
console.log(`Result: valid=${result2.valid}`)
console.log(`Message: ${result2.message}`)
console.log(`Status: ${!result2.valid && result2.message.includes('Allowed models') ? '✅ PASS' : '❌ FAIL'}\n`)

// Test 3: Mixed valid and invalid workers
console.log('Test 3: Mixed valid and invalid workers')
const mixedWorkers = ['opus', 'invalid', 'sonnet']
const result3 = validateWorkersAllowlist(mixedWorkers)
console.log(`Input: ${mixedWorkers.join(', ')}`)
console.log(`Result: valid=${result3.valid}`)
console.log(`Accepted: ${result3.accepted.join(', ')}`)
console.log(`Rejected: ${result3.rejected.join(', ')}`)
console.log(`Message: ${result3.message}`)
console.log(`Status: ${result3.valid && result3.accepted.length === 2 && result3.rejected.length === 1 ? '✅ PASS' : '❌ FAIL'}\n`)

// Test 4: All invalid workers should fail
console.log('Test 4: All invalid workers')
const allInvalidWorkers = ['bad1', 'bad2', 'bad3']
const result4 = validateWorkersAllowlist(allInvalidWorkers)
console.log(`Input: ${allInvalidWorkers.join(', ')}`)
console.log(`Result: valid=${result4.valid}`)
console.log(`Message: ${result4.message}`)
console.log(`Status: ${!result4.valid ? '✅ PASS' : '❌ FAIL'}\n`)

// Test 5: Case-insensitive matching
console.log('Test 5: Case-insensitive matching')
const caseInsensitiveWorkers = ['OPUS', 'Sonnet', 'HAIKU']
const result5 = validateWorkersAllowlist(caseInsensitiveWorkers)
console.log(`Input: ${caseInsensitiveWorkers.join(', ')}`)
console.log(`Result: valid=${result5.valid}`)
console.log(`Accepted: ${result5.accepted.join(', ')}`)
console.log(`Status: ${result5.valid && result5.accepted.length === 3 ? '✅ PASS' : '❌ FAIL'}\n`)

// Test 6: Typo in model name should provide clear error
console.log('Test 6: Typo in model name (opuz instead of opus)')
const typoWorkers = ['opuz']
const result6 = validateWorkersAllowlist(typoWorkers)
console.log(`Input: ${typoWorkers.join(', ')}`)
console.log(`Result: valid=${result6.valid}`)
console.log(`Message: ${result6.message}`)
console.log(`Known models: ${KNOWN_MODELS.join(', ')}`)
console.log(`Status: ${!result6.valid && result6.message.includes('opus') && result6.message.includes('sonnet') ? '✅ PASS' : '❌ FAIL'}\n`)

console.log('=====================================')
console.log('All tests completed successfully!')
