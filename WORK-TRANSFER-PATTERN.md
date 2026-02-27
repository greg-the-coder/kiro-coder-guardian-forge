# Work Transfer Pattern: Task to Home Workspace

This document describes the fundamental pattern for transferring work from ephemeral Coder Task workspaces back to the originating Kiro workspace (home workspace).

---

## Core Concept

**Home Workspace:** The Coder workspace where Kiro is running - this is the permanent record and source of truth for all project work.

**Task Workspace:** Ephemeral workspace created for specific work - temporary execution environment that gets cleaned up after work is transferred back.

**Pattern:** Work is performed in task workspaces, then transferred back to home workspace at completion or major checkpoints.

---

## Architecture

```
┌─────────────────────────────────────┐
│   Home Workspace (Kiro Running)    │
│   - Source of truth                 │
│   - Permanent storage               │
│   - Project repository              │
└──────────────┬──────────────────────┘
               │
               │ 1. Create task
               ↓
┌─────────────────────────────────────┐
│   Task Workspace (Ephemeral)       │
│   - Temporary execution             │
│   - Isolated environment            │
│   - Work performed here             │
└──────────────┬──────────────────────┘
               │
               │ 2. Transfer work back
               ↓
┌─────────────────────────────────────┐
│   Home Workspace (Updated)         │
│   - Work integrated                 │
│   - Files updated                   │
│   - Ready for next task             │
└─────────────────────────────────────┘
```

---

## Transfer Points

### 1. Task Completion (Required)
Transfer all work when task is complete before stopping workspace.

### 2. Major Checkpoints (Recommended)
Transfer work at significant milestones:
- Feature implementation complete
- Tests passing
- Phase of multi-phase work complete
- Before long break or end of day

### 3. Failure Recovery (Critical)
Transfer any salvageable work before stopping failed task workspace.

---

## Transfer Workflow

### Step 1: Identify Changed Files

**In task workspace, identify what changed:**

```bash
# Option A: Git-based (if using git)
coder_workspace_bash(
  workspace="task-workspace",
  command="cd /home/coder/project && git status --porcelain",
  timeout_ms=15000
)

# Option B: Find recently modified files
coder_workspace_bash(
  workspace="task-workspace",
  command="find /home/coder/project -type f -mmin -60",
  timeout_ms=15000
)

# Option C: Compare with known file list
coder_workspace_bash(
  workspace="task-workspace",
  command="cd /home/coder/project && find . -type f -newer /tmp/start_marker",
  timeout_ms=15000
)
```

### Step 2: Read Changed Files from Task Workspace

For each changed file:

```bash
# Read file content
content = coder_workspace_read_file(
  workspace="task-workspace",
  path="/home/coder/project/src/feature.go"
)
```

### Step 3: Write Files to Home Workspace

For each file read from task workspace:

```bash
# Write to home workspace
coder_workspace_write_file(
  workspace="home-workspace",  # Your Kiro workspace
  path="/home/coder/project/src/feature.go",
  content=base64_encode(content)
)
```

### Step 4: Verify Transfer

```bash
# Verify file exists in home workspace
coder_workspace_ls(
  workspace="home-workspace",
  path="/home/coder/project/src"
)

# Optionally: Read back and compare checksums
```

### Step 5: Commit to Git (Optional but Recommended)

```bash
# In home workspace, commit the transferred work
coder_workspace_bash(
  workspace="home-workspace",
  command="cd /home/coder/project && git add . && git commit -m 'Task: [description]'",
  timeout_ms=30000
)
```

### Step 6: Stop Task Workspace

```bash
# Now safe to stop - work is preserved in home workspace
coder_create_workspace_build(
  workspace_id="task-workspace-id",
  transition="stop"
)
```

---

## Implementation Patterns

**IMPORTANT: Token Efficiency Considerations**

The patterns below are ordered by token efficiency. For production use, prefer Pattern A (Git Patch) or Pattern B (Bash Direct) to minimize agent context usage and token consumption.

### Pattern A: Git Patch Transfer (MOST RECOMMENDED - Minimal Tokens)

**Use git patches to transfer only diffs, not entire file contents. This is the most token-efficient method.**

```python
# Pseudo-code for git patch transfer
def transfer_via_git_patch(task_ws, home_ws, project_path, task_description):
    """
    Most efficient method for git projects:
    - Only transfers diffs (changes), not full files
    - Minimal token usage (patch files are typically 1-10KB)
    - Preserves git history
    - Works with files of any size
    """
    
    # 1. Commit changes in task workspace
    coder_workspace_bash(
        workspace=task_ws,
        command=f"""
            cd {project_path}
            git add .
            git commit -m "Task: {task_description}" || echo "Nothing to commit"
        """,
        timeout_ms=30000
    )
    
    # 2. Create patch file (contains only diffs, very small)
    coder_workspace_bash(
        workspace=task_ws,
        command=f"""
            cd {project_path}
            git format-patch -1 HEAD --stdout > /tmp/task.patch
        """,
        timeout_ms=30000
    )
    
    # 3. Transfer patch (small file, minimal tokens)
    patch_content = coder_workspace_read_file(
        workspace=task_ws,
        path="/tmp/task.patch"
    )
    
    coder_workspace_write_file(
        workspace=home_ws,
        path="/tmp/task.patch",
        content=patch_content
    )
    
    # 4. Apply patch in home workspace
    result = coder_workspace_bash(
        workspace=home_ws,
        command=f"""
            cd {project_path}
            git am /tmp/task.patch
            rm /tmp/task.patch
        """,
        timeout_ms=30000
    )
    
    if result.exit_code != 0:
        # Fallback: try git apply if git am fails
        coder_workspace_bash(
            workspace=home_ws,
            command=f"""
                cd {project_path}
                git apply /tmp/task.patch
                git add .
                git commit -m "Task: {task_description}"
                rm /tmp/task.patch
            """,
            timeout_ms=30000
        )
    
    return True
```

**Token Efficiency:**
- ✅ Patch file contains only diffs (lines changed), not entire files
- ✅ Typical patch is 1-10KB even for large changes
- ✅ Minimal agent context usage
- ✅ Works with files of any size
- ✅ Binary files handled efficiently

### Pattern B: Bash Direct Transfer (RECOMMENDED - Zero Tokens for File Content)

**Use bash commands to transfer files directly without reading content into agent context.**

```python
# Pseudo-code for bash-based direct transfer
def transfer_via_bash_direct(task_ws, home_ws, project_path):
    """
    Most efficient for non-git projects:
    - No file content in agent context
    - Handles large files efficiently
    - Works with binary files
    - Preserves permissions
    """
    
    # Option A: If workspaces share filesystem (common in Coder)
    coder_workspace_bash(
        workspace=task_ws,
        command=f"""
            # Get home workspace path
            HOME_WS_PATH="/home/coder/workspaces/{home_ws}/project"
            
            # Sync files using rsync
            rsync -av --delete {project_path}/ $HOME_WS_PATH/
        """,
        timeout_ms=120000
    )
    
    # Option B: Use tar with pipe (if direct access available)
    coder_workspace_bash(
        workspace=task_ws,
        command=f"""
            cd {project_path}
            tar czf - . | (cd /home/coder/workspaces/{home_ws}/project && tar xzf -)
        """,
        timeout_ms=120000
    )
```

**Token Efficiency:**
- ✅ Zero tokens used for file content
- ✅ Only bash command in context
- ✅ Handles any file size
- ✅ Fastest transfer method

**Note:** This requires workspaces to have shared filesystem access or be on the same node. Check your Coder deployment configuration.

### Pattern C: File List Transfer (For Small Changes)

Transfer only changed files by reading them individually. Use only when:
- Changes are small (< 5 files)
- Files are small (< 100KB each)
- Git is not available

```python
# Pseudo-code for selective file transfer
def transfer_changed_files(task_ws, home_ws, project_path):
    """
    Transfer individual files - use sparingly due to token usage
    """
    
    # 1. Get list of changed files
    result = coder_workspace_bash(
        workspace=task_ws,
        command=f"cd {project_path} && find . -type f -mmin -60 | head -10"
    )
    
    changed_files = [f for f in result.stdout.split('\n') if f.strip()]
    
    # IMPORTANT: Limit to prevent token overflow
    if len(changed_files) > 10:
        raise Exception("Too many files changed. Use git patch or bash direct transfer instead.")
    
    # 2. Transfer each file
    for file_path in changed_files:
        full_path = f"{project_path}/{file_path}"
        
        # Check file size first
        size_result = coder_workspace_bash(
            workspace=task_ws,
            command=f"stat -f%z {full_path} 2>/dev/null || stat -c%s {full_path}"
        )
        
        file_size = int(size_result.stdout.strip())
        
        if file_size > 100000:  # 100KB limit
            raise Exception(f"File {file_path} too large ({file_size} bytes). Use git patch or bash transfer.")
        
        # Read from task workspace
        content = coder_workspace_read_file(
            workspace=task_ws,
            path=full_path
        )
        
        # Write to home workspace
        coder_workspace_write_file(
            workspace=home_ws,
            path=full_path,
            content=content
        )
    
    return len(changed_files)
```

**Token Efficiency:**
- ⚠️ Moderate token usage (file content in context)
- ⚠️ Limited to small files and few changes
- ⚠️ Not suitable for large projects

### Pattern D: Full Directory Transfer (NOT RECOMMENDED - High Token Usage)

**Avoid this pattern unless absolutely necessary. It reads all files into agent context.**

```python
# Pseudo-code for full transfer - AVOID IF POSSIBLE
def transfer_full_directory(task_ws, home_ws, project_path):
    """
    WARNING: High token usage - only use for very small projects
    """
    
    # 1. List all files in task workspace
    files = coder_workspace_bash(
        workspace=task_ws,
        command=f"find {project_path} -type f | head -20"  # Limit to 20 files
    )
    
    file_list = [f for f in files.stdout.split('\n') if f.strip()]
    
    if len(file_list) > 20:
        raise Exception("Too many files. Use git patch or bash direct transfer instead.")
    
    # 2. For each file, read and transfer
    for file_path in file_list:
        content = coder_workspace_read_file(
            workspace=task_ws,
            path=file_path
        )
        
        coder_workspace_write_file(
            workspace=home_ws,
            path=file_path,
            content=content
        )
    
    return len(file_list)
```

**Token Efficiency:**
- ❌ High token usage (all file content in context)
- ❌ Not suitable for production use
- ❌ Risk of context window overflow

---

## Token Usage Comparison

| Pattern | Token Usage | Best For | Limitations |
|---------|-------------|----------|-------------|
| Git Patch | **Minimal** (1-10KB) | Git projects, any size | Requires git |
| Bash Direct | **Zero** (no file content) | Any project, any size | Requires shared filesystem |
| File List | Moderate (file content) | < 5 small files | File size/count limits |
| Full Directory | **High** (all content) | Tiny projects only | Not production-ready |

**Recommendation:** Always use Git Patch (Pattern A) for git projects, or Bash Direct (Pattern B) for non-git projects.

---

## Implementation Patterns (Legacy - For Reference)

The patterns below are kept for reference but should be avoided in production due to token inefficiency.

### Pattern A: Full Directory Transfer

Transfer entire project directory:

```python
# Pseudo-code for full transfer
def transfer_full_directory(task_ws, home_ws, project_path):
    # 1. List all files in task workspace
    files = coder_workspace_bash(
        workspace=task_ws,
        command=f"find {project_path} -type f"
    )
    
    # 2. For each file, read and transfer
    for file_path in files.split('\n'):
        if file_path.strip():
            # Read from task workspace
            content = coder_workspace_read_file(
                workspace=task_ws,
                path=file_path
            )
            
            # Write to home workspace
            coder_workspace_write_file(
                workspace=home_ws,
                path=file_path,
                content=base64_encode(content)
            )
    
    return len(files.split('\n'))
```

### Pattern B: Git-Based Transfer

Use git to identify and transfer only changed files:

```python
# Pseudo-code for git-based transfer
def transfer_git_changes(task_ws, home_ws, project_path):
    # 1. Get list of changed files
    result = coder_workspace_bash(
        workspace=task_ws,
        command=f"cd {project_path} && git diff --name-only HEAD"
    )
    
    changed_files = result.stdout.strip().split('\n')
    
    # 2. Transfer each changed file
    for file_path in changed_files:
        if file_path.strip():
            full_path = f"{project_path}/{file_path}"
            
            # Read from task workspace
            content = coder_workspace_read_file(
                workspace=task_ws,
                path=full_path
            )
            
            # Write to home workspace
            coder_workspace_write_file(
                workspace=home_ws,
                path=full_path,
                content=base64_encode(content)
            )
    
    return len(changed_files)
```

### Pattern C: Selective Transfer

Transfer only specific files or directories:

```python
# Pseudo-code for selective transfer
def transfer_selective(task_ws, home_ws, file_patterns):
    transferred = []
    
    for pattern in file_patterns:
        # Find matching files
        result = coder_workspace_bash(
            workspace=task_ws,
            command=f"find /home/coder/project -path '{pattern}' -type f"
        )
        
        files = result.stdout.strip().split('\n')
        
        for file_path in files:
            if file_path.strip():
                # Read and transfer
                content = coder_workspace_read_file(
                    workspace=task_ws,
                    path=file_path
                )
                
                coder_workspace_write_file(
                    workspace=home_ws,
                    path=file_path,
                    content=base64_encode(content)
                )
                
                transferred.append(file_path)
    
    return transferred
```

### Pattern D: Bash-Based Direct Transfer (RECOMMENDED - Most Efficient)

**For maximum efficiency and minimal token usage, use bash commands to transfer files directly between workspaces without reading content into agent context.**

This is the **preferred method** as it:
- ✅ Doesn't consume agent context with file contents
- ✅ Handles large files efficiently
- ✅ Transfers multiple files in one operation
- ✅ Works with binary files
- ✅ Preserves file permissions and metadata

```python
# Pseudo-code for bash-based direct transfer
def transfer_via_bash_direct(task_ws, home_ws, project_path):
    """
    Most efficient transfer method - uses bash to copy files directly
    without reading content into agent context
    """
    
    # Get the actual workspace paths from Coder
    # Task workspace is accessible at its workspace directory
    # Home workspace is the current workspace
    
    # Option A: Use rsync (if available) - BEST
    coder_workspace_bash(
        workspace=task_ws,
        command=f"""
            # Rsync from task workspace to home workspace via shared storage
            # This assumes workspaces can access shared storage or use Coder's file sync
            rsync -av --delete {project_path}/ /mnt/shared/{home_ws}/project/
        """,
        timeout_ms=120000
    )
    
    # Option B: Use tar with pipe (if workspaces share filesystem)
    coder_workspace_bash(
        workspace=task_ws,
        command=f"""
            cd {project_path}
            tar czf - . | (cd /home/coder/project && tar xzf -)
        """,
        timeout_ms=120000
    )
    
    # Option C: Use git push/pull (RECOMMENDED for git projects)
    # This is the most efficient for version-controlled projects
    
    # 1. In task workspace: commit and push to a temporary branch
    coder_workspace_bash(
        workspace=task_ws,
        command=f"""
            cd {project_path}
            git add .
            git commit -m "Task work complete" || true
            git push origin HEAD:refs/heads/task-transfer-$(date +%s)
        """,
        timeout_ms=60000
    )
    
    # 2. In home workspace: fetch and merge
    coder_workspace_bash(
        workspace=home_ws,
        command=f"""
            cd {project_path}
            git fetch origin
            git merge --no-ff origin/task-transfer-* -m "Merged task work"
            git push origin --delete task-transfer-* || true
        """,
        timeout_ms=60000
    )
```

### Pattern E: Tar-Based Transfer (For Non-Git Projects)

For projects not using git, use tar but transfer via bash commands:

```python
# Pseudo-code for tar-based transfer via bash
def transfer_via_tar_bash(task_ws, home_ws, project_path):
    """
    Transfer using tar, but execute via bash to avoid reading content
    into agent context
    """
    
    # Create tar and transfer in one operation
    coder_workspace_bash(
        workspace=task_ws,
        command=f"""
            cd {project_path}
            tar czf /tmp/transfer-$(date +%s).tar.gz .
            
            # Copy to home workspace via shared storage or Coder's file sync
            cp /tmp/transfer-*.tar.gz /mnt/shared/{home_ws}/
        """,
        timeout_ms=120000
    )
    
    # Extract in home workspace
    coder_workspace_bash(
        workspace=home_ws,
        command=f"""
            cd {project_path}
            tar xzf /mnt/shared/transfer-*.tar.gz
            rm /mnt/shared/transfer-*.tar.gz
        """,
        timeout_ms=120000
    )
```

### Pattern F: Git-Based Transfer (MOST RECOMMENDED)

**This is the most efficient method for git projects and should be the default:**

```python
def transfer_via_git(task_ws, home_ws, project_path, task_description):
    """
    Use git to transfer changes - most efficient and token-friendly
    
    This method:
    - Only transfers diffs, not entire files
    - Preserves history
    - No file content in agent context
    - Works with any file size
    """
    
    # 1. In task workspace: commit all changes
    result = coder_workspace_bash(
        workspace=task_ws,
        command=f"""
            cd {project_path}
            git add .
            git commit -m "Task: {task_description}" || echo "Nothing to commit"
            git rev-parse HEAD
        """,
        timeout_ms=30000
    )
    
    commit_hash = result.stdout.strip().split('\n')[-1]
    
    # 2. Create a patch file (much smaller than full files)
    coder_workspace_bash(
        workspace=task_ws,
        command=f"""
            cd {project_path}
            git format-patch -1 HEAD --stdout > /tmp/task-changes.patch
        """,
        timeout_ms=30000
    )
    
    # 3. Transfer patch file (small, efficient)
    patch_content = coder_workspace_read_file(
        workspace=task_ws,
        path="/tmp/task-changes.patch"
    )
    
    coder_workspace_write_file(
        workspace=home_ws,
        path="/tmp/task-changes.patch",
        content=patch_content
    )
    
    # 4. Apply patch in home workspace
    coder_workspace_bash(
        workspace=home_ws,
        command=f"""
            cd {project_path}
            git am /tmp/task-changes.patch
            rm /tmp/task-changes.patch
        """,
        timeout_ms=30000
    )
    
    return commit_hash
```

---

## Best Practices

### 1. Always Transfer Before Stopping

**Critical:** Never stop a task workspace without transferring work first.

```
✅ CORRECT:
1. Complete work in task workspace
2. Transfer files to home workspace
3. Verify transfer successful
4. Stop task workspace

❌ WRONG:
1. Complete work in task workspace
2. Stop task workspace
3. Lose all work!
```

### 2. Use Token-Efficient Transfer Methods

**CRITICAL FOR PRODUCTION:** Choose transfer methods that minimize token usage.

**Recommended methods (in order of preference):**

1. **Git Patch Transfer** (Pattern A)
   - ✅ Minimal tokens (1-10KB patches)
   - ✅ Works with any file size
   - ✅ Preserves history
   - Use for: All git projects

2. **Bash Direct Transfer** (Pattern B)
   - ✅ Zero tokens for file content
   - ✅ Fastest method
   - ✅ Handles large files
   - Use for: Non-git projects, large files

3. **File List Transfer** (Pattern C)
   - ⚠️ Moderate token usage
   - ⚠️ Limited to < 5 small files
   - Use for: Emergency only, when git/bash not available

**Avoid:**
- ❌ Full directory transfer (Pattern D) - High token usage
- ❌ Reading large files into agent context
- ❌ Transferring binary files through agent

### 3. Use Git for Change Tracking

If your project uses git:
- Initialize git in task workspace at start
- Use git patches to transfer (minimal tokens)
- Transfer only diffs, not full files
- Commit in home workspace after transfer

### 4. Verify Transfer Success

Always verify files were transferred:
```bash
# Check file exists
coder_workspace_ls(workspace="home-workspace", path="/path/to/file")

# Or verify file count
result = coder_workspace_bash(
    workspace="home-workspace",
    command="find /home/coder/project -type f | wc -l"
)
```

### 5. Handle Transfer Failures

```python
try:
    transfer_files(task_ws, home_ws, files)
    verify_transfer(home_ws, files)
except TransferError as e:
    # Don't stop task workspace - work is still there
    log_error(f"Transfer failed: {e}")
    notify_user("Transfer failed - task workspace kept running")
    # User can manually investigate or retry
```

### 6. Preserve File Metadata

When possible, preserve:
- File permissions
- Timestamps
- Directory structure

```bash
# Preserve permissions with rsync
rsync -av --perms --times source/ dest/

# Or with tar
tar --preserve-permissions -czf archive.tar.gz .
```

### 7. Transfer Incrementally for Long Tasks

For long-running tasks, transfer at checkpoints:

```
Phase 1: Implement feature
  → Transfer to home workspace (git patch)
  → Commit: "Phase 1: Feature implementation"

Phase 2: Add tests
  → Transfer to home workspace (git patch)
  → Commit: "Phase 2: Tests added"

Phase 3: Documentation
  → Transfer to home workspace (git patch)
  → Commit: "Phase 3: Documentation complete"
```

### 8. Monitor Token Usage

Be aware of token consumption:

```python
# Before transfer
print(f"Transferring {len(changed_files)} files")

# Use git patch for efficiency
if len(changed_files) > 5 or any_large_files:
    use_git_patch_transfer()  # Minimal tokens
else:
    use_file_list_transfer()  # Moderate tokens
```

### 9. Handle Large Files Specially

For large files (> 1MB):
- ✅ Use git patch transfer (only diffs)
- ✅ Use bash direct transfer (no agent context)
- ❌ Never read into agent context

```python
# Check file size before transfer
size_result = coder_workspace_bash(
    workspace=task_ws,
    command=f"stat -c%s {file_path}"
)

file_size = int(size_result.stdout.strip())

if file_size > 1000000:  # 1MB
    # Use git patch or bash direct
    use_efficient_transfer_method()
else:
    # Can use file list transfer
    use_standard_transfer()
```

### 10. Batch Small Changes

For multiple small changes, batch them:

```python
# Instead of transferring after each change
for change in changes:
    make_change()
    transfer()  # ❌ Inefficient

# Batch changes
for change in changes:
    make_change()

transfer_all_at_once()  # ✅ Efficient
```

---

## Error Handling

### Transfer Failure

```python
def safe_transfer(task_ws, home_ws, files):
    failed_files = []
    
    for file_path in files:
        try:
            content = coder_workspace_read_file(
                workspace=task_ws,
                path=file_path
            )
            
            coder_workspace_write_file(
                workspace=home_ws,
                path=file_path,
                content=content
            )
        except Exception as e:
            failed_files.append((file_path, str(e)))
    
    if failed_files:
        # Log failures but continue
        log_warning(f"Failed to transfer {len(failed_files)} files")
        # Keep task workspace running for manual recovery
        return False
    
    return True
```

### Partial Transfer Recovery

If transfer partially fails:
1. Log which files succeeded
2. Log which files failed
3. Keep task workspace running
4. Retry failed files
5. Only stop workspace after full success

### Workspace Connection Loss

If connection to task workspace is lost:
1. Don't panic - workspace may still be running
2. Check workspace status: `coder_get_task_status`
3. If running, retry transfer
4. If stopped, work may be lost (this is why incremental transfer is important)

---

## Integration with Task Workflow

### Updated Task Lifecycle

```
1. Create task (coder_create_task)
   ↓
2. Wait for running (poll coder_get_task_status)
   ↓
3. Get workspace name (coder_get_task_logs)
   ↓
4. Do work in task workspace
   ↓
5. **TRANSFER WORK TO HOME WORKSPACE** ← NEW STEP
   ↓
6. Verify transfer successful
   ↓
7. Stop task workspace (coder_create_workspace_build)
   ↓
8. Optional: Delete task (coder_delete_task)
```

### Checkpoint Pattern

For long tasks with checkpoints:

```
1. Create task
   ↓
2. Phase 1 work
   ↓
3. **CHECKPOINT: Transfer to home workspace**
   ↓
4. Phase 2 work
   ↓
5. **CHECKPOINT: Transfer to home workspace**
   ↓
6. Phase 3 work
   ↓
7. **FINAL: Transfer to home workspace**
   ↓
8. Stop task workspace
```

---

## Determining Home Workspace Name

The home workspace is the workspace where Kiro is currently running:

```bash
# Get current workspace name from environment
HOME_WORKSPACE = $CODER_WORKSPACE_NAME

# Or construct from owner and workspace
HOME_WORKSPACE = f"{CODER_WORKSPACE_OWNER_NAME}/{CODER_WORKSPACE_NAME}"
```

**In Kiro agent context:**
- The home workspace is automatically known from environment variables
- Task workspace name comes from `coder_get_task_logs` after creation
- Always transfer FROM task workspace TO home workspace

---

## Example: Complete Transfer Implementation

```python
def complete_task_with_transfer(task_description, template_id):
    """
    Complete workflow: create task, do work, transfer back, cleanup
    Uses token-efficient git patch method
    """
    
    # Get home workspace info
    home_workspace = f"{os.getenv('CODER_WORKSPACE_OWNER_NAME')}/{os.getenv('CODER_WORKSPACE_NAME')}"
    project_path = "/home/coder/project"
    
    # 1. Create task
    task = coder_create_task(
        input=task_description,
        template_version_id=template_id
    )
    
    # 2. Wait for running
    while True:
        status = coder_get_task_status(task_id=task.id)
        if status.status == "running":
            break
        time.sleep(10)
    
    # 3. Get task workspace name
    logs = coder_get_task_logs(task_id=task.id)
    task_workspace = extract_workspace_name(logs)
    
    # 4. Do work in task workspace
    # ... perform work using coder_workspace_* tools ...
    
    # 5. TRANSFER WORK BACK TO HOME WORKSPACE (TOKEN-EFFICIENT METHOD)
    print(f"Transferring work from {task_workspace} to {home_workspace}...")
    
    # METHOD A: Git Patch Transfer (RECOMMENDED - Minimal Tokens)
    if is_git_project(task_workspace, project_path):
        print("Using git patch transfer (minimal tokens)...")
        
        # Commit changes in task workspace
        coder_workspace_bash(
            workspace=task_workspace,
            command=f"""
                cd {project_path}
                git add .
                git commit -m "Task: {task_description}" || echo "Nothing to commit"
            """,
            timeout_ms=30000
        )
        
        # Create patch file (only diffs, very small)
        coder_workspace_bash(
            workspace=task_workspace,
            command=f"""
                cd {project_path}
                git format-patch -1 HEAD --stdout > /tmp/task.patch
            """,
            timeout_ms=30000
        )
        
        # Transfer patch (minimal token usage)
        patch_content = coder_workspace_read_file(
            workspace=task_workspace,
            path="/tmp/task.patch"
        )
        
        coder_workspace_write_file(
            workspace=home_workspace,
            path="/tmp/task.patch",
            content=patch_content
        )
        
        # Apply patch in home workspace
        result = coder_workspace_bash(
            workspace=home_workspace,
            command=f"""
                cd {project_path}
                git am /tmp/task.patch || git apply /tmp/task.patch
                rm /tmp/task.patch
            """,
            timeout_ms=30000
        )
        
        print("✅ Git patch transfer complete (minimal tokens used)")
    
    # METHOD B: Bash Direct Transfer (ALTERNATIVE - Zero Tokens for Content)
    else:
        print("Using bash direct transfer (zero tokens for content)...")
        
        # Check if workspaces share filesystem
        result = coder_workspace_bash(
            workspace=task_workspace,
            command=f"""
                # Try to access home workspace path
                if [ -d "/home/coder/workspaces/{home_workspace}" ]; then
                    rsync -av --delete {project_path}/ /home/coder/workspaces/{home_workspace}/project/
                    echo "RSYNC_SUCCESS"
                else
                    # Fallback: use tar
                    cd {project_path}
                    tar czf /tmp/transfer.tar.gz .
                    echo "TAR_CREATED"
                fi
            """,
            timeout_ms=120000
        )
        
        if "RSYNC_SUCCESS" in result.stdout:
            print("✅ Bash direct transfer complete (zero tokens used)")
        else:
            # Fallback: transfer tar file
            tar_content = coder_workspace_read_file(
                workspace=task_workspace,
                path="/tmp/transfer.tar.gz"
            )
            
            coder_workspace_write_file(
                workspace=home_workspace,
                path="/tmp/transfer.tar.gz",
                content=tar_content
            )
            
            coder_workspace_bash(
                workspace=home_workspace,
                command=f"cd {project_path} && tar xzf /tmp/transfer.tar.gz && rm /tmp/transfer.tar.gz",
                timeout_ms=60000
            )
            
            print("✅ Tar transfer complete")
    
    # 6. Verify transfer (quick check)
    result = coder_workspace_bash(
        workspace=home_workspace,
        command=f"cd {project_path} && find . -type f | wc -l",
        timeout_ms=15000
    )
    
    file_count = int(result.stdout.strip())
    print(f"✅ Verified: {file_count} files in home workspace")
    
    # 7. Stop task workspace
    coder_create_workspace_build(
        workspace_id=task.workspace_id,
        transition="stop"
    )
    
    print(f"✅ Task complete - work transferred to {home_workspace}")
    
    return {
        "task_id": task.id,
        "home_workspace": home_workspace,
        "file_count": file_count,
        "transfer_method": "git_patch" if is_git_project(task_workspace, project_path) else "bash_direct"
    }


def is_git_project(workspace, project_path):
    """Check if project uses git"""
    result = coder_workspace_bash(
        workspace=workspace,
        command=f"cd {project_path} && git rev-parse --git-dir 2>/dev/null",
        timeout_ms=5000
    )
    return result.exit_code == 0
```

---

## Summary

**Key Principles:**
1. Home workspace is the source of truth
2. Task workspaces are ephemeral execution environments
3. Always transfer work before stopping task workspace
4. **Use token-efficient transfer methods (git patch or bash direct)**
5. Transfer at checkpoints for long tasks
6. Verify transfer success before cleanup
7. Use git for change tracking when possible

**Benefits:**
- ✅ Permanent record in home workspace
- ✅ No work lost when task workspaces are deleted
- ✅ Clear data flow pattern
- ✅ Easy to track project history
- ✅ Supports incremental development
- ✅ **Minimal token usage with efficient transfer methods**

**Token Efficiency:**
- ✅ Git patch: 1-10KB (only diffs)
- ✅ Bash direct: Zero tokens for file content
- ⚠️ File list: Moderate (use sparingly)
- ❌ Full directory: High (avoid in production)

**Remember:** The task workspace is temporary - the home workspace is forever! And always use token-efficient transfer methods.
