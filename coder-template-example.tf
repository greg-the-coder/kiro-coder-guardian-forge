# Example Coder Workspace Template with Kiro MCP Auto-Configuration and AI Task Support
# This template supports both home workspaces and task workspaces with git worktrees

terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

# ============================================
# Template Parameters
# ============================================

variable "feature_branch" {
  description = "Git feature branch for this task (task workspaces only)"
  type        = string
  default     = ""
}

variable "home_workspace" {
  description = "Home workspace name in format owner/workspace (task workspaces only)"
  type        = string
  default     = ""
}

variable "project_path" {
  description = "Path to project directory"
  type        = string
  default     = "/workspaces/project"
}

variable "git_repo_url" {
  description = "Git repository URL (home workspace only)"
  type        = string
  default     = "https://github.com/org/project.git"
}

# ============================================
# Shared Storage for Git Repository
# ============================================

# For home workspace: Create shared storage for .git directory
resource "kubernetes_persistent_volume_claim" "git_storage" {
  count = var.feature_branch == "" ? 1 : 0  # Only for home workspace
  
  metadata {
    name      = "git-storage-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = data.coder_workspace.me.namespace
  }
  
  spec {
    access_modes = ["ReadWriteMany"]  # Multiple workspaces can access
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

# ============================================
# Coder Agent
# ============================================

resource "coder_agent" "dev" {
  arch = "amd64"
  os   = "linux"
  
  startup_script = <<-EOT
    #!/bin/bash
    set -e
    
    # ============================================
    # Kiro Coder Guardian Forge MCP Configuration
    # ============================================
    
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
        "coder_create_task"
      ]
    }
  }
}
MCPEOF
    
    sed -i "s|\${CODER_URL}|${CODER_URL}|g" ~/.kiro/settings/mcp.json
    sed -i "s|\${CODER_SESSION_TOKEN}|${CODER_SESSION_TOKEN}|g" ~/.kiro/settings/mcp.json
    
    echo "✅ Kiro MCP configuration created"
    
    # ============================================
    # Git Worktree Setup (Task Workspaces Only)
    # ============================================
    
    if [ -n "${var.feature_branch}" ]; then
      echo "🌿 Setting up git worktree for task workspace..."
      
      FEATURE_BRANCH="${var.feature_branch}"
      HOME_WORKSPACE="${var.home_workspace}"
      PROJECT_PATH="${var.project_path}"
      SHARED_GIT_DIR="/mnt/shared-git/.git"
      WORKTREE_PATH="/workspaces/task-workspace"
      
      # Wait for shared git directory
      echo "Waiting for shared git directory..."
      timeout 60 bash -c "until [ -d '$SHARED_GIT_DIR' ]; do sleep 1; done"
      
      # Create worktree
      mkdir -p "$WORKTREE_PATH"
      GIT_DIR="$SHARED_GIT_DIR" git worktree add "$WORKTREE_PATH" "$FEATURE_BRANCH"
      
      # Configure git
      cd "$WORKTREE_PATH"
      git config user.name "Kiro Agent"
      git config user.email "kiro@coder.com"
      
      echo "✅ Git worktree ready at $WORKTREE_PATH on branch $FEATURE_BRANCH"
    fi
  EOT
}

# ============================================
# Git Clone (Home Workspace Only)
# ============================================

resource "coder_git_clone" "project" {
  count = var.feature_branch == "" ? 1 : 0  # Only for home workspace
  
  agent_id = coder_agent.dev.id
  url      = var.git_repo_url
  path     = var.project_path
}

# ============================================
# AI Task Resource (Task Workspaces Only)
# ============================================

resource "coder_ai_task" "main" {
  count = var.feature_branch != "" ? 1 : 0  # Only for task workspace
  
  agent_id = coder_agent.dev.id
  
  display_name    = "AI Development Task"
  description     = "Ephemeral workspace for AI agent work on ${var.feature_branch}"
  timeout_minutes = 120
  auto_stop       = true
}

# ============================================
# Template Metadata
# ============================================

resource "coder_metadata" "template_info" {
  count       = var.feature_branch != "" ? 1 : 0  # Only for task workspace
  resource_id = coder_ai_task.main[0].id
  
  item {
    key   = "template_type"
    value = "ai-task"
  }
  
  item {
    key   = "supports_git_worktree"
    value = "true"
  }
  
  item {
    key   = "feature_branch"
    value = var.feature_branch
  }
}
