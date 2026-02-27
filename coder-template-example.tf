# Example Coder Workspace Template with Kiro MCP Auto-Configuration and AI Task Support
# This template is designed for AI agent work with proper task lifecycle management

terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

resource "coder_agent" "dev" {
  arch = "amd64"
  os   = "linux"
  
  # Your existing agent configuration...
  
  # Add this startup script to automatically configure Kiro MCP
  startup_script = <<-EOT
    #!/bin/bash
    set -e
    
    # Your existing startup script commands...
    
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
MCPEOF
    
    # Substitute actual environment variable values
    # Note: Using | as delimiter to avoid conflicts with / in URLs
    sed -i "s|\${CODER_URL}|${CODER_URL}|g" ~/.kiro/settings/mcp.json
    sed -i "s|\${CODER_SESSION_TOKEN}|${CODER_SESSION_TOKEN}|g" ~/.kiro/settings/mcp.json
    
    echo "✅ Kiro MCP configuration created at ~/.kiro/settings/mcp.json"
    echo "   Server: coder"
    echo "   URL: ${CODER_URL}api/experimental/mcp/http"
    echo "   Auth: Session token"
    
    # Your remaining startup script commands...
  EOT
}

# ============================================
# AI Task Resource (REQUIRED for this power)
# ============================================

resource "coder_ai_task" "main" {
  agent_id = coder_agent.dev.id
  
  # Task identification
  display_name = "AI Development Task"
  description  = "Ephemeral workspace for AI agent development work"
  
  # Task lifecycle settings
  timeout_minutes = 120  # Auto-stop after 2 hours of inactivity
  auto_stop       = true # Automatically stop when task completes
  
  # Optional: Resource limits for task workspaces
  # max_cpu    = "2"
  # max_memory = "4Gi"
}

# ============================================
# Template Metadata (Optional but Recommended)
# ============================================

# Add metadata to help identify this as a task-ready template
resource "coder_metadata" "template_info" {
  resource_id = coder_ai_task.main.id
  
  item {
    key   = "template_type"
    value = "ai-task"
  }
  
  item {
    key   = "supports_ai_agents"
    value = "true"
  }
  
  item {
    key   = "kiro_compatible"
    value = "true"
  }
}

# ============================================
# Alternative: Separate Script for MCP Setup
# ============================================

# You can also configure MCP as a separate script for better organization
resource "coder_script" "kiro_mcp_setup" {
  agent_id     = coder_agent.dev.id
  display_name = "Configure Kiro MCP"
  icon         = "/icon/kiro.svg"
  script = <<-EOT
    #!/bin/bash
    set -e
    
    echo "🔧 Configuring Kiro MCP for Coder..."
    
    mkdir -p ~/.kiro/settings
    
    cat > ~/.kiro/settings/mcp.json << 'MCPEOF'
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
MCPEOF
    
    sed -i "s|\${CODER_URL}|${CODER_URL}|g" ~/.kiro/settings/mcp.json
    sed -i "s|\${CODER_SESSION_TOKEN}|${CODER_SESSION_TOKEN}|g" ~/.kiro/settings/mcp.json
    
    echo "✅ Kiro MCP configuration complete"
  EOT
  
  run_on_start = true
  run_on_stop  = false
  timeout      = 30
}
