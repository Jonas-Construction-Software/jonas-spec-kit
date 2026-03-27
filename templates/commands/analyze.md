---
description: Perform a non-destructive cross-artifact consistency and quality analysis across spec.md, plan.md, and tasks.md after task generation, with multi-repository workspace support.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
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
- Analyzes artifacts in `.specs/{feature-name}/` within the `*-document` repository
- Validates cross-repository consistency using `project-context.md` files from implementation repositories
- Checks task `[repo-name]` labels for proper cross-repo sequencing
- This is a READ-ONLY analysis command - no files are modified

**Single-Repository Workspace**:
- Analyzes artifacts at `.specs/{feature-name}/`
- All `[repo-name]` labels reference the same repository
- Validates against single `project-context.md` if present
- No cross-repository consistency checks needed

**Artifact Location**: All analyzed files (spec.md, plan.md, tasks.md) are in `FEATURE_DIR` which is in the `*-document` repository (multi-repo) or at repository root (single-repo).

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Goal

Identify inconsistencies, duplications, ambiguities, and underspecified items across the three core artifacts (`spec.md`, `plan.md`, `tasks.md`) before implementation. This command MUST run only after `/speckit.tasks` has successfully produced a complete `tasks.md`.

**Multi-Repository Support**: In multi-repository workspaces, this analysis also validates cross-repository consistency, contract compatibility, and architectural alignment with `project-context.md` files.

## Operating Constraints

**STRICTLY READ-ONLY**: Do **not** modify any files. Output a structured analysis report. Offer an optional remediation plan (user must explicitly approve before any follow-up editing commands would be invoked manually).

**Constitution Authority**: The project constitution (`/memory/constitution.md`) is **non-negotiable** within this analysis scope. Constitution conflicts are automatically CRITICAL and require adjustment of the spec, plan, or tasks—not dilution, reinterpretation, or silent ignoring of the principle. If a principle itself needs to change, that must occur in a separate, explicit constitution update outside `/speckit.analyze`.

**Architectural Authority** (Multi-Repo): The `project-context.md` files in each repository are authoritative for architectural constraints, integration contracts, and repository boundaries. Misalignments are flagged as HIGH severity.

## Execution Steps

### 1. Initialize Analysis Context

Run `{SCRIPT}` once from repo root and parse JSON for FEATURE_DIR and AVAILABLE_DOCS. Derive absolute paths:

- SPEC = FEATURE_DIR/spec.md
- PLAN = FEATURE_DIR/plan.md
- TASKS = FEATURE_DIR/tasks.md

Abort with an error message if any required file is missing (instruct the user to run missing prerequisite command).
For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

**Multi-Repository Workspace Detection**:
- Detect if running in a multi-repository workspace by checking for multiple `.git` directories in sibling folders or a workspace configuration file
- If multi-repo workspace detected:
  - Confirm that `FEATURE_DIR` is in the `*-document` repository (planning artifacts repository)
  - Load `project-context.md` from implementation repositories if they exist
  - Scan `plan.md` and `tasks.md` for cross-repository references (repository labels like `[shared-contracts]`, `[api-service]`)
  - Load `project-context.md` files from any referenced repositories to validate architectural constraints
  - Build a map of cross-repository dependencies and integration points
- If single-repo workspace:
  - All artifacts and code are in the same repository
  - All `[repo-name]` labels in tasks.md will be identical
  - Load single `project-context.md` from repository root if it exists
  - Skip cross-repository consistency checks

### 2. Load Artifacts (Progressive Disclosure)

Load only the minimal necessary context from each artifact:

**From spec.md:**

- Overview/Context
- Functional Requirements
- Success Criteria (measurable outcomes — e.g., performance, security, availability, user success, business impact)
- User Stories
- Edge Cases (if present)
- Clarifications section (if present) - validates that clarifications were properly integrated

**From plan.md:**

- Architecture/stack choices
- Data Model references
- Phases
- Technical constraints
- **Multi-Repo**: Cross-Repository Impact Summary (if present)
- **Multi-Repo**: Contract compatibility notes

**From tasks.md:**

- Task IDs
- Descriptions
- Phase grouping
- Parallel markers [P]
- Referenced file paths
- **Multi-Repo**: Repository labels `[repo-name]`
- **Multi-Repo**: Cross-repository task sequences and dependencies

**From constitution:**

- Load `/memory/constitution.md` for principle validation

**From project-context.md files** (if multi-repo workspace):
- Architectural constraints and patterns
- Existing contracts and integration surfaces
- Technology stack and framework versions
- Security and privacy requirements
- Performance and scalability constraints
- Cross-repository integration points

### 3. Build Semantic Models

Create internal representations (do not include raw artifacts in output):

- **Requirements inventory**: For each Functional Requirement (FR-###) and Success Criterion (SC-###), record a stable key. Use the explicit FR-/SC- identifier as the primary key when present, and optionally also derive an imperative-phrase slug for readability (e.g., "User can upload file" → `user-can-upload-file`). Include only Success Criteria items that require buildable work (e.g., load-testing infrastructure, security audit tooling), and exclude post-launch outcome metrics and business KPIs (e.g., "Reduce support tickets by 50%").
- **User story/action inventory**: Discrete user actions with acceptance criteria
- **Task coverage mapping**: Map each task to one or more requirements or stories (inference by keyword / explicit reference patterns like IDs or key phrases)
- **Constitution rule set**: Extract principle names and MUST/SHOULD normative statements
- **Multi-Repo**: Cross-repository dependency graph (repository → contracts → consuming repositories)
- **Multi-Repo**: Architectural constraint map (repository → constraints from `project-context.md`)

### 4. Detection Passes (Token-Efficient Analysis)

Focus on high-signal findings. Limit to 50 findings total; aggregate remainder in overflow summary.

#### A. Duplication Detection

- Identify near-duplicate requirements
- Mark lower-quality phrasing for consolidation

#### B. Ambiguity Detection

- Flag vague adjectives (fast, scalable, secure, intuitive, robust) lacking measurable criteria
- Flag unresolved placeholders (TODO, TKTK, ???, `<placeholder>`, etc.)

#### C. Underspecification

- Requirements with verbs but missing object or measurable outcome
- User stories missing acceptance criteria alignment
- Tasks referencing files or components not defined in spec/plan

#### D. Constitution Alignment

- Any requirement or plan element conflicting with a MUST principle
- Missing mandated sections or quality gates from constitution

#### E. Coverage Gaps

- Requirements with zero associated tasks
- Tasks with no mapped requirement/story
- Success Criteria requiring buildable work (performance, security, availability) not reflected in tasks

#### F. Inconsistency

- Terminology drift (same concept named differently across files)
- Data entities referenced in plan but absent in spec (or vice versa)
- Task ordering contradictions (e.g., integration tasks before foundational setup tasks without dependency note)
- Conflicting requirements (e.g., one requires Next.js while other specifies Vue)

#### G. Cross-Repository Consistency (Multi-Repo Only)

**Contract Compatibility**:
- Tasks that modify shared contracts without corresponding tasks in consuming repositories
- Contract changes that conflict with `project-context.md` constraints
- Breaking changes to contracts without versioning or migration tasks
- Contract tasks not sequenced before dependent repository tasks

**Architectural Alignment**:
- Plan decisions that conflict with architectural constraints in `project-context.md`
- Technology choices that contradict existing repository patterns
- Integration patterns that violate repository boundary constraints
- Security or privacy requirements that differ across repositories

**Dependency Sequencing**:
- Cross-repository tasks without proper sequencing constraints
- Parallel markers `[P]` on tasks with cross-repo dependencies
- Missing integration validation tasks between repositories
- Setup/foundational tasks not accounting for cross-repo prerequisites

**Data Model Consistency**:
- Entities referenced in multiple repositories without ownership documentation
- Data synchronization needs not reflected in tasks
- Conflicting entity definitions across repositories

### 5. Severity Assignment

Use this heuristic to prioritize findings:

- **CRITICAL**: Violates constitution MUST, missing core spec artifact, requirement with zero coverage that blocks baseline functionality, **cross-repository contract breaking change without migration path**, **architectural constraint violation from `project-context.md`**
- **HIGH**: Duplicate or conflicting requirement, ambiguous security/performance attribute, untestable acceptance criterion, **cross-repo task sequencing error**, **contract compatibility issue**
- **MEDIUM**: Terminology drift, missing non-functional task coverage, underspecified edge case, **missing cross-repo integration validation**
- **LOW**: Style/wording improvements, minor redundancy not affecting execution order

### 6. Produce Compact Analysis Report

Output a Markdown report (no file writes) with the following structure:

## Specification Analysis Report

| ID | Category | Severity | Location(s) | Summary | Recommendation |
|----|----------|----------|-------------|---------|----------------|
| A1 | Duplication | HIGH | spec.md:L120-134 | Two similar requirements ... | Merge phrasing; keep clearer version |
| G1 | Cross-Repo Contract | CRITICAL | tasks.md:T015, shared-contracts/project-context.md:§API-Contracts | Breaking change to TaskDto without migration | Add contract versioning tasks in T016-T017 |

(Add one row per finding; generate stable IDs prefixed by category initial.)

**Coverage Summary Table:**

| Requirement Key | Has Task? | Task IDs | Notes |
|-----------------|-----------|----------|-------|

**Constitution Alignment Issues:** (if any)

**Unmapped Tasks:** (if any)

**Cross-Repository Consistency** (if multi-repo workspace):

| Issue Type | Severity | Affected Repositories | Summary |
|------------|----------|----------------------|---------|
| Contract Breaking Change | CRITICAL | shared-contracts → api-service, frontend | TaskDto field removal without migration |
| Architectural Conflict | HIGH | api-service | Plan proposes REST while project-context.md requires GraphQL |

**Metrics:**

- Total Requirements
- Total Tasks
- Coverage % (requirements with >=1 task)
- Ambiguity Count
- Duplication Count
- Critical Issues Count
- **Multi-Repo**: Cross-Repository Tasks Count
- **Multi-Repo**: Contract Compatibility Issues Count
- **Multi-Repo**: Architectural Alignment Issues Count

### 7. Provide Next Actions

At end of report, output a concise Next Actions block:

- If CRITICAL issues exist: Recommend resolving before `/speckit.implement`
- **Multi-Repo**: If cross-repo CRITICAL issues exist, recommend coordinating with affected repository owners
- If only LOW/MEDIUM: User may proceed, but provide improvement suggestions
- Provide explicit command suggestions: e.g., "Run /speckit.specify with refinement", "Run /speckit.plan to adjust architecture", "Manually edit tasks.md to add coverage for 'performance-metrics'"
- **Multi-Repo**: "Review `project-context.md` in [repo-name] for architectural constraints", "Add contract migration tasks for shared-contracts repository"

### 8. Offer Remediation

Ask the user: "Would you like me to suggest concrete remediation edits for the top N issues?" (Do NOT apply them automatically.)

**Multi-Repository Remediation**:
- For cross-repo issues, provide repository-specific remediation steps
- Include coordination recommendations (e.g., "Notify shared-contracts team of breaking change")
- Suggest sequencing adjustments for cross-repo task dependencies

## Operating Principles

### Context Efficiency

- **Minimal high-signal tokens**: Focus on actionable findings, not exhaustive documentation
- **Progressive disclosure**: Load artifacts incrementally; don't dump all content into analysis
- **Token-efficient output**: Limit findings table to 50 rows; summarize overflow
- **Deterministic results**: Rerunning without changes should produce consistent IDs and counts
- **Multi-Repo**: Load `project-context.md` files only for repositories referenced in plan/tasks

### Analysis Guidelines

- **NEVER modify files** (this is read-only analysis)
- **NEVER hallucinate missing sections** (if absent, report them accurately)
- **Prioritize constitution violations** (these are always CRITICAL)
- **Use examples over exhaustive rules** (cite specific instances, not generic patterns)
- **Report zero issues gracefully** (emit success report with coverage statistics)
- **Multi-Repo**: Flag cross-repository issues prominently with affected repository names
- **Multi-Repo**: Validate architectural alignment against `project-context.md` constraints

## Context

{ARGS}
