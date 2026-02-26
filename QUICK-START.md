# Coder Guardian Forge — Quick Start Guide

Get up and running with Coder Guardian Forge in 5 minutes.

---

## Prerequisites

1. **Coder deployment** with `mcp-server-http` experiment enabled
2. **Coder API token** from Account → Tokens
3. **At least one workspace template** configured

---

## Setup (3 Steps)

### Step 1: Set Environment Variables

Add to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
export CODER_URL="https://coder.mycompany.com/"  # Your Coder server URL (with trailing slash)
export CODER_TOKEN="<your-token-here>"            # Token from Coder UI
```

**Note:** If you're running Kiro inside a Coder workspace, `CODER_URL` is already set with a trailing slash. You only need to set `CODER_TOKEN`:
```bash
export CODER_TOKEN="<your-token-here>"
```

Reload your shell:
```bash
source ~/.zshrc  # or ~/.bashrc
```

Reload your shell:
```bash
source ~/.zshrc  # or ~/.bashrc
```

### Step 2: Install the Power

In Kiro:
1. Open Powers panel (configure action or UI)
2. Click "Add Custom Power"
3. Select "Local Directory"
4. Enter path: `/home/coder/kiro-coder-guardian-forge`
5. Click "Add"

### Step 3: Verify Connection

In Kiro chat, say:
```
Activate the coder-guardian-forge power
```

You should see:
```
Connected to Coder as <username> at <server-url>. Ready to create agent tasks.
```

---

## Your First Task (5 Steps)

### 1. Start a Task

In Kiro chat:
```
I want to create a Coder task to test the workspace
```

### 2. Choose a Template

Kiro will show available templates. Respond with:
```
Use the <template-name> template
```

### 3. Wait for Workspace

Kiro automatically:
- Creates the task
- Polls until workspace is running
- Reports "working" status to Tasks UI

### 4. Do Some Work

Try these commands:
```
List the contents of /home/coder
```

```
Create a file at /home/coder/test.txt with content "Hello from Coder"
```

```
Read the file /home/coder/test.txt
```

### 5. Complete the Task

Trigger the completion hook from Kiro UI, or say:
```
The work is complete
```

Kiro will:
- Report "idle" status to Tasks UI
- Ask if you want to stop the workspace
- Stop the workspace when confirmed

---

## Quick Reference

### Common Commands

**Create a task:**
```
I want to start working on <description> using Coder
```

**Run a command:**
```
Run '<command>' in the workspace
```

**Read a file:**
```
Read the file <path>
```

**Write a file:**
```
Create a file at <path> with content "<content>"
```

**Edit a file:**
```
Change <old-text> to <new-text> in <path>
```

**Complete task:**
```
The work is complete
```

### Key Tools

| Tool | Purpose |
|---|---|
| `coder_create_task` | Create a new Coder Task |
| `coder_get_task_status` | Check task/workspace status |
| `coder_report_task` | Update Tasks UI with progress |
| `coder_workspace_bash` | Run commands in workspace |
| `coder_workspace_read_file` | Read file contents |
| `coder_workspace_write_file` | Create new file |
| `coder_workspace_edit_file` | Edit existing file |
| `coder_create_workspace_build` | Stop workspace |

---

## Troubleshooting

### "Failed to connect to Coder"

Check:
```bash
echo $CODER_URL      # Should show your Coder server URL (with trailing slash)
echo $CODER_TOKEN    # Should show your token
```

If `CODER_URL` is missing the trailing slash, add it:
```bash
export CODER_URL="${CODER_URL}/"
```

Verify token works:
```bash
curl -H "Authorization: Bearer $CODER_TOKEN" ${CODER_URL}api/v2/users/me
```

### "No templates available"

Ask your Coder admin to create at least one workspace template.

### "Task stuck in pending"

Wait up to 5 minutes for initial provisioning. If still stuck:
- Check Coder server logs
- Verify template is configured correctly
- Check resource quotas

---

## Next Steps

- Read `POWER.md` for complete documentation
- Review `steering/task-workflow.md` for task creation details
- Review `steering/workspace-ops.md` for workspace operations
- Follow `TESTING-PLAN.md` for comprehensive testing

---

## Support

- Coder Documentation: https://coder.com/docs
- Kiro Documentation: https://kiro.dev/docs
- MCP Configuration: https://kiro.dev/docs/mcp/configuration/

---

**You're ready to go! Create your first task and start working in governed Coder workspaces.**
