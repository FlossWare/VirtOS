#!/bin/bash
# validate-scripts.sh - Validate virtos-* scripts for best practices and common issues
#
# This script checks virtos-* management scripts for:
# - Proper shebang
# - Copyright and license headers
# - Error handling (set -e)
# - Version handling
# - Help/usage functions
# - virtos-common.sh usage
# - Input validation
#
# Usage:
#   ./ci/validate-scripts.sh                    # Validate all scripts
#   ./ci/validate-scripts.sh [script-file]      # Validate single script
#   ./ci/validate-scripts.sh --report           # Generate compliance report
#   ./ci/validate-scripts.sh --summary          # Quick summary only

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPTS_DIR="packages/virtos-tools/src/usr/local/bin"
VERBOSE=false
SUMMARY_ONLY=false

# Counters
total_scripts=0
passed_scripts=0
failed_scripts=0
warnings=0

# Show usage
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS] [FILE]

Validate virtos-* scripts for best practices and common issues.

OPTIONS:
    --report        Generate detailed compliance report
    --summary       Show summary only (no per-script details)
    --verbose       Show all checks (including passed)
    -h, --help      Show this help message

EXAMPLES:
    # Validate all scripts
    $0

    # Validate single script
    $0 packages/virtos-tools/src/usr/local/bin/virtos-api

    # Generate compliance report
    $0 --report

    # Quick summary
    $0 --summary

CHECKS PERFORMED:
    ✓ Proper shebang (#!/bin/sh or #!/bin/bash)
    ✓ Copyright header present
    ✓ GPL-3.0 license reference
    ✓ Error handling (set -e)
    ✓ Help function (show_help)
    ✓ Version handling (--version flag)
    ✓ virtos-common.sh sourced (recommended)
    ✓ Input validation present

EOF
}

# Validate single script
validate_script() {
    local script="$1"
    local script_name
    script_name=$(basename "$script")
    local issues=0
    local script_warnings=0

    if [ ! -f "$script" ]; then
        echo -e "${RED}✗${NC} File not found: $script"
        return 1
    fi

    total_scripts=$((total_scripts + 1))

    [ "$VERBOSE" = true ] && echo -e "${BLUE}Validating $script_name...${NC}"

    # Check shebang
    if head -n 1 "$script" | grep -qE '^#!/bin/(ba)?sh'; then
        [ "$VERBOSE" = true ] && echo -e "  ${GREEN}✓${NC} Proper shebang"
    else
        echo -e "  ${RED}✗${NC} $script_name: Missing or invalid shebang"
        issues=$((issues + 1))
    fi

    # Check copyright header
    if head -n 10 "$script" | grep -qi "Copyright.*FlossWare"; then
        [ "$VERBOSE" = true ] && echo -e "  ${GREEN}✓${NC} Copyright header present"
    else
        echo -e "  ${YELLOW}!${NC} $script_name: Missing copyright header"
        script_warnings=$((script_warnings + 1))
    fi

    # Check GPL license reference
    if head -n 10 "$script" | grep -qi "GPL\|General Public License"; then
        [ "$VERBOSE" = true ] && echo -e "  ${GREEN}✓${NC} License reference present"
    else
        echo -e "  ${YELLOW}!${NC} $script_name: Missing GPL license reference"
        script_warnings=$((script_warnings + 1))
    fi

    # Check for set -e
    if head -n 30 "$script" | grep -q "^set -e"; then
        [ "$VERBOSE" = true ] && echo -e "  ${GREEN}✓${NC} Error handling (set -e)"
    else
        echo -e "  ${YELLOW}!${NC} $script_name: Missing 'set -e' for error handling"
        script_warnings=$((script_warnings + 1))
    fi

    # Check for help function
    if grep -q "show_help()" "$script" || grep -q "usage()" "$script"; then
        [ "$VERBOSE" = true ] && echo -e "  ${GREEN}✓${NC} Help function present"
    else
        echo -e "  ${YELLOW}!${NC} $script_name: Missing help/usage function"
        script_warnings=$((script_warnings + 1))
    fi

    # Check for version handling
    if grep -qE "(-v|--version)" "$script" && grep -q "VERSION=" "$script"; then
        [ "$VERBOSE" = true ] && echo -e "  ${GREEN}✓${NC} Version handling present"
    else
        echo -e "  ${YELLOW}!${NC} $script_name: Missing version handling"
        script_warnings=$((script_warnings + 1))
    fi

    # Check if sourcing virtos-common.sh
    if grep -q "virtos-common.sh" "$script"; then
        [ "$VERBOSE" = true ] && echo -e "  ${GREEN}✓${NC} Uses virtos-common.sh"
    else
        echo -e "  ${BLUE}ℹ${NC} $script_name: Not using virtos-common.sh (consider adding)"
    fi

    # Check for input validation
    if grep -qE "validate_|sanitize_" "$script"; then
        [ "$VERBOSE" = true ] && echo -e "  ${GREEN}✓${NC} Input validation present"
    else
        echo -e "  ${BLUE}ℹ${NC} $script_name: No validation functions found (consider adding)"
    fi

    # Summary for this script
    warnings=$((warnings + script_warnings))
    if [ $issues -eq 0 ]; then
        passed_scripts=$((passed_scripts + 1))
        [ "$SUMMARY_ONLY" = false ] && echo -e "${GREEN}✓${NC} $script_name: PASSED (warnings: $script_warnings)"
    else
        failed_scripts=$((failed_scripts + 1))
        echo -e "${RED}✗${NC} $script_name: FAILED ($issues issues, $script_warnings warnings)"
    fi

    [ "$VERBOSE" = true ] && echo ""
}

# Generate compliance report
generate_report() {
    echo -e "${BLUE}VirtOS Script Validation Report${NC}"
    echo "======================================"
    echo ""

    # Validate all scripts
    for script in "$SCRIPTS_DIR"/virtos-*; do
        [ ! -f "$script" ] && continue
        validate_script "$script"
    done

    echo ""
    echo -e "${BLUE}Summary${NC}"
    echo "-------"
    echo "Total scripts: $total_scripts"
    echo -e "${GREEN}Passed: $passed_scripts${NC}"
    [ $failed_scripts -gt 0 ] && echo -e "${RED}Failed: $failed_scripts${NC}" || echo "Failed: 0"
    echo -e "${YELLOW}Total warnings: $warnings${NC}"
    echo ""

    # Calculate compliance percentage
    if [ $total_scripts -gt 0 ]; then
        local compliance=$(((passed_scripts * 100) / total_scripts))
        echo -e "Compliance: ${compliance}%"

        if [ $compliance -ge 90 ]; then
            echo -e "Status: ${GREEN}EXCELLENT${NC}"
        elif [ $compliance -ge 75 ]; then
            echo -e "Status: ${GREEN}GOOD${NC}"
        elif [ $compliance -ge 50 ]; then
            echo -e "Status: ${YELLOW}NEEDS IMPROVEMENT${NC}"
        else
            echo -e "Status: ${RED}POOR${NC}"
        fi
    fi

    echo ""
    echo "Recommendations:"
    echo "  1. Add copyright/license headers to all scripts"
    echo "  2. Use 'set -e' for proper error handling"
    echo "  3. Include --help and --version flags"
    echo "  4. Source virtos-common.sh for shared functionality"
    echo "  5. Add input validation using virtos-common.sh functions"
}

# Quick summary
show_summary() {
    SUMMARY_ONLY=true
    for script in "$SCRIPTS_DIR"/virtos-*; do
        [ ! -f "$script" ] && continue
        validate_script "$script" >/dev/null 2>&1
    done

    echo -e "${BLUE}Quick Validation Summary${NC}"
    echo "========================"
    echo "Total scripts: $total_scripts"
    echo -e "${GREEN}Passed: $passed_scripts${NC} ($(((passed_scripts * 100) / total_scripts))%)"
    [ $failed_scripts -gt 0 ] && echo -e "${RED}Failed: $failed_scripts${NC}" || echo "Failed: 0"
    echo -e "${YELLOW}Warnings: $warnings${NC}"
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
    --summary)
        show_summary
        exit 0
        ;;
    --verbose)
        VERBOSE=true
        generate_report
        exit 0
        ;;
    "")
        generate_report
        exit 0
        ;;
    *)
        validate_script "$1"
        ;;
esac
