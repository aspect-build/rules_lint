bats_load_library "bats-support"
bats_load_library "bats-assert"

@test "should produce reports" {
    run aspect lint //src:example
    assert_success
    # The terraform plugin's recommended preset flags missing version constraints
    assert_output --partial "terraform_required_providers"
    # The google plugin flags the invalid machine type
    assert_output --partial "google_compute_instance_invalid_machine_type"
}
