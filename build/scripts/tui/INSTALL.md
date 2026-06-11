# VirtOS TUI Installation Guide

Quick installation guide for the themed Python TUI.

## Prerequisites

- Python 3.9 or later
- pip3
- Terminal with color support (recommended: xterm-256color)

## Installation Methods

### Method 1: Quick Install (Recommended)

```bash
# Navigate to TUI directory
cd build/scripts/tui

# Install Python dependencies
pip3 install -r requirements.txt

# Run the TUI
./virtos-tui
```

### Method 2: System-Wide Installation

```bash
# Install dependencies
pip3 install curses-themes

# Copy to system location
sudo mkdir -p /opt/virtos/bin
sudo cp -r build/scripts/tui /opt/virtos/bin/

# Create symlink
sudo ln -s /opt/virtos/bin/tui/virtos-tui /usr/local/bin/virtos-tui

# Run from anywhere
virtos-tui
```

### Method 3: Tiny Core Linux (TCZ)

For VirtOS running on Tiny Core:

```bash
# Load Python
tce-load -i python3.9 python3.9-pip

# Install curses-themes
pip3 install curses-themes

# Copy TUI files
sudo cp -r /path/to/build/scripts/tui /opt/virtos/bin/

# Add to bootlocal.sh for persistence
echo 'pip3 install curses-themes' >> /opt/bootlocal.sh
```

## Verification

Test the installation:

```bash
# Launch TUI
virtos-tui

# Should see main menu with current theme
# Press 't' to see theme selector
# Press 'q' to quit
```

## Troubleshooting

### curses-themes not found

```bash
# Install manually
pip3 install curses-themes

# Or use local installation
pip3 install --user curses-themes
```

### Python not found

```bash
# On Debian/Ubuntu
sudo apt-get install python3 python3-pip

# On Tiny Core
tce-load -i python3.9 python3.9-pip
```

### Permission denied

```bash
# Make script executable
chmod +x virtos-tui

# Or run with python3 directly
python3 virtos_tui.py
```

## Next Steps

1. **Configure theme**: Edit `~/.config/virtos/theme.conf`
2. **Read documentation**: See `README.md` and `../../../docs/TUI_THEMES.md`
3. **Explore themes**: Press `t` from main menu

## Uninstallation

```bash
# Remove system installation
sudo rm /usr/local/bin/virtos-tui
sudo rm -rf /opt/virtos/bin/tui

# Remove Python package
pip3 uninstall curses-themes

# Remove config
rm -rf ~/.config/virtos
```
