---
description: "Analyse a user story or feature description for completeness gaps and cross-reference requirements against the existing codebase. Runs as a before_specify hook or standalone."
---

# GitNexus Gap Analysis

> This command is triggered as an optional `before_specify` hook when
> `/speckit.specify` is invoked. It can also be run standalone at any time:
> `/speckit.gitnexus.gap-analysis <feature description or Jira key>`

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
   - Gap analysis runs code-coverage checks against **implementation repositories** only
   - The feature description / user story context comes from conversation or Jira

3. **For single-repo workspaces**:
   - All artifacts and code are in the same repository
   - Code-coverage checks run against the current repository's GitNexus index

### Workspace Architecture Context

**Multi-Repository Workspace**:
- **`*-document` repository**: Holds specs, plans, tasks in `.specs/{feature-name}/`
- **Implementation repositories**: Contain source code, `project-context.md`, and GitNexus indexes
- Gap analysis discovers existing code across ALL indexed implementation repos
- Results are grouped by repository

**Single-Repository Workspace**:
- All artifacts and code are in one repo
- Gap analysis runs against the current repository's GitNexus index

---

## 1. Obtain the Feature Description

**Determine the source of the feature description based on context:**

### When triggered as a `before_specify` hook

The feature description is already in the conversation context from `/speckit.specify`
Step 0 (either imported from Jira or provided manually by the user). Use that
`FEATURE_DESCRIPTION` directly — do not ask the user to repeat it.

If `JIRA_STORY_IMPORTED = true`, also note the `JIRA_STORY_KEY` for the report header.

### When invoked standalone with `$ARGUMENTS`

- **If `$ARGUMENTS` matches a Jira key pattern** (`[A-Z]+-\d+`, e.g., `PROJ-123`):
  1. Retrieve the Atlassian Cloud ID via `mcp_com_atlassian_getAccessibleAtlassianResources()`
  2. Fetch the issue via `mcp_com_atlassian_getJiraIssue()` with fields:
     `["summary", "description", "issuetype", "status", "acceptance_criteria"]`
  3. If Jira MCP is unavailable or the fetch fails, tell the user:
     ```
     ⚠️ Could not fetch Jira issue {KEY}. Please paste the user story text instead:
     /speckit.gitnexus.gap-analysis <paste story here>
     ```
  4. Use the fetched summary + description + acceptance criteria as the feature description
  5. Set `STORY_SOURCE = "Jira {KEY}"`

- **If `$ARGUMENTS` is free text**:
  1. Use `$ARGUMENTS` as the feature description directly
  2. Set `STORY_SOURCE = "Manual entry"`

### When invoked standalone without `$ARGUMENTS`

Ask the user:
> **Please provide the feature description or Jira story key to analyse:**

Wait for response and apply the rules above.

---

## 2. Phase 1 — Requirement Completeness Check (always runs)

This phase requires no GitNexus index. It analyses the feature description text
against a standard set of dimensions that a well-formed user story should cover.

### Dimensions to evaluate

For each dimension, assign one of three statuses:
- **CLEAR** — the story explicitly addresses this with sufficient detail
- **NEEDS CLARIFICATION** — the story mentions this but is ambiguous or incomplete
- **MISSING** — the story does not address this at all

| Dimension | What to look for |
|-----------|-----------------|
| **User / Actor** | Who performs the action? Are roles/permissions defined? |
| **Goal / User Value** | Is the "why" clear? What problem does this solve? |
| **Acceptance Criteria** | Are there explicit, testable conditions for "done"? |
| **Scope Boundary** | Is it clear what's included AND excluded? |
| **Trigger / Entry Point** | How does the user initiate this? (button, event, schedule, etc.) |
| **Data / Entities** | Are the key data objects and their lifecycle defined? |
| **Error / Edge Cases** | What happens when things go wrong? |
| **External Systems** | Are integrations, APIs, or third-party dependencies specified? |
| **Security / Privacy** | Are auth, data protection, or compliance needs addressed (when relevant)? |

### Evaluation rules

- **CLEAR** requires explicit statements in the story — not implications
- **NEEDS CLARIFICATION**: the topic is mentioned but details are ambiguous or
  could mean multiple things (quote the ambiguous text in the Detail column)
- **MISSING**: the topic is not mentioned at all and cannot be inferred from context
- Not all dimensions apply to every story. Skip dimensions that are genuinely
  irrelevant (e.g., "External Systems" for a purely internal UI change). Do not
  flag skipped dimensions as MISSING.
- Be pragmatic: a one-paragraph story for a minor bug fix will have fewer
  applicable dimensions than a multi-page feature epic

### Phase 1 output

Store the results for the final report. Do not present them to the user yet —
wait until after Phase 2 to deliver a single consolidated report.

---

## 3. Phase 2 — Code Coverage Check (conditional on GitNexus index)

### Guard: Check GitNexus Availability

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
- `"status": "ready"` → Include this repo in Phase 2
- `"status": "no-index"` → Skip this repo. If ALL repos return `no-index`, skip
  Phase 2 entirely and note in the report: "Code coverage check skipped — no
  GitNexus index available."
- `"status": "stale"` → Include but note staleness in the report
- `"status": "skipped"` (reason: `"document-repo"`) → Skip silently

**If guard passes for at least one repo, proceed. Otherwise skip to Step 4.**

### Step A: Extract Search Terms

From the feature description, extract 3–6 concise search terms that represent
the functional areas the story touches. Focus on:
- Component/module names mentioned in the story
- Domain concepts (e.g., "export", "calendar report", "PDF generation")
- UI elements or user-facing features referenced
- Data entities or operations described

Example for "Calendar Impact Report export to PDF, Excel, CSV":
```
Search terms:
1. "calendar impact report"
2. "export PDF"
3. "export Excel CSV"
4. "report button toolbar"
```

### Step B: Discover Existing Code

**Enumerate target repositories:**

1. Use `gitnexus_list_repos()` to get all indexed repositories
2. **Multi-repo**: Filter out the `*-document` repo
3. **Single-repo**: Use the current repository

**For each target repository**, query GitNexus with each search term:
```
gitnexus_query({query: "<search_term>", repo: "<repo_name>", limit: 5, include_content: true})
```

> **Parallelization**: Issue all search term queries **in parallel** per repository.
> Agents supporting parallel tool calls should batch all `gitnexus_query` invocations
> into a single round-trip rather than waiting for each query to complete sequentially.

Deduplicate results across all queries and repos.

### Step C: Assess Coverage per Requirement Area

For each search term / requirement area, classify the code coverage using the
content already returned by Step B (`include_content: true`):

| Coverage Status | Meaning |
|----------------|---------|
| **IMPLEMENTED** | Matching symbols exist and are functional (not stubbed) |
| **PARTIALLY IMPLEMENTED** | Matching symbols exist but are stubbed, incomplete, or only cover part of the requirement |
| **NOT PRESENT** | No matching symbols found — this is greenfield work |

**Classify inline** from the query results. Look for indicators of stubs in the
returned content:
- Functions that throw `NotImplementedError` or similar
- Functions that return hardcoded/placeholder values
- Functions with TODO/FIXME comments in their description
- Functions with zero callees (leaf nodes that should call something)

> **Only** call `gitnexus_context()` as a fallback if the returned content was
> truncated or insufficient to determine stub status. In most cases the content
> from Step B is enough to classify — avoid extra round-trips.

### Step D: Risk Scan for High-Impact Symbols

**Cap**: Run impact checks on **at most 2 symbols** — pick the 2 with the highest
caller density or relevance score from Step B results. Skip the rest to keep
the analysis fast.

For each selected symbol that is IMPLEMENTED or PARTIALLY IMPLEMENTED:
```
gitnexus_impact({target: "<symbol_name>", repo: "<repo_name>", direction: "upstream", maxDepth: 1})
```

Only report symbols where d=1 caller count is ≥ 5 or risk is HIGH/CRITICAL.
These are areas where changes to implement the story carry elevated risk.

> If the guard script reported `status: stale`, skip the risk scan entirely and
> note in the report: *"Risk scan skipped — index is stale."*

---

## 4. Determine Verdict

Based on Phase 1 and Phase 2 results, assign one of three verdicts:

### PROCEED

**Conditions**: All applicable Phase 1 dimensions are CLEAR. No critical gaps.

The story is well-formed and sufficient for spec creation. Phase 2 results (if
available) are informational only.

### PROCEED WITH CLARIFICATIONS

**Conditions**: Some dimensions are NEEDS CLARIFICATION or a small number are
MISSING, but core elements (User/Actor, Goal, at least some Acceptance Criteria)
are present.

The story is sufficient to proceed but would produce a cleaner spec if gaps are
resolved first.

### INSUFFICIENT

**Conditions**: Multiple core dimensions are MISSING — typically 2+ of:
User/Actor, Goal/User Value, Acceptance Criteria, Scope Boundary. The story
lacks the foundational elements needed to write a meaningful spec.

---

## 5. Present Consolidated Report

Output a single structured report combining both phases:

```
═══ GITNEXUS GAP ANALYSIS ═══
Feature    : {title derived from feature description}
Story src  : {Jira KEY | Manual entry | Hook (from /speckit.specify)}
Index      : {date (current) | date (N commits stale) | NOT INDEXED}

── Requirement Completeness ──
| Dimension            | Status              | Detail                                |
|----------------------|---------------------|---------------------------------------|
| User / Actor         | {CLEAR|NEEDS..|MISS} | {brief evidence or gap description}  |
| Goal / User Value    | ...                 | ...                                   |
| Acceptance Criteria  | ...                 | ...                                   |
| Scope Boundary       | ...                 | ...                                   |
| Trigger / Entry Point| ...                 | ...                                   |
| Data / Entities      | ...                 | ...                                   |
| Error / Edge Cases   | ...                 | ...                                   |
| External Systems     | ...                 | ...                                   |
| Security / Privacy   | ...                 | ...                                   |

── Code Coverage (GitNexus) ──
| Requirement Area     | Status              | Repository       | Existing Symbol(s)            |
|----------------------|---------------------|------------------|-------------------------------|
| {search term}        | {IMPLEMENTED|PARTIAL|NOT PRESENT} | {repo} | {symbol1, symbol2 or "—"}  |

── Risk Flags ──
| Symbol               | Repository | Risk     | d=1 Callers | Note                          |
|----------------------|------------|----------|-------------|-------------------------------|
| {name}               | {repo}     | {level}  | {count}     | {brief context}               |

(Risk Flags section only shown if Phase 2 found high-risk symbols. Omit entirely otherwise.)
═══════════════════════════════════════════════
```

If Phase 2 was skipped (no index), replace the Code Coverage and Risk Flags
sections with:
```
── Code Coverage ──
Skipped — no GitNexus index available. Run `/speckit.gitnexus.setup` to enable.
```

---

## 6. Handle Verdict

### PROCEED

```
═══ VERDICT: PROCEED ═══
The story is well-formed and sufficient for specification.
No gaps require resolution.
═══════════════════════
```

No further interaction needed. The hook returns and `/speckit.specify` continues.

### PROCEED WITH CLARIFICATIONS

```
═══ VERDICT: PROCEED WITH CLARIFICATIONS ═══

The story is sufficient to proceed. {N} item(s) would strengthen the spec
if resolved now.

| #  | Gap                                       | Severity |
|----|-------------------------------------------|----------|
| C1 | {dimension}: {brief description of gap}   | {MEDIUM|LOW} |
| C2 | ...                                       | ...      |

**Choose how to handle these:**

A) **Resolve now** — answer the questions below, and the answers will be
   appended to your feature description before the spec is created
B) **Defer all to spec** — proceed immediately; the spec command will
   handle ambiguities through its own clarification process
C) **Pick and choose** — type the item numbers to resolve now (e.g., "C1, C3"),
   the rest will be deferred

**Your choice:**
═══════════════════════════════════════════════
```

#### If user picks A (resolve all) or C (pick and choose)

For each selected item, present a focused question using the same table format
as `/speckit.specify` step 8c for consistency:

```markdown
## C{N}: {Dimension / Topic}

**Context**: {Quote or paraphrase the relevant part of the story}

**What we need to know**: {Specific question derived from the gap}

**Suggested Answers**:

| Option | Answer                    | Implications                              |
|--------|---------------------------|-------------------------------------------|
| A      | {First suggested answer}  | {What this means for the feature}         |
| B      | {Second suggested answer} | {What this means for the feature}         |
| C      | {Third suggested answer}  | {What this means for the feature}         |
| Custom | Provide your own answer   | Type your answer in free text             |

**Your choice:**
```

**CRITICAL - Table Formatting**: Ensure markdown tables are properly formatted:
- Use consistent spacing with pipes aligned
- Each cell should have spaces around content: `| Content |` not `|Content|`
- Header separator must have at least 3 dashes: `|--------|`

Present all selected questions together, then wait for responses.

After all responses are collected, append a structured block to `FEATURE_DESCRIPTION`:

```markdown
## Gap Analysis Clarifications (from pre-specify analysis)

- **{Dimension}**: {User's answer or selected option text} (resolved C{N})
- **{Dimension}**: [Deferred to spec] (C{N})
```

Then output:
```
═══ CLARIFICATIONS APPLIED ═══
{N} item(s) resolved. {M} item(s) deferred to spec.
Enriched feature description will be used by /speckit.specify.
═══════════════════════════════
```

#### If user picks B (defer all)

Append a brief note to `FEATURE_DESCRIPTION`:

```markdown
## Gap Analysis Notes (from pre-specify analysis)

The following areas were flagged but deferred to the specification phase:
- {Dimension}: {brief gap description} (C{N})
```

Then proceed — the hook returns and `/speckit.specify` continues. The agent
will encounter these same gaps during spec generation (step 6.3) and handle
them through the standard `[NEEDS CLARIFICATION]` process.

### INSUFFICIENT

```
═══ VERDICT: INSUFFICIENT ═══

The story has critical gaps that would produce a low-quality spec.
Proceeding now risks significant rework.

| #  | Gap                                       | Why it's critical                           |
|----|-------------------------------------------|---------------------------------------------|
| I1 | {dimension}: {gap description}            | {Impact on spec quality}                    |
| I2 | ...                                       | ...                                         |

**Choose how to proceed:**

A) **Resolve now** — answer the critical questions below, then proceed
   to spec creation with clarified requirements
B) **Return to stakeholder** — stop here; a copy-pasteable summary will
   be provided to update the story before retrying
C) **Proceed anyway** — acknowledge the gaps and let the spec command
   make best-effort guesses (expect multiple [NEEDS CLARIFICATION] markers)

**Your choice:**
═══════════════════════════════════════════════
```

#### If user picks A (resolve now)

Present ALL insufficient items as questions (same format as PROCEED WITH
CLARIFICATIONS above). Every item must be answered — no deferral option for
critical gaps.

After all responses are collected, append to `FEATURE_DESCRIPTION`:

```markdown
## Gap Analysis Clarifications (from pre-specify analysis)

⚠️ Story was rated INSUFFICIENT. The following critical gaps were resolved
by the user during gap analysis:

- **{Dimension}**: {User's answer} (resolved I{N})
```

Then output:
```
═══ VERDICT UPDATED: RESOLVED → PROCEED ═══
All {N} critical gap(s) resolved. Proceeding to specification.
═══════════════════════════════════════════════
```

The hook returns and `/speckit.specify` continues with the enriched description.

#### If user picks B (return to stakeholder)

Output a copy-pasteable summary designed to send to the story author:

```markdown
## Gap Analysis Summary for {story title or Jira key}

**Analysed**: {date}
**Result**: Insufficient information to begin specification

The following items need clarification before development can begin:

1. **{Dimension}**: {Specific question that needs answering}
2. **{Dimension}**: {Specific question that needs answering}
...

Please update the story with these details and notify the development team
to retry `/speckit.specify`.
```

Then output the stop signal:
```
⛔ HOOK RESULT: STOP
Gap analysis determined the story is insufficient and the user chose to
return to the stakeholder. Update the story and retry /speckit.specify.
```

The hook returns. `/speckit.specify` must detect `⛔ HOOK RESULT: STOP` and
halt without proceeding to the Outline.

#### If user picks C (proceed anyway)

Append an acknowledgement block to `FEATURE_DESCRIPTION`:

```markdown
## Gap Analysis Acknowledgement (from pre-specify analysis)

⚠️ User chose to proceed despite INSUFFICIENT verdict.
Unresolved critical gaps (agent should use best-effort defaults):

- **{Dimension}**: {gap description} — assumed: {reasonable default} (I{N})
```

Then output:
```
═══ PROCEEDING WITH ACKNOWLEDGED GAPS ═══
{N} critical gap(s) unresolved. The spec command will use best-effort
defaults and flag remaining ambiguities with [NEEDS CLARIFICATION] markers.
═══════════════════════════════════════════════
```

The hook returns and `/speckit.specify` continues.

---

## Fallback

If GitNexus tools fail during Phase 2 (timeouts, MCP errors):
- Log a brief note: "GitNexus code coverage check failed: {error}"
- Complete the report with Phase 1 results only
- Note in the Code Coverage section: "Skipped — GitNexus tool error. Run
  `/speckit.gitnexus.setup` to verify configuration."
- Do NOT block the parent workflow
