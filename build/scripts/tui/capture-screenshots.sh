#!/bin/bash
#
# capture-screenshots.sh - Automated screenshot capture helper for VirtOS TUI
#
# This script helps organize and document screenshot capture for all TUI themes.
# It provides a structured process for capturing consistent screenshots.
#
# Copyright (C) 2024 FlossWare
# License: GPLv3

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
readonly PROJECT_ROOT
readonly SCREENSHOTS_DIR="${PROJECT_ROOT}/docs/screenshots/tui"
readonly TUI_SCRIPT="${SCRIPT_DIR}/virtos-tui"

# Colors for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Create screenshot directories
setup_directories() {
    mkdir -p "${SCREENSHOTS_DIR}/themes"
    mkdir -p "${SCREENSHOTS_DIR}/features"
    echo -e "${GREEN}Created screenshot directories${NC}"
}

# Display usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Automated screenshot capture helper for VirtOS TUI.

OPTIONS:
    -a, --auto       Attempt automated capture (requires scrot or gnome-screenshot)
    -m, --manual     Manual mode - guides you through screenshot capture
    -l, --list       List what screenshots are needed
    -h, --help       Show this help message

EXAMPLES:
    $0 --manual      # Interactive mode (recommended)
    $0 --auto        # Automated mode (if you have scrot installed)
    $0 --list        # See checklist of required screenshots

MANUAL MODE:
    The script will launch TUI for each theme/feature, wait for you to
    take a screenshot, then move to the next one.

AUTOMATED MODE:
    Requires: scrot, xdotool (for window selection)
    The script will attempt to automatically capture screenshots.

EOF
}

# List required screenshots
list_screenshots() {
    cat <<EOF
${BLUE}Required VirtOS TUI Screenshots:${NC}

${YELLOW}1. Theme Screenshots (8 total):${NC}
   [ ] default-theme.png    - Default theme main menu
   [ ] dark-theme.png        - Dark theme main menu
   [ ] light-theme.png       - Light theme main menu
   [ ] ti994a-theme.png      - TI-99/4A theme main menu
   [ ] trs80-theme.png       - TRS-80 theme main menu
   [ ] dos-theme.png         - DOS theme main menu
   [ ] dbase3-theme.png      - dBASE III theme main menu
   [ ] dbase4-theme.png      - dBASE IV theme main menu

${YELLOW}2. Feature Screenshots (5 total):${NC}
   [ ] system-overview.png   - System overview page (press 1)
   [ ] vm-menu.png          - VM management menu (press 2)
   [ ] vm-list.png          - VM list page (press 2, then 1)
   [ ] theme-selector.png   - Theme selector (press t)
   [ ] backup-menu.png      - Backup menu (press 3)

${YELLOW}3. Optional Screenshots:${NC}
   [ ] semantic-colors.png  - Demonstration of color semantics
   [ ] theme-comparison.png - Grid comparison of all themes
   [ ] dialog-vs-python.png - Old dialog TUI vs new Python TUI

${GREEN}Save to:${NC} ${SCREENSHOTS_DIR}/

${GREEN}Documentation:${NC} See docs/TUI_SCREENSHOTS.md for details

EOF
}

# Manual screenshot capture mode
manual_mode() {
    echo -e "${BLUE}VirtOS TUI Screenshot Capture - Manual Mode${NC}"
    echo ""
    echo "This script will guide you through capturing screenshots."
    echo "For each theme, the TUI will launch. Please:"
    echo "  1. Take a screenshot of the window"
    echo "  2. Save to the specified filename"
    echo "  3. Press 'q' to exit TUI and continue"
    echo ""
    read -p "Press Enter to begin..."

    # Theme screenshots
    local themes=(
        "default:Default (classic B/W)"
        "dark:Dark (modern dark mode)"
        "light:Light (high contrast)"
        "ti994a:TI-99/4A (retro 1981)"
        "trs80:TRS-80 (monochrome)"
        "dos:DOS (MS-DOS classic)"
        "dbase3:dBASE III (database)"
        "dbase4:dBASE IV (windowed)"
    )

    local count=1
    local total=${#themes[@]}

    for theme_info in "${themes[@]}"; do
        IFS=':' read -r theme_name theme_desc <<<"$theme_info"

        echo ""
        echo -e "${YELLOW}[${count}/${total}] Theme: ${theme_desc}${NC}"
        echo -e "${GREEN}Save as:${NC} ${SCREENSHOTS_DIR}/themes/${theme_name}-theme.png"
        echo ""
        echo "Launching TUI in 3 seconds..."
        echo "Take screenshot, then press 'q' to continue"
        sleep 3

        "${TUI_SCRIPT}" --theme "${theme_name}" || true

        echo -e "${GREEN}✓ ${theme_desc} complete${NC}"
        ((count++))
    done

    # Feature screenshots
    echo ""
    echo -e "${YELLOW}Feature Screenshots${NC}"
    echo ""
    read -p "Capture feature screenshots? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        capture_feature_screenshots
    fi

    echo ""
    echo -e "${GREEN}Screenshot capture complete!${NC}"
    echo -e "${GREEN}Review screenshots in:${NC} ${SCREENSHOTS_DIR}/"
    echo ""
    echo "Next steps:"
    echo "  1. Review and crop screenshots if needed"
    echo "  2. Optimize file sizes (optipng, pngcrush)"
    echo "  3. Update documentation with screenshot links"
}

# Feature screenshot guide
capture_feature_screenshots() {
    local features=(
        "System Overview (press 1):system-overview.png"
        "VM Menu (press 2):vm-menu.png"
        "VM List (press 2, then 1):vm-list.png"
        "Theme Selector (press t):theme-selector.png"
        "Backup Menu (press 3):backup-menu.png"
    )

    for feature_info in "${features[@]}"; do
        IFS=':' read -r feature_name filename <<<"$feature_info"

        echo ""
        echo -e "${YELLOW}Feature: ${feature_name}${NC}"
        echo -e "${GREEN}Save as:${NC} ${SCREENSHOTS_DIR}/features/${filename}"
        echo ""
        read -p "Press Enter to launch TUI..."

        "${TUI_SCRIPT}" --theme dark || true

        echo -e "${GREEN}✓ ${feature_name} complete${NC}"
    done
}

# Automated screenshot capture (requires scrot)
auto_mode() {
    # Check for scrot
    if ! command -v scrot &>/dev/null; then
        echo -e "${YELLOW}Warning: scrot not found${NC}"
        echo "Install with: sudo apt-get install scrot"
        echo "Falling back to manual mode..."
        manual_mode
        return
    fi

    echo -e "${BLUE}VirtOS TUI Screenshot Capture - Automated Mode${NC}"
    echo ""
    echo "This will automatically capture screenshots using scrot."
    echo "Please ensure the TUI window is visible and focused."
    echo ""
    read -p "Press Enter to begin..."

    # Theme screenshots
    local themes=(
        "default:Default"
        "dark:Dark"
        "light:Light"
        "ti994a:TI-99/4A"
        "trs80:TRS-80"
        "dos:DOS"
        "dbase3:dBASE III"
        "dbase4:dBASE IV"
    )

    for theme_info in "${themes[@]}"; do
        IFS=':' read -r theme_name theme_desc <<<"$theme_info"

        echo ""
        echo -e "${YELLOW}Capturing ${theme_desc} theme...${NC}"

        # Launch TUI in background
        "${TUI_SCRIPT}" --theme "${theme_name}" &
        local tui_pid=$!

        # Wait for TUI to fully render
        sleep 2

        # Capture focused window
        scrot -u "${SCREENSHOTS_DIR}/themes/${theme_name}-theme.png"

        # Close TUI
        kill "${tui_pid}" 2>/dev/null || true

        echo -e "${GREEN}✓ Saved ${theme_name}-theme.png${NC}"
    done

    echo ""
    echo -e "${GREEN}Automated screenshot capture complete!${NC}"
}

# Validate screenshots
check_screenshots() {
    echo -e "${BLUE}Checking for existing screenshots...${NC}"
    echo ""

    local theme_count=0
    local feature_count=0

    # Check theme screenshots
    for theme in default dark light ti994a trs80 dos dbase3 dbase4; do
        if [[ -f "${SCREENSHOTS_DIR}/themes/${theme}-theme.png" ]]; then
            echo -e "${GREEN}✓${NC} ${theme}-theme.png"
            ((theme_count++))
        else
            echo -e "${YELLOW}✗${NC} ${theme}-theme.png (missing)"
        fi
    done

    echo ""

    # Check feature screenshots
    for feature in system-overview vm-menu vm-list theme-selector backup-menu; do
        if [[ -f "${SCREENSHOTS_DIR}/features/${feature}.png" ]]; then
            echo -e "${GREEN}✓${NC} ${feature}.png"
            ((feature_count++))
        else
            echo -e "${YELLOW}✗${NC} ${feature}.png (missing)"
        fi
    done

    echo ""
    echo -e "Theme screenshots: ${GREEN}${theme_count}/8${NC}"
    echo -e "Feature screenshots: ${GREEN}${feature_count}/5${NC}"
    echo -e "Total: ${GREEN}$((theme_count + feature_count))/13${NC}"
}

# Main function
main() {
    setup_directories

    case "${1:-}" in
        -a | --auto)
            auto_mode
            ;;
        -m | --manual)
            manual_mode
            ;;
        -l | --list)
            list_screenshots
            ;;
        -c | --check)
            check_screenshots
            ;;
        -h | --help | *)
            usage
            exit 0
            ;;
    esac
}

main "$@"
