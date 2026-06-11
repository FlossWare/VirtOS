#!/usr/bin/env python3
"""
VirtOS TUI - Terminal User Interface with FlossWare curses-themes

A comprehensive text-based management interface for VirtOS using the
FlossWare curses-themes library for professional theming support.

Copyright (C) 2024 FlossWare
License: GPLv3
"""

import curses
import os
import sys
import subprocess
from typing import List, Tuple, Optional

# Import FlossWare curses-themes
try:
    from curses_themes import ThemeManager
except ImportError:
    print("Error: curses-themes not installed", file=sys.stderr)
    print("Install with: pip3 install curses-themes", file=sys.stderr)
    sys.exit(1)


class VirtOSTUI:
    """Main VirtOS TUI application with theme support"""

    def __init__(self, stdscr, theme_name: str = "default"):
        self.stdscr = stdscr
        self.theme_name = theme_name
        self.theme = None
        self.height, self.width = stdscr.getmaxyx()

        # Initialize theme
        self._load_theme()

        # Application state
        self.running = True
        self.current_menu = "main"

    def _load_theme(self):
        """Load and apply the selected theme"""
        try:
            self.theme = ThemeManager.load(self.theme_name)
            self.theme.apply(self.stdscr)
        except Exception as e:
            # Fallback to default theme
            self.theme = ThemeManager.load("default")
            self.theme.apply(self.stdscr)

    def draw_title(self, title: str):
        """Draw the application title bar"""
        self.stdscr.attron(self.theme.colors.primary)
        title_text = f" {title} "
        x = (self.width - len(title_text)) // 2
        self.stdscr.addstr(0, 0, " " * self.width)
        self.stdscr.addstr(0, x, title_text)
        self.stdscr.attroff(self.theme.colors.primary)

    def draw_footer(self, text: str):
        """Draw the footer with help text"""
        footer_y = self.height - 1
        self.stdscr.attron(self.theme.colors.info)
        self.stdscr.addstr(footer_y, 0, " " * self.width)
        self.stdscr.addstr(footer_y, 2, text[:self.width - 4])
        self.stdscr.attroff(self.theme.colors.info)

    def draw_menu(self, title: str, items: List[Tuple[str, str]], start_y: int = 3):
        """
        Draw a menu with themed styling

        Args:
            title: Menu title
            items: List of (key, description) tuples
            start_y: Starting Y position
        """
        # Draw menu box
        box_height = len(items) + 4
        box_width = min(self.width - 4, 70)
        box_x = (self.width - box_width) // 2

        self.theme.draw_box(self.stdscr, start_y, box_x, box_height, box_width, title=title)

        # Draw menu items
        for idx, (key, description) in enumerate(items):
            y = start_y + 2 + idx
            x = box_x + 3

            # Draw key
            self.stdscr.attron(self.theme.colors.accent)
            self.stdscr.addstr(y, x, f"[{key}]")
            self.stdscr.attroff(self.theme.colors.accent)

            # Draw description
            self.stdscr.addstr(y, x + 6, description)

    def get_system_info(self) -> dict:
        """Gather system information"""
        try:
            # Get hostname
            hostname = subprocess.check_output(["hostname"], text=True).strip()

            # Get uptime
            uptime = subprocess.check_output(["uptime", "-p"], text=True).strip()

            # Get load average
            with open("/proc/loadavg") as f:
                load = f.read().split()[:3]
                load_avg = ", ".join(load)

            # Get memory info
            with open("/proc/meminfo") as f:
                meminfo = {}
                for line in f:
                    parts = line.split()
                    if len(parts) >= 2:
                        meminfo[parts[0].rstrip(":")] = parts[1]

            total_mem = int(meminfo.get("MemTotal", 0)) // 1024  # MB
            free_mem = int(meminfo.get("MemAvailable", 0)) // 1024  # MB
            used_mem = total_mem - free_mem

            # Get disk usage
            df_output = subprocess.check_output(["df", "-h", "/"], text=True)
            disk_line = df_output.split("\n")[1].split()
            disk_usage = f"{disk_line[2]} / {disk_line[1]} ({disk_line[4]})"

            return {
                "hostname": hostname,
                "uptime": uptime,
                "load_avg": load_avg,
                "memory": f"{used_mem}M / {total_mem}M",
                "disk": disk_usage,
            }
        except Exception as e:
            return {
                "hostname": "unknown",
                "uptime": "unknown",
                "load_avg": "unknown",
                "memory": "unknown",
                "disk": "unknown",
            }

    def draw_system_info_banner(self, y: int = 1):
        """Draw system information banner"""
        info = self.get_system_info()

        banner_lines = [
            f"System: {info['hostname']}",
            f"Load: {info['load_avg']} | Memory: {info['memory']} | Disk: {info['disk']}",
            f"{info['uptime']}",
        ]

        for idx, line in enumerate(banner_lines):
            x = (self.width - len(line)) // 2
            self.stdscr.addstr(y + idx, x, line)

    def main_menu(self):
        """Display the main menu"""
        menu_items = [
            ("1", "System Overview"),
            ("2", "Virtual Machines"),
            ("3", "VM Backups & Restore"),
            ("4", "VM Templates"),
            ("5", "VM Snapshots"),
            ("6", "Containers"),
            ("7", "Storage Management"),
            ("8", "Cluster Status"),
            ("9", "Networking"),
            ("t", "Change Theme"),
            ("q", "Exit"),
        ]

        while self.running:
            self.stdscr.clear()
            self.draw_title("VirtOS Management Console")
            self.draw_system_info_banner(1)
            self.draw_menu("Main Menu", menu_items, start_y=5)
            self.draw_footer("Arrow keys: Navigate | Enter: Select | q: Quit")
            self.stdscr.refresh()

            key = self.stdscr.getch()

            if key == ord('q') or key == ord('Q'):
                self.running = False
            elif key == ord('1'):
                self.show_system_overview()
            elif key == ord('2'):
                self.show_vm_menu()
            elif key == ord('3'):
                self.show_backup_menu()
            elif key == ord('t') or key == ord('T'):
                self.theme_selector()
            elif key == 27:  # ESC
                self.running = False

    def show_system_overview(self):
        """Display detailed system overview"""
        self.stdscr.clear()
        self.draw_title("System Overview")

        info = self.get_system_info()

        # Draw overview box
        overview_lines = [
            f"Hostname:    {info['hostname']}",
            f"Uptime:      {info['uptime']}",
            f"Load Avg:    {info['load_avg']}",
            f"Memory:      {info['memory']}",
            f"Disk:        {info['disk']}",
        ]

        box_height = len(overview_lines) + 4
        box_width = 60
        box_x = (self.width - box_width) // 2

        self.theme.draw_box(self.stdscr, 3, box_x, box_height, box_width, title="System Information")

        for idx, line in enumerate(overview_lines):
            self.stdscr.addstr(5 + idx, box_x + 3, line)

        self.draw_footer("Press any key to return to main menu")
        self.stdscr.refresh()
        self.stdscr.getch()

    def show_vm_menu(self):
        """Display VM management submenu"""
        menu_items = [
            ("1", "List All VMs"),
            ("2", "Start VM"),
            ("3", "Stop VM"),
            ("4", "VM Console"),
            ("b", "Back to Main Menu"),
        ]

        while True:
            self.stdscr.clear()
            self.draw_title("Virtual Machine Management")
            self.draw_menu("VM Menu", menu_items, start_y=3)
            self.draw_footer("Select an option | b: Back")
            self.stdscr.refresh()

            key = self.stdscr.getch()

            if key == ord('b') or key == ord('B') or key == 27:  # ESC
                break
            elif key == ord('1'):
                self.list_vms()

    def list_vms(self):
        """List all VMs using virsh"""
        self.stdscr.clear()
        self.draw_title("Virtual Machines")

        try:
            output = subprocess.check_output(["virsh", "list", "--all"], text=True)
            lines = output.strip().split("\n")

            box_height = min(len(lines) + 4, self.height - 6)
            box_width = min(self.width - 4, 80)
            box_x = (self.width - box_width) // 2

            self.theme.draw_box(self.stdscr, 3, box_x, box_height, box_width, title="VM List")

            for idx, line in enumerate(lines[:box_height - 4]):
                if idx < box_height - 4:
                    # Color running VMs differently
                    if "running" in line.lower():
                        self.stdscr.attron(self.theme.colors.success)
                        self.stdscr.addstr(5 + idx, box_x + 2, line[:box_width - 4])
                        self.stdscr.attroff(self.theme.colors.success)
                    elif "shut off" in line.lower():
                        self.stdscr.attron(self.theme.colors.warning)
                        self.stdscr.addstr(5 + idx, box_x + 2, line[:box_width - 4])
                        self.stdscr.attroff(self.theme.colors.warning)
                    else:
                        self.stdscr.addstr(5 + idx, box_x + 2, line[:box_width - 4])
        except Exception as e:
            error_msg = f"Error listing VMs: {str(e)}"
            self.stdscr.attron(self.theme.colors.error)
            self.stdscr.addstr(5, 2, error_msg)
            self.stdscr.attroff(self.theme.colors.error)

        self.draw_footer("Press any key to return")
        self.stdscr.refresh()
        self.stdscr.getch()

    def show_backup_menu(self):
        """Display backup management submenu"""
        menu_items = [
            ("1", "List All Backups"),
            ("2", "Backup a VM"),
            ("3", "Restore a VM"),
            ("b", "Back to Main Menu"),
        ]

        while True:
            self.stdscr.clear()
            self.draw_title("VM Backup & Restore")
            self.draw_menu("Backup Menu", menu_items, start_y=3)
            self.draw_footer("Select an option | b: Back")
            self.stdscr.refresh()

            key = self.stdscr.getch()

            if key == ord('b') or key == ord('B') or key == 27:
                break

    def theme_selector(self):
        """Interactive theme selection"""
        available_themes = [
            ("1", "default", "Classic terminal aesthetic"),
            ("2", "dark", "Professional dark mode"),
            ("3", "light", "High contrast light mode"),
            ("4", "ti994a", "TI-99/4A retro computer"),
            ("5", "trs80", "TRS-80 monochrome"),
            ("6", "dos", "Classic MS-DOS"),
            ("7", "dbase3", "dBASE III database"),
            ("8", "dbase4", "dBASE IV windowed"),
        ]

        while True:
            self.stdscr.clear()
            self.draw_title("Theme Selection")

            menu_items = [(key, f"{name} - {desc}") for key, name, desc in available_themes]
            menu_items.append(("b", "Back to Main Menu"))

            self.draw_menu("Available Themes", menu_items, start_y=3)
            self.draw_footer(f"Current theme: {self.theme_name} | Select a theme or b: Back")
            self.stdscr.refresh()

            key = self.stdscr.getch()

            if key == ord('b') or key == ord('B') or key == 27:
                break

            # Check if a theme was selected
            for k, theme_name, _ in available_themes:
                if key == ord(k):
                    self.theme_name = theme_name
                    self._load_theme()
                    self.stdscr.clear()
                    self.stdscr.refresh()
                    return

    def run(self):
        """Main application loop"""
        curses.curs_set(0)  # Hide cursor
        self.stdscr.keypad(True)  # Enable keypad

        try:
            self.main_menu()
        except KeyboardInterrupt:
            pass


def load_theme_config() -> str:
    """Load theme configuration from file"""
    config_path = os.path.expanduser("~/.config/virtos/theme.conf")

    if os.path.exists(config_path):
        try:
            with open(config_path) as f:
                for line in f:
                    if line.startswith("THEME="):
                        return line.split("=", 1)[1].strip().strip('"\'')
        except Exception:
            pass

    return "default"


def save_theme_config(theme_name: str):
    """Save theme configuration to file"""
    config_dir = os.path.expanduser("~/.config/virtos")
    config_path = os.path.join(config_dir, "theme.conf")

    os.makedirs(config_dir, exist_ok=True)

    with open(config_path, 'w') as f:
        f.write(f'THEME="{theme_name}"\n')


def main(stdscr):
    """Main entry point for curses wrapper"""
    # Load theme from config
    theme_name = load_theme_config()

    # Check for command-line theme override
    if len(sys.argv) > 1 and sys.argv[1] in ["--theme", "-t"]:
        if len(sys.argv) > 2:
            theme_name = sys.argv[2]

    # Create and run TUI
    tui = VirtOSTUI(stdscr, theme_name=theme_name)
    tui.run()

    # Save theme on exit
    save_theme_config(tui.theme_name)


if __name__ == "__main__":
    try:
        curses.wrapper(main)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
