---
description: "Post-implementation verification: compare staged/unstaged changes against expected task scope to detect scope creep and missed changes. Supports multi-repo workspaces."
---

# GitNexus Change Verification

This command runs automatically after implementation (via `after_implement` hook).
It compares what was actually changed against what tasks.md planned — using
`[repo-name]` labels to match changes to their expected tasks per repository.

---

## 0. Repository Location & Workspace Detection

**Before executing any steps below:**

1. **Detect workspace type**:
   - Check for multiple `.git` directories in parent/sibling folders
   - If found → multi-repository workspace
   - If not found → single-repository workspace

2. **For multi-repo workspaces**:
   - Identify the `*-document` repository (holds planning artifacts: `.specs/`, `.specify/`)
   - Identify all **implementation repositories** (sibling repos that are NOT `*-document`)
   - `tasks.md` is in the `*-document` repo; change detection runs against
     implementation repos based on `[repo-name]` labels in each task

3. **For single-repo workspaces**:
   - All artifacts and code are in the same repository
   - All `[repo-name]` labels reference the current repo

### Workspace Architecture Context

**Multi-Repository Workspace**:
- **`*-document` repository**: Holds `tasks.md` in `.specs/{feature-name}/`
- **Implementation repositories**: Contain source code, uncommitted changes, and GitNexus indexes
- Each task's `[repo-name]` label identifies which repo it targets
- Verification groups expected symbols by `[repo-name]` and detects changes per repo

**Single-Repository Workspace**:
- `tasks.md` at `.specs/{feature-name}/`
- All `[repo-name]` labels are identical (current repo name)
- Change detection runs against the single repo's index

---

## Step 1: Locate and Parse tasks.md

### 1a. Locate tasks.md

**Multi-repo workspace:**
1. Switch to the `*-document` repository
2. Detect the active feature branch to determine `{feature-name}`
3. Read `.specs/{feature-name}/tasks.md`
4. If not found, scan `.specs/*/tasks.md` and use the most recently modified
5. If still not found, log "Verification skipped: no tasks.md found" and exit gracefully

**Single-repo workspace:**
1. Detect the active feature branch to determine `{feature-name}`
2. Read `.specs/{feature-name}/tasks.md`
3. If not found, scan `.specs/*/tasks.md` and use the most recently modified
4. If still not found, log "Verification skipped: no tasks.md found" and exit gracefully

### 1b. Extract Expected Scope with Repo Labels

Parse each task line following the format:
```
- [ ] [TaskID] [P?] [Story?] [repo-name] Description with file path
```

For each task (both completed `[x]` and uncompleted `[ ]`), extract:
- **`[repo-name]`**: The target repository label (REQUIRED on every task)
- **Symbol references** from the description:
  - Function/method names mentioned (e.g., `validateUser`, `processPayment`)
  - Class names referenced (e.g., `UserService`, `OrderModel`)
  - File paths mentioned (e.g., `src/services/user_service.py`)
  - Module or component references
- **Completion status**: Whether the task is checked `[x]` or unchecked `[ ]`

**Group expected symbols by `[repo-name]`:**

```
api-service:
  - validateUser (from T012, completed)
  - UserService (from T014, completed)
  - src/services/user_service.py (from T014, completed)

shared-contracts:
  - TaskDto (from T015, completed)
  - src/models/task.ts (from T015, incomplete)
```

Build a mapping of `repo-name → [expected symbols with completion status]`.

---

## Step 2: Guard Check (per repository)

**Run the guard once per distinct `[repo-name]` found in tasks.md.**

The guard scripts live in the `*-document` repo (or the single repo) under
`.specify/extensions/gitnexus/scripts/`. In a multi-repo workspace,
implementation repos do **not** have a `.specify/` directory, so always invoke
the script from the document repo's path and pass the target repo via the
`-RepoPath` / positional argument.

Let `$DOC_ROOT` = the root of the `*-document` repo (single-repo: the project root).

**macOS / Linux:**
```bash
bash "$DOC_ROOT/.specify/extensions/gitnexus/scripts/bash/gitnexus-check.sh" --json "<implementation-repo-path>"
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File "$DOC_ROOT\.specify\extensions\gitnexus\scripts\powershell\gitnexus-check.ps1" -Json -RepoPath "<implementation-repo-path>"
```

For a **single-repo workspace** where `$DOC_ROOT` is the current repo, the
paths simplify to the original relative form:

**macOS / Linux:**
```bash
bash .specify/extensions/gitnexus/scripts/bash/gitnexus-check.sh --json
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File .specify/extensions/gitnexus/scripts/powershell/gitnexus-check.ps1 -Json
```

**Interpret the result per repo:**
- `"status": "ready"` → Include this repo in verification
- `"status": "no-index"` → Skip this repo's verification. Log: "Verification skipped for {repo-name} (no index)". If ALL repos return `no-index`, log "GitNexus verification unavailable (no indexes)" and exit gracefully.
- `"status": "stale"` → Include but note: "⚠️ Index for {repo-name} is N commits behind — verification results may be incomplete."
- `"status": "skipped"` (reason: `"document-repo"`) → Skip silently (expected — the `*-document` repo has no code to verify).

---

## Step 3: Detect Changed Symbols (per repository)

For each `[repo-name]` that passed the guard, detect changes:

```
gitnexus_detect_changes({scope: "all", repo: "<repo_name>"})
```

Collect per repo:
- Changed symbols (added, modified, deleted)
- Affected execution flows
- Risk summary

---

## Step 4: Scope Comparison (repo-scoped)

For each repository, cross-reference detected changes against the tasks targeting
that `[repo-name]`:

### Scope Creep Detection
Symbols that were changed in `{repo-name}` but are NOT mentioned in any task
with `[{repo-name}]` label may indicate unplanned scope expansion.

**Multi-repo**: If a changed symbol in `api-service` is only mentioned in a task
targeting `shared-contracts`, that's a cross-repo scope mismatch — flag it separately.

### Phantom Completion Detection
Symbols that ARE mentioned in completed `[x]` tasks targeting `{repo-name}` but
show NO changes may indicate incomplete implementation.

Symbols in uncompleted `[ ]` tasks are expected to be unchanged — do not flag these.

### Flow Impact Assessment
Execution flows affected by changes in this repo — are they expected based on the
tasks targeting this `[repo-name]`?

---

## Step 5: Verification Report

**Generate one section per affected repository, then a consolidated summary.**

### Per-Repository Report

```markdown
# Change Verification Report — {repo_name}

## Summary
- **Changed symbols**: {count}
- **Expected by tasks**: {count matching tasks with [{repo_name}]}
- **Scope creep candidates**: {count not in tasks}
- **Potentially incomplete**: {count in completed tasks but unchanged}

## ✅ Expected Changes (in tasks.md)

| Symbol | File | Change Type | Task |
|--------|------|-------------|------|
| {name} | {file} | {modified/added/deleted} | {taskID} |

## ⚠️ Scope Creep Candidates (not in tasks.md)

These symbols were changed in [{repo_name}] but not mentioned in the task plan:

| Symbol | File | Change Type | Likely Reason |
|--------|------|-------------|---------------|
| {name} | {file} | {type} | {from affected flow / refactor side-effect / unknown} |

## ❓ Potentially Incomplete (in completed tasks but unchanged)

These symbols are mentioned in completed tasks targeting [{repo_name}] but show no changes:

| Symbol | Task | Task Status |
|--------|------|-------------|
| {name} | {taskID}: {description} | [x] completed |

## Affected Execution Flows

| Flow | Status | Changed Symbols in Flow |
|------|--------|------------------------|
| {process} | {expected/unexpected} | {symbols} |
```

### Consolidated Summary (multi-repo)

```markdown
# Change Verification Summary

**Workspace type**: {single-repo | multi-repo}
**Repositories verified**: {count}
**Total changed symbols**: {count}
**Total scope creep candidates**: {count}
**Total potentially incomplete**: {count}

## Per-Repository Status

| Repository | Changed | Expected | Scope Creep | Incomplete | Status |
|------------|---------|----------|-------------|------------|--------|
| {repo_name} | {count} | {count} | {count} | {count} | {CLEAN/REVIEW/WARN} |

## Cross-Repository Observations

| Observation | Details |
|-------------|---------|
| {type} | {description} |
```

**Status definitions:**
- **CLEAN**: All changes match tasks, no scope creep, no incomplete items
- **REVIEW**: Scope creep candidates detected (may be legitimate refactoring side-effects)
- **WARN**: Potentially incomplete items found in completed tasks

### Reporting behavior

**This report is informational only** — it does not block any workflow. The
developer should review:
- **Scope creep candidates**: May be legitimate (dependency updates, refactoring
  side-effects) or may indicate unplanned work that needs task coverage
- **Potentially incomplete items**: May indicate missed implementation or symbols
  that were handled differently than originally planned

---

## Fallback

If GitNexus tools are unavailable, the guard script does not exist, or any
GitNexus tool call fails (timeout, error, etc.):
1. Log a brief note: "Change verification skipped: GitNexus not available. Review changes manually before committing."
2. Do NOT block the post-implementation workflow — this hook is mandatory but
   informational. The parent `/speckit.implement` command must continue normally.
3. Do NOT emit a `⛔ HOOK RESULT: STOP` signal.
