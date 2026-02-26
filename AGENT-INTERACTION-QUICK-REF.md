# Agent Interaction Quick Reference

Quick reference for using `coder_send_task_input` and `coder_get_task_logs` to collaborate with workspace agents.

---

## Two Tools for Agent Collaboration

### `coder_send_task_input` - Send Prompts to Workspace Agent

**Purpose:** Delegate work to the AI agent running inside the task workspace (Claude Code, Cursor, etc.)

**Parameters:**
```json
{
  "task_id": "[owner/]workspace[.agent]",
  "input": "Your prompt or instruction"
}
```

**When to use:**
- Delegate implementation tasks
- Request information from workspace
- Give follow-up instructions
- Coordinate multi-step workflows

**Example:**
```json
{
  "task_id": "admin/dev-workspace",
  "input": "Implement user authentication with JWT tokens. Include login, logout, and token refresh endpoints."
}
```

### `coder_get_task_logs` - Get Workspace Logs

**Purpose:** Retrieve logs from the workspace, including workspace agent activity and responses

**Parameters:**
```json
{
  "task_id": "[owner/]workspace[.agent]"
}
```

**When to use:**
- Get workspace name after task creation
- Monitor workspace agent activity
- Debug issues
- Extract information from agent responses
- Verify completion of delegated work

**Example:**
```json
{
  "task_id": "admin/dev-workspace"
}
```

---

## Four Collaboration Patterns

### 1. Orchestrator Pattern
**You coordinate, workspace agent implements**

```
1. Create task and wait for running
2. Set up project structure (you)
3. Send prompt: "Implement core business logic" (workspace agent)
4. Monitor progress with coder_get_task_status
5. Run tests (you)
6. Send feedback if needed (workspace agent)
7. Stop workspace (you)
```

**Best for:** Complex projects where you want control over structure but delegate implementation

### 2. Delegator Pattern
**Workspace agent does most work, you monitor**

```
1. Create task and wait for running
2. Send comprehensive prompt: "Implement complete REST API with CRUD, auth, and tests"
3. Monitor task state every 2 minutes
4. Check logs periodically
5. Review results when agent reports idle
6. Stop workspace
```

**Best for:** Well-defined tasks where workspace agent can work autonomously

### 3. Hybrid Pattern
**Both work in parallel on different aspects**

```
1. Send prompt to workspace agent: "Implement backend API"
2. While agent works, you handle infrastructure:
   - Create Dockerfile
   - Create docker-compose.yml
   - Set up CI/CD
3. Monitor agent progress
4. Integrate when agent completes
5. Stop workspace
```

**Best for:** Projects with clear separation between infrastructure and application code

### 4. Iterative Pattern
**Refine work together in iterations**

```
1. Send initial prompt: "Create user registration form"
2. Workspace agent creates basic form
3. Review with coder_workspace_read_file
4. Send refinement: "Add email validation and password strength"
5. Workspace agent adds features
6. Test with coder_workspace_bash
7. Send final refinement: "Add ARIA labels"
8. Verify and stop workspace
```

**Best for:** Tasks requiring iterative refinement and quality improvements

---

## Monitoring Workspace Agent Progress

### Check Task State

```
status = coder_get_task_status(task_id="admin/dev-workspace")
```

**State meanings:**
- `working` - Agent is actively working (wait and monitor)
- `idle` - Agent is waiting for input or completed work (check logs)
- `failure` - Agent encountered an error (check logs for details)

### Monitoring Loop

```
1. Send prompt with coder_send_task_input
2. Wait 10-30 seconds
3. Check state with coder_get_task_status
4. If "working": wait 30-60 seconds and check again
5. If "idle": check logs to see if complete or needs more input
6. If "failure": check logs for error details
```

### Check Logs for Details

```
logs = coder_get_task_logs(task_id="admin/dev-workspace")
```

**Look for:**
- Agent responses to your prompts
- Progress updates
- Test results
- Error messages
- Completion confirmations

---

## Quick Decision Guide

**Should I do it myself or delegate to workspace agent?**

| Task Type | Recommendation |
|---|---|
| Simple file operations (create, copy, move) | You (external agent) |
| Complex implementation requiring AI | Workspace agent |
| Running specific commands | You (external agent) |
| Code generation and refactoring | Workspace agent |
| Infrastructure setup (Docker, CI/CD) | You (external agent) |
| Business logic implementation | Workspace agent |
| Quick checks and validations | You (external agent) |
| Iterative code refinement | Workspace agent |
| Precise control needed | You (external agent) |
| Creative problem solving | Workspace agent |

---

## Common Workflows

### Workflow 1: Delegate Complete Feature

```
1. coder_create_task(input="Feature X", template_version_id="...")
2. Wait for running (poll coder_get_task_status)
3. coder_send_task_input(input="Implement feature X with requirements: ...")
4. Monitor: coder_get_task_status every 60 seconds
5. When idle: coder_get_task_logs to verify completion
6. coder_create_workspace_build(transition="stop")
```

### Workflow 2: Multi-Step with Feedback

```
1. Create task and wait for running
2. coder_send_task_input(input="Step 1: Set up database schema")
3. Wait for idle state
4. coder_get_task_logs to verify step 1
5. coder_send_task_input(input="Step 2: Implement API handlers")
6. Wait for idle state
7. coder_workspace_bash to run tests
8. If tests fail: coder_send_task_input(input="Fix test failures: ...")
9. Stop workspace when complete
```

### Workflow 3: Hybrid Approach

```
1. Create task and wait for running
2. You: Create project structure with coder_workspace_write_file
3. coder_send_task_input(input="Implement business logic in src/handlers/")
4. Monitor workspace agent progress
5. You: Run tests with coder_workspace_bash
6. If issues: coder_send_task_input(input="Fix validation in handleLogin()")
7. Stop workspace when complete
```

### Workflow 4: Information Gathering

```
1. Create task and wait for running
2. coder_send_task_input(input="Analyze the codebase and list all API endpoints")
3. Wait for idle state
4. coder_get_task_logs to get the analysis
5. Parse and present information to user
6. Stop workspace
```

---

## Troubleshooting

### Agent Not Responding

**Symptoms:** Task state stays idle after sending prompt

**Solutions:**
1. Check workspace is running: `coder_get_task_status`
2. Check logs for errors: `coder_get_task_logs`
3. Send test prompt: "Reply with 'ready'"
4. If still unresponsive, stop and recreate workspace

### Can't Find Agent Response

**Symptoms:** Logs are too verbose or unclear

**Solutions:**
1. Look for timestamps around when you sent prompt
2. Search for key phrases from your prompt
3. Look for common patterns (file paths, test results)
4. Send more specific prompt asking for structured output

### Agent Reports Failure

**Symptoms:** Task state shows "failure"

**Solutions:**
1. Get logs: `coder_get_task_logs`
2. Identify the error
3. Send corrective prompt with fix
4. Or fix yourself with `coder_workspace_*` tools
5. Or stop workspace and report to user

---

## Best Practices

**Prompts:**
- Be specific and detailed
- Provide context (file paths, requirements)
- One task at a time
- Wait for completion before next prompt

**Monitoring:**
- Check state every 30-60 seconds during work
- Check logs after sending prompts
- Don't poll too frequently (avoid every second)
- Use reasonable timeouts (5 minutes for complex tasks)

**Resource Management:**
- Always stop workspaces when done
- Don't leave workspaces running unnecessarily
- Monitor task state to know when work is complete
- Clean up failed workspaces promptly

**Collaboration:**
- Leverage workspace agent for complex implementation
- Handle infrastructure and setup yourself
- Provide feedback when results aren't right
- Iterate until quality is satisfactory

---

For detailed guidance, see `steering/agent-interaction.md`
