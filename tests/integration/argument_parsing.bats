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
