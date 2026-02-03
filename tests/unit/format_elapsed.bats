#!/usr/bin/env bats

load "../helpers/test_helper"

@test "format_elapsed: 0 seconds" {
    result="$(format_elapsed 0)"
    assert_equal "$result" "0s"
}

@test "format_elapsed: 45 seconds" {
    result="$(format_elapsed 45)"
    assert_equal "$result" "45s"
}

@test "format_elapsed: 59 seconds (boundary)" {
    result="$(format_elapsed 59)"
    assert_equal "$result" "59s"
}

@test "format_elapsed: 60 seconds becomes 1m 0s" {
    result="$(format_elapsed 60)"
    assert_equal "$result" "1m 0s"
}

@test "format_elapsed: 125 seconds becomes 2m 5s" {
    result="$(format_elapsed 125)"
    assert_equal "$result" "2m 5s"
}

@test "format_elapsed: 3600 seconds becomes 1h 0m 0s" {
    result="$(format_elapsed 3600)"
    assert_equal "$result" "1h 0m 0s"
}

@test "format_elapsed: 3661 seconds becomes 1h 1m 1s" {
    result="$(format_elapsed 3661)"
    assert_equal "$result" "1h 1m 1s"
}
