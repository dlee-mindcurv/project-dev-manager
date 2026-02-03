#!/usr/bin/env bats

load "../helpers/test_helper"

@test "generate_feature_id: converts mixed case to lowercase with hyphens" {
    result="$(generate_feature_id "My Feature")"
    assert_equal "$result" "my-feature"
}

@test "generate_feature_id: already lowercase with hyphens passes through" {
    result="$(generate_feature_id "dark-mode")"
    assert_equal "$result" "dark-mode"
}

@test "generate_feature_id: multiple spaces become hyphens" {
    result="$(generate_feature_id "My Big Feature")"
    assert_equal "$result" "my-big-feature"
}

@test "generate_feature_id: preserves numbers" {
    result="$(generate_feature_id "Feature 2 Test")"
    assert_equal "$result" "feature-2-test"
}

@test "generate_feature_id: strips special characters" {
    result="$(generate_feature_id 'My Feature!@#')"
    assert_equal "$result" "my-feature"
}

@test "generate_feature_id: single word" {
    result="$(generate_feature_id "Dashboard")"
    assert_equal "$result" "dashboard"
}

@test "generate_feature_id: empty string returns empty" {
    result="$(generate_feature_id "")"
    assert_equal "$result" ""
}

@test "generate_feature_id: underscores are stripped (documents current behavior)" {
    result="$(generate_feature_id "my_feature")"
    assert_equal "$result" "myfeature"
}
