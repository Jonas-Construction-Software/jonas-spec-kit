---
description: Create or update the feature specification. Optionally import from Jira user story or provide a natural language feature description. Supports Jira dev-task-based branch naming with auto-discovery of development tasks from imported user stories.
handoffs: 
  - label: Build Technical Plan
    agent: speckit.plan
    prompt: Create a plan for the spec. I am building with...
  - label: Clarify Spec Requirements
    agent: speckit.clarify
    prompt: Clarify specification requirements
    send: true
scripts:
  sh: scripts/bash/create-new-feature.sh --description "{ARGS}" --json
  ps: scripts/powershell/create-new-feature.ps1 -Description "{ARGS}" -Json
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
- **`*-document` repository**: Holds ALL planning artifacts:
  - `.specs/{feature-name}/` - Feature specifications, plans, tasks, checklists
  - `.specify/memory/` - Constitution and project memory
  - `.specify/templates/` - Command and artifact templates
  - Feature branches in *-document repo track planning work
- **Implementation repositories**: Contain source code and `project-context.md`
  - Implementation branches are created later by `/speckit.implement` command
  - Branch names match the *-document feature branch name

**Single-Repository Workspace**:
- All artifacts and code live together in one repository
- `.specs/{feature-name}/` at repository root
- `.specify/` directory at repository root
- Single feature branch contains both planning and implementation changes

**Artifact Storage**: All specs, plans, tasks, and checklists are ALWAYS created in the `*-document` repository (multi-repo) or at repository root (single-repo), never in implementation repositories.

---

## Pre-processing: Optional Jira User Story Import (Step 0)

Before treating the user's message after `/speckit.specify` as the feature description, you **MUST** ask:

> **Do you want to import an existing Jira user story for this feature? (Yes/No)**

### If the user answers **Yes**

1. Ask the user for the Jira user story key:  
   **"Please provide the Jira user story number/key (e.g., PROJ-123)."**

2. **Retrieve Atlassian Cloud ID**:
   
   Call `mcp_com_atlassian_getAccessibleAtlassianResources()` to get the cloud ID.
   
   **Error handling**:
   - If the call fails or returns no resources:
     ```
     ❌ Error: Cannot connect to Atlassian services. 
     
     Possible causes:
     - Atlassian MCP server not installed or not running
     - No Atlassian account connected in VS Code
     - Network connectivity issues
     
     To resolve:
     1. Install the Atlassian MCP server extension in VS Code
     2. Authenticate with your Atlassian account
     3. Try again
     
     Would you like to continue without importing from Jira? (Yes/No)
     ```
   - If user says **Yes**: Skip to Step 0 "If the user answers **No**" section
   - If user says **No**: Exit with error message

3. **Fetch the Jira issue**:
   
   Use `mcp_com_atlassian_getJiraIssue()` with:
   - `cloudId`: from step 2
   - `issueIdOrKey`: provided by user
   - `fields`: `["summary", "description", "issuetype", "status", "subtasks", "issuelinks", "customfield_*"]`
   
   **Error handling**:
   - If issue not found (404):
     ```
     ❌ Error: Issue {ISSUE_KEY} not found.
     
     Please verify:
     - The issue key is correct (e.g., PROJ-123)
     - You have permission to view this issue
     - The issue exists in your Jira instance
     
     Would you like to:
     A) Try a different issue key
     B) Continue without importing from Jira
     ```
   - If permission denied (403):
     ```
     ❌ Error: Access denied to issue {ISSUE_KEY}.
     
     You don't have permission to view this issue. Please:
     - Request access from your Jira administrator
     - Verify you're authenticated with the correct account
     
     Would you like to:
     A) Try a different issue key
     B) Continue without importing from Jira
     ```
   - If network error or timeout:
     ```
     ❌ Error: Cannot connect to Jira.
     
     Network error: {ERROR_MESSAGE}
     
     Please check your internet connection and try again.
     
     Would you like to:
     A) Retry fetching the issue
     B) Continue without importing from Jira
     ```
   - If any other error:
     ```
     ❌ Error: Failed to fetch Jira issue.
     
     Error details: {ERROR_MESSAGE}
     
     Would you like to:
     A) Try a different issue key
     B) Continue without importing from Jira
     ```
   
   Handle user's choice accordingly (retry, try different key, or skip import).

4. **Present the retrieved content**:
   
   ```markdown
   ## Jira Story: {ISSUE_KEY} - {SUMMARY}
   
   **Type**: {ISSUETYPE}
   **Status**: {STATUS}
   
   ### Description
   {DESCRIPTION}
   
   ### Acceptance Criteria
   {ACCEPTANCE_CRITERIA or "Not specified"}
   
   ### Sub-tasks
   {LIST_OF_SUBTASKS or "None"}
   
   ---
   
   Would you like to:
   A) Use this content as-is for the feature specification
   B) Use this content and add additional requirements
   C) Reject this content and continue without importing
   
   **Your choice**:
   ```

5. **Handle the user's response**:
   
   - **Choice A**: Use Jira content as the feature description
   - **Choice B**: Ask user "Please provide your additional requirements:" and combine with Jira content
   - **Choice C**: Skip Jira import and proceed to "If the user answers **No**" section

6. **Set feature description variable**:
   
   Based on the choice, set `FEATURE_DESCRIPTION` to the appropriate content for use in subsequent steps.

7. **Store Jira context for branch naming**:
   
   Set the following variables for use in branch naming:
   - `JIRA_STORY_IMPORTED = true`
   - `JIRA_STORY_KEY` = the user story key (e.g., PROJ-123)
   - `JIRA_CLOUD_ID` = the cloud ID from step 2
   - `JIRA_SUBTASKS` = the subtasks field from the retrieved issue (if any)
   - `JIRA_LINKED_ISSUES` = the issuelinks field from the retrieved issue (if any)

### If the user answers **No**

1. Ask the user to provide the feature description:
   
   **"Please provide a detailed description of the feature you want to build:"**

2. Wait for user's response

3. Set `FEATURE_DESCRIPTION` to the user's provided description

4. **Set Jira context flag**:
   
   Set `JIRA_STORY_IMPORTED = false`

---

## User Input

```text
{ARGS}
```

> **Note**: The `{ARGS}` field is optional. After Step 0, the "feature description" is either:  
> (a) Jira story content (optionally augmented with additional requirements), or  
> (b) The user's natural-language description provided when prompted in the "No" path
> 
> If `{ARGS}` is provided with the initial command, it can be used as a default/fallback, but Step 0 takes precedence.

---

## Pre-Execution Checks

**Check for extension hooks (before specification)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_specify` key
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

The finalized feature description (from Step 0) is now available. You have either:
- Imported it from Jira (with optional additional requirements), or
- Received it directly from the user when they chose not to import from Jira

Do not ask the user to repeat the feature description - you already have it from Step 0.

Given that finalized feature description (from Step 0), do this:

1. **Determine branch naming strategy FIRST (before creating anything)**:

   a. **Retrieve Development Tasks from Jira (if applicable)**:
   
   **CRITICAL**: This step ONLY executes if `JIRA_STORY_IMPORTED = true` (user imported from Jira in Step 0).
   
   If `JIRA_STORY_IMPORTED = true`:
   
   1. **Check for development tasks in the imported story**:
      
      Examine both `JIRA_SUBTASKS` and `JIRA_LINKED_ISSUES` fields from Step 0. Development tasks can be represented as either subtasks or linked issues in Jira.
      
      a. **Process Subtasks**:
      
      Filter subtasks to identify those that appear to be development tasks:
      - Look for issue types: "Development Task", "Dev Task", "Task", "Sub-task", "Technical Task"
      - Look for keywords in summary: "dev", "development", "implement", "code", "technical"
      - Include all subtasks if unable to determine which are development-specific
      
      b. **Process Linked Issues**:
      
      Filter linked issues to identify development tasks:
      - Look for link types: "implements", "is implemented by", "relates to", "depends on", "rolls up into", "breaks down into"
      - Check the linked issue's type: "Development Task", "Dev Task", "Task", "Technical Task"
      - Exclude link types like "duplicates", "is duplicated by", "blocks", "is blocked by" (unless they are development tasks)
      
      c. **Combine Results**:
      
      Merge both lists (subtasks and linked issues) into a single list of development tasks, removing duplicates if any.
   
   2. **If development tasks are found**:
      
      Present them to the user with this format:
      
      ```markdown
      ## Available Development Tasks from {JIRA_STORY_KEY}
      
      I found the following development tasks associated with this user story:
      
      | Option | Task Key | Summary | Status | Source |
      |--------|----------|---------|--------|--------|
      | 1      | {TASK_KEY_1} | {SUMMARY_1} | {STATUS_1} | Subtask |
      | 2      | {TASK_KEY_2} | {SUMMARY_2} | {STATUS_2} | Linked Issue |
      | ...    | ...      | ...     | ...    | ...    |
      | M      | Manual entry | Enter a different Jira development task key | - | - |
      | N      | No dev task | Use auto-numbering instead (001-, 002-, etc.) | - | - |
      
      **Which option would you like to use for the branch prefix?** (Enter 1, 2, ..., M, or N):
      ```
      
      **CRITICAL - Table Formatting**: Ensure markdown tables are properly formatted:
      - Use consistent spacing with pipes aligned
      - Each cell should have spaces around content: `| Content |` not `|Content|`
      - Header separator must have at least 3 dashes: `|--------|`
      - Include "Source" column to indicate whether the task is a subtask or a linked issue
   
   3. **Handle user's selection**:
      
      - **If user selects a numbered option (1, 2, etc.)**:
        - Extract the task key from the selected option
        - Validate format: Must match pattern `[A-Z]+-\d+`
        - Store as `DEV_TASK_KEY` variable
        - **Set branch naming mode**: `USE_DEV_TASK = true`
        - **Skip step 1.b** and proceed directly to step 2
      
      - **If user selects "M" (Manual entry)**:
        - Proceed to step 1.b to ask for manual input
      
      - **If user selects "N" (No dev task)**:
        - **Set branch naming mode**: `USE_DEV_TASK = false`
        - **Skip step 1.b** and proceed directly to step 2
   
   4. **If no development tasks are found OR MCP server fails**:
      
      - Log a note: "No development tasks (subtasks or linked issues) found for {JIRA_STORY_KEY}, asking for manual input"
      - Proceed to step 1.b
   
   5. **Error handling**:
      
      If any error occurs while retrieving or processing subtasks:
      - Log the error details
      - Show warning to user:
        ```
        ⚠️ Warning: Could not retrieve development tasks from Jira.
        
        Error: {ERROR_MESSAGE}
        
        Continuing with manual development task input...
        ```
      - Proceed to step 1.b
   
   If `JIRA_STORY_IMPORTED = false`:
   
   - Skip this entire step and proceed directly to step 1.b

   b. **Ask for Jira Development Task Number (Manual Input)**:
   
   > **Do you have a Jira development task number to use as the branch prefix (e.g., FT-53, DEV-142)? (Yes/No)**
   
   **CRITICAL**: This question MUST be asked BEFORE running any scripts or creating any branches/directories.
   
   - **If Yes**:
     1. Ask: **"Please provide the Jira development task key (e.g., FT-53, DEV-142, PROJ-789):"**
     2. Validate format: Must match pattern `[A-Z]+-\d+` (e.g., FT-53, DEV-142, PROJ-789)
     3. If format invalid, show examples and ask again
     4. Store the validated dev task key as `DEV_TASK_KEY` variable
     5. **Set branch naming mode**: `USE_DEV_TASK = true`
   
   - **If No**:
     1. **Set branch naming mode**: `USE_DEV_TASK = false`
     2. Will use auto-numbering (001-, 002-, 003-, etc.)

2. **Generate a concise short name** (2-4 words) for the branch:
   
   - Analyze the `FEATURE_DESCRIPTION` (set in Step 0) and extract the most meaningful keywords
   - Create a 2-4 word short name that captures the essence of the feature
   - Use action-noun format when possible (e.g., "add-user-auth", "fix-payment-bug")
   - Preserve technical terms and acronyms (OAuth2, API, JWT, etc.)
   - Keep it concise but descriptive enough to understand the feature at a glance
   - Examples:
     - "I want to add user authentication" → "user-auth"
     - "Implement OAuth2 integration for the API" → "oauth2-api-integration"
     - "Create a dashboard for analytics" → "analytics-dashboard"
     - "Fix payment processing timeout bug" → "fix-payment-timeout"

3. **Determine the branch number and name**:

   **CRITICAL**: Branch/directory creation strategy depends on `USE_DEV_TASK` flag from step 1.

   a. **If `USE_DEV_TASK = true`** (user provided Jira dev task key):
      
      - Branch name will be: `{DEV_TASK_KEY}-{short-name}` (e.g., `FT-53-user-auth`)
      - Directory name will be: `{DEV_TASK_KEY}-{short-name}` (e.g., `specs/FT-53-user-auth`)
      - **Skip auto-number checking** - Jira dev task key replaces numeric prefix entirely
      - Run script with `--custom-prefix` flag:
        
        Bash:
        ```bash
        scripts/bash/create-new-feature.sh --description "{brief-summary}" --json --custom-prefix "{DEV_TASK_KEY}" --short-name "{short-name}"
        ```
        
        PowerShell:
        ```powershell
        scripts/powershell/create-new-feature.ps1 -Description "{brief-summary}" -Json -CustomPrefix "{DEV_TASK_KEY}" -ShortName "{short-name}"
        ```
      
      - The script will create: Branch `{DEV_TASK_KEY}-{short-name}` and directory `specs/{DEV_TASK_KEY}-{short-name}`
      - **No renaming needed** - everything created with correct names from the start
   
   b. **If `USE_DEV_TASK = false`** (user did NOT provide Jira dev task key):
      
      - Use standard auto-numbering workflow:
      
      1. First, fetch all remote branches to ensure we have the latest information:
         ```bash
         git fetch --all --prune
         ```
      
      2. Find the highest feature number across all sources for the short-name:
         - Remote branches: `git ls-remote --heads origin | grep -E 'refs/heads/[0-9]+-<short-name>$'`
         - Local branches: `git branch | grep -E '^[* ]*[0-9]+-<short-name>$'`
         - Specs directories: Check for directories matching `specs/[0-9]+-<short-name>`
      
      3. Determine the next available number:
         - Extract all numbers from all three sources
         - Find the highest number N
         - Use N+1 for the new branch number
      
      4. Run the script with the calculated number and short-name:
         
         Bash:
         ```bash
         scripts/bash/create-new-feature.sh --description "{brief-summary}" --json --number {N+1} --short-name "{short-name}"
         ```
         
         PowerShell:
         ```powershell
         scripts/powershell/create-new-feature.ps1 -Description "{brief-summary}" -Json -Number {N+1} -ShortName "{short-name}"
         ```
         
         **Generate a brief summary** from `FEATURE_DESCRIPTION`:
         - Create a concise summary (maximum 35 characters)
         - Capture the key essence of the feature in a few words
         - Examples:
           - "As a user, I want to authenticate using OAuth2..." → "Add OAuth2 authentication"
           - Long Jira story with multiple paragraphs → "User dashboard with analytics"
         
         **IMPORTANT**:
         - Check all three sources (remote branches, local branches, specs directories)
         - Only match branches/directories with the exact short-name pattern
         - If no existing branches/directories found with this short-name, start with number 1
         - You must only ever run this script once per feature
         - The JSON output contains BRANCH_NAME and SPEC_FILE paths
         - For single quotes in args like "I'm Groot", use escape syntax: `'I'\''m Groot'` (or use double quotes: `"I'm Groot"`)

4. **Parse script output and set environment variable**:

   a. Parse the JSON output from the script to extract:
      - `BRANCH_NAME` - The created branch name
      - `SPEC_FILE` - Path to the spec file
      - `FEATURE_NUM` - Feature number or dev task key
   
   b. Set the environment variable for the current session:
      
      Bash:
      ```bash
      export SPECIFY_FEATURE="{BRANCH_NAME}"
      ```
      
      PowerShell:
      ```powershell
      $env:SPECIFY_FEATURE = "{BRANCH_NAME}"
      ```
   
   c. Confirm to user:
      ```
      ✅ Feature environment configured:
         - Branch: {BRANCH_NAME}
         - Directory: specs/{BRANCH_NAME}
         - Spec file: {SPEC_FILE}
         - SPECIFY_FEATURE environment variable set
      ```

5. Load `templates/spec-template.md` to understand required sections.

6. Follow this execution flow:

    1. Parse the `FEATURE_DESCRIPTION` (set in Step 0)
       If empty or missing: ERROR "No feature description provided from Step 0"
    2. Extract key concepts from description
       Identify: actors, actions, data, constraints
    3. For unclear aspects:
       - Make informed guesses based on context and industry standards
       - Only mark with [NEEDS CLARIFICATION: specific question] if:
         - The choice significantly impacts feature scope or user experience
         - Multiple reasonable interpretations exist with different implications
         - No reasonable default exists
       - **LIMIT: Maximum 3 [NEEDS CLARIFICATION] markers total**
       - Prioritize clarifications by impact: scope > security/privacy > user experience > technical details
    4. Fill User Scenarios & Testing section
       If no clear user flow: ERROR "Cannot determine user scenarios"
    5. Generate Functional Requirements
       Each requirement must be testable
       Use reasonable defaults for unspecified details (document assumptions in Assumptions section)
    6. Define Success Criteria
       Create measurable, technology-agnostic outcomes
       Include both quantitative metrics (time, performance, volume) and qualitative measures (user satisfaction, task completion)
       Each criterion must be verifiable without implementation details
    7. Identify Key Entities (if data involved)
    8. Return: SUCCESS (spec ready for planning)

7. Write the specification to SPEC_FILE using the template structure, replacing placeholders with concrete details derived from the `FEATURE_DESCRIPTION` (set in Step 0) while preserving section order and headings.

8. **Specification Quality Validation**: After writing the initial spec, validate it against quality criteria:

   a. **Create Spec Quality Checklist**: Generate a checklist file at `FEATURE_DIR/checklists/requirements.md` using the checklist template structure with these validation items:

      ```markdown
      # Specification Quality Checklist: [FEATURE NAME]
      
      **Purpose**: Validate specification completeness and quality before proceeding to planning
      **Created**: [DATE]
      **Feature**: [Link to spec.md]
      
      ## Content Quality
      
      - [ ] No implementation details (languages, frameworks, APIs)
      - [ ] Focused on user value and business needs
      - [ ] Written for non-technical stakeholders
      - [ ] All mandatory sections completed
      
      ## Requirement Completeness
      
      - [ ] No [NEEDS CLARIFICATION] markers remain
      - [ ] Requirements are testable and unambiguous
      - [ ] Success criteria are measurable
      - [ ] Success criteria are technology-agnostic (no implementation details)
      - [ ] All acceptance scenarios are defined
      - [ ] Edge cases are identified
      - [ ] Scope is clearly bounded
      - [ ] Dependencies and assumptions identified
      
      ## Feature Readiness
      
      - [ ] All functional requirements have clear acceptance criteria
      - [ ] User scenarios cover primary flows
      - [ ] Feature meets measurable outcomes defined in Success Criteria
      - [ ] No implementation details leak into specification
      
      ## Notes
      
      - Items marked incomplete require spec updates before `/speckit.clarify` or `/speckit.plan`
      ```

   b. **Run Validation Check**: Review the spec against each checklist item:
      - For each item, determine if it passes or fails
      - Document specific issues found (quote relevant spec sections)

   c. **Handle Validation Results**:

      - **If all items pass**: Mark checklist complete and proceed to step 7

      - **If items fail (excluding [NEEDS CLARIFICATION])**:
        1. List the failing items and specific issues
        2. Update the spec to address each issue
        3. Re-run validation until all items pass (max 3 iterations)
        4. If still failing after 3 iterations, document remaining issues in checklist notes and warn user

      - **If [NEEDS CLARIFICATION] markers remain**:
        1. Extract all [NEEDS CLARIFICATION: ...] markers from the spec
        2. **LIMIT CHECK**: If more than 3 markers exist, keep only the 3 most critical (by scope/security/UX impact) and make informed guesses for the rest
        3. For each clarification needed (max 3), present options to user in this format:

           ```markdown
           ## Question [N]: [Topic]
           
           **Context**: [Quote relevant spec section]
           
           **What we need to know**: [Specific question from NEEDS CLARIFICATION marker]
           
           **Suggested Answers**:
           
           | Option | Answer | Implications |
           |--------|--------|--------------|
           | A      | [First suggested answer] | [What this means for the feature] |
           | B      | [Second suggested answer] | [What this means for the feature] |
           | C      | [Third suggested answer] | [What this means for the feature] |
           | Custom | Provide your own answer | [Explain how to provide custom input] |
           
           **Your choice**: _[Wait for user response]_
           ```

        4. **CRITICAL - Table Formatting**: Ensure markdown tables are properly formatted:
           - Use consistent spacing with pipes aligned
           - Each cell should have spaces around content: `| Content |` not `|Content|`
           - Header separator must have at least 3 dashes: `|--------|`
           - Test that the table renders correctly in markdown preview
        5. Number questions sequentially (Q1, Q2, Q3 - max 3 total)
        6. Present all questions together before waiting for responses
        7. Wait for user to respond with their choices for all questions (e.g., "Q1: A, Q2: Custom - [details], Q3: B")
        8. Update the spec by replacing each [NEEDS CLARIFICATION] marker with the user's selected or provided answer
        9. Re-run validation after all clarifications are resolved

   d. **Update Checklist**: After each validation iteration, update the checklist file with current pass/fail status

9. Report completion with branch name, spec file path, checklist results, and readiness for the next phase (`/speckit.clarify` or `/speckit.plan`).

8. **Check for extension hooks**: After reporting completion, check if `.specify/extensions.yml` exists in the project root.
   - If it exists, read it and look for entries under the `hooks.after_specify` key
   - If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
   - Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
   - For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
     - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
     - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
   - For each executable hook, output the following based on its `optional` flag:
     - **Optional hook** (`optional: true`):
       ```
       ## Extension Hooks

       **Optional Hook**: {extension}
       Command: `/{command}`
       Description: {description}

       Prompt: {prompt}
       To execute: `/{command}`
       ```
     - **Mandatory hook** (`optional: false`):
       ```
       ## Extension Hooks

       **Automatic Hook**: {extension}
       Executing: `/{command}`
       EXECUTE_COMMAND: {command}
       ```
   - If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently

**NOTE:** The script creates and checks out the new branch and initializes the spec file before writing.

## Quick Guidelines

- Focus on **WHAT** users need and **WHY**.
- Avoid HOW to implement (no tech stack, APIs, code structure).
- Written for business stakeholders, not developers.
- DO NOT create any checklists that are embedded in the spec. That will be a separate command.

### Section Requirements

- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation

When creating this spec from a user prompt:

1. **Make informed guesses**: Use context, industry standards, and common patterns to fill gaps
2. **Document assumptions**: Record reasonable defaults in the Assumptions section
3. **Limit clarifications**: Maximum 3 [NEEDS CLARIFICATION] markers - use only for critical decisions that:
   - Significantly impact feature scope or user experience
   - Have multiple reasonable interpretations with different implications
   - Lack any reasonable default
4. **Prioritize clarifications**: scope > security/privacy > user experience > technical details
5. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
6. **Common areas needing clarification** (only if no reasonable default exists):
   - Feature scope and boundaries (include/exclude specific use cases)
   - User types and permissions (if multiple conflicting interpretations possible)
   - Security/compliance requirements (when legally/financially significant)

**Examples of reasonable defaults** (don't ask about these):

- Data retention: Industry-standard practices for the domain
- Performance targets: Standard web/mobile app expectations unless specified
- Error handling: User-friendly messages with appropriate fallbacks
- Authentication method: Standard session-based or OAuth2 for web apps
- Integration patterns: Use project-appropriate patterns (REST/GraphQL for web services, function calls for libraries, CLI args for tools, etc.)

### Success Criteria Guidelines

Success criteria must be:

1. **Measurable**: Include specific metrics (time, percentage, count, rate)
2. **Technology-agnostic**: No mention of frameworks, languages, databases, or tools
3. **User-focused**: Describe outcomes from user/business perspective, not system internals
4. **Verifiable**: Can be tested/validated without knowing implementation details

**Good examples**:

- "Users can complete checkout in under 3 minutes"
- "System supports 10,000 concurrent users"
- "95% of searches return results in under 1 second"
- "Task completion rate improves by 40%"

**Bad examples** (implementation-focused):

- "API response time is under 200ms" (too technical, use "Users see results instantly")
- "Database can handle 1000 TPS" (implementation detail, use user-facing metric)
- "React components render efficiently" (framework-specific)
- "Redis cache hit rate above 80%" (technology-specific)
