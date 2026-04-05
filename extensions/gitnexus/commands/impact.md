---
description: "Analyze the blast radius of a symbol or area before making changes. Runs in spec-aware mode when triggered as a before_plan hook. Supports multi-repo workspaces."
---

# GitNexus Impact Analysis

## User Input

```text
$ARGUMENTS
```

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
   - Impact analysis runs against **implementation repositories** (where the code lives),
     not the `*-document` repo
   - The spec is located in the `*-document` repo

3. **For single-repo workspaces**:
   - All artifacts and code are in the same repository
   - Impact analysis runs against the current repository

### Workspace Architecture Context

**Multi-Repository Workspace**:
- **`*-document` repository**: Holds specs, plans, tasks in `.specs/{feature-name}/`
- **Implementation repositories**: Contain source code, `project-context.md`, and GitNexus indexes
- Impact analysis discovers symbols across ALL indexed implementation repos
- Results are grouped by repository to show cross-repo blast radius

**Single-Repository Workspace**:
- All artifacts and code are in one repo
- Impact analysis runs against the current repository's GitNexus index

---

## Mode Selection

**Determine the operating mode based on `$ARGUMENTS`:**

- **`$ARGUMENTS` is not empty** → **Targeted mode**: analyze the specific symbol or area the user provided. Skip to the Guard section, then proceed to Step 1.
- **`$ARGUMENTS` is empty** → **Spec-aware mode**: automatically extract areas of change from the current specification and discover matching code symbols. Continue to the Spec-Aware Discovery section below.

---

## Spec-Aware Discovery (when `$ARGUMENTS` is empty)

This mode is designed for the `before_plan` hook or when a user runs
`/speckit.gitnexus.impact` without arguments after completing their spec.

### Step A: Locate the Specification

**Multi-repo workspace:**
1. Switch to the `*-document` repository
2. Detect the active feature branch to determine `{feature-name}`
3. Look for the spec at `.specs/{feature-name}/spec.md`
4. If not found, scan `.specs/*/spec.md` and use the most recently modified
5. If still not found, ask the user: "No spec.md found in the document repo. What area do you want to analyze? Example: `/speckit.gitnexus.impact user authentication`"

**Single-repo workspace:**
1. Detect the active feature branch to determine `{feature-name}`
2. Look for the spec at `.specs/{feature-name}/spec.md`
3. If not found, scan `.specs/*/spec.md` and use the most recently modified
4. If still not found, ask the user: "No spec.md found. What area do you want to analyze? Example: `/speckit.gitnexus.impact user authentication`"

### Step B: Extract Areas of Change

Read the spec and extract:
- **Feature/component names** mentioned in headings and body text
- **Domain concepts** (e.g., "authentication", "checkout", "notification")
- **Specific files or modules** referenced
- **User stories or requirements** that imply code changes
- **Repository references** (if the spec mentions specific repos or services by name)

Condense into a list of 3-8 **search terms** (concise natural-language phrases).

Example extraction from a spec about "Add discount codes to checkout":
```
Search terms:
1. "discount code validation"
2. "checkout flow payment"
3. "order pricing calculation"
4. "coupon storage"
```

### Step C: Discover Code Symbols (across all repos)

**Enumerate target repositories:**

1. Use `gitnexus_list_repos()` to get all indexed repositories
2. **Multi-repo**: Filter out the `*-document` repo (no code to analyze).
   If the spec references specific implementation repos by name, note them as
   **primary targets**. All other indexed repos are **secondary targets**.
3. **Single-repo**: The single repo is the only target.

**For each target repository**, query GitNexus with each search term:
```
gitnexus_query({query: "<search_term>", repo: "<repo_name>", limit: 3, include_content: false})
```

Deduplicate results across all queries and repos. Retain the top **10 most relevant
symbols per repository** (ranked by query relevance score). If no symbols are found
for a search term in any repo, note it as an unmapped area.

**If the spec does NOT clearly indicate which repos are affected**, run discovery
against **all indexed implementation repos**. The results themselves will reveal
which repos are actually impacted (repos with zero matching symbols are
automatically excluded from the report).

### Step D: Proceed to Impact Analysis

Use the discovered symbols as the targets, grouped by repository. Continue to the
Guard section (run per-repo), then Step 2 (skip Step 1 since symbols are already
identified).

---

## Guard: Check GitNexus Availability

**Run the guard once per target repository.** Skip repos that return `no-index`
or `document-repo`.

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
paths simplify to:

**macOS / Linux:**
```bash
bash .specify/extensions/gitnexus/scripts/bash/gitnexus-check.sh --json
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File .specify/extensions/gitnexus/scripts/powershell/gitnexus-check.ps1 -Json
```

**Interpret the result per repo:**
- `"status": "ready"` → Include this repo in analysis
- `"status": "no-index"` → Skip this repo. If ALL repos return `no-index`, tell the user: "No GitNexus indexes found. Run `/speckit.gitnexus.setup` first."
- `"status": "stale"` → Include but note: "Index is N commits behind HEAD — results may be incomplete."
- `"status": "skipped"` (reason: `"document-repo"`) → Skip silently (expected).

---

## Step 1: Find Target Symbols

> **Skip this step in Spec-Aware mode** — symbols were already discovered in Step C.

Use the GitNexus query tool to locate symbols matching the user's input:
```
gitnexus_query({query: "$ARGUMENTS", limit: 5, include_content: false})
```

In multi-repo workspaces, query across all indexed implementation repos unless the
user explicitly scoped to one (e.g., `/speckit.gitnexus.impact api-service:validateUser`).

From the results, identify the most relevant symbol(s), noting which repository
each belongs to.

---

## Step 2: Run Impact Analysis

For each identified symbol, run upstream impact analysis:
```
gitnexus_impact({target: "<symbol_name>", repo: "<repo_name>", direction: "upstream", maxDepth: 3})
```

**Multi-repo**: Cross-repository call edges (if GitNexus detected shared contracts
or inter-service calls) will appear in the impact results. Flag these as
**cross-repo dependencies** in the report.

---

## Step 3: Present Blast Radius Report

**Generate one report section per repository that has results.** In single-repo
mode, this is a single report. In multi-repo mode, repeat for each affected repo.

```markdown
# Impact Analysis: {target} [{repo_name}]

**Repository:** {repo_name}
**Risk Level:** {LOW | MEDIUM | HIGH | CRITICAL}

## Summary
- Direct callers (d=1): {count}
- Indirect dependents (d=2): {count}
- Transitive (d=3): {count}
- Affected execution flows: {count}
- Affected functional areas: {count}

## d=1 — WILL BREAK (must update)

| Symbol | File | Type |
|--------|------|------|
| {name} | {filePath} | {caller/importer} |

## d=2 — LIKELY AFFECTED (should test)

| Symbol | File | Type |
|--------|------|------|
| {name} | {filePath} | {type} |

## d=3 — MAY NEED TESTING (transitive)

| Symbol | File | Type |
|--------|------|------|
| {name} | {filePath} | {type} |

## Affected Execution Flows

| Flow | Impact Point | Risk |
|------|-------------|------|
| {process label} | Step {N} | {direct/indirect} |

## Affected Functional Areas

| Area | Impact | Symbols Affected |
|------|--------|-----------------|
| {cluster label} | {direct/indirect} | {count} |
```

If the risk level is **HIGH** or **CRITICAL**, add a prominent warning:
> ⚠️ **HIGH/CRITICAL RISK**: This change has a large blast radius. Review all d=1 dependents carefully before proceeding.

---

## Step 4: Consolidated Summary

### Spec-Aware mode

When running in spec-aware mode, append a consolidated summary after all
per-symbol, per-repo reports:

```markdown
# Spec Impact Summary

**Specification**: {spec file path}
**Workspace type**: {single-repo | multi-repo}
**Search terms extracted**: {count}
**Code symbols discovered**: {count} across {repo_count} repositories
**Unmapped areas**: {list of search terms with no matching symbols, or "None"}

## Repositories Affected

| Repository | Symbols Matched | Highest Risk | d=1 Total |
|------------|----------------|--------------|-----------|
| {repo_name} | {count} | {risk level} | {count} |

## Per-Area Risk Assessment

| Spec Area | Matched Symbols | Repos | Highest Risk | d=1 Total |
|-----------|----------------|-------|--------------|-----------|
| {search term} | {symbol1, symbol2} | {repo names} | {risk level} | {count} |

**Aggregate risk**: {LOW | MEDIUM | HIGH | CRITICAL}
```

If aggregate risk is HIGH or CRITICAL:
> ⚠️ **This spec touches high-risk areas.** Consider breaking the work into
> smaller, lower-risk increments during planning.

If there are unmapped areas (search terms with no matching symbols):
> ℹ️ **Unmapped areas** may indicate new code that doesn't exist yet (greenfield)
> or domain terms that don't match current symbol names. Review these manually
> during planning.

**Multi-repo cross-cutting note** (if multiple repos affected):
> 📦 **Cross-repository impact detected.** This feature affects {N} repositories.
> Coordinate contract changes carefully during planning. Consider sequencing:
> shared contracts first, then consuming services.

### Targeted mode (multi-repo)

When running in targeted mode in a multi-repo workspace, append:

```markdown
## Cross-Repository Summary

| Repository | Symbols Affected | Risk Level |
|------------|-----------------|------------|
| {repo_name} | {count} | {risk} |
```

---

## Fallback

If GitNexus tools are unavailable, tell the user:
> Impact analysis requires a GitNexus index. Run `/speckit.gitnexus.setup` to get started.
