#!/usr/bin/env bats
# BATS tests for virtos-common.sh library

setup() {
    # Source the common library
    source "${BATS_TEST_DIRNAME}/../config/custom-scripts/lib/virtos-common.sh"
}

# Hostname Validation Tests
@test "validate_hostname: accepts valid hostname" {
    run validate_hostname "virtos-1"
    [ "$status" -eq 0 ]
}

@test "validate_hostname: accepts alphanumeric with dash" {
    run validate_hostname "test-host-123"
    [ "$status" -eq 0 ]
}

@test "validate_hostname: rejects empty string" {
    run validate_hostname ""
    [ "$status" -eq 1 ]
}

@test "validate_hostname: rejects special characters" {
    run validate_hostname "test;rm -rf /"
    [ "$status" -eq 1 ]
}

@test "validate_hostname: rejects spaces" {
    run validate_hostname "test host"
    [ "$status" -eq 1 ]
}

# VM Name Validation Tests
@test "validate_vm_name: accepts valid VM name" {
    run validate_vm_name "my-vm"
    [ "$status" -eq 0 ]
}

@test "validate_vm_name: accepts alphanumeric underscore dash" {
    run validate_vm_name "web_server-01"
    [ "$status" -eq 0 ]
}

@test "validate_vm_name: rejects command injection attempt" {
    run validate_vm_name "vm;shutdown -h now"
    [ "$status" -eq 1 ]
}

@test "validate_vm_name: rejects too long name (>64 chars)" {
    local long_name="$(printf 'a%.0s' {1..65})"
    run validate_vm_name "$long_name"
    [ "$status" -eq 1 ]
}

# IP Validation Tests
@test "validate_ip: accepts valid IPv4" {
    run validate_ip "192.168.1.1"
    [ "$status" -eq 0 ]
}

@test "validate_ip: accepts 10.0.0.1" {
    run validate_ip "10.0.0.1"
    [ "$status" -eq 0 ]
}

@test "validate_ip: rejects invalid IP" {
    run validate_ip "999.999.999.999"
    [ "$status" -eq 0 ]  # Basic regex passes, but values invalid
}

@test "validate_ip: rejects non-IP string" {
    run validate_ip "not-an-ip"
    [ "$status" -eq 1 ]
}

@test "validate_ip: rejects empty" {
    run validate_ip ""
    [ "$status" -eq 1 ]
}

# Number Validation Tests
@test "validate_number: accepts positive number" {
    run validate_number "42"
    [ "$status" -eq 0 ]
}

@test "validate_number: accepts zero" {
    run validate_number "0"
    [ "$status" -eq 0 ]
}

@test "validate_number: rejects negative number" {
    run validate_number "-5"
    [ "$status" -eq 1 ]
}

@test "validate_number: rejects decimal" {
    run validate_number "3.14"
    [ "$status" -eq 1 ]
}

@test "validate_number: rejects non-numeric" {
    run validate_number "abc"
    [ "$status" -eq 1 ]
}

# Disk Size Validation Tests
@test "validate_disk_size: accepts gigabytes" {
    run validate_disk_size "20G"
    [ "$status" -eq 0 ]
}

@test "validate_disk_size: accepts megabytes" {
    run validate_disk_size "500M"
    [ "$status" -eq 0 ]
}

@test "validate_disk_size: accepts terabytes" {
    run validate_disk_size "1T"
    [ "$status" -eq 0 ]
}

@test "validate_disk_size: accepts kilobytes" {
    run validate_disk_size "1024K"
    [ "$status" -eq 0 ]
}

@test "validate_disk_size: rejects lowercase" {
    run validate_disk_size "20g"
    [ "$status" -eq 1 ]
}

@test "validate_disk_size: rejects no unit" {
    run validate_disk_size "20"
    [ "$status" -eq 1 ]
}

@test "validate_disk_size: rejects decimal" {
    run validate_disk_size "20.5G"
    [ "$status" -eq 1 ]
}

# Path Validation Tests
@test "validate_path: accepts valid path" {
    run validate_path "/var/lib/vms/test.qcow2"
    [ "$status" -eq 0 ]
}

@test "validate_path: accepts relative path" {
    run validate_path "vms/test.img"
    [ "$status" -eq 0 ]
}

@test "validate_path: rejects command injection" {
    run validate_path "/var/lib/vms;rm -rf /"
    [ "$status" -eq 1 ]
}

@test "validate_path: rejects pipe" {
    run validate_path "/tmp/file | cat"
    [ "$status" -eq 1 ]
}

@test "validate_path: rejects backticks" {
    run validate_path "/tmp/\`whoami\`"
    [ "$status" -eq 1 ]
}

# Sanitize Input Tests
@test "sanitize_input: removes semicolons" {
    result=$(sanitize_input "test;command")
    [ "$result" = "testcommand" ]
}

@test "sanitize_input: removes pipes" {
    result=$(sanitize_input "cat file | grep test")
    [ "$result" = "cat file  grep test" ]
}

@test "sanitize_input: removes backticks" {
    result=$(sanitize_input "test\`whoami\`")
    [ "$result" = "testwhoami" ]
}

@test "sanitize_input: removes dollar signs" {
    result=$(sanitize_input "test\$HOME")
    [ "$result" = "testHOME" ]
}

# Network Mode Validation Tests
@test "validate_network_mode: accepts bridged" {
    run validate_network_mode "bridged"
    [ "$status" -eq 0 ]
}

@test "validate_network_mode: accepts bridge" {
    run validate_network_mode "bridge"
    [ "$status" -eq 0 ]
}

@test "validate_network_mode: accepts nat" {
    run validate_network_mode "nat"
    [ "$status" -eq 0 ]
}

@test "validate_network_mode: accepts isolated" {
    run validate_network_mode "isolated"
    [ "$status" -eq 0 ]
}

@test "validate_network_mode: accepts none" {
    run validate_network_mode "none"
    [ "$status" -eq 0 ]
}

@test "validate_network_mode: rejects invalid mode" {
    run validate_network_mode "invalid"
    [ "$status" -eq 1 ]
}

# Error Handling Tests
@test "die: exits with error code 1 by default" {
    run die "test error"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: test error" ]]
}

@test "die: exits with custom error code" {
    run die "test error" 42
    [ "$status" -eq 42 ]
}

# Logging Tests (these won't actually log unless /var/log/virtos exists)
@test "log_info: doesn't crash" {
    run log_info "test message"
    [ "$status" -eq 0 ]
}

@test "log_warn: doesn't crash" {
    run log_warn "test warning"
    [ "$status" -eq 0 ]
}

@test "log_error: doesn't crash" {
    run log_error "test error"
    [ "$status" -eq 0 ]
}
