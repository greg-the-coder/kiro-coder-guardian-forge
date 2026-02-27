# Coder Guardian Forge — Kiro Power Prototype
## MVP Product Requirements

**Goal:** Build a working Kiro Power that demonstrates the core integration between Kiro agents and Coder's Tasks + Agent-Ready Workspaces. The prototype should show a Kiro agent creating a Coder Task, monitoring it through the Tasks UI, running commands inside the resulting workspace, and reporting back — all within the developer's own Coder deployment.

---

## What We're Building

A Kiro Power with three files:

```
kiro-coder-guardian-forge/
├── REQUIREMENTS.md        ← this file
├── POWER.md               ← Kiro Power definition (metadata, onboarding, steering)
├── mcp.json               ← Coder remote MCP server connection (no CLI needed)
└── steering/
    ├── task-workflow.md   ← how to create and monitor Coder Tasks
    ├── workspace-ops.md   ← how to run commands inside the workspace
    └── agent-interaction.md ← how to collaborate with workspace agents
```

The Power connects Kiro to a running Coder deployment via the **Coder remote HTTP MCP server**. No Coder CLI installation or local `coder login` is required — the developer provides their Coder server URL and a personal API token, and the Power connects directly to Coder's MCP HTTP endpoint.

---

## 1. `mcp.json` — Coder Remote MCP Server

Coder exposes a remote MCP server over HTTP at:

```
https://<your-coder-server>/api/experimental/mcp/http
```

This endpoint requires the `oauth2` and `mcp-server-http` experiments to be enabled on the Coder server (a one-time admin action). Kiro connects to it using the `url` + `headers` pattern for remote MCP servers — no `command`, no local binary, no CLI session.

Authentication uses a standard `Authorization: Bearer <token>` header with the developer's Coder API token.

**`mcp.json`:**

```json
{
  "mcpServers": {
    "coder": {
      "url": "${CODER_URL}api/experimental/mcp/http",
      "headers": {
        "Authorization": "Bearer ${CODER_TOKEN}"
      }
    }
  }
}
```

**Note:** The URL assumes `CODER_URL` includes a trailing slash (e.g., `https://coder.mycompany.com/`), which is the standard format injected by Coder workspaces.

**Environment variables the developer must set** (once, in their shell profile):

| Variable | Description | Example |
|---|---|---|
| `CODER_URL` | Base URL of the Coder deployment (with trailing slash) | `https://coder.mycompany.com/` |
| `CODER_TOKEN` | Coder personal API token from the web UI | `<token from Account → Tokens>` |

Kiro expands `${VAR}` references at runtime, so credentials are never hardcoded in the file and `mcp.json` is safe to commit to the repository.

**Why remote over local CLI:**
- No Coder CLI install step for the developer
- No `coder login` or local session management
- Works on any machine where Kiro runs, including machines that don't have the Coder CLI installed
- Token-based auth is explicit and auditable — tokens can be scoped, rotated, or revoked from the Coder web UI without touching local config

---

## 2. `POWER.md` — Power Definition

### Frontmatter

```yaml
---
name: "coder-guardian-forge"
displayName: "Coder Guardian Forge"
description: "Run Kiro agents in governed Coder workspaces. Creates Agent-Ready Workspaces as Coder Tasks — visible in the Coder Tasks UI — so all agent activity is tracked, auditable, and isolated inside your own infrastructure."
keywords:
  - coder
  - workspace
  - task
  - agent
  - guardian
  - forge
  - regulated
  - secure workspace
  - remote workspace
  - cloud workspace
---
```

### Onboarding Section

The onboarding section runs once when the Power is first activated. It should:

1. **Verify the connection is working**
   - Call `coder_get_authenticated_user` via the remote MCP server
   - If it succeeds, display: `"Connected to Coder as <username> at <server-url>. Ready to create agent tasks."`
   - If it fails, tell the user to check:
     - `CODER_URL` is set correctly and points to their Coder server
     - `CODER_TOKEN` is set to a valid token from **Coder web UI → Account → Tokens**
     - The Coder admin has enabled the `mcp-server-http` experiment on the server
   - Do not proceed with any Coder operations if this check fails

2. **List available templates**
   - Call `coder_list_templates` and show the results
   - If no templates are found, tell the user their Coder admin needs to configure at least one workspace template before tasks can be created

3. **Create the task-complete hook**
   - Create `.kiro/hooks/coder-task-complete.kiro.hook` with this content:

```json
{
  "enabled": true,
  "name": "Stop Coder Workspace",
  "description": "When work is done, stop the workspace to free resources.",
  "version": "1",
  "when": {
    "type": "userTriggered"
  },
  "then": {
    "type": "askAgent",
    "prompt": "The current work is complete. Stop the workspace by calling coder_create_workspace_build with transition=stop."
  }
}
```

### Steering Routing (inline in `POWER.md`)

```
# When to Load Steering Files
- Creating a new task or starting work on something → `steering/task-workflow.md`
- Running commands, reading or writing files inside a workspace → `steering/workspace-ops.md`
- Sending prompts to or monitoring workspace agents → `steering/agent-interaction.md`
```

---

## 3. `steering/task-workflow.md` — Task Creation Workflow

This file teaches Kiro exactly how to create and monitor a Coder Task. It is loaded when the developer asks to start work on something.

### Content Requirements

**Section: Always use Tasks, never raw workspaces**

All work must start with a Coder Task via `coder_create_task`. This is what makes the workspace visible in the Coder Tasks UI with lifecycle tracking and progress reporting. Never call `coder_create_workspace` directly — the task creates and manages the underlying workspace automatically.

**Section: Step-by-step task creation workflow**

1. **Choose a template**
   - Call `coder_list_templates` to show available templates
   - Ask the user to confirm which template to use before proceeding
   - Note the template's `ActiveVersionID` — this is the `template_version_id` needed for task creation

2. **Create the task**
   - Call `coder_create_task` with:
     - `input`: a concise description of the work to be done (shown in the Coder Tasks UI)
     - `template_version_id`: the `ActiveVersionID` from the confirmed template
   - After the call succeeds, tell the user: `"Task created — you can follow along in the Coder Tasks UI."`

3. **Wait for the workspace to be ready**
   - Poll `coder_get_task_status` every 10 seconds
   - Continue polling until status is no longer `pending` or `starting`
   - Once running, the workspace is ready for work
   - If the task has not started within 5 minutes, stop the workspace and inform the user

4. **Get the workspace name**
   - Call `coder_get_task_logs` to retrieve workspace connection details
   - The workspace name is required for all subsequent `coder_workspace_*` tool calls

**Section: Monitoring task progress**

Task state is managed by the agent running inside the workspace (e.g., Claude Code). External agents can monitor the state by calling `coder_get_task_status` periodically to check:
- `status`: Overall task status (active, paused, stopped)
- `state.state`: Current work state (working, idle, failure)
- `state.message`: Description of current activity

**Section: Completing or failing a task**

When work is done:
1. Ask the user if they want to stop the workspace or keep it running for review
2. If stopping: call `coder_create_workspace_build` with `transition=stop`

If something goes wrong:
1. Stop the workspace with `coder_create_workspace_build` — do not leave it running after a failure
2. Inform the user of the failure

---

## 4. `steering/workspace-ops.md` — Working Inside the Workspace

This file teaches Kiro how to do actual work inside a running task workspace. It is loaded when the developer asks to run commands or modify files.

### Content Requirements

**Section: Running commands**

Use `coder_workspace_bash` to execute commands inside the workspace:
- The `workspace` parameter format is `owner/workspace-name` (get the name from `coder_get_task_logs` after task creation)
- Set a sensible `timeout_ms`: 15000 for quick checks, 60000 for installs, 120000 for builds or test runs
- Always check `exit_code` in the result — non-zero means the command failed
- For long-running background processes, set `background: true`

Example patterns:
```
# Verify the environment
workspace: "me/my-workspace", command: "pwd && ls -la /home/coder", timeout_ms: 15000

# Install dependencies
workspace: "me/my-workspace", command: "cd /home/coder/app && npm install", timeout_ms: 60000

# Run tests
workspace: "me/my-workspace", command: "cd /home/coder/app && go test ./...", timeout_ms: 120000
```

**Section: Reading and writing files**

Always use the dedicated file tools instead of bash `cat` / `echo` / `heredoc`:

| Task | Tool |
|---|---|
| List a directory | `coder_workspace_ls` with absolute path |
| Read a file | `coder_workspace_read_file` with absolute path |
| Write a new file | `coder_workspace_write_file` — content must be base64-encoded |
| Edit an existing file | `coder_workspace_edit_file` with search/replace pairs |
| Edit multiple files | `coder_workspace_edit_files` |

**Section: Checking running apps**

- Use `coder_workspace_list_apps` to see URLs of services already exposed in the workspace
- Use `coder_workspace_port_forward` to access a port not already exposed as an app

---

## 5. `steering/agent-interaction.md` — Collaborating with Workspace Agents

This file teaches Kiro how to interact with AI agents running inside task workspaces (e.g., Claude Code, Cursor, GitHub Copilot Workspace).

### Content Requirements

**Section: Understanding agent types**

Explain the difference between:
- External agents (Kiro running outside the workspace)
- Workspace agents (Claude Code, Cursor running inside the workspace)

**Section: Using `coder_send_task_input`**

How to send prompts and instructions to workspace agents:
- When to delegate work vs. do it yourself
- How to structure effective prompts
- Monitoring workspace agent progress
- Handling workspace agent responses

**Section: Using `coder_get_task_logs`**

How to retrieve and parse workspace logs:
- Getting workspace connection details after task creation
- Monitoring workspace agent activity
- Extracting information from agent responses
- Debugging failures

**Section: Collaboration patterns**

Common patterns for working with workspace agents:
- **Orchestrator pattern:** External agent coordinates, workspace agent implements
- **Delegator pattern:** Send comprehensive prompt, workspace agent does most work
- **Hybrid pattern:** External agent handles infrastructure, workspace agent handles logic
- **Iterative pattern:** External and workspace agents refine work together

**Section: Monitoring workspace agent state**

How to track workspace agent progress:
- Understanding task state (working, idle, failure)
- Polling `coder_get_task_status` to monitor progress
- Knowing when to wait vs. when to intervene
- Handling workspace agent failures

---

## 6. Acceptance Criteria for the Prototype

The prototype is working when a developer can complete this full loop in Kiro, without installing the Coder CLI:

1. Set `CODER_URL` and `CODER_TOKEN` in their environment
2. Install the Power in Kiro and see `"Connected to Coder as <username>"` during onboarding
3. Say: *"I want to start working on a new feature using Coder"*
4. Kiro shows available templates and asks the developer to confirm one
5. Kiro calls `coder_create_task` — within 60 seconds the task appears in the Coder Tasks UI with status `starting`
6. Kiro polls until the workspace is running
7. Kiro runs `ls /home/coder` in the workspace and shows the output in the conversation
8. Developer triggers the "Stop Coder Workspace" hook — Kiro stops the workspace

---

## Task State Management

**IMPORTANT:** Task state (working/idle/failure) is managed by the agent running INSIDE the workspace (e.g., Claude Code, Cursor, or other AI coding assistants). External Kiro agents cannot set or update task state.

**What external agents CAN do:**
- Create tasks via `coder_create_task`
- Monitor task status via `coder_get_task_status` (read-only)
- Stop workspaces via `coder_create_workspace_build`
- Execute commands and file operations in the workspace

**What external agents CANNOT do:**
- Report task progress or completion (no `coder_report_task` tool exists)
- Update task state directly
- Mark tasks as complete or failed

The task state visible in the Coder Tasks UI is set by the workspace agent as it performs work. External monitoring agents can observe this state but not modify it.

---

## Key Coder MCP Tools Reference

| Tool | When to use |
|---|---|
| `coder_get_authenticated_user` | Onboarding — verify the API token and show who is connected |
| `coder_list_templates` | Before task creation — show available workspace templates |
| `coder_list_template_version_parameters` | Before task creation — show configurable template options |
| `coder_create_task` | **Primary provisioning tool** — creates the Coder Task and its underlying workspace |
| `coder_get_task_status` | Poll until the task workspace is running |
| `coder_get_task_logs` | Get workspace logs including agent activity and responses |
| `coder_list_tasks` | Find existing running tasks to avoid creating duplicates |
| `coder_send_task_input` | Send prompts/instructions to workspace agent (Claude Code, Cursor, etc.) |
| `coder_delete_task` | Clean up a completed task |
| `coder_list_workspaces` | Look up workspace name if not available from task logs |
| `coder_workspace_bash` | Run a command inside the task workspace |
| `coder_workspace_ls` | List directory contents |
| `coder_workspace_read_file` | Read a file |
| `coder_workspace_write_file` | Write a new file (base64-encoded content) |
| `coder_workspace_edit_file` | Make targeted edits to an existing file |
| `coder_workspace_list_apps` | Get URLs of running apps in the workspace |
| `coder_create_workspace_build` | Stop the workspace after task completion (`transition=stop`) |

---

## What NOT to Do

- **Do not call `coder_create_workspace` directly** — always use `coder_create_task`. The Task is what surfaces the workspace in the Coder Tasks UI.
- **Do not start file or bash operations before the task workspace is running** — always wait for `coder_get_task_status` to confirm the workspace is up.
- **Do not leave workspaces running after a task failure** — always report failure then stop the workspace.
- **Do not use bash `cat` / `echo` / `heredoc` for file operations** — use the dedicated file tools.
- **Do not hardcode `CODER_URL` or `CODER_TOKEN`** — always use `${CODER_URL}` and `${CODER_TOKEN}` in `mcp.json` so credentials stay out of the repository.

---

## Developer Setup (Two Steps, No CLI Required)

**Step 1 — Get a Coder API token**
- Log into the Coder web UI
- Go to **Account → Tokens → Generate Token**
- Copy the token

**Step 2 — Set two environment variables** in your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):
```bash
export CODER_URL="https://coder.mycompany.com/"
export CODER_TOKEN="<paste-token-here>"
```

**Note:** If running Kiro inside a Coder workspace, `CODER_URL` is already set with a trailing slash.

**Step 3 — Install the Power in Kiro**
- Open the Powers panel → Add power from GitHub → paste the repo URL

That's it. No CLI download, no `coder login`, no local daemon.

---

## Coder Admin Prerequisite (One-Time Server Configuration)

The remote HTTP MCP server must be enabled on the Coder deployment before any developer can use this Power. The admin enables it by starting the Coder server with:

```bash
CODER_EXPERIMENTS="oauth2,mcp-server-http" coder server
```

Once enabled, the MCP endpoint is live at:
```
https://<coder-server>/api/experimental/mcp/http
```

All developers with a valid API token can then connect immediately — no per-user server-side configuration needed.
