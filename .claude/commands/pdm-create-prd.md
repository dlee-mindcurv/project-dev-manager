---
allowed-tools: Read, Write, Edit, Grep, Glob
argument-hint: [feature-id]
description: Create Product Requirements Document (PRD) for new features
---

# Create Product Requirements Document

You are an experienced Product Manager. Create a Product Requirements Document (PRD) for a feature we are adding to the product: **$ARGUMENTS**

**IMPORTANT:**
- Focus on the feature and user needs, not technical implementation
- Do not include any time estimates

## Product Context

1. **Product Documentation**: @product-development/resources/product.md (to understand the product)
2. **Feature Documentation**: @product-development/features/$ARGUMENTS/feature.md (to understand the feature idea)
3. **JTBD Documentation**: @product-development/features/$ARGUMENTS/jtbd.md (to understand the Jobs to be Done)

## Task

Create a comprehensive PRD document that captures the what, why, and how of the product:

1. Use the PRD template from `@product-development/resources/PRD-template.md`

## Contents 
Based on the feature documentation, create a PRD that defines:

1. Introduction/Overview

Brief description of the feature and the problem it solves.

2. Goals

Specific, measurable objectives (bullet list).

3. User Stories

Each story needs:

Title: Short descriptive name
Description: "As a [user], I want [feature] so that [benefit]"
Acceptance Criteria: Verifiable checklist of what "done" means
Each story should be small enough to implement in one focused session.

Format:

### US-001: [Title]
**Description:** As a [user], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] Specific verifiable criterion
- [ ] Another criterion
  Important:

Acceptance criteria must be verifiable, not vague. "Works correctly" is bad. "Button shows confirmation dialog before deleting" is good.

4. Functional Requirements

Numbered list of specific functionalities:

"FR-1: The system must allow users to..."
"FR-2: When a user clicks X, the system must..."
Be explicit and unambiguous.

5. Non-Goals (Out of Scope)

What this feature will NOT include. Critical for managing scope.

6. Design Considerations (Optional)

UI/UX requirements
Link to mockups if available
Relevant existing components to reuse

7. Technical Considerations (Optional)

Known constraints or dependencies
Integration points with existing systems
Performance requirements
8. Success Metrics

How will success be measured?

"Reduce time to complete X by 50%"
"Increase conversion rate by 10%"
9. Open Questions

Remaining questions or areas needing clarification.


## Checklist

Before saving the PRD:

- [ ] User stories are small and specific
- [ ] Functional requirements are numbered and unambiguous
- [ ] Non-goals section defines clear boundaries
- [ ] Saved to `product-development/features/$ARGUMENTS/prd.md`

## Next Step

After successfully saving the PRD, automatically run the `/pdm-create-prd-json` command to generate the PDM Ralph-compatible prd.json:

```
/pdm-create-prd-json $ARGUMENTS
```

This converts the PRD into the structured JSON format needed for autonomous execution with PDM Ralph.
