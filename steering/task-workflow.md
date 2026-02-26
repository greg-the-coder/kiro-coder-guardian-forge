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
- Stop polling and inform the user
- Stop the workspace with `coder_create_workspace_build` to clean up

**Once running:**
- The workspace is ready for work
- The task state will be managed by the agent inside the workspace (e.g., Claude Code)
- You can now execute commands and perform file operations
- Monitor task state by calling `coder_get_task_status` periodically

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

## Monitoring Task Progress

While working inside the task workspace, you can monitor the task state set by the workspace agent.

**How to monitor:**
Call `coder_get_task_status` periodically to check:
- `status`: Overall task status (active, paused, stopped)
- `state.state`: Current work state (working, idle, failure)
- `state.message`: Description of current activity
- `state.timestamp`: When state was last updated

**Note:** Task state is managed by the agent running inside the workspace (e.g., Claude Code, Cursor, etc.). External agents can only read the state, not update it.

**Example monitoring:**
```json
{
  "status": "active",
  "state": {
    "state": "working",
    "message": "Running tests in /home/coder/app",
    "timestamp": "2026-02-26T18:30:00Z"
  }
}
```

---

## Completing a Task

When all work is done successfully, properly complete the task.

**Actions:**
1. **Stop the workspace:**
   - Call `coder_create_workspace_build` with:
     - `workspace_id`: The workspace ID from task creation
     - `transition=stop`
   - This gracefully stops the workspace and frees resources

2. Inform the user that the work is complete and workspace is stopping

**CRITICAL:** Always stop the workspace when work is complete to avoid consuming unnecessary resources.

**Example completion flow:**
```
1. coder_create_workspace_build(workspace_id="...", transition="stop")
2. Inform user: "Work complete. Workspace is stopping."
```

**Note:** Task state (idle/complete) is managed by the agent inside the workspace. External monitoring can check `coder_get_task_status` to see the final state.

---

## Handling Task Failures

If something goes wrong and the work cannot be completed, properly handle the failure.

**When to handle failure:**
- Workspace provisioning fails or times out
- Critical errors that prevent work from continuing
- User explicitly cancels the work
- Unrecoverable errors in the workspace

**Actions:**
1. **Always stop the workspace:**
   - Call `coder_create_workspace_build` with:
     - `workspace_id`: The workspace ID
     - `transition=stop`
   - **Do not leave workspaces running after a failure**

2. Inform the user of the failure and what happened

**CRITICAL:** Always stop the workspace after a failure to avoid consuming unnecessary resources.

**Note:** Task state (failure/error) is managed by the agent inside the workspace. External monitoring can check `coder_get_task_status` to see the final state.

**Example failure flow:**
```
1. coder_create_workspace_build(workspace_id="...", transition="stop")
2. Inform user: "Work failed — [clear description]. Workspace is stopping."
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
4. Get workspace name (coder_get_task_logs)
   ↓
5. Do work (see workspace-ops.md steering file)
   ↓
6. Monitor task state (coder_get_task_status shows state set by workspace agent)
   ↓
7. When complete:
   - Stop workspace (coder_create_workspace_build transition=stop)
   ↓
8. Optional: Delete task (coder_delete_task)
```

---

## Common Patterns

### Pattern: Quick Task for Simple Work

For simple, short-lived work:
```
1. Create task with clear description
2. Wait for running
3. Do the work quickly
4. Stop workspace immediately
5. Delete task to keep task list clean
```

### Pattern: Long-Running Development Task

For extended development work:
```
1. Create task with project description
2. Wait for running
3. Do the work (task state managed by workspace agent)
4. Keep workspace running between work sessions
5. When completely done, stop workspace
6. Keep task in history for reference
```

### Pattern: Batch Processing Task

For processing multiple items:
```
1. Create task describing the batch job
2. Wait for running
3. For each item:
   - Do the work
   - Monitor progress via coder_get_task_status
4. Stop workspace when complete
```

---

## Error Handling

### Workspace Provisioning Timeout

```
If coder_get_task_status shows "pending" or "starting" for > 5 minutes:
1. coder_create_workspace_build(transition="stop")
2. Inform user to check Coder server logs
3. Do not proceed with work
```

### Workspace Connection Lost

```
If workspace operations start failing:
1. Call coder_get_task_status to check workspace state
2. If stopped or failed:
   - Inform user that workspace is no longer available
3. If still running:
   - Retry the operation
   - If still failing, stop workspace and inform user
```

### User Cancellation

```
If user asks to cancel work:
1. coder_create_workspace_build(transition="stop")
2. Confirm cancellation to user
```

---

## Best Practices

- Always wait for `running` status before doing any workspace operations
- Monitor task state by calling `coder_get_task_status` periodically
- Always stop workspaces after completion or failure
- Check for existing tasks before creating new ones
- Use meaningful task descriptions that explain the work goal
- Don't leave workspaces running unnecessarily — they consume resources
- If unsure about workspace state, call `coder_get_task_status` to check
- Task state (working/idle/failure) is managed by the workspace agent, not external agents

---

## Next Steps

Once the task workspace is running and you have the workspace name, load the `workspace-ops.md` steering file to learn how to:
- Run commands inside the workspace
- Read and write files
- Check running applications
- Access workspace ports
