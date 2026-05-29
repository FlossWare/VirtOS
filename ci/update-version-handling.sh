#!/bin/bash
# Update all virtos-* scripts to use get_version() from virtos-common.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VIRTOS_SCRIPTS_DIR="$(dirname "$SCRIPT_DIR")/packages/virtos-tools/src/usr/local/bin"

if [ ! -d "$VIRTOS_SCRIPTS_DIR" ]; then
    echo "ERROR: virtos scripts directory not found: $VIRTOS_SCRIPTS_DIR" >&2
    exit 1
fi

cd "$VIRTOS_SCRIPTS_DIR"

UPDATED_COUNT=0
ALREADY_OK_COUNT=0
ERROR_COUNT=0

for script in virtos-*; do
    if [ ! -f "$script" ]; then
        continue
    fi

    echo "Processing $script..."

    # Create backup
    cp "$script" "$script.bak"

    # Check if already using get_version
    if grep -q 'get_version()' "$script" || grep -q 'VERSION=$(get_version)' "$script"; then
        echo "  ✓ Already using get_version()"
        ALREADY_OK_COUNT=$((ALREADY_OK_COUNT + 1))
        rm "$script.bak"
        continue
    fi

    # Step 1: Add sourcing of virtos-common.sh after shebang if not present
    if ! grep -q 'virtos-common.sh' "$script"; then
        echo "  + Adding virtos-common.sh sourcing"

        # Create temp file with sourcing added after initial comments
        awk '
        BEGIN { added = 0 }
        /^#!/ { print; next }
        /^#/ && !added { print; next }
        !added {
            print "# Load common library"
            print "if [ -f /usr/local/lib/virtos-common.sh ]; then"
            print "    . /usr/local/lib/virtos-common.sh"
            print "elif [ -f \"$(dirname \"$(dirname \"$(dirname \"$(readlink -f \"$0\")\")\")\")/lib/virtos-common.sh\" ]; then"
            print "    . \"$(dirname \"$(dirname \"$(dirname \"$(readlink -f \"$0\")\")\")\")/lib/virtos-common.sh\""
            print "fi"
            print ""
            added = 1
            print
            next
        }
        { print }
        ' "$script" >"$script.tmp"

        mv "$script.tmp" "$script"
    fi

    # Step 2: Replace hardcoded VERSION= with get_version()
    if grep -q '^VERSION=' "$script"; then
        echo "  + Replacing hardcoded VERSION"
        sed -i 's/^VERSION=.*/VERSION=$(get_version)/' "$script"
    elif ! grep -q '^VERSION=' "$script" && ! grep -q 'VERSION=$(get_version)' "$script"; then
        echo "  + Adding VERSION=$(get_version)"
        # Add after sourcing virtos-common.sh
        awk '
        /virtos-common.sh/ { in_source = 1 }
        in_source && /^fi/ { print; print ""; print "VERSION=$(get_version)"; in_source = 0; next }
        { print }
        ' "$script" >"$script.tmp"
        mv "$script.tmp" "$script"
    fi

    # Step 3: Add --version flag if not present
    if ! grep -q '\-\-version' "$script"; then
        echo "  + Adding --version flag handling"

        # Find where case/if statements start for argument parsing
        # This is complex and script-specific, so we'll add it before the main logic
        # Look for common patterns like "case" or "while getopts"

        if grep -q 'case.*in' "$script"; then
            # Add --version to existing case statement
            sed -i '/case.*in/a\    -v|--version)\n        echo "'"$script"' version $VERSION"\n        exit 0\n        ;;' "$script"
        else
            # Add argument parsing before main logic
            # Find first non-comment, non-empty line after VERSION
            awk '
            /^VERSION=/ { found_version = 1; print; next }
            found_version && !added && /^[^#]/ && NF > 0 {
                print ""
                print "# Handle command-line arguments"
                print "case \"${1:-}\" in"
                print "    -v|--version)"
                print "        echo \"'"$script"' version $VERSION\""
                print "        exit 0"
                print "        ;;"
                print "esac"
                print ""
                added = 1
            }
            { print }
            ' "$script" >"$script.tmp"
            mv "$script.tmp" "$script"
        fi
    fi

    # Verify the script still has valid syntax
    if bash -n "$script" 2>/dev/null; then
        echo "  ✓ Updated successfully"
        UPDATED_COUNT=$((UPDATED_COUNT + 1))
        rm "$script.bak"
    else
        echo "  ✗ Syntax error after update, restoring backup"
        mv "$script.bak" "$script"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
done

echo ""
echo "=== Update Summary ==="
echo "Updated:         $UPDATED_COUNT scripts"
echo "Already correct: $ALREADY_OK_COUNT scripts"
echo "Errors:          $ERROR_COUNT scripts"
echo ""

if [ $ERROR_COUNT -gt 0 ]; then
    echo "⚠️ Some scripts had errors and were not updated"
    exit 1
fi

echo "✅ All scripts processed successfully"
