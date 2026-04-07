---
description: "Ask questions about your codebase using GitNexus graph intelligence. Supports dependency analysis, execution flow tracing, architecture exploration, refactoring safety checks, and more. Supports multi-repo workspaces."
---

# GitNexus Ask

A general-purpose code intelligence Q&A command. Ask any question about your codebase and the agent will route it to the appropriate GitNexus tools, synthesize the results, and answer in natural language.

## User Input

```text
$ARGUMENTS
```

If `$ARGUMENTS` is empty, prompt the user:
> **What would you like to know about your codebase?**
>
> Examples:
> - "What breaks if I change UserService.createUser?"
> - "Walk me through the request lifecycle for creating an order."
> - "Where is the real business logic for billing?"
> - "What parts of the system are most central?"
> - "Can I safely delete this file?"

---

## Guard: Check GitNexus Availability

Before answering, verify that at least one repository has a GitNexus index.

Let `$DOC_ROOT` = the root of the `*-document` repo (single-repo: the project root).

**macOS / Linux:**
```bash
bash "$DOC_ROOT/.specify/extensions/gitnexus/scripts/bash/gitnexus-check.sh" --json
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File "$DOC_ROOT\.specify\extensions\gitnexus\scripts\powershell\gitnexus-check.ps1" -Json
```

**Interpret the result:**
- `"status": "ready"` → Proceed
- `"status": "no-index"` → Tell the user: "No GitNexus indexes found. Run `/speckit.gitnexus.setup` first."
- `"status": "stale"` → Proceed, but note: "⚠️ Index is N commits behind HEAD — answers may be incomplete. Run `npx gitnexus analyze` to update."
- `"status": "skipped"` (reason: `"document-repo"`) → Check other repos. If no implementation repos are indexed, direct user to setup.

---

## Step 1: Classify the Question

Read the user's question and classify it into one of the following **strategies**. A question may match multiple strategies — pick the **primary** one and note any secondary strategies to supplement the answer.

| Strategy | Trigger Signals | Primary Tools |
|----------|----------------|---------------|
| **impact** | "what breaks", "what depends on", "who calls", "blast radius", "if I change" | `gitnexus_impact` |
| **flow** | "walk me through", "what happens when", "request lifecycle", "code paths", "execution flow" | `gitnexus_query` → `READ process/{name}` |
| **locate** | "where is", "which file", "who owns", "where does this live", "is this duplicated" | `gitnexus_query` → `gitnexus_context` |
| **safety** | "can I delete", "is this used", "safe to remove", "anyone still using", "dead code" | `gitnexus_context` + `gitnexus_impact` |
| **architecture** | "how do services talk", "consumers vs providers", "project structure", "main components" | `READ clusters` + `gitnexus_query` |
| **consistency** | "implemented differently", "multiple patterns", "violate contract", "design drift", "multiple auth flows" | Multi-repo `gitnexus_query` + `gitnexus_cypher` |
| **planning** | "what needs to change", "how should I implement", "what tests to update", "add a field" | `gitnexus_query` + `gitnexus_impact` + `gitnexus_context` |
| **migration** | "move this module", "replace dependency", "version bumps", "shared library" | Multi-repo `gitnexus_impact` + `gitnexus_context` |
| **meta** | "most central", "highest blast radius", "overly coupled", "hotspots", "what don't I know" | `gitnexus_cypher` + `READ clusters` |

If the question does not clearly match any strategy, default to **locate** (find relevant code and explain it).

If the question is specifically about pre-change blast radius for a planned feature, suggest:
> For full spec-aware impact analysis tied to your SDD workflow, use `/speckit.gitnexus.impact` instead.

---

## Step 2: Discover Target Repositories

### 2a. Enumerate Indexed Repos

```
gitnexus_list_repos()
```

### 2b. Determine Scope

- If the user's question names a specific repository (e.g., "in the API service"), scope queries to that repo only.
- If the user's question names a specific symbol (e.g., `UserService.createUser`), find which repo(s) contain it.
- If no repo is specified, query **all indexed implementation repos**. Skip any `*-document` repos.

### 2c. Multi-Repo Workspace Handling

In multi-repo workspaces, run the guard check per target repo:

**macOS / Linux:**
```bash
bash "$DOC_ROOT/.specify/extensions/gitnexus/scripts/bash/gitnexus-check.sh" --json "<implementation-repo-path>"
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File "$DOC_ROOT\.specify\extensions\gitnexus\scripts\powershell\gitnexus-check.ps1" -Json -RepoPath "<implementation-repo-path>"
```

Skip repos with `"status": "no-index"` or `"status": "skipped"`. Include stale repos with a warning.

---

## Step 3: Execute Strategy

### Strategy: Impact

> "What breaks if I change X?", "What depends on this method?", "Which repos call into this?"

1. **Find the target symbol:**
   ```
   gitnexus_query({query: "<symbol or concept from question>", repo: "<repo_name>", limit: 5, include_content: false})
   ```
   If the user provided an exact symbol name, use `gitnexus_context` directly to confirm it exists.

2. **Run upstream impact analysis:**
   ```
   gitnexus_impact({target: "<symbol_name>", repo: "<repo_name>", direction: "upstream", maxDepth: 3})
   ```

3. **Check affected execution flows:**
   ```
   READ gitnexus://repo/{name}/processes
   ```
   Cross-reference the impacted symbols against process membership.

4. **Present** a structured answer with:
   - d=1 dependents (WILL BREAK) — always list these explicitly
   - d=2 dependents (LIKELY AFFECTED) — summarize count and key symbols
   - d=3 dependents (MAY NEED TESTING) — mention count only
   - Affected execution flows
   - Risk level: LOW / MEDIUM / HIGH / CRITICAL

**Multi-repo**: If d=1 dependents exist in other repos, call them out as **cross-repo dependencies** with the repo name.

---

### Strategy: Flow

> "Walk me through the request lifecycle for creating an order.", "What happens after a webhook is received?"

1. **Discover execution flows related to the question:**
   ```
   gitnexus_query({query: "<concept from question>", repo: "<repo_name>", limit: 5, include_content: false})
   ```

2. **For each relevant process, read the step-by-step trace:**
   ```
   READ gitnexus://repo/{name}/process/{processName}
   ```
   Read up to **3 most relevant** processes (to keep the answer focused).

3. **For key symbols in the flow, get context on what they do:**
   ```
   gitnexus_context({name: "<symbol>", repo: "<repo_name>"})
   ```
   Limit to 2-3 key symbols — the ones that are decision points, external calls, or where the user's question focuses.

4. **Present** a narrative walkthrough:
   - Number each step in the flow
   - Name the symbol, its file, and what it does at each step
   - Highlight branching points, external calls, and error handling paths
   - If multiple flows relate, show how they diverge (e.g., "happy path vs error path")

---

### Strategy: Locate

> "Where is the real business logic for billing?", "Which file controls retries?", "Is this duplicated?"

1. **Search for the concept:**
   ```
   gitnexus_query({query: "<concept from question>", repo: "<repo_name>", limit: 8, include_content: false})
   ```
   In multi-repo workspaces, query across all repos.

2. **For the top matches, get context:**
   ```
   gitnexus_context({name: "<symbol>", repo: "<repo_name>"})
   ```
   Focus on symbols with the most incoming calls (likely the "real" implementation).

3. **Check cluster membership for context:**
   ```
   READ gitnexus://repo/{name}/clusters
   ```
   Identify which functional area the symbols belong to.

4. **Present** a clear answer:
   - The primary location(s) with file paths
   - Which functional area / cluster each belongs to
   - If duplicates found: list all locations and note similarities/differences
   - Incoming call count as a proxy for "this is the main one"

---

### Strategy: Safety

> "Can I safely delete this file?", "Is this abstraction actually used?", "Are there multiple implementations?"

1. **Get full context on the target:**
   ```
   gitnexus_context({name: "<symbol or file>", repo: "<repo_name>"})
   ```
   Check incoming calls, incoming imports, and process participation.

2. **Run upstream impact to confirm:**
   ```
   gitnexus_impact({target: "<symbol>", repo: "<repo_name>", direction: "upstream", maxDepth: 2})
   ```

3. **For "is this used?" — check for zero callers:**
   If `gitnexus_context` shows no incoming calls and `gitnexus_impact` shows zero d=1 dependents, the symbol is likely unused. Verify with:
   ```
   gitnexus_cypher({query: "MATCH (caller)-[:CodeRelation {type: 'CALLS'}]->(f {name: '<symbol>'}) RETURN count(caller) AS callerCount", repo: "<repo_name>"})
   ```

4. **For "multiple implementations?" — search for the pattern:**
   ```
   gitnexus_cypher({query: "MATCH (c)-[:CodeRelation {type: 'IMPLEMENTS'}]->(i {name: '<interface>'}) RETURN c.name, c.filePath", repo: "<repo_name>"})
   ```
   Or use `gitnexus_query` across repos to find similar symbols.

5. **Present** a safety verdict:
   - **SAFE to remove** — zero callers, zero imports, not in any execution flow
   - **CAUTION** — has callers but they are test-only or deprecated
   - **UNSAFE** — active callers exist; list them

---

### Strategy: Architecture

> "How do these services talk to each other?", "What are the main components?", "Consumers vs providers?"

1. **Get functional areas:**
   ```
   READ gitnexus://repo/{name}/clusters
   ```
   Repeat for each indexed repo in multi-repo workspaces.

2. **Get execution flows for inter-area communication:**
   ```
   READ gitnexus://repo/{name}/processes
   ```

3. **For cross-cluster communication, run a Cypher query:**
   ```
   gitnexus_cypher({query: "MATCH (a)-[:CodeRelation {type: 'CALLS'}]->(b) WHERE a.community <> b.community RETURN a.community AS source, b.community AS target, count(*) AS calls ORDER BY calls DESC LIMIT 15", repo: "<repo_name>"})
   ```

4. **For "consumers vs providers" questions:**
   ```
   gitnexus_cypher({query: "MATCH (caller)-[:CodeRelation {type: 'CALLS'}]->(callee) WHERE callee.filePath CONTAINS '<library-or-service-path>' RETURN caller.community AS consumer, count(*) AS callCount ORDER BY callCount DESC", repo: "<repo_name>"})
   ```

5. **Present** a structured topology:
   - List functional areas with brief descriptions
   - Show inter-area dependencies (which area calls which)
   - For multi-repo: show which repos are consumers vs providers
   - Highlight tightly coupled areas (high cross-area call count)

---

### Strategy: Consistency

> "Are we implementing the same concept differently?", "Do we have multiple auth flows?", "Which repos follow the new pattern?"

1. **Search for the concept across all repos:**
   ```
   gitnexus_query({query: "<concept>", repo: "<repo_name>", limit: 10, include_content: true})
   ```
   Repeat for each indexed repo.

2. **For interface compliance checks:**
   ```
   gitnexus_cypher({query: "MATCH (c)-[:CodeRelation {type: 'IMPLEMENTS'}]->(i {name: '<InterfaceName>'}) RETURN c.name, c.filePath", repo: "<repo_name>"})
   ```

3. **For "multiple patterns" — compare implementations:**
   For each matching symbol across repos, get context:
   ```
   gitnexus_context({name: "<symbol>", repo: "<repo_name>"})
   ```
   Compare the callees (outgoing calls) to detect different implementation patterns.

4. **Present** a comparison:
   - Group implementations by repo
   - Note which pattern each follows (based on callees and structure)
   - Flag inconsistencies: "Repo A validates via middleware, Repo B validates inline"
   - If an interface/contract exists, note which implementations conform vs diverge

---

### Strategy: Planning

> "I want to add a field to the user model — what needs to change?", "How should I implement feature X?"

1. **Discover symbols related to the change area:**
   ```
   gitnexus_query({query: "<concept or entity from question>", repo: "<repo_name>", limit: 8, include_content: false})
   ```

2. **For the primary symbol(s), get full context:**
   ```
   gitnexus_context({name: "<symbol>", repo: "<repo_name>"})
   ```

3. **Run impact to map the full change surface:**
   ```
   gitnexus_impact({target: "<symbol>", repo: "<repo_name>", direction: "upstream", maxDepth: 2})
   ```

4. **Check affected execution flows:**
   ```
   READ gitnexus://repo/{name}/processes
   ```
   Identify which flows touch the symbols that need updating.

5. **Present** a change plan outline:
   - **Must change** (d=1): List symbols that definitely need updating, with files
   - **Should test** (d=2): List symbols that are likely affected
   - **Affected flows**: Which execution flows will be impacted
   - **Suggested sequence**: Interfaces → implementations → callers → tests
   - **Risk level**: Based on blast radius

> **Note**: For formal spec-driven planning with full SDD lifecycle integration, use `/speckit.gitnexus.impact` (before plan) and `/speckit.plan` instead.

---

### Strategy: Migration

> "What would it take to move this module to a shared library?", "What breaks if we replace this dependency?"

1. **Map the module's full interface surface:**
   ```
   gitnexus_context({name: "<module or symbol>", repo: "<repo_name>"})
   ```
   Identify all incoming references (consumers) and outgoing references (dependencies).

2. **Run upstream impact across all repos:**
   ```
   gitnexus_impact({target: "<symbol>", repo: "<repo_name>", direction: "upstream", maxDepth: 2})
   ```
   In multi-repo workspaces, this reveals which other repos depend on the module.

3. **For dependency replacement — find all usage sites:**
   ```
   gitnexus_cypher({query: "MATCH (caller)-[:CodeRelation]->(dep) WHERE dep.filePath CONTAINS '<dependency-path>' RETURN caller.name, caller.filePath, type(caller) ORDER BY caller.filePath", repo: "<repo_name>"})
   ```
   Repeat across all repos.

4. **For "version bumps" — check consumers across repos:**
   Query all repos for imports/calls into the target module.

5. **Present** a migration checklist:
   - **Consumers** (repos/symbols that currently depend on this): full list with counts
   - **Internal dependencies** (what the module itself depends on — comes along or needs replacing)
   - **Breaking changes**: Which consumers' code must change
   - **Repos needing updates**: In multi-repo workspaces, list each repo and what changes are required
   - **Suggested migration order**: Shared contracts first, then service-by-service

---

### Strategy: Meta

> "What parts of the system are most central?", "Where are the hotspots?", "What has the highest blast radius?"

1. **Identify high fan-in symbols (most called):**
   ```
   gitnexus_cypher({query: "MATCH (caller)-[:CodeRelation {type: 'CALLS'}]->(f) RETURN f.name, f.filePath, f.community, count(caller) AS fanIn ORDER BY fanIn DESC LIMIT 10", repo: "<repo_name>"})
   ```

2. **Identify high fan-out symbols (most dependencies):**
   ```
   gitnexus_cypher({query: "MATCH (f)-[:CodeRelation {type: 'CALLS'}]->(callee) RETURN f.name, f.filePath, f.community, count(callee) AS fanOut ORDER BY fanOut DESC LIMIT 10", repo: "<repo_name>"})
   ```

3. **Identify cross-cluster coupling (architectural hotspots):**
   ```
   gitnexus_cypher({query: "MATCH (a)-[:CodeRelation {type: 'CALLS'}]->(b) WHERE a.community <> b.community RETURN a.community AS source, b.community AS target, count(*) AS crossCalls ORDER BY crossCalls DESC LIMIT 10", repo: "<repo_name>"})
   ```

4. **Get cluster overview for context:**
   ```
   READ gitnexus://repo/{name}/clusters
   ```

5. **Present** an architectural health report:
   - **Central symbols** (highest fan-in): These have the largest blast radius — changes here are riskiest
   - **Complex symbols** (highest fan-out): These have the most dependencies — hardest to test in isolation
   - **Coupling hotspots**: Cluster pairs with the most cross-boundary calls — candidates for refactoring or explicit interface introduction
   - **Cohesion scores**: From clusters — low-cohesion areas may be doing too many things
   - In multi-repo workspaces, run per repo and then present a cross-repo summary

---

## Step 4: Present the Answer

Regardless of strategy, follow these presentation guidelines:

### Structure

1. **One-sentence direct answer** — Answer the question immediately. Don't bury the answer under methodology.
2. **Evidence** — Show the specific symbols, files, flows, and relationships that support the answer. Use tables for lists of symbols.
3. **Context** — Which functional areas / clusters are involved. Which repos (in multi-repo).
4. **Actionable next steps** (when applicable) — What the user should do with this information.

### Formatting Rules

- Use tables for lists of symbols, files, or dependencies (3+ items).
- Use numbered lists for execution flow walkthroughs.
- Use bold for repo names in multi-repo answers.
- Include file paths for all referenced symbols.
- When referencing risk levels, use the standard scale:

| Risk | Criteria |
|------|----------|
| LOW | <5 symbols affected, few execution flows |
| MEDIUM | 5–15 symbols affected, 2–5 execution flows |
| HIGH | >15 symbols affected or many execution flows |
| CRITICAL | Critical path (auth, payments, data integrity) |

### Multi-Repo Presentation

When the answer spans multiple repositories:
- Group findings by repo
- Lead with a cross-repo summary table
- Highlight cross-repo dependencies explicitly
- Note which repo owns the canonical implementation (if applicable)

### Caveats

Always include relevant caveats:
- If the index is stale, note that answers may be incomplete
- If a query found zero results for part of the question, note the gap
- If Cypher queries returned no rows (e.g., no implementations found), say so explicitly rather than omitting

---

## Fallback

If GitNexus tools are unavailable or no repos are indexed:
> Code intelligence requires a GitNexus index. Run `/speckit.gitnexus.setup` to get started.

If the question is too vague to classify into a strategy:
> I wasn't able to determine what you're asking about. Try being more specific — for example:
> - Name a symbol, file, or module: "What calls `processPayment`?"
> - Describe a concept: "How does authentication work?"
> - Ask about a change: "What breaks if I modify the User model?"
