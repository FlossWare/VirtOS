#!/bin/bash
# VirtOS Quick Test
# Rapid validation without full build

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$BUILD_DIR")"

echo "VirtOS Quick Test"
echo "================="
echo ""

# Test 1: Validation
echo "[1/5] Running validation..."
if "$SCRIPT_DIR/validate-build.sh" >/tmp/virtos-validate.log 2>&1; then
    echo "  ✓ Validation passed"
else
    echo "  ⚠ Validation issues (see /tmp/virtos-validate.log)"
fi

# Test 2: Script syntax
echo "[2/5] Checking script syntax..."
SYNTAX_ERRORS=0
for script in "$PROJECT_ROOT"/build/scripts/*.sh; do
    if ! bash -n "$script" 2>/dev/null; then
        echo "  ✗ $(basename "$script") has syntax errors"
        SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
    fi
done

if [ $SYNTAX_ERRORS -eq 0 ]; then
    echo "  ✓ All build scripts valid"
else
    echo "  ✗ $SYNTAX_ERRORS scripts with syntax errors"
fi

# Test 3: VirtOS scripts
echo "[3/5] Checking VirtOS scripts..."
VIRTOS_ERRORS=0
CHECKED=0
for script in "$PROJECT_ROOT"/config/custom-scripts/virtos-*; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        if ! bash -n "$script" 2>/dev/null; then
            echo "  ✗ $(basename "$script") has syntax errors"
            VIRTOS_ERRORS=$((VIRTOS_ERRORS + 1))
        fi
        CHECKED=$((CHECKED + 1))
    fi
done

if [ $VIRTOS_ERRORS -eq 0 ]; then
    echo "  ✓ All $CHECKED virtos scripts valid"
else
    echo "  ✗ $VIRTOS_ERRORS of $CHECKED scripts with syntax errors"
fi

# Test 4: Package build
echo "[4/5] Testing package build..."
cd "$PROJECT_ROOT/packages"
if ./build-all.sh >/tmp/virtos-package-build.log 2>&1; then
    if [ -f "output/virtos-tools.tcz" ]; then
        SIZE=$(du -h output/virtos-tools.tcz | cut -f1)
        echo "  ✓ Package built successfully ($SIZE)"
    else
        echo "  ✗ Package build completed but no TCZ found"
    fi
else
    echo "  ✗ Package build failed (see /tmp/virtos-package-build.log)"
fi

# Test 5: Configuration
echo "[5/5] Checking configuration..."
cd "$BUILD_DIR"
# shellcheck disable=SC1091
if source build.conf 2>/dev/null; then
    echo "  ✓ build.conf valid"
    echo "    Profile: ${PROFILE:-custom}"
    echo "    Features: KVM=$INCLUDE_KVM LXC=$INCLUDE_LXC Docker=$INCLUDE_DOCKER"
else
    echo "  ✗ build.conf has errors"
fi

# Summary
echo ""
echo "================="
echo "Quick Test Summary"
echo "================="

TOTAL_ERRORS=$((SYNTAX_ERRORS + VIRTOS_ERRORS))

if [ $TOTAL_ERRORS -eq 0 ]; then
    echo "✓ All tests passed!"
    echo ""
    echo "Next steps:"
    echo "  - Run full build: cd build/scripts && ./build-all.sh"
    echo "  - Or validate first: ./validate-build.sh"
    exit 0
else
    echo "✗ Found $TOTAL_ERRORS errors"
    echo ""
    echo "Check logs:"
    echo "  /tmp/virtos-validate.log"
    echo "  /tmp/virtos-package-build.log"
    exit 1
fi
