# Kiro Coder Guardian Forge

A Kiro Power that connects Kiro agents to Coder deployments, enabling agents to work inside governed, auditable workspaces. Every agent operation runs as a Coder Task — visible in the Coder Tasks UI — with full lifecycle tracking and infrastructure isolation.

## Key Features

- **Agent-Ready Workspaces:** Create Coder Tasks that provision workspaces for agent work
- **Agent Collaboration:** External Kiro agents can collaborate with workspace agents (Claude Code, Cursor, etc.)
- **Full Visibility:** All operations tracked in Coder Tasks UI
- **No CLI Required:** Uses Coder's remote HTTP MCP server
- **Governed & Auditable:** All work runs inside your Coder infrastructure with policy enforcement

## What's Included

- **POWER.md** - Kiro Power definition with onboarding and tool reference
- **mcp.json** - Remote MCP server configuration (no CLI installation needed)
- **steering/task-workflow.md** - Creating and monitoring Coder Tasks
- **steering/workspace-ops.md** - Running commands and editing files in workspaces
- **steering/agent-interaction.md** - Collaborating with workspace agents
- **AGENT-INTERACTION-QUICK-REF.md** - Quick reference for agent collaboration patterns

## Agent Collaboration Patterns

This power enables four collaboration patterns between external Kiro agents and workspace agents:

1. **Orchestrator** - External agent coordinates, workspace agent implements
2. **Delegator** - Workspace agent does most work, external agent monitors
3. **Hybrid** - Both agents work in parallel on different aspects
4. **Iterative** - Agents refine work together in iterations

## Quick Start

1. Set environment variables:
   ```bash
   export CODER_URL="https://coder.mycompany.com/"
   export CODER_TOKEN="<your-token>"
   ```

2. Install the power in Kiro

3. Start using:
   - "Create a Coder task to implement feature X"
   - "Send a prompt to the workspace agent to implement the API"
   - "Monitor the workspace agent progress"

## Documentation

- **REQUIREMENTS.md** - Product requirements and specifications
- **TESTING-PLAN.md** - Comprehensive testing plan
- **EXECUTION-PLAN.md** - Step-by-step testing execution guide
- **QUICK-START.md** - 5-minute quick start guide
- **CHANGELOG.md** - Version history and changes
- **AGENT-INTERACTION-QUICK-REF.md** - Quick reference for agent collaboration

## Prerequisites

- Coder deployment with `mcp-server-http` experiment enabled
- Coder personal API token
- At least one workspace template configured

## Status

✅ Prototype complete and tested
✅ End-to-end acceptance test passed
✅ Agent interaction patterns documented
✅ Ready for production use

## License

See LICENSE file for details.
