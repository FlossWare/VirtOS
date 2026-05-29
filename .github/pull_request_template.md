## Description

<!-- Provide a clear and concise description of what this PR does -->

## Related Issues

<!-- Link to related issues using #issue-number -->
<!-- Use "Fixes #123" to auto-close issues when merged -->

Fixes #
Related to #

## Type of Change

<!-- Mark the relevant option with an "x" -->

- [ ] 🐛 Bug fix (non-breaking change that fixes an issue)
- [ ] ✨ New feature (non-breaking change that adds functionality)
- [ ] 💥 Breaking change (fix or feature that breaks existing functionality)
- [ ] 📝 Documentation update (changes to docs only)
- [ ] 🔧 Configuration change (CI/CD, build system, etc.)
- [ ] ♻️ Refactoring (code changes that neither fix bugs nor add features)
- [ ] ⚡ Performance improvement
- [ ] ✅ Test update (adding or updating tests)
- [ ] 🎨 Style/formatting (code style, formatting, missing semicolons, etc.)

## Changes Made

<!-- List the specific changes made in this PR -->

-
-
-

## Testing

<!-- Describe how you tested your changes -->

### Test Environment

- [ ] Tested on VirtOS (version: )
- [ ] Tested on development machine
- [ ] VM/Container used:
- [ ] Operating System:
- [ ] Kernel version:

### Tests Performed

- [ ] Syntax validation (`bash -n <script>`)
- [ ] ShellCheck passed (`shellcheck <script>`)
- [ ] Unit tests passed (`bats tests/<script>.bats`)
- [ ] Integration tests passed
- [ ] Manual testing completed
- [ ] Pre-commit hooks passed

### Test Results

<!-- Paste test output or describe manual testing steps -->

```bash
# Example test output
$ bash -n config/custom-scripts/virtos-example
$ shellcheck config/custom-scripts/virtos-example
$ bats tests/virtos-example.bats
✓ virtos-example shows help
✓ virtos-example handles invalid input
2 tests, 0 failures
```

## Checklist

### Code Quality

- [ ] My code follows the project's coding style (see .editorconfig)
- [ ] I have run `pre-commit run --all-files` and fixed all issues
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] My changes generate no new warnings
- [ ] I have added error handling for edge cases

### Security

- [ ] I have validated all user inputs (see docs/SECURITY-HARDENING.md)
- [ ] I have avoided command injection vulnerabilities
- [ ] I have avoided path traversal vulnerabilities
- [ ] I have not hardcoded any credentials or secrets
- [ ] I have used appropriate file permissions

### Test Coverage

- [ ] I have added tests that prove my fix is effective or feature works
- [ ] New and existing unit tests pass locally
- [ ] I have tested error scenarios
- [ ] I have tested with invalid/malicious input

### Documentation

- [ ] I have updated relevant documentation (README, docs/, help text)
- [ ] I have updated CHANGELOG.md with my changes
- [ ] I have added examples where appropriate
- [ ] My commit messages follow conventional commits format

### Dependencies

- [ ] I have not introduced new external dependencies
- [ ] OR: New dependencies are documented and justified
- [ ] OR: New dependencies are minimal and align with project philosophy

### Breaking Changes

<!-- Only if this is a breaking change -->

- [ ] I have followed the deprecation policy (docs/DEPRECATION_POLICY.md)
- [ ] I have updated version numbers appropriately
- [ ] I have provided migration guide for users
- [ ] I have added deprecation warnings to old functionality

## Screenshots/Examples

<!-- If applicable, add screenshots or examples of the changes -->
<!-- For CLI changes, show before/after command output -->
<!-- For UI changes, show screenshots -->

### Before

```bash
# Example: old behavior
```

### After

```bash
# Example: new behavior
```

## Performance Impact

<!-- If applicable, describe any performance implications -->

- [ ] No significant performance impact
- [ ] Improves performance (describe how)
- [ ] May impact performance (explain why it's acceptable)
- [ ] Performance testing results:

## Backward Compatibility

<!-- Describe backward compatibility considerations -->

- [ ] Fully backward compatible
- [ ] Partially backward compatible (explain)
- [ ] Breaking change (migration guide provided)

## Deployment Notes

<!-- Any special deployment considerations? -->

- [ ] No special deployment steps required
- [ ] Requires VirtOS restart
- [ ] Requires configuration changes (document them)
- [ ] Requires TCZ package rebuild
- [ ] Requires ISO rebuild

## Additional Context

<!-- Add any other context about the PR here -->
<!-- Link to design documents, discussions, or related work -->

## Reviewer Checklist

<!-- For reviewers - do not modify -->

- [ ] Code follows project style and conventions
- [ ] Changes are well-documented
- [ ] Tests are adequate and passing
- [ ] Security considerations addressed
- [ ] Breaking changes properly documented
- [ ] CHANGELOG.md updated appropriately

---

**Contribution Guidelines**: See [CONTRIBUTING.md](../CONTRIBUTING.md)  
**Code of Conduct**: [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md)  
**Deprecation Policy**: [docs/DEPRECATION_POLICY.md](../docs/DEPRECATION_POLICY.md)
