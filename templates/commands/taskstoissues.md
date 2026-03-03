---
description: Convert existing tasks into actionable, dependency-ordered GitHub issues for the feature based on available design artifacts.
tools: ['github/github-mcp-server/issue_write']
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

## Workspace Architecture Context

This command operates within the Spec Kit workspace architecture:

**Multi-Repository Workspace**:
- Reads tasks from `.specs/{feature-name}/tasks.md` in the `*-document` repository
- **CRITICAL**: GitHub issues are created in the Git remote repository, which may be different from the `*-document` repository
- Use `[repo-name]` labels in tasks to determine which repository should receive issues
- For cross-repo tasks, create issues in the target implementation repository

**Single-Repository Workspace**:
- Reads tasks from `.specs/{feature-name}/tasks.md` at repository root
- Creates issues in the current repository (same as Git remote)
- All `[repo-name]` labels reference the same repository

**Important**: This command converts tasks to GitHub issues. Always verify the Git remote matches the intended issue repository before proceeding.

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").
1. From the executed script, extract the path to **tasks**.
1. Get the Git remote by running:

```bash
git config --get remote.origin.url
```

> [!CAUTION]
> ONLY PROCEED TO NEXT STEPS IF THE REMOTE IS A GITHUB URL

1. For each task in the list, use the GitHub MCP server to create a new issue in the repository that is representative of the Git remote.

> [!CAUTION]
> UNDER NO CIRCUMSTANCES EVER CREATE ISSUES IN REPOSITORIES THAT DO NOT MATCH THE REMOTE URL
