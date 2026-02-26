#!/bin/bash
set -e

echo "🔧 Setting up Kiro Coder Guardian Forge MCP configuration..."
echo ""

# Check if running in Coder workspace
if [ -z "$CODER_URL" ]; then
  echo "❌ Error: CODER_URL environment variable not set"
  echo "This power requires running inside a Coder workspace"
  exit 1
fi

if [ -z "$CODER_SESSION_TOKEN" ]; then
  echo "❌ Error: CODER_SESSION_TOKEN environment variable not set"
  echo "This power requires running inside a Coder workspace"
  exit 1
fi

echo "✅ Detected Coder workspace environment"
echo "   CODER_URL: $CODER_URL"
echo "   CODER_SESSION_TOKEN: ${CODER_SESSION_TOKEN:0:10}..."
echo ""

# Create Kiro settings directory
mkdir -p ~/.kiro/settings
echo "✅ Created ~/.kiro/settings directory"

# Create MCP configuration with actual values
cat > ~/.kiro/settings/mcp.json << EOF
{
  "mcpServers": {
    "coder": {
      "url": "${CODER_URL}api/experimental/mcp/http",
      "headers": {
        "Authorization": "Bearer ${CODER_SESSION_TOKEN}"
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
EOF

echo "✅ Created MCP configuration at ~/.kiro/settings/mcp.json"
echo ""
echo "Configuration details:"
echo "  Server: coder"
echo "  URL: ${CODER_URL}api/experimental/mcp/http"
echo "  Auth: Bearer token (session token)"
echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Restart Kiro to connect to the Coder MCP server"
echo "  2. Check MCP Servers panel to verify 'coder' server is connected"
echo "  3. Try calling coder_get_authenticated_user to test the connection"
echo ""
