# Migration Guide: Adopting Work Transfer Pattern

This guide helps you migrate existing workflows to the new work transfer pattern introduced in v2.2.0.

---

## What Changed

### Before (v2.1.0 and earlier)

```
1. Create task
2. Do work in task workspace
3. Stop task workspace
❌ Work remains in task workspace (lost when deleted)
```

### After (v2.2.0+)

```
1. Create task
2. Do work in task workspace
3. **Transfer work to home workspace** ← NEW STEP
4. Stop task workspace
✅ Work preserved in home workspace
```

---

## Why This Change?

**Problem with old approach:**
- Work remained in ephemeral task workspaces
- Deleting task workspace lost all work
- No clear source of truth for project state
- Difficult to track project history

**Benefits of new approach:**
- Home workspace is permanent source of truth
- Task workspaces are clearly ephemeral
- No work lost when task workspaces are deleted
- Clear project history in home workspace
- Supports incremental development with checkpoints

---

## Migration Steps

### Step 1: Understand the Concepts

**Home Workspace:**
- The Coder workspace where Kiro is running
- Permanent storage
- Source of truth for all project work
- Name: `${CODER_WORKSPACE_OWNER_NAME}/${CODER_WORKSPACE_NAME}`

**Task Workspace:**
- Created by `coder_create_task`
- Ephemeral execution environment
- Work is performed here
- Stopped and deleted after work is transferred

### Step 2: Update Your Workflows

**Old workflow:**
```python
# Create task
task = coder_create_task(...)

# Wait for running
wait_for_running(task)

# Do work
coder_workspace_bash(workspace=task_workspace, command="...")
coder_workspace_write_file(workspace=task_workspace, ...)

# Stop workspace
coder_create_workspace_build(workspace_id=task.workspace_id, transition="stop")
```

**New workflow:**
```python
# Create task
task = coder_create_task(...)

# Wait for running
wait_for_running(task)

# Do work
coder_workspace_bash(workspace=task_workspace, command="...")
coder_workspace_write_file(workspace=task_workspace, ...)

# ===== NEW: TRANSFER WORK =====
home_workspace = f"{os.getenv('CODER_WORKSPACE_OWNER_NAME')}/{os.getenv('CODER_WORKSPACE_NAME')}"

# Identify changed files
result = coder_workspace_bash(
    workspace=task_workspace,
    command="cd /home/coder/project && git diff --name-only HEAD",
    timeout_ms=15000
)

# Transfer each file
for file_path in result.stdout.split('\n'):
    if file_path.strip():
        full_path = f"/home/coder/project/{file_path}"
        
        # Read from task workspace
        content = coder_workspace_read_file(
            workspace=task_workspace,
            path=full_path
        )
        
        # Write to home workspace
        coder_workspace_write_file(
            workspace=home_workspace,
            path=full_path,
            content=content
        )

# Commit in home workspace
coder_workspace_bash(
    workspace=home_workspace,
    command="cd /home/coder/project && git add . && git commit -m 'Task: [description]'",
    timeout_ms=30000
)
# ===== END NEW SECTION =====

# Stop workspace (now safe - work is transferred)
coder_create_workspace_build(workspace_id=task.workspace_id, transition="stop")
```

### Step 3: Add Checkpoint Support (Optional but Recommended)

For long-running tasks, add checkpoints:

```python
def do_long_task():
    # Phase 1
    do_phase_1_work()
    transfer_to_home_workspace("Phase 1 complete")  # Checkpoint
    
    # Phase 2
    do_phase_2_work()
    transfer_to_home_workspace("Phase 2 complete")  # Checkpoint
    
    # Phase 3
    do_phase_3_work()
    transfer_to_home_workspace("Phase 3 complete")  # Final transfer
    
    # Now safe to stop
    stop_task_workspace()
```

### Step 4: Add Failure Recovery

Handle failures gracefully by salvaging work:

```python
try:
    # Do work
    do_work_in_task_workspace()
    
    # Transfer on success
    transfer_to_home_workspace()
    
except Exception as e:
    # Try to salvage partial work
    try:
        salvage_partial_work()
        transfer_what_we_can()
        log_warning(f"Partial work salvaged: {e}")
    except:
        log_error(f"Could not salvage work: {e}")
finally:
    # Always stop workspace
    stop_task_workspace()
```

---

## Common Migration Scenarios

### Scenario 1: Simple Task (Quick Fix)

**Before:**
```python
create_task()
fix_typo()
stop_workspace()
```

**After:**
```python
create_task()
fix_typo()
transfer_changed_files()  # NEW
stop_workspace()
```

### Scenario 2: Feature Development

**Before:**
```python
create_task()
implement_feature()
add_tests()
stop_workspace()
```

**After:**
```python
create_task()
implement_feature()
transfer_to_home()  # Checkpoint
add_tests()
transfer_to_home()  # Final
stop_workspace()
```

### Scenario 3: Multi-Day Development

**Before:**
```python
# Day 1
create_task()
start_implementation()
# Leave workspace running overnight

# Day 2
continue_implementation()
stop_workspace()
```

**After:**
```python
# Day 1
create_task()
start_implementation()
transfer_to_home()  # Checkpoint before break
stop_workspace()  # Save resources

# Day 2
create_new_task()  # Or restart existing
continue_implementation()
transfer_to_home()  # Final
stop_workspace()
```

---

## Helper Functions

### Basic Transfer Function

```python
def transfer_work_to_home(task_workspace, project_path="/home/coder/project"):
    """Transfer all changed files from task workspace to home workspace"""
    
    # Get home workspace name
    home_workspace = f"{os.getenv('CODER_WORKSPACE_OWNER_NAME')}/{os.getenv('CODER_WORKSPACE_NAME')}"
    
    # Identify changed files
    result = coder_workspace_bash(
        workspace=task_workspace,
        command=f"cd {project_path} && git diff --name-only HEAD",
        timeout_ms=15000
    )
    
    changed_files = [f for f in result.stdout.split('\n') if f.strip()]
    
    # Transfer each file
    transferred = 0
    for file_path in changed_files:
        full_path = f"{project_path}/{file_path}"
        
        try:
            # Read from task workspace
            content = coder_workspace_read_file(
                workspace=task_workspace,
                path=full_path
            )
            
            # Write to home workspace
            coder_workspace_write_file(
                workspace=home_workspace,
                path=full_path,
                content=content
            )
            
            transferred += 1
        except Exception as e:
            print(f"Failed to transfer {file_path}: {e}")
    
    # Commit in home workspace
    if transferred > 0:
        coder_workspace_bash(
            workspace=home_workspace,
            command=f"cd {project_path} && git add . && git commit -m 'Transferred {transferred} files from task'",
            timeout_ms=30000
        )
    
    return transferred
```

### Checkpoint Transfer Function

```python
def checkpoint_transfer(task_workspace, checkpoint_name, project_path="/home/coder/project"):
    """Transfer work at a checkpoint"""
    
    transferred = transfer_work_to_home(task_workspace, project_path)
    
    if transferred > 0:
        home_workspace = f"{os.getenv('CODER_WORKSPACE_OWNER_NAME')}/{os.getenv('CODER_WORKSPACE_NAME')}"
        
        # Update commit message with checkpoint name
        coder_workspace_bash(
            workspace=home_workspace,
            command=f"cd {project_path} && git commit --amend -m 'Checkpoint: {checkpoint_name}'",
            timeout_ms=15000
        )
        
        print(f"✅ Checkpoint '{checkpoint_name}': {transferred} files transferred")
    
    return transferred
```

---

## Testing Your Migration

### Test 1: Simple Transfer

```python
# Create a test task
task = coder_create_task(input="Test transfer", template_version_id="...")

# Wait for running
wait_for_running(task)

# Create a test file
coder_workspace_write_file(
    workspace=task_workspace,
    path="/home/coder/project/test.txt",
    content=base64.b64encode(b"Hello from task workspace")
)

# Transfer to home
transfer_work_to_home(task_workspace)

# Verify in home workspace
content = coder_workspace_read_file(
    workspace=home_workspace,
    path="/home/coder/project/test.txt"
)

assert base64.b64decode(content) == b"Hello from task workspace"
print("✅ Transfer test passed")

# Stop task workspace
stop_workspace(task)
```

### Test 2: Checkpoint Transfer

```python
# Create task
task = coder_create_task(...)

# Phase 1
do_phase_1_work()
checkpoint_transfer(task_workspace, "Phase 1 complete")

# Phase 2
do_phase_2_work()
checkpoint_transfer(task_workspace, "Phase 2 complete")

# Verify both checkpoints in home workspace git log
result = coder_workspace_bash(
    workspace=home_workspace,
    command="cd /home/coder/project && git log --oneline -2",
    timeout_ms=15000
)

assert "Phase 1 complete" in result.stdout
assert "Phase 2 complete" in result.stdout
print("✅ Checkpoint test passed")
```

### Test 3: Failure Recovery

```python
try:
    # Create task
    task = coder_create_task(...)
    
    # Do some work
    do_partial_work()
    
    # Simulate failure
    raise Exception("Simulated failure")
    
except Exception as e:
    # Salvage work
    transferred = transfer_work_to_home(task_workspace)
    print(f"✅ Salvaged {transferred} files despite failure")
    
finally:
    # Stop workspace
    stop_workspace(task)
```

---

## Troubleshooting

### Problem: "Home workspace not found"

**Solution:**
```python
# Verify environment variables are set
print(f"Owner: {os.getenv('CODER_WORKSPACE_OWNER_NAME')}")
print(f"Workspace: {os.getenv('CODER_WORKSPACE_NAME')}")

# If not set, you're not running in a Coder workspace
# The power requires running inside a Coder workspace
```

### Problem: "No changed files to transfer"

**Solution:**
```python
# Check if git is initialized
result = coder_workspace_bash(
    workspace=task_workspace,
    command="cd /home/coder/project && git status",
    timeout_ms=15000
)

# If not initialized, use find instead of git diff
result = coder_workspace_bash(
    workspace=task_workspace,
    command="find /home/coder/project -type f -mmin -60",
    timeout_ms=15000
)
```

### Problem: "Transfer fails for large files"

**Solution:**
Use tar-based transfer for large numbers of files:
```python
# Create tar in task workspace
coder_workspace_bash(
    workspace=task_workspace,
    command="cd /home/coder/project && tar czf /tmp/transfer.tar.gz .",
    timeout_ms=60000
)

# Transfer tar file
tar_content = coder_workspace_read_file(
    workspace=task_workspace,
    path="/tmp/transfer.tar.gz"
)

coder_workspace_write_file(
    workspace=home_workspace,
    path="/tmp/transfer.tar.gz",
    content=tar_content
)

# Extract in home workspace
coder_workspace_bash(
    workspace=home_workspace,
    command="cd /home/coder/project && tar xzf /tmp/transfer.tar.gz",
    timeout_ms=60000
)
```

---

## Rollback Plan

If you need to temporarily revert to old behavior:

1. Comment out transfer code
2. Keep task workspaces running longer
3. Manually copy files when needed

**Not recommended:** This loses the benefits of the new pattern and risks data loss.

---

## Getting Help

- Read `WORK-TRANSFER-PATTERN.md` for complete implementation details
- Review `steering/task-workflow.md` for integration examples
- Check `POWER.md` best practices section
- Test with simple tasks before migrating complex workflows

---

## Summary

**Key Changes:**
1. Add transfer step before stopping task workspace
2. Use home workspace as source of truth
3. Add checkpoints for long tasks
4. Implement failure recovery

**Benefits:**
- No work lost
- Clear data flow
- Better project history
- Supports incremental development

**Migration Effort:**
- Simple tasks: 5-10 minutes
- Complex workflows: 30-60 minutes
- Testing: 15-30 minutes

The work transfer pattern is a fundamental improvement that makes task workspaces truly ephemeral while ensuring all work is safely preserved in your home workspace.
