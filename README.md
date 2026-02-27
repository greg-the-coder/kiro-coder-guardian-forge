# Kiro Coder Guardian Forge

A Kiro Power that connects Kiro agents to Coder deployments, enabling agents to work inside governed, auditable workspaces. Every agent operation runs as a Coder Task — visible in the Coder Tasks UI — with full lifecycle tracking and infrastructure isolation.

## Key Features

- **Agent-Ready Workspaces:** Create Coder Tasks that provision workspaces for agent work
- **Work Transfer Pattern:** Task workspaces are ephemeral - work automatically transfers back to your home workspace
- **Agent Collaboration:** External Kiro agents can collaborate with workspace agents (Claude Code, Cursor, etc.)
- **Full Visibility:** All operations tracked in Coder Tasks UI
- **No CLI Required:** Uses Coder's remote HTTP MCP server
- **Governed & Auditable:** All work runs inside your Coder infrastructure with policy enforcement
- **Zero Configuration:** Template-based automatic setup for developers

## What's Included

- **POWER.md** - Kiro Power definition with onboarding and tool reference
- **WORK-TRANSFER-PATTERN.md** - Complete guide for transferring work from task to home workspace
- **setup.sh** - Automatic MCP configuration script
- **coder-template-example.tf** - Template code for automatic setup
- **steering/task-workflow.md** - Creating and monitoring Coder Tasks with work transfer
- **steering/workspace-ops.md** - Running commands and editing files in workspaces
- **steering/agent-interaction.md** - Collaborating with workspace agents

## Agent Collaboration Patterns

This power enables four collaboration patterns between external Kiro agents and workspace agents:

1. **Orchestrator** - External agent coordinates, workspace agent implements
2. **Delegator** - Workspace agent does most work, external agent monitors
3. **Hybrid** - Both agents work in parallel on different aspects
4. **Iterative** - Agents refine work together in iterations

## Quick Start

### For Coder Administrators (One-Time Setup)

**This power expects template-based MCP configuration.** Add this to your workspace template:

```hcl
resource "coder_agent" "dev" {
  startup_script = <<-EOT
    # ... your existing startup commands ...
    
    # Kiro MCP Configuration
    mkdir -p ~/.kiro/settings
    cat > ~/.kiro/settings/mcp.json << 'MCPEOF'
{
  "mcpServers": {
    "coder": {
      "url": "$${CODER_URL}api/experimental/mcp/http",
      "headers": {
        "Authorization": "Bearer $${CODER_SESSION_TOKEN}"
      },
      "autoApprove": ["coder_workspace_edit_file", "coder_workspace_read_file", "coder_get_task_status"]
    }
  }
}
MCPEOF
    sed -i "s|\$${CODER_URL}|$${CODER_URL}|g" ~/.kiro/settings/mcp.json
    sed -i "s|\$${CODER_SESSION_TOKEN}|$${CODER_SESSION_TOKEN}|g" ~/.kiro/settings/mcp.json
  EOT
}
```

See `coder-template-example.tf` for complete example.

### For Developers (Zero Configuration)

**If your workspace template includes MCP configuration (expected):**

1. Start your Coder workspace (MCP configured automatically)
2. Open Kiro
3. Verify "coder" MCP server is connected in MCP Servers panel
4. Start creating tasks!

**If your template doesn't include MCP configuration (fallback):**

```bash
# Run the setup script
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh

# Restart Kiro
# Then start using the power
```

## Documentation

- **POWER.md** - Complete power documentation with enhanced troubleshooting
- **setup.sh** - Automatic configuration script with health checks
- **coder-template-example.tf** - Template integration example with error handling
- **WORKSPACE-LIFECYCLE-GUIDE.md** - Guide for managing workspace lifecycle and costs
- **MCP-STABILITY-NOTES.md** - MCP connection stability guide
- **RECOMMENDED-SOLUTION.md** - Architecture and design decisions
- **QUICK-START.md** - 5-minute quick start guide
- **CHANGELOG.md** - Version history and changes

## Prerequisites

- Coder deployment with `mcp-server-http` experiment enabled
- Workspace template configured with automatic MCP setup (see Quick Start)
- At least one additional workspace template for creating tasks

## Configuration

**Expected: Template-based (zero configuration for developers)**

When your workspace template includes the MCP configuration, developers get automatic setup with no manual steps required.

**Fallback: Manual setup script**

If your template doesn't include MCP configuration, developers can run:
```bash
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh
```

**No personal API tokens needed** - uses `CODER_SESSION_TOKEN` automatically available in workspaces.

## Status

✅ Production ready with template-based configuration  
✅ Zero-configuration setup for developers (when template configured)  
✅ Uses secure session tokens (no personal API tokens)  
✅ Tested and stable MCP connection  
✅ Agent interaction patterns documented  
✅ Token-efficient work transfer methods  

## License

See LICENSE file for details.
