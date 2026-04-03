---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
handoffs: 
  - label: Create Tasks
    agent: speckit.tasks
    prompt: Break the plan into tasks
    send: true
  - label: Create Checklist
    agent: speckit.checklist
    prompt: Create a checklist for the following domain...
scripts:
  sh: scripts/bash/setup-plan.sh --json
  ps: scripts/powershell/setup-plan.ps1 -Json
agent_scripts:
  sh: scripts/bash/update-agent-context.sh __AGENT__
  ps: scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---

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
- **Planning artifacts** (specs, plans, tasks) live in `.specs/{feature-name}/` within the `*-document` repository
- **Implementation repositories** contain source code and `project-context.md` files with architectural guidance
- This command generates plan.md in the `*-document` repository
- Cross-repository dependencies are documented in the plan for later coordination

**Single-Repository Workspace**:
- All artifacts and code live together in one repository
- Plan artifacts created at `.specs/{feature-name}/`
- `project-context.md` (if present) at repository root

**Artifact Location**: All plan artifacts (plan.md, research.md, data-model.md, contracts/, quickstart.md) are created in `FEATURE_DIR` which is in the `*-document` repository (multi-repo) or at repository root (single-repo).

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before planning)**:
- Locate `.specify/extensions.yml` in the project root (in multi-repo workspaces, this is the `*-document` repository — already the current directory after Section 0).
- If it exists, read it and look for entries under the `hooks.before_plan` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Pre-Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Outline.
    ```
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently

## Outline

1. **Setup**: Run `{SCRIPT}` from repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

   **Multi-Repository Workspace Detection**:
   - Detect if running in a multi-repository workspace by checking for multiple `.git` directories in sibling folders or a workspace configuration file
   - If multi-repo workspace detected:
     - Confirm that `SPECS_DIR` is in the `*-document` repository (planning artifacts repository)
     - Load `project-context.md` from implementation repositories if they exist
     - Scan for `project-context.md` files in sibling repositories to understand the broader system architecture
     - Note any architectural constraints or dependencies mentioned in these context files
   - If single-repo workspace:
     - All artifacts and code are in the same repository
     - Load `project-context.md` from repository root if it exists

2. **Load context**: Read FEATURE_SPEC and `/memory/constitution.md`. Load IMPL_PLAN template (already copied).

   **Architectural Context Integration**:
   - If `project-context.md` exists in the active repository, treat it as authoritative for:
     - Existing tech stack and patterns
     - Integration surfaces and contracts
     - Performance and scalability constraints
     - Security and privacy requirements
   - If multiple `project-context.md` files exist (multi-repo workspace):
     - Identify which repositories this feature will interact with based on spec requirements
     - Load relevant `project-context.md` files to understand integration points
     - Note any cross-repository constraints that must be preserved

3. **Execute plan workflow**: Follow the structure in IMPL_PLAN template to:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
     - If `project-context.md` exists, pre-populate known constraints from it
     - Highlight any spec requirements that conflict with existing architectural constraints
   - Fill Constitution Check section from constitution
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION)
     - Include research tasks for cross-repository integration patterns if applicable
   - Phase 1: Generate data-model.md, contracts/, quickstart.md
     - Ensure contracts align with existing repository contracts if cross-repo dependencies exist
     - Reference relevant `project-context.md` sections in contract design rationale
   - Phase 1: Update agent context by running the agent script
   - Re-evaluate Constitution Check post-design

4. **Stop and report**: Command ends after Phase 2 planning. Report branch, IMPL_PLAN path, and generated artifacts.

   **Cross-Repository Impact Summary** (if multi-repo workspace):
   - List repositories that will be affected by this implementation
   - Identify shared contracts or APIs that must remain compatible
   - Note any data models that span multiple repositories
   - Highlight service boundaries and integration points
   - Recommend reviewing relevant `project-context.md` files before proceeding to `/speckit.tasks`

5. **Check for extension hooks**: After reporting completion, locate `.specify/extensions.yml` in the project root (in multi-repo workspaces, this is the `*-document` repository — already the current directory after Section 0).
   - If it exists, read it and look for entries under the `hooks.after_plan` key
   - If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
   - Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
   - For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
     - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
     - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
   - For each executable hook, output the following based on its `optional` flag:
     - **Optional hook** (`optional: true`):
       ```
       ## Extension Hooks

       **Optional Post-Hook**: {extension}
       Command: `/{command}`
       Description: {description}

       Prompt: {prompt}
       To execute: `/{command}`
       ```
     - **Mandatory hook** (`optional: false`):
       ```
       ## Extension Hooks

       **Automatic Post-Hook**: {extension}
       Executing: `/{command}`
       EXECUTE_COMMAND: {command}
       ```
   - If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task
   - **Multi-Repo**: For each cross-repository integration → compatibility research task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   For each cross-repository integration (if applicable):
     Task: "Research integration patterns between {source-repo} and {target-repo}"
     Task: "Validate compatibility with existing {target-repo} contracts"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]
   - **Cross-Repository Considerations** (if applicable): [how this aligns with or impacts other repositories]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable
   - **Multi-Repo**: Cross-repository entity references and ownership boundaries

2. **Define interface contracts** (if project has external interfaces) → `/contracts/`:
   - Identify what interfaces the project exposes to users or other systems
   - Document the contract format appropriate for the project type
   - Examples: public APIs for libraries, command schemas for CLI tools, endpoints for web services, grammars for parsers, UI contracts for applications
   - Skip if project is purely internal (build scripts, one-off tools, etc.)
   - **Multi-Repo**: Ensure compatibility with existing contracts in dependent repositories
     - Reference specific sections from relevant `project-context.md` files
     - Validate against existing API/contract versions
     - Document any breaking changes and migration strategy

3. **Agent context update**:
   - Run `{AGENT_SCRIPT}`
   - These scripts detect which AI agent is in use
   - Update the appropriate agent-specific context file
   - Add only new technology from current plan
   - Preserve manual additions between markers
   - **Multi-Repo**: Include cross-repository dependencies in context

**Output**: data-model.md, /contracts/*, quickstart.md, agent-specific file

## Key rules

- Use absolute paths in all outputs
- Lock down versions in Phase 1
- If constitution gate fails, ERROR (force justification in Complexity Tracking)
- Mark research decisions in research.md
- **Multi-Repo**: Validate architectural alignment with `project-context.md` files
- **Multi-Repo**: Document cross-repository dependencies explicitly in plan.md Summary section
