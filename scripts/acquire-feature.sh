#!/bin/bash

# Feature Acquisition Script
# Launches Claude Code to gather feature details and generate JTBD analysis
# Integrates with Claude Code commands: /pdm-create-jtbd

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_ROOT/product-development/features"
RESOURCES_DIR="$PROJECT_ROOT/product-development/resources"
PRODUCT_MD="$PROJECT_ROOT/product.md"
STATUS_JSON="$OUTPUT_DIR/status.json"

# Global variable for feature ID (set during input collection)
FEATURE_ID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure PDM skills/commands are installed
ensure_skills_installed() {
    local command_file="$HOME/.claude/commands/pdm-create-jtbd.md"

    if [[ -f "$command_file" ]]; then
        echo -e "${GREEN}✓ PDM skills already installed${NC}"
        return 0
    fi

    echo -e "${YELLOW}PDM skills not found. Installing via pdm --install...${NC}"

    if [[ ! -x "$PROJECT_ROOT/pdm" ]]; then
        echo -e "${RED}Error: pdm CLI not found at $PROJECT_ROOT/pdm${NC}"
        exit 1
    fi

    "$PROJECT_ROOT/pdm" --install

    if [[ ! -f "$command_file" ]]; then
        echo -e "${RED}Error: PDM skill installation failed. $command_file not found after install.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ PDM skills installed successfully${NC}"
}

# Generate feature ID from name (e.g., "My Feature" -> "my-feature")
generate_feature_id() {
    local name="$1"
    echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-'
}

# Update status.json with a new feature entry
update_status_json() {
    local id="$1"
    local name="$2"
    local status="${3:-OPEN}"
    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    # Create status.json if it doesn't exist
    if [[ ! -f "$STATUS_JSON" ]]; then
        cat > "$STATUS_JSON" << EOF
{
  "features": []
}
EOF
    fi

    # Check if feature ID already exists
    if command -v jq &> /dev/null; then
        local exists=$(jq -r --arg id "$id" '.features[] | select(.id == $id) | .id' "$STATUS_JSON" 2>/dev/null)
        if [[ -n "$exists" ]]; then
            echo -e "${YELLOW}Feature ID '$id' already exists in status.json${NC}"
            return 0
        fi

        # Add new feature entry using jq
        local tmp_file=$(mktemp)
        jq --arg id "$id" \
           --arg name "$name" \
           --arg status "$status" \
           --arg created "$timestamp" \
           --arg updated "$timestamp" \
           '.features += [{"id": $id, "name": $name, "status": $status, "createdAt": $created, "updatedAt": $updated}]' \
           "$STATUS_JSON" > "$tmp_file" && mv "$tmp_file" "$STATUS_JSON"
    else
        # Fallback: simple bash-based JSON update (less robust)
        local tmp_file=$(mktemp)
        # Read existing content and add new entry
        local new_entry="    {
      \"id\": \"$id\",
      \"name\": \"$name\",
      \"status\": \"$status\",
      \"createdAt\": \"$timestamp\",
      \"updatedAt\": \"$timestamp\"
    }"

        # Check if features array is empty
        if grep -q '"features": \[\]' "$STATUS_JSON"; then
            sed "s/\"features\": \[\]/\"features\": [\n$new_entry\n  ]/" "$STATUS_JSON" > "$tmp_file" && mv "$tmp_file" "$STATUS_JSON"
        else
            # Insert before the closing bracket of features array
            sed "s/\(\"features\": \[.*\)\]/\1,\n$new_entry\n  ]/" "$STATUS_JSON" > "$tmp_file" && mv "$tmp_file" "$STATUS_JSON"
        fi
    fi

    echo -e "${GREEN}✓ Updated status.json with feature: $id${NC}"
}

# Create required directory structure
setup_directories() {
    # Create output directory
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        mkdir -p "$OUTPUT_DIR"
        echo -e "${GREEN}✓ Created directory: $OUTPUT_DIR${NC}"
    fi

    # Create resources directory and copy product.md if it exists
    if [[ -f "$PRODUCT_MD" ]]; then
        if [[ ! -d "$RESOURCES_DIR" ]]; then
            mkdir -p "$RESOURCES_DIR"
            echo -e "${GREEN}✓ Created directory: $RESOURCES_DIR${NC}"
        fi
        cp "$PRODUCT_MD" "$RESOURCES_DIR/product.md"
        echo -e "${GREEN}✓ Copied product.md to resources directory${NC}"
    fi

    # Setup JTBD template
    setup_jtbd_template

    # Setup PRD template
    setup_prd_template
}

# Create JTBD template if it doesn't exist
setup_jtbd_template() {
    local template_file="$RESOURCES_DIR/JTBD-template.md"

    # Ensure resources directory exists
    if [[ ! -d "$RESOURCES_DIR" ]]; then
        mkdir -p "$RESOURCES_DIR"
        echo -e "${GREEN}✓ Created directory: $RESOURCES_DIR${NC}"
    fi

    if [[ ! -f "$template_file" ]]; then
        cat > "$template_file" << 'EOF'
# Jobs-to-be-Done Analysis: [FEATURE_NAME]

## Feature Summary

[Brief description of the feature]

---

## Job Statements

### Primary Job

**When** [situation], **I want** [motivation], **so I can** [expected outcome].

### Secondary Jobs

1. **When** [situation], **I want** [motivation], **so I can** [expected outcome].

---

## User Needs and Pain Points

### Needs

| Need | Description |
|------|-------------|
| [Need] | [Description] |

### Pain Points Addressed

| Pain Point | How This Feature Helps |
|------------|----------------------|
| [Pain Point] | [How it helps] |

---

## Desired Outcomes (User Perspective)

### Functional Outcomes

- [Outcome]

### Emotional Outcomes

- [Outcome]

### Social Outcomes

- [Outcome]

---

## Competitive Analysis (JTBD Lens)

| Competitor | How They Solve This Job |
|------------|------------------------|
| [Competitor] | [Their approach] |

### Competitive Insight

[Analysis of competitive landscape]

---

## Market Opportunity Assessment

### Brand Differentiation

- [Differentiation point]

### User Expectations

[What users expect]

### Strategic Value

| Factor | Impact |
|--------|--------|
| [Factor] | [Impact] |

---

## Success Criteria (From User Perspective)

- [Success criterion]

---

## Assumptions to Validate

1. [Assumption to validate]
EOF
        echo -e "${GREEN}✓ Created JTBD template: $template_file${NC}"
    fi
}

# Create PRD template if it doesn't exist
setup_prd_template() {
    local template_file="$RESOURCES_DIR/PRD-template.md"

    # Ensure resources directory exists
    if [[ ! -d "$RESOURCES_DIR" ]]; then
        mkdir -p "$RESOURCES_DIR"
        echo -e "${GREEN}✓ Created directory: $RESOURCES_DIR${NC}"
    fi

    if [[ ! -f "$template_file" ]]; then
        cat > "$template_file" << 'EOF'
# PRD: [FEATURE_NAME]

## Introduction

[Brief description of the feature and the problem it solves.]

## Goals

- [Specific, measurable objective]
- [Another objective]

## User Stories

### US-001: [Title]
**Description:** As a [user], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] Specific verifiable criterion
- [ ] Another criterion
- [ ] Typecheck/lint passes

### US-002: [Title]
**Description:** As a [user], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] Specific verifiable criterion
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

## Functional Requirements

- FR-1: The system must [specific functionality]
- FR-2: When a user [action], the system must [response]

## Non-Goals

- [What this feature will NOT include]
- [Another exclusion]

## Design Considerations

- [UI/UX requirements]
- [Relevant existing components to reuse]

## Technical Considerations

- [Known constraints or dependencies]
- [Integration points with existing systems]

## Success Metrics

- [How success will be measured]
- [Another metric]

## Open Questions

- [Remaining questions or areas needing clarification]
EOF
        echo -e "${GREEN}✓ Created PRD template: $template_file${NC}"
    fi
}

# Display input menu
show_menu() {
    echo ""
    echo -e "${BLUE}How would you like to provide the feature details?${NC}"
    echo ""
    echo "  1) Enter feature name and description manually"
    echo "  2) Reference an existing feature file"
    echo "  3) Cancel"
    echo ""
}

# Get path to existing feature file and copy content
get_existing_file() {
    echo ""
    read -p "Enter the path to the existing feature file: " file_path

    # Expand ~ to home directory
    file_path="${file_path/#\~/$HOME}"

    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}Error: File not found: $file_path${NC}"
        return 1
    fi

    # Get feature name for ID generation
    echo ""
    read -p "Enter a name for this feature (used to generate ID): " feature_name
    if [[ -z "$feature_name" ]]; then
        echo -e "${RED}Error: Feature name cannot be empty${NC}"
        return 1
    fi

    # Generate feature ID
    FEATURE_ID=$(generate_feature_id "$feature_name")
    local feature_dir="$OUTPUT_DIR/${FEATURE_ID}"
    mkdir -p "$feature_dir"
    local feature_file="$feature_dir/feature.md"

    # Copy file content to feature.md
    cp "$file_path" "$feature_file"
    echo -e "${GREEN}✓ Copied feature file to: $feature_file${NC}"

    # Update status.json
    update_status_json "$FEATURE_ID" "$feature_name" "OPEN"

    return 0
}

# Get manual input for feature name and description
get_manual_input() {
    echo ""
    echo -e "${BLUE}Enter feature details:${NC}"
    echo ""

    # Get feature name
    read -p "Feature name: " feature_name
    if [[ -z "$feature_name" ]]; then
        echo -e "${RED}Error: Feature name cannot be empty${NC}"
        return 1
    fi

    # Generate feature ID from name
    FEATURE_ID=$(generate_feature_id "$feature_name")
    echo -e "${BLUE}Generated feature ID: ${FEATURE_ID}${NC}"

    echo ""
    echo "Feature description (press Enter twice when done):"
    echo ""

    # Read multi-line description
    feature_description=""
    while IFS= read -r line; do
        [[ -z "$line" ]] && break
        feature_description+="$line"$'\n'
    done

    # Remove trailing newline
    feature_description="${feature_description%$'\n'}"

    if [[ -z "$feature_description" ]]; then
        echo -e "${RED}Error: Feature description cannot be empty${NC}"
        return 1
    fi

    # Generate feature-[ID].md
    generate_feature_md "$feature_name" "$feature_description"

    # Update status.json
    update_status_json "$FEATURE_ID" "$feature_name" "OPEN"

    return 0
}

# Generate feature.md file in per-feature directory
generate_feature_md() {
    local name="$1"
    local description="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local feature_dir="$OUTPUT_DIR/${FEATURE_ID}"
    mkdir -p "$feature_dir"
    local feature_file="$feature_dir/feature.md"

    cat > "$feature_file" << EOF
# Feature: $name

## Description

$description

## Status

- Created: $timestamp
- Status: Draft
EOF

    echo ""
    echo -e "${GREEN}✓ Created feature file: $feature_file${NC}"
}

# Main function
main() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Feature Acquisition Script        ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
    echo ""

    # Setup directories first
    echo -e "${BLUE}Setting up directories...${NC}"
    setup_directories
    echo ""

    # Check if claude CLI is available
    if ! command -v claude &> /dev/null; then
        echo -e "${RED}Error: Claude CLI not found.${NC}"
        echo -e "Please install Claude Code and try again."
        exit 1
    fi

    # Ensure PDM skills are installed before proceeding
    ensure_skills_installed

    # Always prompt for new feature creation
    echo -e "${YELLOW}Create a new feature:${NC}"

    # Show menu and get user choice
    show_menu
    read -p "Select an option [1-3]: " choice

    case $choice in
        1)
            get_manual_input || exit 1
            ;;
        2)
            get_existing_file || exit 1
            ;;
        3)
            echo -e "${YELLOW}Cancelled.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Exiting.${NC}"
            exit 1
            ;;
    esac

    echo ""
    echo -e "${BLUE}Launching Claude Code with /pdm-create-jtbd ${FEATURE_ID}...${NC}"
    echo ""

    # Launch Claude Code with /pdm-create-jtbd command and feature ID
    cd "$PROJECT_ROOT"
    claude "/pdm-create-jtbd ${FEATURE_ID}"
}

# Run main function
main
