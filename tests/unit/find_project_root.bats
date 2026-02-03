#!/usr/bin/env bats

load "../helpers/test_helper"

setup() {
    setup_temp_dirs
}

teardown() {
    teardown_temp_dirs
}

@test "find_project_root: finds product-development/features at current dir" {
    mkdir -p "$FAKE_PROJECT_ROOT/product-development/features"
    cd "$FAKE_PROJECT_ROOT"

    run find_project_root
    assert_success
    assert_output "$FAKE_PROJECT_ROOT"
}

@test "find_project_root: finds it in parent dir" {
    mkdir -p "$FAKE_PROJECT_ROOT/product-development/features"
    mkdir -p "$FAKE_PROJECT_ROOT/subdir"
    cd "$FAKE_PROJECT_ROOT/subdir"

    run find_project_root
    assert_success
    assert_output "$FAKE_PROJECT_ROOT"
}

@test "find_project_root: finds it two levels up" {
    mkdir -p "$FAKE_PROJECT_ROOT/product-development/features"
    mkdir -p "$FAKE_PROJECT_ROOT/a/b"
    cd "$FAKE_PROJECT_ROOT/a/b"

    run find_project_root
    assert_success
    assert_output "$FAKE_PROJECT_ROOT"
}

@test "find_project_root: returns exit 1 when not found" {
    cd "$TEST_TEMP_DIR"

    run find_project_root
    assert_failure
}
