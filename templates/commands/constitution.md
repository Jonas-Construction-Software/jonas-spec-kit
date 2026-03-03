---
description: Create or update the project constitution from interactive or provided principle inputs, ensuring all dependent templates stay in sync.
handoffs: 
  - label: Build Specification
    agent: speckit.specify
    prompt: Implement the feature specification based on the updated constitution. I want to build...
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Default Prompt Input

Before processing placeholders, load the default constitution prompt from:

`.specify/templates/constitution-prompt.md`

If the file exists, treat its contents as the baseline instruction set for
`/speckit.constitution`.

### Input Merge Rules (Required)

1. Build an **effective input** by combining:
   - Baseline: `.specify/templates/constitution-prompt.md` (if present)
   - User input: `$ARGUMENTS` (if provided)
2. If both are present, append user input as **additional directives** and
   resolve conflicts in favor of explicit user input.
3. If only baseline exists, use baseline as the effective input.
4. If only user input exists, use user input as the effective input.
5. Do not ignore baseline constraints unless the user explicitly requests to
   replace them.

## 0. Repository Location Validation (Multi-Repo Workspaces)

**Before executing any steps below:**

1. **Detect workspace type**:
   - Check for multiple `.git` directories in parent/sibling folders
   - If found → multi-repository workspace
   - If not found → single-repository workspace (skip to Workspace Architecture Context section)

2. **For multi-repo workspaces only**:
   - Identify current repository name from `.git/config` or current directory
   - If current repository name ends with `-document`:
     ✅ Proceed to Workspace Architecture Context section (already in correct repository)
   - If current repository does NOT end with `-document`:
     a. Search sibling directories for `*-document` repository
     b. If found:
        - **Switch working directory** to `*-document` repository root
        - Report: `📂 Switched to planning repository: <repo-name>-document`
        - Proceed to Workspace Architecture Context section
     c. If NOT found:
        ❌ ERROR: "Multi-repo workspace detected but no *-document repository found. Planning artifacts must live in a repository ending with '-document'. Please create one or run this command from the document repository."
        - Exit with error code 1

3. **For single-repo workspaces**:
   - No switching needed - all artifacts in current repository
   - Proceed to Workspace Architecture Context section

## Workspace Architecture Context

This command operates within the Spec Kit workspace architecture:

**Multi-Repository Workspace**:
- **`*-document` repository**: Holds ALL planning artifacts including:
  - `.specify/memory/constitution.md` (this file)
  - `.specify/templates/` (command and artifact templates)
  - `.specify/scripts/` (automation scripts)
  - `.specs/` (feature specifications, plans, tasks, checklists)
- **Implementation repositories**: Contain source code and `project-context.md` files describing architecture
- The constitution applies to all work across all repositories in the workspace

**Single-Repository Workspace**:
- All artifacts and code live together in one repository
- `.specify/memory/constitution.md` resides at repository root
- `project-context.md` (if present) also at repository root

## Outline

You are updating the project constitution at `.specify/memory/constitution.md`. This file is a TEMPLATE containing placeholder tokens in square brackets (e.g. `[PROJECT_NAME]`, `[PRINCIPLE_1_NAME]`). Your job is to (a) collect/derive concrete values, (b) fill the template precisely, and (c) propagate any amendments across dependent artifacts.

**Artifact Location**: 
- Multi-repo: `.specify/memory/constitution.md` in the `*-document` repository
- Single-repo: `.specify/memory/constitution.md` at repository root

**Note**: If `.specify/memory/constitution.md` does not exist yet, it should have been initialized from `.specify/templates/constitution-template.md` during project setup. If it's missing, copy the template first.

Follow this execution flow:

1. Load the existing constitution at `.specify/memory/constitution.md`.
   - Identify every placeholder token of the form `[ALL_CAPS_IDENTIFIER]`.
   **IMPORTANT**: The user might require less or more principles than the ones used in the template. If a number is specified, respect that - follow the general template. You will update the doc accordingly.

2. Collect/derive values for placeholders:
   - Use the **effective input** (baseline prompt + merged user directives) as
     the primary source of truth for principle content.
   - If merged input supplies a value, use it.
    - Otherwise infer from existing repo context (README, docs, prior constitution versions if embedded).
    - **Architectural reference requirement**: if `project-context.md` exists, treat it as a primary
       architectural input when deriving principles, constraints, and governance language.
    - **Multi-repo workspaces**: Check implementation repository roots for `project-context.md` files and
       incorporate relevant architectural constraints into the constitution context.
    - **Single-repo workspaces**: Check for `project-context.md` at repository root if present.
   - For governance dates: `RATIFICATION_DATE` is the original adoption date (if unknown ask or mark TODO), `LAST_AMENDED_DATE` is today if changes are made, otherwise keep previous.
   - `CONSTITUTION_VERSION` must increment according to semantic versioning rules:
     - MAJOR: Backward incompatible governance/principle removals or redefinitions.
     - MINOR: New principle/section added or materially expanded guidance.
     - PATCH: Clarifications, wording, typo fixes, non-semantic refinements.
   - If version bump type ambiguous, propose reasoning before finalizing.

3. Draft the updated constitution content:
   - Replace every placeholder with concrete text (no bracketed tokens left except intentionally retained template slots that the project has chosen not to define yet—explicitly justify any left).
   - Preserve heading hierarchy and comments can be removed once replaced unless they still add clarifying guidance.
   - Ensure each Principle section: succinct name line, paragraph (or bullet list) capturing non‑negotiable rules, explicit rationale if not obvious.
   - Ensure Governance section lists amendment procedure, versioning policy, and compliance review expectations.
   - Ensure the constitution explicitly states that available `project-context.md` files are
       authoritative architectural references for specification and planning activities.

4. Consistency propagation checklist (convert prior checklist into active validations):
   - Read `.specify/templates/plan-template.md` and ensure any "Constitution Check" or rules align with updated principles.
   - Read `.specify/templates/spec-template.md` for scope/requirements alignment—update if constitution adds/removes mandatory sections or constraints.
   - Read `.specify/templates/tasks-template.md` and ensure task categorization reflects new or removed principle-driven task types (e.g., observability, versioning, testing discipline).
   - Read each command file in `.specify/templates/commands/*.md` (including this one) to verify no outdated references (agent-specific names like CLAUDE only) remain when generic guidance is required.
   - Read any runtime guidance docs (e.g., `README.md`, `docs/quickstart.md`, or agent-specific guidance files if present). Update references to principles changed.

5. Produce a Sync Impact Report (prepend as an HTML comment at top of the constitution file after update):
   - Version change: old → new
   - List of modified principles (old title → new title if renamed)
   - Added sections
   - Removed sections
   - Templates requiring updates (✅ updated / ⚠ pending) with file paths
   - Follow-up TODOs if any placeholders intentionally deferred.

6. Validation before final output:
   - No remaining unexplained bracket tokens.
   - Version line matches report.
   - Dates ISO format YYYY-MM-DD.
   - Principles are declarative, testable, and free of vague language ("should" → replace with MUST/SHOULD rationale where appropriate).
    - If `project-context.md` exists in one or more repos, verify the constitution includes an
       explicit reference to those files as architectural guidance.

7. Write the completed constitution back to `.specify/memory/constitution.md` (overwrite).

8. Output a final summary to the user with:
   - New version and bump rationale.
   - Any files flagged for manual follow-up.
   - Suggested commit message (e.g., `docs: amend constitution to vX.Y.Z (principle additions + governance update)`).

Formatting & Style Requirements:

- Use Markdown headings exactly as in the template (do not demote/promote levels).
- Wrap long rationale lines to keep readability (<100 chars ideally) but do not hard enforce with awkward breaks.
- Keep a single blank line between sections.
- Avoid trailing whitespace.

If the user supplies partial updates (e.g., only one principle revision), still perform validation and version decision steps.

If critical info missing (e.g., ratification date truly unknown), insert `TODO(<FIELD_NAME>): explanation` and include in the Sync Impact Report under deferred items.

Do not create a new template; always operate on the existing `.specify/memory/constitution.md` file.
