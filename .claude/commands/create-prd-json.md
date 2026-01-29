---
allowed-tools: Read, Write, Edit, Grep, Glob
argument-hint: [Project Name], [feature-id]
description: "Convert feature PRDs to prd.json format for a Ralph style  autonomous agent system. Use when you have an existing PRD and need to convert it to Ralph's JSON format."
---

# PRD to JSON Converter

Converts existing feature `prd.md` located in `product-development/features/[feature-id]` to the prd.json format that Ralph uses for autonomous execution.

---

## Output Format

```json
{
  "project": "[project-name]",
  "branchName": "feature/[feature-id]",
  "description": "[Feature description from PRD Introduction]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```


## Output location
`product-development/features/[feature-id]/prd.json`