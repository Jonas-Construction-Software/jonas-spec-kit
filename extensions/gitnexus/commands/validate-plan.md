---
description: "Post-plan validation: cross-check plan.md proposed changes against the GitNexus call graph to surface unaccounted risks, missing dependencies, and architecture misalignment. Supports multi-repo workspaces."
---

# GitNexus Plan Validation

This command runs automatically after planning (via `after_plan` hook).
It reads the generated plan.md, extracts the symbols/files/modules the plan
proposes to modify, and runs impact analysis to verify the plan properly
accounts for blast-radius risks discovered in the call graph.

**Feedback loop**: The `before_plan` hook (impact) feeds risk data INTO planning.
This `after_plan` hook validates the plan properly ADDRESSED those risks.

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
   - `plan.md` is in the `*-document` repo; impact validation runs against
     implementation repos

3. **For single-repo workspaces**:
   - All artifacts and code are in the same repository

### Workspace Architecture Context

**Multi-Repository Workspace**:
- **`*-document` repository**: Holds `plan.md` in `.specs/{feature-name}/`
- **Implementation repositories**: Contain source code and GitNexus indexes
- Validation cross-references plan content against implementation repo call graphs

**Single-Repository Workspace**:
- `plan.md` at `.specs/{feature-name}/`
- Validation runs against the single repo's index

---

## Guard: Check GitNexus Availability

For each implementation repository (or the single repo in single-repo mode):

1. Run the guard script:

   **Bash:**
   ```bash
   bash .specify/extensions/gitnexus/scripts/bash/gitnexus-check.sh "<repo-path>"
   ```

   **PowerShell:**
   ```powershell
   & .specify/extensions/gitnexus/scripts/powershell/gitnexus-check.ps1 -RepoPath "<repo-path>"
   ```

2. Handle exit codes:
   - **0 (ready)**: Proceed with validation for this repo
   - **1 (no index)**: Log `"⚠️ {repo-name}: No GitNexus index — skipping validation"` and skip this repo
   - **2 (stale)**: Log `"⚠️ {repo-name}: Index is stale — results may be incomplete"` and proceed with warning
   - **3 (document repo)**: Skip silently (expected for `*-document`)

If ALL repos return exit code 1 (no index anywhere), output:
```
ℹ️ Plan validation skipped: no GitNexus indexes found.
Run /speckit.gitnexus.setup to index your repositories.
```
Exit gracefully — let the parent `plan.md` flow continue normally.

---

## Step 1: Locate and Parse plan.md

### 1a. Locate plan.md

**Multi-repo workspace:**
1. Switch to the `*-document` repository
2. Detect the active feature branch to determine `{feature-name}`
3. Read `.specs/{feature-name}/plan.md`
4. If not found, scan `.specs/*/plan.md` and use the most recently modified
5. If still not found, log `"Validation skipped: no plan.md found"` and exit gracefully

**Single-repo workspace:**
1. Detect the active feature branch to determine `{feature-name}`
2. Read `.specs/{feature-name}/plan.md`
3. If not found, scan `.specs/*/plan.md` and use the most recently modified
4. If still not found, log `"Validation skipped: no plan.md found"` and exit gracefully

### 1b. Extract Proposed Changes from plan.md

Parse the plan to identify all **symbols, files, and modules the plan proposes to create, modify, or interact with**:

- **Files referenced**: Any file paths mentioned in the plan (e.g., `src/auth/login.ts`, `controllers/payment.py`)
- **Modules/components**: Named modules, classes, services, or layers described in the plan
- **Repository assignments**: If the plan mentions `[repo-name]` labels or assigns work to specific repos, extract those mappings
- **Phase boundaries**: Which symbols are touched in which phase (for sequencing validation)

Group extracted symbols by repository:
- If plan uses `[repo-name]` labels, group accordingly
- If no explicit repo labels in single-repo mode, assign all to the current repo
- If no explicit repo labels in multi-repo mode, use `gitnexus_query` to discover which repo each symbol lives in

Store as:
```
plan_symbols = {
  "repo-name-1": ["symbolA", "symbolB", "path/to/file.ts"],
  "repo-name-2": ["symbolC", "symbolD"]
}
```

---

## Step 2: Run Impact Analysis on Plan Symbols

For each repository in `plan_symbols`:

1. **Skip** if the guard marked this repo as no-index (exit code 1)

2. For each symbol in the repo's list, run:
   ```
   gitnexus_impact({target: "<symbol>", direction: "upstream", repo: "<repo_name>"})
   ```

3. Collect results per symbol:
   - Risk level (LOW / MEDIUM / HIGH / CRITICAL)
   - d=1 direct callers count and list
   - d=2 indirect dependents count
   - Affected execution flows
   - Affected functional areas (clusters)

---

## Step 3: Cross-Reference Plan Against Impact Data

For each symbol with impact results, check whether the plan **accounts for** its blast radius:

### 3a. Unaccounted d=1 Dependents

For each symbol where `d=1 > 0`:
- Check if the plan mentions, references, or addresses **each d=1 dependent**
- A dependent is "accounted for" if the plan:
  - Lists it as a file to update
  - Mentions it in a phase or task description
  - Explicitly notes it as out-of-scope with justification
- Dependents not mentioned anywhere in the plan are **unaccounted**

### 3b. Missing Cross-Repo Dependencies

For multi-repo workspaces:
- Check if any d=1 dependents live in a **different repository** than the symbol being changed
- If so, check if the plan's "Cross-Repository Impact Summary" section mentions that repo
- Flag as "missing cross-repo dependency" if not mentioned

### 3c. Cluster Boundary Crossings

For each symbol, check the affected functional areas (clusters):
- If the plan proposes changes that span **3 or more clusters**, flag as "cross-cutting concern"
- Check if the plan acknowledges the cross-cutting nature of the change

---

## Step 4: Generate Validation Report

### Per-Repository Results

For each repo with findings, generate:

```markdown
## Plan Validation: {repo_name}

**Symbols analyzed**: {count}
**Highest risk**: {LOW | MEDIUM | HIGH | CRITICAL}

### Unaccounted Dependents

| Plan Symbol | d=1 Dependent | File | Status |
|-------------|---------------|------|--------|
| {symbolA}   | {caller1}     | {file} | ❌ NOT IN PLAN |
| {symbolA}   | {caller2}     | {file} | ✅ Covered in Phase {N} |

### Cross-Repo Dependencies {multi-repo only}

| Symbol | Dependent | Dependent Repo | Status |
|--------|-----------|---------------|--------|
| {symbolA} | {caller} | {other-repo} | ❌ NOT IN PLAN |

### Cluster Boundary Crossings

| Symbol | Clusters Affected | Acknowledged in Plan? |
|--------|-------------------|----------------------|
| {symbolA} | {cluster1, cluster2, cluster3} | ❌ No |
```

If no findings for a repo, output:
```markdown
## Plan Validation: {repo_name}

✅ **CLEAN** — All plan-proposed changes have accounted blast-radius coverage.
```

### Consolidated Report

```markdown
# Plan Validation Summary

**Workspace type**: {single-repo | multi-repo}
**Plan file**: {plan.md path}
**Repos validated**: {count} of {total}

| Repository | Symbols | Highest Risk | Unaccounted d=1 | Cross-Repo Gaps | Cluster Crossings |
|------------|---------|--------------|-----------------|-----------------|-------------------|
| {repo}     | {count} | {risk}       | {count}         | {count}         | {count}           |

**Overall status**: {CLEAN | REVIEW | WARN}
```

Status definitions:
- **CLEAN**: No unaccounted d=1 dependents, no cross-repo gaps, no unacknowledged cluster crossings
- **REVIEW**: Some unaccounted items found but no HIGH/CRITICAL risk symbols affected
- **WARN**: Unaccounted d=1 dependents on HIGH/CRITICAL risk symbols

---

## Step 5: Risk-Based Guidance

### WARN Status

If overall status is **WARN**:

```
⚠️ **PLAN GAPS DETECTED** — The plan proposes changes to HIGH/CRITICAL risk
symbols without accounting for all direct dependents.

**Recommended actions before proceeding to /speckit.tasks:**

1. Review the unaccounted d=1 dependents listed above
2. For each, decide:
   - **Add to plan**: Include the dependent in the appropriate phase
   - **Mark out-of-scope**: Add explicit justification to plan.md
   - **Defer**: Create a follow-up note for a separate feature

Would you like to update the plan now, or proceed to /speckit.tasks as-is?
```

Wait for user response:
- **Update**: Point the user to the specific plan.md sections that need attention
- **Proceed**: Log acknowledgement and continue

### REVIEW Status

If overall status is **REVIEW**:

```
ℹ️ **Plan has minor coverage gaps** — Some d=1 dependents on LOW/MEDIUM risk
symbols are not explicitly mentioned in the plan.

This is informational. The plan may still be complete if these dependents
don't require changes. Review the report above and proceed when ready.
```

### CLEAN Status

```
✅ **Plan validation passed** — All proposed changes have accounted blast-radius coverage.
```
