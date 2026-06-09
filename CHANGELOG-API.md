# VirtOS API Changelog

This file tracks **command-line interface changes** to VirtOS management scripts. See [docs/API_VERSIONING.md](docs/API_VERSIONING.md) for versioning policy.

**Format**: SCRIPT_NAME → API Version → Changes → Migration Guide (if breaking)

---

## Current API Versions

All scripts are currently at **API 1.0** (initial stable release as of 2026-05-29).

---

## virtos-audit

### API 1.0 (2026-05-29)

**Initial Release**

**Interface**:

```bash
virtos-audit recent [N]              # Show last N events (default: 10)
virtos-audit stats                   # Show statistics
virtos-audit query <type> <value>    # Query by user/action/resource/result/date
virtos-audit watch                   # Real-time monitoring
virtos-audit export [file]           # Export audit log
virtos-audit rotate                  # Manual log rotation
```

**Stability**: ✅ Stable

---

## virtos-setup

### API 1.0 (2026-05-01)

**Initial Release**

**Interface**:

```bash
virtos-setup                         # Interactive setup wizard
virtos-setup --auto                  # Non-interactive setup
virtos-setup --network <type>        # Network configuration
virtos-setup --storage <path>        # Storage configuration
```

**Stability**: ✅ Stable (pending runtime validation)

---

## virtos-create-vm

### API 1.0 (2026-05-01)

**Initial Release**

**Interface**:

```bash
virtos-create-vm --name <name> --cpu <count> --memory <size> --disk <size>
virtos-create-vm --template <name>   # Create from template
virtos-create-vm --no-start          # Don't start after creation
```

**Stability**: ✅ Stable (pending runtime validation)

---

## virtos-migrate

### API 1.0 (2026-05-01)

**Initial Release**

**Interface**:

```bash
virtos-migrate --vm <name> --dest <uri>
virtos-migrate --live                # Live migration
virtos-migrate --persistent          # Make migration persistent
```

**Stability**: ✅ Stable (pending runtime validation)

---

## virtos-snapshot

### API 1.0 (2026-05-01)

**Initial Release**

**Interface**:

```bash
virtos-snapshot create <vm> <name> [description]
virtos-snapshot list <vm>
virtos-snapshot delete <vm> <name>
virtos-snapshot restore <vm> <name>
```

**Stability**: ✅ Stable (pending runtime validation)

---

## virtos-network

### API 1.0 (2026-05-01)

**Initial Release**

**Interface**:

```bash
virtos-network list
virtos-network create --name <name> --type <type> --subnet <cidr>
virtos-network start <name>
virtos-network stop <name>
virtos-network delete <name>
```

**Stability**: ✅ Stable (pending runtime validation)

---

## virtos-storage

### API 1.0 (2026-05-01)

**Initial Release**

**Interface**:

```bash
virtos-storage list-pools
virtos-storage create-pool --name <name> --type <type> --path <path>
virtos-storage create-volume --pool <pool> --name <name> --size <size>
virtos-storage list-volumes <pool>
virtos-storage delete-volume <pool> <volume>
virtos-storage delete-pool <pool>
```

**Stability**: ✅ Stable (pending runtime validation)

---

## virtos-backup

### API 1.0 (2026-05-01)

**Initial Release**

**Interface**:

```bash
virtos-backup backup <vm> <backup-file>
virtos-backup restore <backup-file>
virtos-backup list
```

**Stability**: ✅ Stable (pending runtime validation)

---

## virtos-monitor

### API 1.0 (2026-05-01)

**Initial Release**

**Interface**:

```bash
virtos-monitor stats <vm>
virtos-monitor system
virtos-monitor watch <vm> --interval <seconds>
```

**Stability**: ✅ Stable (pending runtime validation)

---

## virtos-cluster

### API 1.0 (2026-05-01)

**Initial Release**

**Interface**:

```bash
virtos-cluster discover
virtos-cluster join <cluster-name>
virtos-cluster list
virtos-cluster status
```

**Stability**: ✅ Stable (pending runtime validation)

---

## virtos-tui

### API 1.0 (2026-05-01)

**Initial Release**

**Interface**:

```bash
virtos-tui                           # Launch interactive TUI
```

**Stability**: ✅ Stable (pending runtime validation)

**Note**: TUI is interactive, API version mainly tracks availability of menu options

---

## All Other Scripts

### API 1.0 (2026-05-01)

**Initial Release**

All remaining VirtOS management scripts (virtos-template, virtos-gpu, virtos-usb, virtos-ha, virtos-dr, virtos-api, virtos-automation, virtos-devops, virtos-security, virtos-security-advanced, virtos-cloud-init, virtos-analytics, virtos-observability, virtos-telemetry, virtos-quota, virtos-billing, virtos-datacenter, virtos-web, etc.) are at API 1.0.

**Stability**:

- ✅ Stable: 29 scripts with working backends
- 🟡 Partial: 12 scripts needing backend integration
- 📦 Archived: 12 scripts (experimental, no API stability guarantees)

See [CLAUDE.md](CLAUDE.md) for script categorization details.

---

## Future Changes

### Planned for API 1.1

**No breaking changes planned**. Potential additions:

- Add `--format json` to output commands (virtos-monitor, virtos-cluster)
- Add `--dry-run` to destructive operations
- Add `--verbose` to increase output detail
- Add `--quiet` to suppress non-error output

All additions will be backward compatible.

### Planned for API 2.0 (Not Before 2027-01-01)

**Potential breaking changes** (under consideration):

- Change default output format to JSON (with `--format text` fallback)
- Standardize argument naming across all scripts
- Consolidate similar flags (e.g., `--vm` vs `--name`)
- Remove deprecated features from API 1.x

**Commitment**: At least 6 months notice before API 2.0 release.

---

## Migration Guides

### API 1.0 → API 1.1 (Future)

*No migration needed* - API 1.1 will be fully backward compatible with API 1.0.

### API 1.x → API 2.0 (Future)

Migration guide will be published at least 6 months before API 2.0 release.

---

## Deprecation Notices

**Current**: No deprecations.

**How to Handle Deprecations**:

1. Monitor stderr for deprecation warnings
2. Update scripts/automation before removal
3. Test in non-production environment first

---

## See Also

- [docs/API_VERSIONING.md](docs/API_VERSIONING.md) - Versioning policy
- [CHANGELOG.md](CHANGELOG.md) - VirtOS release changelog
- [docs/EXPERIMENTAL_FEATURES.md](docs/EXPERIMENTAL_FEATURES.md) - Experimental scripts
- [GitHub Issue #105](https://github.com/FlossWare/VirtOS/issues/105) - API versioning requirement

---

**Last Updated**: 2026-05-29  
**Maintained By**: VirtOS Team
