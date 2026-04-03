---
description: "Pre-implementation impact check: verify tasks.md symbols against the GitNexus call graph to surface blast-radius risks before coding. Supports multi-repo workspaces."
---

# GitNexus Pre-Flight Check

This command runs automatically before implementation (via `before_implement` hook).
It parses `tasks.md` for symbol references — using `[repo-name]` labels to map each
symbol to its target repository — and checks blast radius per repo.

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
   - `tasks.md` is in the `*-document` repo; impact analysis runs against
     implementation repos based on `[repo-name]` labels in each task

3. **For single-repo workspaces**:
   - All artifacts and code are in the same repository
   - All `[repo-name]` labels reference the current repo

### Workspace Architecture Context

**Multi-Repository Workspace**:
- **`*-document` repository**: Holds `tasks.md` in `.specs/{feature-name}/`
- **Implementation repositories**: Contain source code and GitNexus indexes
- Each task's `[repo-name]` label identifies which repo it targets
- Pre-flight groups symbols by `[repo-name]` and runs impact per repo

**Single-Repository Workspace**:
- `tasks.md` at `.specs/{feature-name}/`
- All `[repo-name]` labels are identical (current repo name)
- Impact analysis runs against the single repo's index

---

## Step 1: Locate and Parse tasks.md

### 1a. Locate tasks.md

**Multi-repo workspace:**
1. Switch to the `*-document` repository
2. Detect the active feature branch to determine `{feature-name}`
3. Read `.specs/{feature-name}/tasks.md`
4. If not found, scan `.specs/*/tasks.md` and use the most recently modified
5. If still not found, log "Pre-flight skipped: no tasks.md found" and exit gracefully

**Single-repo workspace:**
1. Detect the active feature branch to determine `{feature-name}`
2. Read `.specs/{feature-name}/tasks.md`
3. If not found, scan `.specs/*/tasks.md` and use the most recently modified
4. If still not found, log "Pre-flight skipped: no tasks.md found" and exit gracefully

### 1b. Extract Symbol References with Repo Labels

Parse each task line following the format:
```
- [ ] [TaskID] [P?] [Story?] [repo-name] Description with file path
```

For each task, extract:
- **`[repo-name]`**: The target repository label (REQUIRED on every task)
- **Symbol references** from the description:
  - Function/method names mentioned (e.g., `validateUser`, `processPayment`)
  - Class names referenced (e.g., `UserService`, `OrderModel`)
  - File paths mentioned (e.g., `src/services/user_service.py`)
  - Module or component references

**Group symbols by `[repo-name]`:**

```
api-service:
  - validateUser (from T012)
  - UserService (from T014)
  - src/services/user_service.py (from T014)

shared-contracts:
  - TaskDto (from T015)
  - src/models/task.ts (from T015)
```

Build a mapping of `repo-name → [candidate symbols]`.

---

## Step 2: Guard Check (per repository)

**Run the guard once per distinct `[repo-name]` found in tasks.md.** Run from
each implementation repo's root using the **strict** threshold (5 commits by default).

**macOS / Linux:**
```bash
bash .specify/extensions/gitnexus/scripts/bash/gitnexus-check.sh --strict --json
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File .specify/extensions/gitnexus/scripts/powershell/gitnexus-check.ps1 -Strict -Json
```

**Interpret the result per repo:**
- `"status": "ready"` → Include this repo in analysis
- `"status": "no-index"` → Skip this repo's symbols. Log: "Pre-flight skipped for {repo-name} (no index)". If ALL repos return `no-index`, log "GitNexus pre-flight unavailable (no indexes)" and let implementation proceed.
- `"status": "stale"` → Include but warn: "⚠️ Index for {repo-name} is N commits behind — pre-flight results may miss recent changes. Consider running `npx gitnexus analyze` in {repo-name} first."
- `"status": "skipped"` (reason: `"document-repo"`) → Skip silently (expected — the `*-document` repo has no code to analyze).

---

## Step 3: Impact Analysis per Symbol (repo-scoped)

For each `[repo-name]` that passed the guard, run impact analysis on its symbols:

```
gitnexus_impact({target: "<symbol>", repo: "<repo_name>", direction: "upstream", maxDepth: 2})
```

Collect per symbol:
- d=1 (WILL BREAK) dependents — noting which repo they belong to
- Risk level
- Affected execution flows

**Multi-repo**: If a d=1 dependent exists in a *different* repo than the symbol
being modified (cross-repo dependency), flag it as a **cross-repo breakage risk**.

---

## Step 4: Cross-Reference Against Tasks

Compare the d=1 dependents against the full task list:
- **Covered**: A d=1 dependent IS mentioned in tasks.md (will be updated as part of the plan).
  Match by symbol name, file path, or module reference within the same `[repo-name]`.
- **Uncovered**: A d=1 dependent is NOT mentioned in tasks.md (risk of breakage)

**Multi-repo cross-reference**: When checking coverage, match dependents against
tasks that target the same `[repo-name]`. A dependent in `api-service` is only
covered if a task with `[api-service]` mentions it.

---

## Step 5: Pre-Flight Report

**Generate one section per affected repository, then a consolidated summary.**

### Per-Repository Report

```markdown
# Pre-Flight Impact Report — {repo_name}

## Symbols Under Modification

| Symbol | Task | Risk | d=1 Count | Uncovered d=1 |
|--------|------|------|-----------|---------------|
| {name} | {taskID} | {level} | {count} | {uncovered count} |

## ⚠️ Uncovered Dependents (WILL BREAK)

These d=1 dependents are NOT covered by tasks targeting [{repo_name}]:

| Dependent | File | Repo | Depends On | Via |
|-----------|------|------|-----------|-----|
| {name} | {file} | {repo_name} | {target symbol} | {CALLS/IMPORTS/EXTENDS} |

## Recommendations

{For each uncovered dependent:}
- **{dependent}** in `{file}` [{repo_name}]: Add a task to update this symbol, or verify it's unaffected.

## Affected Execution Flows

| Flow | Symbols Involved | Risk |
|------|-----------------|------|
| {process} | {symbols from tasks} | {risk} |
```

### Consolidated Summary (multi-repo)

```markdown
# Pre-Flight Summary

**Workspace type**: {single-repo | multi-repo}
**Repositories analyzed**: {count}
**Total symbols checked**: {count}
**Total uncovered d=1 dependents**: {count}

## Per-Repository Status

| Repository | Symbols | Risk | Uncovered d=1 | Status |
|------------|---------|------|---------------|--------|
| {repo_name} | {count} | {highest risk} | {count} | {PASS/WARN/BLOCK} |

## Cross-Repository Risks

| Modified Symbol | In Repo | Breaks | In Repo | Covered? |
|----------------|---------|--------|---------|----------|
| {symbol} | {source repo} | {dependent} | {target repo} | {Yes/No} |
```

### Blocking behavior

- **CRITICAL risk with uncovered d=1 dependents**:

  Print a prominent block warning and **STOP**:
  > 🛑 **CRITICAL**: {N} direct dependents will break and are not covered by tasks.md.

  **Do NOT proceed to implementation.** Ask the user:
  > "Pre-flight found {N} uncovered d=1 dependents at CRITICAL risk. Choose how to proceed:
  > 1. **Fix tasks first** — update tasks.md to cover the gaps, then re-run pre-flight
  > 2. **Proceed anyway** — accept the risk and continue to implementation
  > 3. **Abort** — stop and investigate further"

  Wait for the user's explicit choice before continuing.

- **HIGH risk with uncovered d=1 dependents**:

  Print a warning and **pause for acknowledgement**:
  > ⚠️ **HIGH RISK**: {N} uncovered dependents detected. Review the recommendations below before proceeding.

  After printing the per-repo recommendations, ask:
  > "Acknowledge HIGH risk findings and continue to implementation? (yes / fix first / abort)"

  Wait for the user's response before continuing.

- **MEDIUM / LOW**: Informational only — proceed automatically.

**Multi-repo escalation**: If uncovered dependents span multiple repos, escalate
the risk level by one tier (e.g., HIGH → CRITICAL) because cross-repo breakage is
harder to detect during implementation. Apply the escalated tier's blocking behavior.

---

## Remediation Workflow

When the user chooses **"Fix tasks first"** (CRITICAL) or **"fix first"** (HIGH),
guide them through the Spec Kit remediation workflow:

### Step 1: Triage — False Positive Check

For each uncovered d=1 dependent, determine if it is a genuine risk:
- **False positive**: The dependent calls/imports the symbol but the planned change
  does not alter the symbol's signature, return type, or observable behavior.
  → Mark as "verified safe" and exclude from the gap count.
- **Genuine risk**: The planned change DOES affect the interface the dependent relies on.
  → Continue to Step 2.

If all uncovered dependents are false positives, report:
> ✅ All uncovered dependents verified as unaffected. Proceeding to implementation.

### Step 2: Assess Gap Size

Count the genuine uncovered dependents remaining after triage:

- **Small gap (1–3 uncovered dependents)**:  
  Manually add tasks to `tasks.md` following the required format:
  ```
  - [ ] [T{next_id}] [P] [{Story}] [{repo-name}] Update {dependent} in {file} to accommodate {symbol} changes
  ```
  After adding, skip to Step 4.

- **Large gap (4+ uncovered dependents)**:  
  The task list has a structural gap — manual patching is error-prone.
  Recommend re-generating:
  > "Found {N} uncovered dependents — this suggests a significant scope gap.
  > Recommended: re-run `/speckit.tasks` to regenerate the task list with the
  > expanded scope, then `/speckit.analyze` to validate consistency."

  After the user re-runs tasks + analyze, continue to Step 4.

### Step 3: Cross-Repo Gaps (multi-repo only)

If uncovered dependents are in a **different repository** than the modified symbol:
- Verify the dependent's repository is listed in `tasks.md` `[repo-name]` labels
- If not, the entire repository may be missing from the implementation scope
- Recommend: "Repository `{repo-name}` is affected but has no tasks. Add cross-repo
  tasks or re-run `/speckit.tasks` with the expanded scope."

### Step 4: Re-Run Pre-Flight

After tasks.md has been updated (manually or via `/speckit.tasks`):
> "Tasks updated. Re-running pre-flight to verify coverage..."

Re-execute this pre-flight check from Step 1. If all d=1 dependents are now
covered (or verified safe), report:
> ✅ Pre-flight passed. All d=1 dependents are covered. Proceeding to implementation.

If gaps remain, repeat the remediation workflow.

---

## Fallback

If GitNexus is unavailable:
1. Log: "GitNexus pre-flight check skipped (index unavailable)"
2. Do NOT block — let implementation proceed normally
3. The standard `/speckit.implement` workflow continues without this enrichment
