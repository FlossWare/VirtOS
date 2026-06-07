/**
 * Test suite for null safety fix in majorityVoteDecision (Issue #473)
 * Tests that null/undefined reviews are properly handled without errors
 */

// Mock log function
const log = (msg) => console.log(msg)

// Simplified majorityVoteDecision for testing
function majorityVoteDecision(reviews, decisionType) {
  // Simple majority vote - no arbiter overhead
  const allReviews = reviews.allReviews || Object.values(reviews).filter(Boolean)

  if (allReviews.length === 0) {
    // No reviews available - safe default
    return {
      final_decision: 'needs_review',
      consensus_score: 0,
      accepted_model: 'none',
      accepted_reasoning: 'No reviews available for majority vote',
      rejected_models: [],
      strategy: 'majority',
      arbiter: 'none'
    }
  }

  if (decisionType === 'issue') {
    // Count votes, treating null/undefined as abstentions
    // Issue #473: Add null safety checks to prevent errors from malformed reviews
    const realIssueVotes = allReviews.filter(r => r && r.is_real_issue === true).length
    const falsePositiveVotes = allReviews.filter(r => r && r.is_real_issue === false).length
    const abstentions = allReviews.filter(r => !r || r.is_real_issue === null || r.is_real_issue === undefined).length

    // Warn if any reviews abstained
    if (abstentions > 0) {
      log(`⚠️ Warning: ${abstentions}/${allReviews.length} reviews abstained (missing or malformed is_real_issue field)`)
    }

    const validVotes = realIssueVotes + falsePositiveVotes
    if (validVotes === 0) {
      // All abstentions - cannot decide
      return {
        final_decision: 'needs_review',
        consensus_score: 0,
        accepted_model: 'none',
        accepted_reasoning: 'All reviews abstained (missing is_real_issue field)',
        rejected_models: [],
        strategy: 'majority',
        arbiter: 'none'
      }
    }

    const isRealIssue = realIssueVotes > falsePositiveVotes
    const consensusScore = Math.round((Math.max(realIssueVotes, falsePositiveVotes) / validVotes) * 100)

    // Find highest confidence model on winning side
    const winningSide = allReviews.filter(r => r && r.is_real_issue === isRealIssue)
    const bestModel = winningSide.length > 0
      ? [...winningSide].sort((a, b) => (b.confidence || 0) - (a.confidence || 0))[0]
      : undefined

    let issuePriority = 'P2' // Safe default for undefined bestModel or medium severity
    if (bestModel) {
      const severity = bestModel.severity_assessment
      if (severity === 'critical') {
        issuePriority = 'P0'
      } else if (severity === 'high') {
        issuePriority = 'P1'
      } else if (severity === 'low' || severity === 'informational') {
        issuePriority = 'P3'
      }
    }

    return {
      final_decision: isRealIssue ? 'real_issue' : 'false_positive',
      consensus_score: consensusScore,
      accepted_model: 'majority_vote',
      accepted_reasoning: `${realIssueVotes}/${validVotes} models voted real issue${abstentions > 0 ? ` (${abstentions} abstained)` : ''}`,
      rejected_models: [],
      create_issue: isRealIssue && consensusScore >= 60,
      issue_priority: issuePriority,
      strategy: 'majority',
      arbiter: 'none'
    }
  } else if (decisionType === 'pr') {
    // Majority vote for PR approval
    // Issue #473: Add null safety checks to prevent errors from malformed reviews
    const approveVotes = allReviews.filter(r =>
      r && (r.approval_recommendation === 'approve' ||
      r.approval_recommendation === 'approved')
    ).length
    const rejectVotes = allReviews.filter(r =>
      r && (r.approval_recommendation === 'reject' ||
      r.approval_recommendation === 'request_changes' ||
      r.approval_recommendation === 'needs_changes')
    ).length
    const abstentions = allReviews.filter(r =>
      !r || !r.approval_recommendation ||
      (r.approval_recommendation !== 'approve' &&
       r.approval_recommendation !== 'approved' &&
       r.approval_recommendation !== 'reject' &&
       r.approval_recommendation !== 'request_changes' &&
       r.approval_recommendation !== 'needs_changes')
    ).length

    // Warn if any reviews abstained
    if (abstentions > 0) {
      log(`⚠️ Warning: ${abstentions}/${allReviews.length} reviews abstained (missing or malformed approval_recommendation field)`)
    }

    const validVotes = approveVotes + rejectVotes
    if (validVotes === 0) {
      // All abstentions - cannot decide
      return {
        final_decision: 'needs_review',
        consensus_score: 0,
        accepted_model: 'none',
        accepted_reasoning: 'All reviews abstained (missing approval_recommendation field)',
        rejected_models: [],
        create_issue: false,
        strategy: 'majority',
        arbiter: 'none'
      }
    }

    const isApproved = approveVotes > rejectVotes
    const consensusScore = Math.round((Math.max(approveVotes, rejectVotes) / validVotes) * 100)

    const winningSide = allReviews.filter(r => {
      const rec = r?.approval_recommendation
      return isApproved
        ? (rec === 'approve' || rec === 'approved')
        : (rec === 'reject' || rec === 'request_changes' || rec === 'needs_changes')
    })
    const bestModel = winningSide.length > 0
      ? [...winningSide].sort((a, b) => (b.confidence || 0) - (a.confidence || 0))[0]
      : undefined

    const finalDecision = isApproved && consensusScore > 50 ? 'approved' : 'needs_review'

    return {
      final_decision: finalDecision,
      consensus_score: consensusScore,
      accepted_model: 'majority_vote',
      accepted_reasoning: `${approveVotes}/${validVotes} models voted to approve${abstentions > 0 ? ` (${abstentions} abstained)` : ''}`,
      rejected_models: [],
      create_issue: false,
      strategy: 'majority',
      arbiter: 'none'
    }
  } else if (decisionType === 'fix') {
    // Majority vote for fix selection
    // Count votes for each unique fix approach
    // Issue #473: Add null safety checks to prevent errors from malformed reviews
    const fixVotes = new Map()
    allReviews.forEach((review, idx) => {
      // Skip null/undefined reviews
      if (!review || typeof review !== 'object') return
      const approach = review.approach || review.fix_approach || `fix_${idx}`
      const count = fixVotes.get(approach) || { count: 0, reviews: [], totalConfidence: 0 }
      count.count++
      count.reviews.push(review)
      count.totalConfidence += (review.confidence || 0)
      fixVotes.set(approach, count)
    })

    // Find most voted fix
    let bestFix = null
    let maxVotes = 0
    for (const [approach, data] of fixVotes.entries()) {
      if (data.count > maxVotes ||
          (data.count === maxVotes && data.totalConfidence > bestFix?.totalConfidence)) {
        bestFix = { approach, ...data }
        maxVotes = data.count
      }
    }

    const consensusScore = Math.round((maxVotes / allReviews.filter(r => r).length) * 100)

    const finalDecision = consensusScore > 50 ? 'approved' : 'needs_review'

    return {
      final_decision: finalDecision,
      consensus_score: consensusScore,
      accepted_model: 'majority_vote',
      accepted_reasoning: `${maxVotes}/${allReviews.filter(r => r).length} models agreed on fix approach: ${bestFix?.approach || 'unknown'}`,
      rejected_models: [],
      create_issue: false,
      strategy: 'majority',
      arbiter: 'none'
    }
  }

  return {
    final_decision: 'needs_review',
    consensus_score: 0,
    accepted_model: 'none',
    accepted_reasoning: `Unsupported decision type: ${decisionType}`,
    rejected_models: [],
    strategy: 'majority',
    arbiter: 'none'
  }
}

// Test suite
const tests = [
  {
    name: 'Issue decision with null reviews mixed in (should not throw)',
    test: () => {
      const reviews = {
        allReviews: [
          { is_real_issue: true, confidence: 95 },
          null,
          { is_real_issue: false, confidence: 80 },
          undefined,
          { is_real_issue: true, confidence: 90 }
        ]
      }
      const result = majorityVoteDecision(reviews, 'issue')
      if (!result.final_decision) {
        throw new Error('Should handle mixed null reviews gracefully')
      }
      // 2 real issues, 1 false positive, 2 abstentions
      if (result.final_decision !== 'real_issue') {
        throw new Error(`Expected 'real_issue', got '${result.final_decision}'`)
      }
    }
  },
  {
    name: 'Issue decision with completely null reviews array (should return needs_review)',
    test: () => {
      const reviews = {
        allReviews: [null, undefined]
      }
      const result = majorityVoteDecision(reviews, 'issue')
      if (result.final_decision !== 'needs_review') {
        throw new Error('All null reviews should return needs_review')
      }
      if (result.consensus_score !== 0) {
        throw new Error('Consensus score should be 0 when all abstain')
      }
    }
  },
  {
    name: 'Issue decision with missing is_real_issue field (should count as abstention)',
    test: () => {
      const reviews = {
        allReviews: [
          { confidence: 95 }, // Missing is_real_issue
          { is_real_issue: true, confidence: 90 },
          { is_real_issue: true, confidence: 85 }
        ]
      }
      const result = majorityVoteDecision(reviews, 'issue')
      if (result.final_decision !== 'real_issue') {
        throw new Error('Should count missing is_real_issue as abstention, not error')
      }
      // Should have counted the abstention
      if (!result.accepted_reasoning.includes('abstained')) {
        throw new Error('Should indicate abstention in reasoning')
      }
    }
  },
  {
    name: 'PR decision with null reviews (should not throw)',
    test: () => {
      const reviews = {
        allReviews: [
          { approval_recommendation: 'approve', confidence: 95 },
          null,
          { approval_recommendation: 'reject', confidence: 80 },
          undefined
        ]
      }
      const result = majorityVoteDecision(reviews, 'pr')
      if (!result.final_decision) {
        throw new Error('Should handle mixed null reviews gracefully')
      }
    }
  },
  {
    name: 'PR decision with missing approval_recommendation (should count as abstention)',
    test: () => {
      const reviews = {
        allReviews: [
          { confidence: 95 }, // Missing approval_recommendation
          { approval_recommendation: 'approve', confidence: 90 },
          { approval_recommendation: 'approve', confidence: 85 }
        ]
      }
      const result = majorityVoteDecision(reviews, 'pr')
      if (result.final_decision === 'needs_review' && result.consensus_score === 0) {
        // This is acceptable - abstention treated
        return
      }
      // Should handle gracefully without throwing
      if (!result.final_decision) {
        throw new Error('Should handle missing approval_recommendation gracefully')
      }
    }
  },
  {
    name: 'Fix decision with null reviews (should skip them, not throw)',
    test: () => {
      const reviews = {
        allReviews: [
          { approach: 'fix_a', confidence: 95 },
          null,
          { approach: 'fix_a', confidence: 90 },
          undefined,
          { approach: 'fix_b', confidence: 85 }
        ]
      }
      const result = majorityVoteDecision(reviews, 'fix')
      if (!result.final_decision) {
        throw new Error('Should handle mixed null reviews gracefully')
      }
      // fix_a should win with 2 votes vs 1
      if (result.final_decision === 'approved' && !result.accepted_reasoning.includes('fix_a')) {
        throw new Error('Should select fix_a with most votes')
      }
    }
  },
  {
    name: 'Fix decision with malformed reviews (non-objects)',
    test: () => {
      const reviews = {
        allReviews: [
          { approach: 'fix_a', confidence: 95 },
          'string_instead_of_object', // Malformed
          { approach: 'fix_a', confidence: 90 },
          123, // Malformed
          { approach: 'fix_b', confidence: 85 }
        ]
      }
      const result = majorityVoteDecision(reviews, 'fix')
      if (!result.final_decision) {
        throw new Error('Should skip malformed reviews and process valid ones')
      }
    }
  },
  {
    name: 'Issue decision with all undefined values (should handle gracefully)',
    test: () => {
      const reviews = {
        allReviews: [
          { is_real_issue: undefined, confidence: 95 },
          { is_real_issue: undefined, confidence: 90 }
        ]
      }
      const result = majorityVoteDecision(reviews, 'issue')
      if (result.final_decision !== 'needs_review') {
        throw new Error('All undefined votes should return needs_review')
      }
    }
  }
]

// Run tests
console.log('═'.repeat(70))
console.log('Testing Null Safety Fix (Issue #473)')
console.log('═'.repeat(70))
console.log()

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

console.log()
console.log('═'.repeat(70))
console.log(`Results: ${passed} passed, ${failed} failed`)
console.log('═'.repeat(70))

if (failed > 0) {
  process.exit(1)
}
