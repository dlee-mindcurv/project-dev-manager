---
allowed-tools: Bash, Read, Glob
argument-hint: <feature-id>
description: "Start autonomous PRD execution using Ralph. Loops through user stories in prd.json until all pass or max iterations reached."
---

# Ralph Execute

Launches the Ralph orchestrator to autonomously execute all user stories in a feature's prd.json.

---

## Usage

```
/ralph-execute <feature-id>
```

**Example:**
```
/ralph-execute add-logo
```

---

## Prerequisites

Before running, ensure:

1. **Feature directory exists**: `product-development/features/<feature-id>/`
2. **prd.json exists**: Run `/create-prd-json <feature-id>` first if needed
3. **User stories are defined**: prd.json should have `userStories` array with `passes: false`

---

## What Ralph Does

1. **Reads prd.json** to find incomplete stories (`passes: false`)
2. **Spawns Claude instances** - one iteration per story
3. **Each iteration**:
   - Implements one user story
   - Runs quality checks (build/typecheck; lint only on last/only story)
   - Verifies UI changes in browser (for UI stories)
   - Commits on success
   - Updates prd.json (`passes: true`)
   - Records learnings in progress.txt
4. **Loops** until all stories complete or max iterations reached
5. **Exits** when it sees `<promise>COMPLETE</promise>` signal

---

## Execution Steps

### Step 1: Validate Feature

Check that the feature exists and has a prd.json:

```bash
# Check feature directory
ls -la product-development/features/$FEATURE_ID/

# Check prd.json exists
cat product-development/features/$FEATURE_ID/prd.json | head -20
```

### Step 2: Review Current Status

Before starting, show the user the current state:

```bash
# Count incomplete stories
jq '[.userStories[] | select(.passes == false)] | length' product-development/features/$FEATURE_ID/prd.json

# Show incomplete story IDs
jq -r '.userStories[] | select(.passes == false) | .id + ": " + .title' product-development/features/$FEATURE_ID/prd.json
```

### Step 3: Launch Ralph

Execute the Ralph orchestrator:

```bash
./scripts/generate-feature-code.sh --feature $FEATURE_ID
```

**Optional: Custom max iterations**

```bash
./scripts/generate-feature-code.sh --feature $FEATURE_ID --max-iterations 20
```

---

## Output

Ralph will display:
- Iteration progress (e.g., "Iteration 3/10 - Working on: US-003")
- Status summary after each iteration
- Final completion message or max iterations warning

---

## Files Created/Modified

| File | Purpose |
|------|---------|
| `progress.txt` | Logs each story's completion with learnings |
| `prd.json` | Updated with `passes: true` for completed stories |
| `.last-branch` | Tracks current branch for archiving |
| `archive/` | Previous runs archived here if branch changes |

---

## Troubleshooting

### "prd.json not found"
Run `/create-prd-json <feature-id>` to generate it from the PRD.

### "Max iterations reached"
- Check `progress.txt` for blockers
- Review the `notes` field in incomplete stories
- Manually fix issues and re-run

### "Quality checks failing"
- Check the iteration output for specific errors
- Fix issues in the codebase
- Re-run Ralph to continue

---

## Example Session

```
> /ralph-execute add-logo

Checking feature: add-logo
✓ Feature directory exists
✓ prd.json found with 5 user stories

Incomplete stories:
- US-001: Create turtle SVG logo asset
- US-002: Add logo component
- US-003: Display logo in application header
- US-004: Make logo clickable to navigate home
- US-005: Add logo as favicon

Launching Ralph orchestrator...

[Ralph executes iterations...]

╔═══════════════════════════════════════════════════════════════╗
║                    ALL STORIES COMPLETE!                      ║
╚═══════════════════════════════════════════════════════════════╝

Stories: 5/5 complete
Branch: feature/add-logo
```
