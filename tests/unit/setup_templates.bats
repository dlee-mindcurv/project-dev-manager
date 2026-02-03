#!/usr/bin/env bats

load "../helpers/test_helper"

setup() {
    setup_temp_dirs
}

teardown() {
    teardown_temp_dirs
}

@test "setup_jtbd_template: creates template in new directory" {
    local resources_dir="$TEST_TEMP_DIR/resources"
    setup_jtbd_template "$resources_dir"

    assert [ -f "$resources_dir/JTBD-template.md" ]
    run cat "$resources_dir/JTBD-template.md"
    assert_output --partial "Jobs-to-be-Done Analysis"
}

@test "setup_prd_template: creates template in new directory" {
    local resources_dir="$TEST_TEMP_DIR/resources"
    setup_prd_template "$resources_dir"

    assert [ -f "$resources_dir/PRD-template.md" ]
    run cat "$resources_dir/PRD-template.md"
    assert_output --partial "PRD:"
}

@test "setup_jtbd_template: skips if template already exists (idempotent)" {
    local resources_dir="$TEST_TEMP_DIR/resources"
    mkdir -p "$resources_dir"
    echo "existing content" > "$resources_dir/JTBD-template.md"

    setup_jtbd_template "$resources_dir"

    result="$(cat "$resources_dir/JTBD-template.md")"
    assert_equal "$result" "existing content"
}

@test "setup_prd_template: does not overwrite existing content" {
    local resources_dir="$TEST_TEMP_DIR/resources"
    mkdir -p "$resources_dir"
    echo "my custom PRD" > "$resources_dir/PRD-template.md"

    setup_prd_template "$resources_dir"

    result="$(cat "$resources_dir/PRD-template.md")"
    assert_equal "$result" "my custom PRD"
}
