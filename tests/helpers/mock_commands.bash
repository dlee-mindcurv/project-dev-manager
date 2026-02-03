#!/usr/bin/env bash

# mock_commands.bash - Helpers for mocking external commands via PATH manipulation

ORIGINAL_PATH="$PATH"

# Set up a mock bin directory and prepend it to PATH
setup_mock_path() {
    MOCK_BIN="$(mktemp -d)"
    export PATH="$MOCK_BIN:$ORIGINAL_PATH"
}

# Restore the original PATH
restore_path() {
    export PATH="$ORIGINAL_PATH"
    if [[ -n "$MOCK_BIN" && -d "$MOCK_BIN" ]]; then
        rm -rf "$MOCK_BIN"
    fi
}

# Create a mock executable in MOCK_BIN
# Usage: create_mock_command <name> <script-body>
create_mock_command() {
    local name="$1"
    local body="$2"
    cat > "$MOCK_BIN/$name" << EOF
#!/bin/bash
$body
EOF
    chmod +x "$MOCK_BIN/$name"
}

# Remove a specific command from PATH by shadowing it with a failing stub
remove_command() {
    local name="$1"
    cat > "$MOCK_BIN/$name" << 'EOF'
#!/bin/bash
exit 127
EOF
    chmod +x "$MOCK_BIN/$name"
}
