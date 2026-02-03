#!/usr/bin/env bash

# test_helper.bash - Common setup for all PDM BATS tests

# Resolve paths
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
PDM_SCRIPT="$PROJECT_ROOT/pdm"

# Load BATS libraries
load "$TEST_DIR/bats/bats-support/load"
load "$TEST_DIR/bats/bats-assert/load"

# Source pdm functions (safe because of BASH_SOURCE guard)
source "$PDM_SCRIPT"

# Disable colors for predictable test output
RED=""
GREEN=""
BLUE=""
YELLOW=""
CYAN=""
NC=""

# Create isolated temp directories for each test
setup_temp_dirs() {
    TEST_TEMP_DIR="$(mktemp -d)"
    CLAUDE_DIR="$TEST_TEMP_DIR/claude"
    SKILLS_DIR="$CLAUDE_DIR/skills"
    COMMANDS_DIR="$CLAUDE_DIR/commands"
    mkdir -p "$SKILLS_DIR" "$COMMANDS_DIR"

    FAKE_PROJECT_ROOT="$TEST_TEMP_DIR/project"
    mkdir -p "$FAKE_PROJECT_ROOT"
}

# Clean up temp directories
teardown_temp_dirs() {
    if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}
