# Project Dev Manager

An autonomous feature development framework powered by Claude Code. Transform feature ideas into working code through a structured workflow that generates documentation, validates requirements, and implements features automatically.

## Overview

Project Dev Manager streamlines the software development process by guiding features through a complete lifecycle:

```
Feature Idea → JTBD Analysis → PRD → prd.json → Generated Code
```

Each step builds on the previous, ensuring requirements are well-understood before implementation begins. The final step uses Claude to autonomously implement user stories, running quality checks and committing code as it progresses.

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- Node.js 18+ (for Next.js projects)
- Git
- `jq` (for JSON processing)

## Project Structure

```
project-dev-manager/
├── .claude/
│   ├── commands/           # Slash commands for Claude Code
│   │   ├── create-jtbd.md      # /create-jtbd - Jobs-to-be-Done analysis
│   │   ├── create-prd.md       # /create-prd - Product Requirements Document
│   │   ├── create-prd-json.md  # /create-prd-json - Convert PRD to JSON
│   │   └── ralph-execute.md    # /ralph-execute - Run autonomous execution
│   └── skills/             # Claude Code skills
│       ├── ralph/              # PRD conversion skill
│       ├── ralph-loop/         # Iteration loop instructions
│       ├── webapp-testing/     # Browser verification
│       └── ...
├── scripts/
│   ├── acquire-feature.sh      # Interactive feature intake
│   └── generate-feature-code.sh # Autonomous code generation
├── product-development/
│   ├── resources/          # Templates and product docs
│   │   ├── product.md          # Product overview
│   │   ├── JTBD-template.md    # JTBD template
│   │   └── PRD-template.md     # PRD template
│   └── features/           # Feature workspaces
│       └── <feature-id>/
│           ├── feature.md      # Initial feature description
│           ├── jtbd.md         # Jobs-to-be-Done analysis
│           ├── prd.md          # Product Requirements Document
│           ├── prd.json        # Machine-readable stories
│           └── progress.txt    # Implementation log
└── LEARNINGS.md            # Accumulated patterns across features
```

## Workflow

### 1. Define a Feature

Create a feature directory with a basic description:

```bash
mkdir -p product-development/features/my-feature
cat > product-development/features/my-feature/feature.md << 'EOF'
# Feature: My Feature

## Description

Brief description of what you want to build.

## Status

- Created: $(date '+%Y-%m-%d %H:%M:%S')
- Status: Draft
EOF
```

Or use the interactive script:

```bash
./scripts/acquire-feature.sh
```

### 2. Generate JTBD Analysis

In Claude Code, run:

```
/create-jtbd my-feature
```

This creates a Jobs-to-be-Done analysis that captures:
- User motivations and pain points
- Desired outcomes
- Competitive analysis
- Success criteria

### 3. Generate PRD

The JTBD command automatically chains to:

```
/create-prd my-feature
```

This produces a Product Requirements Document with:
- User stories with acceptance criteria
- Functional requirements
- Non-goals and scope boundaries
- Technical considerations

### 4. Convert to prd.json

```
/create-prd-json my-feature
```

Converts the PRD into a machine-readable format that the code generator uses. Stories are:
- Consolidated for efficiency (small features become 1-2 stories)
- Ordered by dependency
- Assigned appropriate AI models (haiku/sonnet/opus)

### 5. Generate Code

```
/ralph-execute my-feature
```

Or via script:

```bash
./scripts/generate-feature-code.sh --feature my-feature
```

The generator:
1. Creates/checks out the feature branch
2. Implements one user story per iteration
3. Runs quality checks (build, lint, browser verification)
4. Commits on success
5. Updates prd.json status
6. Loops until all stories pass

## Available Commands

| Command | Description |
|---------|-------------|
| `/create-jtbd <feature-id>` | Generate Jobs-to-be-Done analysis |
| `/create-prd <feature-id>` | Generate Product Requirements Document |
| `/create-prd-json <feature-id>` | Convert PRD to machine-readable JSON |
| `/ralph-execute <feature-id>` | Run autonomous code generation |

## Scripts

### acquire-feature.sh

Interactive feature intake that:
- Prompts for feature name and description
- Creates feature directory structure
- Updates feature status tracking

```bash
./scripts/acquire-feature.sh
```

### generate-feature-code.sh

Autonomous code generation orchestrator:

```bash
./scripts/generate-feature-code.sh --feature <feature-id> [--max-iterations <n>]
```

Options:
- `--feature, -f` - Feature ID (required)
- `--max-iterations` - Maximum iterations before stopping (default: 10)

## Configuration

### Model Selection

Stories in prd.json can specify which Claude model to use:

| Model | Use For |
|-------|---------|
| `haiku` | Simple, mechanical tasks (fastest) |
| `sonnet` | Standard features, moderate complexity (default) |
| `opus` | Complex architecture, nuanced decisions |

### Quality Gates

Each iteration runs these checks before committing:
- TypeScript compilation (`npm run build`)
- Linting (`npm run lint`) - final story only
- Browser verification (UI stories) - final story only

## Project Learnings

The framework accumulates learnings across features in `LEARNINGS.md`. When starting a new feature, the generator reads previous patterns to apply consistent solutions.

## Example Session

```bash
# 1. Create feature idea
mkdir -p product-development/features/dark-mode
echo "# Feature: Dark Mode Toggle" > product-development/features/dark-mode/feature.md

# 2. In Claude Code, generate documentation
> /create-jtbd dark-mode
# Creates jtbd.md, then chains to...
# /create-prd dark-mode
# Creates prd.md

# 3. Convert to executable format
> /create-prd-json dark-mode
# Creates prd.json with consolidated stories

# 4. Generate the code
> /ralph-execute dark-mode
# Implements feature, commits, updates status

# Output:
# ╔═══════════════════════════════════════════════════════════════╗
# ║                    ALL STORIES COMPLETE!                      ║
# ╚═══════════════════════════════════════════════════════════════╝
# Stories: 1/1 complete
# Branch: feature/dark-mode
```

## Troubleshooting

### "prd.json not found"

Run `/create-prd-json <feature-id>` to generate it from the PRD.

### "Max iterations reached"

- Check `progress.txt` in the feature directory for blockers
- Review the `notes` field in incomplete stories
- Fix issues manually and re-run

### "Quality checks failing"

- Check the iteration output for specific errors
- Fix issues in the codebase
- Re-run to continue from where it left off

## Inspiration

The autonomous execution approach is inspired by [snarktank/ralph](https://github.com/snarktank/ralph).

## License

MIT
