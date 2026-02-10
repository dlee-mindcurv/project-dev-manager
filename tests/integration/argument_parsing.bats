#!/usr/bin/env bats

load "../helpers/test_helper"

PDM="$PROJECT_ROOT/pdm"

@test "argument_parsing: --version prints version string" {
    run bash "$PDM" --version
    assert_success
    assert_output --partial "pdm version"
}

@test "argument_parsing: -v prints version string" {
    run bash "$PDM" -v
    assert_success
    assert_output --partial "pdm version"
}

@test "argument_parsing: --help shows usage text" {
    run bash "$PDM" --help
    assert_success
    assert_output --partial "Usage: pdm"
}

@test "argument_parsing: -h shows usage text" {
    run bash "$PDM" -h
    assert_success
    assert_output --partial "Usage: pdm"
}

@test "argument_parsing: no arguments shows usage" {
    run bash "$PDM"
    assert_success
    assert_output --partial "Usage: pdm"
}

@test "argument_parsing: unknown flag exits with error" {
    run bash "$PDM" --nonexistent
    assert_failure
    assert_output --partial "Error: Unknown option"
}

@test "argument_parsing: --create-workspace shows error without feature ID" {
    run bash "$PDM" --create-workspace
    assert_failure
}

@test "argument_parsing: --list-workspaces is recognized (no error)" {
    # list-workspaces with no product-development dir will show "No workspaces"
    # or error about project root - either way it should not say "Unknown option"
    run bash "$PDM" --list-workspaces
    refute_output --partial "Error: Unknown option"
}

@test "argument_parsing: --complete-feature shows error without feature ID" {
    run bash "$PDM" --complete-feature
    assert_failure
}

@test "argument_parsing: --cleanup-workspace shows error without feature ID" {
    run bash "$PDM" --cleanup-workspace
    assert_failure
}

@test "argument_parsing: --help output includes Workspace Commands section" {
    run bash "$PDM" --help
    assert_success
    assert_output --partial "Workspace Commands"
}
