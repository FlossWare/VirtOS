# VirtOS Makefile
# Convenience targets for common build operations

.PHONY: help validate test quick-test packages clean clean-all build iso check pin-checksums verify-checksums

# Default target
all: packages

help:
	@echo "VirtOS Build System"
	@echo "==================="
	@echo ""
	@echo "Quick Commands:"
	@echo "  make validate    - Validate build environment"
	@echo "  make test        - Run quick validation tests"
	@echo "  make packages    - Build all TCZ packages"
	@echo "  make build       - Build complete ISO (downloads ~500MB)"
	@echo "  make check       - Check script syntax"
	@echo "  make clean       - Clean build artifacts"
	@echo ""
	@echo "Reproducibility:"
	@echo "  make pin-checksums     - Pin SHA256 hashes for downloaded artifacts"
	@echo "  make verify-checksums  - Verify downloads against pinned hashes"
	@echo ""
	@echo "Detailed Commands:"
	@echo "  make validate    - Check prerequisites and configuration"
	@echo "  make quick-test  - Fast 5-second validation"
	@echo "  make packages    - Build virtos-tools.tcz and all packages"
	@echo "  make iso         - Build complete bootable ISO image"
	@echo "  make clean       - Remove build outputs"
	@echo "  make clean-all   - Remove all build artifacts and downloads"
	@echo ""
	@echo "Development:"
	@echo "  make check       - Run syntax checks on all scripts"
	@echo ""
	@echo "See BUILD.md for detailed build guide"

# Validate build environment
validate:
	@echo "Validating build environment..."
	@cd build/scripts && ./validate-build.sh

# Quick test (fast validation)
quick-test test:
	@echo "Running quick tests..."
	@build/scripts/quick-test.sh

# Build packages
packages:
	@echo "Building packages..."
	@cd packages && ./build-all.sh
	@echo ""
	@echo "✓ Packages built successfully!"
	@echo "Output: packages/output/"
	@ls -lh packages/output/*.tcz

# Build full ISO
build iso:
	@echo "Building VirtOS ISO..."
	@echo "This will download ~500MB of Tiny Core Linux"
	@read -p "Continue? [y/N] " confirm && \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		cd build/scripts && ./build-all.sh; \
	else \
		echo "Build cancelled"; \
		exit 1; \
	fi

# Syntax checking
check:
	@echo "Checking script syntax..."
	@errors=0; \
	for script in build/scripts/*.sh; do \
		if ! bash -n "$$script" 2>/dev/null; then \
			echo "✗ $$script has syntax errors"; \
			errors=$$((errors + 1)); \
		fi; \
	done; \
	for script in config/custom-scripts/virtos-*; do \
		if [ -f "$$script" ] && [ -x "$$script" ]; then \
			if ! bash -n "$$script" 2>/dev/null; then \
				echo "✗ $$script has syntax errors"; \
				errors=$$((errors + 1)); \
			fi; \
		fi; \
	done; \
	if [ $$errors -eq 0 ]; then \
		echo "✓ All scripts have valid syntax"; \
		exit 0; \
	else \
		echo "✗ Found $$errors scripts with syntax errors"; \
		exit 1; \
	fi

# Clean build outputs
clean:
	@echo "Cleaning build outputs..."
	@rm -rf packages/output/*
	@rm -rf packages/virtos-tools/*.tcz*
	@rm -rf packages/virtos-tools/src
	@rm -f build/output/*.iso*
	@echo "✓ Build outputs cleaned"

# Clean everything including downloads
clean-all: clean
	@echo "Cleaning all build artifacts..."
	@rm -rf build/workspace
	@rm -rf build/downloads
	@echo "✓ All build artifacts cleaned"
	@echo "Note: Next build will re-download Tiny Core Linux"

# Install build dependencies (system-specific)
install-deps-fedora:
	@echo "Installing build dependencies for Fedora..."
	sudo dnf install -y squashfs-tools genisoimage syslinux wget cpio gzip qemu-kvm

install-deps-ubuntu:
	@echo "Installing build dependencies for Ubuntu/Debian..."
	sudo apt install -y squashfs-tools genisoimage syslinux-utils wget cpio gzip qemu-kvm

install-deps-arch:
	@echo "Installing build dependencies for Arch Linux..."
	sudo pacman -S --needed squashfs-tools cdrtools syslinux wget cpio gzip qemu

# Show project statistics
stats:
	@echo "VirtOS Project Statistics"
	@echo "========================="
	@echo ""
	@echo "Documentation:"
	@find docs -name "*.md" -type f | wc -l | xargs echo "  Markdown files:"
	@cat docs/*.md README.md BUILD.md TESTING.md CONTRIBUTING.md 2>/dev/null | wc -l | xargs echo "  Total lines:"
	@echo ""
	@echo "Scripts:"
	@find config/custom-scripts -name "virtos-*" -type f -executable | wc -l | xargs echo "  Management scripts:"
	@find build/scripts -name "*.sh" -type f | wc -l | xargs echo "  Build scripts:"
	@echo ""
	@echo "Packages:"
	@find packages -name "*.tcz" -type f 2>/dev/null | wc -l | xargs echo "  Built packages:"
	@if [ -d packages/output ]; then \
		du -sh packages/output 2>/dev/null | cut -f1 | xargs echo "  Package size:"; \
	fi
	@echo ""
	@echo "Git:"
	@git log --oneline | wc -l | xargs echo "  Total commits:"
	@git log --oneline --since="1 week ago" | wc -l | xargs echo "  Commits (last week):"

# Development helpers
dev-setup:
	@echo "Setting up development environment..."
	@echo "Installing git hooks..."
	@mkdir -p .git/hooks
	@echo '#!/bin/bash' > .git/hooks/pre-commit
	@echo 'make check' >> .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "✓ Git hooks installed (will run syntax checks before commit)"
	@echo ""
	@echo "Consider installing:"
	@echo "  - shellcheck (shell script linter)"
	@echo "  - qemu-kvm (for testing ISOs)"
	@echo "  - docker (for container testing)"

# Pin checksums for reproducible builds
pin-checksums:
	@echo "Pinning SHA256 checksums for downloaded artifacts..."
	@build/scripts/pin-checksums.sh

# Verify downloads against pinned checksums
verify-checksums:
	@echo "Verifying downloads against pinned checksums..."
	@build/scripts/pin-checksums.sh --verify-only

# Run all validation checks
verify: check test
	@echo ""
	@echo "✓ All verification checks passed!"
