---
name: ralph-loop
description: "Agent instructions for each Ralph iteration. Implements one user story from prd.json, runs quality checks, updates status, and signals completion when all stories pass."
---

# Ralph Loop - Single Iteration Agent Instructions

This skill defines the behavior for a single Ralph iteration. Each iteration implements ONE user story from prd.json.

---

## Iteration Workflow

### Step 1: Read State Files

1. Read `product-development/features/$FEATURE_ID/prd.json`
2. Read `product-development/features/$FEATURE_ID/progress.txt`
   - **Important**: Check the "Codebase Patterns" section first for learnings from previous iterations

### Step 2: Setup Branch

1. Get `branchName` from prd.json
2. Check if branch exists: `git branch --list <branchName>`
3. If exists: `git checkout <branchName>`
4. If not: `git checkout -b <branchName>`

### Step 3: Find Next Story

1. Filter `userStories` where `passes: false`
2. Sort by `priority` (ascending)
3. Take the first story - this is your target for this iteration

If no stories have `passes: false`, output `<promise>COMPLETE</promise>` and exit.

### Step 4: Implement the Story

1. Read the story's `title`, `description`, and `acceptanceCriteria`
2. Implement the feature to satisfy ALL acceptance criteria
3. Focus ONLY on this one story - do not touch other stories

### Step 5: Run Quality Checks

Run these checks in order:

```bash
# Typecheck (via build)
npm run build

# Lint
npm run lint
```

**If checks fail:**
- Fix the issues
- Re-run checks
- Maximum 3 fix attempts per story
- If still failing after 3 attempts, update the story's `notes` field with the blocker

### Step 6: Browser Verification (UI Stories)

If the acceptance criteria includes "Verify in browser using dev-browser skill":

1. Start dev server if not running: `npm run dev`
2. Use webapp-testing skill to:
   - Navigate to relevant page
   - Verify UI changes are visible
   - Test interactive elements
   - Take screenshot as evidence

#### Console Error Check (REQUIRED)

During browser verification, you MUST check for console errors:

1. **Capture console output** during page load and interaction
2. **FAIL the story** if any of these appear:
   - Console errors (`[error]` level)
   - React hydration warnings
   - Unhandled promise rejections
3. **Document errors** in the story's `notes` field if failing due to console errors

Common patterns to watch for:
- "A tree hydrated but some attributes..." = Hydration mismatch
- "Uncaught TypeError" = Runtime JavaScript error
- "Failed to fetch" = Network/API error

If console errors exist, the story should NOT pass even if visual verification succeeds.

#### Functional Verification (REQUIRED)

For UI stories involving user interactions, you MUST verify that actions produce visible changes:

1. **Capture before state** - screenshot or computed styles before interaction
2. **Perform the action** - click, toggle, submit, etc.
3. **Capture after state** - screenshot or computed styles after interaction
4. **Compare states** - FAIL if no visual difference when one is expected

Example for dark mode toggle:
- Before: Check background-color of body or main container
- Click toggle button
- After: Verify background-color changed
- If colors are the same, the feature is broken even if no errors occurred

**Silent failures to watch for:**
- CSS not applying (missing Tailwind config, wrong selectors)
- State updates not triggering re-renders
- DOM changes not reflected visually

#### Next.js Hydration Best Practices

When implementing features that modify the DOM before React hydration (e.g., dark mode, locale detection), use these patterns to avoid hydration mismatches:

1. **Preferred: Client-side only with useEffect**
   - Don't modify DOM before hydration
   - Use `useEffect` to apply changes after mount
   - Accept brief flash as trade-off for proper hydration

2. **Alternative: suppressHydrationWarning**
   - Add `suppressHydrationWarning` to elements that intentionally differ
   - Only use when flash prevention is critical
   - Document why suppression is needed

3. **Avoid: Inline scripts that modify DOM**
   - Scripts in `<head>` that add classes before React runs cause mismatches
   - If used, MUST add `suppressHydrationWarning` to affected elements

#### Tailwind v4 Dark Mode Configuration

Tailwind CSS v4 uses `@import "tailwindcss"` syntax and requires explicit configuration for class-based dark mode.

**REQUIRED for class-based dark mode in Tailwind v4:**
Add to `globals.css` after the import:
```css
@import "tailwindcss";

/* Enable class-based dark mode with .dark class on html element */
@custom-variant dark (&:is(.dark *));
```

Without this line, `dark:` variants will only respond to `prefers-color-scheme: dark` media query, NOT the `.dark` class.

**How to detect Tailwind v4:**
- Uses `@import "tailwindcss"` instead of `@tailwind base/components/utilities`
- Uses `@tailwindcss/postcss` in postcss.config
- No `tailwind.config.js/ts` file (or minimal one)

### Step 7: Commit (Only If All Checks Pass)

```bash
git add <changed-files>
git commit -m "feat: [Story ID] - [Story Title]"
```

**Commit message format:**
- `feat: US-001 - Create turtle SVG logo asset`
- `feat: US-002 - Add logo component`

**DO NOT commit if:**
- Typecheck fails
- Lint fails
- Browser verification fails (for UI stories)

### Step 8: Update prd.json

After successful commit, update the story in prd.json:

```json
{
  "passes": true,
  "notes": "Implemented successfully. [Brief note about approach]"
}
```

Write the updated prd.json back to the file.

### Step 9: Update progress.txt

Append to progress.txt:

```markdown
### [Story ID] - [Story Title]
**Completed:** [timestamp]
**Approach:** [Brief description of implementation]
**Learnings:** [Any patterns, gotchas, or knowledge for future iterations]
```

If you discovered a reusable pattern, also add it to the "Codebase Patterns" section at the top.

### Step 10: Check Completion

Read the updated prd.json and check if ALL stories have `passes: true`.

**If ALL complete:**
Output exactly: `<promise>COMPLETE</promise>`

**If stories remain:**
Exit normally (the orchestrator will spawn a new iteration)

---

## Quality Gates Summary

| Check | Command | Required For |
|-------|---------|--------------|
| Typecheck | `npm run build` | All stories |
| Lint | `npm run lint` | All stories |
| Browser | webapp-testing skill | UI stories with browser verification criterion |
| Console Check | Playwright console capture | UI stories with browser verification criterion |

---

## Important Rules

1. **ONE story per iteration** - Do not implement multiple stories
2. **No commits without passing checks** - Quality gates are mandatory
3. **Update state files** - prd.json and progress.txt must be updated
4. **Accumulate knowledge** - Add patterns to progress.txt for future iterations
5. **Signal completion** - Output `<promise>COMPLETE</promise>` when all stories pass

---

## Error Handling

### Build Failures
- Read error message carefully
- Fix TypeScript errors
- Re-run `npm run build`

### Lint Failures
- Run `npm run lint` to see issues
- Fix linting errors (formatting, unused imports, etc.)
- Re-run lint

### Browser Verification Failures
- Check if dev server is running
- Verify correct URL
- Check for JavaScript errors in console
- Fix UI issues and re-verify

### After 3 Failed Attempts
If you cannot pass quality checks after 3 attempts:
1. Update the story's `notes` field with detailed blocker description
2. Do NOT mark `passes: true`
3. Exit the iteration (orchestrator may retry or human can intervene)

---

## File Paths Reference

| File | Path |
|------|------|
| PRD JSON | `product-development/features/$FEATURE_ID/prd.json` |
| Progress | `product-development/features/$FEATURE_ID/progress.txt` |
| Archive | `product-development/features/$FEATURE_ID/archive/` |

---

## Example Iteration Flow

```
1. Read prd.json → Find US-002 (priority 2, passes: false)
2. Read progress.txt → Note pattern: "Use next/image for optimized images"
3. Checkout branch: feature/add-logo
4. Implement: Create Logo component in src/components/ui/Logo.tsx
5. Run npm run build → Pass
6. Run npm run lint → Pass
7. Browser verify → Logo visible at 50x50px → Pass
8. Commit: "feat: US-002 - Add logo component"
9. Update prd.json: US-002.passes = true
10. Update progress.txt with implementation notes
11. Check: US-003, US-004, US-005 still passes: false
12. Exit iteration (no COMPLETE signal)
```
