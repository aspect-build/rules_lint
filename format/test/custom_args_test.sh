#!/usr/bin/env bash

# Test script to verify that custom arguments are correctly embedded in generated multirun configuration

set -o nounset -o errexit -o pipefail

echo "Testing custom arguments in generated multirun configuration..."

check_flags() {
    local script_name="$1"
    local expected_flags="$2"
    local description="$3"
    
    script_path="$(rlocation "_main/format/test/$script_name")"
    if [[ ! -f "$script_path" ]]; then
        echo "✗ $description: script not found"
        exit 1
    fi
    
    if grep -q "export flags='$expected_flags'" "$script_path"; then
        echo "✓ $description"
    else
        echo "✗ $description"
        exit 1
    fi
}

# Test custom arguments work
check_flags "format_with_custom_args_Kotlin_with_ktfmt.bash" "--custom-fix --flag" "Kotlin fix mode has custom arguments"
check_flags "format_with_custom_args_Kotlin_with_ktfmt.check.bash" "--custom-check" "Kotlin check mode has custom arguments"

# Test default arguments used when no custom specified
check_flags "format_with_custom_args_Java_with_java-format.check.bash" "--set-exit-if-changed --dry-run" "Java check mode uses default arguments"

echo "All custom arguments tests passed!"