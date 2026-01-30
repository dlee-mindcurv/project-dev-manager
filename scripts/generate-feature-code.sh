#!/bin/bash

# Ralph Orchestrator Script
# Loops through prd.json user stories, spawning fresh Claude instances until all stories pass.
# Inspired by https://github.com/snarktank/ralph

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FEATURES_DIR="$PROJECT_ROOT/product-development/features"

# Default values
MAX_ITERATIONS=10
FEATURE_ID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print usage
usage() {
    echo ""
    echo -e "${BLUE}Ralph Orchestrator - Autonomous PRD Execution${NC}"
    echo ""
    echo "Usage: $0 --feature <feature-id> [--max-iterations <n>]"
    echo ""
    echo "Options:"
    echo "  --feature, -f       Feature ID (required)"
    echo "  --max-iterations    Maximum iterations before stopping (default: 10)"
    echo "  --help, -h          Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --feature add-logo"
    echo "  $0 --feature add-logo --max-iterations 20"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --feature|-f)
            FEATURE_ID="$2"
            shift 2
            ;;
        --max-iterations)
            MAX_ITERATIONS="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Validate feature ID
if [[ -z "$FEATURE_ID" ]]; then
    echo -e "${RED}Error: --feature is required${NC}"
    usage
    exit 1
fi

# Set feature paths
FEATURE_DIR="$FEATURES_DIR/$FEATURE_ID"
PRD_JSON="$FEATURE_DIR/prd.json"
PROGRESS_FILE="$FEATURE_DIR/progress.txt"
LAST_BRANCH_FILE="$FEATURE_DIR/.last-branch"
ARCHIVE_DIR="$FEATURE_DIR/archive"
PROJECT_LEARNINGS="$PROJECT_ROOT/LEARNINGS.md"

# Validate feature directory exists
if [[ ! -d "$FEATURE_DIR" ]]; then
    echo -e "${RED}Error: Feature directory not found: $FEATURE_DIR${NC}"
    exit 1
fi

# Validate prd.json exists
if [[ ! -f "$PRD_JSON" ]]; then
    echo -e "${RED}Error: prd.json not found: $PRD_JSON${NC}"
    echo -e "${YELLOW}Run /create-prd-json $FEATURE_ID first to generate prd.json${NC}"
    exit 1
fi

# Initialize progress.txt if it doesn't exist
init_progress_file() {
    if [[ ! -f "$PROGRESS_FILE" ]]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        cat > "$PROGRESS_FILE" << EOF
# Progress Log: $FEATURE_ID
# Started: $timestamp

## Codebase Patterns

[Patterns and learnings discovered during implementation will be recorded here]

---

## Story Progress

EOF
        echo -e "${GREEN}✓ Initialized progress.txt${NC}"
    fi
}

# Initialize LEARNINGS.md if it doesn't exist
init_project_learnings() {
    if [[ ! -f "$PROJECT_LEARNINGS" ]]; then
        cat > "$PROJECT_LEARNINGS" << 'HEADER'
# Project Learnings

Accumulated codebase patterns and insights discovered during feature implementations.
Each section represents learnings from a completed feature.

---

HEADER
        echo -e "${GREEN}✓ Initialized LEARNINGS.md${NC}"
    fi
}

# Archive previous run if branch changed
archive_previous_run() {
    if [[ -f "$LAST_BRANCH_FILE" && -f "$PRD_JSON" ]]; then
        local last_branch=$(cat "$LAST_BRANCH_FILE")
        local current_branch=$(jq -r '.branchName' "$PRD_JSON" 2>/dev/null || echo "")

        if [[ -n "$last_branch" && "$last_branch" != "$current_branch" ]]; then
            # Check if progress.txt has content beyond header
            if [[ -f "$PROGRESS_FILE" ]] && [[ $(wc -l < "$PROGRESS_FILE") -gt 10 ]]; then
                local archive_name=$(date '+%Y-%m-%d')-$(echo "$last_branch" | sed 's/.*\///')
                local archive_path="$ARCHIVE_DIR/$archive_name"

                mkdir -p "$archive_path"
                cp "$PRD_JSON" "$archive_path/"
                cp "$PROGRESS_FILE" "$archive_path/"

                echo -e "${YELLOW}✓ Archived previous run to: $archive_path${NC}"

                # Reset progress file
                rm "$PROGRESS_FILE"
                init_progress_file
            fi
        fi
    fi
}

# Update last branch tracking
update_last_branch() {
    local branch=$(jq -r '.branchName' "$PRD_JSON" 2>/dev/null || echo "")
    if [[ -n "$branch" ]]; then
        echo "$branch" > "$LAST_BRANCH_FILE"
    fi
}

# Append learnings to project-level file when feature completes
append_to_project_learnings() {
    local feature_name=$(jq -r '.featureName' "$PRD_JSON")
    local timestamp=$(date '+%Y-%m-%d')

    # Add feature header
    echo "" >> "$PROJECT_LEARNINGS"
    echo "## $feature_name ($timestamp)" >> "$PROJECT_LEARNINGS"
    echo "" >> "$PROJECT_LEARNINGS"

    # Extract content between "## Codebase Patterns" and "---"
    # Skip the header line and the trailing separator
    sed -n '/^## Codebase Patterns$/,/^---$/p' "$PROGRESS_FILE" | \
        sed '1d;$d' >> "$PROJECT_LEARNINGS"

    echo "---" >> "$PROJECT_LEARNINGS"

    echo -e "${GREEN}✓ Appended learnings to LEARNINGS.md${NC}"
}

# Count incomplete stories
count_incomplete_stories() {
    jq '[.userStories[] | select(.passes == false)] | length' "$PRD_JSON" 2>/dev/null || echo "0"
}

# Count total stories
count_total_stories() {
    jq '.userStories | length' "$PRD_JSON" 2>/dev/null || echo "0"
}

# Get next incomplete story ID
get_next_story_id() {
    jq -r '[.userStories[] | select(.passes == false)] | sort_by(.priority) | .[0].id // empty' "$PRD_JSON" 2>/dev/null
}

# Get model for a specific story (defaults to sonnet if not specified)
get_story_model() {
    local story_id="$1"
    local model=$(jq -r --arg id "$story_id" '.userStories[] | select(.id == $id) | .model // "sonnet"' "$PRD_JSON" 2>/dev/null)
    # Return model alias directly (CLI accepts: sonnet, opus, haiku)
    case "$model" in
        haiku)
            echo "haiku"
            ;;
        opus)
            echo "opus"
            ;;
        sonnet|*)
            echo "sonnet"
            ;;
    esac
}

# Print status summary
print_status() {
    local incomplete=$(count_incomplete_stories)
    local total=$(count_total_stories)
    local complete=$((total - incomplete))

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Ralph Orchestrator - Feature: ${FEATURE_ID}${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  Stories: ${complete}/${total} complete${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Build the prompt for Claude
build_prompt() {
    local is_first_story="$1"
    local learnings_instruction=""

    if [[ "$is_first_story" == "true" && -f "$PROJECT_LEARNINGS" ]]; then
        learnings_instruction="
IMPORTANT: This is the first story of this feature.
Read the project learnings file first: $PROJECT_LEARNINGS
Apply relevant patterns from previous features to this implementation.
"
    fi

    cat << EOF
You are executing the Ralph autonomous agent loop for feature: $FEATURE_ID
$learnings_instruction
IMPORTANT: Read and follow these instructions exactly.

## Your Task This Iteration

1. Read the PRD file: $PRD_JSON
2. Read the progress file: $PROGRESS_FILE (check Codebase Patterns section first)
3. Find the highest priority user story where "passes": false
4. Checkout or create the branch specified in branchName
5. Implement ONLY that one user story
6. Run quality checks npm run build.  Only run npm run lint if it is the LAST or ONLY story in the feature
7. Follow acceptance criteria exactly - only verify in browser if the story's criteria includes "Verify in browser"
8. If ALL checks pass:
   - Commit with message: "feat: [Story ID] - [Story Title]"
   - Update prd.json: set that story's "passes": true
   - Append to progress.txt with what you learned
9. If checks FAIL:
   - Do NOT commit
   - Fix the issues and retry
   - If you cannot fix after 3 attempts, update the story's "notes" field with the blocker

## Completion Signal

After updating prd.json, check if ALL stories have "passes": true.
If ALL stories pass, output this EXACT text on its own line:
<promise>COMPLETE</promise>

If stories remain incomplete, just finish this iteration normally.

## Quality Gates

- Typecheck must pass (npm run build)
- Lint must pass (npm run lint)
- UI stories must pass browser verification
- NO commits if checks fail

## File Locations

- PRD: $PRD_JSON
- Progress: $PROGRESS_FILE
- Feature directory: $FEATURE_DIR

Begin now. Read the prd.json first to find the next story to implement.
EOF
}

# Main execution
main() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           Ralph Orchestrator - Starting Execution            ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Check for required tools
    if ! command -v claude &> /dev/null; then
        echo -e "${RED}Error: Claude CLI not found${NC}"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq not found. Please install jq.${NC}"
        exit 1
    fi

    # Initialize
    archive_previous_run
    init_progress_file
    init_project_learnings
    update_last_branch

    print_status

    # Check if already complete
    local incomplete=$(count_incomplete_stories)
    if [[ "$incomplete" -eq 0 ]]; then
        echo -e "${GREEN}✓ All stories already complete!${NC}"
        exit 0
    fi

    echo -e "${BLUE}Starting iteration loop (max: $MAX_ITERATIONS)${NC}"
    echo ""

    # Track first story for LEARNINGS.md reading
    local first_story_done=false

    # Main loop
    for i in $(seq 1 $MAX_ITERATIONS); do
        local next_story=$(get_next_story_id)

        if [[ -z "$next_story" ]]; then
            echo -e "${GREEN}✓ All stories complete!${NC}"
            exit 0
        fi

        # Get model for this story
        local story_model=$(get_story_model "$next_story")

        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}  Iteration $i/$MAX_ITERATIONS - Working on: $next_story (model: $story_model)${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        # Determine if this is the first story of the feature
        local is_first="false"
        if [[ "$first_story_done" == "false" ]]; then
            is_first="true"
            first_story_done=true
        fi

        # Build prompt and run Claude
        local prompt=$(build_prompt "$is_first")

        # Run Claude with --dangerously-skip-permissions, model selection, and capture output
        local output
        output=$(echo "$prompt" | claude --dangerously-skip-permissions --model "$story_model" --print 2>&1) || true

        # Check for completion signal
        if echo "$output" | grep -q "<promise>COMPLETE</promise>"; then
            # Append learnings to project-level file
            append_to_project_learnings

            echo ""
            echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║                    ALL STORIES COMPLETE!                      ║${NC}"
            echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            print_status
            exit 0
        fi

        # Print iteration summary
        print_status

        # Small delay between iterations
        sleep 2
    done

    # Max iterations reached
    echo ""
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  Max iterations ($MAX_ITERATIONS) reached. Some stories incomplete.   ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local incomplete=$(count_incomplete_stories)
    local total=$(count_total_stories)
    echo -e "${YELLOW}Incomplete stories: $incomplete/$total${NC}"
    echo -e "${YELLOW}Check $PROGRESS_FILE for details.${NC}"

    exit 1
}

# Run main
main
