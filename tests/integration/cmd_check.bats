#!/usr/bin/env bats

load "../helpers/test_helper"

# These tests override `command` builtin behavior by redefining cmd_check
# with a controlled environment. We source pdm functions and override
# the relevant checks.

setup() {
    MOCK_BIN="$(mktemp -d)"
    ORIGINAL_PATH="$PATH"
    # Prepend mock bin to PATH so mocks shadow real commands
    export PATH="$MOCK_BIN:$ORIGINAL_PATH"
}

teardown() {
    export PATH="$ORIGINAL_PATH"
    if [[ -n "$MOCK_BIN" && -d "$MOCK_BIN" ]]; then
        rm -rf "$MOCK_BIN"
    fi
}

# Create a working mock
mock_cmd() {
    local name="$1"
    local body="$2"
    cat > "$MOCK_BIN/$name" << EOF
#!/bin/bash
$body
EOF
    chmod +x "$MOCK_BIN/$name"
}

# Hide a command by making a non-executable file (command -v won't find it)
hide_cmd() {
    local name="$1"
    # We need to ensure the real command is not found.
    # Create a wrapper that returns false for the hidden commands.
    # We'll create a custom cmd_check wrapper instead.
    :
}

# Custom check function that controls which commands are "found"
# by overriding command -v behavior
run_check_with() {
    local has_claude="${1:-yes}"
    local has_node="${2:-yes}"
    local has_git="${3:-yes}"
    local has_curl="${4:-yes}"
    local node_version="${5:-v20.0.0}"

    # Build a self-contained check script that sources pdm and overrides command lookups
    bash << SCRIPT
set -e
source "$PDM_SCRIPT"

# Override colors
RED="" GREEN="" BLUE="" YELLOW="" CYAN="" NC=""

# Override command to control what's "found"
command() {
    if [[ "\$1" == "-v" ]]; then
        case "\$2" in
            claude) [[ "$has_claude" == "yes" ]] && echo "/usr/bin/claude" && return 0 || return 1 ;;
            node)   [[ "$has_node" == "yes" ]] && echo "/usr/bin/node" && return 0 || return 1 ;;
            git)    [[ "$has_git" == "yes" ]] && echo "/usr/bin/git" && return 0 || return 1 ;;
            curl)   [[ "$has_curl" == "yes" ]] && echo "/usr/bin/curl" && return 0 || return 1 ;;
            *)      builtin command "\$@" ;;
        esac
    else
        builtin command "\$@"
    fi
}
export -f command 2>/dev/null || true

# Override the version-checking commands with mocks
claude() { echo "Claude Code 1.0.0"; }
node() {
    if [[ "\$1" == "--version" ]]; then
        echo "$node_version"
    else
        builtin command node "\$@"
    fi
}
git() { echo "git version 2.40.0"; }
curl() { echo "curl 8.0.0 (x86_64-apple-darwin)"; }

cmd_check
SCRIPT
}

@test "cmd_check: all deps present reports all satisfied" {
    run run_check_with yes yes yes yes
    assert_success
    assert_output --partial "All dependencies satisfied"
}

@test "cmd_check: missing claude reports error" {
    run run_check_with no yes yes yes
    assert_failure
    assert_output --partial "Claude CLI: not found"
}

@test "cmd_check: missing node reports error" {
    run run_check_with yes no yes yes
    assert_failure
    assert_output --partial "Node.js: not found"
}

@test "cmd_check: node version below 18 shows warning" {
    run run_check_with yes yes yes yes v16.20.0
    assert_success
    assert_output --partial "Warning: Node.js 18+ recommended"
}

@test "cmd_check: multiple missing deps reports all and fails" {
    run run_check_with no no yes yes
    assert_failure
    assert_output --partial "Claude CLI: not found"
    assert_output --partial "Node.js: not found"
}
