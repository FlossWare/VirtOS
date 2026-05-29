# VirtOS Deprecation Policy

**Version**: 1.0  
**Last Updated**: 2026-05-29  
**Status**: Official

This document defines the deprecation policy for VirtOS features, APIs, and interfaces. Following this policy ensures users have adequate time to migrate away from deprecated functionality while maintaining project velocity.

## Purpose

The deprecation policy exists to:

1. **Protect Users** - Provide advance warning before removing features
2. **Enable Evolution** - Allow the project to improve and remove technical debt
3. **Maintain Stability** - Balance innovation with backward compatibility
4. **Communicate Clearly** - Set expectations about feature lifecycles

## Scope

This policy applies to:

- ✅ Command-line interfaces (all `virtos-*` scripts)
- ✅ Configuration file formats
- ✅ REST API endpoints (`virtos-api`)
- ✅ TUI menu structure (`virtos-tui`)
- ✅ Web UI interfaces (Cockpit module)
- ✅ Script output formats (for automation)
- ✅ TCZ package structure

This policy does NOT apply to:

- ❌ Internal implementation details (not user-visible)
- ❌ Experimental features (clearly marked as research prototypes)
- ❌ Development/testing tools
- ❌ Private functions (not documented as public API)

## Deprecation Timeline

### Standard Deprecation (6-Month Policy)

```text
┌─────────────────────────────────────────────────────────────┐
│                    Deprecation Timeline                      │
├─────────────────────────────────────────────────────────────┤
│ T+0 months    │ Announcement & Warning Phase Begins         │
│               │ - Feature marked deprecated in docs         │
│               │ - Warning message added to command          │
│               │ - Announced in CHANGELOG.md                 │
│               │ - GitHub issue created                      │
├─────────────────────────────────────────────────────────────┤
│ T+1-5 months  │ Warning Period                              │
│               │ - Feature still works fully                 │
│               │ - Warning shown on every use                │
│               │ - Migration guide available                 │
│               │ - Alternative documented                    │
├─────────────────────────────────────────────────────────────┤
│ T+6 months    │ Removal in Next Major Version               │
│               │ - Feature removed from codebase             │
│               │ - Entry in CHANGELOG.md (BREAKING CHANGE)   │
│               │ - Documented in migration guide             │
└─────────────────────────────────────────────────────────────┘
```

### Accelerated Deprecation (Security/Critical Issues)

For security vulnerabilities or critical bugs, the timeline may be shortened:

- **Critical Security Issue**: 0-1 month (immediate removal if necessary)
- **Data Loss Risk**: 1-2 months
- **Severe Performance Issue**: 2-3 months

## Deprecation Process

### Step 1: Announcement (T+0)

**Required Actions**:

1. **Create GitHub Issue**:

   ```markdown
   Title: [DEPRECATION] Feature X will be removed in vY.Z

   ## Summary
   Feature X is deprecated and will be removed in version Y.Z.

   ## Timeline
   - Announcement: YYYY-MM-DD
   - Planned Removal: YYYY-MM-DD (version Y.Z)

   ## Reason
   [Why is this being deprecated?]

   ## Alternative
   Use Feature Z instead: `virtos-new-command`

   ## Migration Guide
   [Link to migration documentation]
   ```

2. **Update CHANGELOG.md**:

   ```markdown
   ### Deprecated
   - `virtos-old-command` - Use `virtos-new-command` instead. Will be removed in v2.0.
   ```

3. **Add Warning to Script**:

   ```bash
   echo "WARNING: This command is deprecated and will be removed in v2.0." >&2
   echo "Please use 'virtos-new-command' instead." >&2
   echo "See: https://github.com/FlossWare/VirtOS/issues/XXX" >&2
   ```

4. **Update Documentation**:
   - Add deprecation notice to command help text
   - Update README.md to show alternative
   - Create migration guide in docs/

### Step 2: Warning Period (T+1 to T+5 months)

**During This Period**:

- ✅ Feature continues to work fully
- ✅ Warning message shown on every use
- ✅ Migration guide actively maintained
- ✅ User questions answered
- ✅ Monitoring usage (if possible)

**Communication**:

- Monthly reminders in project updates
- Highlighted in release notes
- Mentioned in community channels

### Step 3: Removal (T+6 months)

**Actions**:

1. **Remove from codebase** in next **major version** (X.0.0)
2. **Update CHANGELOG.md**:

   ```markdown
   ### Removed
   - `virtos-old-command` - Deprecated in v1.5, removed in v2.0.
     Use `virtos-new-command` instead.
   ```

3. **Remove from documentation**
4. **Keep migration guide** for historical reference

## Semantic Versioning

VirtOS follows [Semantic Versioning](https://semver.org/) (MAJOR.MINOR.PATCH):

- **MAJOR** (X.0.0) - Breaking changes, removal of deprecated features
- **MINOR** (1.X.0) - New features, deprecation announcements (backward compatible)
- **PATCH** (1.0.X) - Bug fixes, no deprecations

**Deprecation Rules**:

- ✅ Deprecation warnings introduced in **MINOR** versions
- ✅ Deprecated features removed in **MAJOR** versions
- ❌ Never remove features in MINOR or PATCH versions

## Example Deprecation: `virtos-vm-create` → `virtos-create-vm`

### Announcement (v1.3.0 - 2026-01-15)

**Issue #250**: [DEPRECATION] virtos-vm-create renamed to virtos-create-vm

**CHANGELOG.md**:

```markdown
### Deprecated
- `virtos-vm-create` - Renamed to `virtos-create-vm` for consistency.
  Will be removed in v2.0 (July 2026).
```

**Warning Message**:

```bash
WARNING: 'virtos-vm-create' is deprecated and will be removed in v2.0.
Please use 'virtos-create-vm' instead. Functionality is identical.
See: https://github.com/FlossWare/VirtOS/issues/250
```

**Migration Guide** (docs/MIGRATION-VM-CREATE.md):

```markdown
# Migrating from virtos-vm-create to virtos-create-vm

## Quick Migration

Simply replace the command name:

**Before**: `virtos-vm-create --name test --cpu 2 --ram 4096`
**After**: `virtos-create-vm --name test --cpu 2 --ram 4096`

All flags and options are identical.
```

### Warning Period (v1.3.0 to v1.9.0 - Jan to Jun 2026)

- Feature works normally
- Warning shown on every use
- Both commands coexist

### Removal (v2.0.0 - 2026-07-15)

**CHANGELOG.md**:

```markdown
### Removed
- `virtos-vm-create` - Use `virtos-create-vm` instead.
  Deprecated since v1.3.0.
```

- `virtos-vm-create` script removed
- Documentation updated
- Migration guide remains available

## Types of Changes and Deprecation

### Breaking Changes (Require Deprecation)

**Command-Line Interface**:

- ✅ Removing command-line flags
- ✅ Changing flag behavior significantly
- ✅ Renaming commands
- ✅ Changing default values
- ✅ Removing commands

**API Changes**:

- ✅ Removing REST API endpoints
- ✅ Changing response formats
- ✅ Renaming fields
- ✅ Changing HTTP methods

**Configuration**:

- ✅ Removing configuration options
- ✅ Changing config file formats
- ✅ Changing default paths

### Non-Breaking Changes (No Deprecation Required)

**Additive Changes**:

- ✅ Adding new commands
- ✅ Adding new flags (optional)
- ✅ Adding new API endpoints
- ✅ Adding new fields to responses
- ✅ Improving error messages

**Internal Changes**:

- ✅ Refactoring code
- ✅ Performance improvements
- ✅ Bug fixes (that don't change behavior)

## Communication Channels

**Where Deprecations Are Announced**:

1. **CHANGELOG.md** - Primary source of truth
2. **GitHub Issues** - One issue per deprecation
3. **Release Notes** - Highlighted in release announcements
4. **Documentation** - Deprecation notices in docs
5. **Runtime Warnings** - Warning message when using deprecated feature
6. **README.md** - Major deprecations listed

**Notification Methods**:

- 📝 Update all documentation immediately
- 🔔 GitHub issue notifications
- 📢 Release announcements
- ⚠️ Runtime warning messages

## Backward Compatibility Guarantee

### v1.x Series (Current)

**Promise**: All v1.x releases are backward compatible

- ✅ No features removed in v1.x
- ✅ Only deprecation warnings added
- ✅ New features are additive
- ✅ Bug fixes don't break scripts

### v2.0 (Future Major Release)

**Breaking Changes Allowed**:

- ❌ Removal of features deprecated in v1.x
- ✅ API redesigns
- ✅ Configuration format changes

**Process**:

1. All v1.x deprecations clearly documented
2. Comprehensive v2.0 migration guide
3. At least 6 months warning
4. Automated migration tools (where possible)

## Experimental Features

Features marked as **experimental** or **research prototypes** are **exempt** from this deprecation policy:

- May be removed without warning
- May change significantly between versions
- Clearly marked in documentation
- Should not be used in production

**Identifying Experimental Features**:

- Scripts in `virtos-experimental.tcz` package
- Documentation marked with ⚠️ EXPERIMENTAL
- Help text includes "Experimental" label
- See: docs/EXPERIMENTAL.md

## Long-Term Support (LTS)

Currently, VirtOS does NOT have LTS releases. This may change post-v1.0.

**Future LTS Policy** (proposed):

- Every 3rd major version is LTS (e.g., v3.0, v6.0)
- LTS supported for 2 years
- Security updates only (no new features)
- Deprecations frozen during LTS

## FAQ

### Q: Can I still use a deprecated feature?

**A**: Yes, during the warning period (6 months). The feature works normally but shows a warning. After removal in the next major version, the feature will no longer work.

### Q: What if I depend on a deprecated feature?

**A**: Migrate to the alternative during the warning period. If no alternative exists, file a GitHub issue explaining your use case. We may reconsider the deprecation.

### Q: How do I know what's deprecated?

**A**: Check:

1. CHANGELOG.md (Deprecated section)
2. GitHub issues labeled "deprecation"
3. Runtime warning messages
4. Documentation deprecation notices

### Q: Can deprecations be reversed?

**A**: Yes, if strong user feedback shows the deprecation was a mistake. File a GitHub issue with your use case. Reversal must happen before removal (during warning period).

### Q: What if a security issue requires immediate removal?

**A**: Security takes precedence. The feature may be removed immediately with minimal warning. We'll provide a migration path and document the security issue.

### Q: Do experimental features follow this policy?

**A**: No. Experimental features can change or be removed without warning. See docs/EXPERIMENTAL.md.

## References

- **Semantic Versioning**: <https://semver.org/>
- **Keep a Changelog**: <https://keepachangelog.com/>
- **VirtOS CHANGELOG**: ../CHANGELOG.md
- **Experimental Features**: EXPERIMENTAL.md
- **Migration Guides**: /docs/migrations/

## Version History

- **1.0** (2026-05-29) - Initial deprecation policy

---

**Questions or Feedback?**

File an issue: <https://github.com/FlossWare/VirtOS/issues>
