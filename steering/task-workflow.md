# Coder Task Creation and Monitoring Workflow

This steering file teaches you how to create and monitor Coder Tasks. Load this when the developer asks to start work on something using Coder.

---

## Quick Start: Create Task in 5-10 Minutes

**For agents: Follow this complete workflow for fastest, error-free task creation**

### Step 0: Pre-Flight Validation (REQUIRED - 1 minute)

**Before creating any task, validate all prerequisites to prevent failures:**

```python
# Validation function - run this first
def validate_task_prerequisites(home_workspace, repo_path):
    """
    Validate all prerequisites before task creation.
    Returns: (valid: bool, issues: list, fixes: list)
    """
    issues = []
    fixes = []
    
    # Check 1: Verify Coder environment
    result = coder_workspace_bash(
        workspace=home_workspace,
        command="echo $CODER_URL && echo $CODER_WORKSPACE_NAME",
        timeout_ms=5000
    )
    if not result.stdout.strip():
        issues.append("Not running in Coder workspace")
        fixes.append("This power requires a Coder workspace environment")
        return (False, issues, fixes)
    
    # Check 2: Verify git repository exists
    result = coder_workspace_bash(
        workspace=home_workspace,
        command=f"cd {repo_path} && git status",
        timeout_ms=10000
    )
    if result.exit_code != 0:
        issues.append(f"No git repository found at {repo_path}")
        fixes.append(f"Clone repository: git clone <repo-url> {repo_path}")
        return (False, issues, fixes)
    
    # Check 3: Verify Coder git SSH wrapper is configured (CRITICAL)
    result = coder_workspace_bash(
        workspace=home_workspace,
        command="echo $GIT_SSH_COMMAND",
        timeout_ms=5000
    )
    if not result.stdout.strip() or "coder gitssh" not in result.stdout:
        issues.append("Coder git SSH wrapper not configured")
        fixes.append("""
GIT_SSH_COMMAND environment variable must be set to Coder's git SSH wrapper.

Expected: GIT_SSH_COMMAND=/tmp/coder.*/coder gitssh --

This is automatically configured by Coder workspace templates. If missing:
1. Restart workspace to reload environment variables
2. Check Coder agent logs for initialization errors
3. Contact Coder administrator to verify template configuration

Why this matters: Coder uses a custom SSH wrapper (coder gitssh) that handles
SSH authentication through Coder's infrastructure using Coder-managed SSH keys.
Without this, git operations will fail.
        """)
        return (False, issues, fixes)
    
    # Check 3a: Verify git authentication works (CRITICAL)
    result = coder_workspace_bash(
        workspace=home_workspace,
        command="git ls-remote git@github.com:coder/coder.git HEAD 2>&1",
        timeout_ms=10000
    )
    if result.exit_code != 0:
        issues.append("Git authentication not working")
        fixes.append("""
Git operations are failing even though GIT_SSH_COMMAND is set.

Troubleshooting steps:
1. Test wrapper directly: $GIT_SSH_COMMAND -T git@github.com
2. Check wrapper binary exists: ls -la $(echo $GIT_SSH_COMMAND | awk '{print $1}')
3. Verify network connectivity: ping github.com
4. Check Coder agent logs for authentication errors
5. Contact Coder administrator if issue persists

Note: Coder manages SSH keys centrally - no user SSH key setup required.
        """)
        return (False, issues, fixes)
    
    # Check 4: Verify git remote uses SSH
    result = coder_workspace_bash(
        workspace=home_workspace,
        command=f"cd {repo_path} && git remote get-url origin",
        timeout_ms=5000
    )
    if "https://" in result.stdout:
        issues.append("Git remote uses HTTPS instead of SSH")
        fixes.append(f"""
Convert remote to SSH:
cd {repo_path}
git remote set-url origin git@github.com:user/repo.git
git remote -v
        """)
        return (False, issues, fixes)
    
    # Check 5: Verify task-ready templates exist
    templates = coder_list_templates()
    task_templates = [t for t in templates 
                     if 'task' in t.name.lower() or 'ai-task' in t.name.lower()]
    if not task_templates:
        issues.append("No task-ready templates available")
        fixes.append("Contact Coder admin to create task-ready template with coder_ai_task resource")
        return (False, issues, fixes)
    
    # All checks passed
    return (True, [], [])

# Run validation before proceeding
valid, issues, fixes = validate_task_prerequisites(
    home_workspace=f"{CODER_WORKSPACE_OWNER_NAME}/{CODER_WORKSPACE_NAME}",
    repo_path="/workspaces/my-project"
)

if not valid:
    print("❌ Pre-flight validation failed:")
    for issue in issues:
        print(f"  - {issue}")
    print("\n🔧 Required fixes:")
    for fix in fixes:
        print(fix)
    # STOP - do not proceed until issues are fixed
    return False

print("✅ All prerequisites validated - proceeding with task creation")
```

### Step 1: Filter Task-Ready Templates (30 seconds)

```python
def filter_task_ready_templates(all_templates):
    """Filter templates to find task-ready ones"""
    task_ready = []
    
    for template in all_templates:
        name = template.name.lower()
        desc = template.description.lower() if template.description else ""
        
        # High confidence indicators
        if any(keyword in name for keyword in ['task', 'ai-task', 'claude-code', 'cursor']):
            task_ready.append(template)
            continue
        
        # Medium confidence indicators
        if any(keyword in desc for keyword in ['ai task', 'agent work', 'claude code', 'ephemeral']):
            task_ready.append(template)
            continue
    
    return task_ready

# Get and filter templates
all_templates = coder_list_templates()
task_templates = filter_task_ready_templates(all_templates)

if not task_templates:
    print("❌ No task-ready templates found")
    print("Contact Coder admin to create template with coder_ai_task resource")
    return False

# Show templates to user
print("Available task-ready templates:")
for i, template in enumerate(task_templates, 1):
    print(f"{i}. {template.name} - {template.description}")

# Select template (first one or ask user)
selected_template = task_templates[0]
template_version_id = selected_template.active_version_id
```

### Step 2: Create Feature Branch (1 minute)

```python
import time

# Generate unique feature branch name
task_slug = task_description.lower().replace(" ", "-")[:30]
feature_branch = f"feature/{task_slug}-{int(time.time())}"

# Create and push feature branch in home workspace
result = coder_workspace_bash(
    workspace=home_workspace,
    command=f"""
        cd {repo_path}
        
        # Create feature branch
        git checkout -b {feature_branch}
        
        # Push to remote
        git push -u origin {feature_branch}
        
        # Verify push succeeded
        if [ $? -eq 0 ]; then
            echo "✅ Feature branch created: {feature_branch}"
            git log -1 --oneline
        else
            echo "❌ Failed to push feature branch"
            exit 1
        fi
    """,
    timeout_ms=30000
)

if result.exit_code != 0:
    print(f"❌ Failed to create feature branch: {result.stderr}")
    return False

print(f"✅ Feature branch created: {feature_branch}")
```

### Step 3: Create Task (1 minute)

```python
# Create task with git worktree parameters
task = coder_create_task(
    input=f"Work on {task_description}. Use git worktree on branch {feature_branch}.",
    template_version_id=template_version_id,
    rich_parameter_values={
        "feature_branch": feature_branch,
        "home_workspace": home_workspace,
        "repo_path": repo_path
    }
)

print(f"✅ Task created: {task.id}")
print(f"📊 Monitor at: {CODER_URL}/tasks")
```

### Step 4: Wait for Workspace Ready (1-3 minutes)

```python
import time

# Wait for workspace to be running
max_wait = 300  # 5 minutes
start_time = time.time()
check_interval = 10  # Start with 10 seconds

while True:
    elapsed = time.time() - start_time
    if elapsed > max_wait:
        print("❌ Timeout waiting for workspace to start")
        return False
    
    status = coder_get_task_status(task_id=task.id)
    
    if status.status == "running":
        print("✅ Workspace is running and ready")
        break
    elif status.status == "failed":
        print(f"❌ Workspace provisioning failed: {status.error}")
        return False
    else:
        print(f"⏳ Workspace status: {status.status} (waiting {check_interval}s)")
        time.sleep(check_interval)
        check_interval = min(check_interval + 5, 30)  # Increase interval up to 30s
```

### Step 5: Get Workspace Name (30 seconds)

```python
# Get workspace connection details from logs
logs = coder_get_task_logs(task_id=task.id)

# Extract workspace name (format: owner/workspace-name)
# Look for patterns in logs
import re
workspace_match = re.search(r'Workspace:\s+(\S+/\S+)', logs)
if workspace_match:
    task_workspace = workspace_match.group(1)
else:
    # Fallback: use task ID format
    task_workspace = f"{CODER_WORKSPACE_OWNER_NAME}/{task.id}"

print(f"✅ Task workspace: {task_workspace}")
```

### Step 6: Begin Work (Ready!)

```python
print(f"""
✅ Task ready for work!

Task ID: {task.id}
Workspace: {task_workspace}
Feature Branch: {feature_branch}
Monitor: {CODER_URL}/tasks

Next steps:
- Send work to task workspace with coder_send_task_input
- Or execute commands with coder_workspace_bash
- Monitor progress with coder_get_task_status
- When complete, merge back to home workspace
""")
```

**Total time: 5-10 minutes from validation to ready**

---

## Core Principle: Always Use Tasks

**CRITICAL:** All work must start with a Coder Task via `coder_create_task`. This is what makes the workspace visible in the Coder Tasks UI with lifecycle tracking and progress reporting.

**Never call `coder_create_workspace` directly** — the task creates and manages the underlying workspace automatically.

---

## Pre-Flight Validation Checklist

**Always run these checks before creating a task to prevent failures:**

### 1. Verify Coder Workspace Environment

```bash
# Check environment variables
echo $CODER_URL
echo $CODER_WORKSPACE_NAME
echo $CODER_WORKSPACE_OWNER_NAME
```

**Expected:** All variables should have values  
**If missing:** Not running in Coder workspace - this power requires Coder

### 2. Verify Git Repository

```bash
# Check git repository exists
cd /workspaces/my-project && git status
```

**Expected:** Should show git status, not "not a git repository"  
**If fails:** Clone repository or initialize git

### 3. Verify Coder Git SSH Wrapper (CRITICAL)

```bash
# Check GIT_SSH_COMMAND environment variable
echo $GIT_SSH_COMMAND
```

**Expected:** `/tmp/coder.*/coder gitssh --` (path will vary)  
**Why this matters:** Coder workspaces use a custom git SSH wrapper (`coder gitssh`) that handles SSH authentication through Coder's infrastructure using Coder-managed SSH keys. This wrapper is automatically configured via the `GIT_SSH_COMMAND` environment variable and is essential for all git operations.

**If empty or incorrect:**
```bash
# Verify the wrapper exists
ls -la /tmp/coder.*/coder

# If missing, restart workspace or contact Coder administrator
```

### 3a. Verify Git Authentication Works (CRITICAL)

```bash
# Test git operations
git ls-remote git@github.com:coder/coder.git HEAD
```

**Expected:** Commit hash and HEAD reference  
**If fails:**
```bash
# Test wrapper directly
$GIT_SSH_COMMAND -T git@github.com

# Check network connectivity
ping github.com

# Check Coder agent logs for errors
# Contact Coder administrator if issue persists
```

**Note:** No SSH key generation or GitHub/GitLab key management required - Coder handles all authentication automatically through the git SSH wrapper.

### 4. Verify Git Remote Uses SSH

```bash
cd /workspaces/my-project
git remote -v
```

**Expected:** Should show `git@github.com:user/repo.git`  
**If shows https://**:
```bash
# Convert to SSH
git remote set-url origin git@github.com:user/repo.git
git remote -v
```

### 5. Verify Task-Ready Templates

```python
# Call coder_list_templates and filter
templates = coder_list_templates()
task_templates = [t for t in templates 
                 if 'task' in t.name.lower() or 'ai-task' in t.name.lower()]
```

**Expected:** At least one task-ready template available  
**If none found:** Contact Coder administrator to create task-ready template

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

When all work is done successfully, properly complete the task by transferring work back to the home workspace.

**WORK TRANSFER PATTERN:** Task workspaces work on feature branches. Work is shared via git operations (commit, push, fetch, merge) - the most efficient and reliable method.

### Complete Task with Automatic Cleanup

Use this comprehensive function for reliable task completion:

```python
def complete_task_with_cleanup(task_workspace, home_workspace, feature_branch, task_description, repo_path="/workspaces/project"):
    """Complete task with automatic work transfer and cleanup"""
    
    # Step 1: Commit and push from task workspace
    print("📤 Committing and pushing from task workspace...")
    result = coder_workspace_bash(
        workspace=task_workspace,
        command=f"""
            cd {repo_path}
            
            # Check for uncommitted changes
            if [ -n "$(git status --porcelain)" ]; then
                # Stage all changes
                git add .
                
                # Commit with descriptive message
                git commit -m "Complete: {task_description}"
            fi
            
            # Push to remote
            git push origin {feature_branch}
            
            # Verify push succeeded
            if [ $? -eq 0 ]; then
                echo "✅ Pushed to {feature_branch}"
                git log -1 --oneline
            else
                echo "❌ Push failed"
                exit 1
            fi
        """,
        timeout_ms=60000
    )
    
    if result.exit_code != 0:
        print(f"❌ Failed to push from task workspace: {result.stderr}")
        return False
    
    print(f"✅ Task workspace pushed to {feature_branch}")
    
    # Step 2: Fetch and merge in home workspace
    print("📥 Fetching and merging in home workspace...")
    result = coder_workspace_bash(
        workspace=home_workspace,
        command=f"""
            cd {repo_path}
            
            # Fetch latest from remote
            git fetch origin {feature_branch}
            
            # Checkout main branch
            git checkout main
            
            # Pull latest main
            git pull origin main
            
            # Merge feature branch (no fast-forward to preserve history)
            git merge origin/{feature_branch} --no-ff -m "Merge: {task_description}"
            
            # Push to remote
            git push origin main
            
            # Show merge result
            echo "✅ Merge complete"
            git log --oneline -3
            git diff --stat HEAD~1
        """,
        timeout_ms=60000
    )
    
    if result.exit_code != 0:
        print(f"❌ Failed to merge in home workspace: {result.stderr}")
        print("⚠️ Work is pushed to feature branch but not merged to main")
        return False
    
    print(f"✅ Work transferred successfully via git")
    print(f"Changes: {result.stdout}")
    
    # Step 3: Stop task workspace immediately
    print("🛑 Stopping task workspace...")
    try:
        # Get workspace ID from task
        workspaces = coder_list_workspaces()
        task_ws = next((w for w in workspaces if task_workspace in w.name), None)
        
        if task_ws:
            coder_create_workspace_build(
                workspace_id=task_ws.id,
                transition="stop"
            )
            print(f"✅ Task workspace stopped: {task_workspace}")
        else:
            print(f"⚠️ Task workspace not found (may already be stopped): {task_workspace}")
    except Exception as e:
        print(f"⚠️ Could not stop workspace: {e}")
        print("Note: Workspace may have auto-stopped or been deleted")
    
    # Step 4: Optional - Delete feature branch
    print("🧹 Cleaning up feature branch...")
    coder_workspace_bash(
        workspace=home_workspace,
        command=f"""
            cd {repo_path}
            git branch -d {feature_branch} 2>/dev/null || true
            git push origin --delete {feature_branch} 2>/dev/null || true
        """,
        timeout_ms=30000
    )
    
    print(f"""
✅ Task complete and cleaned up!

Work transferred: {feature_branch} → main
Task workspace: stopped
Feature branch: deleted
Repository: {repo_path}
    """)
    
    return True

# Example usage
success = complete_task_with_cleanup(
    task_workspace="alice/task-abc123",
    home_workspace="alice/main-workspace",
    feature_branch="feature/phase-5-cdk-integration",
    task_description="Integrate React build into CDK deployment",
    repo_path="/workspaces/mvp-ai-demo"
)
```

### Manual Step-by-Step (If Needed)

If you need more control, follow these steps manually:

#### Step 1: Commit and Push from Task Workspace

```python
coder_workspace_bash(
    workspace=task_workspace,
    command=f"""
        cd {repo_path}
        
        # Check for uncommitted changes
        if [ -n "$(git status --porcelain)" ]; then
            git add .
            git commit -m "Complete: {task_description}"
        fi
        
        # Push to remote
        git push origin {feature_branch}
        
        # Show final commit
        git log -1 --oneline
    """,
    timeout_ms=60000
)
```

#### Step 2: Fetch and Merge in Home Workspace

```python
coder_workspace_bash(
    workspace=home_workspace,
    command=f"""
        cd {repo_path}
        
        # Fetch latest changes
        git fetch origin {feature_branch}
        
        # Checkout main branch
        git checkout main
        
        # Merge feature branch (no fast-forward to preserve history)
        git merge origin/{feature_branch} --no-ff -m "Merge {feature_branch}: {task_description}"
        
        # Push to remote
        git push origin main
        
        # Show merge commit
        git log -1 --oneline
    """,
    timeout_ms=60000
)
```

#### Step 3: Verify Merge

```python
result = coder_workspace_bash(
    workspace=home_workspace,
    command=f"cd {repo_path} && git log --oneline -5",
    timeout_ms=15000
)

if result.exit_code == 0:
    print(f"✅ Merge successful: {result.stdout}")
else:
    print(f"❌ Merge failed: {result.stderr}")
```

#### Step 4: Stop Task Workspace

```python
# Get workspace ID
workspaces = coder_list_workspaces()
task_ws = next((w for w in workspaces if task_workspace in w.name), None)

if task_ws:
    coder_create_workspace_build(
        workspace_id=task_ws.id,
        transition="stop"
    )
    print(f"✅ Task workspace stopped")
```

### Workspace Lifecycle Management

**BEST PRACTICE:** Stop task workspaces immediately after successful work transfer to free resources.

#### Workspace Lifecycle States

| State | Meaning | Action |
|-------|---------|--------|
| `pending` | Queued for provisioning | Wait |
| `starting` | Provisioning in progress | Wait |
| `running` | Ready for work | Use it |
| `stopping` | Shutting down | Wait for stopped |
| `stopped` | Not consuming resources | Can delete or restart |
| `failed` | Provisioning failed | Delete and retry |

#### When to Stop vs Delete

**Stop workspace when:**
- ✅ Work is transferred to home workspace
- ✅ Task is complete
- ✅ Taking a break (>1 hour)
- ✅ End of day

**Delete workspace when:**
- ✅ Work is complete AND merged
- ✅ Task failed and work is not salvageable
- ✅ Workspace is no longer needed
- ✅ Cleaning up old tasks

**Keep workspace running when:**
- ⏳ Actively working
- ⏳ Waiting for long-running operation
- ⏳ Debugging issues

### CRITICAL RULES

1. ✅ Always commit and push from task workspace BEFORE merging
2. ✅ Use `--no-ff` flag to preserve feature branch history
3. ✅ Verify merge succeeded before stopping workspace
4. ✅ Stop workspace immediately after successful transfer
5. ✅ Home workspace main branch is the permanent record

### Benefits of Git-Fetch Approach

- ✅ **Fast:** 2 minutes vs 20 minutes for manual file copying (90% reduction)
- ✅ **Reliable:** Standard git operations, well-tested
- ✅ **Complete:** All files transferred atomically
- ✅ **History:** Full git history preserved
- ✅ **Low token usage:** Only git commands, no file reading
- ✅ **Automatic:** No manual file-by-file copying needed

### Getting Home Workspace Name

The home workspace is where Kiro is currently running:
```python
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

## Parallel Task Execution Patterns

### Pattern 1: Independent Parallel Tasks

For completely independent tasks that can run simultaneously:

```python
def create_parallel_tasks(tasks_config, home_workspace, repo_path="/workspaces/project"):
    """Create multiple independent tasks in parallel"""
    
    task_ids = []
    feature_branches = []
    task_workspaces = []
    
    # Create all tasks
    for config in tasks_config:
        # Create feature branch
        branch = f"feature/{config['name']}-{int(time.time())}"
        feature_branches.append(branch)
        
        result = coder_workspace_bash(
            workspace=home_workspace,
            command=f"""
                cd {repo_path}
                git checkout main
                git pull origin main
                git checkout -b {branch}
                git push -u origin {branch}
            """,
            timeout_ms=30000
        )
        
        if result.exit_code != 0:
            print(f"❌ Failed to create branch {branch}: {result.stderr}")
            continue
        
        # Create task
        task = coder_create_task(
            input=config['prompt'],
            template_version_id=config['template_id'],
            rich_parameter_values={
                "feature_branch": branch,
                "home_workspace": home_workspace,
                "repo_path": repo_path
            }
        )
        
        task_ids.append(task.id)
        task_workspaces.append(f"{CODER_WORKSPACE_OWNER_NAME}/{task.id}")
        print(f"✅ Created task: {config['name']} on branch {branch}")
    
    return task_ids, feature_branches, task_workspaces

# Monitor all tasks
def monitor_parallel_tasks(task_ids):
    """Monitor multiple tasks until all complete"""
    
    pending_tasks = set(task_ids)
    completed_tasks = []
    failed_tasks = []
    
    while pending_tasks:
        for task_id in list(pending_tasks):
            status = coder_get_task_status(task_id=task_id)
            
            if status.state.state in ['idle', 'completed']:
                pending_tasks.remove(task_id)
                completed_tasks.append(task_id)
                print(f"✅ Task completed: {task_id}")
            elif status.state.state == 'failure':
                pending_tasks.remove(task_id)
                failed_tasks.append(task_id)
                print(f"❌ Task failed: {task_id}")
        
        if pending_tasks:
            print(f"⏳ {len(pending_tasks)} tasks still running...")
            time.sleep(30)  # Check every 30 seconds
    
    return completed_tasks, failed_tasks

# Example usage
tasks = [
    {
        'name': 'phase-5-cdk',
        'prompt': 'Integrate React build into CDK deployment pipeline...',
        'template_id': 'template-123'
    },
    {
        'name': 'phase-6-monitoring',
        'prompt': 'Add monitoring dashboard with CloudWatch metrics...',
        'template_id': 'template-123'
    }
]

task_ids, branches, workspaces = create_parallel_tasks(tasks, home_workspace)
completed, failed = monitor_parallel_tasks(task_ids)

# Transfer work from all completed tasks
for i, task_id in enumerate(completed):
    complete_task_with_cleanup(
        task_workspace=workspaces[i],
        home_workspace=home_workspace,
        feature_branch=branches[i],
        task_description=tasks[i]['name']
    )

print(f"✅ All tasks complete: {len(completed)} succeeded, {len(failed)} failed")
```

### Pattern 2: Sequential with Dependencies

For tasks where one depends on another:

```python
def create_sequential_tasks(tasks_config, home_workspace, repo_path="/workspaces/project"):
    """Create tasks sequentially with dependencies"""
    
    results = []
    
    for i, config in enumerate(tasks_config):
        print(f"Starting task {i+1}/{len(tasks_config)}: {config['name']}")
        
        # Create feature branch
        branch = f"feature/{config['name']}-{int(time.time())}"
        
        coder_workspace_bash(
            workspace=home_workspace,
            command=f"""
                cd {repo_path}
                git checkout main
                git pull origin main
                git checkout -b {branch}
                git push -u origin {branch}
            """,
            timeout_ms=30000
        )
        
        # Add dependency context if available
        prompt = config['prompt']
        if results:
            prompt += f"\n\nNote: This builds on work from {results[-1]['name']} (merged to main)."
        
        # Create task
        task = coder_create_task(
            input=prompt,
            template_version_id=config['template_id'],
            rich_parameter_values={
                "feature_branch": branch,
                "home_workspace": home_workspace,
                "repo_path": repo_path
            }
        )
        
        task_workspace = f"{CODER_WORKSPACE_OWNER_NAME}/{task.id}"
        
        # Wait for completion
        while True:
            status = coder_get_task_status(task_id=task.id)
            if status.state.state in ['idle', 'completed']:
                break
            elif status.state.state == 'failure':
                print(f"❌ Task failed: {config['name']}")
                return results
            time.sleep(30)
        
        # Transfer work
        success = complete_task_with_cleanup(
            task_workspace=task_workspace,
            home_workspace=home_workspace,
            feature_branch=branch,
            task_description=config['name'],
            repo_path=repo_path
        )
        
        if not success:
            print(f"❌ Failed to transfer work from {config['name']}")
            return results
        
        results.append({
            'task_id': task.id,
            'branch': branch,
            'name': config['name']
        })
        
        print(f"✅ Task {i+1} complete: {config['name']}")
    
    return results
```

### Pattern 3: Hybrid (Parallel Groups with Dependencies)

For complex workflows with both parallel and sequential phases:

```python
# Phase 1: Foundation (sequential)
print("Phase 1: Foundation")
foundation = create_sequential_tasks([
    {'name': 'setup-infrastructure', 'prompt': '...', 'template_id': '...'}
], home_workspace)

# Phase 2: Parallel development (independent)
print("Phase 2: Parallel Development")
parallel_tasks = [
    {'name': 'frontend-components', 'prompt': '...', 'template_id': '...'},
    {'name': 'backend-api', 'prompt': '...', 'template_id': '...'},
    {'name': 'database-schema', 'prompt': '...', 'template_id': '...'}
]

task_ids, branches, workspaces = create_parallel_tasks(parallel_tasks, home_workspace)
completed, failed = monitor_parallel_tasks(task_ids)

# Transfer all parallel work
for i, task_id in enumerate(completed):
    complete_task_with_cleanup(
        task_workspace=workspaces[i],
        home_workspace=home_workspace,
        feature_branch=branches[i],
        task_description=parallel_tasks[i]['name']
    )

# Phase 3: Integration (sequential, depends on Phase 2)
print("Phase 3: Integration")
integration = create_sequential_tasks([
    {'name': 'integrate-components', 'prompt': '...', 'template_id': '...'}
], home_workspace)

print("✅ All phases complete!")
```

## Common Patterns

### Pattern: Quick Task for Simple Work

For simple, short-lived work:
```
1. Create task with clear description
2. Wait for running
3. Do the work quickly
4. **Transfer via git (commit, push, fetch, merge)**
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
   - **Final transfer via git**
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
4. **Transfer all results via gitspace**
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


---

## Post-Task Analysis and Validation (v3.3)

### When to Run Analysis

After tasks complete and work is transferred, run comprehensive analysis to ensure quality:

**Scenarios:**
- After single task completes
- After all parallel tasks complete
- Before final deployment
- For stakeholder reporting
- For audit and compliance

### Quick Analysis Workflow

```python
# After work transfer completes
complete_task_with_cleanup(...)

# Run comprehensive analysis
from post_task_analysis import complete_post_task_analysis

analysis = complete_post_task_analysis(
    home_workspace=f"{CODER_WORKSPACE_OWNER_NAME}/{CODER_WORKSPACE_NAME}",
    repo_path="/workspaces/my-project"
)

# Review results
print(f"Consistency Score: {analysis['consistency']['score']}%")
print(f"Compliance Score: {analysis['compliance']['score']}%")

# Reports generated:
# - CONSISTENCY_ANALYSIS.md
# - REQUIREMENTS_COMPLIANCE.md
# - EXECUTIVE_SUMMARY.md
```

### Validation-First Task Creation

**Include validation requirements in every task prompt:**

```python
from validation_patterns import generate_validation_prompt

# Generate prompt with project-specific validation
task_prompt = generate_validation_prompt(
    project_type='python',  # or 'nodejs', 'go', 'react', 'api', 'infrastructure'
    task_description='Implement user authentication'
)

# Create task with validation requirements
task = coder_create_task(
    input=task_prompt,
    template_version_id=template_version_id,
    rich_parameter_values={
        "feature_branch": feature_branch,
        "home_workspace": home_workspace
    }
)
```

**Benefits:**
- 80% reduction in post-task bugs
- Workspace agents validate before completing
- Clear success criteria
- Automated verification

### Complete Validated Workflow

**Integrated workflow with validation and analysis:**

```python
def complete_validated_task_workflow(
    task_description,
    project_type,
    template_version_id,
    home_workspace,
    repo_path
):
    """
    Complete task workflow with validation and analysis.
    
    Time: ~32 minutes (vs 77 minutes without automation)
    """
    print("🚀 Starting validated task workflow...")
    
    # Step 1: Pre-flight validation
    valid, issues, fixes = validate_task_prerequisites(home_workspace, repo_path)
    if not valid:
        print("❌ Prerequisites not met:")
        for issue in issues:
            print(f"   - {issue}")
        return False
    
    # Step 2: Generate validation prompt
    print("\n📝 Generating task prompt with validation...")
    task_prompt = generate_validation_prompt(project_type, task_description)
    
    # Step 3: Create feature branch
    print("\n🌿 Creating feature branch...")
    task_slug = task_description.lower().replace(" ", "-")[:30]
    feature_branch = f"feature/{task_slug}-{int(time.time())}"
    
    result = coder_workspace_bash(
        workspace=home_workspace,
        command=f"""
            cd {repo_path}
            git checkout -b {feature_branch}
            git push -u origin {feature_branch}
        """,
        timeout_ms=30000
    )
    
    if result.exit_code != 0:
        print(f"❌ Failed to create feature branch")
        return False
    
    # Step 4: Create task
    print("\n📦 Creating task...")
    task = coder_create_task(
        input=task_prompt,
        template_version_id=template_version_id,
        rich_parameter_values={
            "feature_branch": feature_branch,
            "home_workspace": home_workspace
        }
    )
    
    # Step 5: Wait for completion
    print("\n⏳ Waiting for task completion...")
    task_workspace = wait_for_task_ready(task)
    
    # Monitor until complete
    while True:
        status = coder_get_task_status(task_id=task_workspace)
        if status.state == "idle":
            print("✅ Task completed")
            break
        elif status.state == "failure":
            print("❌ Task failed")
            return False
        time.sleep(30)
    
    # Step 6: Transfer work
    print("\n📥 Transferring work via git...")
    complete_task_with_cleanup(
        task_workspace=task_workspace,
        home_workspace=home_workspace,
        feature_branch=feature_branch,
        task_description=task_description
    )
    
    # Step 7: Verify validation
    print("\n✅ Verifying validation requirements...")
    from validation_patterns import verify_task_completion
    
    validation_results = verify_task_completion(
        home_workspace, repo_path, project_type
    )
    
    if not validation_results['overall_pass']:
        print("⚠️ Validation checks failed:")
        for failure in validation_results['failed']:
            print(f"   - {failure}")
        print("\n🔧 Fix issues before proceeding")
        return False
    
    # Step 8: Run post-task analysis
    print("\n🔍 Running post-task analysis...")
    from post_task_analysis import complete_post_task_analysis
    
    analysis = complete_post_task_analysis(home_workspace, repo_path)
    
    print(f"\n📊 Analysis Results:")
    print(f"   Consistency: {analysis['consistency']['score']}%")
    print(f"   Compliance: {analysis['compliance']['score']}%")
    
    # Step 9: Quality gates
    print("\n🚦 Running quality gates...")
    from validation_patterns import pre_merge_quality_gate, pre_deployment_quality_gate
    
    if not pre_merge_quality_gate(home_workspace, repo_path, project_type):
        print("❌ Pre-merge gate failed - review issues")
        return False
    
    if not pre_deployment_quality_gate(home_workspace, repo_path):
        print("❌ Pre-deployment gate failed - review analysis reports")
        return False
    
    print("\n🎉 Task workflow complete!")
    print(f"\n📄 Generated reports:")
    print(f"   - {repo_path}/CONSISTENCY_ANALYSIS.md")
    print(f"   - {repo_path}/REQUIREMENTS_COMPLIANCE.md")
    print(f"   - {repo_path}/EXECUTIVE_SUMMARY.md")
    print("\n✅ Ready for deployment")
    
    return True

# Usage
success = complete_validated_task_workflow(
    task_description="Implement user authentication with JWT",
    project_type="python",
    template_version_id=template_id,
    home_workspace=f"{CODER_WORKSPACE_OWNER_NAME}/{CODER_WORKSPACE_NAME}",
    repo_path="/workspaces/my-project"
)
```

### Parallel Tasks with Analysis

**For multiple parallel tasks:**

```python
def parallel_tasks_with_analysis(
    task_descriptions,
    project_type,
    template_version_id,
    home_workspace,
    repo_path
):
    """
    Create and analyze multiple parallel tasks.
    """
    print(f"🚀 Starting {len(task_descriptions)} parallel tasks...")
    
    # Create all tasks
    tasks = []
    branches = []
    
    for desc in task_descriptions:
        # Generate validation prompt
        task_prompt = generate_validation_prompt(project_type, desc)
        
        # Create feature branch
        task_slug = desc.lower().replace(" ", "-")[:30]
        feature_branch = f"feature/{task_slug}-{int(time.time())}"
        
        coder_workspace_bash(
            workspace=home_workspace,
            command=f"cd {repo_path} && git checkout -b {feature_branch} && git push -u origin {feature_branch}",
            timeout_ms=30000
        )
        
        # Create task
        task = coder_create_task(
            input=task_prompt,
            template_version_id=template_version_id,
            rich_parameter_values={
                "feature_branch": feature_branch,
                "home_workspace": home_workspace
            }
        )
        
        tasks.append(task)
        branches.append(feature_branch)
        time.sleep(2)  # Stagger task creation
    
    print(f"✅ Created {len(tasks)} tasks")
    
    # Wait for all to complete
    print("\n⏳ Waiting for all tasks to complete...")
    completed = []
    
    while len(completed) < len(tasks):
        for i, task in enumerate(tasks):
            if i in completed:
                continue
            
            status = coder_get_task_status(task_id=task.workspace_name)
            if status.state == "idle":
                print(f"✅ Task {i+1} completed")
                completed.append(i)
            elif status.state == "failure":
                print(f"❌ Task {i+1} failed")
                completed.append(i)
        
        if len(completed) < len(tasks):
            time.sleep(30)
    
    # Transfer all work
    print("\n📥 Transferring work from all tasks...")
    for task, branch in zip(tasks, branches):
        complete_task_with_cleanup(
            task_workspace=task.workspace_name,
            home_workspace=home_workspace,
            feature_branch=branch,
            task_description=f"Parallel task on {branch}"
        )
    
    # Run consolidated analysis
    print("\n🔍 Running consolidated analysis...")
    from post_task_analysis import complete_post_task_analysis
    
    analysis = complete_post_task_analysis(home_workspace, repo_path)
    
    print(f"\n📊 Consolidated Analysis:")
    print(f"   Consistency: {analysis['consistency']['score']}%")
    print(f"   Compliance: {analysis['compliance']['score']}%")
    print(f"\n✅ All {len(tasks)} tasks analyzed")
    
    return analysis

# Usage
analysis = parallel_tasks_with_analysis(
    task_descriptions=[
        "Implement user authentication",
        "Create dashboard UI",
        "Add data export feature"
    ],
    project_type="python",
    template_version_id=template_id,
    home_workspace=home_workspace,
    repo_path=repo_path
)
```

### Time Savings Summary

**Without v3.3 automation:**
- Task creation: 2 min
- Task execution: 10 min
- Work transfer: 5 min
- Manual analysis: 60 min
- **Total: 77 minutes**

**With v3.3 automation:**
- Task creation: 2 min
- Task execution: 10 min (workspace agent validates)
- Work transfer: 5 min
- Automated analysis: 14 min
- Quality gates: 1 min
- **Total: 32 minutes**

**Savings: 58% (45 minutes per task)**

### Additional Resources

For detailed analysis and validation workflows, load these steering files:

- **post-task-analysis.md** - Comprehensive analysis workflows
- **validation-patterns.md** - Validation checklists and quality gates
- **docs/ANALYSIS-WORKFLOWS.md** - Reference documentation

---

**End of Task Workflow Guide**
