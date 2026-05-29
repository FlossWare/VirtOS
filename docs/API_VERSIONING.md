# VirtOS API Versioning Policy

**Last Updated**: 2026-05-29  
**Status**: Implemented  
**Related Issue**: [#105](https://github.com/FlossWare/VirtOS/issues/105)

---

## Overview

VirtOS management scripts form a **command-line API** that users and automation tools depend on. This document defines how we version, evolve, and deprecate script interfaces to maintain stability while enabling innovation.

**Key Principle**: **Backward compatibility within major versions**. Scripts can add features but cannot break existing behavior without a major version bump.

---

## Versioning Scheme

### Two-Level Versioning

Every VirtOS script has **two version numbers**:

1. **VirtOS Version** - The overall VirtOS release (e.g., `0.1`, `1.0`, `2.5`)
   - Tracks VirtOS distribution version
   - Incremented by CD pipeline
   - Synchronized across all packages

2. **API Version** - The script interface version (e.g., `1.0`, `2.0`)
   - Tracks command-line interface changes
   - Incremented manually when interface changes
   - Independent per script (different scripts can have different API versions)

### API Version Format

**`MAJOR.MINOR`** (Semantic Versioning subset)

- **MAJOR** - Incremented for breaking changes
  - Argument removed or renamed
  - Output format changed (breaks parsers)
  - Exit code meaning changed
  - Default behavior changed (affects existing scripts)
  
- **MINOR** - Incremented for backward-compatible additions
  - New argument added
  - New feature added (doesn't break existing usage)
  - Deprecation warning added
  - Bug fix that changes behavior (if significant)

**Examples**:
- `1.0` → `1.1` - Added `--format json` option (backward compatible)
- `1.1` → `2.0` - Changed default output from text to JSON (breaking change)

---

## Implementation

### Script Header

Every script must declare its API version:

```bash
#!/bin/sh
# virtos-create-vm - Create virtual machine
#
# API Version: 1.0
# VirtOS Version: 0.1

# API version constant
readonly API_VERSION="1.0"

# VirtOS version from package
readonly VIRTOS_VERSION="$(get_version)"
```

### Version Flags

All scripts must support:

```bash
--version, -v, version
    Show both VirtOS version and API version
    
--api-version
    Show only API version (for compatibility checks)
```

**Example Output**:
```
$ virtos-create-vm --version
virtos-create-vm version 0.1 (API 1.0)

$ virtos-create-vm --api-version
1.0
```

### Compatibility Checking

Scripts that depend on other scripts can check API compatibility:

```bash
# Check if virtos-network has compatible API
required_api="1.0"
actual_api=$(virtos-network --api-version)

if [ "$actual_api" != "$required_api" ]; then
    echo "Warning: virtos-network API mismatch (have $actual_api, need $required_api)" >&2
fi
```

---

## Change Management

### When to Bump API Version

**Increment MINOR (1.0 → 1.1)** when:
- ✅ Adding optional argument: `--cpu <count>` → add `--memory <size>`
- ✅ Adding new feature (doesn't break existing usage)
- ✅ Adding deprecation warning (doesn't break, just warns)
- ✅ Improving error messages (non-breaking)
- ✅ Adding new output format option: `--format json`
- ✅ Bug fix that changes behavior (if observable to users)

**Increment MAJOR (1.x → 2.0)** when:
- ❌ Removing argument: `--old-flag` deleted
- ❌ Renaming argument: `--cpu` → `--vcpu`
- ❌ Changing required arguments: `<vm-name>` → `<vm-name> <disk-size>`
- ❌ Changing output format (breaks parsers): text → JSON by default
- ❌ Changing exit codes: success was 0, now 0 or 2
- ❌ Changing default behavior: `virtos-create-vm` now requires `--disk` instead of defaulting
- ❌ Removing feature/command

**Do NOT bump API version** when:
- ✅ Internal refactoring (no observable change)
- ✅ Performance improvements
- ✅ Bug fix that only fixes obviously wrong behavior
- ✅ Documentation changes
- ✅ Adding comments to code

### Deprecation Process

**Before removing a feature**, follow the deprecation process:

1. **Announce Deprecation** (MINOR version bump)
   - Add deprecation warning
   - Document in CHANGELOG-API.md
   - Update documentation

2. **Grace Period** (At least 1 major version or 6 months)
   - Old feature continues to work with warning
   - Users have time to migrate

3. **Removal** (MAJOR version bump)
   - Remove deprecated feature
   - Update API version MAJOR
   - Document migration in CHANGELOG-API.md

**Example Deprecation**:

```bash
# API 1.0: Introduce new flag, deprecate old
if [ -n "$OLD_FLAG" ]; then
    echo "Warning: --old-flag is deprecated, use --new-flag (will be removed in API 2.0)" >&2
    NEW_FLAG="$OLD_FLAG"  # Still works
fi

# API 1.1, 1.2, etc: Both flags work, warning continues

# API 2.0: Remove old flag
# OLD_FLAG no longer recognized
```

---

## API Changelog

All API changes are documented in **CHANGELOG-API.md**:

```markdown
# VirtOS API Changelog

## virtos-create-vm

### API 2.0 (2027-01-15)
**BREAKING CHANGES**:
- Removed `--old-format` flag (deprecated in API 1.1)
- Default output format changed to JSON (use `--format text` for old behavior)

**Migration Guide**:
- Replace `virtos-create-vm --old-format` with `virtos-create-vm --format legacy`
- Update parsers to handle JSON output or add `--format text` flag

### API 1.1 (2026-06-01)
**Backward Compatible**:
- Added `--format <type>` flag (text|json|legacy)
- Deprecated `--old-format`, use `--format legacy` instead
- Added deprecation warnings

### API 1.0 (2026-05-01)
**Initial Release**:
- Basic VM creation functionality
```

---

## Testing API Compatibility

### Compatibility Test Suite

Create tests that verify API stability:

```bash
# tests/api/virtos-create-vm-api-1.0.bats

@test "virtos-create-vm API 1.0: help flag works" {
    run virtos-create-vm --help
    [ "$status" -eq 0 ]
}

@test "virtos-create-vm API 1.0: version flag shows API version" {
    run virtos-create-vm --version
    [[ "$output" =~ "API 1.0" ]]
}

@test "virtos-create-vm API 1.0: required arguments" {
    # Verify that API 1.0 argument structure still works
    run virtos-create-vm --name test --cpu 2 --memory 1024 --disk 10G
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]  # May fail without libvirt, but args parsed
}

@test "virtos-create-vm API 1.0: output format unchanged" {
    # Verify output format hasn't changed
    run virtos-create-vm --name test --cpu 1 --memory 512 --disk 5G --dry-run
    [[ "$output" =~ "VM created: test" ]] || [[ "$output" =~ "Would create VM: test" ]]
}
```

### CI Integration

Run API compatibility tests on every commit:

```yaml
# .github/workflows/ci.yml
- name: Run API Compatibility Tests
  run: |
    cd tests/api
    bats *.bats
```

---

## Version Support Policy

### Supported Versions

**Current Policy** (Alpha/Beta):
- **Latest API version only** - Best effort backward compatibility
- Breaking changes allowed with deprecation warnings
- No LTS (Long-Term Support) versions yet

**Future Policy** (v1.0+):
- **N and N-1** - Support current and previous major version
- **LTS releases** - Every 3rd major version (e.g., 3.0, 6.0, 9.0)
- **6-month minimum** between major versions

**Example Timeline**:
```
API 1.0 released: 2026-05-01
API 1.1 released: 2026-06-01
API 1.2 released: 2026-07-01
API 2.0 released: 2026-11-01
  ↳ API 1.x deprecated, removal planned for API 3.0 (2027-05-01)
API 2.1 released: 2026-12-01
API 3.0 released: 2027-05-01
  ↳ API 1.x removed (after 6-month grace period)
  ↳ API 2.x supported until API 4.0
```

---

## Migration Guides

When introducing breaking changes, provide migration guides:

### Template: API Migration Guide

```markdown
# Migrating from API 1.x to API 2.0

## virtos-create-vm

### Breaking Changes

**1. Output format changed to JSON by default**

**Old behavior (API 1.x)**:
```bash
$ virtos-create-vm test
VM created: test
CPU: 2
Memory: 1024MB
```

**New behavior (API 2.0)**:
```bash
$ virtos-create-vm test
{"name":"test","cpu":2,"memory":"1024MB","status":"created"}
```

**Migration**:
- Parsers: Update to parse JSON
- Scripts: Add `--format text` to get old output
- CI/CD: Add `--format text` to existing automation

**2. `--old-flag` removed**

**Old behavior (API 1.x)**:
```bash
virtos-create-vm --old-flag value
```

**New behavior (API 2.0)**:
```bash
virtos-create-vm --new-flag value
```

**Migration**: Replace all uses of `--old-flag` with `--new-flag`
```

---

## Best Practices

### For VirtOS Developers

1. **Think Before Breaking**
   - Can this be backward compatible?
   - Can we add instead of change?
   - Is a deprecation period possible?

2. **Document Everything**
   - Update CHANGELOG-API.md
   - Update docs/API_VERSIONING.md
   - Add migration guide for breaking changes

3. **Test Compatibility**
   - Run API compatibility tests
   - Test old scripts still work
   - Verify deprecation warnings appear

4. **Communicate Changes**
   - Announce in release notes
   - Post to mailing list/forum
   - Update documentation immediately

### For VirtOS Users

1. **Check API Version**
   ```bash
   virtos-create-vm --api-version  # Check before automating
   ```

2. **Pin to Specific Versions** (when critical)
   ```bash
   # In automation, check API version
   if [ "$(virtos-create-vm --api-version)" != "1.0" ]; then
       echo "Error: Incompatible API version" >&2
       exit 1
   fi
   ```

3. **Monitor Deprecation Warnings**
   - Read stderr output
   - Update scripts when deprecations appear
   - Don't wait until removal

4. **Test Before Upgrading**
   - Test scripts in non-production
   - Check release notes for breaking changes
   - Review CHANGELOG-API.md

---

## Current API Versions

| Script | API Version | Last Changed | Notes |
|--------|-------------|--------------|-------|
| virtos-setup | 1.0 | 2026-05-01 | Initial release |
| virtos-create-vm | 1.0 | 2026-05-01 | Initial release |
| virtos-migrate | 1.0 | 2026-05-01 | Initial release |
| virtos-snapshot | 1.0 | 2026-05-01 | Initial release |
| virtos-network | 1.0 | 2026-05-01 | Initial release |
| virtos-storage | 1.0 | 2026-05-01 | Initial release |
| virtos-backup | 1.0 | 2026-05-01 | Initial release |
| virtos-monitor | 1.0 | 2026-05-01 | Initial release |
| virtos-cluster | 1.0 | 2026-05-01 | Initial release |
| virtos-tui | 1.0 | 2026-05-01 | Initial release |
| virtos-audit | 1.0 | 2026-05-29 | Initial release |
| *(all others)* | 1.0 | 2026-05-01 | Initial release |

**Note**: All scripts are currently at API 1.0 (initial stable interface).

---

## FAQ

### Q: Do internal functions have API versions?

**A**: No, only **command-line interfaces** (scripts users run). Internal functions in libraries (virtos-common.sh, virtos-audit.sh) can change freely as long as script interfaces remain stable.

### Q: What about output format changes?

**A**: Output format changes are **breaking** if:
- Scripts/tools parse the output (e.g., `grep`, `awk`, `jq`)
- Exit codes change meaning

Output format changes are **non-breaking** if:
- New `--format` flag added (existing format unchanged)
- Only improving error messages
- Adding optional verbose output

### Q: How do I know if my change breaks the API?

**A**: Ask:
1. Will existing user scripts/automation break?
2. Will existing output parsers break?
3. Will existing CI/CD pipelines break?

If **YES** to any → breaking change → MAJOR version bump

### Q: Can different scripts have different API versions?

**A**: Yes! Each script has independent API versioning. `virtos-create-vm` can be API 2.0 while `virtos-network` is still API 1.0.

### Q: What about experimental scripts?

**A**: Experimental scripts (see [EXPERIMENTAL_FEATURES.md](EXPERIMENTAL_FEATURES.md)) **have no API stability guarantees**. They can change freely without version bumps.

---

## See Also

- [EXPERIMENTAL_FEATURES.md](EXPERIMENTAL_FEATURES.md) - Experimental vs stable scripts
- [CHANGELOG.md](../CHANGELOG.md) - VirtOS release changelog
- [VERSIONING.md](VERSIONING.md) - VirtOS package versioning
- [GitHub Issue #105](https://github.com/FlossWare/VirtOS/issues/105) - API versioning requirement

---

**Document Version**: 1.0  
**Author**: VirtOS Team  
**License**: Same as VirtOS project (GPL-3.0)
