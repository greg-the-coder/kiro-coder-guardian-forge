# Coder Guardian Forge — Execution Plan

Your step-by-step plan to complete and unit test the Coder Guardian Forge Power in your current Coder workspace.

---

## Overview

You now have a complete prototype of the Coder Guardian Forge Power with:
- ✅ Core power files (mcp.json, POWER.md)
- ✅ Steering files (task-workflow.md, workspace-ops.md, agent-interaction.md)
- ✅ Agent collaboration capabilities (coder_send_task_input, coder_get_task_logs)
- ✅ Comprehensive testing plan
- ✅ Quick start guide
- ✅ Documentation

**Next:** Execute the testing plan to validate everything works, including the new agent interaction features.

**New in this version:** Phase 6 includes comprehensive tests for agent-to-agent collaboration, covering all four collaboration patterns (Orchestrator, Delegator, Hybrid, Iterative).

---

## Phase 1: Pre-Testing Setup (15 minutes)

### Step 1.1: Verify Coder Server Configuration

**Check with your Coder admin:**
```
Is the mcp-server-http experiment enabled on the Coder server?
```

The server must be started with:
```bash
CODER_EXPERIMENTS="oauth2,mcp-server-http" coder server
```

**Verify endpoint is accessible:**
```bash
curl -I https://your-coder-server.com/api/experimental/mcp/http
```

Expected: HTTP 200 or 401 (not 404)

### Step 1.2: Get Your Coder API Token

1. Open Coder web UI in browser
2. Navigate to **Account → Tokens**
3. Click **Generate Token**
4. Copy the token value
5. Save it securely (you'll need it in next step)

### Step 1.3: Set Environment Variables

Add to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
# Coder Guardian Forge Configuration
export CODER_URL="https://your-coder-server.com/"  # Your Coder server URL (with trailing slash)
export CODER_TOKEN="<paste-your-token-here>"        # Token from Step 1.2
```

**Note:** If you're running Kiro inside a Coder workspace, `CODER_URL` is already injected with a trailing slash. You only need to set `CODER_TOKEN`:
```bash
export CODER_TOKEN="<paste-your-token-here>"
```

**Why the trailing slash matters:** The mcp.json configuration is designed to work with Coder's standard `CODER_URL` format, which includes a trailing slash. This ensures compatibility when Kiro is running inside a Coder workspace.

**Apply changes:**
```bash
source ~/.zshrc  # or ~/.bashrc
```

**Verify:**
```bash
echo $CODER_URL
echo $CODER_TOKEN
```

Both should show values (not empty).

### Step 1.4: Test Token Manually

```bash
curl -H "Authorization: Bearer $CODER_TOKEN" $CODER_URL/api/v2/users/me
```

Expected: JSON response with your user information

If this fails, your token or URL is incorrect.

### Step 1.5: Verify Templates Exist

Check Coder web UI → Templates

You need at least one workspace template configured. If none exist, ask your Coder admin to create one.

**Checklist:**
- [ ] MCP HTTP experiment enabled on server
- [ ] API token generated
- [ ] Environment variables set and verified
- [ ] Token works (curl test passes)
- [ ] At least one template exists

---

## Phase 2: Install and Activate Power (10 minutes)

### Step 2.1: Install Power in Kiro

**Option A: Using Kiro Chat**
```
Open the Powers configuration panel
```

**Option B: Direct Action**
In Kiro, trigger the configure action for powers.

**Then:**
1. Click "Add Custom Power" button at top
2. Select "Local Directory" option
3. Enter path: `/home/coder/kiro-coder-guardian-forge`
4. Click "Add" to install

**Verify:**
- Power appears in installed powers list
- Name: "Coder Guardian Forge"
- No installation errors

### Step 2.2: Activate Power

In Kiro chat:
```
Activate the coder-guardian-forge power
```

**Expected output:**
```
Connected to Coder as <your-username> at <your-coder-url>. Ready to create agent tasks.
```

**If connection fails:**
- Check environment variables are set
- Verify token is valid
- Confirm MCP HTTP experiment is enabled
- **Check for trailing slash:** If `CODER_URL` doesn't end with `/`, add it: `export CODER_URL="${CODER_URL}/"`
- Review troubleshooting in QUICK-START.md

### Step 2.3: Verify Templates Listed

Kiro should automatically list available templates during activation.

**If not shown, ask:**
```
Show me available Coder templates
```

**Expected:**
- List of templates with names
- Each template shows ActiveVersionID
- At least one template available

### Step 2.4: Verify Hook Created

Check if hook file exists:
```bash
ls -la .kiro/hooks/coder-task-complete.kiro.hook
```

**Expected:**
- File exists
- Contains valid JSON
- Hook is enabled

**View hook:**
```bash
cat .kiro/hooks/coder-task-complete.kiro.hook
```

**Checklist:**
- [ ] Power installed successfully
- [ ] Connection verified (username shown)
- [ ] Templates listed
- [ ] Hook file created

---

## Phase 3: Basic Functionality Tests (20 minutes)

### Test 3.1: Create Your First Task

In Kiro chat:
```
I want to create a Coder task to test the workspace
```

**Expected flow:**
1. Kiro shows available templates
2. Kiro asks which template to use
3. You respond: "Use the <template-name> template"
4. Kiro calls `coder_create_task`
5. Kiro says: "Task created — you can follow along in the Coder Tasks UI"

**Verify in Coder UI:**
1. Open Coder web UI → Tasks
2. New task should appear within 60 seconds
3. Status should be "pending" or "starting"

**Wait for workspace:**
- Kiro should poll `coder_get_task_status` every 10 seconds
- Wait for status to become "running" (may take 2-5 minutes)
- Kiro should report: "Workspace ready, starting work"

**Check Tasks UI:**
- Status should update to "working"
- Progress summary should show

**Checklist:**
- [ ] Task created successfully
- [ ] Task appears in Coder Tasks UI
- [ ] Workspace reaches "running" status
- [ ] Tasks UI shows "working" status

### Test 3.2: Run Simple Commands

In Kiro chat:
```
Run 'pwd' in the workspace
```

**Expected:**
- Command executes successfully
- Output shows workspace directory (e.g., `/home/coder`)
- Exit code is 0

**Try more commands:**
```
List the contents of /home/coder
```

```
Check if git is installed in the workspace
```

**Checklist:**
- [ ] Commands execute successfully
- [ ] Output is displayed correctly
- [ ] Exit codes are 0

### Test 3.3: File Operations

**Create a file:**
```
Create a file at /home/coder/test.txt with content "Hello from Coder Guardian Forge"
```

**Read the file:**
```
Read the file /home/coder/test.txt
```

**Edit the file:**
```
Change "Hello" to "Greetings" in /home/coder/test.txt
```

**Verify the change:**
```
Read the file /home/coder/test.txt again
```

**Checklist:**
- [ ] File created successfully
- [ ] File read shows correct content
- [ ] File edited successfully
- [ ] Changes verified

### Test 3.4: Progress Reporting

During the above operations, check Coder Tasks UI:

**Expected:**
- Progress updates appear after each operation
- Summaries are clear and concise
- Status remains "working"

**Checklist:**
- [ ] Progress updates appear in Tasks UI
- [ ] Summaries are clear (<160 chars)
- [ ] Updates are timely

### Test 3.5: Complete the Task

**Option A: Use the hook**
- Find "Report Coder Task Complete" in Kiro Agent Hooks UI
- Trigger the hook

**Option B: Say it**
```
The work is complete
```

**Expected flow:**
1. Kiro reports task as "idle" with summary
2. Kiro asks if you want to stop the workspace
3. Respond: "Yes, stop the workspace"
4. Kiro stops the workspace

**Verify in Tasks UI:**
- Task status shows "idle"
- Workspace stops

**Checklist:**
- [ ] Task reported as "idle"
- [ ] Summary describes work done
- [ ] Workspace stopped successfully
- [ ] Tasks UI shows final status

---

## Phase 4: Advanced Tests (30 minutes)

### Test 4.1: Check for Existing Tasks

Create a new task but don't complete it:
```
I want to create another Coder task for testing
```

Then immediately try to create another:
```
I want to start working on a new feature using Coder
```

**Expected:**
- Kiro checks for existing tasks
- Kiro informs you about the running task
- Kiro asks if you want to use existing or create new

**Checklist:**
- [ ] Existing task detected
- [ ] User informed
- [ ] Choice offered

### Test 4.2: Background Process

In a running task workspace:
```
Start a simple HTTP server in the background on port 8000
```

**Expected:**
- Command runs with `background=true`
- Returns immediately
- Process continues running

**Verify:**
```
Check if the server is running
```

**Checklist:**
- [ ] Background process started
- [ ] Command returns immediately
- [ ] Process verified as running

### Test 4.3: Error Handling

**Test command failure:**
```
Run 'nonexistent-command' in the workspace
```

**Expected:**
- Command fails with exit code 127
- Error is reported clearly
- Kiro suggests corrective action

**Test file not found:**
```
Read the file /home/coder/does-not-exist.txt
```

**Expected:**
- Operation fails with clear error
- Error indicates file not found
- Kiro suggests checking path

**Checklist:**
- [ ] Command failures detected
- [ ] Errors reported clearly
- [ ] Suggestions provided

### Test 4.4: Task Failure

In a running task:
```
This is a critical error, fail the task
```

**Expected:**
1. Kiro reports task as "failure" with description
2. Kiro stops the workspace immediately
3. Tasks UI shows "failure" status

**Checklist:**
- [ ] Task reported as "failure"
- [ ] Workspace stopped
- [ ] Tasks UI shows failure

---

## Phase 5: End-to-End Acceptance Test (15 minutes)

This is the primary acceptance test from REQUIREMENTS.md.

### Complete Workflow

1. **Prerequisites verified** ✓ (Phase 1)
2. **Power installed** ✓ (Phase 2)
3. **Connection verified** ✓ (Phase 2)

4. **Create task:**
   ```
   I want to start working on a new feature using Coder
   ```

5. **Confirm template** when asked

6. **Wait for task creation:**
   - Task appears in Coder Tasks UI within 60 seconds
   - Status shows "starting"

7. **Wait for workspace:**
   - Kiro polls until "running"
   - Tasks UI updates to "working"

8. **Run command:**
   ```
   Run 'ls /home/coder' in the workspace
   ```
   - Output is displayed

9. **Complete task:**
   - Trigger "Report Coder Task Complete" hook
   - Tasks UI shows "idle"
   - Workspace stops

**Acceptance Criteria:**
- [ ] All steps complete without errors
- [ ] Task visible in UI throughout
- [ ] Commands execute successfully
- [ ] Status updates appear in UI
- [ ] Workspace stops cleanly

**If this test passes, the prototype is working!**

---

## Phase 6: Agent Interaction Tests (45 minutes)

These tests validate the new agent collaboration capabilities using `coder_send_task_input` and `coder_get_task_logs`.

### Test 6.1: Verify Agent Interaction Steering File

**Load the steering file:**
```
Load the agent-interaction steering file
```

**Expected:**
- Kiro loads `steering/agent-interaction.md`
- Kiro confirms understanding of agent collaboration patterns

**Verify understanding:**
```
What are the four agent collaboration patterns?
```

**Expected response should mention:**
1. Orchestrator pattern
2. Delegator pattern
3. Hybrid pattern
4. Iterative pattern

**Checklist:**
- [ ] Steering file loads successfully
- [ ] Kiro understands collaboration patterns
- [ ] Four patterns explained correctly

### Test 6.2: Basic Prompt Sending (Delegator Pattern)

**Create a task with a workspace agent:**
```
Create a Coder task for testing agent interaction
```

**Wait for workspace to be running**

**Send a simple prompt to the workspace agent:**
```
Send this prompt to the workspace agent: "Create a file at /home/coder/agent-test.txt with the content 'Hello from workspace agent'"
```

**Expected:**
- Kiro calls `coder_send_task_input`
- Prompt is delivered to workspace agent
- Kiro monitors task state

**Monitor progress:**
```
What's the current task state?
```

**Expected:**
- Kiro calls `coder_get_task_status`
- Shows current state (working, idle, or failure)
- Displays state message if available

**Check logs for agent response:**
```
Show me the task logs
```

**Expected:**
- Kiro calls `coder_get_task_logs`
- Logs show agent activity
- Can see if agent processed the prompt

**Verify the result:**
```
Read the file /home/coder/agent-test.txt
```

**Expected:**
- File exists (if workspace agent processed the prompt)
- Content matches what was requested

**Checklist:**
- [ ] Prompt sent successfully
- [ ] Task state monitored
- [ ] Logs retrieved and displayed
- [ ] Agent activity visible in logs

### Test 6.3: Orchestrator Pattern

**Create a new task:**
```
Create a Coder task for orchestrator pattern testing
```

**Wait for running, then set up structure yourself:**
```
Create a directory at /home/coder/project
Create a file at /home/coder/project/README.md with content "# Test Project"
```

**Now delegate implementation to workspace agent:**
```
Send this prompt to the workspace agent: "In the /home/coder/project directory, create a simple Python script called hello.py that prints 'Hello, World!'"
```

**Monitor until idle:**
```
Monitor the task state until the workspace agent is idle
```

**Expected:**
- Kiro polls `coder_get_task_status` periodically
- Waits for state to change from "working" to "idle"
- Reports when agent completes

**Verify the work:**
```
Read the file /home/coder/project/hello.py
```

**Run the script yourself:**
```
Run 'python3 /home/coder/project/hello.py' in the workspace
```

**Expected:**
- File exists and contains Python code
- Script runs and prints "Hello, World!"

**Checklist:**
- [ ] External agent set up structure
- [ ] Prompt delegated to workspace agent
- [ ] Monitoring worked correctly
- [ ] Workspace agent completed task
- [ ] Results verified

### Test 6.4: Iterative Pattern

**Create a new task:**
```
Create a Coder task for iterative pattern testing
```

**Wait for running, then send initial prompt:**
```
Send this prompt to the workspace agent: "Create a simple HTML file at /home/coder/form.html with a basic contact form (name and email fields)"
```

**Wait for completion:**
```
Monitor task state until idle
```

**Review the initial work:**
```
Read the file /home/coder/form.html
```

**Send refinement prompt:**
```
Send this prompt to the workspace agent: "Add a phone number field and a submit button to the form"
```

**Wait for completion:**
```
Monitor task state until idle
```

**Review the refined work:**
```
Read the file /home/coder/form.html again
```

**Expected:**
- Form now has phone field and submit button
- Previous fields (name, email) still present

**Send final refinement:**
```
Send this prompt to the workspace agent: "Add basic CSS styling to make the form look better"
```

**Wait and verify:**
```
Monitor task state until idle
Read the file /home/coder/form.html one more time
```

**Expected:**
- CSS styling added
- Form is improved iteratively

**Checklist:**
- [ ] Initial prompt created basic form
- [ ] First refinement added fields
- [ ] Second refinement added styling
- [ ] Iterative improvements worked

### Test 6.5: Hybrid Pattern

**Create a new task:**
```
Create a Coder task for hybrid pattern testing
```

**Wait for running, then start parallel work:**

**You (external agent) - Set up infrastructure:**
```
Create a file at /home/coder/Dockerfile with this content:
FROM python:3.11-slim
WORKDIR /app
COPY . .
CMD ["python", "app.py"]
```

**Workspace agent - Implement application:**
```
Send this prompt to the workspace agent: "Create a simple Python Flask app at /home/coder/app.py with a single route that returns 'Hello from Flask!'"
```

**While workspace agent works, you continue with infrastructure:**
```
Create a file at /home/coder/requirements.txt with content "flask==3.0.0"
```

**Monitor workspace agent:**
```
What's the task state?
```

**When idle, verify both parts:**
```
Read /home/coder/app.py
Read /home/coder/Dockerfile
Read /home/coder/requirements.txt
```

**Expected:**
- Infrastructure files created by you
- Application created by workspace agent
- Both parts work together

**Checklist:**
- [ ] External agent created infrastructure
- [ ] Workspace agent created application
- [ ] Parallel work completed
- [ ] Integration successful

### Test 6.6: Information Gathering

**Create a new task:**
```
Create a Coder task for information gathering
```

**Wait for running, then create some test files:**
```
Create a file at /home/coder/test1.py with content "print('test1')"
Create a file at /home/coder/test2.py with content "print('test2')"
Create a directory at /home/coder/src
Create a file at /home/coder/src/main.py with content "print('main')"
```

**Ask workspace agent for information:**
```
Send this prompt to the workspace agent: "List all Python files in /home/coder and its subdirectories, and tell me what each one does"
```

**Wait for response:**
```
Monitor task state until idle
```

**Check logs for agent's response:**
```
Show me the task logs
```

**Expected:**
- Logs contain agent's analysis
- Agent identified all Python files
- Agent described what each file does

**Checklist:**
- [ ] Prompt sent successfully
- [ ] Workspace agent analyzed files
- [ ] Response visible in logs
- [ ] Information extracted successfully

### Test 6.7: Error Handling in Agent Interaction

**Create a new task:**
```
Create a Coder task for error handling testing
```

**Wait for running, then send a prompt that will cause an error:**
```
Send this prompt to the workspace agent: "Install a package called 'nonexistent-package-xyz-123' using pip"
```

**Monitor the task:**
```
Monitor task state
```

**Expected:**
- Task state may show "failure" or "idle" with error
- Workspace agent reports the error

**Check logs:**
```
Show me the task logs
```

**Expected:**
- Logs show error message
- Error indicates package not found

**Send corrective prompt:**
```
Send this prompt to the workspace agent: "That's okay, the package doesn't exist. Just create a simple text file at /home/coder/recovery.txt with content 'Recovered from error'"
```

**Verify recovery:**
```
Monitor task state until idle
Read /home/coder/recovery.txt
```

**Expected:**
- Workspace agent recovered
- File created successfully

**Checklist:**
- [ ] Error detected in task state
- [ ] Error visible in logs
- [ ] Corrective prompt sent
- [ ] Recovery successful

### Test 6.8: Monitoring and Log Parsing

**Create a new task:**
```
Create a Coder task for monitoring testing
```

**Wait for running, then send a long-running prompt:**
```
Send this prompt to the workspace agent: "Create 5 text files named file1.txt through file5.txt, each with different content. Take your time and report progress."
```

**Monitor with polling:**
```
Check task state every 30 seconds until idle
```

**Expected:**
- Kiro polls periodically
- State changes from "working" to "idle"
- Kiro reports when complete

**Check logs multiple times:**
```
Show me the task logs
```

**Wait 10 seconds, then:**
```
Show me the task logs again
```

**Expected:**
- Logs grow over time
- Can see agent progress
- New log entries appear

**Verify all files created:**
```
List the contents of /home/coder
```

**Expected:**
- All 5 files exist

**Checklist:**
- [ ] Monitoring loop worked
- [ ] State changes detected
- [ ] Logs updated over time
- [ ] Progress visible

### Test 6.9: Complete Agent Interaction Workflow

**Full end-to-end test of agent collaboration:**

1. **Create task:**
   ```
   Create a Coder task for a complete agent collaboration test
   ```

2. **Wait for running**

3. **Set up project structure (you):**
   ```
   Create a directory at /home/coder/webapp
   Create a file at /home/coder/webapp/README.md with content "# Web Application"
   ```

4. **Delegate implementation (workspace agent):**
   ```
   Send this prompt to the workspace agent: "In /home/coder/webapp, create a simple web application with an index.html file that has a form for user registration (name, email, password fields) and basic CSS styling"
   ```

5. **Monitor progress:**
   ```
   Monitor task state until idle
   ```

6. **Review work:**
   ```
   Read /home/coder/webapp/index.html
   ```

7. **Provide feedback:**
   ```
   Send this prompt to the workspace agent: "Add form validation - email should be required and password should be at least 8 characters"
   ```

8. **Monitor again:**
   ```
   Monitor task state until idle
   ```

9. **Verify improvements:**
   ```
   Read /home/coder/webapp/index.html
   ```

10. **Add infrastructure (you):**
    ```
    Create a file at /home/coder/webapp/server.py with a simple HTTP server
    ```

11. **Complete and stop:**
    ```
    The work is complete. Stop the workspace.
    ```

**Expected:**
- Complete workflow executes smoothly
- External and workspace agents collaborate effectively
- All files created correctly
- Workspace stops cleanly

**Checklist:**
- [ ] Task created
- [ ] Structure set up by external agent
- [ ] Implementation delegated to workspace agent
- [ ] Monitoring worked
- [ ] Feedback incorporated
- [ ] Infrastructure added by external agent
- [ ] Workspace stopped

### Test 6.10: Quick Reference Validation

**Verify the quick reference guide is accurate:**

```
Show me the agent interaction quick reference
```

**Or manually review:**
```bash
cat kiro-coder-guardian-forge/AGENT-INTERACTION-QUICK-REF.md
```

**Verify:**
- [ ] Tool syntax matches actual usage
- [ ] Patterns match what you tested
- [ ] Examples are accurate
- [ ] Troubleshooting tips are helpful

**Test a workflow from the quick reference:**

Pick one workflow example from the quick reference and execute it exactly as documented.

**Expected:**
- Workflow works as documented
- No errors or confusion
- Results match expectations

**Checklist:**
- [ ] Quick reference reviewed
- [ ] Workflow example tested
- [ ] Documentation is accurate

---

## Phase 7: Comprehensive Testing (Optional, 60+ minutes)

For thorough validation beyond agent interaction, follow the complete testing plan:

**Reference:** `TESTING-PLAN.md`

**Phases to complete:**
1. ✓ Setup (completed in Phase 1-2 above)
2. ✓ Task Creation (completed in Phase 3 above)
3. ✓ Workspace Operations (completed in Phase 3 above)
4. ✓ Progress Reporting (completed in Phase 3 above)
5. ✓ Task Completion (completed in Phase 3 above)
6. ✓ Advanced Scenarios (completed in Phase 4 above)
7. ✓ Agent Interaction (completed in Phase 6 above)
8. Error Handling (additional tests in TESTING-PLAN.md)
9. ✓ End-to-End (completed in Phase 5 above)
10. Documentation and Cleanup

**Follow TESTING-PLAN.md for:**
- Additional error handling tests
- Edge case scenarios
- Documentation verification
- Resource cleanup

---

## Phase 8: Documentation and Cleanup (15 minutes)

### Step 8.1: Document Test Results

Create a test results file:
```bash
cat > kiro-coder-guardian-forge/TEST-RESULTS.md << 'EOF'
# Test Results

## Date: $(date)
## Tester: <your-name>

## Summary
- Total tests run: <number>
- Tests passed: <number>
- Tests failed: <number>
- Issues found: <number>

## Test Results by Phase

### Phase 1: Setup
- [ ] All setup tests passed

### Phase 2: Installation
- [ ] All installation tests passed

### Phase 3: Basic Functionality
- [ ] All basic tests passed

### Phase 4: Advanced Tests
- [ ] All advanced tests passed

### Phase 5: Acceptance Test
- [ ] Acceptance test passed

### Phase 6: Agent Interaction Tests
- [ ] All agent interaction tests passed

## Issues Found

1. Issue description
   - Severity: High/Medium/Low
   - Steps to reproduce
   - Expected vs actual behavior

## Recommendations

1. Recommendation for improvement

## Conclusion

The prototype is: [ ] Ready for use [ ] Needs fixes
EOF
```

Fill in the results based on your testing.

### Step 8.2: Clean Up Test Resources

List all test tasks:
```
Show me all Coder tasks
```

For each test task:
```
Stop and delete the task named <task-name>
```

Or manually in Coder UI:
1. Go to Tasks
2. Stop any running test workspaces
3. Delete test tasks

### Step 8.3: Review Documentation

Quick review checklist:
- [ ] POWER.md is accurate
- [ ] Steering files are accurate
- [ ] Examples work as documented
- [ ] Troubleshooting steps are helpful

---

## Success Criteria

The prototype is complete and ready when:

✅ **All Phase 1-6 tests pass**
✅ **Acceptance test (Phase 5) passes without errors**
✅ **Agent interaction tests (Phase 6) pass without errors**
✅ **Documentation is accurate**
✅ **Test results are documented**
✅ **Test resources are cleaned up**

---

## Timeline Estimate

| Phase | Time | Cumulative |
|---|---|---|
| Phase 1: Pre-Testing Setup | 15 min | 15 min |
| Phase 2: Install and Activate | 10 min | 25 min |
| Phase 3: Basic Functionality | 20 min | 45 min |
| Phase 4: Advanced Tests | 30 min | 75 min |
| Phase 5: Acceptance Test | 15 min | 90 min |
| Phase 6: Agent Interaction Tests | 45 min | 135 min |
| Phase 7: Comprehensive (optional) | 60 min | 195 min |
| Phase 8: Documentation | 15 min | 150 min (or 210 min) |

**Minimum viable testing:** 90 minutes (Phases 1-5, 8)
**With agent interaction:** 150 minutes (Phases 1-6, 8)
**Comprehensive testing:** 210 minutes (all phases)

---

## Troubleshooting

### Common Issues

**"Failed to connect to Coder"**
- Check `CODER_URL` and `CODER_TOKEN` are set
- Verify token with curl test
- Confirm MCP HTTP experiment enabled

**"No templates available"**
- Ask admin to create templates
- Check permissions in Coder UI

**"Task stuck in pending"**
- Wait up to 5 minutes
- Check Coder server logs
- Verify template configuration

**"Command timeout"**
- Increase timeout for long operations
- Use background mode for long processes

**"File operation failed"**
- Check path is absolute
- Verify file/directory exists
- Check permissions

### Getting Help

- Review `QUICK-START.md` for setup help
- Review `TESTING-PLAN.md` for detailed test procedures
- Review `POWER.md` troubleshooting section
- Check Coder documentation: https://coder.com/docs
- Check Kiro documentation: https://kiro.dev/docs

---

## Next Steps After Testing

Once testing is complete and successful:

1. **Document any issues** found during testing
2. **Create fixes** for any bugs discovered
3. **Update documentation** based on testing insights
4. **Create example workflows** for common use cases
5. **Prepare for sharing:**
   - mcp.json already uses env vars (safe to share)
   - Consider adding icon (512x512 PNG)
   - Consider submitting to Kiro recommended powers
6. **Share with team** or community

---

## Quick Reference

**Start testing:**
```bash
# Set environment variables (with trailing slash)
export CODER_URL="https://your-coder-server.com/"  # With trailing slash
export CODER_TOKEN="<your-token>"

# Or if CODER_URL is already set without trailing slash:
export CODER_URL="${CODER_URL}/"  # Adds trailing slash
export CODER_TOKEN="<your-token>"

# Verify
echo $CODER_URL
echo $CODER_TOKEN

# Test token
curl -H "Authorization: Bearer $CODER_TOKEN" ${CODER_URL}api/v2/users/me
```

**Install power:**
- Open Kiro Powers panel
- Add custom power from `/home/coder/kiro-coder-guardian-forge`

**Activate power:**
```
Activate the coder-guardian-forge power
```

**Create first task:**
```
I want to create a Coder task to test the workspace
```

**Complete task:**
```
The work is complete
```

**Test agent interaction:**
```
# Load agent interaction steering
Load the agent-interaction steering file

# Send prompt to workspace agent
Send this prompt to the workspace agent: "Create a file at /home/coder/test.txt"

# Monitor task state
What's the current task state?

# Check logs
Show me the task logs

# Monitor until complete
Monitor task state until idle
```

---

## Checklist

Use this checklist to track your progress:

### Pre-Testing
- [ ] MCP HTTP experiment verified
- [ ] API token generated
- [ ] Environment variables set
- [ ] Token tested with curl
- [ ] Templates exist

### Installation
- [ ] Power installed in Kiro
- [ ] Connection verified
- [ ] Templates listed
- [ ] Hook created

### Basic Tests
- [ ] Task created successfully
- [ ] Workspace reached running state
- [ ] Commands executed
- [ ] Files created/read/edited
- [ ] Progress reported
- [ ] Task completed

### Advanced Tests
- [ ] Existing tasks detected
- [ ] Background processes work
- [ ] Errors handled gracefully
- [ ] Task failure works

### Agent Interaction Tests
- [ ] Steering file loads
- [ ] Prompts sent to workspace agent
- [ ] Task state monitored
- [ ] Logs retrieved and parsed
- [ ] Orchestrator pattern works
- [ ] Delegator pattern works
- [ ] Hybrid pattern works
- [ ] Iterative pattern works
- [ ] Information gathering works
- [ ] Error handling works
- [ ] Complete workflow passes

### Acceptance Test
- [ ] Complete end-to-end workflow passed

### Documentation
- [ ] Test results documented
- [ ] Resources cleaned up
- [ ] Documentation reviewed

---

**You're ready to start testing! Begin with Phase 1 and work through each phase systematically.**

**Good luck! 🚀**
