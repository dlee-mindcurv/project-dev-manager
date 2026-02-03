#!/usr/bin/env bats

load "../helpers/test_helper"

setup() {
    setup_temp_dirs
}

teardown() {
    teardown_temp_dirs
}

@test "update_status_json: creates new file if missing" {
    local status_file="$TEST_TEMP_DIR/status.json"
    update_status_json "$status_file" "dark-mode" "Dark Mode" "OPEN"

    assert [ -f "$status_file" ]
    result="$(json_get "$status_file" ".features[0].id")"
    assert_equal "$result" "dark-mode"
}

@test "update_status_json: adds feature to existing file" {
    local status_file="$TEST_TEMP_DIR/status.json"
    echo '{ "features": [{ "id": "existing", "name": "Existing", "status": "OPEN", "createdAt": "2025-01-01", "updatedAt": "2025-01-01" }] }' > "$status_file"

    update_status_json "$status_file" "new-feat" "New Feature" "OPEN"

    result="$(json_array_length "$status_file" ".features")"
    assert_equal "$result" "2"
    result="$(json_array_item "$status_file" ".features" 1 "id")"
    assert_equal "$result" "new-feat"
}

@test "update_status_json: skips duplicate feature IDs" {
    local status_file="$TEST_TEMP_DIR/status.json"
    update_status_json "$status_file" "dark-mode" "Dark Mode" "OPEN"
    update_status_json "$status_file" "dark-mode" "Dark Mode Again" "OPEN"

    result="$(json_array_length "$status_file" ".features")"
    assert_equal "$result" "1"
}

@test "update_status_json: preserves existing features" {
    local status_file="$TEST_TEMP_DIR/status.json"
    update_status_json "$status_file" "feat-a" "Feature A" "OPEN"
    update_status_json "$status_file" "feat-b" "Feature B" "OPEN"

    result="$(json_array_item "$status_file" ".features" 0 "id")"
    assert_equal "$result" "feat-a"
    result="$(json_array_item "$status_file" ".features" 1 "id")"
    assert_equal "$result" "feat-b"
}
