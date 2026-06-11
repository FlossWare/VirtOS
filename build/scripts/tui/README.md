# VirtOS TUI with FlossWare Curses-Themes

Python-based Text User Interface for VirtOS using the [FlossWare curses-themes](https://github.com/FlossWare/curses-themes) library.

## Features

- **Professional Theming**: Multiple built-in themes with FlossWare curses-themes
- **Theme Switching**: Change themes on-the-fly from within the TUI
- **Comprehensive Management**: VMs, containers, storage, clustering, and more
- **Semantic Colors**: Color-coded status (success, error, warning, info)
- **Keyboard-Driven**: Fast navigation with keyboard shortcuts
- **Persistent Config**: Theme preferences saved between sessions

## Installation

### Dependencies

```bash
# Python 3 and pip
sudo apt-get install python3 python3-pip

# Install curses-themes
pip3 install -r requirements.txt
```

Or install curses-themes directly:

```bash
pip3 install curses-themes
```

## Usage

### Launch TUI

```bash
# Launch with saved theme preference
./virtos-tui

# Launch with specific theme
./virtos-tui --theme dark

# List available themes
./virtos-tui --list-themes
```

### Available Themes

| Theme | Style | Era | Description |
|-------|-------|-----|-------------|
| `default` | Classic | Timeless | Traditional terminal aesthetic |
| `dark` | Modern | 2020s | Professional dark mode |
| `light` | Modern | 2020s | High contrast light mode |
| `ti994a` | Retro | 1981-1984 | TI-99/4A home computer |
| `trs80` | Retro | 1980-1983 | TRS-80 monochrome |
| `dos` | Classic | 1981-1995 | MS-DOS interface |
| `dbase3` | Business | 1984-1985 | dBASE III database |
| `dbase4` | Business | 1988-1993 | dBASE IV windowed |

### Keyboard Shortcuts

- **Arrow Keys**: Navigate menus
- **Enter**: Select menu item
- **Number Keys**: Direct menu selection
- **t**: Change theme (from main menu)
- **b**: Back to previous menu
- **q**: Quit
- **ESC**: Back/Cancel

## Configuration

Theme preferences are saved in `~/.config/virtos/theme.conf`:

```bash
THEME="dark"
```

You can edit this file manually or use the theme selector in the TUI (press `t`).

## Integration with VirtOS

### Build System

To include the Python TUI in VirtOS builds, add to `build.conf`:

```bash
# Enable Python TUI with curses-themes
INCLUDE_PYTHON_TUI="yes"
```

### Runtime Installation

On a running VirtOS system:

```bash
# Install Python and pip (if not already present)
tce-load -i python3.9 python3.9-pip

# Install curses-themes
pip3 install curses-themes

# Copy TUI files
sudo cp -r build/scripts/tui /opt/virtos/bin/
sudo ln -s /opt/virtos/bin/tui/virtos-tui /usr/local/bin/virtos-tui

# Launch
virtos-tui
```

## Comparison: Python TUI vs Dialog/Whiptail

| Feature | Python TUI (curses-themes) | Dialog/Whiptail |
|---------|---------------------------|-----------------|
| **Theming** | 8+ professional themes | Limited customization |
| **Colors** | Semantic color support | Basic color pairs |
| **Performance** | Fast, native Python | Requires shell spawning |
| **Customization** | Easy to extend in Python | Shell scripting |
| **Dependencies** | Python 3 + curses-themes | dialog/whiptail package |
| **File Size** | ~20KB Python scripts | Dialog binary ~200KB |

## Development

### Adding New Menus

Edit `virtos_tui.py` and add a new method:

```python
def show_my_menu(self):
    """Display custom submenu"""
    menu_items = [
        ("1", "Option 1"),
        ("2", "Option 2"),
        ("b", "Back to Main Menu"),
    ]

    while True:
        self.stdscr.clear()
        self.draw_title("My Custom Menu")
        self.draw_menu("Options", menu_items, start_y=3)
        self.draw_footer("Select an option | b: Back")
        self.stdscr.refresh()

        key = self.stdscr.getch()
        if key == ord('b') or key == 27:
            break
```

Then add to `main_menu()`:

```python
("x", "My Custom Menu"),
```

And in the key handler:

```python
elif key == ord('x'):
    self.show_my_menu()
```

### Creating Custom Themes

If you want to create a VirtOS-specific theme:

```python
from curses_themes import Theme, ThemeManager

class VirtOSTheme(Theme):
    """Custom VirtOS theme"""

    def __init__(self):
        super().__init__(
            name="VirtOS",
            description="Official VirtOS theme",
            author="FlossWare"
        )

    def get_color_map(self):
        return {
            'background': (0, 0, 0),
            'foreground': (0, 255, 0),  # Green terminal
            'primary': (0, 200, 255),
            'success': (0, 255, 0),
            'error': (255, 0, 0),
            'warning': (255, 200, 0),
            'info': (100, 200, 255),
            'accent': (200, 0, 255),
        }

# Register theme
ThemeManager.register(VirtOSTheme)
```

## Testing

Test the TUI without installing:

```bash
# From this directory
python3 virtos_tui.py

# With specific theme
python3 virtos_tui.py --theme dark
```

## Troubleshooting

### curses-themes not found

```bash
pip3 install curses-themes
```

### Terminal too small

Minimum terminal size: 80x24

```bash
# Resize terminal
resize -s 24 80
```

### Colors not working

Some terminals have limited color support. Try:

```bash
export TERM=xterm-256color
```

### Permission errors

Some features require root:

```bash
sudo virtos-tui
```

## Related Documentation

- [FlossWare curses-themes](https://github.com/FlossWare/curses-themes) - Theme library
- [VirtOS TUI.md](../../docs/TUI.md) - TUI documentation
- [VirtOS QUICK-REFERENCE.md](../../QUICK-REFERENCE.md) - CLI commands

## License

GPLv3 - Copyright (C) 2024 FlossWare
