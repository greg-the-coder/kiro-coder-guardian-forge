# Kiro Coder Guardian Forge

A Kiro Power that connects Kiro agents to Coder deployments, enabling agents to work inside governed, auditable workspaces. Every agent operation runs as a Coder Task with full lifecycle tracking and infrastructure isolation.

## Key Features

- **Agent-Ready Workspaces** - Create Coder Tasks that provision workspaces for agent work
- **Work Transfer Pattern** - Ephemeral task workspaces with automatic transfer to permanent home workspace
- **Agent Collaboration** - External Kiro agents collaborate with workspace agents (Claude Code, Cursor, etc.)
- **Full Visibility** - All operations tracked in Coder Tasks UI
- **Zero Configuration** - Template-based automatic setup for developers
- **No CLI Required** - Uses Coder's remote HTTP MCP server
- **Governed & Auditable** - All work runs inside your Coder infrastructure with policy enforcement

## Quick Start

### For Coder Administrators (One-Time Setup)

Add MCP configuration and AI task resource to your workspace template. See `coder-template-example.tf` for complete example:

```hcl
resource "coder_agent" "dev" {
  startup_script = <<-EOT
    # Create Kiro MCP configuration
    mkdir -p ~/.kiro/settings
    cat > ~/.kiro/settings/mcp.json << 'MCPEOF'
{
  "mcpServers": {
    "coder": {
      "url": "${CODER_URL}api/experimental/mcp/http",
      "headers": {
        "Authorization": "Bearer ${CODER_SESSION_TOKEN}"
      },
      "autoApprove": ["coder_workspace_edit_file", "coder_workspace_read_file", "coder_get_task_status"]
    }
  }
}
MCPEOF
    sed -i "s|\${CODER_URL}|${CODER_URL}|g" ~/.kiro/settings/mcp.json
    sed -i "s|\${CODER_SESSION_TOKEN}|${CODER_SESSION_TOKEN}|g" ~/.kiro/settings/mcp.json
  EOT
}

# REQUIRED: AI Task resource for task lifecycle management
resource "coder_ai_task" "main" {
  agent_id        = coder_agent.dev.id
  display_name    = "AI Development Task"
  description     = "Ephemeral workspace for AI agent work"
  timeout_minutes = 120
  auto_stop       = true
}
```

### For Developers (Zero Configuration)

**If your workspace template includes MCP configuration:**

1. Start your Coder workspace (MCP configured automatically)
2. Open Kiro
3. Verify "coder" MCP server is connected in MCP Servers panel
4. Start creating tasks!

**If your template doesn't include MCP configuration:**

```bash
# Run the setup script
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh

# Restart Kiro
```

## Core Concepts

### Home Workspace vs Task Workspace

- **Home Workspace** - Where Kiro runs; permanent source of truth for all project work
- **Task Workspace** - Ephemeral execution environment; work is transferred back to home workspace

### Work Transfer Pattern

Work is transferred from task workspaces to home workspace via git operations:

1. Task workspace commits and pushes to feature branch
2. Home workspace fetches and merges feature branch
3. Task workspace stopped automatically
4. Feature branch cleaned up (optional)

**Automated via `complete_task_with_cleanup()` function:**
- 90% faster than manual file copying (2 min vs 20 min)
- Standard git operations (commit, push, fetch, merge)
- Full git history preserved
- Automatic workspace cleanup

See `WORK-TRANSFER-PATTERN.md` for complete implementation and `steering/task-workflow.md` for the automation function.

### Agent Collaboration

External Kiro agents can collaborate with workspace agents (Claude Code, Cursor) using:
- `coder_send_task_input` - Send prompts to workspace agent
- `coder_get_task_logs` - Monitor workspace agent activity
- `coder_get_task_status` - Check task state

Four collaboration patterns: Orchestrator, Delegator, Hybrid, Iterative

## Documentation

### Core Files
- **POWER.md** - Complete power documentation with tool reference
- **README.md** - This file
- **QUICK-START.md** - 5-minute quick start guide
- **CHANGELOG.md** - Version history

### Implementation Guides
- **WORK-TRANSFER-PATTERN.md** - Git-based work transfer pattern (v3.2)
- **QUICK-REFERENCE-V3.2.md** - Quick copy-paste examples for v3.2 features
- **coder-template-example.tf** - Template configuration example
- **setup.sh** - Manual configuration script (fallback)

### Steering Files (Loaded On-Demand)
- **steering/task-workflow.md** - Creating and monitoring Coder Tasks
- **steering/workspace-ops.md** - Running commands and managing files
- **steering/agent-interaction.md** - Collaborating with workspace agents

### Development Documentation
- **docs/** - Historical and development documentation

## Prerequisites

- Coder deployment with `mcp-server-http` experiment enabled
- Workspace template with automatic MCP setup
- **At least one task-ready template** that defines a `coder_ai_task` resource

## Status

✅ Production ready with template-based configuration  
✅ Zero-configuration setup for developers (when template configured)  
✅ Uses secure session tokens (no personal API tokens)  
✅ Tested and stable MCP connection  
✅ Agent collaboration patterns documented  
✅ Automated git-based work transfer (90% faster)  
✅ Comprehensive validation and quality gates  
✅ Parallel task coordination patterns  

**Version:** 3.2.0 - See `CHANGELOG.md` for latest enhancements  

## License

See LICENSE file for details.
