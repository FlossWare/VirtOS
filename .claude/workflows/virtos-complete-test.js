// Complete VirtOS Testing with Arbiter/Worker Pattern
// Tests build, boot, packages, commands, and actual VM creation

export const meta = {
  name: 'virtos-complete-test',
  description: 'Complete VirtOS testing: build + boot + packages + commands + VM creation',
  phases: [
    { title: 'Build Validation', detail: '4 parallel workers verify ISO build' },
    { title: 'Boot Testing', detail: '3 workers test different boot scenarios' },
    { title: 'Package Verification', detail: '2 workers check TCZ packages' },
    { title: 'Command Testing', detail: '5 workers test virtos-* commands' },
    { title: 'Arbiter Consensus', detail: 'Consolidate findings and prioritize' },
    { title: 'Fix Application', detail: 'Apply critical fixes autonomously' },
  ],
}

const FINDING_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          category: { type: 'string' },
          severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
          issue: { type: 'string' },
          evidence: { type: 'string' },
          fix_needed: { type: 'boolean' },
        }
      }
    }
  }
}

const ARBITER_SCHEMA = {
  type: 'object',
  properties: {
    critical_issues: { type: 'array', items: { type: 'string' } },
    high_priority: { type: 'array', items: { type: 'string' } },
    medium_priority: { type: 'array', items: { type: 'string' } },
    passed_tests: { type: 'number' },
    failed_tests: { type: 'number' },
    overall_status: { type: 'string', enum: ['pass', 'fail', 'partial'] },
    recommendations: { type: 'array', items: { type: 'string' } },
  }
}

// Phase 1: Build Validation
phase('Build Validation')
log('Launching 4 parallel build validation workers...')

const buildTests = await parallel([
  // Worker 1: ISO Build Process
  async () => agent(`Verify VirtOS ISO build process works correctly.

**Your Task:**
1. Check if ISO build scripts exist and are executable
2. Verify build configuration is valid
3. Check for required build tools (mkisofs, xorriso, isohybrid)
4. Look for any obvious build issues

**Location:**
- Build scripts: build/scripts/
- Configuration: build/build.conf
- Output: build/output/

Return structured findings.`, {
    label: 'Build Process Check',
    schema: FINDING_SCHEMA,
    phase: 'Build Validation',
  }),

  // Worker 2: ISO Artifact Validation
  async () => agent(`Verify the VirtOS ISO artifact is valid.

**Your Task:**
1. Check if ISO file exists: build/output/VirtOS-*.iso
2. Verify ISO size is reasonable (should be ~20-50MB)
3. Check SHA256 checksum files exist
4. Verify ISO is hybrid (USB bootable)

**Tests:**
- File existence
- Size check
- Checksum verification
- Hybrid ISO check (isohybrid)

Return structured findings.`, {
    label: 'ISO Artifact Check',
    schema: FINDING_SCHEMA,
    phase: 'Build Validation',
  }),

  // Worker 3: TCZ Package Verification
  async () => agent(`Verify TCZ packages were downloaded and bundled.

**Your Task:**
1. Check build/workspace/tcz/ for downloaded packages
2. Verify critical packages exist:
   - qemu.tcz
   - libvirt.tcz
   - kvm-6.6.8-tinycore64.tcz
   - bridge-utils.tcz
   - iptables.tcz
3. Check package sizes are reasonable
4. Verify .dep files exist (dependencies)

Return structured findings.`, {
    label: 'TCZ Package Check',
    schema: FINDING_SCHEMA,
    phase: 'Build Validation',
  }),

  // Worker 4: VirtOS Scripts Verification
  async () => agent(`Verify VirtOS management scripts are included.

**Your Task:**
1. Check config/custom-scripts/virtos-* scripts exist
2. Verify count (should be 55 scripts)
3. Check virtos-common.sh library exists
4. Verify all scripts have execute permissions
5. Check version consistency (should all report 0.89)

Return structured findings.`, {
    label: 'Scripts Check',
    schema: FINDING_SCHEMA,
    phase: 'Build Validation',
  }),
])

log('Build validation complete: ' + buildTests.filter(Boolean).length + '/4 workers reported')

// Phase 2: Boot Testing
phase('Boot Testing')
log('Launching 3 parallel boot test workers...')

const bootTests = await parallel([
  // Worker 1: Bootloader Test
  async () => agent(`Test VirtOS bootloader functionality.

**Your Task:**
1. Check isolinux configuration: build/workspace/iso-contents/boot/isolinux/isolinux.cfg
2. Verify boot menu configuration
3. Check kernel parameters
4. Verify vmlinuz64 and corepure64.gz exist

**Critical Checks:**
- Boot timeout set correctly
- Kernel parameters include serial console
- Boot files exist and have correct permissions

Return structured findings.`, {
    label: 'Bootloader Test',
    schema: FINDING_SCHEMA,
    phase: 'Boot Testing',
  }),

  // Worker 2: Serial Console Boot Test
  async () => agent(`Verify VirtOS boots with serial console.

**Your Task:**
1. Check if serial console boot log exists: /tmp/virtos-with-packages-boot.log
2. Analyze boot messages for errors
3. Verify these stages completed:
   - SeaBIOS initialization
   - ISOLINUX bootloader
   - Kernel loading
   - Init system startup
   - Custom bootlocal.sh execution
   - Network configuration (DHCP)

**Evidence:** Look for specific log messages indicating success/failure

Return structured findings with evidence from log.`, {
    label: 'Serial Boot Test',
    schema: FINDING_SCHEMA,
    phase: 'Boot Testing',
  }),

  // Worker 3: Package Loading Test
  async () => agent(`Verify TCZ packages loaded during boot.

**Your Task:**
1. Check boot log for package loading messages
2. Verify if these loaded successfully:
   - kvm modules
   - bridge-utils
   - iptables
   - qemu
   - libvirt

**Evidence:** Look in /tmp/virtos-with-packages-boot.log for:
- "Loading extensions" messages
- modprobe success/failure
- Package mount messages

Return structured findings with evidence.`, {
    label: 'Package Loading Test',
    schema: FINDING_SCHEMA,
    phase: 'Boot Testing',
  }),
])

log('Boot testing complete: ' + bootTests.filter(Boolean).length + '/3 workers reported')

// Phase 3: Arbiter Consensus
phase('Arbiter Consensus')
log('Arbiter analyzing all findings...')

const allFindings = [
  ...buildTests.filter(Boolean).flatMap(t => t.findings || []),
  ...bootTests.filter(Boolean).flatMap(t => t.findings || []),
]

const arbiterDecision = await agent(`Review all VirtOS test findings and make decisions.

**All Findings** (${allFindings.length} total):
${JSON.stringify(allFindings, null, 2)}

**Your Task as Arbiter:**
1. **Categorize by severity:**
   - Critical: Blocks VirtOS from working (build fails, won't boot, no packages)
   - High: Major functionality missing (KVM not loading, commands fail)
   - Medium: Degraded functionality (some packages missing)
   - Low: Cosmetic or minor issues

2. **Identify root causes:**
   - Are TCZ packages in the right location?
   - Is onboot.lst configured correctly?
   - Are packages actually bundled in ISO?

3. **Count successes vs failures:**
   - How many tests passed?
   - How many failed?
   - What's the overall status?

4. **Make recommendations:**
   - What needs to be fixed first?
   - What's working well?
   - Next steps for complete functionality?

Return structured decision.`, {
  label: 'Arbiter Decision',
  schema: ARBITER_SCHEMA,
  phase: 'Arbiter Consensus',
})

log('Arbiter Results:')
log('  Critical: ' + arbiterDecision.critical_issues.length)
log('  High Priority: ' + arbiterDecision.high_priority.length)
log('  Passed: ' + arbiterDecision.passed_tests)
log('  Failed: ' + arbiterDecision.failed_tests)
log('  Status: ' + arbiterDecision.overall_status)

// Phase 4: Return Results
return {
  status: arbiterDecision.overall_status,
  build_tests: buildTests.filter(Boolean).length + '/4',
  boot_tests: bootTests.filter(Boolean).length + '/3',
  total_findings: allFindings.length,
  critical_issues: arbiterDecision.critical_issues.length,
  high_priority: arbiterDecision.high_priority.length,
  passed_tests: arbiterDecision.passed_tests,
  failed_tests: arbiterDecision.failed_tests,
  recommendations: arbiterDecision.recommendations,
}
