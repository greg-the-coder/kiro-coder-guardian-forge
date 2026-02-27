#!/bin/bash
set -e

echo "🔧 Setting up Kiro Coder Guardian Forge MCP configuration..."
echo ""

# Check if running in Coder workspace
if [ -z "$CODER_URL" ]; then
  echo "❌ Error: CODER_URL environment variable not set"
  echo "This power requires running inside a Coder workspace"
  echo ""
  echo "If you're in a Coder workspace, try:"
  echo "  source ~/.bashrc  # or ~/.zshrc"
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

# Backup existing config if present
if [ -f ~/.kiro/settings/mcp.json ]; then
  BACKUP_FILE=~/.kiro/settings/mcp.json.backup.$(date +%Y%m%d_%H%M%S)
  cp ~/.kiro/settings/mcp.json "$BACKUP_FILE"
  echo "📦 Backed up existing config to: $BACKUP_FILE"
fi

# Remove trailing slash from CODER_URL if present
CODER_URL_CLEAN="${CODER_URL%/}"

# Create MCP configuration with actual values
cat > ~/.kiro/settings/mcp.json << EOF
{
  "mcpServers": {
    "coder": {
      "url": "${CODER_URL_CLEAN}/api/experimental/mcp/http",
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
        "coder_create_task",
        "coder_get_authenticated_user",
        "coder_delete_task",
        "coder_send_task_input",
        "coder_list_workspaces",
        "coder_workspace_edit_files",
        "coder_workspace_list_apps",
        "coder_workspace_port_forward",
        "coder_create_workspace_build",
        "coder_template_version_parameters"
      ]
    }
  }
}
EOF

# Verify config was created
if [ ! -f ~/.kiro/settings/mcp.json ]; then
  echo "❌ Failed to create MCP configuration"
  exit 1
fi

echo "✅ Created MCP configuration at ~/.kiro/settings/mcp.json"
echo ""
echo "Configuration details:"
echo "  Server: coder"
echo "  URL: ${CODER_URL_CLEAN}/api/experimental/mcp/http"
echo "  Auth: Bearer token (session token)"
echo "  Auto-approved tools: 17"
echo ""

# Test connection (optional but helpful)
echo "🧪 Testing connection..."
if command -v curl &> /dev/null; then
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer ${CODER_SESSION_TOKEN}" \
    "${CODER_URL_CLEAN}/api/v2/users/me")
  
  if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Connection test successful (HTTP $HTTP_CODE)"
  else
    echo "⚠️  Connection test returned HTTP $HTTP_CODE"
    echo "   This may be normal - verify after restarting Kiro"
  fi
else
  echo "⚠️  curl not found - skipping connection test"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Restart Kiro to connect to the Coder MCP server"
echo "  2. Check MCP Servers panel to verify 'coder' server is connected"
echo "  3. Try calling coder_get_authenticated_user to test the connection"
echo ""
