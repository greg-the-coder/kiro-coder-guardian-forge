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

## Comprehensive Task Prompt Templates

Use these templates for all task creation to ensure consistent, high-quality results with proper validation.

### Template Function

```python
def generate_task_prompt(
    task_description: str,
    feature_branch: str,
    home_workspace: str,
    repo_path: str,
    validation_requirements: list = None,
    additional_context: str = ""
) -> str:
    """Generate comprehensive task prompt with all necessary context"""
    
    validation_section = ""
    if validation_requirements:
        validation_section = f"""
VALIDATION REQUIREMENTS (MUST COMPLETE BEFORE FINISHING):

{chr(10).join(f"{i+1}. {req}" for i, req in enumerate(validation_requirements))}

CRITICAL: If any validation fails, fix the issue before completing the task.
Document any issues found and how they were resolved.
"""
    
    prompt = f"""
{task_description}

GIT WORKFLOW:
- You are working on feature branch: {feature_branch}
- This branch has been created and pushed to remote
- Commit your work frequently with descriptive messages
- When complete, ensure all work is committed and pushed:
  ```bash
  git add .
  git commit -m "Complete: {task_description}"
  git push origin {feature_branch}
  ```

{validation_section}

COMPLETION CHECKLIST:
- [ ] All code changes committed
- [ ] All tests passing
- [ ] Build succeeds
- [ ] Changes pushed to {feature_branch}
- [ ] Documentation updated (if needed)

{additional_context}

When you have completed all work and validations, set your state to 'idle' or 'completed'.
"""
    
    return prompt
```

### Example Usage: Backend API Task

```python
prompt = generate_task_prompt(
    task_description="Implement user authentication API with JWT tokens",
    feature_branch="feature/auth-api",
    home_workspace="alice/main-workspace",
    repo_path="/workspaces/my-project",
    validation_requirements=[
        "Run full test suite: `npm test` - all tests must pass",
        "Run type checker: `npm run type-check` - zero TypeScript errors",
        "Test authentication flow: login, token refresh, logout",
        "Verify JWT tokens are properly signed and validated",
        "Check error handling for invalid credentials"
    ],
    additional_context="""
CONTEXT:
- Use jsonwebtoken library for JWT handling
- Store user credentials in PostgreSQL database
- API endpoints should be in src/api/auth.ts
- Follow existing error handling patterns in src/api/errors.ts
- Token expiry: 1 hour for access tokens, 7 days for refresh tokens
"""
)

task = coder_create_task(
    input=prompt,
    template_version_id=template_id,
    rich_parameter_values={
        "feature_branch": "feature/auth-api",
        "home_workspace": "alice/main-workspace"
    }
)
```

### Example Usage: Frontend Component Task

```python
prompt = generate_task_prompt(
    task_description="Create responsive dashboard with real-time metrics",
    feature_branch="feature/dashboard-ui",
    home_workspace="bob/main-workspace",
    repo_path="/workspaces/frontend-app",
    validation_requirements=[
        "Run build: `npm run build` - must succeed with zero errors",
        "Run linter: `npm run lint` - fix all linting errors",
        "Test responsive design: verify mobile, tablet, desktop layouts",
        "Check accessibility: run `npm run a11y-check`",
        "Verify all metrics update in real-time (WebSocket connection)"
    ],
    additional_context="""
CONTEXT:
- Use React with TypeScript
- Component location: src/components/Dashboard/
- Use existing design system from src/components/ui/
- WebSocket connection already set up in src/services/websocket.ts
- Follow accessibility guidelines (WCAG 2.1 AA)
- Metrics to display: CPU usage, memory, active users, request rate
"""
)
```

### Example Usage: Infrastructure Task

```python
prompt = generate_task_prompt(
    task_description="Integrate React build into CDK deployment pipeline",
    feature_branch="feature/cdk-integration",
    home_workspace="charlie/main-workspace",
    repo_path="/workspaces/mvp-ai-demo",
    validation_requirements=[
        "Run full build: `npm run build` - must succeed with zero errors",
        "Test CDK synth: `npx cdk synth -c envName=dev -c siteAssetsPath=../dist`",
        "Verify dist/ directory contains built assets",
        "Check vite.config.ts imports from correct package (vitest/config not vite)",
        "Run type checker: `npm run type-check` - must pass",
        "Test deployment to dev environment: `npx cdk deploy -c envName=dev`"
    ],
    additional_context="""
CONTEXT:
- React app is in /workspaces/mvp-ai-demo/frontend
- CDK infrastructure is in /workspaces/mvp-ai-demo/infrastructure
- Build output should go to frontend/dist
- CDK needs to reference ../dist for site assets
- Use S3 bucket for static hosting
- CloudFront distribution for CDN
"""
)
```

### Validation Script Template

Create reusable validation scripts for common project types:

```bash
#!/bin/bash
# validation.sh - Run before task completion

set -e

echo "🔍 Running pre-completion validation..."

# Build validation
echo "1. Build validation..."
npm run build
echo "✅ Build succeeded"

# Type checking
echo "2. Type checking..."
npm run type-check || tsc --noEmit
echo "✅ Type checking passed"

# Tests
echo "3. Running tests..."
npm test
echo "✅ Tests passed"

# Linting
echo "4. Linting..."
npm run lint
echo "✅ Linting passed"

# Optional: Integration tests
if [ -f "package.json" ] && grep -q "test:integration" package.json; then
    echo "5. Integration tests..."
    npm run test:integration
    echo "✅ Integration tests passed"
fi

echo "✅ All validations passed - ready to complete task"
```

**Include validation script in task workspace:**

```python
# Write validation script to task workspace
validation_script = """#!/bin/bash
set -e
echo "🔍 Running pre-completion validation..."
npm run build
npm run type-check || tsc --noEmit
npm test
npm run lint
echo "✅ All validations passed"
"""

coder_workspace_write_file(
    workspace=task_workspace,
    path="/home/coder/validation.sh",
    content=base64.b64encode(validation_script.encode()).decode()
)

# Make executable
coder_workspace_bash(
    workspace=task_workspace,
    command="chmod +x /home/coder/validation.sh",
    timeout_ms=5000
)

# Include in task prompt
prompt += """

VALIDATION SCRIPT:
A validation script is available at /home/coder/validation.sh
Run it before completing: `bash /home/coder/validation.sh`
"""
```

### Template for Different Project Types

**Python Project:**
```python
validation_requirements=[
    "Run tests: `pytest` - all tests must pass",
    "Run type checker: `mypy .` - zero type errors",
    "Run linter: `ruff check .` - fix all issues",
    "Check code formatting: `black --check .`",
    "Verify requirements.txt is updated"
]
```

**Go Project:**
```python
validation_requirements=[
    "Run tests: `go test ./...` - all tests must pass",
    "Run linter: `golangci-lint run` - fix all issues",
    "Check formatting: `gofmt -l .` - should return nothing",
    "Build binary: `go build` - must succeed",
    "Verify go.mod and go.sum are updated"
]
```

**Rust Project:**
```python
validation_requirements=[
    "Run tests: `cargo test` - all tests must pass",
    "Run clippy: `cargo clippy` - fix all warnings",
    "Check formatting: `cargo fmt --check`",
    "Build release: `cargo build --release` - must succeed",
    "Verify Cargo.toml dependencies are correct"
]
```

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
- **Include validation requirements in every prompt**
- **Specify git workflow expectations clearly**

**Resource management:**
- Don't leave workspaces running unnecessarily
- Stop workspaces after work completes or fails
- Monitor task state to know when work is done
- Use timeouts to avoid infinite waiting
- **Stop workspaces immediately after work transfer**

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
