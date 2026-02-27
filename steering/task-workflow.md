# Coder Task Creation and Monitoring Workflow

This steering file teaches you how to create and monitor Coder Tasks. Load this when the developer asks to start work on something using Coder.

---

## Core Principle: Always Use Tasks

**CRITICAL:** All work must start with a Coder Task via `coder_create_task`. This is what makes the workspace visible in the Coder Tasks UI with lifecycle tracking and progress reporting.

**Never call `coder_create_workspace` directly** — the task creates and manages the underlying workspace automatically.

---

## Step-by-Step Task Creation Workflow

### Step 1: Choose a Task-Ready Template

Before creating a task, you must identify which workspace template to use. **Only templates that define a `coder_ai_task` resource are suitable for AI agent work.**

**Actions:**
1. Call `coder_list_templates` to show available templates
2. **Filter for task-ready templates**: Check each template's metadata or description for indication of AI task support
3. Display only task-ready templates to the user with their names and descriptions
4. Ask the user to confirm which template to use before proceeding
5. Note the template's `ActiveVersionID` — this is the `template_version_id` needed for task creation

**Identifying Task-Ready Templates:**

Templates designed for AI agent work will typically:
- Include "task" or "ai-task" in the name or description
- Have metadata indicating AI agent support
- Define a `coder_ai_task` resource in their Terraform configuration

**Example interaction:**
```
Available task-ready templates:
1. python-ai-task (ActiveVersionID: abc123) - Python development with AI task support
2. go-ai-task (ActiveVersionID: def456) - Go development with AI task support
3. node-ai-task (ActiveVersionID: ghi789) - Node.js development with AI task support

Which template would you like to use for this task?
```

**If no task-ready templates are available:**
```
No task-ready templates found. Task-ready templates must define a coder_ai_task resource.

Please ask your Coder administrator to create a template with AI task support, or see the template example in this power for guidance.
```

**Optional:** If the template has configurable parameters, call `coder_template_version_parameters` to show options and gather user preferences.

### Step 2: Create the Task with Feature Branch

Once the template is confirmed, create the Coder Task with a feature branch for git worktree.

**Actions:**
1. Generate a unique feature branch name based on the task description
2. Create the feature branch in the home workspace
3. Call `coder_create_task` with:
   - `input`: A concise description of the work to be done
   - `template_version_id`: The `ActiveVersionID` from the confirmed template
   - `rich_parameter_values`: Include feature branch and home workspace information

**Feature branch naming:**
```python
# Generate descriptive branch name
task_slug = task_description.lower().replace(" ", "-")[:30]
feature_branch = f"feature/{task_slug}"

# Or with timestamp for uniqueness
feature_branch = f"feature/{task_slug}-{int(time.time())}"
```

**Create feature branch in home workspace:**
```python
coder_workspace_bash(
    workspace=home_workspace,
    command=f"""
        cd /workspaces/my-project
        git checkout -b {feature_branch}
        git push -u origin {feature_branch}
    """,
    timeout_ms=15000
)
```

**Create task with parameters:**
```python
task = coder_create_task(
    input="Implement user authentication API endpoints",
    template_version_id="abc123",
    rich_parameter_values={
        "feature_branch": feature_branch,
        "home_workspace": f"{owner}/{workspace_name}",
        "project_path": "/workspaces/my-project"
    }
)
```

2. After the call succeeds, tell the user:
   ```
   Task created on branch {feature_branch} — you can follow along in the Coder Tasks UI at ${CODER_URL}/tasks
   ```

**What happens:**
- Coder creates a new task entry in the Tasks UI
- Coder provisions a workspace based on the template
- Task workspace startup script creates git worktree pointing to feature branch
- Task workspace is ready to work with git directly

### Step 3: Wait for Workspace to Be Ready

The workspace takes time to provision. You must wait until it's running before doing any work.

**Actions:**
1. Poll `coder_get_task_status` using optimal intervals (see below)
2. Check the `status` field in the response
3. Continue polling until status is no longer `pending` or `starting`
4. Once status is `running`, the workspace is ready

**Status progression:**
- `pending` → Workspace is being queued
- `starting` → Workspace is provisioning
- `running` → Workspace is ready for work
- `stopped` → Workspace has been stopped
- `failed` → Workspace provisioning failed

**Optimal Polling Intervals:**
- **First check:** Immediately after task creation
- **Subsequent checks:** Every 10 seconds
- **Timeout:** 5 minutes for initial provisioning
- **Reason:** Provisioning is usually quick (30-90 seconds) but can take longer for first-time images

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

**Extracting Workspace Name from Logs:**

Look for these patterns in the logs:

**Pattern 1: Direct workspace reference**
```
Workspace: owner/workspace-name
```

**Pattern 2: Task ID format**
```
Task created: owner--task-abc123
```

**Pattern 3: Agent connection log**
```
Agent connected in workspace: owner/workspace-name
```

**Pattern 4: Workspace build log**
```
Starting workspace build for: owner/workspace-name
```

**Alternative method:**
If `coder_get_task_logs` doesn't provide the workspace name clearly:
1. Call `coder_list_workspaces`
2. Find the workspace created most recently (check `created_at` timestamp)
3. Use that workspace name

**Workspace name format:**
The workspace parameter for all workspace operations uses the format: `owner/workspace-name`
- Example: `alice/alice-task-123`
- Example: `bob/python-dev-456`

**Important:** Store this workspace name as you'll use it for:
- `coder_workspace_bash` - Running commands
- `coder_workspace_read_file` - Reading files
- `coder_workspace_write_file` - Writing files
- `coder_workspace_edit_file` - Editing files
- `coder_workspace_ls` - Listing directories
- All other workspace operations

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

**Optimal Polling Intervals for Task State:**
- **After sending prompt to workspace agent:** Wait 30 seconds before first check
- **While agent is working:** Check every 30-60 seconds
- **Long-running operations:** Check every 2-5 minutes
- **Use exponential backoff for very long tasks:** 30s, 1m, 2m, 5m, 5m...
- **Reason:** Give workspace agent time to work, reduce API load

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

When all work is done successfully, properly complete the task by merging the feature branch back to the home workspace.

**GIT WORKTREE PATTERN:** Task workspaces work on feature branches via git worktrees. Work is shared via standard git operations (commit, push, merge) instead of file copying.

### Step 1: Commit and Push from Task Workspace

Ensure all work in the task workspace is committed and pushed to the feature branch:

```python
coder_workspace_bash(
    workspace=task_workspace,
    command="""
        cd /workspaces/task-workspace
        
        # Check for uncommitted changes
        if [ -n "$(git status --porcelain)" ]; then
            # Commit any remaining changes
            git add .
            git commit -m "Complete task: [description]"
        fi
        
        # Push to remote
        git push origin {feature_branch}
        
        # Show final commit
        git log -1 --oneline
    """,
    timeout_ms=30000
)
```

### Step 2: Merge Feature Branch in Home Workspace

Merge the feature branch to main in the home workspace:

```python
coder_workspace_bash(
    workspace=home_workspace,
    command=f"""
        cd /workspaces/my-project
        
        # Fetch latest changes
        git fetch origin
        
        # Checkout main branch
        git checkout main
        
        # Merge feature branch (no fast-forward to preserve history)
        git merge origin/{feature_branch} --no-ff -m "Merge {feature_branch}: [task description]"
        
        # Push to remote
        git push origin main
        
        # Show merge commit
        git log -1 --oneline
    """,
    timeout_ms=30000
)
```

### Step 3: Verify Merge

Confirm the merge was successful:

```python
result = coder_workspace_bash(
    workspace=home_workspace,
    command="""
        cd /workspaces/my-project
        git log --oneline -5
    """,
    timeout_ms=15000
)

# Check exit code
if result.exit_code == 0:
    print(f"✅ Merge successful: {result.stdout}")
else:
    print(f"❌ Merge failed: {result.stderr}")
```

### Step 4: Clean Up Feature Branch (Optional)

Delete the feature branch after successful merge:

```python
coder_workspace_bash(
    workspace=home_workspace,
    command=f"""
        cd /workspaces/my-project
        
        # Delete local branch
        git branch -d {feature_branch}
        
        # Delete remote branch
        git push origin --delete {feature_branch}
        
        # Prune worktree references
        git worktree prune
    """,
    timeout_ms=15000
)
```

### Step 5: Stop Task Workspace

After successful merge:

```python
coder_create_workspace_build(
    workspace_id=task_workspace_id,
    transition="stop"
)
```

### Step 6: Inform User

```python
print(f"""
✅ Task complete!

Feature branch: {feature_branch}
Merged to: main
Commits: [show commit count]
Task workspace: stopped

All changes are now in the home workspace on the main branch.
""")
```

**CRITICAL RULES:**
1. ✅ Always commit and push from task workspace BEFORE merging
2. ✅ Use `--no-ff` flag to preserve feature branch history
3. ✅ Verify merge succeeded before stopping workspace
4. ✅ Home workspace main branch is the permanent record

**Example completion flow:**
```
1. Task workspace commits and pushes to feature branch
2. Home workspace fetches and merges feature branch to main
3. Verify merge successful
4. Clean up feature branch (optional)
5. Stop task workspace
6. Inform user of completion
```

**Benefits of git worktree approach:**
- ✅ No file copying needed
- ✅ Minimal token usage (only git commands)
- ✅ Full git history preserved
- ✅ Atomic operations
- ✅ Standard git workflow

**Getting Home Workspace Name:**
The home workspace is where Kiro is currently running:
```
HOME_WORKSPACE = f"{CODER_WORKSPACE_OWNER_NAME}/{CODER_WORKSPACE_NAME}"
```
These environment variables are automatically available in Coder workspaces.

**Note:** Task state (idle/complete) is managed by the agent inside the workspace. External monitoring can check `coder_get_task_status` to see the final state.

---

## Handling Task Failures

If something goes wrong and the work cannot be completed, properly handle the failure while attempting to salvage any work.

**When to handle failure:**
- Workspace provisioning fails or times out
- Critical errors that prevent work from continuing
- User explicitly cancels the work
- Unrecoverable errors in the workspace

**Actions:**

### Step 1: Attempt to Salvage Work

Even if the task failed, try to transfer any completed work:

```
1. Check if workspace is still accessible
2. Identify any files that were created/modified
3. Transfer salvageable files to home workspace
4. Log what was transferred and what was lost
```

**Example:**
```
try:
  # Try to get any changed files
  result = coder_workspace_bash(
    workspace="task-workspace-name",
    command="find /home/coder/project -type f -mmin -60",
    timeout_ms=15000
  )
  
  # Transfer what we can
  for file_path in result.stdout.split('\n'):
    if file_path.strip():
      content = coder_workspace_read_file(workspace="task-workspace-name", path=file_path)
      coder_workspace_write_file(workspace="home-workspace-name", path=file_path, content=content)
  
  inform_user("Salvaged [N] files before stopping workspace")
except:
  inform_user("Could not salvage work - workspace inaccessible")
```

### Step 2: Stop the Workspace

After attempting salvage:

```
coder_create_workspace_build(
  workspace_id="task-workspace-id",
  transition="stop"
)
```

**CRITICAL:** Always stop the workspace after a failure to avoid consuming unnecessary resources.

### Step 3: Inform User

Provide clear information about:
- What failed and why
- What work (if any) was salvaged
- What work was lost
- Next steps

**Note:** Task state (failure/error) is managed by the agent inside the workspace. External monitoring can check `coder_get_task_status` to see the final state.

**Example failure flow:**
```
1. Attempt to salvage any completed work
2. Transfer salvaged files to home workspace
3. coder_create_workspace_build(workspace_id="...", transition="stop")
4. Inform user: "Work failed — [clear description]. Salvaged [N] files. Workspace stopped."
```

**Best Practice:** For long-running tasks, transfer work at checkpoints (see Checkpoint Pattern below) so that failure doesn't lose all progress.

---

## Checkpoint Pattern for Long Tasks

For long-running tasks with multiple phases, transfer work at checkpoints to avoid losing progress if something fails.

### When to Use Checkpoints

- Multi-phase tasks (design → implement → test)
- Long-running development (hours or days)
- Complex refactoring with multiple steps
- Any task where partial progress is valuable

### Checkpoint Workflow

**Phase 1: Initial Implementation**
```
1. Do work in task workspace
2. Reach checkpoint (e.g., "basic implementation complete")
3. Transfer files to home workspace
4. Commit in home workspace: "Phase 1: Basic implementation"
5. Continue to next phase
```

**Phase 2: Add Tests**
```
1. Continue work in task workspace
2. Reach checkpoint (e.g., "tests added")
3. Transfer files to home workspace
4. Commit in home workspace: "Phase 2: Tests added"
5. Continue to next phase
```

**Phase 3: Documentation**
```
1. Continue work in task workspace
2. Complete final phase
3. Transfer files to home workspace
4. Commit in home workspace: "Phase 3: Documentation complete"
5. Stop task workspace
```

### Benefits of Checkpoints

- ✅ No work lost if task fails mid-way
- ✅ Progress visible in home workspace
- ✅ Can resume from checkpoint if needed
- ✅ Clear project history with commits
- ✅ Reduces risk of data loss

### Checkpoint Implementation

```python
def checkpoint_transfer(task_workspace, home_workspace, phase_name):
    """Transfer work at a checkpoint"""
    
    # 1. Identify changed files since last checkpoint
    result = coder_workspace_bash(
        workspace=task_workspace,
        command="cd /home/coder/project && git diff --name-only HEAD",
        timeout_ms=15000
    )
    
    changed_files = [f for f in result.stdout.split('\n') if f.strip()]
    
    # 2. Transfer each file
    for file_path in changed_files:
        full_path = f"/home/coder/project/{file_path}"
        content = coder_workspace_read_file(workspace=task_workspace, path=full_path)
        coder_workspace_write_file(workspace=home_workspace, path=full_path, content=content)
    
    # 3. Commit in home workspace
    coder_workspace_bash(
        workspace=home_workspace,
        command=f"cd /home/coder/project && git add . && git commit -m 'Checkpoint: {phase_name}'",
        timeout_ms=30000
    )
    
    # 4. Create checkpoint marker in task workspace
    coder_workspace_bash(
        workspace=task_workspace,
        command="cd /home/coder/project && git add . && git commit -m 'Checkpoint marker'",
        timeout_ms=15000
    )
    
    return len(changed_files)
```

### Checkpoint Best Practices

1. **Transfer at logical boundaries:** End of phases, after tests pass, before breaks
2. **Use descriptive commit messages:** "Phase 1: API implementation", "Checkpoint: Tests passing"
3. **Verify transfer:** Always check files arrived in home workspace
4. **Don't checkpoint too frequently:** Every 30-60 minutes is reasonable
5. **Always checkpoint before long breaks:** End of day, lunch, meetings

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
7. When complete or at checkpoint:
   ↓
8. **TRANSFER WORK TO HOME WORKSPACE** ← CRITICAL STEP
   - Identify changed files
   - Read from task workspace
   - Write to home workspace
   - Verify transfer
   - Commit in home workspace
   ↓
9. Stop workspace (coder_create_workspace_build transition=stop)
   ↓
10. Optional: Delete task (coder_delete_task)
```

**Key Addition:** Step 8 is the new critical step that ensures all work is preserved in the home workspace before the task workspace is stopped.

---

## Common Patterns

### Pattern: Quick Task for Simple Work

For simple, short-lived work:
```
1. Create task with clear description
2. Wait for running
3. Do the work quickly
4. **Transfer files to home workspace**
5. Stop workspace immediately
6. Delete task to keep task list clean
```

### Pattern: Long-Running Development Task

For extended development work:
```
1. Create task with project description
2. Wait for running
3. Do the work (task state managed by workspace agent)
4. **Transfer at checkpoints** (end of phases, before breaks)
5. When completely done:
   - **Final transfer to home workspace**
   - Stop workspace
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
4. **Transfer all results to home workspace**
5. Stop workspace when complete
```

### Pattern: Multi-Phase Development

For complex work with distinct phases:
```
1. Create task
2. Phase 1: Design
   - Do design work
   - **Checkpoint: Transfer to home workspace**
3. Phase 2: Implementation
   - Implement features
   - **Checkpoint: Transfer to home workspace**
4. Phase 3: Testing
   - Add tests
   - **Checkpoint: Transfer to home workspace**
5. Phase 4: Documentation
   - Write docs
   - **Final transfer to home workspace**
6. Stop workspace
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
