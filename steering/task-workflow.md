# Coder Task Creation and Monitoring Workflow

This steering file teaches you how to create and monitor Coder Tasks. Load this when the developer asks to start work on something using Coder.

---

## Core Principle: Always Use Tasks

**CRITICAL:** All work must start with a Coder Task via `coder_create_task`. This is what makes the workspace visible in the Coder Tasks UI with lifecycle tracking and progress reporting.

**Never call `coder_create_workspace` directly** — the task creates and manages the underlying workspace automatically.

---

## Step-by-Step Task Creation Workflow

### Step 1: Choose a Template

Before creating a task, you must identify which workspace template to use.

**Actions:**
1. Call `coder_list_templates` to show available templates
2. Display the templates to the user with their names and descriptions
3. Ask the user to confirm which template to use before proceeding
4. Note the template's `ActiveVersionID` — this is the `template_version_id` needed for task creation

**Example interaction:**
```
Available templates:
1. python-dev (ActiveVersionID: abc123) - Python development environment
2. go-dev (ActiveVersionID: def456) - Go development environment
3. node-dev (ActiveVersionID: ghi789) - Node.js development environment

Which template would you like to use for this task?
```

**Optional:** If the template has configurable parameters, call `coder_list_template_version_parameters` to show options and gather user preferences.

### Step 2: Create the Task

Once the template is confirmed, create the Coder Task.

**Actions:**
1. Call `coder_create_task` with:
   - `input`: A concise description of the work to be done (this appears in the Coder Tasks UI)
   - `template_version_id`: The `ActiveVersionID` from the confirmed template
   - Optional: `rich_parameter_values` if the template requires parameters

2. After the call succeeds, tell the user:
   ```
   Task created — you can follow along in the Coder Tasks UI at ${CODER_URL}/tasks
   ```

**Example call:**
```json
{
  "input": "Implement user authentication API endpoints",
  "template_version_id": "abc123"
}
```

**What happens:**
- Coder creates a new task entry in the Tasks UI
- Coder provisions a workspace based on the template
- The task status starts as `pending` and transitions to `starting`

### Step 3: Wait for Workspace to Be Ready

The workspace takes time to provision. You must wait until it's running before doing any work.

**Actions:**
1. Poll `coder_get_task_status` every 10 seconds
2. Check the `status` field in the response
3. Continue polling until status is no longer `pending` or `starting`
4. Once status is `running`, the workspace is ready

**Status progression:**
- `pending` → Workspace is being queued
- `starting` → Workspace is provisioning
- `running` → Workspace is ready for work
- `stopped` → Workspace has been stopped
- `failed` → Workspace provisioning failed

**Timeout handling:**
- If the task has not reached `running` status within 5 minutes, something is wrong
- Call `coder_report_task` with `state=failure` and summary explaining the timeout
- Stop polling and inform the user

**Once running:**
1. Call `coder_report_task` with:
   - `state=working`
   - `summary="Workspace ready, starting work"`
2. This updates the Tasks UI to show the agent is actively working

### Step 4: Get Workspace Connection Details

After the workspace is running, you need its name for all subsequent operations.

**Actions:**
1. Call `coder_get_task_logs` to retrieve workspace connection details
2. Extract the workspace name from the logs
3. The workspace name format is typically: `<username>-<task-id>` or similar
4. Store this workspace name — you'll need it for all `coder_workspace_*` tool calls

**Alternative method:**
If `coder_get_task_logs` doesn't provide the workspace name clearly:
1. Call `coder_list_workspaces`
2. Find the workspace created most recently
3. Use that workspace name

**Workspace name format:**
The workspace parameter for all workspace operations uses the format: `owner/workspace-name`
- Example: `alice/alice-task-123`
- Example: `bob/python-dev-456`

---

## Reporting Progress During Work

As you work inside the task workspace, report progress frequently to keep the Coder Tasks UI updated.

**When to report:**
- After completing each meaningful step
- Before starting a long-running operation
- After a long-running operation completes
- When switching between different types of work

**How to report:**
Call `coder_report_task` with:
- `state=working` (indicates active work in progress)
- `summary`: A clear, concise description of current progress

**Summary requirements:**
- Maximum 160 characters
- No newlines or special formatting
- Clear and specific about what's happening
- Written in present tense or present continuous

**Good summary examples:**
- `"Reading project structure in /home/coder/app"`
- `"Implementing the auth handler in src/api/auth.go"`
- `"Running tests — waiting for results"`
- `"Installing dependencies with npm install"`
- `"Building Docker image for deployment"`
- `"Analyzing code for security vulnerabilities"`

**Bad summary examples:**
- `"Working"` (too vague)
- `"Doing stuff in the workspace"` (not specific)
- `"Step 1 complete\nStep 2 starting"` (contains newline)
- `"I am currently in the process of implementing the authentication handler and will then proceed to write comprehensive unit tests"` (too long)

**Example call:**
```json
{
  "state": "working",
  "summary": "Running go test ./... in /home/coder/app"
}
```

---

## Completing a Task

When all work is done successfully, properly complete the task.

**Actions:**
1. Call `coder_report_task` with:
   - `state=idle`
   - `summary`: A clear summary of what was accomplished (under 160 characters)

2. Ask the user if they want to stop the workspace or keep it running:
   ```
   Work complete. Would you like me to stop the workspace to free up resources, or keep it running for review?
   ```

3. If stopping (recommended):
   - Call `coder_create_workspace_build` with:
     - `workspace`: The workspace name (format: `owner/workspace-name`)
     - `transition=stop`
   - This gracefully stops the workspace

4. Optional: If the task is completely done and won't be revisited:
   - Call `coder_delete_task` to clean up the task entry
   - Only do this if the user confirms they don't need the task history

**Completion summary examples:**
- `"Implemented auth endpoints with tests — all passing"`
- `"Fixed bug in payment processor — deployed to staging"`
- `"Refactored database layer — 30% performance improvement"`
- `"Added logging to error handlers — ready for review"`

**Example completion flow:**
```
1. coder_report_task(state="idle", summary="API endpoints implemented and tested")
2. Ask user about stopping workspace
3. coder_create_workspace_build(workspace="alice/task-123", transition="stop")
```

---

## Handling Task Failures

If something goes wrong and the work cannot be completed, properly report the failure.

**When to report failure:**
- Workspace provisioning fails or times out
- Critical errors that prevent work from continuing
- User explicitly cancels the work
- Unrecoverable errors in the workspace

**Actions:**
1. Call `coder_report_task` with:
   - `state=failure`
   - `summary`: A clear description of what went wrong (under 160 characters)

2. Stop the workspace immediately:
   - Call `coder_create_workspace_build` with `transition=stop`
   - **Do not leave workspaces running after a failure**

3. Inform the user of the failure and what happened

**Failure summary examples:**
- `"Workspace provisioning timed out after 5 minutes"`
- `"Tests failed — 3 critical errors in auth module"`
- `"Build failed — missing dependency: libssl-dev"`
- `"Cannot connect to database — check credentials"`

**Example failure flow:**
```
1. coder_report_task(state="failure", summary="Build failed — missing Go 1.21")
2. coder_create_workspace_build(workspace="alice/task-123", transition="stop")
3. Inform user of the failure
```

---

## Finding Existing Tasks

Before creating a new task, check if there's already a running task for similar work.

**Actions:**
1. Call `coder_list_tasks` to see all tasks
2. Check for tasks with status `running` or `pending`
3. If a relevant task exists, ask the user if they want to:
   - Continue with the existing task
   - Create a new task anyway
   - Stop the old task and create a new one

**Why this matters:**
- Avoids duplicate workspaces consuming resources
- Maintains continuity if work was interrupted
- Keeps task history organized

---

## Task Lifecycle Summary

```
1. Choose template (coder_list_templates)
   ↓
2. Create task (coder_create_task)
   ↓
3. Wait for running (poll coder_get_task_status)
   ↓
4. Report working (coder_report_task state=working)
   ↓
5. Get workspace name (coder_get_task_logs)
   ↓
6. Do work (see workspace-ops.md steering file)
   ↓
7. Report progress frequently (coder_report_task state=working)
   ↓
8. Complete or fail:
   - Success: coder_report_task state=idle
   - Failure: coder_report_task state=failure
   ↓
9. Stop workspace (coder_create_workspace_build transition=stop)
   ↓
10. Optional: Delete task (coder_delete_task)
```

---

## Common Patterns

### Pattern: Quick Task for Simple Work

For simple, short-lived work:
```
1. Create task with clear description
2. Wait for running
3. Do the work quickly
4. Report idle with summary
5. Stop workspace immediately
6. Delete task to keep task list clean
```

### Pattern: Long-Running Development Task

For extended development work:
```
1. Create task with project description
2. Wait for running
3. Report progress at each major step
4. Keep workspace running between work sessions
5. When completely done, report idle and stop
6. Keep task in history for reference
```

### Pattern: Batch Processing Task

For processing multiple items:
```
1. Create task describing the batch job
2. Wait for running
3. For each item:
   - Report progress: "Processing item X of Y"
   - Do the work
4. Report idle with summary of results
5. Stop workspace
```

---

## Error Handling

### Workspace Provisioning Timeout

```
If coder_get_task_status shows "pending" or "starting" for > 5 minutes:
1. coder_report_task(state="failure", summary="Provisioning timeout")
2. Inform user to check Coder server logs
3. Do not proceed with work
```

### Workspace Connection Lost

```
If workspace operations start failing:
1. Call coder_get_task_status to check workspace state
2. If stopped or failed:
   - coder_report_task(state="failure", summary="Workspace connection lost")
   - Inform user
3. If still running:
   - Retry the operation
   - If still failing, report failure
```

### User Cancellation

```
If user asks to cancel work:
1. coder_report_task(state="failure", summary="Cancelled by user")
2. coder_create_workspace_build(transition="stop")
3. Confirm cancellation to user
```

---

## Best Practices

- Always wait for `running` status before doing any workspace operations
- Report progress every 1-2 minutes during long operations
- Keep summaries clear, concise, and under 160 characters
- Always stop workspaces after completion or failure
- Check for existing tasks before creating new ones
- Use meaningful task descriptions that explain the work goal
- Don't leave workspaces running unnecessarily — they consume resources
- If unsure about workspace state, call `coder_get_task_status` to check

---

## Next Steps

Once the task workspace is running and you have the workspace name, load the `workspace-ops.md` steering file to learn how to:
- Run commands inside the workspace
- Read and write files
- Check running applications
- Access workspace ports
