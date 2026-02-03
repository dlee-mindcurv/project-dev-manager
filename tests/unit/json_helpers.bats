#!/usr/bin/env bats

load "../helpers/test_helper"

setup() {
    setup_temp_dirs
    # Create a fixture JSON file
    cat > "$TEST_TEMP_DIR/test.json" << 'EOF'
{
  "name": "test-feature",
  "version": "1.0",
  "nested": {
    "key": "nested-value"
  },
  "userStories": [
    { "id": "US-001", "title": "First story", "passes": false },
    { "id": "US-002", "title": "Second story", "passes": true },
    { "id": "US-003", "title": "Third story", "passes": false }
  ]
}
EOF
}

teardown() {
    teardown_temp_dirs
}

@test "json_get: reads a string property" {
    result="$(json_get "$TEST_TEMP_DIR/test.json" ".name")"
    assert_equal "$result" "test-feature"
}

@test "json_get: reads a nested property" {
    result="$(json_get "$TEST_TEMP_DIR/test.json" ".nested.key")"
    assert_equal "$result" "nested-value"
}

@test "json_get: returns empty for missing property" {
    result="$(json_get "$TEST_TEMP_DIR/test.json" ".nonexistent")"
    assert_equal "$result" ""
}

@test "json_array_length: returns correct count" {
    result="$(json_array_length "$TEST_TEMP_DIR/test.json" ".userStories")"
    assert_equal "$result" "3"
}

@test "json_array_item: returns correct property by index" {
    result="$(json_array_item "$TEST_TEMP_DIR/test.json" ".userStories" 0 "id")"
    assert_equal "$result" "US-001"
}

@test "json_array_item: returns property from second element" {
    result="$(json_array_item "$TEST_TEMP_DIR/test.json" ".userStories" 1 "title")"
    assert_equal "$result" "Second story"
}

@test "json_get: returns empty string for missing file" {
    run json_get "$TEST_TEMP_DIR/nonexistent.json" ".name"
    assert_equal "$output" ""
}
