#!/usr/bin/env bats

load "../helpers/test_helper"

setup() {
    setup_temp_dirs

    # Override PROJECT_ROOT for workspace helpers
    PROJECT_ROOT="$FAKE_PROJECT_ROOT"

    # Create a git repo in FAKE_PROJECT_ROOT
    git -C "$FAKE_PROJECT_ROOT" init -b main >/dev/null 2>&1
    git -C "$FAKE_PROJECT_ROOT" config user.email "test@test.com"
    git -C "$FAKE_PROJECT_ROOT" config user.name "Test"
    touch "$FAKE_PROJECT_ROOT/.gitkeep"
    git -C "$FAKE_PROJECT_ROOT" add .gitkeep
    git -C "$FAKE_PROJECT_ROOT" commit -m "init" >/dev/null 2>&1
}

teardown() {
    teardown_temp_dirs
}

@test "workspace_tracking_file: returns correct path based on PROJECT_ROOT" {
    result="$(workspace_tracking_file)"
    assert_equal "$result" "$FAKE_PROJECT_ROOT/.pdm-workspaces/workspaces.json"
}

@test "init_workspace_tracking: creates .pdm-workspaces/ dir and workspaces.json with empty array" {
    init_workspace_tracking

    [[ -d "$FAKE_PROJECT_ROOT/.pdm-workspaces" ]]
    [[ -f "$FAKE_PROJECT_ROOT/.pdm-workspaces/workspaces.json" ]]

    local count
    count=$(node -e "
        const data = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
        console.log(data.workspaces.length);
    " "$FAKE_PROJECT_ROOT/.pdm-workspaces/workspaces.json")
    assert_equal "$count" "0"
}

@test "init_workspace_tracking: is idempotent (doesn't overwrite existing)" {
    init_workspace_tracking

    # Add an entry manually
    node -e "
        const fs = require('fs');
        const file = process.argv[1];
        const data = JSON.parse(fs.readFileSync(file, 'utf8'));
        data.workspaces.push({ featureId: 'test-123' });
        fs.writeFileSync(file, JSON.stringify(data, null, 2));
    " "$FAKE_PROJECT_ROOT/.pdm-workspaces/workspaces.json"

    # Call init again
    init_workspace_tracking

    # Verify existing data preserved
    local count
    count=$(node -e "
        const data = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
        console.log(data.workspaces.length);
    " "$FAKE_PROJECT_ROOT/.pdm-workspaces/workspaces.json")
    assert_equal "$count" "1"
}

@test "update_workspace_tracking: adds new workspace entry to empty tracking file" {
    init_workspace_tracking

    update_workspace_tracking "my-feature" "feature/my-feature" "/tmp/ws/my-feature" "active"

    local fid
    fid=$(node -e "
        const data = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
        console.log(data.workspaces[0].featureId);
    " "$FAKE_PROJECT_ROOT/.pdm-workspaces/workspaces.json")
    assert_equal "$fid" "my-feature"

    local status
    status=$(node -e "
        const data = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
        console.log(data.workspaces[0].status);
    " "$FAKE_PROJECT_ROOT/.pdm-workspaces/workspaces.json")
    assert_equal "$status" "active"
}

@test "update_workspace_tracking: updates existing entry (matching by featureId)" {
    init_workspace_tracking
    update_workspace_tracking "my-feature" "feature/my-feature" "/tmp/ws/my-feature" "active"
    update_workspace_tracking "my-feature" "feature/my-feature" "/tmp/ws/my-feature" "completed"

    local count
    count=$(node -e "
        const data = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
        console.log(data.workspaces.length);
    " "$FAKE_PROJECT_ROOT/.pdm-workspaces/workspaces.json")
    assert_equal "$count" "1"

    local status
    status=$(node -e "
        const data = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
        console.log(data.workspaces[0].status);
    " "$FAKE_PROJECT_ROOT/.pdm-workspaces/workspaces.json")
    assert_equal "$status" "completed"
}

@test "get_workspace_path: returns path for active workspace" {
    init_workspace_tracking
    update_workspace_tracking "my-feature" "feature/my-feature" "/tmp/ws/my-feature" "active"

    result="$(get_workspace_path "my-feature")"
    assert_equal "$result" "/tmp/ws/my-feature"
}

@test "get_workspace_path: returns empty string for non-existent feature" {
    init_workspace_tracking

    result="$(get_workspace_path "no-such-feature")"
    assert_equal "$result" ""
}

@test "get_workspace_path: returns empty string for removed workspace" {
    init_workspace_tracking
    update_workspace_tracking "my-feature" "feature/my-feature" "/tmp/ws/my-feature" "active"
    update_workspace_tracking "my-feature" "feature/my-feature" "/tmp/ws/my-feature" "removed"

    result="$(get_workspace_path "my-feature")"
    assert_equal "$result" ""
}
