# VirtOS Release Process

This document describes the versioning scheme and release process for VirtOS.

## Versioning Scheme

VirtOS follows [Semantic Versioning 2.0.0](https://semver.org/):

```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]
```

**Examples:**
- `0.1.0-alpha` - Alpha release
- `0.2.0-beta.1` - First beta of 0.2.0
- `1.0.0` - First stable release
- `1.2.3` - Stable release with patches

### Version Components

- **MAJOR** - Incompatible API/interface changes
- **MINOR** - Backwards-compatible functionality additions
- **PATCH** - Backwards-compatible bug fixes
- **PRERELEASE** - alpha, beta, rc.1, rc.2, etc.
- **BUILD** - Build metadata (commit hash, build date)

### Current Version

**0.1.0-alpha** (as of May 2026)

- First alpha release
- Package building functional
- ISO building framework ready
- Management scripts complete
- Documentation comprehensive

## Release Types

### Alpha Releases (0.x.0-alpha)

**Purpose:** Early testing, proof of concept, gather feedback

**Stability:** Unstable, breaking changes expected

**When:**
- Major features completed but not fully tested
- APIs/interfaces may change
- Not recommended for production

**Example:** `0.1.0-alpha` - Initial release with working package build

### Beta Releases (0.x.0-beta.N)

**Purpose:** Feature complete, testing and stabilization

**Stability:** More stable, fewer breaking changes

**When:**
- All planned features implemented
- Focus on bug fixes and polish
- Ready for wider testing
- APIs mostly stable

**Example:** `0.2.0-beta.1` - First beta with ISO building tested

### Release Candidates (0.x.0-rc.N)

**Purpose:** Final testing before stable release

**Stability:** Stable, only critical bug fixes

**When:**
- No known critical bugs
- All tests passing
- Documentation complete
- Ready for production consideration

**Example:** `1.0.0-rc.1` - First release candidate

### Stable Releases (X.Y.Z)

**Purpose:** Production-ready releases

**Stability:** Stable, well-tested

**When:**
- All RC issues resolved
- Full test suite passing
- Documentation reviewed
- Community feedback incorporated

**Example:** `1.0.0` - First stable release

## Release Checklist

### Pre-Release Checklist

#### Code Quality
- [ ] All scripts pass syntax check (`make check`)
- [ ] Quick test passes (`make test`)
- [ ] Package builds successfully (`make packages`)
- [ ] CI/CD pipeline passes (GitHub Actions)
- [ ] No critical bugs in issue tracker
- [ ] Security review completed (if applicable)

#### Testing
- [ ] Unit tests passing (when implemented)
- [ ] Integration tests passing (when implemented)
- [ ] Manual testing completed
- [ ] Tested on target hardware (if applicable)
- [ ] Performance benchmarks run and documented
- [ ] No regressions from previous version

#### Documentation
- [ ] README.md updated with new features
- [ ] CHANGELOG.md updated
- [ ] BUILD.md reflects current build process
- [ ] TESTING.md includes new test procedures
- [ ] All new features documented
- [ ] API/interface changes documented
- [ ] Migration guide provided (for breaking changes)

#### Package/Build
- [ ] Version bumped in all necessary files
- [ ] Package metadata updated (.tcz.info files)
- [ ] Build scripts tested and working
- [ ] ISO builds successfully (when applicable)
- [ ] Checksums generated and verified

#### Legal/Licensing
- [ ] LICENSE file present and correct
- [ ] Copyright notices updated
- [ ] Third-party licenses acknowledged
- [ ] CONTRIBUTORS file updated (if applicable)

### Release Process

#### 1. Prepare Release Branch

```bash
# Create release branch
git checkout -b release/v0.2.0-alpha

# Update version in files
vim build/build.conf  # Update FW_VERSION
vim packages/virtos-tools/virtos-tools.tcz.info  # Update Version
```

#### 2. Update CHANGELOG

```bash
vim CHANGELOG.md

# Add entry:
## [0.2.0-alpha] - 2026-MM-DD

### Added
- New feature X
- New feature Y

### Changed
- Improved Z

### Fixed
- Bug #123
- Bug #456

### Deprecated
- Feature A (will be removed in 1.0.0)
```

#### 3. Update Documentation

```bash
# Update README with version-specific info
vim README.md

# Ensure build docs reflect current state
vim BUILD.md

# Update test documentation if needed
vim TESTING.md
```

#### 4. Run Full Validation

```bash
# Clean everything
make clean-all

# Validate
make validate

# Check syntax
make check

# Run tests
make test

# Build packages
make packages

# Build ISO (if ready)
# make build
```

#### 5. Create Release Commit

```bash
git add .
git commit -m "release: Version 0.2.0-alpha

- Updated version to 0.2.0-alpha
- Updated CHANGELOG.md
- Updated documentation
- All tests passing
"
```

#### 6. Tag Release

```bash
# Create annotated tag
git tag -a v0.2.0-alpha -m "Release v0.2.0-alpha

Key changes:
- Feature X
- Feature Y
- Bug fixes

See CHANGELOG.md for full details.
"

# Verify tag
git show v0.2.0-alpha
```

#### 7. Push Release

```bash
# Push release branch
git push origin release/v0.2.0-alpha

# Push tag
git push origin v0.2.0-alpha
```

#### 8. Create GitHub Release

1. Go to GitHub → Releases → "Draft a new release"
2. Select tag: `v0.2.0-alpha`
3. Release title: `VirtOS v0.2.0-alpha`
4. Description:
   ```markdown
   ## VirtOS v0.2.0-alpha

   **Release Date:** 2026-MM-DD

   ### Highlights
   - Feature X
   - Feature Y
   - Performance improvements

   ### What's New
   See [CHANGELOG.md](CHANGELOG.md#020-alpha) for full details.

   ### Downloads
   - `virtos-tools.tcz` - Management tools package (~340 KB)
   - `virtos-platform-java.tcz` - platform-java integration package (~4 KB)
   - `VirtOS-v0.2.0-alpha.iso` - Bootable ISO (~50-150 MB) [if available]

   ### Installation
   See [QUICKSTART.md](QUICKSTART.md) for installation instructions.

   ### Known Issues
   - Issue #X
   - Issue #Y

   ### Support
   - Report bugs: https://github.com/FlossWare/VirtOS/issues
   - Discussions: https://github.com/FlossWare/VirtOS/discussions
   ```

5. Upload artifacts:
   - `packages/output/virtos-tools.tcz`
   - `packages/output/virtos-tools.tcz.md5.txt`
   - `build/output/VirtOS-*.iso` (if available)
   - `build/output/VirtOS-*.iso.sha256` (if available)

6. Check "This is a pre-release" (for alpha/beta/rc)
7. Publish release

#### 9. Merge to Main

```bash
# Switch to main
git checkout main

# Merge release branch
git merge release/v0.2.0-alpha

# Push main
git push origin main

# Delete release branch (optional)
git branch -d release/v0.2.0-alpha
git push origin --delete release/v0.2.0-alpha
```

#### 10. Post-Release Tasks

- [ ] Announce release on discussions/social media
- [ ] Update project website (if exists)
- [ ] Notify packagers/distributors
- [ ] Update milestone in GitHub
- [ ] Close related issues
- [ ] Thank contributors

## Version History

### 0.1.0-alpha (May 24, 2026)

**Status:** Initial alpha release

**What Works:**
- ✅ Package building (virtos-tools.tcz)
- ✅ Build validation and testing
- ✅ 52 management scripts
- ✅ Comprehensive documentation
- ✅ CI/CD pipeline

**What's Planned:**
- 🔧 ISO building (framework ready)
- 🔧 Virtualization packages (QEMU, libvirt, etc.)
- 🔧 Custom kernel builds

**Artifacts:**
- virtos-tools.tcz (332KB)

### Future Releases

**0.2.0-alpha** (Target: June 2026)
- ISO building tested and functional
- QEMU package available
- Basic VM creation working

**0.3.0-beta** (Target: Q3 2026)
- All core packages (QEMU, libvirt, Docker, LXC)
- Complete VM/container workflows
- Clustering tested

**1.0.0** (Target: Q4 2026)
- Feature complete
- Production ready
- Full documentation
- Comprehensive testing

## Hotfix Process

For critical bugs in released versions:

```bash
# Create hotfix branch from tag
git checkout -b hotfix/v0.1.1-alpha v0.1.0-alpha

# Fix bug
vim path/to/buggy/file
git commit -m "fix: Critical bug in X"

# Update version (PATCH bump)
vim build/build.conf  # 0.1.0-alpha → 0.1.1-alpha

# Update CHANGELOG
vim CHANGELOG.md

# Tag and release
git tag -a v0.1.1-alpha -m "Hotfix release v0.1.1-alpha"
git push origin v0.1.1-alpha

# Merge back to main
git checkout main
git merge hotfix/v0.1.1-alpha
git push origin main
```

## Release Automation

### Future: Automated Releases

Consider implementing:
- GitHub Actions for release builds
- Automated CHANGELOG generation
- Automated artifact uploads
- Automated version bumping

Example workflow:
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build packages
        run: make packages
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            packages/output/virtos-tools.tcz
            packages/output/virtos-tools.tcz.md5.txt
```

## Support Policy

**Alpha/Beta Releases:**
- No long-term support
- Upgrade to latest version

**Stable Releases:**
- Critical security fixes: 6 months
- Bug fixes: 3 months
- Feature updates: Latest version only

## Communication

**Release Announcements:**
- GitHub Releases page
- GitHub Discussions
- Project README.md
- Social media (if applicable)

**Release Notes Format:**
- Highlight major changes
- List all changes (from CHANGELOG)
- Acknowledge contributors
- Link to documentation
- List known issues

## Questions?

- Check [CONTRIBUTING.md](CONTRIBUTING.md) for development process
- See [BUILD.md](BUILD.md) for build instructions
- Ask in [GitHub Discussions](https://github.com/FlossWare/VirtOS/discussions)

---

**Current Release:** 0.1.0-alpha  
**Next Release:** 0.2.0-alpha (planned)
