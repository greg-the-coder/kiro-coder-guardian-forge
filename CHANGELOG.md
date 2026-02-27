# Changelog

## 2026-02-27 - Usability and Reliability Improvements (v2.1.0)

### Enhanced

**Setup Script (`setup.sh`):**
- Added backup of existing configuration before overwriting
- Expanded auto-approval list from 9 to 17 tools for better workflow coverage
- Added connection health check with curl test
- Improved error messages with actionable guidance
- Added verification step to confirm config creation
- Better visual feedback with tool count display

**Template Example (`coder-template-example.tf`):**
- Expanded auto-approval list to match setup.sh (17 tools)
- Added error handling for directory creation
- Added verification step for config creation
- Fixed URL format to include proper path separator
- Improved output messages with more detail

**Documentation (`POWER.md`):**
- Added comprehensive error code reference (401, 403, 404, 429, 502, 503)
- Added connection health check section with curl commands
- Added full diagnostic workflow for troubleshooting
- Enhanced troubleshooting with specific solutions for each error type
- Added CloudFront/CDN-specific guidance

**Task Workflow (`steering/task-workflow.md`):**
- Added optimal polling intervals with clear timing guidance
- Added detailed workspace name extraction patterns (4 different patterns)
- Enhanced workspace connection details section
- Added rationale for polling intervals
- Improved clarity on when and how to poll

### Added

**New Documentation:**
- `WORKSPACE-LIFECYCLE-GUIDE.md` - Complete guide for managing workspace lifecycle
  - Decision tree for stop/delete/keep running
  - Resource cost considerations
  - Best practices by use case (quick fixes, development, long-running)
  - Automation recommendations
  - Cost optimization tips
  - Monitoring guidance

**Auto-Approved Tools (expanded from 9 to 17):**
- `coder_get_authenticated_user` - Connection verification
- `coder_delete_task` - Task cleanup
- `coder_send_task_input` - Agent collaboration
- `coder_list_workspaces` - Workspace discovery
- `coder_workspace_edit_files` - Batch file editing
- `coder_workspace_list_apps` - App discovery
- `coder_workspace_port_forward` - Port access
- `coder_create_workspace_build` - Workspace lifecycle
- `coder_template_version_parameters` - Template configuration

### Benefits

**Improved Reliability:**
- Configuration backup prevents accidental data loss
- Health checks catch connection issues early
- Better error messages reduce troubleshooting time
- Verification steps ensure proper setup

**Better User Experience:**
- Expanded auto-approval reduces friction
- Clear polling guidance prevents API overload
- Comprehensive error reference speeds problem resolution
- Lifecycle guide helps with resource management

**Cost Optimization:**
- Lifecycle guide helps users manage workspace costs
- Clear guidance on when to stop vs. keep running
- Resource consideration section educates on cost implications

**Enhanced Workflows:**
- More tools auto-approved means smoother agent operations
- Workspace name extraction patterns reduce confusion
- Health check commands enable proactive monitoring

### Migration Notes

**For existing users:**
- Run the updated setup.sh to get expanded auto-approval list
- Review WORKSPACE-LIFECYCLE-GUIDE.md for cost optimization tips
- No breaking changes - all existing configurations continue to work

**For new users:**
- Setup script now provides better feedback and verification
- More tools work without manual approval
- Better error messages guide through any issues

---

## 2026-02-26 - Template-Based Configuration (v2.0.0)

### Breaking Changes
- **Removed `mcp.json` from power** - Configuration is now template-based
- **Changed authentication method** - Now uses `CODER_SESSION_TOKEN` instead of personal API tokens
- **Configuration approach changed** - From environment variables to template-based generation

### Added
- **Template-based automatic configuration** - Zero-config setup for developers
- **`setup.sh` script** - Automatic MCP configuration for manual setup
- **`coder-template-example.tf`** - Complete Terraform example for admins
- **`MCP-STABILITY-NOTES.md`** - Comprehensive stability and troubleshooting guide
- **`RECOMMENDED-SOLUTION.md`** - Architecture decisions and implementation details
- **`IMPLEMENTATION-SUMMARY.md`** - Quick reference for the new approach
- **Session token authentication** - Uses `CODER_SESSION_TOKEN` for better security and rate limits

### Changed
- **POWER.md** - Complete rewrite of onboarding section with template-based approach
- **POWER.md** - Updated MCP Server Configuration section
- **POWER.md** - Revised troubleshooting section for new configuration method
- **README.md** - Updated with template-based quick start instructions
- **Authentication** - Switched from personal API tokens to session tokens

### Fixed
- **Environment variable expansion issue** - Kiro doesn't support `${VAR}` in mcp.json
- **Rate limiting (429 errors)** - Session tokens have higher rate limits than personal tokens
- **URL construction issues** - Proper handling of trailing slashes in CODER_URL
- **Configuration reliability** - Template-based approach ensures consistent setup across workspaces

### Removed
- **`mcp.json`** - No longer included in power (configuration is template-based)
- **Personal API token requirement** - No longer needed for authentication
- **Manual environment variable setup** - Replaced with automatic configuration

### Benefits
- ✅ Zero configuration for developers (with template approach)
- ✅ Higher rate limits (session tokens vs personal tokens)
- ✅ Better security (auto-rotated session tokens)
- ✅ Easier maintenance (centralized template configuration)
- ✅ More reliable (no environment variable expansion issues)
- ✅ Scalable (works for all developers automatically)

### Migration Guide

**For Coder Administrators:**
1. Add the startup script from `coder-template-example.tf` to your workspace templates
2. Developers will get automatic configuration on next workspace start
3. No action needed from developers

**For Developers (if admin hasn't updated template):**
1. Run: `bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh`
2. Restart Kiro
3. Verify "coder" MCP server is connected in MCP Servers panel

**Backward Compatibility:** Existing configurations continue to work. The new approach is additive.

---

## 2026-02-26 - Agent Interaction Enhancements

### New Capabilities
Added comprehensive documentation for interacting with workspace agents (Claude Code, Cursor, etc.) running inside Coder task workspaces.

### New Files
- **steering/agent-interaction.md** (500+ lines): Complete guide for collaborating with workspace agents
  - Explains external vs. workspace agent roles
  - Detailed `coder_send_task_input` usage patterns
  - Detailed `coder_get_task_logs` usage patterns
  - Four collaboration patterns (Orchestrator, Delegator, Hybrid, Iterative)
  - Monitoring and troubleshooting guidance
- **AGENT-INTERACTION-QUICK-REF.md** (300+ lines): Quick reference for agent collaboration
  - Tool syntax and parameters
  - Pattern examples with code
  - Decision guide for delegation
  - Common workflows
  - Troubleshooting tips
- **AGENT-INTERACTION-SUMMARY.md**: Comprehensive summary of enhancements
  - Overview of new capabilities
  - Use case examples
  - Technical implementation details
  - Best practices and next steps

### Documentation Updates
- **POWER.md**:
  - Added agent-interaction steering file to available files list
  - Enhanced tool descriptions for `coder_send_task_input` and `coder_get_task_logs`
  - Added collaboration patterns to best practices
  - Added agent interaction note to key tools section
- **REQUIREMENTS.md**:
  - Added agent-interaction.md to file structure
  - Enhanced tool descriptions in reference table
  - Added section 5 documenting agent interaction requirements
- **EXECUTION-PLAN.md**:
  - Added Phase 6: Agent Interaction Tests (45 minutes, 10 tests)
  - Updated timeline to include agent interaction testing
  - Added quick reference commands for agent interaction
  - Updated success criteria and checklist
  - Renumbered subsequent phases

### Use Cases Enabled

**1. Delegation Pattern**
External Kiro agent can delegate complex implementation tasks to workspace agents:
```
1. Create task
2. Send prompt: "Implement user authentication with JWT"
3. Monitor progress via coder_get_task_status
4. Check results via coder_get_task_logs
5. Stop workspace when complete
```

**2. Orchestration Pattern**
External agent coordinates workflow, workspace agent handles specific steps:
```
1. External: Set up project structure
2. External: Send prompt to workspace agent: "Implement business logic"
3. Workspace agent: Implements logic
4. External: Run tests
5. External: Send feedback if needed
```

**3. Hybrid Pattern**
Both agents work in parallel on different aspects:
```
1. External: Send prompt: "Implement backend API"
2. Workspace agent: Works on backend
3. External: While agent works, set up Docker, CI/CD
4. External: Monitor and integrate when agent completes
```

**4. Iterative Refinement**
Agents collaborate in iterations:
```
1. External: Send initial prompt
2. Workspace agent: Creates initial implementation
3. External: Review and send refinement prompt
4. Workspace agent: Improves implementation
5. Repeat until satisfactory
```

### Benefits
- Enables true agent-to-agent collaboration
- Leverages strengths of both external and workspace agents
- Provides clear patterns for different collaboration styles
- Improves efficiency by delegating appropriate tasks
- Maintains visibility and control through monitoring

---

## 2026-02-26 - Task State Management Corrections

### Issue
The prototype incorrectly assumed external Kiro agents could report task state via a `coder_report_task` tool. Testing revealed this tool does not exist in the Coder MCP server.

### Root Cause
Task state (working/idle/failure) is managed by the agent running INSIDE the workspace (e.g., Claude Code), not by external monitoring agents. The Coder MCP server provides read-only access to task state via `coder_get_task_status`.

### Changes Made

#### 1. Documentation Updates
- **POWER.md**: Removed `coder_report_task` from tools list and best practices
- **REQUIREMENTS.md**: 
  - Added "Task State Management" section clarifying internal vs external agent roles
  - Removed `coder_report_task` from tools reference table
  - Updated acceptance criteria to remove task reporting steps
  - Updated task workflow instructions to focus on monitoring instead of reporting
- **steering/task-workflow.md**:
  - Removed all `coder_report_task` calls from workflows
  - Updated "Monitoring Task Progress" section to clarify read-only monitoring
  - Updated "Completing a Task" section to focus on stopping workspace
  - Updated "Handling Task Failures" section to remove reporting steps
  - Updated "Task Lifecycle Summary" diagram
  - Updated all workflow patterns to remove reporting
  - Updated error handling examples

#### 2. Hook Updates
- **.kiro/hooks/coder-task-complete.kiro.hook**:
  - Renamed from "Report Coder Task Complete" to "Stop Coder Workspace"
  - Removed `coder_report_task` call from prompt
  - Simplified to only stop the workspace

### Correct Workflow

**External Kiro agents should:**
1. Create tasks via `coder_create_task`
2. Monitor task status via `coder_get_task_status` (read-only)
3. Execute commands and file operations in the workspace
4. Stop workspaces via `coder_create_workspace_build` when done

**External Kiro agents should NOT:**
- Attempt to report task progress or state
- Try to mark tasks as complete or failed
- Assume they can update the Coder Tasks UI directly

**Task state updates are handled by:**
- The workspace agent (Claude Code, Cursor, etc.) running inside the task workspace
- These agents have direct access to report their own progress

### Testing Status
- ✅ End-to-end acceptance test completed successfully
- ✅ Task creation, monitoring, and workspace operations verified
- ✅ Workspace stop operation confirmed working
- ✅ Documentation corrected to match actual MCP server capabilities

### Files Modified
- `kiro-coder-guardian-forge/POWER.md`
- `kiro-coder-guardian-forge/REQUIREMENTS.md`
- `kiro-coder-guardian-forge/steering/task-workflow.md`
- `.kiro/hooks/coder-task-complete.kiro.hook`
