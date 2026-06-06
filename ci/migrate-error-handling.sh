#!/bin/bash
# shellcheck disable=SC2001,SC2004,SC2016,SC2027,SC2034,SC2046,SC2050,SC2064,SC2140,SC2144,SC2155
# migrate-error-handling.sh - Helper script to migrate scripts to standardized error functions
#
# This script helps migrate virtos-* scripts from manual echo statements
# to standardized error handling functions (die, warn, info, success)
# defined in virtos-common.sh
#
# Usage:
#   ./ci/migrate-error-handling.sh [script-file]           # Migrate single file
#   ./ci/migrate-error-handling.sh --all                   # Migrate all virtos-* scripts
#   ./ci/migrate-error-handling.sh --dry-run [file]        # Show changes without applying
#   ./ci/migrate-error-handling.sh --report                # Generate migration report

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPTS_DIR="packages/virtos-tools/src/usr/local/bin"
DRY_RUN=false

# Show usage
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS] [FILE]

Migrate virtos-* scripts to use standardized error handling functions
from virtos-common.sh (die, warn, info, success).

OPTIONS:
    --all           Migrate all virtos-* scripts
    --dry-run       Show changes without applying them
    --report        Generate migration report (no changes)
    -h, --help      Show this help message

EXAMPLES:
    # Show what would change in virtos-api
    $0 --dry-run packages/virtos-tools/src/usr/local/bin/virtos-api

    # Migrate single script
    $0 packages/virtos-tools/src/usr/local/bin/virtos-api

    # Generate report of all scripts
    $0 --report

    # Migrate all scripts (use with caution!)
    $0 --all

MIGRATION PATTERNS:
    echo "Error: ..." >&2 && exit 1    →  die "..."
    echo "Error: ..." >&2               →  error "..." (requires adding error function)
    echo "Warning: ..." >&2             →  warn "..."
    echo "Info: ..."                    →  info "..."
    echo "✓ ..." or echo "Success: ..." →  success "..."

NOTE: This script performs basic pattern matching. Always review changes
      and test scripts after migration!

EOF
}

# Generate migration report
generate_report() {
    echo -e "${BLUE}Migration Report - Error Handling Patterns${NC}"
    echo "=========================================="
    echo ""

    local total_scripts=0
    local scripts_with_echo_error=0
    local scripts_with_die=0
    local scripts_with_warn=0

    for script in "$SCRIPTS_DIR"/virtos-*; do
        [ ! -f "$script" ] && continue
        total_scripts=$((total_scripts + 1))

        if grep -q 'echo.*[Ee]rror' "$script"; then
            scripts_with_echo_error=$((scripts_with_echo_error + 1))
        fi

        if grep -q '^[[:space:]]*die()' "$script"; then
            scripts_with_die=$((scripts_with_die + 1))
        fi

        if grep -q '^[[:space:]]*warn()' "$script"; then
            scripts_with_warn=$((scripts_with_warn + 1))
        fi
    done

    echo "Total scripts: $total_scripts"
    echo "Scripts with echo error messages: $scripts_with_echo_error"
    echo "Scripts with local die() function: $scripts_with_die"
    echo "Scripts with local warn() function: $scripts_with_warn"
    echo ""

    echo -e "${YELLOW}Migration Candidates:${NC}"
    echo "Scripts with echo errors (need review):"
    for script in "$SCRIPTS_DIR"/virtos-*; do
        [ ! -f "$script" ] && continue
        if grep -q 'echo.*[Ee]rror' "$script"; then
            local count
            count=$(grep -c 'echo.*[Ee]rror' "$script") || {
                echo "  - $(basename "$script"): ERROR reading file" >&2
                continue
            }
            echo "  - $(basename "$script"): $count error messages"
        fi
    done
    echo ""

    echo -e "${GREEN}Already Using Standardized Functions:${NC}"
    echo "Scripts sourcing virtos-common.sh:"
    grep -l 'virtos-common.sh' "$SCRIPTS_DIR"/virtos-* 2>/dev/null | while read -r script; do
        echo "  ✓ $(basename "$script")"
    done
    echo ""

    echo -e "${BLUE}Recommendations:${NC}"
    echo "1. Ensure scripts source virtos-common.sh:"
    echo "   . /usr/local/lib/virtos-common.sh 2>/dev/null || true"
    echo ""
    echo "2. Replace local die/warn/info functions with virtos-common.sh versions"
    echo ""
    echo "3. Migrate echo statements to standardized functions:"
    echo "   - die \"message\" for fatal errors"
    echo "   - warn \"message\" for warnings"
    echo "   - info \"message\" for informational output"
    echo "   - success \"message\" for success messages"
}

# Analyze single script
analyze_script() {
    local script="$1"

    if [ ! -f "$script" ]; then
        echo -e "${RED}Error: File not found: $script${NC}" >&2
        return 1
    fi

    echo -e "${BLUE}Analyzing $(basename "$script")...${NC}"
    echo ""

    # Check if sourcing virtos-common.sh
    if grep -q 'virtos-common.sh' "$script"; then
        echo -e "${GREEN}✓${NC} Already sources virtos-common.sh"
    else
        echo -e "${YELLOW}!${NC} Does NOT source virtos-common.sh (will need to add)"
    fi

    # Count error patterns
    local echo_errors
    local echo_warnings
    local echo_info

    echo_errors=$(grep -c 'echo.*[Ee]rror' "$script" 2>/dev/null) || {
        echo -e "${RED}✗${NC} Error reading file for error patterns" >&2
        return 1
    }

    echo_warnings=$(grep -c 'echo.*[Ww]arning' "$script" 2>/dev/null) || {
        echo -e "${RED}✗${NC} Error reading file for warning patterns" >&2
        return 1
    }

    echo_info=$(grep -c 'echo.*[Ii]nfo' "$script" 2>/dev/null) || {
        echo -e "${RED}✗${NC} Error reading file for info patterns" >&2
        return 1
    }

    echo ""
    echo "Patterns found:"
    echo "  - Error messages: $echo_errors"
    echo "  - Warning messages: $echo_warnings"
    echo "  - Info messages: $echo_info"

    # Check for local die/warn/info functions
    echo ""
    if grep -q '^[[:space:]]*die()' "$script"; then
        echo -e "${YELLOW}!${NC} Has local die() function (should use virtos-common.sh version)"
    fi
    if grep -q '^[[:space:]]*warn()' "$script"; then
        echo -e "${YELLOW}!${NC} Has local warn() function (should use virtos-common.sh version)"
    fi
    if grep -q '^[[:space:]]*info()' "$script"; then
        echo -e "${YELLOW}!${NC} Has local info() function (should use virtos-common.sh version)"
    fi

    echo ""
    echo -e "${BLUE}Sample conversions:${NC}"

    # Show some examples
    grep -n 'echo.*[Ee]rror' "$script" 2>/dev/null | head -3 | while read -r line; do
        echo "$line"
    done
}

# Parse arguments
case "${1:-}" in
    -h | --help)
        show_help
        exit 0
        ;;
    --report)
        generate_report
        exit 0
        ;;
    --dry-run)
        DRY_RUN=true
        ;;
    --all)
        echo "Error: --all migration not yet implemented" >&2
        echo "Use --report to see migration candidates" >&2
        exit 1
        ;;
    "")
        show_help
        exit 1
        ;;
    *)
        analyze_script "$1"
        ;;
esac
