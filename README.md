# Kiro Coder Guardian Forge

A Kiro Power that connects Kiro agents to Coder deployments, enabling agents to work inside governed, auditable workspaces. Every agent operation runs as a Coder Task — visible in the Coder Tasks UI — with full lifecycle tracking and infrastructure isolation.

## Key Features

- **Agent-Ready Workspaces:** Create Coder Tasks that provision workspaces for agent work
- **Agent Collaboration:** External Kiro agents can collaborate with workspace agents (Claude Code, Cursor, etc.)
- **Full Visibility:** All operations tracked in Coder Tasks UI
- **No CLI Required:** Uses Coder's remote HTTP MCP server
- **Governed & Auditable:** All work runs inside your Coder infrastructure with policy enforcement
- **Zero Configuration:** Template-based automatic setup for developers

## What's Included

- **POWER.md** - Kiro Power definition with onboarding and tool reference
- **setup.sh** - Automatic MCP configuration script
- **coder-template-example.tf** - Template code for automatic setup
- **steering/task-workflow.md** - Creating and monitoring Coder Tasks
- **steering/workspace-ops.md** - Running commands and editing files in workspaces
- **steering/agent-interaction.md** - Collaborating with workspace agents

## Agent Collaboration Patterns

This power enables four collaboration patterns between external Kiro agents and workspace agents:

1. **Orchestrator** - External agent coordinates, workspace agent implements
2. **Delegator** - Workspace agent does most work, external agent monitors
3. **Hybrid** - Both agents work in parallel on different aspects
4. **Iterative** - Agents refine work together in iterations

## Quick Start

### For Coder Administrators (Recommended)

Add automatic MCP configuration to your workspace template:

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

### For Developers (Manual Setup)

If your admin hasn't configured automatic setup:

```bash
# Run the setup script
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh

# Restart Kiro
# Then start using the power
```

## Documentation

- **POWER.md** - Complete power documentation
- **setup.sh** - Automatic configuration script
- **coder-template-example.tf** - Template integration example
- **MCP-STABILITY-NOTES.md** - MCP connection stability guide
- **RECOMMENDED-SOLUTION.md** - Architecture and design decisions
- **QUICK-START.md** - 5-minute quick start guide
- **CHANGELOG.md** - Version history and changes

## Prerequisites

- Coder deployment with `mcp-server-http` experiment enabled
- Running inside a Coder workspace (for automatic session token)
- At least one workspace template configured

## Configuration

**Template-based (recommended):** Zero configuration for developers when admin adds setup to template

**Manual (fallback):** Run `setup.sh` script and restart Kiro

**No personal API tokens needed** - uses `CODER_SESSION_TOKEN` automatically available in workspaces

## Status

✅ Production ready with template-based configuration
✅ Zero-configuration setup for developers
✅ Uses secure session tokens (no personal API tokens)
✅ Tested and stable MCP connection
✅ Agent interaction patterns documented

## License

See LICENSE file for details.
