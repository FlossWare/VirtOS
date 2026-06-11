#!/usr/bin/env python3
"""
Generate screenshots for VirtOS TUI using curses-themes screenshot_capture tool.

This script leverages the FlossWare curses-themes screenshot_capture.py tool
to automatically generate pixel-perfect PNG screenshots of the VirtOS TUI
in all available themes.

Usage:
    python3 generate_virtos_screenshots.py [--output-dir DIR] [--theme THEME]

Copyright (C) 2024 FlossWare
License: GPLv3
"""

import sys
import os
from pathlib import Path
from typing import Dict, Tuple, Optional

# Import the curses-themes screenshot tool
try:
    # Add curses-themes tools directory to path
    curses_themes_tools = Path.home() / "Development/github/FlossWare/curses-themes/tools"
    sys.path.insert(0, str(curses_themes_tools))

    from screenshot_capture import TerminalRenderer, render_theme_screenshot, create_comparison_grid
    from curses_themes import ThemeManager
except ImportError as e:
    print(f"Error: Could not import curses-themes screenshot tools: {e}", file=sys.stderr)
    print("", file=sys.stderr)
    print("Make sure curses-themes is installed and screenshot_capture.py is available:", file=sys.stderr)
    print("  pip3 install curses-themes Pillow", file=sys.stderr)
    sys.exit(1)


def render_virtos_main_menu(theme, renderer: TerminalRenderer):
    """
    Render the VirtOS TUI main menu for screenshot.

    This creates a realistic representation of the VirtOS main menu
    similar to what users see when running virtos-tui.
    """
    # Get theme colors
    color_map = theme.get_color_map()
    bg_color = color_map.get('background', (0, 0, 0))
    fg_color = color_map.get('foreground', (255, 255, 255))
    primary_color = color_map.get('primary', (0, 120, 215))
    success_color = color_map.get('success', (16, 124, 16))
    warning_color = color_map.get('warning', (193, 156, 0))
    info_color = color_map.get('info', (0, 120, 212))
    accent_color = color_map.get('accent', (142, 68, 173))

    # Clear screen
    renderer.clear(bg_color)

    # Title bar (row 0)
    title = "VirtOS Management Console"
    title_padded = f" {title} ".center(renderer.width)
    renderer.addstr(0, 0, title_padded, primary_color, primary_color, bold=True)

    # System information banner (rows 2-4)
    sys_info = [
        "System: virtos-1.local",
        "Load: 0.15, 0.10, 0.05 | Memory: 4.2G / 16G | Disk: 45G / 200G (23%)",
        "Uptime: up 2 days, 4 hours, 32 minutes"
    ]

    for idx, line in enumerate(sys_info):
        x = (renderer.width - len(line)) // 2
        renderer.addstr(2 + idx, x, line, fg_color, bg_color)

    # Main menu box
    menu_y = 6
    menu_x = (renderer.width - 60) // 2
    menu_width = 60
    menu_height = 14

    border_chars = theme.get_border_chars()

    try:
        border = theme.get_border()
        if border:
            border_fg, border_bg = border.foreground, border.background
        else:
            border_fg, border_bg = fg_color, bg_color
    except:
        border_fg, border_bg = fg_color, bg_color

    renderer.draw_box(menu_y, menu_x, menu_height, menu_width,
                     border_chars, border_fg, border_bg, "Main Menu")

    # Menu items
    menu_items = [
        ("[1]", "System Overview"),
        ("[2]", "Virtual Machines"),
        ("[3]", "VM Backups & Restore"),
        ("[4]", "VM Templates"),
        ("[5]", "VM Snapshots"),
        ("[6]", "Containers"),
        ("[7]", "Storage Management"),
        ("[8]", "Cluster Status"),
        ("[9]", "Networking"),
        ("[t]", "Change Theme"),
        ("[q]", "Exit"),
    ]

    for idx, (key, desc) in enumerate(menu_items):
        item_y = menu_y + 2 + idx
        item_x = menu_x + 4

        # Draw key in accent color
        renderer.addstr(item_y, item_x, key, accent_color, bg_color, bold=True)

        # Draw description
        renderer.addstr(item_y, item_x + 6, desc, fg_color, bg_color)

    # Footer (row 23)
    footer = "Arrow keys: Navigate | Enter: Select | q: Quit"
    footer_x = (renderer.width - len(footer)) // 2
    renderer.addstr(23, footer_x, footer, info_color, bg_color)

    return renderer.image


def render_virtos_vm_list(theme, renderer: TerminalRenderer):
    """
    Render the VirtOS VM list view for screenshot.

    Shows the VM management screen with color-coded VM status.
    """
    color_map = theme.get_color_map()
    bg_color = color_map.get('background', (0, 0, 0))
    fg_color = color_map.get('foreground', (255, 255, 255))
    primary_color = color_map.get('primary', (0, 120, 215))
    success_color = color_map.get('success', (16, 124, 16))
    warning_color = color_map.get('warning', (193, 156, 0))

    renderer.clear(bg_color)

    # Title bar
    title = "Virtual Machines"
    title_padded = f" {title} ".center(renderer.width)
    renderer.addstr(0, 0, title_padded, primary_color, primary_color, bold=True)

    # VM list box
    border_chars = theme.get_border_chars()

    try:
        border = theme.get_border()
        border_fg, border_bg = border.foreground if border else fg_color, bg_color
    except:
        border_fg, border_bg = fg_color, bg_color

    renderer.draw_box(3, 2, 16, 76, border_chars, border_fg, border_bg, "VM List")

    # VM list header
    header = " Id   Name                     State        CPU    Memory"
    renderer.addstr(5, 4, header, fg_color, bg_color, bold=True)
    renderer.addstr(6, 4, "─" * 70, border_fg, bg_color)

    # VM entries
    vms = [
        ("1", "web-server-1", "running", success_color),
        ("2", "db-server", "running", success_color),
        ("3", "test-vm", "shut off", warning_color),
        ("4", "backup-vm", "running", success_color),
        ("5", "dev-environment", "shut off", warning_color),
    ]

    for idx, (vm_id, name, state, color) in enumerate(vms):
        vm_y = 7 + idx
        vm_line = f" {vm_id:3}  {name:25} {state:12} 2      4096M"
        renderer.addstr(vm_y, 4, vm_line, color, bg_color)

    # Footer
    footer = "Green: Running | Yellow: Stopped | Press any key to return"
    footer_x = (renderer.width - len(footer)) // 2
    renderer.addstr(21, footer_x, footer, fg_color, bg_color)

    return renderer.image


def main():
    """Generate VirtOS TUI screenshots."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Generate VirtOS TUI screenshots using curses-themes"
    )
    parser.add_argument(
        '--output-dir',
        default='../../../docs/screenshots/tui',
        help='Output directory for screenshots'
    )
    parser.add_argument(
        '--theme',
        help='Generate screenshots for specific theme only'
    )
    parser.add_argument(
        '--view',
        choices=['main-menu', 'vm-list', 'all'],
        default='main-menu',
        help='Which view to render (default: main-menu)'
    )
    parser.add_argument(
        '--create-grid',
        action='store_true',
        help='Create a comparison grid of all themes'
    )

    args = parser.parse_args()

    # Create output directory
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Create theme subdirectories
    themes_dir = output_dir / "themes"
    features_dir = output_dir / "features"
    themes_dir.mkdir(exist_ok=True)
    features_dir.mkdir(exist_ok=True)

    print("VirtOS TUI Screenshot Generator")
    print("=" * 70)
    print(f"Output directory: {output_dir}")
    print(f"View: {args.view}")
    print()

    # Initialize renderer
    renderer = TerminalRenderer(width=80, height=24, font_size=14)

    # Get themes to render
    all_themes = ThemeManager.list_themes()

    if args.theme:
        theme_names = [args.theme]
    else:
        theme_names = sorted(all_themes.keys())

    # Track images for grid
    grid_images = []

    # Generate screenshots
    for theme_name in theme_names:
        try:
            print(f"Rendering {theme_name}...", end=' ')

            # Load theme
            theme = ThemeManager.load(theme_name)

            # Render main menu
            if args.view in ['main-menu', 'all']:
                image = render_virtos_main_menu(theme, renderer)
                output_file = themes_dir / f"{theme_name}-theme.png"
                renderer.save(str(output_file))
                print(f"✓ main menu -> {output_file.name}", end='')

                if args.create_grid:
                    grid_images.append((theme_name, image.copy()))

            # Render VM list
            if args.view in ['vm-list', 'all']:
                image = render_virtos_vm_list(theme, renderer)
                output_file = features_dir / f"{theme_name}-vm-list.png"
                renderer.save(str(output_file))
                print(f" ✓ VM list -> {output_file.name}", end='')

            print()

        except Exception as e:
            print(f"✗ Error: {e}")
            import traceback
            traceback.print_exc()

    print()
    print(f"Generated screenshots for {len(theme_names)} theme(s)")

    # Create comparison grid
    if args.create_grid and grid_images:
        grid_path = output_dir / "theme-comparison.png"
        create_comparison_grid(grid_images, str(grid_path))
        print(f"Created comparison grid: {grid_path}")

    print()
    print("Done! Screenshots saved to:")
    print(f"  Themes: {themes_dir}/")
    print(f"  Features: {features_dir}/")

    print()
    print("Next steps:")
    print("  1. Review screenshots")
    print("  2. Update documentation with screenshot links")
    print("  3. Commit to repository")


if __name__ == '__main__':
    main()
