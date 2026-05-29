# VirtOS Rollback Procedure

**Last Updated**: 2026-05-29  
**Status**: Implemented  
**Related Issue**: [#106](https://github.com/FlossWare/VirtOS/issues/106)

---

## Overview

VirtOS has an automated rollback mechanism to quickly revert to a previous version if a deployment introduces critical bugs. This document describes when and how to perform rollbacks.

**Rollback Workflow**: `.github/workflows/rollback.yml` (manual trigger)

---

## When to Rollback

### Critical Issues (Immediate Rollback)

Roll back immediately if the new version:

- ❌ Prevents VirtOS from booting
- ❌ Breaks core VM operations (create/start/stop)
- ❌ Causes data corruption
- ❌ Has severe security vulnerability
- ❌ Crashes on startup

### Major Issues (Consider Rollback)

Consider rollback if:

- ⚠️ Critical features broken (networking, storage)
- ⚠️ Multiple user reports of failures
- ⚠️ Performance degradation >50%
- ⚠️ Memory leaks or resource exhaustion

### Minor Issues (Do Not Rollback)

Fix forward instead of rolling back:

- ✅ Documentation errors
- ✅ Minor UI issues
- ✅ Non-critical feature bugs
- ✅ Cosmetic issues
- ✅ Edge case failures

---

## Rollback Process

### Step 1: Identify Target Version

Find the last known good version:

```bash
# List recent releases
gh release list --repo FlossWare/VirtOS --limit 10

# Check specific version
gh release view v0.5 --repo FlossWare/VirtOS
```

**Target Selection**:

- Use the last stable release (usually N-1)
- Avoid versions with known critical bugs
- Check release notes for issues

### Step 2: Trigger Rollback Workflow

**Via GitHub Web UI**:

1. Go to <https://github.com/FlossWare/VirtOS/actions/workflows/rollback.yml>
2. Click "Run workflow"
3. Fill in:
   - **Version**: `0.5` (without 'v' prefix)
   - **Reason**: "Critical bug: VM creation fails on Fedora 44"
4. Click "Run workflow"

**Via GitHub CLI**:

```bash
gh workflow run rollback.yml \
  --repo FlossWare/VirtOS \
  --field version=0.5 \
  --field reason="Critical bug: VM creation fails on Fedora 44"
```

### Step 3: Monitor Rollback

Watch the workflow execution:

```bash
# Via GitHub CLI
gh run watch --repo FlossWare/VirtOS

# Or view in browser
# https://github.com/FlossWare/VirtOS/actions
```

**Workflow Steps**:

1. ✅ Validates version exists
2. ✅ Checks out old version from git
3. ✅ Rebuilds packages
4. ✅ Validates package integrity
5. ✅ Creates rollback release (tagged as `vX.Y-rollback`)
6. ✅ Deploys to packagecloud.io
7. ✅ Creates notification issue

**Duration**: ~5-10 minutes

### Step 4: Verify Rollback

After rollback completes:

```bash
# Check rollback release created
gh release view v0.5-rollback --repo FlossWare/VirtOS

# Verify packages deployed
curl -s https://packagecloud.io/api/v1/repos/flossware/virtos/packages.json | jq -r '.[].filename'
```

**Verification Checklist**:

- [ ] Rollback release exists
- [ ] Packages downloadable from GitHub
- [ ] Packages available on packagecloud.io
- [ ] Notification issue created
- [ ] Release marked as prerelease

### Step 5: Communicate Rollback

The workflow automatically creates a notification issue, but also:

1. **Update Release Notes** - Add warning to broken release
2. **Notify Users** - Post to mailing list, forums, chat
3. **Document Root Cause** - Create issue for the bug
4. **Plan Fix** - Schedule fix and validation

**Example Communication**:

```markdown
## ⚠️ Rollback Notice

We have rolled back VirtOS from v0.6 to v0.5 due to a critical bug
that prevents VM creation on Fedora 44.

**Action Required**:
- If you upgraded to v0.6, downgrade to v0.5-rollback immediately
- Download from: https://github.com/FlossWare/VirtOS/releases/tag/v0.5-rollback

**Root Cause**: Missing libvirt dependency check
**Fix Status**: In progress, will be released as v0.7
**Timeline**: Fix expected within 48 hours

We apologize for the inconvenience.
```

---

## Manual Rollback (If Workflow Fails)

If the automated rollback fails, perform manual rollback:

### Manual Rollback Steps

```bash
# 1. Clone repository
git clone https://github.com/FlossWare/VirtOS.git
cd VirtOS

# 2. Checkout target version
git checkout v0.5

# 3. Build packages
cd packages
./build-all.sh

# 4. Validate packages
for pkg in output/*.tcz; do
  unsquashfs -l "$pkg" >/dev/null && echo "✓ $(basename $pkg)" || echo "✗ $(basename $pkg)"
done

# 5. Create release manually (via GitHub web UI)
# - Go to https://github.com/FlossWare/VirtOS/releases/new
# - Tag: v0.5-rollback
# - Title: VirtOS v0.5 (Rollback)
# - Upload packages from packages/output/
# - Mark as prerelease

# 6. Deploy to packagecloud.io (if credentials available)
gem install package_cloud
for pkg in output/*.tcz; do
  package_cloud push flossware/virtos "$pkg"
done
```

---

## User Instructions for Downgrading

### For VirtOS Users

If you need to downgrade after a bad release:

**Option 1: Fresh Install**

```bash
# 1. Download rollback ISO (if available)
# 2. Boot from ISO
# 3. Install normally
```

**Option 2: Package Downgrade**

```bash
# 1. Download rollback packages
wget https://github.com/FlossWare/VirtOS/releases/download/v0.5-rollback/virtos-tools.tcz
wget https://github.com/FlossWare/VirtOS/releases/download/v0.5-rollback/virtos-platform-java.tcz

# 2. Stop VirtOS services
sudo systemctl stop libvirtd
sudo systemctl stop virtos-*

# 3. Remove current packages
tce-audit builddb
tce-audit delete virtos-tools.tcz
tce-audit delete virtos-platform-java.tcz

# 4. Install rollback packages
tce-load -i virtos-tools.tcz
tce-load -i virtos-platform-java.tcz

# 5. Restart services
sudo systemctl start libvirtd
sudo systemctl start virtos-*

# 6. Verify version
virtos-setup --version
```

**Option 3: Snapshot Rollback** (if you took snapshots)

```bash
# Restore system snapshot from before upgrade
# (Implementation depends on your snapshot tool)
```

---

## Preventing Future Rollbacks

### Pre-Deployment Validation

**Smoke Tests** (already in CD pipeline):

- ✅ Package integrity checks
- ✅ Syntax validation
- ✅ Metadata verification

**Should Add**:

- [ ] Integration tests in staging environment
- [ ] Canary deployment (1% of users first)
- [ ] Automated rollback on failure detection
- [ ] User acceptance testing period

### Staging Environment

**Recommendation**: Create staging packagecloud.io repository

```yaml
# .github/workflows/cd.yml (future enhancement)
- name: Deploy to staging
  run: package_cloud push flossware/virtos-staging "$package"

- name: Run integration tests against staging
  run: |
    # Download from staging
    # Run tests
    # Promote to production only if tests pass
```

### Monitoring and Alerts

**Should Implement**:

- [ ] Error rate monitoring (libvirt failures, crashes)
- [ ] Performance monitoring (response times, resource usage)
- [ ] Automated alerts on anomalies
- [ ] Automatic rollback triggers

---

## Rollback History

### Rollback Log

| Date | From Version | To Version | Reason | Duration |
|------|--------------|------------|--------|----------|
| *(none)* | - | - | - | - |

*No rollbacks have been performed yet.*

---

## Testing Rollback Procedure

### Dry Run (Recommended)

Test rollback process without affecting production:

```bash
# 1. Fork repository
# 2. Set up test packagecloud.io repository
# 3. Run rollback workflow against fork
# 4. Verify packages built and deployed correctly
# 5. Document any issues
```

### Rollback Drill

Schedule regular rollback drills (quarterly):

1. Pick a stable old version
2. Perform full rollback
3. Verify all steps complete
4. Document time taken and issues
5. Update procedure if needed

---

## FAQ

### Q: How far back can we rollback?

**A**: Any version with a git tag. Typically rollback to N-1 (previous version), but older versions are possible if needed.

### Q: What happens to data during rollback?

**A**: Packages are rolled back, but **user data is preserved**:

- VMs, snapshots, networks remain
- Configuration files unchanged
- Only VirtOS scripts are replaced

**Exception**: If new version changed data formats, rollback may cause issues. Test thoroughly.

### Q: Can we rollback just one package?

**A**: The automated workflow rolls back all packages together. For single-package rollback, use manual process.

### Q: How long does rollback take?

**A**:

- Automated workflow: ~5-10 minutes
- Manual rollback: ~15-30 minutes
- User downgrade: ~5 minutes (if packages cached)

### Q: What if the rollback itself fails?

**A**:

1. Use manual rollback procedure
2. If that fails, keep current version and fix forward
3. Worst case: fresh install of last stable version

### Q: Do we lose commits during rollback?

**A**: No, rollback only affects releases/packages. Git history is unchanged. The broken version remains in git for investigation.

---

## See Also

- [.github/workflows/rollback.yml](../.github/workflows/rollback.yml) - Rollback workflow
- [.github/workflows/cd.yml](../.github/workflows/cd.yml) - Deployment workflow
- [API_VERSIONING.md](API_VERSIONING.md) - API versioning policy
- [TESTING_ROADMAP.md](../TESTING_ROADMAP.md) - Testing execution plan
- [GitHub Issue #106](https://github.com/FlossWare/VirtOS/issues/106) - Rollback requirement

---

**Document Version**: 1.0  
**Author**: VirtOS Team  
**License**: Same as VirtOS project (GPL-3.0)
