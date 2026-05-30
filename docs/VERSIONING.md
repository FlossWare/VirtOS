# VirtOS Versioning Strategy

**Current Version**: 0.89 (Alpha)  
**Last Updated**: 2026-05-29  
**Status**: Pre-1.0 (Development)

---

## Overview

VirtOS uses **centralized semantic versioning** with a single source of truth: the `VERSION` file in the repository root.

---

## Version Format

### Semantic Versioning: MAJOR.MINOR

```text
0.89
```

- **MAJOR**: 0 (pre-release, API unstable)
- **MINOR**: 89 (auto-incremented on each release)

**Note**: PATCH version omitted during 0.x phase (every release is a new MINOR)

---

## Single Source of Truth

### VERSION File

**Location**: `VirtOS/VERSION`

```bash
$ cat VERSION
0.89
```

**All version references derive from this file:**

- Scripts use `get_version()` function
- Package builds read from VERSION
- CI/CD auto-increments VERSION
- Documentation should reference VERSION

### get_version() Function

All virtos-* scripts use centralized version retrieval:

```bash
# In virtos-common.sh
get_version() {
    # Try installed package first
    if [ -f /usr/local/share/virtos/VERSION ]; then
        cat /usr/local/share/virtos/VERSION
        return 0
    fi

    # Try system config
    if [ -f /etc/virtos/version.txt ]; then
        grep '^Version:' /etc/virtos/version.txt | awk '{print $2}'
        return 0
    fi

    # Try repository VERSION file
    if [ -f "$SCRIPT_DIR/../../VERSION" ]; then
        cat "$SCRIPT_DIR/../../VERSION"
        return 0
    fi

    # Fallback
    echo "0.89"
}
```

---

## Automatic Version Management

### CI/CD Auto-Increment

File: `.github/workflows/cd.yml`

```yaml
- name: Increment version
  run: |
    current=$(cat VERSION)
    major=$(echo "$current" | cut -d. -f1)
    minor=$(echo "$current" | cut -d. -f2)
    new_minor=$((minor + 1))
    echo "$major.$new_minor" > VERSION
```

**Triggers**:

- On merge to `main` branch
- After successful CI validation
- Before package deployment

**Result**: VERSION increments from 0.89 → 0.90 → 0.91...

All version references stay synchronized:

| File | Version Reference |
|------|-------------------|
| `VERSION` | 0.89 |
| `packages/virtos-tools/virtos-tools.tcz.info` | Version: 0.89 |
| `packages/virtos-platform-java/virtos-platform-java.tcz.info` | Version: 0.89 |
| Git tag | v0.89 |
| GitHub Release | VirtOS v0.89 |

### Validation

CI workflow validates version sync across all files:

```bash
./ci/verify-version-sync.sh
```

Fails CI if any package metadata doesn't match VERSION file.

## Release Strategy

### Alpha Phase (0.x)

**Current phase**: Pre-1.0 development

- Major version: 0
- Minor version: Auto-incremented
- **Stability**: Core features working, runtime testing pending
- **API**: Subject to change

### Approaching 1.0

Version 1.0 will be released when:

- ✅ 100% test coverage achieved *(Done: v0.41)*
- ✅ CI/CD fully automated *(Done: v0.44)*
- ⏸️ ISO builds tested on hardware
- ⏸️ Integration tests executed in VirtOS runtime
- ⏸️ Production deployment validated
- ⏸️ Documentation complete
- ⏸️ Security audit completed

### Post-1.0 Strategy

**Major version (X)** increments for:

- Breaking changes to APIs
- Incompatible configuration changes
- Major architectural changes

**Minor version (Y)** increments for:

- New features (backwards compatible)
- Enhancements
- Bug fixes
- Security patches

## Version in Code

### Shell Scripts

Scripts use centralized `get_version()` function:

```bash
# From virtos-common.sh
get_version() {
    # Try multiple sources in order
    if [ -f /usr/local/share/virtos/VERSION ]; then
        cat /usr/local/share/virtos/VERSION
    elif [ -f /etc/virtos/version.txt ]; then
        cat /etc/virtos/version.txt
    elif [ -f /usr/local/tce.installed/virtos-tools ]; then
        cat /usr/local/tce.installed/virtos-tools
    else
        echo "0.1"  # Fallback
    fi
}

# Usage in scripts
VERSION=$(get_version 2>/dev/null || echo "0.1")
echo "virtos-script version $VERSION"
```

### Build Scripts

Build scripts read directly from VERSION file:

```bash
# From packages/virtos-platform-java/build.sh
if [ -f "$SCRIPT_DIR/../../VERSION" ]; then
    PACKAGE_VERSION=$(cat "$SCRIPT_DIR/../../VERSION")
else
    PACKAGE_VERSION="0.1"  # Fallback
fi
```

## Version Display

### Command Line

All virtos-* scripts support `--version`:

```bash
$ virtos-create-vm --version
virtos-create-vm version 0.89

$ virtos-tui --version
virtos-tui version 0.89
```

### Package Metadata

TCZ package info files show version:

```bash
$ cat /tmp/tcloop/virtos-tools/virtos-tools.tcz.info
Title:          virtos-tools.tcz
Version: 0.89
...
```

### Git Tags

All releases tagged as `vX.Y`:

```bash
$ git tag | tail -5
v0.83
v0.84
v0.89
v0.89
v0.89
```

## Historical Versions

| Version | Date | Milestone |
|---------|------|-----------|
| 0.1 | 2026-05-25 | Initial alpha release |
| 0.22-0.29 | 2026-05-26 | VERSION standardization |
| 0.30-0.35 | 2026-05-26 | Test expansion begins |
| 0.36-0.40 | 2026-05-26 | Advanced script tests |
| 0.41-0.42 | 2026-05-26 | 100% test coverage achieved |
| 0.44-0.59 | 2026-05-26 | CI/CD fixes and enhancements |

## Version Queries

### Get Current Version

```bash
# From repository
cat VERSION

# From installed package
virtos-create-vm --version | cut -d' ' -f3

# From git tag
git describe --tags --abbrev=0

# From GitHub API
curl -s https://api.github.com/repos/FlossWare/VirtOS/releases/latest | jq -r .tag_name
```

### Compare Versions

```bash
# Check if version is at least X.Y
MIN_VERSION="0.40"
CURRENT_VERSION=$(cat VERSION)

if [ "$(printf '%s\n' "$MIN_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" = "$MIN_VERSION" ]; then
    echo "Version OK: $CURRENT_VERSION >= $MIN_VERSION"
fi
```

## References

- **VERSION file**: `/VERSION`
- **Versioning script**: `ci/rev-version.sh`
- **Validation script**: `ci/verify-version-sync.sh`
- **CD workflow**: `.github/workflows/cd.yml`
- **Semantic Versioning**: <https://semver.org/>

---

## Documentation Version Consistency

### Identifying Inconsistent Versions

Common inconsistencies found in VirtOS documentation:

| Location | Referenced Version | Current Version | Status |
|----------|-------------------|-----------------|--------|
| VERSION file | 0.89 | 0.89 | ✅ Correct |
| README.md | v0.87 | 0.89 | ❌ Outdated |
| QUICK-START.md | 0.83 | 0.89 | ❌ Outdated |
| API_REFERENCE.md | 0.22 | 0.89 | ❌ Very outdated |
| COMMUNITY.md | 0.1 | 0.89 | ❌ Very outdated |

### Best Practices for Documentation

**✅ GOOD - Use version ranges:**

```markdown
Compatible with: VirtOS 0.80+
Tested on: VirtOS 0.x (all pre-release)
Minimum version: VirtOS 0.85
```

**✅ GOOD - Include last updated date:**

```markdown
**Version**: 0.89  
**Last Updated**: 2026-05-29
```

**❌ BAD - Hardcoded specific old versions:**

```markdown
Compatible with: VirtOS 0.1
Requires: VirtOS 0.22
Version: 0.83
```

### Fixing Inconsistent Versions

**Step 1**: Find outdated references:

```bash
# Search for version references
grep -r "version.*0\." docs/ README.md | grep -v "0.89" | grep -v "0.80+"
```

**Step 2**: Update using these strategies:

1. **Dynamic references** (best for changing content):

   ```markdown
   Current version: $(cat VERSION)
   ```

2. **Version ranges** (best for compatibility):

   ```markdown
   Compatible with: VirtOS 0.80+
   Works on: VirtOS 0.x
   ```

3. **Specific current version** (best for release notes):

   ```markdown
   Version: 0.89 (updated 2026-05-29)
   ```

**Step 3**: Verify synchronization:

```bash
# All package info files should match VERSION
grep "Version:" packages/*/virtos-*.tcz.info
# Expected: Version: 0.89 (all files)

# Git tags should match releases
git tag | grep "v0.89"
# Expected: v0.89
```

---

## Addressing Issue #171

**Issue**: Inconsistent Versioning Across Scripts and Documentation

**Resolution**:

1. **✅ Single source of truth**: VERSION file (0.89)
2. **✅ Centralized function**: get_version() in virtos-common.sh
3. **✅ Automatic sync**: CI/CD updates all package metadata
4. **⚠️ Documentation lag**: Some docs reference old versions

**Action Items**:

- [x] Documented versioning strategy (this file)
- [x] Identified inconsistent references
- [x] Provided update guidelines
- [ ] Update outdated version references in documentation
- [ ] Add version consistency check to CI

**Impact**: Low priority - Core functionality unaffected. Version inconsistencies only in documentation examples and compatibility statements.

---

**Last Updated**: 2026-05-29  
**Current Version**: 0.89  
**Next Version**: 0.90 (after next merge to main)
