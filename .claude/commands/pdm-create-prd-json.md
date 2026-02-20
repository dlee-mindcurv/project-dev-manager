---
allowed-tools: Read, Write, Edit, Grep, Glob
argument-hint: [feature-id]
description: "Convert feature PRDs to prd.json format for the PDM Ralph autonomous agent system. Use when you have an existing PRD and need to convert it to Ralph's JSON format."
---

# PDM PRD to JSON Converter

Converts existing feature `prd.md` located in `product-development/features/[feature-id]` to the prd.json format that PDM Ralph uses for autonomous execution.

---

## Input

Read the PRD from: `product-development/features/$ARGUMENTS/prd.md`

---

## Output Format

```json
{
  "project": "[project-name from product.md or infer from codebase]",
  "appDir": ".",
  "branchName": "feature/[feature-id]",
  "description": "[Feature description from PRD Introduction]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2"
      ],
      "agents": [
        { "name": "build", "agent": "build-user-story", "status": "pending", "dependsOn": null, "notes": "" },
        { "name": "playwright", "agent": "run-playwright", "status": "pending", "dependsOn": "build", "notes": "" },
        { "name": "lint", "agent": "run-lint", "status": "pending", "dependsOn": "playwright", "notes": "" },
        { "name": "typecheck", "agent": "run-typecheck", "status": "pending", "dependsOn": "lint", "notes": "" },
        { "name": "test", "agent": "write-tests", "status": "pending", "dependsOn": "typecheck", "notes": "" }
      ],
      "priority": 1,
      "model": "sonnet",
      "passes": false,
      "notes": ""
    }
  ]
}
```

## Output Location

`product-development/features/$ARGUMENTS/prd.json`

---

## Feature Complexity Assessment (Do This First!)

Before converting stories, assess the feature's complexity to determine the right approach:

| Complexity | Files Changed | Stories | Approach |
|------------|---------------|---------|----------|
| **Trivial** | 1-2 files | 1 story | Consolidate ALL into single story |
| **Small** | 3-5 files | 1-2 stories | Consolidate related work |
| **Medium** | 6-10 files | 3-4 stories | Group by layer (backend/frontend) |
| **Large** | 10+ files | 5+ stories | Full story breakdown |

### Consolidation Rules

**ALWAYS consolidate when:**
- Feature touches ≤ 5 files
- PRD has ≤ 5 user stories
- Stories are tightly coupled (each depends on the previous)
- Feature is a single cohesive unit (e.g., "add dark mode", "add search")

**Example: Dark Mode Toggle (WRONG - 5 stories, ~24 min)**
```
US-001: Theme Context Provider
US-002: Theme Persistence
US-003: Dark Theme Styling
US-004: Theme Toggle Button
US-005: Theme Switching
```

**Example: Dark Mode Toggle (RIGHT - 1 story, ~5 min)**
```
US-001: Dark Mode Toggle
- ThemeContext with useTheme hook provides theme state and toggleTheme function
- Theme preference persists to localStorage (key: taskflow-theme)
- Toggle button in header displays sun icon (dark mode) or moon icon (light mode)
- All components have dark: Tailwind variants (slate-900 bg, slate-100 text)
- Clicking toggle switches theme instantly without page reload
```

### When to Keep Stories Separate

Only split into multiple stories when:
- Database schema must exist before backend logic
- Backend API must exist before frontend can call it
- Feature is genuinely large (auth system, payment integration)
- Independent teams would work on different parts

---

## Model Selection (Speed vs. Capability)

Assign a model to each story based on complexity. Faster models = faster execution + lower cost.

| Model | Use For | Speed |
|-------|---------|-------|
| `haiku` | Simple, mechanical tasks | Fastest (~1-2 min) |
| `sonnet` | Standard features, moderate complexity | Medium (~3-5 min) |
| `opus` | Complex architecture, nuanced decisions | Slowest (~5-8 min) |

### Model Assignment Guidelines

**Use `haiku` for:**
- Adding a single component with clear requirements
- Simple CRUD operations
- Styling changes (add dark mode classes)
- Configuration file updates
- Renaming/refactoring with clear patterns
- Adding straightforward tests

**Use `sonnet` for (default):**
- Features requiring multiple file changes
- Components with state management
- API integrations
- Stories needing architectural decisions
- Browser verification stories (needs reasoning about what to check)

**Use `opus` for:**
- Complex architectural decisions
- Performance optimization requiring analysis
- Security-sensitive implementations
- Stories with ambiguous requirements
- Debugging complex issues

### Example: Multi-Story Feature with Model Assignment

```json
{
  "userStories": [
    {
      "id": "US-001",
      "title": "Add status column to database",
      "model": "haiku",
      "acceptanceCriteria": ["Add status column with default 'pending'"],
      "agents": [
        { "name": "build", "agent": "build-user-story", "status": "pending", "dependsOn": null, "notes": "" },
        { "name": "playwright", "agent": "run-playwright", "status": "pending", "dependsOn": "build", "notes": "" },
        { "name": "lint", "agent": "run-lint", "status": "pending", "dependsOn": "playwright", "notes": "" },
        { "name": "typecheck", "agent": "run-typecheck", "status": "pending", "dependsOn": "lint", "notes": "" },
        { "name": "test", "agent": "write-tests", "status": "pending", "dependsOn": "typecheck", "notes": "" }
      ]
    },
    {
      "id": "US-002",
      "title": "Create status filter API",
      "model": "sonnet",
      "acceptanceCriteria": ["GET /api/tasks accepts ?status param", "Returns filtered results"],
      "agents": "... same agent pipeline as above ..."
    },
    {
      "id": "US-003",
      "title": "Add filter dropdown to UI",
      "model": "sonnet",
      "acceptanceCriteria": ["Dropdown with All/Active/Completed options"],
      "agents": "... same agent pipeline as above ..."
    }
  ]
}
```

**Default:** If unsure, use `sonnet`. It balances speed and capability well.

---

## Story Size: The Number One Rule

**Each story must be completable in ONE PDM Ralph iteration (one context window).**

PDM Ralph spawns a fresh Claude instance per iteration with no memory of previous work. If a story is too big, the LLM runs out of context before finishing and produces broken code.

### Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list
- **A complete small feature** (dark mode, search bar, notification badge)

### Too big (split these):
- "Build the entire dashboard" → Split into: schema, queries, UI components, filters
- "Add authentication" → Split into: schema, middleware, login UI, session handling
- "Refactor the API" → Split into one story per endpoint or pattern

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it is too big. But if the PRD has 5 simple stories that together take 2-3 sentences, CONSOLIDATE them.

---

## Story Ordering: Dependencies First

Stories execute in priority order. Earlier stories must not depend on later ones.

**Correct order:**
1. Schema/database changes (migrations)
2. Server actions / backend logic
3. UI components that use the backend
4. Dashboard/summary views that aggregate data

**Wrong order:**
1. UI component (depends on schema that does not exist yet)
2. Schema change

---


## Acceptance Criteria: Must Be Verifiable

Each criterion must be something PDM Ralph can CHECK, not something vague.

### Good criteria (verifiable):
- "Add `status` column to tasks table with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Clicking delete shows confirmation dialog"

### Bad criteria (vague):
- "Works correctly"
- "User can do X easily"
- "Good UX"
- "Handles edge cases"


## Conversion Rules

1. **Assess complexity first** - Count files/stories, determine if consolidation needed
2. **Consolidate small features** - If ≤5 PRD stories AND ≤5 files, merge into 1-2 JSON stories
3. **Combine acceptance criteria** - When consolidating, merge all criteria into the single story
4. **Assign models** - Use `haiku` for simple tasks, `sonnet` for standard, `opus` for complex
5. **IDs**: Sequential (US-001, US-002, etc.) - renumber after consolidation
6. **Priority**: Based on dependency order, then document order
7. **All stories**: `passes: false` and empty `notes`
8. **branchName**: `feature/[feature-id]`
9. **Agents pipeline**: Every story must include the standard 5-agent pipeline (`build → playwright → lint → typecheck → test`)

---

## Checklist Before Saving

Before writing prd.json, verify:

- [ ] **Assessed complexity** - Counted files/stories to determine consolidation
- [ ] **Consolidated if small** - Features with ≤5 PRD stories merged into 1-2 JSON stories
- [ ] **Assigned models** - haiku for simple, sonnet for standard, opus for complex
- [ ] Each story is completable in one iteration (small enough)
- [ ] Stories are ordered by dependency (schema → backend → UI)
- [ ] **Only final story** has "Verify in browser" (not intermediate stories)
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] No story depends on a later story
- [ ] Remove any specific acceptance criteria involving creating unit tests, linting, typechecking, as these tasks handled by other agents
- [ ] All stories have `passes: false` and empty `notes`
- [ ] **Agents pipeline** - Every story includes the 5-agent array (build, playwright, lint, typecheck, test)

---

## Next Step

After saving prd.json exit claude code.
