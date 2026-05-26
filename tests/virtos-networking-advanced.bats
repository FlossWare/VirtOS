#!/usr/bin/env bats
# Unit tests for virtos-networking-advanced (Advanced networking features)

# Load test helpers
load test_helper 2>/dev/null || true

SCRIPT_PATH="../config/custom-scripts/virtos-networking-advanced"

setup() {
    # Skip if virtos-networking-advanced not available
    if [ ! -f "$SCRIPT_PATH" ]; then
        skip "virtos-networking-advanced script not found"
    fi
}

@test "virtos-networking-advanced exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "virtos-networking-advanced shows usage with no arguments" {
    run "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-networking-advanced --help shows usage" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "virtos-networking-advanced --version shows version" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-networking-advanced help shows networking commands" {
    run "$SCRIPT_PATH" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "sdn" ]] || [[ "$output" =~ "Commands:" ]]
}

@test "virtos-networking-advanced sdn-create requires network name" {
    skip "Requires SDN backend"
    run "$SCRIPT_PATH" sdn-create
    [ "$status" -ne 0 ]
}

@test "virtos-networking-advanced ovn-configure command exists" {
    skip "Requires OVN configuration"
    run "$SCRIPT_PATH" ovn-configure
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "virtos-networking-advanced vpn-create requires VPN name" {
    skip "Requires VPN backend"
    run "$SCRIPT_PATH" vpn-create
    [ "$status" -ne 0 ]
}

@test "virtos-networking-advanced load-balancer requires LB name" {
    skip "Requires load balancer backend"
    run "$SCRIPT_PATH" load-balancer
    [ "$status" -ne 0 ]
}

@test "virtos-networking-advanced advanced networking workflow (placeholder)" {
    skip "Requires SDN/OVN backend and permissions"
    # Full workflow test would:
    # 1. Configure SDN
    # 2. Create virtual networks
    # 3. Set up VPN
    # 4. Configure load balancer
    # 5. Verify traffic routing
    # 6. Clean up
}
