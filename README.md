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

Add MCP configuration to your workspace template. See `coder-template-example.tf` for complete example:

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

All work performed in task workspaces must be transferred back to home workspace before stopping:

1. Identify changed files in task workspace
2. Read files from task workspace
3. Write files to home workspace
4. Verify transfer succeeded
5. Stop task workspace

See `WORK-TRANSFER-PATTERN.md` for complete implementation with token-efficient methods.

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
- **WORK-TRANSFER-PATTERN.md** - Complete work transfer implementation with code examples
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
- Workspace template configured with automatic MCP setup
- At least one additional workspace template for creating tasks

## Status

✅ Production ready with template-based configuration  
✅ Zero-configuration setup for developers (when template configured)  
✅ Uses secure session tokens (no personal API tokens)  
✅ Tested and stable MCP connection  
✅ Agent collaboration patterns documented  
✅ Token-efficient work transfer methods  

## License

See LICENSE file for details.
