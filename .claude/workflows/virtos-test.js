// Multi-AI VirtOS Testing with Arbiter/Worker Pattern
// Tests VirtOS scripts comprehensively and fixes issues immediately

export const meta = {
  name: 'virtos-test',
  description: 'Multi-AI comprehensive VirtOS testing with immediate fixes',
  phases: [
    { title: 'Parallel Testing', detail: 'Multiple AIs test different subsystems' },
    { title: 'Arbiter Review', detail: 'Consolidate findings and prioritize' },
    { title: 'Apply Fixes', detail: 'Fix critical issues immediately' },
    { title: 'Verification', detail: 'Re-test fixed components' },
  ],
}

// Test categories - each worker gets a focused area
const TEST_AREAS = [
  {
    id: 'core-vm',
    name: 'Core VM Management',
    scripts: ['virtos-create-vm', 'virtos-migrate', 'virtos-snapshot'],
    tests: [
      'Version flags consistency (--version, -v, version)',
      'Help output completeness',
      'Input validation (command injection, path traversal)',
      'Library loading in dev environment',
      'Error messages clarity',
      'Dry-run functionality',
    ]
  },
  {
    id: 'storage-network',
    name: 'Storage & Networking',
    scripts: ['virtos-storage', 'virtos-network', 'virtos-backup'],
    tests: [
      'Version flags consistency',
      'Library path flexibility',
      'Input sanitization',
      'Privilege escalation safety',
      'Resource validation',
    ]
  },
  {
    id: 'monitoring-cluster',
    name: 'Monitoring & Clustering',
    scripts: ['virtos-monitor', 'virtos-cluster', 'virtos-tui'],
    tests: [
      'Version flags consistency',
      'Real-time data accuracy',
      'Cluster discovery safety',
      'TUI responsiveness',
    ]
  },
  {
    id: 'security-audit',
    name: 'Security & Audit',
    scripts: ['virtos-security', 'virtos-audit', 'virtos-common.sh'],
    tests: [
      'validate_vm_name() function',
      'validate_path() function',
      'sanitize_input() function',
      'Audit logging completeness',
      'Permission checks',
    ]
  },
]

const ISSUE_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
          category: { type: 'string' },
          script: { type: 'string' },
          issue: { type: 'string' },
          test_command: { type: 'string' },
          actual_output: { type: 'string' },
          expected: { type: 'string' },
          fix_needed: { type: 'boolean' },
        }
      }
    }
  }
}

const ARBITER_SCHEMA = {
  type: 'object',
  properties: {
    critical_fixes: { type: 'array', items: { type: 'string' } },
    high_priority: { type: 'array', items: { type: 'string' } },
    medium_priority: { type: 'array', items: { type: 'string' } },
    false_positives: { type: 'array', items: { type: 'string' } },
    systematic_issues: { type: 'array', items: { type: 'string' } },
  }
}

phase('Parallel Testing')
log('🚀 Launching parallel test workers across VirtOS subsystems...')

// Spawn workers in parallel - each tests a different area
const testResults = await parallel(
  TEST_AREAS.map(area => async () => {
    log("Testing: " + area.name)

    return await agent(`Test VirtOS ${area.name} subsystem comprehensively.

**Scripts to Test**: ${area.scripts.join(', ')}

**Test Checklist**:
${area.tests.map((t, i) => `${i+1}. ${t}`).join('\n')}

**Instructions**:
1. Run each test systematically
2. Record EXACT commands and outputs
3. Classify severity: critical (security/data loss) > high (broken functionality) > medium (inconsistency) > low (cosmetic)
4. For EACH finding, provide the test command that reproduces it
5. Mark fix_needed=true only for real bugs (not dev environment limitations)

**Environment Context**:
- Development environment (not installed VirtOS)
- Library path: config/custom-scripts/lib/virtos-common.sh
- Scripts path: config/custom-scripts/virtos-*

Return findings as structured JSON.`, {
      label: `Test: ${area.name}`,
      schema: ISSUE_SCHEMA,
      phase: 'Parallel Testing',
    })
  })
)

const allFindings = testResults.filter(Boolean).flatMap(r => r.findings || [])
log("Collected " + allFindings.length + " findings from " + testResults.filter(Boolean).length + " workers")

phase('Arbiter Review')
log('⚖️  Arbiter consolidating findings and prioritizing fixes...')

const arbiterDecision = await agent(`Review all VirtOS test findings and make fix decisions.

**All Findings** (${allFindings.length} total):
${JSON.stringify(allFindings, null, 2)}

**Your Task**:
1. **Identify false positives**: Dev environment quirks, expected behavior, already fixed
2. **Categorize real bugs**: critical → high → medium priority
3. **Find systematic issues**: Same bug across multiple scripts (fix once, apply everywhere)
4. **Prioritize fixes**: What to fix immediately vs. later

**Critical Severity Criteria**:
- Security vulnerabilities (command injection, path traversal)
- Data loss risks
- Privilege escalation

**High Priority Criteria**:
- Broken core functionality
- Inconsistent behavior across scripts
- User-facing errors

**Medium Priority Criteria**:
- Missing features
- Cosmetic issues
- Documentation gaps

Return categorized findings with clear fix priorities.`, {
  label: 'Arbiter Decision',
  schema: ARBITER_SCHEMA,
  phase: 'Arbiter Review',
})

log('Arbiter Results: Critical=' + arbiterDecision.critical_fixes.length +
    ', High=' + arbiterDecision.high_priority.length +
    ', Medium=' + arbiterDecision.medium_priority.length +
    ', FalsePositives=' + arbiterDecision.false_positives.length +
    ', Systematic=' + arbiterDecision.systematic_issues.length)

phase('Apply Fixes')

// Fix critical and high priority issues immediately
const fixTargets = [
  ...arbiterDecision.critical_fixes.map(f => ({ priority: 'critical', finding: f })),
  ...arbiterDecision.high_priority.map(f => ({ priority: 'high', finding: f })),
]

if (fixTargets.length === 0) {
  log('✅ No critical or high-priority fixes needed!')
} else {
  log('Applying ' + fixTargets.length + ' fixes...')

  const fixes = await pipeline(
    fixTargets,
    // Stage 1: Generate fix
    async ({ priority, finding }) => {
      const fix = await agent('Generate a fix for this VirtOS issue.\n\n' +
        '**Finding**: ' + finding + '\n\n' +
        '**Instructions**:\n' +
        '1. Read the affected script\n' +
        '2. Identify the exact issue\n' +
        '3. Generate the minimal fix\n' +
        '4. Return the exact Edit/Write command needed\n\n' +
        'Use Edit tool for changes, Write for new files.\n' +
        'Return the fix as executable commands.', {
        label: 'Fix: ' + priority,
        phase: 'Apply Fixes',
      })

      return { priority, finding, fix }
    },
    // Stage 2: Verify fix works
    async ({ priority, finding, fix }, original) => {
      const verification = await agent('Verify this fix actually works.\n\n' +
        '**Original Finding**: ' + original.finding + '\n' +
        '**Fix Applied**: ' + fix + '\n\n' +
        '**Instructions**:\n' +
        '1. Re-run the test that found the bug\n' +
        '2. Confirm the fix resolves the issue\n' +
        '3. Check for regressions\n' +
        '4. Return pass/fail with evidence\n\n' +
        'Return verification results.', {
        label: 'Verify: ' + original.priority,
        phase: 'Apply Fixes',
      })

      return { ...original, fix, verification }
    }
  )

  log('Fixed ' + fixes.filter(Boolean).length + '/' + fixTargets.length + ' issues')
}

phase('Verification')
log('🔍 Final verification of all changes...')

return {
  status: 'success',
  findings_count: allFindings.length,
  critical_fixed: arbiterDecision.critical_fixes.length,
  high_priority_fixed: arbiterDecision.high_priority.length,
  systematic_issues: arbiterDecision.systematic_issues,
  false_positives: arbiterDecision.false_positives,
}
