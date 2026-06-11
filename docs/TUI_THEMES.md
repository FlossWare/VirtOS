# VirtOS TUI Themes

Professional theming support for VirtOS Text User Interface using [FlossWare curses-themes](https://github.com/FlossWare/curses-themes).

## Overview

VirtOS TUI now includes comprehensive theme support via the FlossWare curses-themes library, offering:

- **8+ Professional Themes**: From modern dark mode to retro computer aesthetics
- **Runtime Theme Switching**: Change themes on-the-fly without restarting
- **Semantic Colors**: Consistent color usage (success=green, error=red, etc.)
- **Terminal-Aware**: Auto-detects terminal capabilities with graceful fallbacks
- **Zero Configuration**: Works out-of-the-box with sensible defaults

## Quick Start

```bash
# Launch TUI with default theme
virtos-tui

# Launch with specific theme
virtos-tui --theme dark

# Change theme from within TUI
# Press 't' from main menu
```

## Theme Gallery

### Modern Themes

#### Default Theme

**Style**: Classic terminal aesthetic  
**Era**: Timeless  
**Best For**: Universal compatibility, traditional Unix feel

```bash
virtos-tui --theme default
```

- Black background, white foreground
- High contrast for readability
- Works on all terminal types

#### Dark Theme

**Style**: Professional dark mode  
**Era**: Modern (2020s)  
**Best For**: Low-light coding, reduced eye strain

```bash
virtos-tui --theme dark
```

- Dark blue/gray background
- Soft blue and green accents
- Optimized for extended use

#### Light Theme

**Style**: High contrast light mode  
**Era**: Modern (2020s)  
**Best For**: Bright environments, daytime use

```bash
virtos-tui --theme light
```

- White/light gray background
- Dark blue and black text
- Maximum contrast for outdoor/bright conditions

### Retro Computer Themes

#### TI-99/4A Theme

**Style**: Texas Instruments home computer  
**Era**: 1981-1984  
**Best For**: Nostalgia, retro gaming UIs

```bash
virtos-tui --theme ti994a
```

- Cyan background
- Blue and white text
- Authentic TI-99/4A color palette

#### TRS-80 Theme

**Style**: Tandy/Radio Shack monochrome  
**Era**: 1980-1983  
**Best For**: Authentic retro feel, minimalism

```bash
virtos-tui --theme trs80
```

- Black background
- White text only
- Classic monochrome display

### Business Software Themes

#### DOS Theme

**Style**: Classic MS-DOS interface  
**Era**: 1981-1995  
**Best For**: System utilities, DOS nostalgia

```bash
virtos-tui --theme dos
```

- Black background
- White and yellow text
- Iconic DOS color scheme

#### dBASE III Theme

**Style**: Database software interface  
**Era**: 1984-1985  
**Best For**: Database applications, business software

```bash
virtos-tui --theme dbase3
```

- Black background
- Cyan menu bars
- Classic database UI

#### dBASE IV Theme

**Style**: Windowed database interface  
**Era**: 1988-1993  
**Best For**: Modern database UIs, professional applications

```bash
virtos-tui --theme dbase4
```

- Blue background
- White windows and borders
- Windowed UI aesthetic

### 3D Effect Themes (If Available)

Some themes include 3D effects with shadows and depth:

- **borland3d** - Turbo Vision 3D look (1990-1997)
- **dbase4-3d** - dBASE IV with 3D windows

## Theme Comparison

| Theme | Colors | Style | CPU Impact | Terminal Compat |
|-------|--------|-------|------------|-----------------|
| default | B/W | Minimal | Low | 100% |
| dark | 256-color | Modern | Low | 95% |
| light | 256-color | Modern | Low | 95% |
| ti994a | 8-color | Retro | Low | 90% |
| trs80 | Mono | Retro | Minimal | 100% |
| dos | 16-color | Classic | Low | 98% |
| dbase3 | 8-color | Business | Low | 90% |
| dbase4 | 16-color | Business | Low | 95% |

## Configuration

### Theme Persistence

Your theme choice is automatically saved to `~/.config/virtos/theme.conf`:

```bash
THEME="dark"
```

### Setting Default Theme

Edit `~/.config/virtos/theme.conf`:

```bash
# Use dark theme by default
THEME="dark"
```

Or use command-line:

```bash
echo 'THEME="dark"' > ~/.config/virtos/theme.conf
```

### System-Wide Default

For system-wide theme configuration, edit `/etc/virtos/theme.conf`:

```bash
# System-wide default theme
THEME="default"
```

User preferences in `~/.config/virtos/theme.conf` override system defaults.

## Changing Themes

### From Within TUI

1. Launch `virtos-tui`
2. Press `t` from the main menu
3. Select a theme from the list
4. Theme changes immediately
5. Choice is saved for next session

### Command-Line

```bash
# Launch with specific theme
virtos-tui --theme dark

# List available themes
virtos-tui --list-themes
```

### Programmatically

```bash
# Set theme via config file
echo 'THEME="ti994a"' > ~/.config/virtos/theme.conf

# Then launch TUI
virtos-tui
```

## Theme Features

### Semantic Colors

All themes provide consistent semantic color meanings:

| Color Type | Meaning | Example Usage |
|------------|---------|---------------|
| **success** | Positive status | Running VMs, successful operations |
| **error** | Errors and failures | Stopped VMs, failed commands |
| **warning** | Warnings and alerts | Resource warnings, deprecated features |
| **info** | Informational | Help text, status messages |
| **primary** | Primary actions | Selected items, active elements |
| **accent** | Highlights | Menu keys, shortcuts |

### Themed Components

#### Title Bars

Use `primary` color for application titles and headers

#### Menu Boxes

Themed borders and backgrounds with `draw_box()` method

#### Status Indicators

Color-coded status using semantic colors:

- Running VMs: green (success)
- Stopped VMs: yellow (warning)
- Failed operations: red (error)

#### Help Text

Footer and help messages use `info` color

## Creating Custom Themes

You can create VirtOS-specific themes by extending the FlossWare curses-themes library.

### Example: Custom VirtOS Theme

Create `~/.config/virtos/custom_theme.py`:

```python
from curses_themes import Theme, ThemeManager

class VirtOSCustomTheme(Theme):
    """Custom VirtOS theme"""

    def __init__(self):
        super().__init__(
            name="VirtOS Custom",
            description="My custom VirtOS theme",
            author="Your Name"
        )

    def get_color_map(self):
        return {
            'background': (15, 15, 35),      # Dark blue
            'foreground': (200, 200, 200),   # Light gray
            'primary': (0, 200, 255),        # Bright cyan
            'success': (0, 255, 0),          # Green
            'error': (255, 50, 50),          # Red
            'warning': (255, 200, 0),        # Yellow
            'info': (150, 150, 255),         # Soft blue
            'accent': (255, 100, 200),       # Pink
        }

# Register theme
ThemeManager.register(VirtOSCustomTheme)
```

Then use it:

```bash
# Add to Python path
export PYTHONPATH=~/.config/virtos:$PYTHONPATH

# Import in TUI
virtos-tui --theme virtos-custom
```

### Color Format

Colors are specified as RGB tuples (0-255):

```python
'foreground': (red, green, blue)
```

Example colors:

- Black: `(0, 0, 0)`
- White: `(255, 255, 255)`
- Red: `(255, 0, 0)`
- Green: `(0, 255, 0)`
- Blue: `(0, 0, 255)`
- Cyan: `(0, 255, 255)`

## Terminal Compatibility

### Color Support Detection

curses-themes automatically detects terminal capabilities:

- **256-color terminals**: Full RGB support with palette mapping
- **16-color terminals**: Fallback to nearest ANSI color
- **8-color terminals**: Basic color support
- **Monochrome terminals**: Fallback to intensity/bold

### Testing Terminal Capabilities

```bash
# Check color support
echo $TERM

# Common terminal types:
# xterm-256color  - 256 colors (best)
# xterm-color     - 16 colors
# xterm           - 8 colors
# linux           - 8 colors
```

### Recommended Terminals

| Terminal | Color Support | Recommended |
|----------|---------------|-------------|
| **xterm-256color** | 256 colors | ✓ Best |
| **tmux-256color** | 256 colors | ✓ Best |
| **screen-256color** | 256 colors | ✓ Best |
| **xterm** | 8-16 colors | ○ OK |
| **linux console** | 8 colors | ○ OK |

### Setting Terminal Type

```bash
# Enable 256-color support
export TERM=xterm-256color

# Add to ~/.bashrc for persistence
echo 'export TERM=xterm-256color' >> ~/.bashrc
```

## Advanced Usage

### Theme-Specific Features

Some themes include unique features:

#### 3D Themes

- Borland 3D: Shadow effects on windows
- dBASE IV 3D: Raised/lowered panels

#### Retro Themes

- TI-99/4A: Color bleeding effect simulation
- TRS-80: Monochrome with intensity variations

### Performance Considerations

All themes have minimal performance impact (<1% CPU), but:

- **3D themes**: Slightly more drawing operations for shadows
- **256-color themes**: Marginally slower on 8-color terminals (color mapping)

For maximum performance, use `default` or `trs80` (monochrome).

## Troubleshooting

### Colors Not Showing

**Problem**: All text appears white on black

**Solutions**:

```bash
# Enable 256-color support
export TERM=xterm-256color

# Or try different terminal
tmux  # Often has better color support
```

### Theme Not Loading

**Problem**: Theme reverts to default

**Solutions**:

```bash
# Check theme name spelling
virtos-tui --list-themes

# Verify config file
cat ~/.config/virtos/theme.conf

# Reset to default
echo 'THEME="default"' > ~/.config/virtos/theme.conf
```

### Garbled Display

**Problem**: Characters appear corrupted

**Solutions**:

```bash
# Set proper locale
export LANG=en_US.UTF-8

# Reset terminal
reset

# Try different theme
virtos-tui --theme default
```

## Integration with VirtOS

### Build System

To include themed TUI in VirtOS builds, update `build.conf`:

```bash
# Enable Python TUI with themes
INCLUDE_PYTHON_TUI="yes"
INCLUDE_PYTHON="yes"
```

### Package Dependencies

Add to package list:

- `python3.9.tcz`
- `python3.9-pip.tcz`

Install curses-themes during build:

```bash
pip3 install curses-themes
```

## Related Documentation

- [TUI.md](TUI.md) - Main TUI documentation
- [FlossWare curses-themes](https://github.com/FlossWare/curses-themes) - Theme library
- [QUICK-REFERENCE.md](../QUICK-REFERENCE.md) - CLI commands

## Examples

### Daily Use with Dark Theme

```bash
# Set preferred theme
echo 'THEME="dark"' > ~/.config/virtos/theme.conf

# Launch TUI
virtos-tui

# Theme persists across sessions
```

### Retro TRS-80 Experience

```bash
# Use TRS-80 monochrome theme
virtos-tui --theme trs80

# Perfect for minimalist/retro aesthetic
```

### Switching Themes On-the-Fly

```bash
# Launch TUI
virtos-tui

# Press 't' for theme menu
# Select different theme
# See changes immediately
```

## Summary

VirtOS TUI themes provide:

✓ **Professional appearance** - Modern and retro aesthetics  
✓ **Consistent semantics** - Colors have consistent meaning  
✓ **Easy switching** - Change themes anytime  
✓ **No configuration** - Works immediately  
✓ **Terminal-aware** - Adapts to terminal capabilities  
✓ **Extensible** - Create custom themes

**Quick Start**:

```bash
virtos-tui --theme dark
```

**Change Themes**: Press `t` from main menu

Enjoy your themed VirtOS experience!
