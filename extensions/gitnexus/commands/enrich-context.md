---
description: "Gather GitNexus graph intelligence (architecture, clusters, execution flows) into conversation context for use by /speckit.context during analysis."
---

# Enrich Context with GitNexus Intelligence

> This command is triggered automatically as a `before_context` hook **per
> repository** when `/speckit.context` iterates the workspace. It can also be
> invoked standalone at any time: `/speckit.gitnexus.enrich-context`

## User Input

```text
$ARGUMENTS
```

---

## Guard: Check GitNexus Availability

Before proceeding, run the runtime guard for the current repository:

**macOS / Linux:**
```bash
bash .specify/extensions/gitnexus/scripts/bash/gitnexus-check.sh --json
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File .specify/extensions/gitnexus/scripts/powershell/gitnexus-check.ps1 -Json
```

**Interpret the result:**
- `"status": "ready"` → Proceed with all steps below
- `"status": "no-index"` → Skip all GitNexus steps silently. Let the parent `/speckit.context` command proceed with its standard file-scanning workflow. Do NOT error.
- `"status": "stale"` → Proceed but prepend a note to the output: "⚠️ GitNexus index is N commits behind HEAD. Results may be incomplete. Run `npx gitnexus analyze` to update."
- `"status": "skipped"` (reason: `"document-repo"`) → Skip all GitNexus steps silently. The current repository is a `*-document` planning repo with no source code to analyze. Do NOT error.

---

## Step 1: Identify Current Repository

The parent `/speckit.context` workflow invokes this hook once per repository.
Identify which repository is currently being analyzed from the conversation
context (the repo name is shown in the hook prompt).

Use the GitNexus MCP tool to confirm the repo is indexed:
```
gitnexus_list_repos()
```

From the results, match the current repository. If not found in the index,
log "GitNexus enrichment skipped: repo not indexed" and exit gracefully.
Use the `repo` parameter on all subsequent tool calls.

---

## Step 2: Retrieve Architectural Overview

Read the GitNexus context resource for the identified repository:
```
READ gitnexus://repo/{name}/context
```

This returns:
- Repository stats (files, symbols, languages)
- Index freshness
- High-level architecture summary

---

## Step 3: Retrieve Functional Clusters

Read the clusters resource:
```
READ gitnexus://repo/{name}/clusters
```

This returns auto-detected functional areas (communities) with:
- Cluster labels and descriptions
- Symbol counts and cohesion scores
- Keywords for each area

---

## Step 4: Retrieve Main Execution Flows

Query for the primary execution flows:
```
gitnexus_query({query: "main execution flows entry points", limit: 8})
```

This returns process-grouped results showing how code connects across the codebase.

---

## Step 5: Output Intelligence to Conversation Context

**Do NOT write to `project-context.md`.** The parent `/speckit.context` workflow owns file
creation. Instead, output all gathered intelligence as a structured block in the
conversation so the agent retains it when it resumes `context.md`.

Output the following exactly (replace placeholders with real data from Steps 2-4):

```
═══ GITNEXUS PRE-HOOK INTELLIGENCE ═══

Repository : {repo name}
Index Date : {date from context resource}
Staleness  : {staleness_note or "Current"}

── Functional Areas ──
| Area | Description | Key Symbols | Cohesion |
|------|-------------|-------------|----------|
| {cluster.label} | {cluster.description} | {top 3 symbols} | {cohesion} |
  … (one row per cluster)

── Key Execution Flows ──
| Flow | Entry Point | Steps | Areas Crossed |
|------|-------------|-------|---------------|
| {process.label} | {entry symbol} | {step count} | {communities} |
  … (one row per flow, up to 8)

── Codebase Stats ──
Languages       : {languages}
Indexed Symbols : {count}
Execution Flows : {count}
Functional Areas: {count}

═══ END GITNEXUS PRE-HOOK INTELLIGENCE ═══
```

The `/speckit.context` workflow will:
1. Detect this block in conversation context
2. Use functional areas and execution flows to enhance architectural analysis (sections 2.1–2.3)
3. Incorporate codebase stats into source discovery
4. Write a dedicated **Code Intelligence** appendix in Phase 5

---

## Fallback

If any GitNexus tool call fails (timeout, error, etc.):
1. Log a brief note: "GitNexus enrichment skipped: {reason}"
2. Do NOT block the parent workflow
3. The standard `/speckit.context` file-scanning workflow proceeds normally
