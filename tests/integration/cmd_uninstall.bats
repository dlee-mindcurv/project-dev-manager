#!/usr/bin/env bats

load "../helpers/test_helper"

setup() {
    setup_temp_dirs
}

teardown() {
    teardown_temp_dirs
}

@test "cmd_uninstall: removes pdm-* skills and commands" {
    mkdir -p "$SKILLS_DIR/pdm-ralph"
    mkdir -p "$SKILLS_DIR/pdm-review"
    touch "$COMMANDS_DIR/pdm-create-prd.md"

    run cmd_uninstall
    assert_success

    assert [ ! -d "$SKILLS_DIR/pdm-ralph" ]
    assert [ ! -d "$SKILLS_DIR/pdm-review" ]
    assert [ ! -f "$COMMANDS_DIR/pdm-create-prd.md" ]
}

@test "cmd_uninstall: does not remove non-pdm items" {
    mkdir -p "$SKILLS_DIR/pdm-ralph"
    mkdir -p "$SKILLS_DIR/other-skill"
    touch "$COMMANDS_DIR/pdm-review.md"
    touch "$COMMANDS_DIR/something-else.md"

    run cmd_uninstall
    assert_success

    assert [ ! -d "$SKILLS_DIR/pdm-ralph" ]
    assert [ -d "$SKILLS_DIR/other-skill" ]
    assert [ ! -f "$COMMANDS_DIR/pdm-review.md" ]
    assert [ -f "$COMMANDS_DIR/something-else.md" ]
}

@test "cmd_uninstall: no-op when nothing installed" {
    run cmd_uninstall
    assert_success
    assert_output --partial "Uninstall complete"
}
