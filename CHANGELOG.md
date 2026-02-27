# Changelog

All notable changes to Kiro Coder Guardian Forge are documented in this file.

## [2.4.0] - 2026-02-27 - Task-Ready Template Requirement

### Changed

**This power now requires templates that define a `coder_ai_task` resource.**

This ensures templates are specifically designed for AI agent work with proper task lifecycle management.

**What changed:**
- Template selection now filters for task-ready templates
- Documentation updated to explain `coder_ai_task` requirement
- Template example updated to include `coder_ai_task` resource
- Troubleshooting updated with guidance for missing task-ready templates

**Benefits:**
- ✅ Proper task lifecycle management in Coder Tasks UI
- ✅ Automatic progress tracking and reporting
- ✅ Task-specific resource limits and policies
- ✅ Better visibility and auditability
- ✅ Optimized for AI agent workflows

**Task-ready template requirements:**
```hcl
resource "coder_ai_task" "main" {
  agent_id        = coder_agent.dev.id
  display_name    = "AI Development Task"
  description     = "Ephemeral workspace for AI agent work"
  timeout_minutes = 120
  auto_stop       = true
}
```

**Migration:**
- Coder administrators must add `coder_ai_task` resource to templates
- See `coder-template-example.tf` for complete example
- Existing templates without `coder_ai_task` will not be usable for tasks

**Files updated:**
- POWER.md - Added "Task-Ready Templates" section
- README.md - Updated prerequisites and quick start
- steering/task-workflow.md - Updated template selection workflow
- coder-template-example.tf - Added `coder_ai_task` resource and metadata
- CHANGELOG.md - This entry

---

## [2.3.0] - 2026-02-27 - Documentation Consolidation & Power Builder Compliance

### Changed

**Major documentation restructuring to comply with power-builder standards:**

- **POWER.md** - Complete rewrite with streamlined structure
  - Enhanced frontmatter with proper power name (`kiro-coder-guardian-forge`)
  - Consolidated onboarding section (removed redundancy)
  - Clearer configuration section
  - Organized tools by category (Task Management, Workspace Operations, Discovery)
  - Streamlined troubleshooting with error code table
  - Better integration with steering files

- **README.md** - Streamlined project overview
  - Clearer feature list
  - Simplified quick start
  - Better documentation organization
  - Removed redundant content

- **CHANGELOG.md** - Consolidated version history
  - Merged redundant entries
  - Clearer version progression
  - Better categorization

**File organization:**
- Moved development/historical docs to `docs/` directory:
  - All *-SUMMARY.md files
  - All *-PLAN.md files
  - REQUIREMENTS.md
  - MIGRATION-*.md files
  - Historical issue tracking files

- Removed redundant files:
  - AGENT-INTERACTION-QUICK-REF.md (content in steering file)
  - QUICK-SETUP-REFERENCE.md (redundant with QUICK-START.md)
  - TOKEN-EFFICIENCY-GUIDE.md (merged into WORK-TRANSFER-PATTERN.md)
  - MCP-STABILITY-NOTES.md (merged into troubleshooting)
  - WORKSPACE-LIFECYCLE-GUIDE.md (merged into best practices)

**Final structure:**
```
kiro-coder-guardian-forge/
├── POWER.md                    # Main power documentation
├── README.md                   # Project overview
├── CHANGELOG.md                # Version history
├── QUICK-START.md              # 5-minute guide
├── WORK-TRANSFER-PATTERN.md    # Critical pattern doc
├── setup.sh                    # Setup script
├── coder-template-example.tf   # Template example
├── steering/                   # Workflow guides
│   ├── task-workflow.md
│   ├── workspace-ops.md
│   └── agent-interaction.md
└── docs/                       # Historical/development docs
```

### Benefits

- ✅ Complies with power-builder standards
- ✅ Clearer documentation structure
- ✅ Easier to navigate and maintain
- ✅ Reduced redundancy
- ✅ Better separation of user vs. development docs

---

## [2.2.2] - 2026-02-27 - Template-Based Configuration Emphasis

### Changed

**Updated documentation to emphasize template-based MCP configuration as the expected setup method.**

- Reordered onboarding to show template-based configuration first
- Moved manual setup to "Fallback" section
- Added "Why Template-Based Configuration?" section
- Clarified that manual setup is only for fallback scenarios

### Rationale

Template-based configuration provides:
- Zero configuration for developers
- Consistent setup across organization
- Automatic updates on workspace restart
- Better security with session tokens

---

## [2.2.1] - 2026-02-27 - Token Efficiency Optimization

### Added

**Token-efficient work transfer methods to minimize context usage:**

1. **Git Patch Transfer** (recommended for git projects)
   - Token usage: 1-10KB (only diffs)
   - Savings: 90-99% vs. file-by-file
   - Works with unlimited file sizes

2. **Bash Direct Transfer** (recommended for non-git)
   - Token usage: ~100 bytes (only commands)
   - Savings: 99.9% vs. file-by-file
   - Zero file content in agent context

### Changed

- Updated WORK-TRANSFER-PATTERN.md with token-efficient methods
- Reordered patterns by efficiency
- Added token usage comparison table
- Enhanced best practices with token guidance

### Benefits

- 90-99% reduction in token usage
- No context window overflow
- Handles projects of any size
- Significantly lower API costs

---

## [2.2.0] - 2026-02-27 - Work Transfer Pattern

### Added

**Fundamental work transfer pattern:** Task workspaces are ephemeral execution environments. Home workspace (where Kiro runs) is the permanent source of truth.

- New file: WORK-TRANSFER-PATTERN.md (complete implementation guide)
- Transfer workflow: Identify → Read → Write → Verify → Commit → Stop
- Checkpoint pattern for long tasks
- Failure recovery with work salvage

### Changed

- Updated task-workflow.md with 6-step transfer process
- Updated POWER.md best practices
- Updated README.md with work transfer concept

### Breaking Change

Work MUST be transferred to home workspace before stopping task workspaces. Previous behavior allowed work to remain in task workspace.

### Benefits

- No work lost when task workspaces are deleted
- Clear data flow pattern
- Supports incremental development
- Complete audit trail in home workspace

---

## [2.1.0] - 2026-02-27 - Usability & Reliability Improvements

### Enhanced

- **setup.sh**: Backup existing config, expanded auto-approval (17 tools), health checks
- **coder-template-example.tf**: Expanded auto-approval, better error handling
- **POWER.md**: Comprehensive error code reference, diagnostic workflows
- **task-workflow.md**: Optimal polling intervals, workspace name extraction patterns

### Added

- WORKSPACE-LIFECYCLE-GUIDE.md (resource management)
- 8 additional auto-approved tools
- Connection health check commands
- CloudFront/CDN-specific guidance

### Benefits

- Improved reliability with backups and verification
- Better user experience with expanded auto-approval
- Faster troubleshooting with error reference
- Cost optimization guidance

---

## [2.0.0] - 2026-02-26 - Template-Based Configuration

### Breaking Changes

- Removed mcp.json from power (now template-based)
- Changed to session token authentication (from personal API tokens)
- Configuration approach changed to template-based generation

### Added

- Template-based automatic configuration
- setup.sh script for manual setup
- coder-template-example.tf for admins
- Session token authentication

### Benefits

- Zero configuration for developers
- Higher rate limits with session tokens
- Better security (auto-rotated tokens)
- Easier maintenance
- More reliable (no environment variable expansion issues)

---

## [1.1.0] - 2026-02-26 - Agent Interaction Enhancements

### Added

- **steering/agent-interaction.md**: Complete guide for workspace agent collaboration
- Four collaboration patterns: Orchestrator, Delegator, Hybrid, Iterative
- `coder_send_task_input` and `coder_get_task_logs` usage patterns
- Monitoring and troubleshooting guidance

### Use Cases Enabled

- Delegation: External agent delegates to workspace agent
- Orchestration: External agent coordinates, workspace agent implements
- Hybrid: Both agents work in parallel
- Iterative: Agents refine work together

---

## [1.0.1] - 2026-02-26 - Task State Management Corrections

### Fixed

- Removed non-existent `coder_report_task` tool from documentation
- Clarified that task state is managed by workspace agents (internal)
- External agents monitor via `coder_get_task_status` (read-only)

### Changed

- Updated POWER.md, REQUIREMENTS.md, task-workflow.md
- Renamed hook from "Report Task Complete" to "Stop Workspace"
- Simplified workflows to focus on monitoring vs. reporting

---

## [1.0.0] - 2026-02-26 - Initial Release

### Added

- Core power functionality
- Task creation and monitoring
- Workspace operations (commands, files)
- MCP server integration
- Comprehensive documentation
- Steering files for workflows
- Setup automation

### Features

- Agent-Ready Workspaces as Coder Tasks
- Full lifecycle tracking in Coder Tasks UI
- Governed and auditable operations
- Remote HTTP MCP server (no CLI required)
