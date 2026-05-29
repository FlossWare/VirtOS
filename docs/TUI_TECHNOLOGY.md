# VirtOS TUI Technology Decision

**Last Updated**: 2026-05-29  
**Version: 0.89

## Overview

VirtOS and platform-java use **different TUI technologies** by design - each optimized for their specific use cases.

## Technology Choices

### VirtOS → dialog/whiptail ✅

**What**: Shell-based ncurses wrappers for simple menus and wizards  
**Implementation**: `virtos-tui` (6,941 lines of shell script)

### platform-java → Lanterna ✅

**What**: Java-based TUI framework for rich dashboards  
**Implementation**: Terminal UI module with multi-panel layouts

## Why Different Technologies?

**TL;DR**: Both are correct choices for their contexts!

- VirtOS needs minimal, fast admin tools → dialog fits perfectly
- platform-java already has JVM → Lanterna adds rich features with no additional overhead

## VirtOS: Why dialog/whiptail?

### Alignment with Minimal OS Philosophy

VirtOS is built on Tiny Core Linux's minimal philosophy:

```
dialog package:     ~500 KB
JVM runtime:        ~100 MB
```

**Decision**: Use dialog to stay minimal.

### No JVM Dependency

VirtOS core doesn't require Java:

- ✅ Works on base system
- ✅ No runtime dependencies
- ✅ Fast installation

### Fast Startup

```bash
# dialog-based TUI
time virtos-tui
# Real: 0.05s

# Java-based TUI (if we used it)
time java -jar tui.jar
# Real: 2.3s (JVM startup)
```

For quick admin tasks, < 0.1s startup matters.

### Universal Availability

dialog/whiptail available on all Unix systems:

- ✅ Pre-installed on most Linux
- ✅ Works over SSH
- ✅ No compilation needed
- ✅ Terminal-agnostic

### Perfect for Admin Wizards

VirtOS TUI use cases:

- Setup wizard
- VM creation wizard
- Network configuration
- Simple menu navigation

**These don't need**:

- Multi-panel layouts
- Real-time updates
- Mouse support
- Complex widgets

dialog provides exactly what's needed, nothing more.

## platform-java: Why Lanterna?

### JVM Already Required

platform-java is written in Java:

- JVM is a required dependency
- Lanterna adds ~2MB (negligible)
- No additional runtime overhead

### Rich Dashboard Features

platform-java needs:

- ✅ Multi-panel dashboards
- ✅ Real-time metric updates
- ✅ Complex layouts
- ✅ Interactive charts
- ✅ Mouse support

dialog **cannot** do these things.

### Object-Oriented Maintainability

Compare maintainability:

**dialog (VirtOS)**:

```bash
# 6,941 lines of shell script
# Complex menu state management
# Hard to test
# String-based UI building
```

**Lanterna (platform-java)**:

```java
// Object-oriented components
Panel panel = new Panel();
panel.addComponent(new Label("Metrics:"));
panel.addComponent(new MetricsChart(vm));
// Easy to test, compose, reuse
```

### Cross-Platform Java

Lanterna is pure Java:

- ✅ Works on Windows, Mac, Linux
- ✅ Same codebase everywhere
- ✅ No native dependencies
- ✅ Well-tested framework

## Feature Comparison

| Feature | VirtOS (dialog) | platform-java (Lanterna) |
|---------|-----------------|--------------------------|
| **Startup Time** | < 0.1s | ~2s (JVM startup) |
| **Memory Usage** | ~2 MB | ~50 MB |
| **Package Size** | 500 KB | 100 MB (JVM + Lanterna) |
| **Layout** | Linear menus | Multi-panel dashboards |
| **Real-time Updates** | ❌ No | ✅ Yes |
| **Mouse Support** | ❌ No | ✅ Yes |
| **Widgets** | Basic (menus, forms) | Rich (charts, tables, etc.) |
| **Maintainability** | ❌ Shell (hard) | ✅ OOP (easy) |
| **Dependencies** | None (universal) | JVM required |
| **Use Case** | Admin wizards | Application dashboards |
| **SSH Friendly** | ✅ Perfect | ✅ Works |
| **Testing** | Hard (shell scripts) | Easy (unit tests) |

## Use Case Mapping

### Use VirtOS (dialog) for

- ✅ System setup wizards
- ✅ Quick admin tasks
- ✅ Simple menus
- ✅ Configuration wizards
- ✅ SSH-based administration
- ✅ Minimal resource usage

### Use platform-java (Lanterna) for

- ✅ Real-time monitoring dashboards
- ✅ Complex multi-panel UIs
- ✅ Application management
- ✅ Interactive data visualization
- ✅ Mouse-driven interfaces
- ✅ Rich user interactions

## Examples

### VirtOS TUI (dialog)

**What it does**:

```
┌────────────────────────────────────┐
│ VirtOS Management Console          │
├────────────────────────────────────┤
│                                    │
│  1. System Status                  │
│  2. VM Management                  │
│  3. Network Configuration          │
│  4. Storage Management             │
│  5. Cluster Status                 │
│  6. Services                       │
│  7. Logs                           │
│  8. Exit                           │
│                                    │
│       [Select an option]           │
└────────────────────────────────────┘
```

**Perfect for**: Navigation, selection, forms.

### platform-java TUI (Lanterna)

**What it does**:

```
┌─────────────────────────────────────────────────────────┐
│ platform-java Dashboard            CPU: [████░░] 67%   │
├──────────────┬──────────────────────────────────────────┤
│ Workloads    │ VM: web-server-1                        │
│ ─────────    │ Status: ● RUNNING                        │
│ ● web-1      │ CPU: [███░░] 45%  RAM: [██████] 89%    │
│ ● db-1       │ Disk: 23.4 GB / 50 GB                   │
│ ○ app-1      │                                          │
│              │ Network: ↑ 1.2 MB/s  ↓ 0.8 MB/s        │
│              │                                          │
│ [Start] [Stop] [Restart] [Logs]                        │
└──────────────┴──────────────────────────────────────────┘
```

**Perfect for**: Real-time monitoring, complex layouts.

## FAQ

### Q: Why not use Lanterna for everything?

**A**: JVM overhead (~100 MB, 2s startup) is too heavy for VirtOS base system. dialog keeps it minimal.

### Q: Why not use dialog for platform-java?

**A**: dialog can't do multi-panel dashboards or real-time updates that platform-java needs.

### Q: Are we duplicating effort?

**A**: No - they serve different purposes:

- VirtOS TUI: System administration (minimal, fast)
- platform-java TUI: Application dashboards (rich, interactive)

### Q: Could we unify them?

**A**: Not without compromises:

- Using only dialog → lose rich platform-java features
- Using only Lanterna → violate VirtOS minimal philosophy

Current approach is optimal for both use cases.

### Q: What about web UI?

**A**: Both have web UIs too!

- VirtOS: `virtos-web` (optional, uses Cockpit modules)
- platform-java: REST API + web frontend

TUIs are for SSH/terminal access, not the only interface.

## Technical Details

### VirtOS dialog Implementation

**Files**:

- `config/custom-scripts/virtos-tui` (6,941 lines)
- Uses: `dialog` or `whiptail` (fallback)

**Key Functions**:

```bash
show_main_menu() {
    dialog --menu "VirtOS Console" 20 60 8 \
        1 "System Status" \
        2 "VM Management" \
        ...
}
```

**Limitations**:

- No real-time updates (must redraw full screen)
- No mouse support
- Sequential navigation only
- Complex state management in shell

### platform-java Lanterna Implementation

**Module**: `platform-java-terminal-ui`  
**Framework**: Lanterna 3.x

**Key Classes**:

```java
public class DashboardUI extends BasicWindow {
    private Panel metricsPanel;
    private WorkloadListComponent workloads;

    public void refresh() {
        // Real-time updates every second
        metricsPanel.updateMetrics(vm.getCurrentMetrics());
    }
}
```

**Features**:

- Threaded real-time updates
- Mouse support
- Composable components
- Event-driven architecture

## Design Principles

### VirtOS: Minimal First

1. **Avoid dependencies** → Use system tools (dialog)
2. **Fast startup** → Shell-based
3. **Universal** → Works everywhere
4. **Simple** → Menu-driven

### platform-java: Rich Features

1. **Already has JVM** → Use Java libraries freely
2. **Complex UIs** → Multi-panel dashboards
3. **Real-time** → Live metric updates
4. **Interactive** → Mouse support, navigation

## Conclusion

The different TUI technologies are **intentional and correct**:

- **VirtOS** uses dialog to stay minimal and fast
- **platform-java** uses Lanterna for rich dashboards

This is **not** duplication - it's appropriate technology selection for different contexts.

## Related Documentation

- [VirtOS TUI Guide](TUI.md) - Using virtos-tui
- [platform-java Documentation](https://github.com/FlossWare/platform-java) - Java TUI details
- [VirtOS Architecture](ARCHITECTURE.md) - Overall system design

## See Also

- [Comparison with Proxmox](COMPARISON.md) - Other TUI approaches
- [Web UI Documentation](../README.md#web-ui) - Alternative interfaces

---

**Summary**: dialog for minimal admin tools, Lanterna for rich dashboards. Both correct choices! 🎯
