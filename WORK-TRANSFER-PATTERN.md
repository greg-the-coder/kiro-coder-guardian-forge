# Work Sharing Pattern: Git Worktrees for Coder Tasks

This document describes the recommended pattern for sharing work between the home Coder workspace (where Kiro runs) and ephemeral Coder Task workspaces using git worktrees.

---

## Core Concept

**Home Workspace:** Contains the main git repository (cloned via `coder_git_clone` resource). This is the permanent source of truth with the primary working tree on the `main` branch.

**Task Workspace:** Uses a git worktree pointing to a feature branch. Each task works in isolation on its own branch, commits directly to git, and pushes changes to the remote.

**Pattern:** Work is shared via standard git operations (commit, push, merge) instead of manual file copying. This is significantly more efficient, preserves git history, and aligns with standard development workflows.

---

## Architecture

```
┌─────────────────────────────────────────────┐
│   Home Workspace (Kiro Running)            │
│   /workspaces/my-project/                  │
│   ├── .git/              (shared)          │
│   ├── main branch        (primary tree)    │
│   └── Source of truth                      │
└──────────────┬──────────────────────────────┘
               │
               │ Shared .git directory
               │ (via network mount or shared storage)
               │
               ├─────────────────────────────────┐
               │                                 │
               ↓                                 ↓
┌──────────────────────────────┐  ┌──────────────────────────────┐
│  Task Workspace 1            │  │  Task Workspace 2            │
│  /workspaces/task-1/         │  │  /workspaces/task-2/         │
│  ├── .git/ → (shared)        │  │  ├── .git/ → (shared)        │
│  ├── feature/task-1 branch   │  │  ├── feature/task-2 branch   │
│  └── Git worktree            │  │  └── Git worktree            │
└──────────────────────────────┘  └──────────────────────────────┘
               │                                 │
               │ git commit + push               │ git commit + push
               ↓                                 ↓
┌─────────────────────────────────────────────┐
│   Remote Git Repository                     │
│   ├── main                                  │
│   ├── feature/task-1                        │
│   └── feature/task-2                        │
└─────────────────────────────────────────────┘
               │
               │ git fetch + merge
               ↓
┌─────────────────────────────────────────────┐
│   Home Workspace (Updated)                  │
│   All feature branches merged to main       │
└─────────────────────────────────────────────┘
```

---

## Prerequisites

### Coder Template Requirements

**Home workspace template must include:**

```hcl
# Clone the project repository
resource "coder_git_clone" "project" {
  agent_id = coder_agent.dev.id
  url      = "https://github.com/org/project.git"
  path     = "/workspaces/project"
}

# Shared storage for .git directory
resource "kubernetes_persistent_volume_claim" "git_storage" {
  metadata {
    name = "git-storage-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
  }
  spec {
    access_modes = ["ReadWriteMany"]  # Multiple workspaces can access
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}
```

**Task workspace template must include:**

```hcl
# Mount shared .git directory
resource "kubernetes_persistent_volume_claim" "git_storage" {
  metadata {
    name = "git-storage-${var.home_workspace_owner}-${var.home_workspace_name}"
  }
  # Reference the home workspace's PVC
}

# Task-specific configuration
resource "coder_ai_task" "main" {
  agent_id = coder_agent.dev.id
  # ... task configuration ...
}
```

---

## Workflow

### Step 1: Create Task with Feature Branch

When creating a Coder Task, specify the feature branch:

```python
# Create task for specific work
task = coder_create_task(
    input="Implement user authentication API",
    template_version_id="task-template-id",
    rich_parameter_values={
        "feature_branch": "feature/auth-api",
        "home_workspace": f"{owner}/{workspace_name}",
        "project_path": "/workspaces/my-project"
    }
)
```

### Step 2: Task Workspace Initializes Git Worktree

The task workspace startup script automatically sets up the git worktree:

```bash
#!/bin/bash
# Task workspace startup script

# Get parameters
FEATURE_BRANCH="${FEATURE_BRANCH}"
HOME_WORKSPACE="${HOME_WORKSPACE}"
PROJECT_PATH="${PROJECT_PATH}"
SHARED_GIT_DIR="/mnt/shared-git/${HOME_WORKSPACE}/.git"

# Create worktree directory
WORKTREE_PATH="/workspaces/task-workspace"
mkdir -p "$WORKTREE_PATH"

# Create git worktree pointing to feature branch
cd "$PROJECT_PATH"
git worktree add "$WORKTREE_PATH" -b "$FEATURE_BRANCH"

# Set up git config for task
cd "$WORKTREE_PATH"
git config user.name "Kiro Agent"
git config user.email "kiro@coder.com"

echo "✅ Git worktree ready at $WORKTREE_PATH on branch $FEATURE_BRANCH"
```

### Step 3: Work in Task Workspace

The task workspace works directly with git:

```bash
# Task workspace operations
cd /workspaces/task-workspace

# Make changes
echo "new feature" > src/auth.go

# Commit directly to feature branch
git add .
git commit -m "Implement authentication API"

# Push to remote
git push origin feature/auth-api
```

**No file copying needed!** All work is committed directly to git.

### Step 4: Merge to Home Workspace

When task completes, merge the feature branch in the home workspace:

```python
# In home workspace
coder_workspace_bash(
    workspace=home_workspace,
    command=f"""
        cd /workspaces/my-project
        
        # Fetch latest changes
        git fetch origin
        
        # Merge feature branch
        git merge origin/{feature_branch} --no-ff -m "Merge {feature_branch}"
        
        # Push to remote
        git push origin main
    """,
    timeout_ms=30000
)
```

### Step 5: Clean Up Task Workspace

After successful merge, clean up the worktree and stop the task workspace:

```python
# Remove worktree reference (optional - happens automatically on workspace deletion)
coder_workspace_bash(
    workspace=home_workspace,
    command=f"""
        cd /workspaces/my-project
        git worktree remove /workspaces/task-workspace --force
    """,
    timeout_ms=15000
)

# Stop task workspace
coder_create_workspace_build(
    workspace_id=task_workspace_id,
    transition="stop"
)
```

---

## Benefits

### Efficiency
- ✅ **No file copying**: Direct git operations instead of manual transfer
- ✅ **No base64 encoding**: No need to encode/decode large files
- ✅ **Minimal tokens**: Only git commands in agent context, not file contents
- ✅ **Fast operations**: Git is optimized for this workflow

### Git Integration
- ✅ **Full history**: Complete git history and blame information preserved
- ✅ **Atomic commits**: Each task commits to its own branch
- ✅ **Standard workflow**: Everyone knows how to use git
- ✅ **Branch isolation**: Tasks don't interfere with each other

### Collaboration
- ✅ **Multiple tasks**: Can work simultaneously on different branches
- ✅ **Code review**: Feature branches can be reviewed before merge
- ✅ **Rollback**: Easy to revert changes if needed
- ✅ **Conflict resolution**: Standard git merge conflict handling

### Auditability
- ✅ **Complete history**: All changes tracked in git
- ✅ **Author information**: Commits show who made changes
- ✅ **Timestamps**: When changes were made
- ✅ **Commit messages**: Why changes were made

---

## Implementation Patterns

### Pattern A: Simple Feature Branch (Recommended)

**Use for:** Most tasks - single feature implementation

```python
def create_task_with_worktree(task_description, feature_branch):
    """
    Create task that works on a feature branch via git worktree
    """
    
    # 1. Create feature branch in home workspace
    coder_workspace_bash(
        workspace=home_workspace,
        command=f"""
            cd /workspaces/my-project
            git checkout -b {feature_branch}
            git push -u origin {feature_branch}
        """,
        timeout_ms=15000
    )
    
    # 2. Create task with feature branch parameter
    task = coder_create_task(
        input=task_description,
        template_version_id=task_template_id,
        rich_parameter_values={
            "feature_branch": feature_branch,
            "home_workspace": home_workspace,
            "project_path": "/workspaces/my-project"
        }
    )
    
    # 3. Wait for task workspace to be ready
    # (worktree is set up automatically by task startup script)
    
    # 4. Task workspace works and commits to feature branch
    # (happens in task workspace)
    
    # 5. When task completes, merge to main
    coder_workspace_bash(
        workspace=home_workspace,
        command=f"""
            cd /workspaces/my-project
            git checkout main
            git fetch origin
            git merge origin/{feature_branch} --no-ff -m "Merge {feature_branch}"
            git push origin main
        """,
        timeout_ms=30000
    )
    
    # 6. Stop task workspace
    coder_create_workspace_build(
        workspace_id=task.workspace_id,
        transition="stop"
    )
    
    return task
```

### Pattern B: Checkpoint Commits

**Use for:** Long-running tasks with multiple phases

```python
def task_with_checkpoints(task_description, feature_branch):
    """
    Task commits at checkpoints, home workspace can track progress
    """
    
    # Create task (same as Pattern A)
    task = create_task_with_worktree(task_description, feature_branch)
    
    # Task workspace commits at each checkpoint
    # Phase 1
    coder_workspace_bash(
        workspace=task_workspace,
        command="""
            cd /workspaces/task-workspace
            # ... do work ...
            git add .
            git commit -m "Phase 1: Design complete"
            git push origin feature/task
        """,
        timeout_ms=60000
    )
    
    # Home workspace can fetch and review progress
    coder_workspace_bash(
        workspace=home_workspace,
        command=f"""
            cd /workspaces/my-project
            git fetch origin
            git log origin/{feature_branch} --oneline
        """,
        timeout_ms=15000
    )
    
    # Continue with more phases...
    # Final merge happens when all phases complete
```

### Pattern C: Multiple Concurrent Tasks

**Use for:** Parallel work on different features

```python
def create_multiple_tasks(tasks):
    """
    Create multiple tasks working on different feature branches simultaneously
    """
    
    task_results = []
    
    for task_desc, feature_branch in tasks:
        # Each task gets its own feature branch and worktree
        task = create_task_with_worktree(task_desc, feature_branch)
        task_results.append((task, feature_branch))
    
    # All tasks work in parallel
    # Each commits to its own feature branch
    
    # When all complete, merge all branches
    for task, feature_branch in task_results:
        coder_workspace_bash(
            workspace=home_workspace,
            command=f"""
                cd /workspaces/my-project
                git fetch origin
                git merge origin/{feature_branch} --no-ff -m "Merge {feature_branch}"
            """,
            timeout_ms=30000
        )
    
    # Push all merges
    coder_workspace_bash(
        workspace=home_workspace,
        command="""
            cd /workspaces/my-project
            git push origin main
        """,
        timeout_ms=15000
    )
```

---

## Task Template Configuration

### Required Template Parameters

Task templates should accept these parameters:

```hcl
variable "feature_branch" {
  description = "Git feature branch for this task"
  type        = string
}

variable "home_workspace" {
  description = "Home workspace name (owner/workspace)"
  type        = string
}

variable "project_path" {
  description = "Path to project in home workspace"
  type        = string
  default     = "/workspaces/project"
}
```

### Startup Script

```hcl
resource "coder_agent" "dev" {
  startup_script = <<-EOT
    #!/bin/bash
    set -e
    
    # Parameters from template
    FEATURE_BRANCH="${var.feature_branch}"
    HOME_WORKSPACE="${var.home_workspace}"
    PROJECT_PATH="${var.project_path}"
    
    # Shared git directory (mounted from home workspace)
    SHARED_GIT_DIR="/mnt/shared-git/${HOME_WORKSPACE}/.git"
    WORKTREE_PATH="/workspaces/task-workspace"
    
    # Wait for shared git directory to be available
    echo "Waiting for shared git directory..."
    timeout 60 bash -c "until [ -d '$SHARED_GIT_DIR' ]; do sleep 1; done"
    
    # Create worktree
    echo "Creating git worktree for branch: $FEATURE_BRANCH"
    mkdir -p "$WORKTREE_PATH"
    
    # Use git worktree add with shared .git directory
    GIT_DIR="$SHARED_GIT_DIR" git worktree add "$WORKTREE_PATH" "$FEATURE_BRANCH"
    
    # Configure git for task
    cd "$WORKTREE_PATH"
    git config user.name "Kiro Agent"
    git config user.email "kiro@coder.com"
    
    echo "✅ Git worktree ready at $WORKTREE_PATH on branch $FEATURE_BRANCH"
    echo "   Shared .git: $SHARED_GIT_DIR"
    echo "   Home workspace: $HOME_WORKSPACE"
  EOT
}
```

---

## Best Practices

### Branch Naming

Use descriptive, task-specific branch names:

```
feature/auth-api
feature/user-dashboard
feature/payment-integration
bugfix/login-error
refactor/database-layer
```

**Pattern:** `<type>/<description>`
- `feature/` - New features
- `bugfix/` - Bug fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation updates

### Commit Messages

Write clear, descriptive commit messages:

```bash
# Good
git commit -m "Implement JWT authentication for API endpoints"
git commit -m "Add user dashboard with profile management"
git commit -m "Fix login error when password contains special characters"

# Avoid
git commit -m "updates"
git commit -m "fix"
git commit -m "wip"
```

### Merge Strategy

Use `--no-ff` (no fast-forward) to preserve feature branch history:

```bash
git merge origin/feature/auth-api --no-ff -m "Merge feature/auth-api"
```

This creates a merge commit even if fast-forward is possible, making it clear when features were integrated.

### Cleanup

Clean up feature branches after successful merge:

```bash
# Delete local branch
git branch -d feature/auth-api

# Delete remote branch
git push origin --delete feature/auth-api

# Remove worktree reference
git worktree prune
```

---

## Troubleshooting

### Problem: "Shared .git directory not found"

**Cause:** Task workspace can't access home workspace's .git directory

**Solutions:**
1. Verify shared storage is configured correctly
2. Check PVC is mounted in both workspaces
3. Verify network mount permissions
4. Check home workspace is running

### Problem: "Worktree already exists"

**Cause:** Previous task didn't clean up worktree

**Solution:**
```bash
# In home workspace
cd /workspaces/my-project
git worktree list
git worktree remove /workspaces/task-workspace --force
git worktree prune
```

### Problem: "Branch already exists"

**Cause:** Feature branch from previous task wasn't deleted

**Solution:**
```bash
# Delete local and remote branch
git branch -D feature/old-task
git push origin --delete feature/old-task

# Or use a unique branch name
feature/auth-api-$(date +%s)
```

### Problem: "Merge conflicts"

**Cause:** Feature branch conflicts with main

**Solution:**
```bash
# In home workspace
cd /workspaces/my-project
git fetch origin
git checkout feature/auth-api
git rebase main

# Resolve conflicts
git add .
git rebase --continue

# Push resolved branch
git push origin feature/auth-api --force

# Merge to main
git checkout main
git merge feature/auth-api --no-ff
```

---

## Comparison: Old vs. New Approach

### Old Approach (File Copying)

```python
# ❌ Token-intensive, error-prone
for file in changed_files:
    content = coder_workspace_read_file(workspace=task_ws, path=file)  # Large file in context
    coder_workspace_write_file(workspace=home_ws, path=file, content=content)  # Base64 encoding
```

**Problems:**
- High token usage (file contents in agent context)
- Base64 encoding overhead
- No git history
- Manual file tracking
- Risk of incomplete transfer

### New Approach (Git Worktrees)

```python
# ✅ Efficient, standard git workflow
coder_workspace_bash(
    workspace=task_ws,
    command="cd /workspaces/task-workspace && git add . && git commit -m 'Complete feature' && git push",
    timeout_ms=30000
)

coder_workspace_bash(
    workspace=home_ws,
    command="cd /workspaces/my-project && git fetch && git merge origin/feature/task --no-ff",
    timeout_ms=30000
)
```

**Benefits:**
- Minimal token usage (only git commands)
- No encoding overhead
- Full git history preserved
- Automatic file tracking
- Atomic operations

---

## Summary

**Git worktrees provide the optimal workflow for sharing work between home and task workspaces:**

✅ **Efficient** - No file copying, minimal tokens  
✅ **Standard** - Uses familiar git workflows  
✅ **Atomic** - Each task works on isolated branch  
✅ **Auditable** - Complete git history preserved  
✅ **Scalable** - Multiple tasks can work simultaneously  
✅ **Simple** - Standard git commands everyone knows  

**Key Requirements:**
- Home workspace template with `coder_git_clone` resource
- Shared storage for .git directory (PVC with ReadWriteMany)
- Task workspace template with worktree initialization
- Feature branch per task

**Workflow:**
1. Create feature branch in home workspace
2. Create task with feature branch parameter
3. Task workspace initializes worktree automatically
4. Task commits directly to feature branch
5. Home workspace merges feature branch when complete
6. Clean up and stop task workspace

This approach eliminates the complexity and inefficiency of manual file transfer while providing all the benefits of standard git workflows.
