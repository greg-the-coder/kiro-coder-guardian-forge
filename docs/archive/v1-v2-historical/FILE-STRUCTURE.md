# Coder Guardian Forge - File Structure

Complete file structure of the Kiro Coder Guardian Forge Power.

---

## Core Power Files

```
kiro-coder-guardian-forge/
├── mcp.json                    # Remote MCP server configuration
├── POWER.md                    # Kiro Power definition with onboarding
├── README.md                   # Project overview and quick start
└── LICENSE                     # License information
```

---

## Steering Files (Workflow Guides)

```
steering/
├── task-workflow.md            # Creating and monitoring Coder Tasks
├── workspace-ops.md            # Running commands and editing files
└── agent-interaction.md        # Collaborating with workspace agents (NEW)
```

**Purpose:** Loaded on-demand by Kiro to guide specific workflows

**When to load:**
- `task-workflow.md` - When creating new tasks or starting work
- `workspace-ops.md` - When running commands or editing files
- `agent-interaction.md` - When delegating to or monitoring workspace agents

---

## Documentation Files

### Requirements & Planning
```
REQUIREMENTS.md                 # Product requirements and specifications
TESTING-PLAN.md                 # Comprehensive testing plan (30+ test cases)
EXECUTION-PLAN.md               # Step-by-step testing execution guide
```

### Quick References
```
QUICK-START.md                  # 5-minute quick start guide
AGENT-INTERACTION-QUICK-REF.md  # Quick reference for agent collaboration (NEW)
```

### Summaries & History
```
PROTOTYPE-SUMMARY.md            # Overview of initial prototype
AGENT-INTERACTION-SUMMARY.md    # Summary of agent interaction enhancements (NEW)
COMPLETION-SUMMARY.md           # Summary of completed work (NEW)
CHANGELOG.md                    # Version history and changes
FILE-STRUCTURE.md               # This file
```

---

## File Purposes

### Core Files

**mcp.json**
- Configures remote HTTP MCP server connection to Coder
- Uses environment variables: `${CODER_URL}` and `${CODER_TOKEN}`
- No CLI installation required

**POWER.md**
- Kiro Power definition with frontmatter metadata
- Onboarding instructions (verify connection, list templates, create hook)
- Tool reference table
- Best practices and troubleshooting
- Steering file routing

**README.md**
- Project overview and key features
- Agent collaboration patterns summary
- Quick start instructions
- Documentation index
- Status and prerequisites

### Steering Files

**task-workflow.md** (520 lines)
- Step-by-step task creation workflow
- Monitoring task progress
- Completing and failing tasks
- Finding existing tasks
- Common patterns and error handling

**workspace-ops.md** (580 lines)
- Running commands with `coder_workspace_bash`
- File operations (read, write, edit, list)
- Checking running apps and port forwarding
- Best practices for workspace operations

**agent-interaction.md** (500+ lines) ⭐ NEW
- Understanding external vs. workspace agents
- Using `coder_send_task_input` to delegate work
- Using `coder_get_task_logs` to monitor activity
- Four collaboration patterns (Orchestrator, Delegator, Hybrid, Iterative)
- Monitoring strategies and troubleshooting

### Documentation Files

**REQUIREMENTS.md**
- MVP product requirements
- File structure and content requirements
- Acceptance criteria
- Task state management explanation
- Key tools reference

**TESTING-PLAN.md**
- 30+ test cases organized by category
- Test procedures and validation criteria
- Expected results for each test
- Comprehensive coverage of all features

**EXECUTION-PLAN.md**
- Step-by-step testing execution guide
- Prerequisites and setup
- Detailed test procedures
- Success criteria

**QUICK-START.md**
- 5-minute quick start guide
- Environment setup
- First task creation
- Basic operations

**AGENT-INTERACTION-QUICK-REF.md** (300+ lines) ⭐ NEW
- Tool syntax and parameters
- Four patterns with code examples
- Decision guide (when to delegate)
- Common workflows
- Troubleshooting quick fixes

**PROTOTYPE-SUMMARY.md**
- Overview of initial prototype
- What was built
- Files created
- Testing approach

**AGENT-INTERACTION-SUMMARY.md** (400+ lines) ⭐ NEW
- Overview of agent interaction enhancements
- Key capabilities enabled
- Benefits for all stakeholders
- Use case examples
- Technical implementation details

**COMPLETION-SUMMARY.md** ⭐ NEW
- Summary of completed agent interaction work
- What was delivered
- Four patterns explained
- Benefits and metrics
- Production readiness assessment

**CHANGELOG.md**
- Version history
- Agent interaction enhancements (2026-02-26)
- Task state management corrections (2026-02-26)
- Files modified and created

---

## File Statistics

### Total Files
- Core files: 4
- Steering files: 3
- Documentation files: 9
- **Total: 16 files**

### Lines of Documentation
- Steering files: ~1,600 lines
- Documentation files: ~2,500 lines
- **Total: ~4,100 lines**

### New Files (Agent Interaction Enhancement)
- `steering/agent-interaction.md` - 500+ lines
- `AGENT-INTERACTION-QUICK-REF.md` - 300+ lines
- `AGENT-INTERACTION-SUMMARY.md` - 400+ lines
- `COMPLETION-SUMMARY.md` - 300+ lines
- `FILE-STRUCTURE.md` - This file
- **Total new: 5 files, ~1,500 lines**

### Modified Files (Agent Interaction Enhancement)
- `POWER.md` - Enhanced tool descriptions and patterns
- `REQUIREMENTS.md` - Added agent interaction section
- `README.md` - Complete rewrite with agent collaboration
- `CHANGELOG.md` - Documented enhancements
- **Total modified: 4 files**

---

## Documentation Organization

### By Audience

**For Developers Using the Power:**
- README.md - Start here
- QUICK-START.md - Get started quickly
- POWER.md - Reference for tools and capabilities
- AGENT-INTERACTION-QUICK-REF.md - Quick reference for collaboration

**For Kiro Agent (Runtime):**
- POWER.md - Loaded on activation
- steering/task-workflow.md - Loaded when creating tasks
- steering/workspace-ops.md - Loaded when doing workspace operations
- steering/agent-interaction.md - Loaded when collaborating with workspace agents

**For Power Developers/Maintainers:**
- REQUIREMENTS.md - Product requirements
- TESTING-PLAN.md - How to test
- EXECUTION-PLAN.md - Step-by-step testing
- CHANGELOG.md - Version history
- PROTOTYPE-SUMMARY.md - Initial prototype overview
- AGENT-INTERACTION-SUMMARY.md - Enhancement overview
- COMPLETION-SUMMARY.md - Work completion summary

### By Topic

**Getting Started:**
- README.md
- QUICK-START.md
- POWER.md (onboarding section)

**Task Management:**
- steering/task-workflow.md
- REQUIREMENTS.md (task workflow section)

**Workspace Operations:**
- steering/workspace-ops.md
- REQUIREMENTS.md (workspace ops section)

**Agent Collaboration:** ⭐ NEW
- steering/agent-interaction.md
- AGENT-INTERACTION-QUICK-REF.md
- AGENT-INTERACTION-SUMMARY.md
- REQUIREMENTS.md (agent interaction section)

**Testing:**
- TESTING-PLAN.md
- EXECUTION-PLAN.md

**Reference:**
- POWER.md (tools table)
- REQUIREMENTS.md (tools reference)
- CHANGELOG.md (version history)

---

## Navigation Guide

### "I want to get started quickly"
→ README.md → QUICK-START.md

### "I want to understand what this power does"
→ README.md → POWER.md

### "I want to create a Coder task"
→ POWER.md (activate) → steering/task-workflow.md (loaded automatically)

### "I want to run commands in a workspace"
→ steering/workspace-ops.md

### "I want to delegate work to a workspace agent"
→ steering/agent-interaction.md or AGENT-INTERACTION-QUICK-REF.md

### "I want to test the power"
→ TESTING-PLAN.md → EXECUTION-PLAN.md

### "I want to understand the requirements"
→ REQUIREMENTS.md

### "I want to see what changed"
→ CHANGELOG.md

### "I want to understand agent collaboration"
→ AGENT-INTERACTION-SUMMARY.md → steering/agent-interaction.md

---

## File Relationships

```
README.md
  ├─→ QUICK-START.md (getting started)
  ├─→ POWER.md (detailed reference)
  └─→ REQUIREMENTS.md (specifications)

POWER.md
  ├─→ steering/task-workflow.md (task creation)
  ├─→ steering/workspace-ops.md (workspace operations)
  └─→ steering/agent-interaction.md (agent collaboration)

REQUIREMENTS.md
  ├─→ TESTING-PLAN.md (how to test)
  ├─→ EXECUTION-PLAN.md (test execution)
  └─→ PROTOTYPE-SUMMARY.md (what was built)

AGENT-INTERACTION-SUMMARY.md
  ├─→ steering/agent-interaction.md (detailed guide)
  ├─→ AGENT-INTERACTION-QUICK-REF.md (quick reference)
  └─→ COMPLETION-SUMMARY.md (work summary)

CHANGELOG.md
  ├─→ AGENT-INTERACTION-SUMMARY.md (latest enhancements)
  └─→ PROTOTYPE-SUMMARY.md (initial prototype)
```

---

## Maintenance Notes

### When Adding New Features
1. Update POWER.md (tools table, best practices)
2. Update REQUIREMENTS.md (specifications)
3. Add/update steering files as needed
4. Update CHANGELOG.md
5. Update README.md if major feature
6. Add tests to TESTING-PLAN.md

### When Fixing Bugs
1. Update affected steering files
2. Update CHANGELOG.md
3. Update troubleshooting sections in POWER.md

### When Improving Documentation
1. Update relevant files
2. Update CHANGELOG.md
3. Ensure cross-references are correct
4. Update this FILE-STRUCTURE.md if structure changes

---

## Summary

The Coder Guardian Forge Power has a well-organized file structure with:
- Clear separation between core files, steering files, and documentation
- Multiple entry points for different audiences
- Comprehensive documentation (~4,100 lines)
- Recent enhancements for agent collaboration (~1,500 new lines)
- Easy navigation with clear relationships between files

**Status:** ✅ Complete and well-documented
**Organization:** ✅ Clear and maintainable
**Coverage:** ✅ Comprehensive
