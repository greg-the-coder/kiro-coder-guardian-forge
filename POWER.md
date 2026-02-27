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

**For Coder Administrators:**
- Coder server must be started with the `mcp-server-http` experiment enabled:
  ```bash
  CODER_EXPERIMENTS="oauth2,mcp-server-http" coder server
  ```
- At least one workspace template configured

**For Developers:**
- Access to a Coder workspace (the power works inside Coder workspaces)
- No manual configuration needed if admin has set up the template (see below)

### Setup Options

#### Option A: Automatic Setup (Recommended for Admins)

**For Coder administrators:** Add automatic MCP configuration to your workspace templates so developers get zero-configuration setup.

Add this to your Coder workspace template's agent startup script:

```hcl
resource "coder_agent" "dev" {
  # ... your existing agent config ...
  
  startup_script = <<-EOT
    #!/bin/bash
    
    # Your existing startup commands...
    
    # ============================================
    # Kiro Coder Guardian Forge MCP Configuration
    # ============================================
    
    echo "🔧 Configuring Kiro MCP for Coder..."
    
    # Create Kiro settings directory
    mkdir -p ~/.kiro/settings
    
    # Create MCP configuration with environment variables
    cat > ~/.kiro/settings/mcp.json << 'MCPEOF'
{
  "mcpServers": {
    "coder": {
      "url": "$${CODER_URL}api/experimental/mcp/http",
      "headers": {
        "Authorization": "Bearer $${CODER_SESSION_TOKEN}"
      },
      "autoApprove": [
        "coder_workspace_edit_file",
        "coder_workspace_read_file",
        "coder_get_task_status",
        "coder_workspace_write_file",
        "coder_workspace_ls",
        "coder_workspace_bash",
        "coder_get_task_logs",
        "coder_list_templates",
        "coder_create_task"
      ]
    }
  }
}
MCPEOF
    
    # Substitute actual environment variable values
    sed -i "s|\$${CODER_URL}|$${CODER_URL}|g" ~/.kiro/settings/mcp.json
    sed -i "s|\$${CODER_SESSION_TOKEN}|$${CODER_SESSION_TOKEN}|g" ~/.kiro/settings/mcp.json
    
    echo "✅ Kiro MCP configuration created at ~/.kiro/settings/mcp.json"
    
    # Your remaining startup commands...
  EOT
}
```

**See `coder-template-example.tf` in this power for a complete example.**

**Benefits:**
- ✅ Zero configuration for developers
- ✅ Works automatically in every workspace
- ✅ Uses secure session tokens (no personal API tokens needed)
- ✅ Credentials never committed to version control
- ✅ Automatically updated when workspace restarts

#### Option B: Manual Setup (For Developers)

If your Coder admin hasn't configured automatic setup, you can configure manually:

**Step 1: Run the setup script**

This power includes a setup script that automatically configures the MCP server:

```bash
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh
```

The script will:
- Detect your Coder workspace environment
- Create the MCP configuration using `CODER_SESSION_TOKEN`
- Configure auto-approval for common tools

**Step 2: Restart Kiro**

After running the setup script, restart Kiro to connect to the Coder MCP server:
- Reload the Kiro window, or
- Restart the Kiro process

**Step 3: Verify connection**

Check the MCP Servers panel in Kiro - you should see the "coder" server connected.

Test the connection by calling `coder_get_authenticated_user` to verify you're authenticated.

### Why Session Tokens?

This power uses `CODER_SESSION_TOKEN` (automatically available in Coder workspaces) instead of personal API tokens because:

- ✅ **Higher rate limits** - No 429 errors during normal use
- ✅ **Automatically managed** - Rotated by Coder, no manual token generation
- ✅ **Secure** - Scoped to the current user session
- ✅ **Zero configuration** - Already injected into workspace environment

## MCP Server Configuration

This Power connects to Coder's remote HTTP MCP server at:
```
${CODER_URL}/api/experimental/mcp/http
```

**Configuration is template-based** - the MCP server configuration is created automatically when your workspace starts (if your admin has configured the template) or via the `setup.sh` script.

**Why remote HTTP MCP server:**
- No Coder CLI installation required
- No `coder login` or local session management
- Works seamlessly inside Coder workspaces
- Token-based auth is explicit and auditable
- Session tokens are automatically rotated by Coder

**Configuration file location:**
```
~/.kiro/settings/mcp.json
```

This file is created automatically and contains your actual Coder URL and session token. It should not be committed to version control.

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
- **CRITICAL: Transfer work from task workspace to home workspace before stopping** (see below)
- Always stop workspaces after work is complete to free resources
- Use dedicated file tools instead of bash `cat`/`echo`/`heredoc`
- Set appropriate timeouts for `coder_workspace_bash` based on operation type

**Work Transfer Pattern (NEW):**

The home workspace (where Kiro is running) is the permanent source of truth. Task workspaces are ephemeral execution environments. Always transfer work back to the home workspace before stopping:

1. **Identify changed files** in task workspace (use git diff or find)
2. **Read files** from task workspace using `coder_workspace_read_file`
3. **Write files** to home workspace using `coder_workspace_write_file`
4. **Verify transfer** succeeded
5. **Commit in home workspace** (if using git)
6. **Then stop** task workspace

**For long tasks:** Transfer at checkpoints (end of phases, before breaks) to avoid losing progress if something fails.

**See `WORK-TRANSFER-PATTERN.md` for complete implementation details.**

**Collaboration Patterns:**
- **Orchestrator:** You coordinate, workspace agent implements specific tasks
- **Delegator:** Send comprehensive prompt, workspace agent does most work
- **Hybrid:** You handle infrastructure, workspace agent handles business logic
- **Iterative:** You and workspace agent refine work together in iterations

## Troubleshooting

### Connection Issues

**Problem:** "Failed to connect to Coder MCP server"

**Solutions:**
1. Verify you're running inside a Coder workspace: `echo $CODER_URL`
2. Check session token is available: `echo ${CODER_SESSION_TOKEN:0:10}...`
3. Run the setup script: `bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh`
4. Restart Kiro to reconnect
5. Confirm admin enabled `mcp-server-http` experiment on server

**Problem:** "Unauthorized" or "Invalid token"

**Solutions:**
1. Session token may have expired - restart your workspace
2. Run setup script again to get fresh token: `bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh`
3. Restart Kiro to pick up new configuration

**Problem:** MCP server not listed in Kiro

**Solutions:**
1. Check if config file exists: `cat ~/.kiro/settings/mcp.json`
2. If missing, run setup script: `bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh`
3. Verify config has actual values (not `${VAR}` placeholders)
4. Restart Kiro to load the configuration

**Problem:** Rate limiting (429 errors)

**Cause:** Too many connection attempts in a short time

**Solutions:**
1. Wait 5-10 minutes for rate limit to reset
2. Verify you're using session token (not personal API token)
3. Check Coder server logs for rate limit configuration
4. Contact Coder admin to increase MCP endpoint rate limits

### Common Error Codes

**401 Unauthorized**
- Session token expired or invalid
- Solution: Restart workspace to get fresh token, then run setup.sh

**403 Forbidden**
- User doesn't have permission for the operation
- Solution: Check Coder RBAC settings for your user role

**404 Not Found**
- Workspace or task doesn't exist
- Solution: Verify workspace name format: `owner/workspace-name`
- Use `coder_list_workspaces` to find correct workspace name

**429 Too Many Requests**
- Rate limit exceeded
- Solution: Wait 5-10 minutes, ensure using session token (not personal API token)
- Check with Coder admin about rate limit configuration

**502/503 Bad Gateway/Service Unavailable**
- Coder server or proxy issue
- Solution: Check Coder server health, verify `mcp-server-http` experiment enabled
- If using CloudFront or other CDN, check CDN health
- Review Coder server logs for errors

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

### Connection Health Check

**Quick Test:**
```bash
# Test authentication
curl -s -H "Authorization: Bearer ${CODER_SESSION_TOKEN}" \
  "${CODER_URL}api/v2/users/me" | jq -r '.username'
# Should output: your-username
```

**Full Diagnostic:**
```bash
# 1. Check environment
env | grep CODER_

# 2. Check config
cat ~/.kiro/settings/mcp.json

# 3. Test API
curl -s -H "Authorization: Bearer ${CODER_SESSION_TOKEN}" \
  "${CODER_URL}api/v2/users/me"

# 4. Test MCP endpoint
curl -s -X POST \
  -H "Authorization: Bearer ${CODER_SESSION_TOKEN}" \
  -H "Content-Type: application/json" \
  "${CODER_URL}api/experimental/mcp/http" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}'
```

**In Kiro:**
1. Call `coder_get_authenticated_user` → Verify auth
2. Call `coder_list_templates` → Verify API access
3. Call `coder_list_workspaces` → Verify workspace access
4. Call `coder_list_tasks` → Verify task access

All should succeed. If any fail, check specific permissions.

## Configuration

**Template-based configuration (recommended):**
- Add MCP config generation to your Coder workspace template
- See `coder-template-example.tf` for implementation
- Developers get automatic zero-configuration setup

**Manual configuration (fallback):**
- Run `setup.sh` script in the power directory
- Configuration created at `~/.kiro/settings/mcp.json`
- Restart Kiro to connect

**No additional configuration required** after setup - the MCP server connects automatically when Kiro starts.

---

**MCP Server:** coder (remote HTTP)
**Endpoint:** `${CODER_URL}/api/experimental/mcp/http`
**Authentication:** Bearer token via `CODER_SESSION_TOKEN`
**Configuration:** Template-based (see `setup.sh` or `coder-template-example.tf`)
