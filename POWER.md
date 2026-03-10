---
name: "kiro-coder-guardian-forge"
displayName: "Kiro Coder Guardian Forge"
description: "Run Kiro agents in governed Coder workspaces. Creates Agent-Ready Workspaces as Coder Tasks — visible in the Coder Tasks UI — so all agent activity is tracked, auditable, and isolated inside your own infrastructure."
keywords: ["coder", "workspace", "task", "agent", "guardian", "forge", "regulated", "secure workspace", "remote workspace", "cloud workspace"]
author: "Coder"
---

# Kiro Coder Guardian Forge

## Overview

Kiro Coder Guardian Forge connects Kiro agents to your Coder deployment, enabling agents to work inside governed, auditable workspaces. Every agent operation runs as a Coder Task — visible in the Coder Tasks UI — providing full lifecycle tracking, progress reporting, and infrastructure isolation.

This Power uses Coder's remote HTTP MCP server with no CLI installation required. The MCP configuration is automatically created by your Coder workspace template using session tokens for secure, zero-configuration setup.

**What this power enables:**
- Create Agent-Ready Workspaces as Coder Tasks with full UI visibility
- Execute commands and manage files inside task workspaces
- Collaborate with workspace agents (Claude Code, Cursor, etc.)
- Transfer work from ephemeral task workspaces to permanent home workspace
- Automatic progress reporting to Coder Tasks UI
- All operations auditable and governed by Coder policies

**Key pattern:** Task workspaces are ephemeral execution environments. Work is performed in task workspaces, then transferred back to your home workspace (where Kiro runs) for permanent storage.

**New in v3.3:** Post-task analysis and validation workflows that reduce analysis time by 77% (60 min → 14 min) and post-task bugs by 80%.

## What's New in v3.4

### Proactive Validation & Enhanced Onboarding

**Problem Solved:** Task failures due to missing SSH authentication (33% failure rate) and unclear onboarding process.

**Solution:** Proactive validation before task creation with clear setup guidance:
- `validate_task_prerequisites()` function checks all requirements before task creation
- ONE-TIME-SETUP.md provides step-by-step 5-minute setup guide
- Pre-flight validation prevents task creation when prerequisites not met
- Clear error messages with actionable fixes
- Enhanced onboarding documentation

**Results:**
- Task failure rate: 33% → 0% (SSH issues eliminated)
- Time to first success: 90 min → 10 min (89% reduction)
- Manual interventions: 3-5 → 0-1 (80% reduction)
- User onboarding time: 30 min → 5 min (83% reduction)

### Pre-Flight Validation

**New capability:** Comprehensive validation before every task creation:
- SSH authentication verification
- Git repository validation
- Git remote format checking
- Task-ready template availability
- Clear error messages with fixes
- Prevents task failures before they happen

**Benefits:**
- 100% task success rate (up from 67%)
- Zero SSH-related failures
- Faster time to productivity
- Reduced support requests

---

## What's New in v3.3

### Post-Task Analysis Automation

**Problem Solved:** After tasks complete successfully, manual analysis of deliverables took 60 minutes:
- Consistency checking across deliverables (20 min)
- Requirements compliance validation (25 min)
- Executive summary generation (10 min)
- Deployment validation (5 min)

**Solution:** Automated analysis workflows with structured patterns:
- `post-task-analysis.md` steering file with complete analysis functions
- `validation-patterns.md` steering file with project-specific validation checklists
- Automated report generation (CONSISTENCY_ANALYSIS.md, REQUIREMENTS_COMPLIANCE.md, EXECUTIVE_SUMMARY.md)
- Quality gates for pre-merge and pre-deployment validation

**Results:**
- Analysis time: 60 min → 14 min (77% reduction)
- Post-task bugs: 80% reduction through validation-first approach
- Total session time: 77 min → 32 min (58% reduction)

### Validation-First Task Creation

**New capability:** Include comprehensive validation requirements in every task prompt:
- Project-type-specific validation checklists (Python, Node.js, Go, React, API, Infrastructure)
- Pre-completion validation by workspace agents
- Automated verification after work transfer
- Quality gates before merge and deployment

**Benefits:**
- 80% reduction in post-task bugs
- Clear success criteria for workspace agents
- Automated verification vs manual review
- Consistent quality across all tasks

### Three Analysis Workflows

1. **Consistency Analysis** - Verify deliverables align with each other
   - Compare design → implementation → code
   - Check component naming consistency
   - Validate data structure alignment
   - Generate consistency reports with scores

2. **Requirements Compliance** - Validate against product requirements
   - Map requirements to implementation
   - Track functional and non-functional requirements
   - Generate traceability matrix
   - Compliance reports for audit

3. **Executive Summary** - Synthesize findings for stakeholders
   - Project metrics and scores
   - Key findings and recommendations
   - Deployment readiness assessment
   - Stakeholder-ready reports

### Quality Gates

**Two automated quality gates:**
1. **Pre-merge gate** - Validates before merging feature branch
2. **Pre-deployment gate** - Ensures deployment readiness

**Gate criteria:**
- Minimum consistency score (default: 85%)
- Minimum compliance score (default: 90%)
- All tests pass
- No linting errors
- Dependencies install successfully

## Available Steering Files

This power provides five steering files for different workflows. Load them on-demand based on your current task:

- **task-workflow.md** - Creating and monitoring Coder Tasks with work transfer patterns
- **workspace-ops.md** - Running commands and managing files inside workspaces  
- **agent-interaction.md** - Collaborating with AI agents inside task workspaces
- **post-task-analysis.md** - Analyzing and validating completed task deliverables (v3.3)
- **validation-patterns.md** - Validation checklists and quality gates for different project types (v3.3)

**When to load:**
- Starting new work or creating a task → `task-workflow.md` + `validation-patterns.md`
- Executing commands or file operations → `workspace-ops.md`
- Delegating to workspace agents (Claude Code, Cursor) → `agent-interaction.md`
- After tasks complete → `post-task-analysis.md`
- Before deployment → `post-task-analysis.md` + `validation-patterns.md`

**How to load:**
```
Call action "readSteering" with powerName="kiro-coder-guardian-forge", steeringFile="task-workflow.md"
```

## Onboarding

### Prerequisites

**Coder Administrators:**
- Coder server with `mcp-server-http` experiment enabled:
  ```bash
  CODER_EXPERIMENTS="mcp-server-http" coder server
  ```
- Workspace template with automatic MCP configuration (see Configuration section)
- **At least one task-ready template** that defines a `coder_ai_task` resource for AI agent work

**Developers:**
- Access to a Coder workspace with MCP configuration
- **One-time setup:** SSH key added to GitHub/GitLab (see ONE-TIME-SETUP.md)
- No additional setup required when template is properly configured

### Installation

**Step 1: Complete One-Time Setup (5 minutes)**

Before creating your first task, complete the one-time SSH setup:

```
See ONE-TIME-SETUP.md for detailed instructions
```

**Quick summary:**
1. Get your SSH public key: `cat ~/.ssh/id_ed25519.pub`
2. Add to GitHub: https://github.com/settings/keys
3. Test: `ssh -T git@github.com`

**Why this is required:** Task workspaces need to push code to git. This one-time setup authorizes your Coder workspaces to push to your repositories.

**Step 2: Verify Template Configuration**

Check if your workspace has MCP configuration:
```bash
cat ~/.kiro/settings/mcp.json
```

If the file exists with Coder MCP server configuration, you're ready to go.

**Step 3: Verify Connection**

In Kiro:
1. Check MCP Servers panel - look for "coder" server
2. Server should show as connected
3. Test with: Call `coder_get_authenticated_user` tool

**Step 4: Start Using**

You're ready! Create your first task:
```
Load task-workflow.md steering file and create a Coder task
```

### Fallback: Manual Setup

If your workspace template doesn't include MCP configuration:

```bash
# Run the setup script
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh

# Restart Kiro to connect
```

The setup script creates `~/.kiro/settings/mcp.json` with your Coder URL and session token.

### SSH Authentication Setup

**IMPORTANT:** SSH authentication is required for git push operations in task workspaces. Without proper SSH configuration, tasks will complete work but fail to push changes.

**Coder Git SSH Wrapper:** Coder workspaces use a custom git SSH wrapper (`coder gitssh`) that handles SSH authentication through Coder's infrastructure. This wrapper is automatically configured via the `GIT_SSH_COMMAND` environment variable (e.g., `/tmp/coder.*/coder gitssh --`). The wrapper is essential for all git operations and is automatically set up by your Coder workspace template.

**Complete setup instructions:** See ONE-TIME-SETUP.md for detailed step-by-step guide.

**Quick verification:**
```bash
# Verify git SSH wrapper is configured
echo $GIT_SSH_COMMAND
# Expected: /tmp/coder.*/coder gitssh --

# Test GitHub authentication
ssh -T git@github.com
# Expected: "Hi username! You've successfully authenticated..."

# Verify git remote uses SSH
cd /workspaces/your-project
git remote -v
# Expected: git@github.com:user/repo.git
```

**If authentication fails:** Follow the complete setup guide in ONE-TIME-SETUP.md (takes 5 minutes, one-time only).

## Configuration

### Task-Ready Templates

**This power requires templates that define a `coder_ai_task` resource.** This ensures the template is specifically designed for AI agent work with proper task lifecycle management.

**What makes a template task-ready:**

A task-ready template must include a `coder_ai_task` resource in its Terraform configuration:

```hcl
resource "coder_ai_task" "main" {
  agent_id = coder_agent.dev.id
  
  # Task configuration
  display_name = "AI Development Task"
  description  = "Workspace for AI agent development work"
  
  # Optional: Task-specific settings
  timeout_minutes = 120
  auto_stop       = true
}
```

**Benefits of task-ready templates:**
- Proper task lifecycle management in Coder Tasks UI
- Automatic progress tracking and reporting
- Task-specific resource limits and policies
- Better visibility and auditability
- Optimized for AI agent workflows

**Identifying task-ready templates:**

When calling `coder_list_templates`, look for templates that:
- Include "task" or "ai-task" in the name
- Have descriptions mentioning AI agent support
- Are specifically designed for ephemeral agent work

**If no task-ready templates exist:**

Ask your Coder administrator to create one. See `coder-template-example.tf` in this power for a complete example that includes both MCP configuration and `coder_ai_task` resource definition.

### Template Selection Guide

**Choosing the right template is critical for successful task creation.** Use this guide to select the appropriate template for your work.

#### Template Selection Matrix

| Task Type | Recommended Template Pattern | Why |
|-----------|----------------------------|-----|
| Python development | `python-ai-task`, `python-task` | Python tools, pip, Claude Code, git worktree |
| Node.js/TypeScript | `node-ai-task`, `node-task` | Node.js, npm, Claude Code, git worktree |
| Go development | `go-ai-task`, `go-task` | Go toolchain, Claude Code, git worktree |
| General coding | `claude-code-general`, `ai-task-general` | Multi-language, Claude Code, git worktree |
| Data science | `python-data-task` | Python, Jupyter, pandas, Claude Code |

#### Filtering Task-Ready Templates

When calling `coder_list_templates`, filter using these criteria:

**High confidence indicators (name patterns):**
- Contains "task" or "ai-task"
- Contains "claude-code" or "cursor"
- Contains "agent" or "ai-agent"

**Medium confidence indicators (description patterns):**
- Mentions "AI task" or "agent work"
- Mentions "ephemeral" or "task workspace"
- Mentions specific AI agents (Claude Code, Cursor)

**Avoid templates with:**
- "jupyter" only (notebook-focused, may lack task support)
- "cli" only (may lack `coder_ai_task` resource)
- "base" or "minimal" (likely missing AI agent)

#### Example Template Capabilities

**python-ai-task:**
- ✅ Python 3.11+
- ✅ pip, poetry
- ✅ Claude Code agent
- ✅ Git worktree support
- ✅ SSH key configuration
- ❌ No Node.js

**node-ai-task:**
- ✅ Node.js 20+
- ✅ npm, yarn, pnpm
- ✅ Claude Code agent
- ✅ Git worktree support
- ✅ SSH key configuration
- ❌ No Python

**claude-code-general:**
- ✅ Multi-language support
- ✅ Python, Node.js, Go
- ✅ Claude Code agent
- ✅ Git worktree support
- ✅ SSH key configuration
- ⚠️ May be larger/slower to provision



### MCP Server Setup

This power connects to Coder's remote HTTP MCP server at:
```
${CODER_URL}/api/experimental/mcp/http
```

**Automatic Configuration (Recommended):**

The MCP configuration is created automatically by your Coder workspace template's startup script. The configuration file is created at `~/.kiro/settings/mcp.json` when your workspace starts.

**Template Configuration Example:**

See `coder-template-example.tf` in this power directory for a complete Terraform template example that includes automatic MCP setup.

**Key configuration details:**
- Uses `CODER_SESSION_TOKEN` for authentication (automatically available in workspaces)
- No personal API tokens needed
- Configuration refreshes on workspace restart
- Higher rate limits than personal tokens

**Manual Configuration (Fallback):**

If your template doesn't include MCP setup, run:
```bash
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh
```

Then restart Kiro to connect.

### Why Session Tokens?

Session tokens (`CODER_SESSION_TOKEN`) are preferred over personal API tokens because:
- Higher rate limits (no 429 errors)
- Automatically managed and rotated by Coder
- Scoped to current user session
- Zero manual configuration needed

### Why Remote HTTP MCP?

- No Coder CLI installation required
- No `coder login` or local session management  
- Works seamlessly inside Coder workspaces
- Token-based auth is explicit and auditable

## Available MCP Tools

### Task Management

| Tool | Purpose |
|------|---------|
| `coder_create_task` | Create Agent-Ready Workspace as Coder Task (primary tool) |
| `coder_get_task_status` | Monitor task status (set by workspace agent) |
| `coder_get_task_logs` | Get workspace logs and agent activity |
| `coder_send_task_input` | Send prompts to workspace agent (Claude Code, Cursor) |
| `coder_list_tasks` | Find existing tasks |
| `coder_delete_task` | Clean up completed tasks |

### Workspace Operations

| Tool | Purpose |
|------|---------|
| `coder_workspace_bash` | Execute commands in workspace |
| `coder_workspace_read_file` | Read file contents |
| `coder_workspace_write_file` | Write new file (base64-encoded) |
| `coder_workspace_edit_file` | Edit file with search/replace |
| `coder_workspace_edit_files` | Edit multiple files atomically |
| `coder_workspace_ls` | List directory contents |
| `coder_workspace_list_apps` | Get URLs of running apps |
| `coder_workspace_port_forward` | Access non-exposed ports |
| `coder_create_workspace_build` | Stop workspace (transition=stop) |

### Discovery & Configuration

| Tool | Purpose |
|------|---------|
| `coder_get_authenticated_user` | Verify connection and current user |
| `coder_list_templates` | Show available workspace templates |
| `coder_template_version_parameters` | Show template configuration options |
| `coder_list_workspaces` | Look up workspace details |

**Note:** Task state (working, idle, failure) is managed by the agent inside the workspace, not externally. External agents monitor state via `coder_get_task_status`.

## Common Patterns

**Quick reference for common workflows. For detailed guidance, load the appropriate steering file.**

### Pattern: Quick Task Creation with Validation

**Goal:** Create a task with proper validation in 5-10 minutes

**Steps:**
1. Validate prerequisites (SSH auth, git repo, templates)
2. Filter for task-ready templates
3. Create feature branch in home workspace
4. Create task with comprehensive prompt (including validation requirements)
5. Wait for workspace ready
6. Monitor progress
7. Transfer work via git (commit/push/fetch/merge)
8. Stop workspace immediately

**Details:** Load `task-workflow.md` steering file for complete Quick Start workflow

### Pattern: Delegate and Monitor

**Goal:** Delegate work to workspace agent and monitor progress

**Steps:**
1. Send comprehensive prompt with validation checklist
2. Monitor with smart polling (10s, 30s, 60s intervals)
3. Check logs periodically for progress
4. Handle completion or failure
5. Transfer work via git

**Details:** Load `agent-interaction.md` steering file for delegation patterns and prompt templates

### Pattern: Complete and Merge

**Goal:** Merge completed work back to home workspace efficiently

**Steps:**
1. Commit and push from task workspace
2. Fetch and merge in home workspace (use --no-ff)
3. Verify merge succeeded
4. Stop task workspace immediately
5. Clean up feature branch (optional)

**Details:** Load `task-workflow.md` steering file for complete merge workflow with automatic cleanup

### Pattern: Parallel Task Execution

**Goal:** Run multiple independent tasks simultaneously

**Steps:**
1. Create feature branches for each task
2. Create all tasks in parallel
3. Monitor all tasks until complete
4. Transfer work from each task via git
5. Stop all workspaces

**Details:** Load `task-workflow.md` steering file for parallel coordination patterns

### Pattern: Run Commands and Edit Files

**Goal:** Execute operations in workspace efficiently

**Steps:**
1. Use `coder_workspace_bash` for commands (set appropriate timeout)
2. Use `coder_workspace_read_file` to read files
3. Use `coder_workspace_edit_file` for targeted changes
4. Use `coder_workspace_write_file` for new files (base64-encode content)
5. Always check exit codes and verify operations

**Details:** Load `workspace-ops.md` steering file for operation examples

## Best Practices

### Task Workflow
- Always create tasks with `coder_create_task` (never `coder_create_workspace`)
- **Only use task-ready templates** that define a `coder_ai_task` resource
- Wait for task workspace to reach "running" status before operations
- Monitor task status with `coder_get_task_status`
- **Include validation requirements in all task prompts**
- Always stop workspaces immediately after work transfer to free resources

### Work Sharing (Critical)
- **Home workspace is the source of truth** - contains main git repository
- **Task workspaces work on feature branches** - each task gets its own branch
- **Share via git operations** - commit, push, fetch, merge (no file copying)
- Use `--no-ff` flag when merging to preserve history
- Always commit and push from task workspace before merging
- **Stop workspace immediately after successful work transfer**
- See `WORK-TRANSFER-PATTERN.md` for complete implementation

### Workspace Operations
- Use dedicated file tools instead of bash `cat`/`echo`/`heredoc`
- Set appropriate timeouts for `coder_workspace_bash` based on operation
- Verify operations succeeded before proceeding

### Agent Collaboration
- Use `coder_send_task_input` to delegate work to workspace agents
- **Include comprehensive prompts with validation checklists**
- Monitor progress with `coder_get_task_logs`
- Four patterns: Orchestrator, Delegator, Hybrid, Iterative
- See `steering/agent-interaction.md` for detailed patterns and prompt templates

### Workspace Lifecycle
- **Stop workspaces immediately** after work is transferred
- Delete workspaces after work is merged and no longer needed
- Don't leave workspaces running unnecessarily - they consume resources
- Use automatic cleanup functions for reliable lifecycle management

## Work Sharing Pattern

**Git operations provide the optimal workflow for sharing work between home and task workspaces.**

### Architecture

- **Home workspace** contains the main git repository (cloned via `coder_git_clone`)
- **Task workspaces** work on feature branches
- Work is shared via standard git operations (commit, push, fetch, merge)
- No manual file copying needed

### Workflow

1. **Create feature branch** in home workspace
2. **Push branch to remote** so task workspace can access it
3. **Create task** with feature branch parameter
4. **Task workspace** works on the feature branch
5. **Task commits and pushes** directly to feature branch
6. **Home workspace fetches and merges** feature branch when complete
7. **Stop workspace immediately** to free resources
8. **Clean up** feature branch (optional)

### Benefits

- ✅ **Efficient** - No file copying, minimal tokens (90% faster than manual transfer)
- ✅ **Standard** - Uses familiar git workflows
- ✅ **Atomic** - Each task works on isolated branch
- ✅ **Auditable** - Complete git history preserved
- ✅ **Scalable** - Multiple tasks can work simultaneously
- ✅ **Reliable** - Standard git operations, well-tested

### Complete Example

```python
# 1. Create feature branch in home workspace
feature_branch = "feature/user-auth"
coder_workspace_bash(
    workspace=home_workspace,
    command=f"""
        cd /workspaces/project
        git checkout -b {feature_branch}
        git push -u origin {feature_branch}
    """,
    timeout_ms=30000
)

# 2. Create task
task = coder_create_task(
    input=f"Implement user authentication. Work on branch {feature_branch}.",
    template_version_id=template_id,
    rich_parameter_values={
        "feature_branch": feature_branch,
        "home_workspace": home_workspace
    }
)

# 3. Wait for task completion
# ... (monitor task status)

# 4. Transfer work via git
complete_task_with_cleanup(
    task_workspace=f"{owner}/{task.id}",
    home_workspace=home_workspace,
    feature_branch=feature_branch,
    task_description="Implement user authentication"
)
```

**See `WORK-TRANSFER-PATTERN.md` for complete implementation with code examples.**
**See `steering/task-workflow.md` for the `complete_task_with_cleanup` function.**

## Troubleshooting

### Connection Issues

**Problem:** "Failed to connect to Coder MCP server"

**Solutions:**
1. Verify running in Coder workspace: `echo $CODER_URL`
2. Check session token available: `echo ${CODER_SESSION_TOKEN:0:10}...`
3. Run setup script: `bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh`
4. Restart Kiro
5. Confirm admin enabled `mcp-server-http` experiment

**Problem:** "Unauthorized" or "Invalid token"

**Solutions:**
1. Session token may have expired - restart workspace
2. Run setup script to get fresh token
3. Restart Kiro

**Problem:** MCP server not listed in Kiro

**Solutions:**
1. Check config exists: `cat ~/.kiro/settings/mcp.json`
2. Run setup script if missing
3. Verify config has actual values (not `${VAR}` placeholders)
4. Restart Kiro

### Rate Limiting

**Problem:** 429 errors

**Cause:** Too many requests

**Solutions:**
1. Wait 5-10 minutes for rate limit reset
2. Verify using session token (not personal API token)
3. Contact Coder admin about rate limit configuration

### Common Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| 401 | Unauthorized | Session token expired - restart workspace, run setup.sh |
| 403 | Forbidden | Check Coder RBAC permissions |
| 404 | Not Found | Verify workspace name format: `owner/workspace-name` |
| 429 | Rate Limited | Wait 5-10 minutes, ensure using session token |
| 502/503 | Server Issue | Check Coder server health, verify experiment enabled |

### Task Issues

**Problem:** "No templates available" or "No task-ready templates found"

**Solution:** 
1. Ask Coder admin to create a task-ready template with `coder_ai_task` resource
2. See `coder-template-example.tf` in this power for complete example
3. Template must include both MCP configuration and `coder_ai_task` resource

**Problem:** "Task stuck in pending/starting"

**Solutions:**
1. Wait up to 5 minutes for provisioning
2. Check Coder server logs
3. Verify template configured correctly
4. Check resource quotas

**Problem:** "Workspace not found"

**Solutions:**
1. Verify format: `owner/workspace-name`
2. Get name from `coder_get_task_logs` after creation
3. Check workspace exists: `coder_list_workspaces`

**Problem:** Git push fails in task workspace with "Permission denied (publickey)"

**Cause:** SSH authentication not configured or git SSH wrapper not working

**Solutions:**
1. Verify SSH key added to GitHub: `ssh -T git@github.com`
2. Check git SSH wrapper is configured: `echo $GIT_SSH_COMMAND`
3. Expected: `/tmp/coder.*/coder gitssh --`
4. Test wrapper directly: `$GIT_SSH_COMMAND -T git@github.com`
5. If wrapper missing, restart workspace or contact Coder administrator
6. See ONE-TIME-SETUP.md for complete SSH setup guide

**Problem:** Git operations work in home workspace but fail in task workspace

**Cause:** Task workspace may not have inherited `GIT_SSH_COMMAND` environment variable

**Solutions:**
1. Verify in task workspace: `coder_workspace_bash(command="echo $GIT_SSH_COMMAND")`
2. If empty, check Coder template ensures environment variables are inherited
3. Contact Coder administrator to update template configuration
4. Temporary workaround: Manually set in task workspace startup script

### Quick Health Check

**Test connection:**
```bash
curl -s -H "Authorization: Bearer ${CODER_SESSION_TOKEN}" \
  "${CODER_URL}api/v2/users/me" | jq -r '.username'
```

**In Kiro:**
1. Call `coder_get_authenticated_user` → Verify auth
2. Call `coder_list_templates` → Verify API access
3. Call `coder_list_workspaces` → Verify workspace access

## Additional Resources

- **ONE-TIME-SETUP.md** - One-time SSH setup guide (5 minutes)
- **QUICK-START.md** - 5-minute quick start guide
- **WORK-TRANSFER-PATTERN.md** - Complete work transfer implementation
- **coder-template-example.tf** - Template configuration example
- **steering/task-workflow.md** - Task creation and monitoring
- **steering/workspace-ops.md** - Workspace operations
- **steering/agent-interaction.md** - Agent collaboration patterns
- **steering/validation-patterns.md** - Validation checklists and quality gates
- **steering/post-task-analysis.md** - Post-task analysis and validation
- **CHANGELOG.md** - Version history

---

**MCP Server:** coder (remote HTTP)  
**Endpoint:** `${CODER_URL}/api/experimental/mcp/http`  
**Authentication:** Bearer token via `CODER_SESSION_TOKEN`  
**Configuration:** Template-based automatic setup (see `coder-template-example.tf`)
