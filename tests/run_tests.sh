#!/bin/bash

# run_tests.sh - Run all PDM BATS tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATS="$SCRIPT_DIR/bats/bats-core/bin/bats"

if [[ ! -x "$BATS" ]]; then
    echo "Error: bats not found at $BATS"
    echo "Run: git submodule update --init --recursive"
    exit 1
fi

echo "Running PDM unit tests..."
echo ""

"$BATS" "$SCRIPT_DIR"/unit/*.bats

echo ""
echo "Running PDM integration tests..."
echo ""

"$BATS" "$SCRIPT_DIR"/integration/*.bats

echo ""
echo "All tests passed!"
