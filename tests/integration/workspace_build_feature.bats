#!/usr/bin/env bats

load "../helpers/test_helper"

FEATURE_ID="build-test"
BRANCH_NAME="feature/build-test"

setup() {
    setup_temp_dirs

    # Override PROJECT_ROOT
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
  "featureName": "Build Test Feature",
  "description": "Testing build-feature workspace integration",
  "branchName": "$BRANCH_NAME",
  "userStories": [
    { "id": "US-001", "title": "Test story", "passes": false, "priority": 1, "model": "sonnet" }
  ]
}
EOF

    echo '{ "features": [] }' > "$FAKE_PROJECT_ROOT/product-development/features/status.json"

    # Create .claude/ directory
    mkdir -p "$FAKE_PROJECT_ROOT/.claude/commands"
    echo "test" > "$FAKE_PROJECT_ROOT/.claude/commands/test.md"

    # Override find_project_root to return FAKE_PROJECT_ROOT
    find_project_root() {
        echo "$FAKE_PROJECT_ROOT"
        return 0
    }

    # Create a mock claude command that captures the prompt and outputs COMPLETE
    MOCK_BIN="$TEST_TEMP_DIR/mock_bin"
    mkdir -p "$MOCK_BIN"
    cat > "$MOCK_BIN/claude" << 'MOCK_EOF'
#!/bin/bash
# Capture stdin (the prompt) to a file for inspection
cat > "${CLAUDE_PROMPT_CAPTURE:-/dev/null}"
echo "<promise>COMPLETE</promise>"
MOCK_EOF
    chmod +x "$MOCK_BIN/claude"
    export PATH="$MOCK_BIN:$PATH"

    # Set up capture file
    export CLAUDE_PROMPT_CAPTURE="$TEST_TEMP_DIR/captured_prompt.txt"
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

@test "cmd_build_feature: auto-creates workspace when none exists" {
    # Run build-feature - it should auto-create a workspace
    run cmd_build_feature "$FEATURE_ID" 1
    # It will exit 0 because the mock outputs COMPLETE

    # Verify workspace was created
    local ws_path="$FAKE_PROJECT_ROOT/.pdm-workspaces/$FEATURE_ID"
    [[ -d "$ws_path" || -f "$FAKE_PROJECT_ROOT/.pdm-workspaces/workspaces.json" ]]

    # Check tracking file has an entry
    local ws_file="$FAKE_PROJECT_ROOT/.pdm-workspaces/workspaces.json"
    if [[ -f "$ws_file" ]]; then
        local fid
        fid=$(node -e "
            const data = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
            const ws = data.workspaces.find(w => w.featureId === '$FEATURE_ID');
            console.log(ws ? ws.featureId : '');
        " "$ws_file")
        assert_equal "$fid" "$FEATURE_ID"
    fi
}

@test "cmd_build_feature: detects existing workspace and uses it" {
    # Create workspace first
    cmd_create_workspace "$FEATURE_ID"

    run cmd_build_feature "$FEATURE_ID" 1
    assert_output --partial "Using workspace"
}

@test "cmd_build_feature: computes paths relative to workspace root" {
    cmd_create_workspace "$FEATURE_ID"

    run cmd_build_feature "$FEATURE_ID" 1

    # The prompt should reference workspace paths, not main project paths
    local ws_path="$FAKE_PROJECT_ROOT/.pdm-workspaces/$FEATURE_ID"
    if [[ -f "$CLAUDE_PROMPT_CAPTURE" ]]; then
        local prompt_content
        prompt_content=$(cat "$CLAUDE_PROMPT_CAPTURE")
        [[ "$prompt_content" == *"$ws_path"* ]]
    fi
}

@test "cmd_build_feature: prompt includes 'do NOT switch branches' in workspace mode" {
    cmd_create_workspace "$FEATURE_ID"

    run cmd_build_feature "$FEATURE_ID" 1

    if [[ -f "$CLAUDE_PROMPT_CAPTURE" ]]; then
        local prompt_content
        prompt_content=$(cat "$CLAUDE_PROMPT_CAPTURE")
        [[ "$prompt_content" == *"Do NOT run git checkout"* ]] || [[ "$prompt_content" == *"do NOT switch branches"* ]] || [[ "$prompt_content" == *"Do NOT switch branches"* ]]
    fi
}
