# Interacting with Workspace Agents

This steering file teaches you how to interact with AI agents running inside Coder task workspaces (e.g., Claude Code, Cursor, GitHub Copilot Workspace). Load this when you need to collaborate with or monitor workspace agents.

---

## Overview: Two Types of Agents

When working with Coder Tasks, there are two types of agents:

**1. External Agents (You)**
- Run outside the workspace (e.g., Kiro in the developer's local environment)
- Create and monitor tasks via Coder MCP tools
- Execute commands and file operations in the workspace
- Cannot set task state directly

**2. Workspace Agents (Inside the Task)**
- Run inside the task workspace (e.g., Claude Code, Cursor)
- Set task state (working, idle, failure) visible in Coder Tasks UI
- Receive prompts via `coder_send_task_input`
- Generate logs visible via `coder_get_task_logs`

**Key insight:** External agents can collaborate with workspace agents by sending prompts and monitoring their progress.

---

## Tool: `coder_send_task_input`

Send a prompt or instruction to the agent running inside a task workspace.

### When to Use

- **Delegate work to the workspace agent:** "Implement the login API endpoint"
- **Request information:** "What's the current status of the test suite?"
- **Give follow-up instructions:** "Now add error handling to the auth module"
- **Coordinate multi-step workflows:** "Step 1 complete. Proceed to step 2: database migration"
- **Provide feedback:** "The tests are failing. Please fix the validation logic"

### How It Works

1. You call `coder_send_task_input` with a prompt
2. The prompt is delivered to the workspace agent (e.g., Claude Code)
3. The workspace agent processes the prompt and performs the work
4. The workspace agent updates task state as it works
5. You monitor progress via `coder_get_task_status` and `coder_get_task_logs`

### Parameters

```json
{
  "task_id": "workspace-identifier",  // Format: [owner/]workspace[.agent]
  "input": "Your prompt or instruction"
}
```

**Task ID formats:**
- `workspace-name` - Uses authenticated user as owner
- `owner/workspace-name` - Explicit owner
- `workspace-name.agent-name` - Specific agent in workspace
- `owner/workspace-name.agent-name` - Full specification

### Example Usage Patterns

**Pattern 1: Delegate a complete task**
```
1. Create task with coder_create_task
2. Wait for running status
3. Send initial prompt:
   coder_send_task_input(
     task_id="admin/dev-workspace",
     input="Implement user authentication with JWT tokens. Include login, logout, and token refresh endpoints."
   )
4. Monitor progress with coder_get_task_status
5. Check logs periodically with coder_get_task_logs
```

**Pattern 2: Multi-step workflow**
```
1. Send first instruction:
   coder_send_task_input(input="Step 1: Set up the database schema")
2. Wait for workspace agent to complete (monitor task state)
3. Send next instruction:
   coder_send_task_input(input="Step 2: Implement the API handlers")
4. Continue until all steps complete
```

**Pattern 3: Hybrid approach (you + workspace agent)**
```
1. You: Create files and basic structure using coder_workspace_write_file
2. You: Send prompt to workspace agent:
   coder_send_task_input(input="I've created the basic structure. Please implement the business logic in src/handlers/")
3. Workspace agent: Implements the logic
4. You: Run tests using coder_workspace_bash
5. You: Send feedback:
   coder_send_task_input(input="Tests are failing. Please fix the validation in handleLogin()")
```

**Pattern 4: Information gathering**
```
1. Send query to workspace agent:
   coder_send_task_input(input="What's the current test coverage percentage?")
2. Check logs for response:
   coder_get_task_logs(task_id="admin/dev-workspace")
3. Parse the agent's response from the logs
```

### Best Practices

- **Be specific:** Clear, detailed prompts get better results
- **One task at a time:** Don't overload the workspace agent with multiple requests simultaneously
- **Monitor progress:** Check `coder_get_task_status` to see if the agent is working or idle
- **Wait for completion:** Let the workspace agent finish before sending the next prompt
- **Provide context:** Reference specific files, functions, or requirements
- **Give feedback:** If results aren't right, send follow-up instructions

### What NOT to Do

- Don't send prompts before the workspace is running
- Don't send multiple prompts in rapid succession without waiting for completion
- Don't assume the workspace agent can access external resources without proper setup
- Don't send prompts to stopped or failed workspaces

---

## Tool: `coder_get_task_logs`

Retrieve logs from a task workspace, including output from the workspace agent.

### When to Use

- **Get workspace connection details** after task creation (workspace name, agent info)
- **Monitor workspace agent activity** (what the agent is doing)
- **Debug issues** (error messages, stack traces)
- **Extract information** provided by the workspace agent
- **Verify completion** of delegated work

### How It Works

1. You call `coder_get_task_logs` with a task ID
2. Coder returns logs from the workspace, including:
   - Workspace provisioning logs
   - Agent startup logs
   - Agent activity logs (responses to prompts)
   - Command output
   - Error messages

### Parameters

```json
{
  "task_id": "workspace-identifier"  // Format: [owner/]workspace[.agent]
}
```

### Example Usage Patterns

**Pattern 1: Get workspace name after creation**
```
1. Create task: coder_create_task(...)
2. Wait for running: poll coder_get_task_status
3. Get workspace details:
   logs = coder_get_task_logs(task_id="admin/dev-workspace")
4. Extract workspace name from logs
5. Use workspace name for coder_workspace_* operations
```

**Pattern 2: Monitor workspace agent progress**
```
1. Send prompt: coder_send_task_input(input="Run the test suite")
2. Wait 30 seconds
3. Check logs:
   logs = coder_get_task_logs(task_id="admin/dev-workspace")
4. Look for test results in the logs
5. If tests still running, wait and check again
```

**Pattern 3: Debug failures**
```
1. Task state shows "failure" in coder_get_task_status
2. Get logs to see what went wrong:
   logs = coder_get_task_logs(task_id="admin/dev-workspace")
3. Search logs for error messages
4. Identify the issue
5. Either:
   - Send corrective prompt to workspace agent
   - Fix the issue yourself with coder_workspace_* tools
   - Stop workspace and report failure to user
```

**Pattern 4: Extract information from workspace agent**
```
1. Send query: coder_send_task_input(input="List all API endpoints in the project")
2. Wait for agent to respond
3. Get logs: coder_get_task_logs(task_id="admin/dev-workspace")
4. Parse the agent's response from the logs
5. Present information to user
```

### Log Content Examples

**Workspace provisioning:**
```
[2026-02-26 10:15:23] Workspace starting...
[2026-02-26 10:15:45] Agent connected: claude-code
[2026-02-26 10:15:46] Workspace ready at /home/coder
```

**Agent activity:**
```
[2026-02-26 10:16:00] Received prompt: "Implement login endpoint"
[2026-02-26 10:16:05] Creating file: src/api/auth.go
[2026-02-26 10:16:12] Running tests...
[2026-02-26 10:16:18] Tests passed: 15/15
[2026-02-26 10:16:19] Task complete
```

**Errors:**
```
[2026-02-26 10:20:15] Error: cannot find package "github.com/jwt-go"
[2026-02-26 10:20:15] Please run: go get github.com/jwt-go
```

### Best Practices

- **Check logs after sending prompts** to see workspace agent responses
- **Use logs for debugging** when operations fail
- **Extract workspace name** from logs after task creation
- **Monitor logs periodically** during long-running operations
- **Parse logs carefully** — format may vary by workspace agent

### What NOT to Do

- Don't call `coder_get_task_logs` before the workspace is running
- Don't assume log format is consistent across different workspace agents
- Don't parse logs with brittle regex — look for key phrases instead
- Don't overwhelm the system by calling this every second — use reasonable intervals (10-30 seconds)

---

## Collaboration Patterns

### Pattern: External Agent as Orchestrator

You coordinate the overall workflow, delegating specific tasks to the workspace agent:

```
1. You: Create task and wait for running
2. You: Set up project structure (create directories, config files)
3. You: Send prompt to workspace agent: "Implement the core business logic"
4. Workspace agent: Implements the logic, updates task state to "working"
5. You: Monitor via coder_get_task_status
6. Workspace agent: Completes work, updates task state to "idle"
7. You: Run tests using coder_workspace_bash
8. You: If tests fail, send feedback to workspace agent
9. You: If tests pass, stop workspace
```

### Pattern: Workspace Agent as Primary Worker

The workspace agent does most of the work, you just monitor and intervene when needed:

```
1. You: Create task and wait for running
2. You: Send comprehensive prompt:
   "Implement a REST API for user management with CRUD operations, 
    authentication, and comprehensive tests. Use the existing database 
    schema in schema.sql."
3. Workspace agent: Does all the work, updating task state as it progresses
4. You: Monitor task state every 2 minutes
5. You: Check logs periodically to see progress
6. Workspace agent: Completes work, sets task state to "idle"
7. You: Review the results using coder_workspace_read_file
8. You: Stop workspace
```

### Pattern: Iterative Refinement

You and the workspace agent work together in iterations:

```
1. You: Send initial prompt: "Create a user registration form"
2. Workspace agent: Creates basic form
3. You: Review with coder_workspace_read_file
4. You: Send refinement: "Add email validation and password strength meter"
5. Workspace agent: Adds features
6. You: Test with coder_workspace_bash
7. You: Send final refinement: "Add ARIA labels for accessibility"
8. Workspace agent: Completes accessibility improvements
9. You: Verify and stop workspace
```

### Pattern: Parallel Work

You and the workspace agent work on different parts simultaneously:

```
1. You: Send prompt to workspace agent: "Implement the backend API"
2. Workspace agent: Starts working on backend (task state: "working")
3. You: While agent works, you set up infrastructure:
   - Create Dockerfile with coder_workspace_write_file
   - Create docker-compose.yml
   - Create CI/CD config
4. You: Monitor workspace agent progress via coder_get_task_status
5. Workspace agent: Completes backend (task state: "idle")
6. You: Run integration tests
7. You: Stop workspace
```

---

## Monitoring Workspace Agent State

### Understanding Task State

The workspace agent sets task state as it works:

| State | Meaning | What to Do |
|---|---|---|
| `working` | Agent is actively working | Wait and monitor progress |
| `idle` | Agent is waiting for input or has completed work | Check logs to see if done, or send next prompt |
| `failure` | Agent encountered an error | Check logs for details, send corrective prompt or stop workspace |

### Monitoring Loop

```
1. Send prompt with coder_send_task_input
2. Wait 10-30 seconds for agent to start
3. Check state with coder_get_task_status
4. If state is "working":
   - Wait 30-60 seconds
   - Check state again
   - Repeat until state changes
5. If state is "idle":
   - Check logs with coder_get_task_logs
   - Determine if work is complete or agent needs more input
6. If state is "failure":
   - Check logs for error details
   - Decide: fix and retry, or stop workspace
```

### Example Monitoring Code Flow

```
# Send work to workspace agent
coder_send_task_input(
  task_id="admin/dev-workspace",
  input="Run the full test suite and report results"
)

# Monitor until complete
while True:
  status = coder_get_task_status(task_id="admin/dev-workspace")
  
  if status.state.state == "working":
    # Agent is working, wait and check again
    wait(30 seconds)
    continue
  
  elif status.state.state == "idle":
    # Agent finished, check logs for results
    logs = coder_get_task_logs(task_id="admin/dev-workspace")
    # Parse logs to see test results
    break
  
  elif status.state.state == "failure":
    # Something went wrong
    logs = coder_get_task_logs(task_id="admin/dev-workspace")
    # Check logs for error details
    break
```

---

## Best Practices Summary

**When to use workspace agents:**
- Complex implementation tasks that benefit from AI assistance
- Tasks requiring deep code understanding
- Iterative refinement of code
- When you want to delegate and monitor rather than do directly

**When to do work yourself (external agent):**
- Simple file operations (create, copy, move)
- Running specific commands with known parameters
- Setting up infrastructure (configs, scripts)
- Quick checks and validations
- When you need precise control over every step

**Communication tips:**
- Be clear and specific in prompts
- Provide context (file paths, function names, requirements)
- Break complex work into steps
- Monitor progress regularly
- Give feedback when results aren't right
- Always check logs after sending prompts

**Resource management:**
- Don't leave workspaces running unnecessarily
- Stop workspaces after work completes or fails
- Monitor task state to know when work is done
- Use timeouts to avoid infinite waiting

---

## Troubleshooting

### Problem: Workspace agent not responding

**Symptoms:**
- Task state stays "idle" after sending prompt
- No new logs appear

**Solutions:**
1. Check workspace is still running: `coder_get_task_status`
2. Verify prompt was sent successfully
3. Check logs for errors: `coder_get_task_logs`
4. Try sending a simple test prompt: "Reply with 'ready'"
5. If still unresponsive, stop and recreate workspace

### Problem: Can't find workspace agent response in logs

**Symptoms:**
- Logs are too verbose
- Can't identify agent output

**Solutions:**
1. Look for timestamps around when you sent the prompt
2. Search for key phrases from your prompt
3. Look for common agent output patterns (file paths, test results)
4. If logs are overwhelming, send a more specific prompt asking for structured output

### Problem: Workspace agent reports failure but logs unclear

**Symptoms:**
- Task state shows "failure"
- Logs don't clearly explain the issue

**Solutions:**
1. Send follow-up prompt: "What error occurred? Please explain in detail."
2. Check recent logs for error messages or stack traces
3. Run diagnostic commands yourself: `coder_workspace_bash`
4. If issue is unclear, stop workspace and report to user

---

## Next Steps

- For creating tasks: see `task-workflow.md`
- For direct workspace operations: see `workspace-ops.md`
- For understanding Coder Tasks UI: check your Coder deployment at `${CODER_URL}/tasks`
