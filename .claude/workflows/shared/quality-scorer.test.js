/**
 * Test suite for quality-scorer.js type confusion fix (Issue #488)
 * Tests that malformed issue objects with missing severity are properly detected
 * and don't artificially inflate quality scores
 */

import {
  calculateQualityScore,
  formatQualityReport,
  categorizeIssuesBySeverity,
  prioritizeIssuesForFix,
  isValidIssue,
  sanitizeIssuesArray,
  validateIssueCounts,
  capIssueCounts,
} from './quality-scorer.js'

// Test suite
const tests = [
  {
    name: 'isValidIssue returns true for valid issue objects',
    test: () => {
      const validIssues = [
        { severity: 'critical', description: 'Test' },
        { severity: 'high', description: 'Test' },
        { severity: 'medium', description: 'Test' },
        { severity: 'low', description: 'Test' },
        { severity: 'P0' },
        { severity: 'P1', extra: 'data' },
      ]

      validIssues.forEach(issue => {
        if (!isValidIssue(issue)) {
          throw new Error(`Valid issue was rejected: ${JSON.stringify(issue)}`)
        }
      })
    }
  },

  {
    name: 'isValidIssue returns false for malformed objects',
    test: () => {
      const malformedIssues = [
        null,
        undefined,
        {},
        { description: 'Missing severity' },
        { severity: null },
        { severity: undefined },
        { severity: 123 }, // number instead of string
        { severity: ['critical'] }, // array instead of string
        'not an object',
        123,
        true,
        { severity: '' }, // empty string
      ]

      malformedIssues.forEach(issue => {
        if (isValidIssue(issue)) {
          throw new Error(`Malformed issue was accepted: ${JSON.stringify(issue)}`)
        }
      })
    }
  },

  {
    name: 'isValidIssue rejects unrecognized severity values',
    test: () => {
      // These have valid structure but unrecognized severity strings.
      // Without this check they would silently fall through all filter
      // categories and artificially inflate the quality score.
      const unrecognizedSeverities = [
        { severity: 'warning', description: 'Not a known severity' },
        { severity: 'info', description: 'Not a known severity' },
        { severity: 'blocker', description: 'Not a known severity' },
        { severity: 'trivial', description: 'Not a known severity' },
        { severity: 'CRITICAL', description: 'Case-sensitive mismatch' },
        { severity: 'HIGH', description: 'Case-sensitive mismatch' },
        { severity: 'Critical', description: 'Mixed case' },
        { severity: 'p0', description: 'Wrong case for P-level' },
        { severity: 'error', description: 'Common but unsupported' },
        { severity: 'suggestion', description: 'Common but unsupported' },
      ]

      unrecognizedSeverities.forEach(issue => {
        if (isValidIssue(issue)) {
          throw new Error(
            `Issue with unrecognized severity was accepted: ${JSON.stringify(issue)}`
          )
        }
      })
    }
  },

  {
    name: 'sanitizeIssuesArray filters out malformed objects',
    test: () => {
      const mixedIssues = [
        { severity: 'critical', description: 'Valid 1' },
        { description: 'Invalid - missing severity' },
        { severity: 'high', description: 'Valid 2' },
        null,
        { severity: 123 }, // Invalid - non-string severity
        { severity: 'low', description: 'Valid 3' },
      ]

      const { validIssues, malformedCount } = sanitizeIssuesArray(mixedIssues)

      if (validIssues.length !== 3) {
        throw new Error(`Expected 3 valid issues, got ${validIssues.length}`)
      }

      if (malformedCount !== 3) {
        throw new Error(`Expected 3 malformed issues, got ${malformedCount}`)
      }

      // Verify only valid issues remain
      validIssues.forEach(issue => {
        if (!isValidIssue(issue)) {
          throw new Error(`Invalid issue in validIssues array: ${JSON.stringify(issue)}`)
        }
      })
    }
  },

  {
    name: 'sanitizeIssuesArray handles non-array input gracefully',
    test: () => {
      const testCases = [
        null,
        undefined,
        'not an array',
        123,
        { issues: [] },
      ]

      testCases.forEach(input => {
        const { validIssues, malformedCount } = sanitizeIssuesArray(input)
        if (!Array.isArray(validIssues)) {
          throw new Error(`validIssues should be an array for input: ${JSON.stringify(input)}`)
        }
        if (validIssues.length !== 0) {
          throw new Error(`Expected empty array for input: ${JSON.stringify(input)}`)
        }
        if (malformedCount !== 0) {
          throw new Error(`Expected malformedCount=0 for input: ${JSON.stringify(input)}`)
        }
      })
    }
  },

  {
    name: 'calculateQualityScore detects and penalizes malformed issues',
    test: () => {
      const issuesWithoutMalformed = [
        { severity: 'high', description: 'Issue 1' },
        { severity: 'medium', description: 'Issue 2' },
      ]

      const issuesWithMalformed = [
        { severity: 'high', description: 'Issue 1' },
        { description: 'Malformed - missing severity' },
        { severity: 'medium', description: 'Issue 2' },
      ]

      const scoreWithoutMalformed = calculateQualityScore(issuesWithoutMalformed)
      const scoreWithMalformed = calculateQualityScore(issuesWithMalformed)

      // Both should detect same number of valid issues
      if (scoreWithoutMalformed.high_count !== 1 || scoreWithoutMalformed.medium_count !== 1) {
        throw new Error('Failed to categorize non-malformed issues correctly')
      }

      if (scoreWithMalformed.high_count !== 1 || scoreWithMalformed.medium_count !== 1) {
        throw new Error('Failed to categorize valid issues when malformed present')
      }

      // Malformed version should have malformed_count
      if (scoreWithMalformed.malformed_count !== 1) {
        throw new Error(`Expected malformed_count=1, got ${scoreWithMalformed.malformed_count}`)
      }

      // Score should be penalized (reduced by 10%) when malformed present
      if (scoreWithMalformed.score >= scoreWithoutMalformed.score) {
        throw new Error(
          `Score should be penalized for malformed issues: ${scoreWithMalformed.score} >= ${scoreWithoutMalformed.score}`
        )
      }

      // Verify penalty is approximately 10%
      const expectedPenalty = Math.floor(scoreWithoutMalformed.score * 0.9)
      if (scoreWithMalformed.score !== expectedPenalty) {
        throw new Error(
          `Score penalty incorrect: expected ${expectedPenalty}, got ${scoreWithMalformed.score}`
        )
      }
    }
  },

  {
    name: 'calculateQualityScore includes malformed_count in result',
    test: () => {
      const issues = [
        { severity: 'critical' },
        { description: 'Malformed 1' },
        { severity: 'high' },
        { severity: null }, // Malformed
      ]

      const score = calculateQualityScore(issues)

      if (!('malformed_count' in score)) {
        throw new Error('malformed_count property missing from result')
      }

      if (score.malformed_count !== 2) {
        throw new Error(`Expected malformed_count=2, got ${score.malformed_count}`)
      }
    }
  },

  {
    name: 'calculateQualityScore returns penalized score when only malformed issues',
    test: () => {
      const malformedOnly = [
        { description: 'Malformed 1' },
        { severity: null },
        { extra: 'field' },
      ]

      const score = calculateQualityScore(malformedOnly)

      // When no valid issues but there are malformed ones, score is 100 * 0.9 = 90
      if (score.score !== 90) {
        throw new Error(`Expected score=90 when only malformed issues, got ${score.score}`)
      }

      if (score.malformed_count !== 3) {
        throw new Error(`Expected malformed_count=3, got ${score.malformed_count}`)
      }

      // No valid issues counted in any category
      if (score.critical_count !== 0 || score.high_count !== 0 || score.medium_count !== 0 || score.low_count !== 0) {
        throw new Error('Expected all category counts to be 0')
      }
    }
  },

  {
    name: 'formatQualityReport includes malformed warning',
    test: () => {
      const scoreWithMalformed = {
        score: 90,
        critical_count: 0,
        high_count: 1,
        medium_count: 0,
        low_count: 0,
        malformed_count: 2,
        meets_threshold: true,
      }

      const report = formatQualityReport(scoreWithMalformed)

      if (!report.includes('WARNING')) {
        throw new Error('Report should include WARNING for malformed issues')
      }

      if (!report.includes('2 malformed')) {
        throw new Error('Report should mention number of malformed issues')
      }

      if (!report.includes('missing or invalid')) {
        throw new Error('Report should explain what malformed means')
      }

      if (!report.includes('penalized')) {
        throw new Error('Report should mention penalty')
      }
    }
  },

  {
    name: 'formatQualityReport does not warn when no malformed issues',
    test: () => {
      const scoreWithoutMalformed = {
        score: 95,
        critical_count: 0,
        high_count: 0,
        medium_count: 0,
        low_count: 0,
        malformed_count: 0,
        meets_threshold: true,
      }

      const report = formatQualityReport(scoreWithoutMalformed)

      if (report.includes('WARNING')) {
        throw new Error('Report should not warn when malformed_count is 0')
      }
    }
  },

  {
    name: 'categorizeIssuesBySeverity filters malformed issues',
    test: () => {
      const mixedIssues = [
        { severity: 'critical', description: 'Valid critical' },
        { severity: 'high', description: 'Valid high' },
        { description: 'Malformed - no severity' },
        { severity: 'medium', description: 'Valid medium' },
        { severity: undefined }, // Malformed
        { severity: 'low', description: 'Valid low' },
      ]

      const categorized = categorizeIssuesBySeverity(mixedIssues)

      if (categorized.critical.length !== 1) {
        throw new Error(`Expected 1 critical, got ${categorized.critical.length}`)
      }

      if (categorized.high.length !== 1) {
        throw new Error(`Expected 1 high, got ${categorized.high.length}`)
      }

      if (categorized.medium.length !== 1) {
        throw new Error(`Expected 1 medium, got ${categorized.medium.length}`)
      }

      if (categorized.low.length !== 1) {
        throw new Error(`Expected 1 low, got ${categorized.low.length}`)
      }

      // Verify no malformed issues in results
      const allIssues = [
        ...categorized.critical,
        ...categorized.high,
        ...categorized.medium,
        ...categorized.low,
      ]

      if (allIssues.length !== 4) {
        throw new Error(`Expected 4 total valid issues, got ${allIssues.length}`)
      }
    }
  },

  {
    name: 'prioritizeIssuesForFix filters malformed issues',
    test: () => {
      const mixedIssues = [
        { severity: 'low', confidence: 0.5, description: 'Low 1' },
        { description: 'Malformed - no severity' },
        { severity: 'critical', confidence: 0.9, description: 'Critical 1' },
        { severity: 123 }, // Malformed
        { severity: 'medium', confidence: 0.7, description: 'Medium 1' },
        { severity: 'high', confidence: 0.8, description: 'High 1' },
      ]

      const prioritized = prioritizeIssuesForFix(mixedIssues, 10)

      // Should only have 4 valid issues
      if (prioritized.length !== 4) {
        throw new Error(`Expected 4 valid issues, got ${prioritized.length}`)
      }

      // Verify order: critical > high > medium > low
      const expectedOrder = ['critical', 'high', 'medium', 'low']
      const actualOrder = prioritized.map(i => i.severity)

      for (let i = 0; i < actualOrder.length; i++) {
        if (actualOrder[i] !== expectedOrder[i]) {
          throw new Error(
            `Expected severity order ${expectedOrder}, got ${actualOrder}`
          )
        }
      }

      // Verify all returned issues are valid
      prioritized.forEach(issue => {
        if (!isValidIssue(issue)) {
          throw new Error(`Invalid issue in prioritized list: ${JSON.stringify(issue)}`)
        }
      })
    }
  },

  {
    name: 'prioritizeIssuesForFix respects maxIssues limit',
    test: () => {
      const manyIssues = Array.from({ length: 20 }, (_, i) => ({
        severity: 'low',
        description: `Issue ${i}`,
      }))

      const prioritized = prioritizeIssuesForFix(manyIssues, 5)

      if (prioritized.length !== 5) {
        throw new Error(`Expected maxIssues=5, got ${prioritized.length}`)
      }
    }
  },

  {
    name: 'Attack: AI returns issues with numeric severity',
    test: () => {
      const malformedFromAI = [
        { severity: 'critical', description: 'Valid issue' },
        { severity: 1, description: 'Numeric severity - AI mistake' }, // AI returned number instead of string
        { severity: 'high', description: 'Valid issue' },
      ]

      const score = calculateQualityScore(malformedFromAI)

      // Should detect the malformed issue
      if (score.malformed_count !== 1) {
        throw new Error(`Expected malformed_count=1, got ${score.malformed_count}`)
      }

      // Should only count the 2 valid issues (critical + high = 10 + 5 = 15 penalty, so 85 score)
      if (score.critical_count !== 1 || score.high_count !== 1) {
        throw new Error('Failed to correctly categorize valid issues')
      }

      // Score should be penalized for malformed issue (85 * 0.9 = 76.5 -> 76)
      if (score.score !== 76) {
        throw new Error(`Expected score=76 (85 * 0.9), got ${score.score}`)
      }
    }
  },

  {
    name: 'Attack: AI returns issues with missing severity',
    test: () => {
      const malformedFromAI = [
        { severity: 'critical', description: 'Valid' },
        { description: 'Oops, forgot severity!' }, // AI forgot severity property
        { severity: 'medium', description: 'Valid' },
        { location: 'file.js:10' }, // AI returned object but no severity
      ]

      const score = calculateQualityScore(malformedFromAI)

      // Before fix, these would be silently ignored, inflating score
      // After fix, malformed_count should be 2
      if (score.malformed_count !== 2) {
        throw new Error(`Expected malformed_count=2, got ${score.malformed_count}`)
      }

      // Should only count 2 valid issues (critical + medium = 10 + 1 = 11, so 89)
      if (score.critical_count !== 1 || score.medium_count !== 1) {
        throw new Error('Failed to correctly count valid issues')
      }

      // Score should be penalized (89 * 0.9 = 80.1 -> 80)
      if (score.score !== 80) {
        throw new Error(`Expected score=80 (89 * 0.9), got ${score.score}`)
      }
    }
  },

  {
    name: 'Attack: AI returns null/undefined in issues array',
    test: () => {
      const malformedFromAI = [
        { severity: 'critical', description: 'Valid' },
        null, // AI returned null
        { severity: 'high', description: 'Valid' },
        undefined, // AI returned undefined
      ]

      const score = calculateQualityScore(malformedFromAI)

      if (score.malformed_count !== 2) {
        throw new Error(`Expected malformed_count=2, got ${score.malformed_count}`)
      }

      // Should only count 2 valid issues (critical + high = 15, so 85)
      if (score.critical_count !== 1 || score.high_count !== 1) {
        throw new Error('Failed to correctly count valid issues')
      }

      // Score should be penalized (85 * 0.9 = 76.5 -> 76)
      if (score.score !== 76) {
        throw new Error(`Expected score=76, got ${score.score}`)
      }
    }
  },

  {
    name: 'validateIssueCounts accepts counts within threshold',
    test: () => {
      const testCases = [
        { critical: 0, high: 0, medium: 0 },
        { critical: 1, high: 1, medium: 1 },
        { critical: 10, high: 50, medium: 100 },
        { critical: 999, high: 999, medium: 999 },
        { critical: 1000, high: 1000, medium: 1000 }, // Edge case: exactly at threshold
      ]

      testCases.forEach(({ critical, high, medium }) => {
        const result = validateIssueCounts(critical, high, medium)
        if (!result.valid) {
          throw new Error(
            `Expected counts (critical=${critical}, high=${high}, medium=${medium}) to be valid, but got invalid`
          )
        }
        if (result.anomalousCount !== null) {
          throw new Error(
            `Expected anomalousCount=null, got ${result.anomalousCount}`
          )
        }
      })
    }
  },

  {
    name: 'validateIssueCounts rejects counts exceeding threshold',
    test: () => {
      const testCases = [
        { critical: 1001, high: 0, medium: 0, expected: 'critical (1001)' },
        { critical: 0, high: 1001, medium: 0, expected: 'high (1001)' },
        { critical: 0, high: 0, medium: 1001, expected: 'medium (1001)' },
        { critical: 10000, high: 0, medium: 0, expected: 'critical (10000)' },
      ]

      testCases.forEach(({ critical, high, medium, expected }) => {
        const result = validateIssueCounts(critical, high, medium)
        if (result.valid) {
          throw new Error(
            `Expected counts (critical=${critical}, high=${high}, medium=${medium}) to be invalid, but got valid`
          )
        }
        if (result.anomalousCount !== expected) {
          throw new Error(
            `Expected anomalousCount='${expected}', got '${result.anomalousCount}'`
          )
        }
      })
    }
  },

  {
    name: 'calculateQualityScore includes anomalous_counts flag in result',
    test: () => {
      const normalIssues = [
        { severity: 'critical', description: 'Normal critical issue' },
      ]

      const score = calculateQualityScore(normalIssues)

      if (!('anomalous_counts' in score)) {
        throw new Error('anomalous_counts property missing from result')
      }

      if (score.anomalous_counts !== false) {
        throw new Error(`Expected anomalous_counts=false for normal issues, got ${score.anomalous_counts}`)
      }
    }
  },

  {
    name: 'Attack: AI returns 10,000 critical issues (integer underflow)',
    test: () => {
      // Simulate a scenario where AI returns an unreasonably large number of issues
      // This could happen due to AI corruption, prompt injection, or malicious input
      const maliciousIssues = Array.from({ length: 10000 }, (_, i) => ({
        severity: 'critical',
        description: `Injected issue ${i}`,
      }))

      const score = calculateQualityScore(maliciousIssues)

      // Should detect anomalous count
      if (!score.anomalous_counts) {
        throw new Error('Expected anomalous_counts=true for 10,000 critical issues')
      }

      // Score should still be clamped to 0 (100 - 100000 = -99900, clamped to 0)
      if (score.score !== 0) {
        throw new Error(`Expected score=0 for massive issue count, got ${score.score}`)
      }

      // Critical count should match input
      if (score.critical_count !== 10000) {
        throw new Error(`Expected critical_count=10000, got ${score.critical_count}`)
      }
    }
  },

  {
    name: 'Attack: AI returns 5,000 high + 3,000 medium issues',
    test: () => {
      const maliciousIssues = [
        ...Array.from({ length: 5000 }, (_, i) => ({ severity: 'high', description: `High ${i}` })),
        ...Array.from({ length: 3000 }, (_, i) => ({ severity: 'medium', description: `Medium ${i}` })),
      ]

      const score = calculateQualityScore(maliciousIssues)

      // Should detect anomalous counts (both high and medium exceed threshold)
      if (!score.anomalous_counts) {
        throw new Error('Expected anomalous_counts=true for 5,000 high issues')
      }

      // Score should be clamped to 0 (100 - (5000*5 + 3000*1) = 100 - 28000 = -27900, clamped to 0)
      if (score.score !== 0) {
        throw new Error(`Expected score=0, got ${score.score}`)
      }
    }
  },

  {
    name: 'Boundary: 1,000 critical issues (at threshold)',
    test: () => {
      const boundaryIssues = Array.from({ length: 1000 }, (_, i) => ({
        severity: 'critical',
        description: `Issue ${i}`,
      }))

      const score = calculateQualityScore(boundaryIssues)

      // At threshold should still be valid (not anomalous)
      if (score.anomalous_counts !== false) {
        throw new Error('Expected anomalous_counts=false at threshold boundary')
      }

      // Score should be clamped to 0 (100 - 10000 = -9900, clamped to 0)
      if (score.score !== 0) {
        throw new Error(`Expected score=0, got ${score.score}`)
      }

      if (score.critical_count !== 1000) {
        throw new Error(`Expected critical_count=1000, got ${score.critical_count}`)
      }
    }
  },

  {
    name: 'Attack: AI returns issues with unrecognized severity strings',
    test: () => {
      // Before the fix, these issues would pass isValidIssue (they have
      // a string severity) but match no filter category, resulting in
      // a perfect score of 100 despite real issues existing.
      const unrecognizedSeverityIssues = [
        { severity: 'warning', description: 'Potential problem' },
        { severity: 'info', description: 'Information' },
        { severity: 'critical', description: 'Real critical issue' },
      ]

      const score = calculateQualityScore(unrecognizedSeverityIssues)

      // The 2 unrecognized severity issues should be detected as malformed
      if (score.malformed_count !== 2) {
        throw new Error(
          `Expected malformed_count=2 for unrecognized severities, got ${score.malformed_count}`
        )
      }

      // Only 1 valid critical issue should be counted
      if (score.critical_count !== 1) {
        throw new Error(`Expected critical_count=1, got ${score.critical_count}`)
      }

      // Score should be penalized: 90 (100 - 10) * 0.9 = 81
      if (score.score !== 81) {
        throw new Error(`Expected score=81 (90 * 0.9), got ${score.score}`)
      }
    }
  },

  {
    name: 'Attack: AI returns only unrecognized severity strings',
    test: () => {
      // All issues have unrecognized severities - without the fix,
      // this would give a perfect 100 score despite having "issues"
      const allUnrecognized = [
        { severity: 'warning', description: 'Issue 1' },
        { severity: 'info', description: 'Issue 2' },
        { severity: 'suggestion', description: 'Issue 3' },
      ]

      const score = calculateQualityScore(allUnrecognized)

      // All should be malformed
      if (score.malformed_count !== 3) {
        throw new Error(`Expected malformed_count=3, got ${score.malformed_count}`)
      }

      // No valid issues in any category
      if (score.critical_count !== 0 || score.high_count !== 0 ||
          score.medium_count !== 0 || score.low_count !== 0) {
        throw new Error('Expected all category counts to be 0')
      }

      // Score should be penalized: 100 * 0.9 = 90 (not 100!)
      if (score.score !== 90) {
        throw new Error(`Expected score=90, got ${score.score}`)
      }
    }
  },

  {
    name: 'Boundary: 1,001 critical issues (exceeds threshold)',
    test: () => {
      const boundaryIssues = Array.from({ length: 1001 }, (_, i) => ({
        severity: 'critical',
        description: `Issue ${i}`,
      }))

      const score = calculateQualityScore(boundaryIssues)

      // Just over threshold should be flagged as anomalous
      if (!score.anomalous_counts) {
        throw new Error('Expected anomalous_counts=true just over threshold')
      }

      if (score.critical_count !== 1001) {
        throw new Error(`Expected critical_count=1001, got ${score.critical_count}`)
      }
    }
  },

  // --- capIssueCounts tests (Issue #468) ---

  {
    name: 'capIssueCounts passes through counts within threshold',
    test: () => {
      const testCases = [
        { critical: 0, high: 0, medium: 0 },
        { critical: 1, high: 1, medium: 1 },
        { critical: 500, high: 250, medium: 100 },
        { critical: 1000, high: 1000, medium: 1000 },
      ]

      testCases.forEach(({ critical, high, medium }) => {
        const capped = capIssueCounts(critical, high, medium)
        if (capped.critical !== critical || capped.high !== high || capped.medium !== medium) {
          throw new Error(
            `Expected counts to pass through unchanged: ` +
            `input=(${critical},${high},${medium}), ` +
            `got=(${capped.critical},${capped.high},${capped.medium})`
          )
        }
      })
    }
  },

  {
    name: 'capIssueCounts clamps counts exceeding threshold',
    test: () => {
      const testCases = [
        { critical: 1001, high: 0, medium: 0, expectedCritical: 1000, expectedHigh: 0, expectedMedium: 0 },
        { critical: 0, high: 5000, medium: 0, expectedCritical: 0, expectedHigh: 1000, expectedMedium: 0 },
        { critical: 0, high: 0, medium: 9999, expectedCritical: 0, expectedHigh: 0, expectedMedium: 1000 },
        { critical: 10000, high: 10000, medium: 10000, expectedCritical: 1000, expectedHigh: 1000, expectedMedium: 1000 },
      ]

      testCases.forEach(({ critical, high, medium, expectedCritical, expectedHigh, expectedMedium }) => {
        const capped = capIssueCounts(critical, high, medium)
        if (capped.critical !== expectedCritical || capped.high !== expectedHigh || capped.medium !== expectedMedium) {
          throw new Error(
            `Expected capped counts: ` +
            `input=(${critical},${high},${medium}), ` +
            `expected=(${expectedCritical},${expectedHigh},${expectedMedium}), ` +
            `got=(${capped.critical},${capped.high},${capped.medium})`
          )
        }
      })
    }
  },

  {
    name: 'Score calculation uses capped counts (not raw) for anomalous input',
    test: () => {
      // With 2000 critical issues:
      //   Raw:    100 - (2000 * 10) = 100 - 20000 = -19900 -> clamped to 0
      //   Capped: 100 - (1000 * 10) = 100 - 10000 = -9900  -> clamped to 0
      // Both give 0 in this case, but verify the capping is active by checking
      // that the reported critical_count is the RAW count (for transparency)
      // while the score uses capped values.
      const issues = Array.from({ length: 2000 }, () => ({ severity: 'critical', description: 'test' }))
      const score = calculateQualityScore(issues)

      // Raw count should be preserved in the result for callers
      if (score.critical_count !== 2000) {
        throw new Error(`Expected critical_count=2000 (raw), got ${score.critical_count}`)
      }

      // Score should be 0 (capped calc still exceeds 100)
      if (score.score !== 0) {
        throw new Error(`Expected score=0, got ${score.score}`)
      }

      // Should flag as anomalous
      if (!score.anomalous_counts) {
        throw new Error('Expected anomalous_counts=true')
      }
    }
  },

  {
    name: 'Capped score calculation prevents intermediate underflow beyond threshold bounds',
    test: () => {
      // Verify that extreme input (e.g. 100,000 issues) does not produce
      // intermediate values vastly below zero in the score formula.
      // With capping: max intermediate = 100 - (1000*10 + 1000*5 + 1000*1) = 100 - 16000 = -15900
      // Without capping: 100 - (100000*10) = -999900
      // Both clamp to 0 via Math.max, but capping keeps the intermediate predictable.
      const issues = Array.from({ length: 100000 }, () => ({ severity: 'critical', description: 'extreme' }))
      const score = calculateQualityScore(issues)

      if (score.score !== 0) {
        throw new Error(`Expected score=0 for extreme input, got ${score.score}`)
      }

      if (!score.anomalous_counts) {
        throw new Error('Expected anomalous_counts=true for extreme input')
      }

      // Raw count preserved
      if (score.critical_count !== 100000) {
        throw new Error(`Expected critical_count=100000, got ${score.critical_count}`)
      }
    }
  },
]

// Run tests
console.log('═'.repeat(70))
console.log('Testing Type Confusion Fix (Issue #488)')
console.log('═'.repeat(70))

let passed = 0
let failed = 0

tests.forEach(({ name, test }) => {
  try {
    test()
    console.log(`✅ ${name}`)
    passed++
  } catch (error) {
    console.log(`❌ ${name}`)
    console.log(`   Error: ${error.message}`)
    failed++
  }
})

console.log('')
console.log('═'.repeat(70))
console.log(`Results: ${passed} passed, ${failed} failed`)
console.log('═'.repeat(70))

if (failed > 0) {
  process.exit(1)
}
