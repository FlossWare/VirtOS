#!/usr/bin/env bats
# Security tests for credential storage vulnerability (Issue #241)

DEVOPS_PATH="../config/custom-scripts/virtos-devops"
SECRETS_PATH="../config/custom-scripts/virtos-secrets"

setup() {
    :
}

@test "virtos-secrets protects Vault credentials with chmod 600" {
    # Should set chmod 600 on vault-init.txt
    grep -A2 "vault operator init.*vault-init.txt" "$SECRETS_PATH" | grep -q "chmod 600"
}

@test "virtos-secrets sets ownership on Vault credentials" {
    # Should set ownership to root:root
    grep -A3 "vault operator init.*vault-init.txt" "$SECRETS_PATH" | grep -q "chown root:root"
}

@test "virtos-devops does not save ArgoCD password to file" {
    # Should NOT write password to file
    ! grep -E 'echo.*admin_pass.*argocd-admin-password\.txt' "$DEVOPS_PATH"
}

@test "virtos-devops displays ArgoCD password to user" {
    # Should echo password to stdout for user to save
    grep -q 'echo.*Password:.*admin_pass' "$DEVOPS_PATH"
}

@test "virtos-devops includes security warning for ArgoCD" {
    # Should warn user to change password
    grep -q "SECURITY WARNING" "$DEVOPS_PATH"
    grep -q "Change this password immediately" "$DEVOPS_PATH"
}

@test "virtos-devops does not save Jenkins password to file" {
    # Should NOT write Jenkins password to file
    ! grep -E 'echo.*jenkins_pass.*jenkins-admin-password\.txt' "$DEVOPS_PATH"
}

@test "virtos-devops displays Jenkins password to user" {
    # Should echo Jenkins password to stdout
    grep -q 'echo.*Password:.*jenkins_pass' "$DEVOPS_PATH"
}

@test "virtos-secrets warns user about Vault credential backup" {
    # Should include warning about secure backup
    grep -q "IMPORTANT\|WARNING" "$SECRETS_PATH"
}

@test "virtos-devops config and package files are synchronized" {
    PACKAGE_DEVOPS="../packages/virtos-tools/src/usr/local/bin/virtos-devops"
    if [ -f "$PACKAGE_DEVOPS" ] && [ -f "$DEVOPS_PATH" ]; then
        diff -q "$PACKAGE_DEVOPS" "$DEVOPS_PATH"
    else
        skip "One or both virtos-devops files not found"
    fi
}

@test "virtos-secrets config and package files are synchronized" {
    PACKAGE_SECRETS="../packages/virtos-tools/src/usr/local/bin/virtos-secrets"
    if [ -f "$PACKAGE_SECRETS" ] && [ -f "$SECRETS_PATH" ]; then
        diff -q "$PACKAGE_SECRETS" "$SECRETS_PATH"
    else
        skip "One or both virtos-secrets files not found"
    fi
}
