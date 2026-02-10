#!/usr/bin/env bats

load "../helpers/test_helper"

FEATURE_ID="test-feature"
BRANCH_NAME="feature/test-feature"

setup() {
    setup_temp_dirs

    # Override PROJECT_ROOT for workspace helpers
    PROJECT_ROOT="$FAKE_PROJECT_ROOT"

    # Create a real git repo with an initial commit
    git -C "$FAKE_PROJECT_ROOT" init -b main >/dev/null 2>&1
    git -C "$FAKE_PROJECT_ROOT" config user.email "test@test.com"
    git -C "$FAKE_PROJECT_ROOT" config user.name "Test"
    touch "$FAKE_PROJECT_ROOT/.gitkeep"
    git -C "$FAKE_PROJECT_ROOT" add .gitkeep
    git -C "$FAKE_PROJECT_ROOT" commit -m "init" >/dev/null 2>&1

    # Create product-development/features/<id>/prd.json
    local feature_dir="$FAKE_PROJECT_ROOT/product-development/features/$FEATURE_ID"
    mkdir -p "$feature_dir"
    cat > "$feature_dir/prd.json" << EOF
{
  "featureName": "Test Feature",
  "description": "A test feature",
  "branchName": "$BRANCH_NAME",
  "userStories": [
    { "id": "US-001", "title": "Story one", "passes": false, "priority": 1 }
  ]
}
EOF

    # Create progress.txt
    echo "# Progress Log" > "$feature_dir/progress.txt"

    # Create status.json
    echo '{ "features": [] }' > "$FAKE_PROJECT_ROOT/product-development/features/status.json"

    # Create .claude/ directory
    mkdir -p "$FAKE_PROJECT_ROOT/.claude/commands"
    echo "test" > "$FAKE_PROJECT_ROOT/.claude/commands/test.md"

    # Create resources dir
    mkdir -p "$FAKE_PROJECT_ROOT/product-development/resources"
    echo "template" > "$FAKE_PROJECT_ROOT/product-development/resources/PRD-template.md"

    # Override find_project_root to return FAKE_PROJECT_ROOT
    find_project_root() {
        echo "$FAKE_PROJECT_ROOT"
        return 0
    }
}

teardown() {
    # Clean up any worktrees
    if [[ -d "$FAKE_PROJECT_ROOT" ]]; then
        git -C "$FAKE_PROJECT_ROOT" worktree list --porcelain 2>/dev/null | \
            grep "^worktree " | grep -v "$FAKE_PROJECT_ROOT$" | \
            sed 's/^worktree //' | while read -r wt; do
                git -C "$FAKE_PROJECT_ROOT" worktree remove --force "$wt" 2>/dev/null || true
            done
        git -C "$FAKE_PROJECT_ROOT" worktree prune 2>/dev/null || true
    fi

    teardown_temp_dirs
}

# --- cmd_create_workspace ---

@test "cmd_create_workspace: fails without feature ID" {
    run cmd_create_workspace ""
    assert_failure
    assert_output --partial "Error: Feature ID required"
}

@test "cmd_create_workspace: fails if feature dir missing" {
    run cmd_create_workspace "nonexistent-feature"
    assert_failure
    assert_output --partial "Error: Feature directory not found"
}

@test "cmd_create_workspace: fails if prd.json missing" {
    mkdir -p "$FAKE_PROJECT_ROOT/product-development/features/no-prd"
    run cmd_create_workspace "no-prd"
    assert_failure
    assert_output --partial "Error: prd.json not found"
}

@test "cmd_create_workspace: creates git worktree at correct path" {
    run cmd_create_workspace "$FEATURE_ID"
    assert_success

    local ws_path="$FAKE_PROJECT_ROOT/.pdm-workspaces/$FEATURE_ID"
    [[ -d "$ws_path" ]]
    [[ -d "$ws_path/.git" || -f "$ws_path/.git" ]]
}

@test "cmd_create_workspace: copies product-development/ into worktree" {
    run cmd_create_workspace "$FEATURE_ID"
    assert_success

    local ws_path="$FAKE_PROJECT_ROOT/.pdm-workspaces/$FEATURE_ID"
    [[ -f "$ws_path/product-development/features/$FEATURE_ID/prd.json" ]]
    [[ -f "$ws_path/product-development/features/status.json" ]]
    [[ -f "$ws_path/product-development/resources/PRD-template.md" ]]
}

@test "cmd_create_workspace: copies .claude/ into worktree" {
    run cmd_create_workspace "$FEATURE_ID"
    assert_success

    local ws_path="$FAKE_PROJECT_ROOT/.pdm-workspaces/$FEATURE_ID"
    [[ -d "$ws_path/.claude/commands" ]]
    [[ -f "$ws_path/.claude/commands/test.md" ]]
}

@test "cmd_create_workspace: records workspace in workspaces.json" {
    run cmd_create_workspace "$FEATURE_ID"
    assert_success

    local ws_file="$FAKE_PROJECT_ROOT/.pdm-workspaces/workspaces.json"
    [[ -f "$ws_file" ]]

    local fid
    fid=$(node -e "
        const data = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
        const ws = data.workspaces.find(w => w.featureId === '$FEATURE_ID');
        console.log(ws ? ws.featureId : '');
    " "$ws_file")
    assert_equal "$fid" "$FEATURE_ID"

    local status
    status=$(node -e "
        const data = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
        const ws = data.workspaces.find(w => w.featureId === '$FEATURE_ID');
        console.log(ws ? ws.status : '');
    " "$ws_file")
    assert_equal "$status" "active"
}

@test "cmd_create_workspace: fails if workspace already exists" {
    cmd_create_workspace "$FEATURE_ID"

    run cmd_create_workspace "$FEATURE_ID"
    assert_failure
    assert_output --partial "Error: Workspace already exists"
}

@test "cmd_create_workspace: fails if branch already exists" {
    # Create the branch first
    git -C "$FAKE_PROJECT_ROOT" branch "$BRANCH_NAME" 2>/dev/null

    run cmd_create_workspace "$FEATURE_ID"
    assert_failure
    assert_output --partial "Error: Branch"
    assert_output --partial "already exists"
}

# --- cmd_list_workspaces ---

@test "cmd_list_workspaces: shows 'No workspaces' when none exist" {
    run cmd_list_workspaces
    assert_success
    assert_output --partial "No workspaces found"
}

@test "cmd_list_workspaces: displays active workspace info" {
    cmd_create_workspace "$FEATURE_ID"

    run cmd_list_workspaces
    assert_success
    assert_output --partial "$FEATURE_ID"
    assert_output --partial "$BRANCH_NAME"
    assert_output --partial "active"
}

# --- cmd_cleanup_workspace ---

@test "cmd_cleanup_workspace: fails without feature ID" {
    run cmd_cleanup_workspace ""
    assert_failure
    assert_output --partial "Error: Feature ID required"
}

@test "cmd_cleanup_workspace: removes worktree directory" {
    cmd_create_workspace "$FEATURE_ID"
    local ws_path="$FAKE_PROJECT_ROOT/.pdm-workspaces/$FEATURE_ID"
    [[ -d "$ws_path" ]]

    # Workspace has untracked files (copied gitignored content), so use --force
    run cmd_cleanup_workspace "$FEATURE_ID" "--force"
    assert_success

    [[ ! -d "$ws_path" ]]
}

@test "cmd_cleanup_workspace: updates tracking to removed status" {
    cmd_create_workspace "$FEATURE_ID"

    run cmd_cleanup_workspace "$FEATURE_ID" "--force"
    assert_success

    local ws_file="$FAKE_PROJECT_ROOT/.pdm-workspaces/workspaces.json"
    local status
    status=$(node -e "
        const data = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
        const ws = data.workspaces.find(w => w.featureId === '$FEATURE_ID');
        console.log(ws ? ws.status : '');
    " "$ws_file")
    assert_equal "$status" "removed"
}

@test "cmd_cleanup_workspace: syncs progress files back before removal" {
    cmd_create_workspace "$FEATURE_ID"

    # Modify progress.txt in workspace
    local ws_path="$FAKE_PROJECT_ROOT/.pdm-workspaces/$FEATURE_ID"
    echo "Updated progress" > "$ws_path/product-development/features/$FEATURE_ID/progress.txt"

    cmd_cleanup_workspace "$FEATURE_ID" "--force"

    # Check the file was synced back to main
    local main_progress="$FAKE_PROJECT_ROOT/product-development/features/$FEATURE_ID/progress.txt"
    local content
    content=$(cat "$main_progress")
    [[ "$content" == "Updated progress" ]]
}

# --- cmd_complete_feature ---

@test "cmd_complete_feature: fails without feature ID" {
    run cmd_complete_feature ""
    assert_failure
    assert_output --partial "Error: Feature ID required"
}

@test "cmd_complete_feature: fails if no active workspace" {
    run cmd_complete_feature "nonexistent"
    assert_failure
    assert_output --partial "Error: No active workspace found"
}
