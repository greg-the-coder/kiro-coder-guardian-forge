---
name: "kiro-coder-guardian-forge"
displayName: "Kiro Coder Guardian Forge"
description: "Run Kiro agents in governed Coder workspaces. Creates Agent-Ready Workspaces as Coder Tasks — visible in the Coder Tasks UI — so all agent activity is tracked, auditable, and isolated inside your own infrastructure."
keywords: ["coder", "workspace", "task", "agent", "guardian", "forge", "regulated", "secure workspace", "remote workspace", "cloud workspace"]
author: "Coder"
---

# Kiro Coder Guardian Forge

## Overview

Kiro Coder Guardian Forge connects Kiro agents to your Coder deployment, enabling agents to work inside governed, auditable workspaces. Every agent operation runs as a Coder Task — visible in the Coder Tasks UI — providing full lifecycle tracking, progress reporting, and infrastructure isolation.

This Power uses Coder's remote HTTP MCP server with no CLI installation required. The MCP configuration is automatically created by your Coder workspace template using session tokens for secure, zero-configuration setup.

**What this power enables:**
- Create Agent-Ready Workspaces as Coder Tasks with full UI visibility
- Execute commands and manage files inside task workspaces
- Collaborate with workspace agents (Claude Code, Cursor, etc.)
- Transfer work from ephemeral task workspaces to permanent home workspace
- Automatic progress reporting to Coder Tasks UI
- All operations auditable and governed by Coder policies

**Key pattern:** Task workspaces are ephemeral execution environments. Work is performed in task workspaces, then transferred back to your home workspace (where Kiro runs) for permanent storage.

## Available Steering Files

This power provides three steering files for different workflows. Load them on-demand based on your current task:

- **task-workflow.md** - Creating and monitoring Coder Tasks with work transfer patterns
- **workspace-ops.md** - Running commands and managing files inside workspaces  
- **agent-interaction.md** - Collaborating with AI agents inside task workspaces

**When to load:**
- Starting new work or creating a task → `task-workflow.md`
- Executing commands or file operations → `workspace-ops.md`
- Delegating to workspace agents (Claude Code, Cursor) → `agent-interaction.md`

**How to load:**
```
Call action "readSteering" with powerName="kiro-coder-guardian-forge", steeringFile="task-workflow.md"
```

## Onboarding

### Prerequisites

**Coder Administrators:**
- Coder server with `mcp-server-http` experiment enabled:
  ```bash
  CODER_EXPERIMENTS="mcp-server-http" coder server
  ```
- Workspace template with automatic MCP configuration (see Configuration section)
- **At least one task-ready template** that defines a `coder_ai_task` resource for AI agent work

**Developers:**
- Access to a Coder workspace with MCP configuration
- No manual setup required when template is properly configured

### Installation

**Step 1: Verify Template Configuration**

Check if your workspace has MCP configuration:
```bash
cat ~/.kiro/settings/mcp.json
```

If the file exists with Coder MCP server configuration, you're ready to go.

**Step 2: Verify Connection**

In Kiro:
1. Check MCP Servers panel - look for "coder" server
2. Server should show as connected
3. Test with: Call `coder_get_authenticated_user` tool

**Step 3: Start Using**

You're ready! Create your first task:
```
Load task-workflow.md steering file and create a Coder task
```

### Fallback: Manual Setup

If your workspace template doesn't include MCP configuration:

```bash
# Run the setup script
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh

# Restart Kiro to connect
```

The setup script creates `~/.kiro/settings/mcp.json` with your Coder URL and session token.

## Configuration

### Task-Ready Templates

**This power requires templates that define a `coder_ai_task` resource.** This ensures the template is specifically designed for AI agent work with proper task lifecycle management.

**What makes a template task-ready:**

A task-ready template must include a `coder_ai_task` resource in its Terraform configuration:

```hcl
resource "coder_ai_task" "main" {
  agent_id = coder_agent.dev.id
  
  # Task configuration
  display_name = "AI Development Task"
  description  = "Workspace for AI agent development work"
  
  # Optional: Task-specific settings
  timeout_minutes = 120
  auto_stop       = true
}
```

**Benefits of task-ready templates:**
- Proper task lifecycle management in Coder Tasks UI
- Automatic progress tracking and reporting
- Task-specific resource limits and policies
- Better visibility and auditability
- Optimized for AI agent workflows

**Identifying task-ready templates:**

When calling `coder_list_templates`, look for templates that:
- Include "task" or "ai-task" in the name
- Have descriptions mentioning AI agent support
- Are specifically designed for ephemeral agent work

**If no task-ready templates exist:**

Ask your Coder administrator to create one. See `coder-template-example.tf` in this power for a complete example that includes both MCP configuration and `coder_ai_task` resource definition.

### MCP Server Setup

This power connects to Coder's remote HTTP MCP server at:
```
${CODER_URL}/api/experimental/mcp/http
```

**Automatic Configuration (Recommended):**

The MCP configuration is created automatically by your Coder workspace template's startup script. The configuration file is created at `~/.kiro/settings/mcp.json` when your workspace starts.

**Template Configuration Example:**

See `coder-template-example.tf` in this power directory for a complete Terraform template example that includes automatic MCP setup.

**Key configuration details:**
- Uses `CODER_SESSION_TOKEN` for authentication (automatically available in workspaces)
- No personal API tokens needed
- Configuration refreshes on workspace restart
- Higher rate limits than personal tokens

**Manual Configuration (Fallback):**

If your template doesn't include MCP setup, run:
```bash
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh
```

Then restart Kiro to connect.

### Why Session Tokens?

Session tokens (`CODER_SESSION_TOKEN`) are preferred over personal API tokens because:
- Higher rate limits (no 429 errors)
- Automatically managed and rotated by Coder
- Scoped to current user session
- Zero manual configuration needed

### Why Remote HTTP MCP?

- No Coder CLI installation required
- No `coder login` or local session management  
- Works seamlessly inside Coder workspaces
- Token-based auth is explicit and auditable

## Available MCP Tools

### Task Management

| Tool | Purpose |
|------|---------|
| `coder_create_task` | Create Agent-Ready Workspace as Coder Task (primary tool) |
| `coder_get_task_status` | Monitor task status (set by workspace agent) |
| `coder_get_task_logs` | Get workspace logs and agent activity |
| `coder_send_task_input` | Send prompts to workspace agent (Claude Code, Cursor) |
| `coder_list_tasks` | Find existing tasks |
| `coder_delete_task` | Clean up completed tasks |

### Workspace Operations

| Tool | Purpose |
|------|---------|
| `coder_workspace_bash` | Execute commands in workspace |
| `coder_workspace_read_file` | Read file contents |
| `coder_workspace_write_file` | Write new file (base64-encoded) |
| `coder_workspace_edit_file` | Edit file with search/replace |
| `coder_workspace_edit_files` | Edit multiple files atomically |
| `coder_workspace_ls` | List directory contents |
| `coder_workspace_list_apps` | Get URLs of running apps |
| `coder_workspace_port_forward` | Access non-exposed ports |
| `coder_create_workspace_build` | Stop workspace (transition=stop) |

### Discovery & Configuration

| Tool | Purpose |
|------|---------|
| `coder_get_authenticated_user` | Verify connection and current user |
| `coder_list_templates` | Show available workspace templates |
| `coder_template_version_parameters` | Show template configuration options |
| `coder_list_workspaces` | Look up workspace details |

**Note:** Task state (working, idle, failure) is managed by the agent inside the workspace, not externally. External agents monitor state via `coder_get_task_status`.

## Best Practices

### Task Workflow
- Always create tasks with `coder_create_task` (never `coder_create_workspace`)
- **Only use task-ready templates** that define a `coder_ai_task` resource
- Wait for task workspace to reach "running" status before operations
- Monitor task status with `coder_get_task_status`
- Always stop workspaces after completion to free resources

### Work Sharing (Critical)
- **Home workspace is the source of truth** - contains main git repository
- **Task workspaces use git worktrees** - each on a feature branch
- **Share via git operations** - commit, push, merge (no file copying)
- Use `--no-ff` flag when merging to preserve history
- Always commit and push from task workspace before merging
- See `WORK-TRANSFER-PATTERN.md` for complete implementation

### Workspace Operations
- Use dedicated file tools instead of bash `cat`/`echo`/`heredoc`
- Set appropriate timeouts for `coder_workspace_bash` based on operation
- Verify operations succeeded before proceeding

### Agent Collaboration
- Use `coder_send_task_input` to delegate work to workspace agents
- Monitor progress with `coder_get_task_logs`
- Four patterns: Orchestrator, Delegator, Hybrid, Iterative
- See `steering/agent-interaction.md` for detailed patterns

## Work Sharing Pattern

**Git worktrees provide the optimal workflow for sharing work between home and task workspaces.**

### Architecture

- **Home workspace** contains the main git repository (cloned via `coder_git_clone`)
- **Task workspaces** use git worktrees pointing to feature branches
- Work is shared via standard git operations (commit, push, merge)
- No manual file copying needed

### Workflow

1. **Create feature branch** in home workspace
2. **Create task** with feature branch parameter
3. **Task workspace** initializes git worktree automatically
4. **Task commits** directly to feature branch
5. **Home workspace merges** feature branch when complete
6. **Clean up** and stop task workspace

### Benefits

- ✅ **Efficient** - No file copying, minimal tokens
- ✅ **Standard** - Uses familiar git workflows
- ✅ **Atomic** - Each task works on isolated branch
- ✅ **Auditable** - Complete git history preserved
- ✅ **Scalable** - Multiple tasks can work simultaneously

**See `WORK-TRANSFER-PATTERN.md` for complete implementation with code examples.**

## Troubleshooting

### Connection Issues

**Problem:** "Failed to connect to Coder MCP server"

**Solutions:**
1. Verify running in Coder workspace: `echo $CODER_URL`
2. Check session token available: `echo ${CODER_SESSION_TOKEN:0:10}...`
3. Run setup script: `bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh`
4. Restart Kiro
5. Confirm admin enabled `mcp-server-http` experiment

**Problem:** "Unauthorized" or "Invalid token"

**Solutions:**
1. Session token may have expired - restart workspace
2. Run setup script to get fresh token
3. Restart Kiro

**Problem:** MCP server not listed in Kiro

**Solutions:**
1. Check config exists: `cat ~/.kiro/settings/mcp.json`
2. Run setup script if missing
3. Verify config has actual values (not `${VAR}` placeholders)
4. Restart Kiro

### Rate Limiting

**Problem:** 429 errors

**Cause:** Too many requests

**Solutions:**
1. Wait 5-10 minutes for rate limit reset
2. Verify using session token (not personal API token)
3. Contact Coder admin about rate limit configuration

### Common Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| 401 | Unauthorized | Session token expired - restart workspace, run setup.sh |
| 403 | Forbidden | Check Coder RBAC permissions |
| 404 | Not Found | Verify workspace name format: `owner/workspace-name` |
| 429 | Rate Limited | Wait 5-10 minutes, ensure using session token |
| 502/503 | Server Issue | Check Coder server health, verify experiment enabled |

### Task Issues

**Problem:** "No templates available" or "No task-ready templates found"

**Solution:** 
1. Ask Coder admin to create a task-ready template with `coder_ai_task` resource
2. See `coder-template-example.tf` in this power for complete example
3. Template must include both MCP configuration and `coder_ai_task` resource

**Problem:** "Task stuck in pending/starting"

**Solutions:**
1. Wait up to 5 minutes for provisioning
2. Check Coder server logs
3. Verify template configured correctly
4. Check resource quotas

**Problem:** "Workspace not found"

**Solutions:**
1. Verify format: `owner/workspace-name`
2. Get name from `coder_get_task_logs` after creation
3. Check workspace exists: `coder_list_workspaces`

### Quick Health Check

**Test connection:**
```bash
curl -s -H "Authorization: Bearer ${CODER_SESSION_TOKEN}" \
  "${CODER_URL}api/v2/users/me" | jq -r '.username'
```

**In Kiro:**
1. Call `coder_get_authenticated_user` → Verify auth
2. Call `coder_list_templates` → Verify API access
3. Call `coder_list_workspaces` → Verify workspace access

## Additional Resources

- **QUICK-START.md** - 5-minute quick start guide
- **WORK-TRANSFER-PATTERN.md** - Complete work transfer implementation
- **coder-template-example.tf** - Template configuration example
- **steering/task-workflow.md** - Task creation and monitoring
- **steering/workspace-ops.md** - Workspace operations
- **steering/agent-interaction.md** - Agent collaboration patterns
- **CHANGELOG.md** - Version history

---

**MCP Server:** coder (remote HTTP)  
**Endpoint:** `${CODER_URL}/api/experimental/mcp/http`  
**Authentication:** Bearer token via `CODER_SESSION_TOKEN`  
**Configuration:** Template-based automatic setup (see `coder-template-example.tf`)
