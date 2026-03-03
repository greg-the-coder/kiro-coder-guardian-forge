# Task-Ready Templates for Kiro Coder Guardian Forge

## Overview

As of version 2.4.0, Kiro Coder Guardian Forge requires templates that define a `coder_ai_task` resource. This ensures templates are specifically designed for AI agent work with proper task lifecycle management.

## What is a Task-Ready Template?

A task-ready template is a Coder workspace template that includes a `coder_ai_task` resource in its Terraform configuration. This resource provides:

- Proper task lifecycle management in Coder Tasks UI
- Automatic progress tracking and reporting
- Task-specific resource limits and policies
- Better visibility and auditability
- Optimization for AI agent workflows

## Required Resource

### Minimal Configuration

```hcl
resource "coder_ai_task" "main" {
  agent_id = coder_agent.dev.id
  
  display_name = "AI Development Task"
  description  = "Ephemeral workspace for AI agent development work"
}
```

### Recommended Configuration

```hcl
resource "coder_ai_task" "main" {
  agent_id = coder_agent.dev.id
  
  # Task identification
  display_name = "AI Development Task"
  description  = "Ephemeral workspace for AI agent development work"
  
  # Task lifecycle settings
  timeout_minutes = 120  # Auto-stop after 2 hours of inactivity
  auto_stop       = true # Automatically stop when task completes
  
  # Optional: Resource limits for task workspaces
  max_cpu    = "2"
  max_memory = "4Gi"
}
```

## Complete Template Example

See `coder-template-example.tf` for a complete example that includes:

1. **Coder Agent** with MCP configuration
2. **AI Task Resource** (required)
3. **Template Metadata** (optional but recommended)

Key sections:

```hcl
# 1. Agent with MCP configuration
resource "coder_agent" "dev" {
  arch = "amd64"
  os   = "linux"
  
  startup_script = <<-EOT
    # ... MCP configuration script ...
  EOT
}

# 2. AI Task Resource (REQUIRED)
resource "coder_ai_task" "main" {
  agent_id        = coder_agent.dev.id
  display_name    = "AI Development Task"
  description     = "Ephemeral workspace for AI agent work"
  timeout_minutes = 120
  auto_stop       = true
}

# 3. Template Metadata (OPTIONAL)
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
```

## Identifying Task-Ready Templates

When calling `coder_list_templates`, task-ready templates typically:

1. **Include "task" or "ai-task" in the name**
   - Examples: `python-ai-task`, `go-task-dev`, `node-ai-workspace`

2. **Have descriptions mentioning AI agent support**
   - "AI agent development workspace"
   - "Task-ready environment for AI work"
   - "Ephemeral workspace for agent tasks"

3. **Include metadata indicating task support**
   - `template_type: "ai-task"`
   - `supports_ai_agents: "true"`
   - `kiro_compatible: "true"`

## Benefits of Task-Ready Templates

### For AI Agents

- **Proper lifecycle management**: Tasks are tracked from creation to completion
- **Progress visibility**: Task state visible in Coder Tasks UI
- **Automatic cleanup**: Tasks can auto-stop when work completes
- **Resource limits**: Prevent runaway resource consumption

### For Administrators

- **Better governance**: Task-specific policies and limits
- **Cost control**: Automatic timeouts and resource caps
- **Auditability**: Complete task history and tracking
- **Visibility**: All AI agent work visible in Tasks UI

### For Developers

- **Clear separation**: Task workspaces vs. development workspaces
- **Ephemeral by design**: No confusion about workspace purpose
- **Automatic cleanup**: No manual workspace management needed
- **Better organization**: Tasks grouped and tracked separately

## Migration Guide

### For Coder Administrators

**Step 1: Update existing templates**

Add the `coder_ai_task` resource to templates you want to use for AI agent work:

```hcl
resource "coder_ai_task" "main" {
  agent_id        = coder_agent.dev.id
  display_name    = "AI Development Task"
  description     = "Ephemeral workspace for AI agent work"
  timeout_minutes = 120
  auto_stop       = true
}
```

**Step 2: Add metadata (optional but recommended)**

Help agents identify task-ready templates:

```hcl
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
}
```

**Step 3: Update template names/descriptions**

Make it clear which templates are task-ready:
- Name: `python-dev` → `python-ai-task`
- Description: "Python development" → "Python development with AI task support"

**Step 4: Test the template**

1. Create a test task using the updated template
2. Verify task appears in Coder Tasks UI
3. Verify task lifecycle (start, work, stop) functions correctly
4. Verify auto-stop and timeout settings work as expected

### For Developers

**No action required** - once administrators update templates, you can use them immediately.

**To verify a template is task-ready:**

```bash
# List templates
coder templates list

# Look for templates with "task" or "ai-task" in name
# Or check template description for AI agent support
```

## Troubleshooting

### Problem: "No task-ready templates found"

**Cause:** No templates in your Coder deployment define `coder_ai_task` resource

**Solution:**
1. Ask your Coder administrator to create task-ready templates
2. Provide them with `coder-template-example.tf` from this power
3. Wait for administrator to update templates

### Problem: "Template doesn't appear in task-ready list"

**Cause:** Template missing `coder_ai_task` resource or metadata

**Solution:**
1. Verify template includes `coder_ai_task` resource
2. Add metadata to help with identification
3. Update template name/description to indicate task support

### Problem: "Task doesn't appear in Coder Tasks UI"

**Cause:** Template missing `coder_ai_task` resource

**Solution:**
1. Verify template was created with `coder_create_task` (not `coder_create_workspace`)
2. Check template includes `coder_ai_task` resource
3. Verify Coder server has Tasks UI enabled

## Best Practices

### Template Design

1. **Use descriptive names**: Include "task" or "ai-task" in template name
2. **Set reasonable timeouts**: 60-120 minutes for most tasks
3. **Enable auto-stop**: Prevent resource waste
4. **Set resource limits**: Prevent runaway consumption
5. **Add metadata**: Help agents identify task-ready templates

### Resource Limits

```hcl
resource "coder_ai_task" "main" {
  agent_id = coder_agent.dev.id
  
  # Recommended limits for AI agent work
  timeout_minutes = 120      # 2 hours
  max_cpu         = "2"      # 2 CPU cores
  max_memory      = "4Gi"    # 4GB RAM
  auto_stop       = true     # Auto-stop when complete
}
```

### Naming Conventions

**Good template names:**
- `python-ai-task`
- `go-task-dev`
- `node-ai-workspace`
- `java-agent-task`

**Avoid:**
- `python-dev` (not clear it's for tasks)
- `workspace-1` (too generic)
- `test-template` (not descriptive)

### Template Organization

**Separate templates for different purposes:**
- Development workspaces: Long-lived, persistent
- Task workspaces: Ephemeral, auto-stop enabled
- Testing workspaces: Isolated, resource-limited

**Don't mix purposes** - use dedicated templates for AI agent tasks.

## FAQ

**Q: Can I use regular templates for tasks?**

A: No, as of version 2.4.0, only templates with `coder_ai_task` resource are supported.

**Q: What happens to existing tasks created with old templates?**

A: Existing tasks continue to work, but new tasks must use task-ready templates.

**Q: Can I convert a regular template to task-ready?**

A: Yes, add the `coder_ai_task` resource to the template's Terraform configuration.

**Q: Do I need separate templates for different languages?**

A: Recommended but not required. You can have language-specific task templates (python-ai-task, go-ai-task) or a general-purpose task template.

**Q: What's the difference between task and development workspaces?**

A: Task workspaces are ephemeral (auto-stop, timeouts) and designed for AI agent work. Development workspaces are long-lived and designed for human developers.

**Q: Can I use the same template for both tasks and development?**

A: Not recommended. Use separate templates optimized for each purpose.

## Additional Resources

- **coder-template-example.tf** - Complete template example
- **POWER.md** - Main power documentation
- **steering/task-workflow.md** - Task creation workflow
- **Coder Documentation** - https://coder.com/docs

---

**Summary:** Task-ready templates with `coder_ai_task` resources provide proper lifecycle management, better governance, and optimized workflows for AI agent work. Administrators should create dedicated task templates, and agents will automatically filter for task-ready templates when creating tasks.
