bats_load_library "bats-support"
bats_load_library "bats-assert"

function setup_file() {}

@test "should fail when requested" {
    ../lint.sh --fail-on-violation //src:all
    assert_success
}
