#!/bin/bash
# shellcheck disable=SC2001,SC2004,SC2016,SC2027,SC2034,SC2046,SC2050,SC2064,SC2140,SC2144,SC2155
# Exit on any error
set -e

# --- Security: Path Validation ---
# Validate that a file path is within the expected directory structure
# to prevent path traversal attacks
validate_package_path() {
    local file_path="$1"
    local repo_root
    repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    # Get canonical path (resolves symlinks, removes ..)
    local canonical_path
    canonical_path="$(readlink -f "$file_path" 2>/dev/null || echo "")"

    # Ensure file exists and is within repo
    if [ -z "$canonical_path" ] || [ ! -f "$canonical_path" ]; then
        echo "ERROR: Invalid package path: $file_path" >&2
        return 1
    fi

    # Check if canonical path starts with repo root
    if [[ "$canonical_path" != "$repo_root/packages/"* ]]; then
        echo "ERROR: Path outside packages directory: $file_path" >&2
        return 1
    fi

    # Ensure it's a .tcz.info file
    if [[ "$canonical_path" != *.tcz.info ]]; then
        echo "ERROR: Not a .tcz.info file: $file_path" >&2
        return 1
    fi

    return 0
}

# --- CI Identity Setup ---
# Required for clean CI environments to allow git commits
git config user.name "FlossWare CI"
git config user.email "ci@flossware.org"

# --- Versioning Logic ---
# Extract current version from VERSION file (the single point of truth)
CURRENT_VERSION="$(cat VERSION)"

# Parse X.Y format
MAJOR="$(echo "${CURRENT_VERSION}" | cut -d. -f1)"
MINOR="$(echo "${CURRENT_VERSION}" | cut -d. -f2)"

# Increment the minor version
NEXT_MINOR="$((${MINOR} + 1))"
NEXT_VERSION="${MAJOR}.${NEXT_MINOR}"

echo "Reving version from ${CURRENT_VERSION} to ${NEXT_VERSION}..."

# Update the VERSION file
echo "${NEXT_VERSION}" >VERSION

# Update package info files
for info_file in packages/*/virtos-*.tcz.info; do
    if [ -f "$info_file" ]; then
        # Validate path before processing
        if ! validate_package_path "$info_file"; then
            echo "Skipping invalid path: $info_file" >&2
            continue
        fi
        sed -i "s/Version:.*/Version:        ${NEXT_VERSION}/" "$info_file"
        echo "Updated $(basename "$info_file")"
    fi
done

# --- Git Lifecycle ---
# Capture the branch name to ensure we push back to the correct place
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

echo "Committing version change to ${CURRENT_BRANCH}..."
git add VERSION packages/*/virtos-*.tcz.info
# [ci skip] prevents the version bump from triggering another build cycle
git commit -m "chore: bump version to ${NEXT_VERSION} [ci skip]"

echo "Creating tag v${NEXT_VERSION}..."
git tag -a "v${NEXT_VERSION}" -m "Release version ${NEXT_VERSION}"

echo "Pushing changes and tags to origin..."
git push origin "${CURRENT_BRANCH}"
git push origin "v${NEXT_VERSION}"

echo "CI/CD Lifecycle complete for VirtOS ${NEXT_VERSION}"
