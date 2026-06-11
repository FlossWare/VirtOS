# VirtOS TUI Screenshot Generation

Automated screenshot generation for VirtOS TUI using FlossWare curses-themes.

## Quick Start

```bash
# Install dependencies
pip3 install curses-themes Pillow

# Generate all screenshots
python3 generate_virtos_screenshots.py

# Done! Screenshots are in ../../../docs/screenshots/tui/
```

## What This Does

The `generate_virtos_screenshots.py` script uses the [FlossWare curses-themes screenshot_capture.py](https://github.com/FlossWare/curses-themes/blob/main/tools/screenshot_capture.py) tool to automatically generate pixel-perfect PNG screenshots of the VirtOS TUI.

**No terminal emulator required** - renders directly to PNG using PIL/Pillow.

## Usage

### Generate All Themes (Main Menu)

```bash
python3 generate_virtos_screenshots.py
```

Creates screenshots in `docs/screenshots/tui/themes/`:

- `default-theme.png`
- `dark-theme.png`
- `light-theme.png`
- `ti994a-theme.png`
- `trs80-theme.png`
- `dos-theme.png`
- `dbase3-theme.png`
- `dbase4-theme.png`

### Generate Specific Theme

```bash
python3 generate_virtos_screenshots.py --theme dark
```

### Generate All Views

```bash
python3 generate_virtos_screenshots.py --view all
```

Generates:

- Main menu (all themes)
- VM list view (all themes)

### Create Comparison Grid

```bash
python3 generate_virtos_screenshots.py --create-grid
```

Creates `docs/screenshots/tui/theme-comparison.png` with all themes in a grid.

### Custom Output Directory

```bash
python3 generate_virtos_screenshots.py --output-dir /tmp/screenshots
```

## Output Structure

```
docs/screenshots/tui/
├── themes/
│   ├── default-theme.png
│   ├── dark-theme.png
│   ├── light-theme.png
│   └── ...
├── features/
│   ├── default-vm-list.png
│   ├── dark-vm-list.png
│   └── ...
└── theme-comparison.png  (if --create-grid)
```

## Requirements

- Python 3.9+
- curses-themes package
- Pillow (PIL) package
- Access to FlossWare curses-themes repository

### Installing Dependencies

```bash
# Install Python packages
pip3 install curses-themes Pillow

# Ensure curses-themes repo is available
# (Script looks in ~/Development/github/FlossWare/curses-themes/)
```

## How It Works

1. **Imports** curses-themes `screenshot_capture.py` tool
2. **Initializes** TerminalRenderer (80x24 terminal, 14pt font)
3. **Renders** VirtOS TUI layouts (main menu, VM list, etc.)
4. **Saves** pixel-perfect PNG screenshots
5. **Creates** comparison grid (optional)

## Customization

### Rendering Different Views

Edit `generate_virtos_screenshots.py` and add new render functions:

```python
def render_virtos_my_view(theme, renderer: TerminalRenderer):
    """Render custom VirtOS view"""
    color_map = theme.get_color_map()
    bg_color = color_map.get('background', (0, 0, 0))
    fg_color = color_map.get('foreground', (255, 255, 255))

    renderer.clear(bg_color)

    # Draw your custom view
    renderer.addstr(0, 0, "My Custom View", fg_color, bg_color, bold=True)

    return renderer.image
```

Then add to main():

```python
if args.view in ['my-view', 'all']:
    image = render_virtos_my_view(theme, renderer)
    output_file = features_dir / f"{theme_name}-my-view.png"
    renderer.save(str(output_file))
```

### Changing Terminal Size

```python
renderer = TerminalRenderer(
    width=100,      # Change from 80
    height=30,      # Change from 24
    font_size=16    # Change from 14
)
```

## Comparison with Other Methods

| Method | Automated | Consistency | Quality | Speed |
|--------|-----------|-------------|---------|-------|
| **generate_virtos_screenshots.py** | ✓ | Perfect | Pixel-perfect | Fast |
| curses-themes screenshot_capture.py | ✓ | Perfect | Pixel-perfect | Fast |
| Terminal screenshots (scrot, etc.) | ✗ | Varies | Good | Medium |
| Manual screenshots | ✗ | Varies | Varies | Slow |

## Troubleshooting

### ImportError: No module named 'screenshot_capture'

The script looks for curses-themes in `~/Development/github/FlossWare/curses-themes/`.

**Fix**:

```bash
# Clone curses-themes
cd ~/Development/github/FlossWare/
git clone https://github.com/FlossWare/curses-themes

# Or adjust path in generate_virtos_screenshots.py
```

### No monospace font found

The screenshot tool needs a monospace font installed.

**Fix**:

```bash
# Ubuntu/Debian
sudo apt-get install fonts-dejavu fonts-liberation

# Fedora
sudo dnf install dejavu-sans-mono-fonts liberation-mono-fonts

# macOS (usually already has them)
```

### Screenshots look wrong

Check that you have the latest curses-themes:

```bash
pip3 install --upgrade curses-themes
```

## Examples

### Generate Everything

```bash
# Generate all themes, all views, and comparison grid
python3 generate_virtos_screenshots.py --view all --create-grid
```

### Quick Test

```bash
# Generate just one theme for testing
python3 generate_virtos_screenshots.py --theme dark --view main-menu
```

### Batch Processing

```bash
# Generate screenshots for specific themes
for theme in default dark light; do
    python3 generate_virtos_screenshots.py --theme $theme --view all
done
```

## Integration with Documentation

After generating screenshots, update documentation:

```markdown
### Dark Theme

![VirtOS TUI - Dark Theme](../screenshots/tui/themes/dark-theme.png)

Professional dark mode for reduced eye strain.
```

## Contributing

To add new screenshot views:

1. Create a render function in `generate_virtos_screenshots.py`
2. Add view option to argparse choices
3. Update this README with the new view
4. Generate screenshots and commit

## Related

- [TUI_SCREENSHOTS.md](../../../docs/TUI_SCREENSHOTS.md) - Full screenshot documentation
- [FlossWare curses-themes](https://github.com/FlossWare/curses-themes) - Theme library
- [screenshot_capture.py](https://github.com/FlossWare/curses-themes/blob/main/tools/screenshot_capture.py) - Underlying screenshot tool

## License

GPLv3 - Copyright (C) 2024 FlossWare
