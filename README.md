# PDM - Project Dev Manager

An autonomous feature development framework powered by Claude Code. Transform feature ideas into working code through a structured workflow that generates documentation, validates requirements, and implements features automatically.

## Overview

PDM streamlines the software development process by guiding features through a complete lifecycle:

```
Feature Idea → JTBD Analysis → PRD → prd.json → Generated Code
```

Each step builds on the previous, ensuring requirements are well-understood before implementation begins. The final step uses Claude to autonomously implement user stories, running quality checks and committing code as it progresses.

## Quick Start

### 1. Install PDM

```bash
# Download and install the pdm CLI tool
curl -sL https://raw.githubusercontent.com/dlee-mindcurv/project-dev-manager/main/pdm -o ~/.local/bin/pdm
chmod +x ~/.local/bin/pdm

# Install skills and commands to ~/.claude/
pdm --install

# Verify installation
pdm --list
pdm --check
```

### 2. Use PDM commands in Claude Code

```bash
# In any project with product-development/features/ structure
claude

# Create documentation chain
> /pdm-create-jtbd my-feature
> /pdm-create-prd my-feature
> /pdm-create-prd-json my-feature

# Execute autonomous implementation
> /pdm-ralph-execute my-feature
```

Or use the CLI directly:

```bash
pdm --feature my-feature
```

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- Node.js 18+ (for Next.js projects)
- Git
- curl (for installation)

**Note:** `jq` is no longer required - PDM uses Node.js for JSON processing.

## Installation

### Option A: Global Installation (Recommended)

```bash
# Install pdm CLI
curl -sL https://raw.githubusercontent.com/dlee-mindcurv/project-dev-manager/main/pdm -o ~/.local/bin/pdm
chmod +x ~/.local/bin/pdm

# Install PDM skills and commands
pdm --install
```

### Option B: Symlink from Source

```bash
# Clone the repo
git clone https://github.com/dlee-mindcurv/project-dev-manager.git
cd project-dev-manager

# Symlink pdm to your PATH
ln -s $(pwd)/pdm ~/.local/bin/pdm

# Install skills and commands
pdm --install
```

## PDM CLI Commands

### Installation Commands

```bash
pdm --install              # Install all skills and commands to ~/.claude/
pdm --install skills       # Install only skills
pdm --install commands     # Install only commands
pdm --update               # Force re-download everything
pdm --uninstall            # Remove all pdm-* skills and commands
```

### Info Commands

```bash
pdm --list                 # Show installed pdm-* items
pdm --check                # Verify dependencies (Claude CLI, Node, Git, curl)
```

### Feature Execution

```bash
pdm --feature <id>         # Run PDM Ralph on a feature
pdm -f <id> --max-iterations <n>  # With custom iteration limit
```

### Meta

```bash
pdm --version
pdm --help
```

## Available Slash Commands

After running `pdm --install`, these commands are available in Claude Code:

| Command | Description |
|---------|-------------|
| `/pdm-create-jtbd <feature-id>` | Generate Jobs-to-be-Done analysis |
| `/pdm-create-prd <feature-id>` | Generate Product Requirements Document |
| `/pdm-create-prd-json <feature-id>` | Convert PRD to machine-readable JSON |
| `/pdm-ralph-execute <feature-id>` | Run autonomous code generation |
| `/pdm-code-review` | Comprehensive code quality review |
| `/pdm-create-prp` | Create Product Requirement Prompt |

## Installed Skills

| Skill | Description |
|-------|-------------|
| `pdm-ralph` | PRD to prd.json converter |
| `pdm-ralph-loop` | Iteration loop instructions |
| `pdm-webapp-testing` | Browser verification with Playwright |
| `pdm-code-reviewer` | Code review toolkit |
| `pdm-react-best-practices` | React/Next.js optimization patterns |

## Project Structure

For PDM to work in your project, create this structure:

```
your-project/
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

### 2. Generate Documentation

In Claude Code:

```
/pdm-create-jtbd my-feature    # Creates JTBD analysis
/pdm-create-prd my-feature     # Creates PRD (auto-chained from JTBD)
/pdm-create-prd-json my-feature # Converts PRD to executable JSON
```

### 3. Execute Autonomous Generation

In Claude Code:

```
/pdm-ralph-execute my-feature
```

Or via CLI:

```bash
pdm --feature my-feature
```

The generator:
1. Creates/checks out the feature branch
2. Implements one user story per iteration
3. Runs quality checks (build, lint, browser verification)
4. Commits on success
5. Updates prd.json status
6. Loops until all stories pass

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

## Example Session

```bash
# 1. Create feature idea
mkdir -p product-development/features/dark-mode
echo "# Feature: Dark Mode Toggle" > product-development/features/dark-mode/feature.md

# 2. In Claude Code, generate documentation
> /pdm-create-jtbd dark-mode
# Creates jtbd.md, then chains to...
# /pdm-create-prd dark-mode
# Creates prd.md

# 3. Convert to executable format
> /pdm-create-prd-json dark-mode
# Creates prd.json with consolidated stories

# 4. Generate the code
> /pdm-ralph-execute dark-mode
# Or: pdm --feature dark-mode

# Output:
# ╔═══════════════════════════════════════════════════════════════╗
# ║                    ALL STORIES COMPLETE!                      ║
# ╚═══════════════════════════════════════════════════════════════╝
# Stories: 1/1 complete
# Branch: feature/dark-mode
```

## Troubleshooting

### "prd.json not found"

Run `/pdm-create-prd-json <feature-id>` to generate it from the PRD.

### "Max iterations reached"

- Check `progress.txt` in the feature directory for blockers
- Review the `notes` field in incomplete stories
- Fix issues manually and re-run

### "Quality checks failing"

- Check the iteration output for specific errors
- Fix issues in the codebase
- Re-run to continue from where it left off

### Skills/commands not available

```bash
# Re-install PDM tools
pdm --update

# Verify installation
pdm --list
```

## Uninstalling

```bash
# Remove PDM skills and commands
pdm --uninstall

# Remove the CLI
rm ~/.local/bin/pdm
```

## Inspiration

The autonomous execution approach is inspired by [snarktank/ralph](https://github.com/snarktank/ralph).

## License

MIT
