---
name: "coder-guardian-forge"
displayName: "Coder Guardian Forge"
description: "Run Kiro agents in governed Coder workspaces. Creates Agent-Ready Workspaces as Coder Tasks — visible in the Coder Tasks UI — so all agent activity is tracked, auditable, and isolated inside your own infrastructure."
keywords: ["coder", "workspace", "task", "agent", "guardian", "forge", "regulated", "secure workspace", "remote workspace", "cloud workspace"]
author: "Coder"
---

# Coder Guardian Forge

## Overview

Coder Guardian Forge connects Kiro agents to your Coder deployment, enabling agents to work inside governed, auditable workspaces. Every agent operation runs as a Coder Task — visible in the Coder Tasks UI — so you get full lifecycle tracking, progress reporting, and infrastructure isolation without sacrificing agent autonomy.

This Power uses Coder's remote HTTP MCP server, so there's no CLI to install. Just set two environment variables (`CODER_URL` and `CODER_TOKEN`), and Kiro connects directly to your Coder deployment.

**Key capabilities:**
- Create Agent-Ready Workspaces as Coder Tasks with full UI visibility
- Run commands and edit files inside task workspaces
- Report progress to the Coder Tasks UI at each step
- Stop workspaces automatically when work completes or fails
- All operations are auditable and governed by your Coder policies

## Available Steering Files

This power has three steering files for different workflows:

- **task-workflow** - Creating and monitoring Coder Tasks (load when starting new work)
- **workspace-ops** - Running commands and editing files inside workspaces (load when doing actual work)
- **agent-interaction** - Collaborating with AI agents inside task workspaces (load when delegating work to workspace agents)

Call action "readSteering" to access specific workflows as needed.

## When to Load Steering Files

- Creating a new task or starting work on something → `steering/task-workflow.md`
- Running commands, reading or writing files inside a workspace → `steering/workspace-ops.md`
- Sending prompts to or monitoring workspace agents (Claude Code, Cursor, etc.) → `steering/agent-interaction.md`

## Onboarding

### Prerequisites

**Developer requirements:**
- Access to a Coder deployment with the `mcp-server-http` experiment enabled
- A Coder personal API token (from Coder web UI → Account → Tokens)
- At least one workspace template configured by your Coder admin

**Coder admin prerequisite (one-time):**
The Coder server must be started with the MCP HTTP experiment enabled:
```bash
CODER_EXPERIMENTS="oauth2,mcp-server-http" coder server
```

### Setup

**Step 1: Get your Coder API token**
1. Log into your Coder web UI
2. Navigate to **Account → Tokens**
3. Click **Generate Token**
4. Copy the token value

**Step 2: Set environment variables**

Add these to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):

```bash
export CODER_URL="https://coder.mycompany.com"   # Your Coder server URL
export CODER_TOKEN="<paste-your-token-here>"     # Token from Step 1
```

**Note:** If you're running Kiro inside a Coder workspace, `CODER_URL` is already injected into your environment. You only need to set `CODER_TOKEN`:
```bash
export CODER_TOKEN="<paste-your-token-here>"
```

Then reload your shell:
```bash
source ~/.zshrc  # or ~/.bashrc
```

**Step 3: Verify connection**

After installing this Power, I will automatically verify the connection by calling `coder_get_authenticated_user`. If successful, you'll see:

```
Connected to Coder as <username> at <server-url>. Ready to create agent tasks.
```

If the connection fails, check:
- `CODER_URL` is set correctly and points to your Coder server
- `CODER_TOKEN` is set to a valid token from the Coder web UI
- Your Coder admin has enabled the `mcp-server-http` experiment on the server

**Step 4: Check available templates**

I will list available workspace templates using `coder_list_templates`. If no templates are found, ask your Coder admin to configure at least one workspace template before tasks can be created.

**Step 5: Create task completion hook**

I will create a hook at `.kiro/hooks/coder-task-complete.kiro.hook` that you can trigger when work is complete. This hook will:
- Report the task as `idle` in the Coder Tasks UI with a summary
- Stop the workspace to free up resources

## MCP Server Configuration

This Power connects to Coder's remote HTTP MCP server at:
```
${CODER_URL}/api/experimental/mcp/http
```

Authentication uses the standard `Authorization: Bearer ${CODER_TOKEN}` header. Kiro expands the `${VAR}` references at runtime, so credentials are never hardcoded and `mcp.json` is safe to commit.

**Why remote over local CLI:**
- No Coder CLI installation required
- No `coder login` or local session management
- Works on any machine where Kiro runs
- Token-based auth is explicit and auditable
- Tokens can be scoped, rotated, or revoked from the Coder web UI

## Key Coder MCP Tools

| Tool | Purpose |
|---|---|
| `coder_get_authenticated_user` | Verify connection and show current user |
| `coder_list_templates` | Show available workspace templates |
| `coder_list_template_version_parameters` | Show template configuration options |
| `coder_create_task` | **Primary tool** — creates Coder Task with workspace |
| `coder_get_task_status` | Monitor task status (read-only, set by workspace agent) |
| `coder_get_task_logs` | Get workspace logs including agent activity and responses |
| `coder_list_tasks` | Find existing running tasks |
| `coder_send_task_input` | Send prompts/instructions to workspace agent (Claude Code, Cursor, etc.) |
| `coder_delete_task` | Clean up completed tasks |
| `coder_list_workspaces` | Look up workspace details |
| `coder_workspace_bash` | Run commands inside workspace |
| `coder_workspace_ls` | List directory contents |
| `coder_workspace_read_file` | Read file contents |
| `coder_workspace_write_file` | Write new file (base64-encoded) |
| `coder_workspace_edit_file` | Edit existing file with search/replace |
| `coder_workspace_edit_files` | Edit multiple files at once |
| `coder_workspace_list_apps` | Get URLs of running apps |
| `coder_workspace_port_forward` | Access ports not exposed as apps |
| `coder_create_workspace_build` | Stop workspace after completion |

**Note:** Task state (working, idle, failure) is managed by the agent running inside the workspace, not externally. Use `coder_get_task_status` to monitor the current state.

**Agent Interaction:** Use `coder_send_task_input` to send prompts to workspace agents (Claude Code, Cursor, etc.) and `coder_get_task_logs` to see their responses. This enables collaboration between external Kiro agents and workspace agents.

## Best Practices

- Always create tasks with `coder_create_task`, never use `coder_create_workspace` directly
- Wait for task workspace to be running before executing commands or file operations
- Monitor task status with `coder_get_task_status` to track workspace agent progress
- Use `coder_send_task_input` to delegate work to workspace agents (Claude Code, Cursor, etc.)
- Check `coder_get_task_logs` to see workspace agent responses and activity
- Always stop workspaces after work is complete to free resources
- Use dedicated file tools instead of bash `cat`/`echo`/`heredoc`
- Set appropriate timeouts for `coder_workspace_bash` based on operation type

**Collaboration Patterns:**
- **Orchestrator:** You coordinate, workspace agent implements specific tasks
- **Delegator:** Send comprehensive prompt, workspace agent does most work
- **Hybrid:** You handle infrastructure, workspace agent handles business logic
- **Iterative:** You and workspace agent refine work together in iterations

## Troubleshooting

### Connection Issues

**Problem:** "Failed to connect to Coder MCP server"

**Solutions:**
1. Verify `CODER_URL` is set: `echo $CODER_URL`
2. Verify `CODER_TOKEN` is set: `echo $CODER_TOKEN` (should show token)
3. Check URL format: includes `https://` or `http://`
4. Test token in browser: visit `${CODER_URL}/api/v2/users/me` with token in Authorization header
5. Confirm admin enabled `mcp-server-http` experiment on server

**Problem:** "Unauthorized" or "Invalid token"

**Solutions:**
1. Generate a new token from Coder web UI → Account → Tokens
2. Update `CODER_TOKEN` in your shell profile
3. Reload shell: `source ~/.zshrc`
4. Restart Kiro to pick up new environment variables

### Task Creation Issues

**Problem:** "No templates available"

**Solutions:**
1. Ask your Coder admin to create at least one workspace template
2. Verify you have permission to use templates: check Coder web UI → Templates
3. Try listing templates manually: call `coder_list_templates`

**Problem:** "Task stuck in pending/starting state"

**Solutions:**
1. Check Coder server logs for provisioning errors
2. Verify template is configured correctly
3. Check workspace resource quotas and limits
4. Wait up to 5 minutes for initial provisioning
5. If still stuck, report failure and delete the task

### Workspace Operation Issues

**Problem:** "Workspace not found"

**Solutions:**
1. Verify workspace name format: `owner/workspace-name`
2. Get correct name from `coder_get_task_logs` after task creation
3. Check workspace still exists: call `coder_list_workspaces`
4. Ensure task workspace is running: call `coder_get_task_status`

**Problem:** "Command timeout"

**Solutions:**
1. Increase `timeout_ms` for long-running operations
2. Use `background: true` for processes that don't need to complete immediately
3. Check workspace is responsive: try simple command like `pwd`
4. Review workspace logs in Coder UI for errors

## Configuration

**No additional configuration required** after setting `CODER_URL` and `CODER_TOKEN` environment variables.

The Power works immediately once:
1. Environment variables are set
2. Coder admin has enabled `mcp-server-http` experiment
3. At least one workspace template exists

---

**MCP Server:** coder (remote HTTP)
**Endpoint:** `${CODER_URL}/api/experimental/mcp/http`
**Authentication:** Bearer token via `${CODER_TOKEN}`
