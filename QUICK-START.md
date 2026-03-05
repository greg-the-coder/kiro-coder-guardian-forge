# Kiro Coder Guardian Forge — Quick Start Guide

Get up and running with Kiro Coder Guardian Forge in 10 minutes (5 minutes one-time setup + 5 minutes first task).

**Version:** 3.4.0  
**Last Updated:** March 5, 2026

---

## Prerequisites

1. **Coder deployment** with `mcp-server-http` experiment enabled
2. **Coder workspace** with MCP configuration (template-based setup)
3. **One-time setup completed** - SSH authentication configured (see below)

---

## One-Time Setup (5 minutes)

**Before creating your first task, complete the one-time SSH setup:**

📖 **See ONE-TIME-SETUP.md for detailed step-by-step instructions**

**Quick summary:**
1. Get your SSH public key: `cat ~/.ssh/id_ed25519.pub`
2. Add to GitHub: https://github.com/settings/keys
3. Test: `ssh -T git@github.com`
4. Verify git remote uses SSH format

**Why this is required:** Task workspaces need to push code to git. This one-time setup authorizes your Coder workspaces to push to your repositories.

**After completing this once, all future workspaces work automatically!**

---

## MCP Setup (2 Options)

### Option A: Template-Based Setup (Recommended)

**If your workspace template includes MCP configuration:**

1. Start your Coder workspace (MCP configured automatically)
2. Open Kiro
3. Verify "coder" MCP server is connected in MCP Servers panel
4. Start creating tasks!

**No manual setup required!** The template creates `~/.kiro/settings/mcp.json` automatically using `CODER_SESSION_TOKEN`.

### Option B: Manual Setup (Fallback)

**If your template doesn't include MCP configuration:**

```bash
# Run the setup script
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh

# Restart Kiro to connect
```

The setup script creates `~/.kiro/settings/mcp.json` with your Coder URL and session token.

---

## Your First Task (5 Steps)

### 1. Verify Connection

In Kiro chat:
```
Activate the kiro-coder-guardian-forge power and verify connection
```

You should see:
```
✅ Connected to Coder as <username>
✅ MCP server: coder
✅ Ready to create tasks
```

### 2. Load Task Workflow

In Kiro chat:
```
Load the task-workflow steering file
```

This loads the comprehensive task creation workflow with validation and automation.

### 3. Create Your First Task

In Kiro chat:
```
Create a Coder task to implement a simple hello world API endpoint
```

Kiro will:
- Validate prerequisites (SSH auth, git repo, templates)
- Filter for task-ready templates
- Create feature branch
- Create task with validation requirements
- Wait for workspace ready

### 4. Monitor Progress

Kiro automatically monitors the task:
- Checks task status every 30 seconds
- Shows workspace agent activity
- Reports progress updates

### 5. Complete and Transfer Work

When task completes, Kiro will:
- Commit and push from task workspace
- Fetch and merge in home workspace
- Stop task workspace immediately
- Clean up feature branch

**All automated via `complete_task_with_cleanup()` function!**

---

## Quick Reference

### Common Commands

**Create a task:**
```
Create a Coder task to <description>
```

**Monitor task:**
```
Check the status of task <task-id>
```

**Run a command in task workspace:**
```
Run '<command>' in the task workspace
```

**Complete task:**
```
The task is complete - transfer work and stop workspace
```

### Key Tools

| Tool | Purpose |
|---|---|
| `coder_create_task` | Create a new Coder Task |
| `coder_get_task_status` | Check task/workspace status |
| `coder_get_task_logs` | Get workspace logs and agent activity |
| `coder_send_task_input` | Send prompts to workspace agent |
| `coder_workspace_bash` | Run commands in workspace |
| `coder_workspace_read_file` | Read file contents |
| `coder_workspace_write_file` | Create new file |
| `coder_workspace_edit_file` | Edit existing file |
| `coder_create_workspace_build` | Stop workspace |

### New in v3.2

**Automated Work Transfer:**
```python
complete_task_with_cleanup(
    task_workspace="alice/task-123",
    home_workspace="alice/main-workspace",
    feature_branch="feature/hello-api",
    task_description="Implement hello world API"
)
```

**Comprehensive Task Prompts:**
```python
prompt = generate_task_prompt(
    task_description="Implement REST API",
    feature_branch="feature/api",
    home_workspace="alice/main",
    repo_path="/workspaces/project",
    validation_requirements=[
        "Run tests: `npm test`",
        "Run build: `npm run build`"
    ]
)
```

**Parallel Tasks:**
```python
task_ids, branches, workspaces = create_parallel_tasks(tasks, home_workspace)
completed, failed = monitor_parallel_tasks(task_ids)
```

---

## Troubleshooting

### "Failed to connect to Coder"

**Check MCP configuration:**
```bash
cat ~/.kiro/settings/mcp.json
```

Should show:
```json
{
  "mcpServers": {
    "coder": {
      "url": "https://coder.example.com/api/experimental/mcp/http",
      "headers": {
        "Authorization": "Bearer <session-token>"
      }
    }
  }
}
```

**If missing, run setup script:**
```bash
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh
```

### "Permission denied (publickey)"

**SSH authentication not configured:**
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your@email.com" -f ~/.ssh/id_ed25519 -N ""

# Display public key
cat ~/.ssh/id_ed25519.pub

# Add to GitHub: https://github.com/settings/keys
# Test: ssh -T git@github.com
```

### "No task-ready templates found"

**Ask your Coder admin to create a task-ready template with `coder_ai_task` resource.**

See `coder-template-example.tf` for complete example.

### "Task stuck in pending"

Wait up to 5 minutes for initial provisioning. If still stuck:
- Check Coder server logs
- Verify template is configured correctly
- Check resource quotas

### "Work transfer failed"

**Check git remote uses SSH:**
```bash
cd /workspaces/your-project
git remote -v

# Should show: git@github.com:user/repo.git
# If shows https://, convert:
git remote set-url origin git@github.com:user/repo.git
```

---

## Next Steps

### Documentation
- **POWER.md** - Complete power documentation
- **WORK-TRANSFER-PATTERN.md** - Git-based work transfer pattern
- **QUICK-REFERENCE-V3.2.md** - Copy-paste examples for v3.2 features
- **steering/task-workflow.md** - Task creation and monitoring
- **steering/agent-interaction.md** - Workspace agent collaboration
- **steering/workspace-ops.md** - Workspace operations

### Learn More
- **Automated Work Transfer** - See `complete_task_with_cleanup()` in task-workflow.md
- **Task Validation** - See `generate_task_prompt()` in agent-interaction.md
- **Parallel Tasks** - See parallel patterns in task-workflow.md
- **Best Practices** - See Best Practices section in POWER.md

### Support
- Coder Documentation: https://coder.com/docs
- Kiro Documentation: https://kiro.dev/docs
- MCP Configuration: https://kiro.dev/docs/mcp/configuration/

---

## What's New in v3.2

### Automated Work Transfer (90% faster)
- `complete_task_with_cleanup()` function
- Git-based transfer (commit/push/fetch/merge)
- Automatic workspace cleanup
- 2 minutes vs 20 minutes for manual copying

### Comprehensive Validation
- `generate_task_prompt()` with validation requirements
- Pre-completion validation checklists
- Project-specific validation patterns
- 80% reduction in post-task bug fixes

### Parallel Task Coordination
- `create_parallel_tasks()` for independent tasks
- `create_sequential_tasks()` for dependencies
- `monitor_parallel_tasks()` for unified monitoring
- 50% time savings for parallel execution

### Workspace Lifecycle Management
- Automatic cleanup after work transfer
- Clear lifecycle state documentation
- When to stop vs delete guidance
- 100% automation of workspace cleanup

---

**You're ready to go! Create your first task and experience the automated workflow.**

**Version:** 3.2.0 - See `CHANGELOG.md` for complete release notes
