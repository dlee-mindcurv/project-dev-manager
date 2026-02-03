#!/usr/bin/env bats

load "../helpers/test_helper"

setup() {
    setup_temp_dirs
}

teardown() {
    teardown_temp_dirs
}

@test "cmd_list: no items shows (none)" {
    run cmd_list
    assert_success
    assert_output --partial "(none)"
}

@test "cmd_list: skills installed lists them" {
    mkdir -p "$SKILLS_DIR/pdm-ralph"
    mkdir -p "$SKILLS_DIR/pdm-review"

    run cmd_list
    assert_success
    assert_output --partial "pdm-ralph"
    assert_output --partial "pdm-review"
}

@test "cmd_list: commands installed lists them with / prefix" {
    touch "$COMMANDS_DIR/pdm-create-prd.md"
    touch "$COMMANDS_DIR/pdm-create-jtbd.md"

    run cmd_list
    assert_success
    assert_output --partial "/pdm-create-prd"
    assert_output --partial "/pdm-create-jtbd"
}

@test "cmd_list: only shows pdm-* items, ignores others" {
    mkdir -p "$SKILLS_DIR/pdm-ralph"
    mkdir -p "$SKILLS_DIR/other-skill"
    touch "$COMMANDS_DIR/pdm-review.md"
    touch "$COMMANDS_DIR/something-else.md"

    run cmd_list
    assert_success
    assert_output --partial "pdm-ralph"
    assert_output --partial "/pdm-review"
    refute_output --partial "other-skill"
    refute_output --partial "something-else"
}
