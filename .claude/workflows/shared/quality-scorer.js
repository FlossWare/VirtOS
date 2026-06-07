// Quality Scoring System
// Used by: code-improve, code-solve, pr-review
// Consistent quality calculation across workflows

/**
 * Set of all recognized severity values.
 * Issues with severity strings not in this set are treated as malformed
 * to prevent silent exclusion from all categories (which would artificially
 * inflate the quality score).
 */
const KNOWN_SEVERITIES = new Set([
  'critical', 'P0',
  'high', 'major', 'P1',
  'medium', 'P2',
  'low', 'minor', 'P3', 'P4',
])

/**
 * Validates that an issue object has a valid, recognized severity property.
 * Guards against malformed AI responses where array elements may be
 * strings, nulls, arrays, objects missing the .severity property, or
 * objects with unrecognized severity values (e.g. "warning", "info")
 * that would silently fall through all filter categories.
 * @param {*} issue - The issue object to validate
 * @returns {boolean} - True if issue is a non-null, non-array object with a recognized severity string
 */
export function isValidIssue(issue) {
  return (
    issue !== null &&
    issue !== undefined &&
    typeof issue === 'object' &&
    !Array.isArray(issue) &&
    typeof issue.severity === 'string' &&
    KNOWN_SEVERITIES.has(issue.severity)
  )
}

/**
 * Sanitizes an issues array by filtering out malformed objects and tracking them.
 * Malformed issues are logged with console.warn so callers have visibility
 * into AI output quality problems.
 * @param {*} issues - Potentially malformed issues array from AI responses
 * @returns {{ validIssues: Array, malformedCount: number }}
 */
export function sanitizeIssuesArray(issues) {
  if (!Array.isArray(issues)) {
    return { validIssues: [], malformedCount: 0 }
  }

  const validIssues = []
  let malformedCount = 0

  for (let index = 0; index < issues.length; index++) {
    const issue = issues[index]
    if (isValidIssue(issue)) {
      validIssues.push(issue)
    } else {
      malformedCount++
      // Truncate stringified issue to prevent log flooding from large objects
      const issueStr = JSON.stringify(issue)
      const truncated = issueStr && issueStr.length > 200 ? issueStr.slice(0, 200) + '...' : issueStr
      console.warn(
        `[quality-scorer] Malformed issue at index ${index}: expected object with string 'severity' property, got: ${truncated}`
      )
    }
  }

  return { validIssues, malformedCount }
}

/** Maximum number of issues per severity level before counts are considered anomalous. */
const MAX_ISSUES_PER_SEVERITY = 1000

/**
 * Validates that issue counts are within reasonable bounds.
 * Detects anomalous input that would indicate malicious or erroneous AI output.
 * Threshold of 1000 allows for large code reviews while catching obvious attacks.
 * @param {number} critical - Count of critical severity issues
 * @param {number} high - Count of high severity issues
 * @param {number} medium - Count of medium severity issues
 * @returns {{ valid: boolean, anomalousCount: string|null }}
 */
export function validateIssueCounts(critical, high, medium) {
  if (critical > MAX_ISSUES_PER_SEVERITY) {
    return { valid: false, anomalousCount: `critical (${critical})` }
  }

  if (high > MAX_ISSUES_PER_SEVERITY) {
    return { valid: false, anomalousCount: `high (${high})` }
  }

  if (medium > MAX_ISSUES_PER_SEVERITY) {
    return { valid: false, anomalousCount: `medium (${medium})` }
  }

  return { valid: true, anomalousCount: null }
}

/**
 * Caps issue counts at the maximum threshold to prevent extreme arithmetic
 * underflow in score calculations. When an AI returns anomalous counts
 * (e.g. 10,000 critical issues), the raw values are clamped so that
 * downstream arithmetic stays within predictable bounds.
 * @param {number} critical - Raw count of critical severity issues
 * @param {number} high - Raw count of high severity issues
 * @param {number} medium - Raw count of medium severity issues
 * @returns {{ critical: number, high: number, medium: number }}
 */
export function capIssueCounts(critical, high, medium) {
  return {
    critical: Math.min(critical, MAX_ISSUES_PER_SEVERITY),
    high: Math.min(high, MAX_ISSUES_PER_SEVERITY),
    medium: Math.min(medium, MAX_ISSUES_PER_SEVERITY),
  }
}

export function calculateQualityScore(issues) {
  // Sanitize input and detect malformed objects
  const { validIssues, malformedCount } = sanitizeIssuesArray(issues)

  if (validIssues.length === 0 && malformedCount === 0) {
    return {
      score: 100,
      critical_count: 0,
      high_count: 0,
      medium_count: 0,
      low_count: 0,
      malformed_count: 0,
      anomalous_counts: false,
      meets_threshold: true
    }
  }

  const critical = validIssues.filter(i =>
    i.severity === 'critical' || i.severity === 'P0'
  ).length

  const high = validIssues.filter(i =>
    i.severity === 'high' || i.severity === 'major' || i.severity === 'P1'
  ).length

  const medium = validIssues.filter(i =>
    i.severity === 'medium' || i.severity === 'P2'
  ).length

  const low = validIssues.filter(i =>
    i.severity === 'low' || i.severity === 'minor' || i.severity === 'P3' || i.severity === 'P4'
  ).length

  // Validate issue counts before calculation to detect anomalous input
  const countValidation = validateIssueCounts(critical, high, medium)
  if (!countValidation.valid) {
    console.warn(
      `[quality-scorer] Anomalous issue count detected: ${countValidation.anomalousCount} exceeds threshold of ${MAX_ISSUES_PER_SEVERITY}. Capping counts for score calculation. Possible AI output corruption.`
    )
  }

  // Cap counts at threshold to prevent extreme arithmetic underflow.
  // Without capping, 10,000 critical issues would produce 100 - 100,000 = -99,900.
  // With capping, the calculation uses at most 1,000 per severity, keeping the
  // intermediate value within a predictable range before Math.max clamps to 0.
  const capped = capIssueCounts(critical, high, medium)

  // Score calculation: 100 - (critical×10 + high×5 + medium×1)
  // Low severity issues don't affect score
  const score = Math.max(0, 100 - (capped.critical * 10 + capped.high * 5 + capped.medium * 1))

  // If there were malformed issues, penalize score to alert users
  const penaltyMultiplier = malformedCount > 0 ? 0.9 : 1.0
  const adjustedScore = Math.max(0, Math.floor(score * penaltyMultiplier))

  return {
    score: adjustedScore,
    critical_count: critical,
    high_count: high,
    medium_count: medium,
    low_count: low,
    malformed_count: malformedCount,
    anomalous_counts: !countValidation.valid,
    meets_threshold: adjustedScore >= 90 // Default threshold
  }
}

export function meetsQualityThreshold(qualityScore, threshold = 90) {
  return qualityScore.score >= threshold
}

export function formatQualityReport(qualityScore) {
  const { score, critical_count, high_count, medium_count, low_count, malformed_count } = qualityScore

  let emoji = '✅'
  if (score < 60) emoji = '❌'
  else if (score < 80) emoji = '⚠️'
  else if (score < 90) emoji = '🟡'

  let malformedWarning = ''
  if (malformed_count > 0) {
    malformedWarning = `\n**WARNING**: ${malformed_count} malformed issue(s) detected (missing or invalid 'severity' property). Score penalized to prevent artificial inflation. Check AI model output quality.`
  }

  return `${emoji} **Quality Score**: ${score}/100

**Issues Breakdown**:
- Critical: ${critical_count} (×10 points each)
- High: ${high_count} (×5 points each)
- Medium: ${medium_count} (×1 point each)
- Low: ${low_count} (no penalty)
- Malformed: ${malformed_count || 0}

**Total Impact**: -${100 - score} points${malformedWarning}
`
}

export function categorizeIssuesBySeverity(issues) {
  const { validIssues } = sanitizeIssuesArray(issues)

  return {
    critical: validIssues.filter(i => i.severity === 'critical' || i.severity === 'P0'),
    high: validIssues.filter(i => i.severity === 'high' || i.severity === 'major' || i.severity === 'P1'),
    medium: validIssues.filter(i => i.severity === 'medium' || i.severity === 'P2'),
    low: validIssues.filter(i => i.severity === 'low' || i.severity === 'minor' || i.severity === 'P3' || i.severity === 'P4'),
  }
}

export function prioritizeIssuesForFix(issues, maxIssues = 10) {
  const { validIssues } = sanitizeIssuesArray(issues)

  // Sort by severity (critical first, then high, then medium, then low)
  const severityOrder = { 'critical': 0, 'P0': 0, 'high': 1, 'major': 1, 'P1': 1, 'medium': 2, 'P2': 2, 'low': 3, 'minor': 3, 'P3': 3, 'P4': 3 }

  const sorted = [...validIssues].sort((a, b) => {
    const aSev = severityOrder[a.severity] ?? 99
    const bSev = severityOrder[b.severity] ?? 99

    if (aSev !== bSev) return aSev - bSev

    // If same severity, sort by confidence (higher first)
    return (b.confidence || 0) - (a.confidence || 0)
  })

  return sorted.slice(0, maxIssues)
}

export function hasImproved(previousScore, currentScore) {
  return currentScore.score > previousScore.score
}

export function hasConverged(previousScore, currentScore, tolerance = 2) {
  // Converged if score difference is within tolerance and no critical issues
  const scoreDiff = Math.abs(currentScore.score - previousScore.score)
  return scoreDiff <= tolerance && currentScore.critical_count === 0
}

export function shouldContinueImproving(qualityScore, targetScore = 95, maxIterations = 10, currentIteration = 1) {
  // Stop if:
  // 1. Target score reached
  if (qualityScore.score >= targetScore) {
    return { continue: false, reason: 'target_score_reached' }
  }

  // 2. Max iterations reached
  if (currentIteration >= maxIterations) {
    return { continue: false, reason: 'max_iterations_reached' }
  }

  // 3. No issues found (perfect score)
  if (qualityScore.score === 100) {
    return { continue: false, reason: 'perfect_score' }
  }

  // Otherwise, continue
  return { continue: true, reason: 'improvements_needed' }
}
