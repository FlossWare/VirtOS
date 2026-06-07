# AI-Assisted Development in VirtOS

This document explains how AI (specifically Claude Code) is used in VirtOS development and provides guidelines for contributors working with AI-generated code.

## What is Claude Code?

[Claude Code](https://claude.ai/code) is Anthropic's official AI coding assistant that assists with VirtOS development through:

- Code generation and refactoring
- Documentation writing and formatting
- Test creation (BATS test files)
- Code review and quality checks
- Issue triage and automated fixes
- Boilerplate generation

## AI vs Human Contributions

VirtOS uses a **collaborative AI-human development model** where AI accelerates development but humans make all critical decisions.

### What AI (Claude Code) Handles

✅ **100% AI-Automated**:

- Code formatting (pre-commit hooks)
- Linting and style fixes
- Test file structure generation
- Documentation formatting
- Automated code reviews
- Issue labeling and triage

✅ **AI-Generated, Human-Reviewed**:

- Documentation writing (guides, README, tutorials)
- Help text for scripts (`show_help()` functions)
- Boilerplate code (script templates)
- BATS test cases
- Refactoring suggestions
- Simple bug fixes

### What Humans Own

🧑‍💻 **Core Development** (Human-Led):

- **Architecture** - System design, component organization
- **Security code** - Input validation, privilege handling, audit logic
- **libvirt integration** - VM management, storage, networking backends
- **Business logic** - Workflow design, state management
- **API contracts** - Breaking changes, deprecation policy
- **Production decisions** - Deployment, scaling, incident response

🔍 **Human Review Required**:

- All security-sensitive code
- Backend implementations (virtos-* script logic)
- Breaking API changes
- External dependency additions
- Compliance-critical code (audit logging)
- Performance-critical paths

## How to Identify AI Contributions

All AI-generated commits include co-authorship attribution:

```text
Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### View AI Commits

```bash
# List all AI-attributed commits
git log --grep="Co-Authored-By: Claude" --oneline

# View AI contribution stats
git log --grep="Co-Authored-By: Claude" --pretty=format:"%h %s" | wc -l

# Compare human vs AI commits
total=$(git log --oneline | wc -l)
ai=$(git log --grep="Co-Authored-By: Claude" --oneline | wc -l)
echo "Total: $total | AI: $ai | Human: $((total - ai))"
```

## Quality Standards

**AI code must meet the same quality standards as human code.**

### All Code (Human and AI) Must

1. ✅ **Pass Tests** - All BATS tests passing
2. ✅ **Pass Security Review** - Manual review for security code
3. ✅ **Have Documentation** - Help text, comments where needed
4. ✅ **Pass Pre-commit Checks** - 12 automated quality gates
5. ✅ **Get Human Approval** - Final merge decision by human maintainer

### Pre-Commit Quality Gates

```bash
# All code (human and AI) must pass:
- check for added large files
- check for case conflicts
- check for merge conflicts
- check that scripts with shebangs are executable
- detect private key
- fix end of files
- trim trailing whitespace
- ShellCheck (all severity levels)
- Shell script formatting
- Bashate (shell style checker)
- Markdown linting
- Detect secrets
```

## Guidelines for Human Contributors

### Working With AI-Generated Code

**✅ DO**:

- Review AI code critically (like any PR)
- Test AI code thoroughly before merging
- Ask AI to explain its reasoning
- Request changes if something is unclear
- Use AI for time-consuming tasks (test writing, documentation)
- Leverage AI for code exploration and pattern finding

**❌ DON'T**:

- Blindly trust AI output without testing
- Skip security review for AI security code
- Accept AI architectural decisions without discussion
- Use AI for compliance decisions (PCI-DSS, HIPAA, SOX)
- Delegate final judgment to AI

### When to Use AI Assistance

**Good Use Cases** 🟢:

- Writing BATS test files (structural, repetitive)
- Generating help text (`show_help()` functions)
- Formatting documentation (markdown, code comments)
- Finding code patterns or anti-patterns
- Creating boilerplate (script templates)
- Writing examples and tutorials
- Refactoring for readability

**Use With Caution** 🟡:

- Backend implementations (verify correctness)
- Error handling logic (test edge cases)
- Performance optimizations (benchmark results)
- Complex refactoring (verify no behavior changes)

**Avoid AI** 🔴:

- Designing security mechanisms (input validation, privilege checks)
- Making breaking API changes
- Critical infrastructure code (libvirt integration core)
- Audit logging internals (compliance requirements)
- Performance-critical hot paths (needs profiling)

## Transparency Principles

VirtOS maintains full transparency about AI usage:

### 1. Git Attribution

Every AI commit clearly marked:

```bash
git log --format="%h %s %an" | grep "Claude"
```

### 2. This Documentation

- Explains AI role in project
- Clarifies human responsibilities
- Provides guidelines for contributors

### 3. Issue Labels

AI-detected issues labeled (when using workflows):

- `ai-review` - Created by automated code review (e.g., `/code-review` workflow)
- `automated-fix` - Created by automated fixing (e.g., `/code-solve` workflow)
- `ai-generated` - Indicates AI-generated code/content

### 4. Code Comments

Complex AI-generated logic includes explanatory comments:

```bash
# SECURITY NOTE: eval is required here to execute workflow commands
# Workflow files must be trusted (checked above for permissions)
eval "$current_command"
```

## Automated Code Quality System

The `.claude/scripts/` directory contains automated quality tools that run every 10 minutes.

### What Gets Automated

```bash
# Continuous code review (.claude/scripts/code_review.sh)
├── Shell script security scans
├── TODO/FIXME detection
├── Code duplication checks
└── Style violations

# Automated issue creation (.claude/scripts/create_review_issues.py)
├── GitHub issues for findings
├── Priority assignment
├── File/line references
└── Suggested fixes

# Auto-fix and push (.claude/scripts/auto_fix_and_push.sh)
├── Safe formatting fixes
├── Help text generation
├── Simple refactoring
└── Co-authored commits
```

### Human Oversight

Despite automation, humans control:

- **What gets merged** - All PRs require human approval
- **What gets deployed** - Production releases are manual
- **Breaking changes** - Require human RFC and discussion
- **Security patches** - Manual review even for AI fixes

## Contribution Workflow

### For Human Contributors

```bash
# 1. Make changes (with or without AI assistance)
git add <files>

# 2. Pre-commit checks run automatically
# (12 quality gates - human and AI code both checked)

# 3. Commit with clear message
git commit -m "fix: improve error handling in virtos-network"

# 4. Push to branch
git push origin feature-branch

# 5. Create PR (human review required)
gh pr create --title "..." --body "..."

# 6. Address review feedback
# (Both human and AI can suggest improvements)

# 7. Merge after approval
# (Final decision: human maintainer)
```

### For AI-Assisted Changes

Same workflow, but commits include co-authorship:

```bash
git commit -m "docs: add container examples to QUICK-START.md

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

## Security Considerations

### AI-Generated Security Code

All security-sensitive code (regardless of origin) requires:

1. **Manual code review** by human security-aware developer
2. **Security testing** beyond standard unit tests
3. **Threat modeling** for new attack surface
4. **Penetration testing** for critical paths
5. **Compliance verification** (PCI-DSS, HIPAA, etc.)

### What AI Can Do

✅ **Low-risk security tasks**:

- Formatting security documentation
- Generating security test cases (structure)
- Finding potential vulnerabilities (code review)
- Writing security examples for docs

### What AI Cannot Do

❌ **High-risk security decisions**:

- Designing authentication/authorization systems
- Implementing cryptographic operations
- Making privilege escalation decisions
- Writing compliance-critical audit code
- Evaluating third-party security libraries

## Examples of Good AI Usage

### ✅ Good: Documentation Generation

```bash
# Human provides structure, AI fills content
Human: "Write help text for virtos-network"
AI: Generates comprehensive --help output
Human: Reviews for accuracy, approves
Result: ✅ Merged (low risk, high value)
```

### ✅ Good: Test Case Generation

```bash
# Human defines test scope, AI writes test cases
Human: "Add BATS tests for virtos-snapshot"
AI: Generates 106 functional tests
Human: Reviews test coverage, runs tests
Result: ✅ Merged (verified correctness)
```

### ❌ Bad: Security Implementation

```bash
# AI designs security mechanism without human guidance
AI: "I'll add input validation to all scripts"
Human: Didn't review validation logic thoroughly
Result: ❌ Potential security gaps, reject
```

### ✅ Good: Security Review

```bash
# AI finds issues, human decides fix
AI: "Found potential command injection in virtos-automation"
Human: Reviews context, determines it's documented/safe
Result: ✅ Issue closed as false positive
```

## Statistics (as of 2026-05-29)

### Contribution Breakdown

- **Total Commits**: 500+
- **AI-Attributed**: ~200 (40%)
- **Human-Only**: ~300 (60%)

### AI Usage by Category

- **Documentation**: 60% (guides, help text, comments)
- **Testing**: 25% (BATS test files, test cases)
- **Refactoring**: 10% (formatting, cleanup)
- **Bug Fixes**: 5% (simple, obvious fixes)

### Quality Metrics

- **Code Quality**: A- (92.8/100)
- **Security Score**: A+ (97/100)
- **Test Coverage**: 100% (54/54 files with tests)
- **Pre-commit Pass Rate**: 99%+ (both human and AI code)

All metrics maintained through human+AI collaboration.

## Common Questions

### Q: Can I trust AI-generated code?

**A**: Treat it like any other PR - review, test, and verify. AI code goes through the same quality gates as human code.

### Q: Will AI replace human developers?

**A**: No. AI is a productivity tool, not a replacement. Humans make all architectural, security, and business decisions.

### Q: How do I know if code is AI-generated?

**A**: Check for `Co-Authored-By: Claude Sonnet 4.5` in git commits. Also, check file history.

### Q: What if I disagree with an AI change?

**A**: Same as any PR - comment on it, request changes, or reject it. Humans have final say.

### Q: Can I disable AI assistance?

**A**: Yes. The `.claude/` directory can be ignored. AI is opt-in for contributors.

## Related Documentation

- **[CONTRIBUTING.md](../CONTRIBUTING.md)** - General contribution guidelines
- **[CODING_STANDARDS.md](../docs/CODING_STANDARDS.md)** - Code quality standards
- **[SECURITY-HARDENING.md](../docs/SECURITY-HARDENING.md)** - Security practices
- **[.claude/README.md](README.md)** - Automated code review system

## Questions or Concerns?

- **GitHub Issues**: [github.com/FlossWare/VirtOS/issues](https://github.com/FlossWare/VirtOS/issues)
- **GitHub Discussions**: [github.com/FlossWare/VirtOS/discussions](https://github.com/FlossWare/VirtOS/discussions)
- **Security**: Report privately to maintainers (see SECURITY.md)

---

**Summary**: VirtOS uses AI as a development accelerator that handles time-consuming tasks (docs, tests, formatting) while humans retain control over architecture, security, and all critical decisions. All code, regardless of origin, meets the same quality standards and requires human approval before merge.

---

**Created**: 2026-05-29  
**Maintained By**: VirtOS Contributors  
**Status**: Official Project Policy
