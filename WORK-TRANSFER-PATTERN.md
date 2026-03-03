# Work Transfer Pattern: Git-Based Transfer for Coder Tasks

This document describes the recommended pattern for transferring work between the home Coder workspace (where Kiro runs) and ephemeral Coder Task workspaces using standard git operations.

**Version:** 3.2.0  
**Last Updated:** March 3, 2026

---

## Core Concept

**Home Workspace:** Contains the main git repository. This is the permanent source of truth with the primary working tree on the `main` branch.

**Task Workspace:** Works on a feature branch. Each task works in isolation on its own branch, commits directly to git, and pushes changes to the remote.

**Pattern:** Work is shared via standard git operations (commit, push, fetch, merge) instead of manual file copying. This is significantly more efficient, preserves git history, and aligns with standard development workflows.

---

## Architecture

```
┌─────────────────────────────────────────────┐
│   Home Workspace (Kiro Running)            │
│   /workspaces/my-project/                  │
│   ├── .git/              (local)           │
│   ├── main branch        (primary)         │
│   └── Source of truth                      │
└──────────────┬──────────────────────────────┘
               │
               │ Git operations via remote
               │
               ↓
┌─────────────────────────────────────────────┐
│   Remote Git Repository (GitHub/GitLab)    │
│   ├── main                                  │
│   ├── feature/task-1                        │
│   └── feature/task-2                        │
└──────────────┬──────────────────────────────┘
               │
               │ Git operations via remote
               │
               ├─────────────────────────────────┐
               │                                 │
               ↓                                 ↓
┌──────────────────────────────┐  ┌──────────────────────────────┐
│  Task Workspace 1            │  │  Task Workspace 2            │
│  /workspaces/task-1/         │  │  /workspaces/task-2/         │
│  ├── .git/ (independent)     │  │  ├── .git/ (independent)     │
│  ├── feature/task-1 branch   │  │  ├── feature/task-2 branch   │
│  └── Works independently      │  │  └── Works independently      │
└──────────────────────────────┘  └──────────────────────────────┘
```

**Key Points:**
- Each workspace has its own independent .git directory
- No shared storage or network mounts required
- Work transferred via remote git repository
- Standard git workflow everyone knows

---

## Prerequisites

### Home Workspace Requirements

**Coder template must include:**

```hcl
# Clone the project repository
resource "coder_git_clone" "project" {
  agent_id = coder_agent.dev.id
  url      = "git@github.com:org/project.git"  # Use SSH URL
  path     = "/workspaces/project"
}

# SSH key configuration for git push
resource "coder_script" "ssh_setup" {
  agent_id = coder_agent.dev.id
  display_name = "SSH Key Setup"
  script = <<-EOT
    #!/bin/bash
    # Ensure SSH key exists and is configured
    if [ ! -f ~/.ssh/id_ed25519 ]; then
      echo "⚠️  SSH key not found - git push will fail"
      echo "Generate key: ssh-keygen -t ed25519 -C 'your@email.com'"
    fi
  EOT
  run_on_start = true
}
```

### Task Workspace Requirements

**Task template must include:**

```hcl
# Clone repository on feature branch
resource "coder_git_clone" "project" {
  agent_id = coder_agent.dev.id
  url      = "git@github.com:org/project.git"  # Use SSH URL
  path     = "/workspaces/project"
  branch   = var.feature_branch  # Checkout feature branch
}

# AI Task resource for lifecycle management
resource "coder_ai_task" "main" {
  agent_id        = coder_agent.dev.id
  display_name    = "AI Development Task"
  description     = "Ephemeral workspace for AI agent work"
  timeout_minutes = 120
  auto_stop       = true
}

# Template parameters
variable "feature_branch" {
  description = "Git feature branch for this task"
  type        = string
}
```

### SSH Authentication (CRITICAL)

**Both home and task workspaces require SSH authentication configured:**

```bash
# Generate SSH key (if not exists)
ssh-keygen -t ed25519 -C "your@email.com" -f ~/.ssh/id_ed25519 -N ""

# Add to GitHub/GitLab
cat ~/.ssh/id_ed25519.pub
# Copy and add to: https://github.com/settings/keys

# Test authentication
ssh -T git@github.com
# Expected: "Hi username! You've successfully authenticated..."
```

**Without SSH authentication, git push will fail and work cannot be transferred.**

---

## Workflow

### Step 1: Create Feature Branch in Home Workspace

Before creating a task, create and push the feature branch:

```python
import time

# Generate unique feature branch name
task_slug = "user-auth"
feature_branch = f"feature/{task_slug}-{int(time.time())}"

# Create and push feature branch
result = coder_workspace_bash(
    workspace=home_workspace,
    command=f"""
        cd /workspaces/my-project
        
        # Create feature branch from main
        git checkout main
        git pull origin main
        git checkout -b {feature_branch}
        
        # Push to remote
        git push -u origin {feature_branch}
        
        # Verify push succeeded
        if [ $? -eq 0 ]; then
            echo "✅ Feature branch created: {feature_branch}"
        else
            echo "❌ Failed to push feature branch"
            exit 1
        fi
    """,
    timeout_ms=30000
)

if result.exit_code != 0:
    print(f"❌ Failed to create feature branch: {result.stderr}")
    # STOP - cannot proceed without feature branch
```

### Step 2: Create Task with Feature Branch

Create the Coder Task with the feature branch parameter:

```python
# Create task
task = coder_create_task(
    input=f"Implement user authentication API. Work on branch {feature_branch}.",
    template_version_id=template_id,
    rich_parameter_values={
        "feature_branch": feature_branch,
        "home_workspace": home_workspace,
        "repo_path": "/workspaces/my-project"
    }
)

print(f"✅ Task created: {task.id}")
print(f"   Feature branch: {feature_branch}")
```

### Step 3: Task Workspace Works on Feature Branch

The task workspace automatically checks out the feature branch and works on it:

```bash
# Task workspace operations (happens automatically)
cd /workspaces/my-project

# Verify on correct branch
git branch --show-current
# Output: feature/user-auth-1234567890

# Make changes
echo "new feature" > src/auth.go

# Commit directly to feature branch
git add .
git commit -m "Implement authentication API"

# Push to remote
git push origin feature/user-auth-1234567890
```

**No file copying needed!** All work is committed directly to git.

### Step 4: Transfer Work via Git (Automated)

Use the `complete_task_with_cleanup()` function for automatic work transfer:

```python
# Automated work transfer and cleanup
success = complete_task_with_cleanup(
    task_workspace=f"{owner}/{task.id}",
    home_workspace=home_workspace,
    feature_branch=feature_branch,
    task_description="Implement user authentication",
    repo_path="/workspaces/my-project"
)

if success:
    print("✅ Work transferred successfully!")
    print("   - Task workspace committed and pushed")
    print("   - Home workspace fetched and merged")
    print("   - Task workspace stopped")
    print("   - Feature branch cleaned up")
else:
    print("❌ Work transfer failed - check logs")
```

**What this function does:**
1. Commits and pushes from task workspace
2. Fetches and merges in home workspace
3. Stops task workspace immediately
4. Cleans up feature branch (optional)

### Step 5: Manual Transfer (If Needed)

If you need more control, follow these steps manually:

#### 5a. Commit and Push from Task Workspace

```python
result = coder_workspace_bash(
    workspace=task_workspace,
    command=f"""
        cd /workspaces/my-project
        
        # Check for uncommitted changes
        if [ -n "$(git status --porcelain)" ]; then
            git add .
            git commit -m "Complete: Implement user authentication"
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
```

#### 5b. Fetch and Merge in Home Workspace

```python
result = coder_workspace_bash(
    workspace=home_workspace,
    command=f"""
        cd /workspaces/my-project
        
        # Fetch latest from remote
        git fetch origin {feature_branch}
        
        # Checkout main branch
        git checkout main
        
        # Pull latest main
        git pull origin main
        
        # Merge feature branch (no fast-forward to preserve history)
        git merge origin/{feature_branch} --no-ff -m "Merge: Implement user authentication"
        
        # Push to remote
        git push origin main
        
        # Show merge result
        echo "✅ Merge complete"
        git log --oneline -3
        git diff --stat HEAD~1
    """,
    timeout_ms=60000
)
```

#### 5c. Stop Task Workspace

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

---

## Benefits

### Efficiency
- ✅ **No file copying**: Direct git operations instead of manual transfer
- ✅ **No base64 encoding**: No need to encode/decode large files
- ✅ **Minimal tokens**: Only git commands in agent context, not file contents
- ✅ **Fast operations**: Git is optimized for this workflow
- ✅ **90% faster**: 2 minutes vs 20 minutes for manual file copying

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
def create_task_with_git_transfer(task_description, feature_branch, home_workspace, repo_path):
    """
    Create task that works on a feature branch with automatic git-based transfer
    """
    
    # 1. Create feature branch in home workspace
    coder_workspace_bash(
        workspace=home_workspace,
        command=f"""
            cd {repo_path}
            git checkout main
            git pull origin main
            git checkout -b {feature_branch}
            git push -u origin {feature_branch}
        """,
        timeout_ms=30000
    )
    
    # 2. Create task with feature branch parameter
    task = coder_create_task(
        input=task_description,
        template_version_id=task_template_id,
        rich_parameter_values={
            "feature_branch": feature_branch,
            "home_workspace": home_workspace,
            "repo_path": repo_path
        }
    )
    
    # 3. Wait for task workspace to be ready
    # (task workspace clones repo and checks out feature branch automatically)
    
    # 4. Task workspace works and commits to feature branch
    # (happens in task workspace)
    
    # 5. When task completes, transfer work via git
    success = complete_task_with_cleanup(
        task_workspace=f"{owner}/{task.id}",
        home_workspace=home_workspace,
        feature_branch=feature_branch,
        task_description=task_description,
        repo_path=repo_path
    )
    
    return task, success
```

### Pattern B: Checkpoint Commits

**Use for:** Long-running tasks with multiple phases

```python
def task_with_checkpoints(task_description, feature_branch, home_workspace, repo_path):
    """
    Task commits at checkpoints, home workspace can track progress
    """
    
    # Create task (same as Pattern A)
    task, _ = create_task_with_git_transfer(task_description, feature_branch, home_workspace, repo_path)
    
    task_workspace = f"{owner}/{task.id}"
    
    # Task workspace commits at each checkpoint
    # Phase 1
    coder_workspace_bash(
        workspace=task_workspace,
        command=f"""
            cd {repo_path}
            # ... do work ...
            git add .
            git commit -m "Phase 1: Design complete"
            git push origin {feature_branch}
        """,
        timeout_ms=60000
    )
    
    # Home workspace can fetch and review progress
    coder_workspace_bash(
        workspace=home_workspace,
        command=f"""
            cd {repo_path}
            git fetch origin
            git log origin/{feature_branch} --oneline
        """,
        timeout_ms=15000
    )
    
    # Continue with more phases...
    # Final transfer happens when all phases complete
    success = complete_task_with_cleanup(
        task_workspace=task_workspace,
        home_workspace=home_workspace,
        feature_branch=feature_branch,
        task_description=task_description,
        repo_path=repo_path
    )
    
    return task, success
```

### Pattern C: Multiple Concurrent Tasks

**Use for:** Parallel work on different features

```python
def create_multiple_tasks(tasks, home_workspace, repo_path):
    """
    Create multiple tasks working on different feature branches simultaneously
    """
    
    task_results = []
    
    for task_desc, feature_branch in tasks:
        # Each task gets its own feature branch
        task, _ = create_task_with_git_transfer(task_desc, feature_branch, home_workspace, repo_path)
        task_results.append((task, feature_branch))
    
    # All tasks work in parallel
    # Each commits to its own feature branch
    
    # When all complete, transfer all work
    for task, feature_branch in task_results:
        task_workspace = f"{owner}/{task.id}"
        success = complete_task_with_cleanup(
            task_workspace=task_workspace,
            home_workspace=home_workspace,
            feature_branch=feature_branch,
            task_description=f"Task {task.id}",
            repo_path=repo_path
        )
        
        if not success:
            print(f"⚠️ Failed to transfer work from {task.id}")
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
```

The `complete_task_with_cleanup()` function does this automatically.

---

## Troubleshooting

### Problem: "Permission denied (publickey)"

**Cause:** SSH authentication not configured

**Solution:**
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your@email.com" -f ~/.ssh/id_ed25519 -N ""

# Display public key
cat ~/.ssh/id_ed25519.pub

# Add to GitHub: https://github.com/settings/keys
# Test: ssh -T git@github.com
```

### Problem: "Git remote uses HTTPS instead of SSH"

**Cause:** Repository cloned with HTTPS URL

**Solution:**
```bash
cd /workspaces/my-project
git remote set-url origin git@github.com:user/repo.git
git remote -v
```

### Problem: "Branch already exists"

**Cause:** Feature branch from previous task wasn't deleted

**Solution:**
```bash
# Delete local and remote branch
git branch -D feature/old-task
git push origin --delete feature/old-task

# Or use a unique branch name with timestamp
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

### Problem: "Push failed - no upstream branch"

**Cause:** Feature branch not pushed to remote before task creation

**Solution:**
```bash
# In home workspace
cd /workspaces/my-project
git checkout feature/auth-api
git push -u origin feature/auth-api
```

Always push the feature branch before creating the task.

---

## Comparison: Old vs. New Approach

### Old Approach (Manual File Copying)

```python
# ❌ Token-intensive, error-prone, slow
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
- 20 minutes for typical project

### New Approach (Git-Based Transfer)

```python
# ✅ Efficient, standard git workflow, fast
complete_task_with_cleanup(
    task_workspace=task_workspace,
    home_workspace=home_workspace,
    feature_branch=feature_branch,
    task_description=task_description,
    repo_path=repo_path
)
```

**Benefits:**
- Minimal token usage (only git commands)
- No encoding overhead
- Full git history preserved
- Automatic file tracking
- Atomic operations
- 2 minutes for typical project (90% faster)

---

## Summary

**Git-based transfer provides the optimal workflow for sharing work between home and task workspaces:**

✅ **Efficient** - No file copying, minimal tokens, 90% faster  
✅ **Standard** - Uses familiar git workflows  
✅ **Atomic** - Each task works on isolated branch  
✅ **Auditable** - Complete git history preserved  
✅ **Scalable** - Multiple tasks can work simultaneously  
✅ **Simple** - Standard git commands everyone knows  
✅ **Automated** - `complete_task_with_cleanup()` function handles everything  

**Key Requirements:**
- SSH authentication configured (critical for git push)
- Home workspace with git repository
- Task workspace template with feature branch parameter
- Feature branch created and pushed before task creation

**Workflow:**
1. Create feature branch in home workspace
2. Push feature branch to remote
3. Create task with feature branch parameter
4. Task workspace clones repo and checks out feature branch
5. Task commits directly to feature branch
6. Use `complete_task_with_cleanup()` for automatic transfer
7. Work is merged to main in home workspace
8. Task workspace stopped automatically

This approach eliminates the complexity and inefficiency of manual file transfer while providing all the benefits of standard git workflows with 90% time savings.

---

**Version:** 3.2.0  
**Pattern:** Git Fetch/Merge (replaces git worktree pattern from v3.1)  
**Function:** `complete_task_with_cleanup()` in `steering/task-workflow.md`
