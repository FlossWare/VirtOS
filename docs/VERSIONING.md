# VirtOS Versioning Scheme

## Format: X.Y (Semantic Versioning)

VirtOS uses **X.Y semantic versioning** where:
- **X** (Major) = Major version, breaking changes
- **Y** (Minor) = Minor version, features and fixes

## Current Version

**v0.57** (as of 2026-05-26)

- **Major**: 0 (pre-1.0 alpha/beta phase)
- **Minor**: 57 (auto-incremented by CD workflow)

## Version Management

### Single Source of Truth

The `VERSION` file at repository root contains the canonical version:

```
$ cat VERSION
0.57
```

All package metadata files sync from this single source.

### Automatic Versioning

**CD Workflow** (`ci/rev-version.sh`):
1. Reads current version from `VERSION` file
2. Parses as X.Y format: `MAJOR.MINOR`
3. Increments minor version: `MINOR + 1`
4. Updates `VERSION` and all `packages/*/virtos-*.tcz.info` files
5. Creates git tag `vX.Y`
6. Pushes changes and tag to repository

### Example Version Progression

```
0.50 → 0.51 → 0.52 → 0.53 → 0.54 → 0.55 → 0.56 → 0.57 ...
```

Minor version increments on every merged PR to `main` branch.

## Version Synchronization

All version references stay synchronized:

| File | Version Reference |
|------|-------------------|
| `VERSION` | 0.57 |
| `packages/virtos-tools/virtos-tools.tcz.info` | Version: 0.57 |
| `packages/virtos-jplatform/virtos-jplatform.tcz.info` | Version: 0.57 |
| Git tag | v0.57 |
| GitHub Release | VirtOS v0.57 |

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
# From packages/virtos-jplatform/build.sh
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
virtos-create-vm version 0.57

$ virtos-tui --version
virtos-tui version 0.57
```

### Package Metadata

TCZ package info files show version:

```bash
$ cat /tmp/tcloop/virtos-tools/virtos-tools.tcz.info
Title:          virtos-tools.tcz
Version:        0.57
...
```

### Git Tags

All releases tagged as `vX.Y`:

```bash
$ git tag | tail -5
v0.53
v0.54
v0.55
v0.56
v0.57
```

## Historical Versions

| Version | Date | Milestone |
|---------|------|-----------|
| 0.1 | 2026-05-25 | Initial alpha release |
| 0.22-0.29 | 2026-05-26 | VERSION standardization |
| 0.30-0.35 | 2026-05-26 | Test expansion begins |
| 0.36-0.40 | 2026-05-26 | Advanced script tests |
| 0.41-0.42 | 2026-05-26 | 100% test coverage achieved |
| 0.44-0.57 | 2026-05-26 | CI/CD fixes and enhancements |

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
- **Semantic Versioning**: https://semver.org/
