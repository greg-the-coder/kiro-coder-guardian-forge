# Coder Guardian Forge — Testing Plan

This document outlines the complete plan for testing and validating the Coder Guardian Forge Power in your Coder workspace.

---

## Prerequisites

Before starting testing, ensure you have:

1. **Coder deployment with MCP HTTP server enabled**
   - Admin must have started Coder with: `CODER_EXPERIMENTS="oauth2,mcp-server-http" coder server`
   - Verify endpoint is accessible: `https://<your-coder-server>/api/experimental/mcp/http`

2. **Coder API token**
   - Generate from Coder web UI → Account → Tokens
   - Token should have full workspace permissions

3. **At least one workspace template**
   - Check Coder web UI → Templates
   - Note the template name and ActiveVersionID

4. **Environment variables set**
   ```bash
   export CODER_URL="https://coder.mycompany.com/"  # Your Coder server URL (with trailing slash)
   export CODER_TOKEN="<your-token-here>"            # Token from step 2
   ```

   **Note:** If running Kiro inside a Coder workspace, `CODER_URL` is already set with a trailing slash. You only need to set `CODER_TOKEN`.

5. **Kiro installed and running**
   - Verify Kiro can access environment variables
   - Check: `echo $CODER_URL` and `echo $CODER_TOKEN` in Kiro's terminal

---

## Phase 1: Power Installation and Setup

### Test 1.1: Install Power Locally

**Objective:** Install the power from local directory and verify it loads correctly.

**Steps:**
1. Open Kiro Powers panel (use configure action or UI)
2. Click "Add Custom Power" button
3. Select "Local Directory" option
4. Enter path: `/home/coder/kiro-coder-guardian-forge`
5. Click "Add" to install

**Expected Results:**
- Power appears in installed powers list
- Name: "Coder Guardian Forge"
- Description shows correctly
- No installation errors

**Validation:**
```
✅ Power installed successfully
✅ Power appears in powers list
✅ Metadata (name, description, keywords) displays correctly
```

### Test 1.2: Activate Power and Verify Connection

**Objective:** Activate the power and verify it can connect to Coder MCP server.

**Steps:**
1. In Kiro chat, say: "Activate the coder-guardian-forge power"
2. Kiro should automatically call `coder_get_authenticated_user`
3. Observe the connection verification message

**Expected Results:**
- Connection succeeds
- Message displays: "Connected to Coder as <username> at <server-url>. Ready to create agent tasks."
- Your username and Coder URL are shown correctly

**Validation:**
```
✅ coder_get_authenticated_user succeeds
✅ Username displayed correctly
✅ Coder URL displayed correctly
✅ No authentication errors
```

**Troubleshooting if connection fails:**
- Verify `CODER_URL` is set: `echo $CODER_URL`
- Verify `CODER_TOKEN` is set: `echo $CODER_TOKEN`
- Check URL format: includes `https://` or `http://`
- Test token manually: `curl -H "Authorization: Bearer $CODER_TOKEN" $CODER_URL/api/v2/users/me`
- Confirm admin enabled `mcp-server-http` experiment

### Test 1.3: List Available Templates

**Objective:** Verify the power can list workspace templates.

**Steps:**
1. In Kiro chat, say: "Show me available Coder templates"
2. Kiro should call `coder_list_templates`
3. Observe the template list

**Expected Results:**
- Templates are listed with names and descriptions
- Each template shows its ActiveVersionID
- At least one template is available

**Validation:**
```
✅ coder_list_templates succeeds
✅ Templates displayed with names
✅ ActiveVersionID shown for each template
✅ At least one template available
```

**Troubleshooting if no templates:**
- Ask Coder admin to create at least one workspace template
- Verify you have permission to view templates in Coder UI
- Check Coder web UI → Templates to confirm templates exist

### Test 1.4: Verify Hook Creation

**Objective:** Verify the task completion hook was created during onboarding.

**Steps:**
1. Check if hook file exists: `ls -la .kiro/hooks/coder-task-complete.kiro.hook`
2. Read hook contents: `cat .kiro/hooks/coder-task-complete.kiro.hook`
3. Verify hook appears in Kiro's Agent Hooks UI

**Expected Results:**
- Hook file exists at `.kiro/hooks/coder-task-complete.kiro.hook`
- Hook contains correct JSON structure
- Hook is enabled and appears in Kiro UI

**Validation:**
```
✅ Hook file exists
✅ Hook JSON is valid
✅ Hook type is "userTriggered"
✅ Hook action is "askAgent"
✅ Hook appears in Kiro Agent Hooks UI
```

---

## Phase 2: Task Creation Workflow

### Test 2.1: Create a Simple Task

**Objective:** Create a Coder Task and verify it appears in the Tasks UI.

**Steps:**
1. In Kiro chat, say: "I want to create a Coder task to test the workspace"
2. Kiro should load `task-workflow.md` steering file
3. Kiro should show available templates and ask for confirmation
4. Confirm a template (e.g., "Use the python-dev template")
5. Kiro should call `coder_create_task`
6. Open Coder web UI → Tasks to verify task appears

**Expected Results:**
- Kiro shows available templates
- Kiro asks for confirmation before creating task
- `coder_create_task` succeeds
- Task appears in Coder Tasks UI within 60 seconds
- Task status shows as "pending" or "starting"
- Task description matches what you told Kiro

**Validation:**
```
✅ Templates listed correctly
✅ User confirmation requested
✅ coder_create_task succeeds
✅ Task appears in Coder Tasks UI
✅ Task status is "pending" or "starting"
✅ Task description is clear and accurate
```

### Test 2.2: Wait for Workspace to Be Ready

**Objective:** Verify Kiro polls task status and waits for workspace to be running.

**Steps:**
1. After task creation, observe Kiro's behavior
2. Kiro should poll `coder_get_task_status` every 10 seconds
3. Wait for workspace to reach "running" status
4. Verify Kiro reports "working" state to Tasks UI

**Expected Results:**
- Kiro polls `coder_get_task_status` automatically
- Polling continues until status is "running"
- Kiro calls `coder_report_task` with state="working" and summary="Workspace ready, starting work"
- Tasks UI shows status updated to "working"
- Workspace is accessible

**Validation:**
```
✅ Kiro polls task status automatically
✅ Polling interval is ~10 seconds
✅ Polling stops when status is "running"
✅ coder_report_task called with state="working"
✅ Tasks UI shows "working" status
✅ Workspace is running and accessible
```

**Timeout test:**
- If workspace doesn't start within 5 minutes, Kiro should report failure
- Verify Kiro calls `coder_report_task` with state="failure"

### Test 2.3: Get Workspace Name

**Objective:** Verify Kiro retrieves the workspace name for subsequent operations.

**Steps:**
1. After workspace is running, observe Kiro's behavior
2. Kiro should call `coder_get_task_logs` to get workspace details
3. Verify Kiro extracts the workspace name

**Expected Results:**
- `coder_get_task_logs` succeeds
- Workspace name is extracted (format: `owner/workspace-name`)
- Kiro stores workspace name for future operations

**Validation:**
```
✅ coder_get_task_logs succeeds
✅ Workspace name extracted correctly
✅ Workspace name format is "owner/workspace-name"
✅ Kiro can use workspace name in subsequent calls
```

---

## Phase 3: Workspace Operations

### Test 3.1: Run Simple Commands

**Objective:** Verify Kiro can execute bash commands inside the workspace.

**Steps:**
1. In Kiro chat, say: "Run 'pwd' in the workspace"
2. Kiro should call `coder_workspace_bash` with command="pwd"
3. Observe the output

**Expected Results:**
- `coder_workspace_bash` succeeds
- Output shows workspace directory (e.g., `/home/coder`)
- Exit code is 0

**Validation:**
```
✅ coder_workspace_bash succeeds
✅ Command output is displayed
✅ Exit code is 0
✅ Output is correct (shows /home/coder or similar)
```

**Additional command tests:**
```bash
# Test 3.1a: List home directory
"List the contents of /home/coder"
Expected: coder_workspace_bash(command="ls -la /home/coder")

# Test 3.1b: Check environment
"Show environment variables in the workspace"
Expected: coder_workspace_bash(command="env")

# Test 3.1c: Check installed tools
"Check if git is installed in the workspace"
Expected: coder_workspace_bash(command="which git && git --version")
```

### Test 3.2: List Directory Contents

**Objective:** Verify Kiro can list directory contents using the file tool.

**Steps:**
1. In Kiro chat, say: "List the contents of /home/coder using the file tool"
2. Kiro should call `coder_workspace_ls` with path="/home/coder"
3. Observe the output

**Expected Results:**
- `coder_workspace_ls` succeeds
- Output shows files and directories with metadata
- Metadata includes size, permissions, modified time

**Validation:**
```
✅ coder_workspace_ls succeeds
✅ Files and directories listed
✅ Metadata displayed (size, permissions, time)
✅ Output is structured and readable
```

### Test 3.3: Read a File

**Objective:** Verify Kiro can read file contents.

**Steps:**
1. First, create a test file: "Create a file at /home/coder/test.txt with content 'Hello from Coder'"
2. Then read it: "Read the file /home/coder/test.txt"
3. Kiro should call `coder_workspace_read_file`
4. Observe the output

**Expected Results:**
- `coder_workspace_write_file` succeeds (file creation)
- `coder_workspace_read_file` succeeds (file reading)
- File contents match what was written

**Validation:**
```
✅ coder_workspace_write_file succeeds
✅ coder_workspace_read_file succeeds
✅ File contents are correct
✅ No encoding issues
```

### Test 3.4: Write a New File

**Objective:** Verify Kiro can create new files with proper base64 encoding.

**Steps:**
1. In Kiro chat, say: "Create a file at /home/coder/config.yaml with this content: name: test-app, port: 8080"
2. Kiro should call `coder_workspace_write_file` with base64-encoded content
3. Verify file was created: "Read /home/coder/config.yaml"

**Expected Results:**
- `coder_workspace_write_file` succeeds
- Content is properly base64-encoded
- File is created at correct path
- Reading file back shows correct content

**Validation:**
```
✅ coder_workspace_write_file succeeds
✅ Content is base64-encoded
✅ File created at correct path
✅ File contents are correct when read back
```

### Test 3.5: Edit an Existing File

**Objective:** Verify Kiro can edit files using search/replace.

**Steps:**
1. Use the file created in Test 3.4
2. In Kiro chat, say: "Change the port in /home/coder/config.yaml from 8080 to 3000"
3. Kiro should call `coder_workspace_edit_file`
4. Verify the change: "Read /home/coder/config.yaml"

**Expected Results:**
- `coder_workspace_edit_file` succeeds
- oldText matches exactly
- newText replaces correctly
- File contents show the change

**Validation:**
```
✅ coder_workspace_edit_file succeeds
✅ Search text matched correctly
✅ Replacement applied correctly
✅ File contents updated as expected
```

### Test 3.6: Run Commands with Different Timeouts

**Objective:** Verify Kiro uses appropriate timeouts for different operations.

**Steps:**
1. Quick command: "Run 'echo hello' in the workspace"
   - Expected timeout: ~15000ms
2. Longer command: "Run 'sleep 5 && echo done' in the workspace"
   - Expected timeout: ~30000ms

**Expected Results:**
- Quick commands use short timeouts (15s)
- Longer commands use appropriate timeouts (30s+)
- Commands complete successfully within timeout

**Validation:**
```
✅ Quick commands use ~15s timeout
✅ Longer commands use appropriate timeout
✅ Commands complete within timeout
✅ No timeout errors for legitimate operations
```

---

## Phase 4: Progress Reporting

### Test 4.1: Report Progress During Work

**Objective:** Verify Kiro reports progress to Tasks UI during work.

**Steps:**
1. In Kiro chat, say: "Create a file, then read it, then edit it, reporting progress at each step"
2. Observe Kiro calling `coder_report_task` after each operation
3. Check Coder Tasks UI for progress updates

**Expected Results:**
- Kiro calls `coder_report_task` after each major step
- Each call has state="working"
- Summaries are clear and under 160 characters
- Tasks UI shows progress updates in real-time

**Validation:**
```
✅ coder_report_task called after each step
✅ state="working" for all progress reports
✅ Summaries are clear and concise (<160 chars)
✅ No newlines in summaries
✅ Tasks UI shows updates in real-time
```

**Example good summaries:**
- "Creating test file at /home/coder/test.txt"
- "Reading file contents for verification"
- "Editing file — updating configuration values"

### Test 4.2: Verify Summary Quality

**Objective:** Verify progress summaries follow best practices.

**Steps:**
1. Review all `coder_report_task` calls from previous tests
2. Check each summary for:
   - Length (must be ≤160 characters)
   - No newlines
   - Clear and specific
   - Present tense or present continuous

**Expected Results:**
- All summaries are ≤160 characters
- No summaries contain newlines
- All summaries are clear and specific
- Summaries describe current action

**Validation:**
```
✅ All summaries ≤160 characters
✅ No newlines in any summary
✅ Summaries are specific (not vague like "working")
✅ Summaries use appropriate tense
```

---

## Phase 5: Task Completion

### Test 5.1: Complete Task Successfully

**Objective:** Verify Kiro can properly complete a task.

**Steps:**
1. After completing some work in the workspace, say: "The work is complete"
2. Kiro should call `coder_report_task` with state="idle"
3. Kiro should ask if you want to stop the workspace
4. Respond: "Yes, stop the workspace"
5. Kiro should call `coder_create_workspace_build` with transition="stop"
6. Check Coder Tasks UI for status update

**Expected Results:**
- `coder_report_task` called with state="idle"
- Summary describes what was accomplished
- Kiro asks about stopping workspace
- `coder_create_workspace_build` called with transition="stop"
- Tasks UI shows task as "idle"
- Workspace stops gracefully

**Validation:**
```
✅ coder_report_task(state="idle") succeeds
✅ Summary describes accomplishments
✅ Kiro asks about stopping workspace
✅ coder_create_workspace_build(transition="stop") succeeds
✅ Tasks UI shows "idle" status
✅ Workspace stops successfully
```

### Test 5.2: Use Task Completion Hook

**Objective:** Verify the task completion hook works correctly.

**Steps:**
1. Create a new task and do some work
2. Trigger the "Report Coder Task Complete" hook from Kiro UI
3. Observe Kiro's behavior

**Expected Results:**
- Hook triggers successfully
- Kiro calls `coder_report_task` with state="idle" and summary
- Kiro calls `coder_create_workspace_build` with transition="stop"
- Task completes and workspace stops

**Validation:**
```
✅ Hook triggers from UI
✅ coder_report_task(state="idle") called
✅ Summary is clear and describes work
✅ coder_create_workspace_build(transition="stop") called
✅ Workspace stops
```

### Test 5.3: Handle Task Failure

**Objective:** Verify Kiro properly handles task failures.

**Steps:**
1. Create a new task
2. Simulate a failure: "Try to run a command that doesn't exist: 'nonexistent-command'"
3. Command should fail with exit code 127
4. Say: "This is a critical error, fail the task"
5. Observe Kiro's behavior

**Expected Results:**
- Command fails with non-zero exit code
- Kiro recognizes the failure
- Kiro calls `coder_report_task` with state="failure"
- Summary describes what went wrong
- Kiro calls `coder_create_workspace_build` with transition="stop"
- Workspace stops immediately

**Validation:**
```
✅ Command failure detected (exit_code != 0)
✅ coder_report_task(state="failure") called
✅ Summary describes the failure
✅ coder_create_workspace_build(transition="stop") called
✅ Workspace stops immediately
✅ Tasks UI shows "failure" status
```

---

## Phase 6: Advanced Scenarios

### Test 6.1: Check for Existing Tasks

**Objective:** Verify Kiro checks for existing tasks before creating new ones.

**Steps:**
1. Create a task and leave it running
2. Say: "I want to start working on a new feature using Coder"
3. Kiro should call `coder_list_tasks` to check for existing tasks
4. Kiro should inform you about the existing task
5. Kiro should ask if you want to use existing or create new

**Expected Results:**
- `coder_list_tasks` called before creating new task
- Existing running task is detected
- Kiro informs you about existing task
- Kiro asks for your preference

**Validation:**
```
✅ coder_list_tasks called proactively
✅ Existing task detected
✅ User informed about existing task
✅ User asked for preference (continue vs new)
```

### Test 6.2: List Running Applications

**Objective:** Verify Kiro can list exposed applications in workspace.

**Steps:**
1. Create a task with a template that exposes applications
2. Or manually start an app: "Start a simple HTTP server on port 8000"
3. Say: "Show me the running applications in the workspace"
4. Kiro should call `coder_workspace_list_apps`

**Expected Results:**
- `coder_workspace_list_apps` succeeds
- Applications are listed with names and URLs
- URLs are accessible

**Validation:**
```
✅ coder_workspace_list_apps succeeds
✅ Applications listed with names
✅ URLs provided for each app
✅ URLs are accessible (can be opened in browser)
```

### Test 6.3: Edit Multiple Files

**Objective:** Verify Kiro can edit multiple files atomically.

**Steps:**
1. Create two test files
2. Say: "Update both /home/coder/file1.txt and /home/coder/file2.txt — change 'old' to 'new' in both"
3. Kiro should call `coder_workspace_edit_files` (not multiple `edit_file` calls)
4. Verify both files were updated

**Expected Results:**
- `coder_workspace_edit_files` called (single call)
- Both files updated in one atomic operation
- Both files show correct changes when read back

**Validation:**
```
✅ coder_workspace_edit_files called (not edit_file)
✅ Single atomic operation for both files
✅ Both files updated correctly
✅ Changes verified by reading files back
```

### Test 6.4: Background Process

**Objective:** Verify Kiro can start background processes.

**Steps:**
1. Say: "Start a development server in the background on port 3000"
2. Kiro should call `coder_workspace_bash` with background=true
3. Verify process is running: "Check if the server is running"

**Expected Results:**
- `coder_workspace_bash` called with background=true
- Command returns immediately (doesn't wait for completion)
- Process continues running in background
- Process can be verified with `ps aux` or similar

**Validation:**
```
✅ coder_workspace_bash called with background=true
✅ Command returns immediately
✅ Process runs in background
✅ Process can be verified as running
```

---

## Phase 7: Error Handling and Edge Cases

### Test 7.1: Invalid Workspace Name

**Objective:** Verify Kiro handles invalid workspace names gracefully.

**Steps:**
1. Manually try to use an invalid workspace name
2. Say: "Run 'pwd' in workspace 'invalid/workspace-name'"
3. Observe error handling

**Expected Results:**
- Operation fails with clear error message
- Kiro recognizes the error
- Kiro suggests checking workspace name
- Kiro doesn't retry indefinitely

**Validation:**
```
✅ Operation fails with clear error
✅ Error message is informative
✅ Kiro suggests corrective action
✅ No infinite retry loops
```

### Test 7.2: Command Timeout

**Objective:** Verify Kiro handles command timeouts appropriately.

**Steps:**
1. Say: "Run 'sleep 30' with a 5 second timeout"
2. Command should timeout
3. Observe error handling

**Expected Results:**
- Command times out after 5 seconds
- Timeout error is reported
- Kiro suggests increasing timeout or using background mode
- Workspace remains functional

**Validation:**
```
✅ Command times out as expected
✅ Timeout error reported clearly
✅ Kiro suggests solutions
✅ Workspace still functional after timeout
```

### Test 7.3: File Not Found

**Objective:** Verify Kiro handles missing files gracefully.

**Steps:**
1. Say: "Read the file /home/coder/nonexistent.txt"
2. File doesn't exist
3. Observe error handling

**Expected Results:**
- Operation fails with "file not found" error
- Kiro recognizes the error
- Kiro suggests checking path or listing directory
- Kiro doesn't retry indefinitely

**Validation:**
```
✅ Operation fails with clear error
✅ Error indicates file not found
✅ Kiro suggests corrective action
✅ No infinite retry loops
```

### Test 7.4: Connection Lost

**Objective:** Verify Kiro handles connection issues gracefully.

**Steps:**
1. Create a task and start working
2. Simulate connection issue (if possible, or just test error handling logic)
3. Observe error handling

**Expected Results:**
- Connection error is detected
- Kiro reports the issue clearly
- Kiro suggests checking connection and workspace status
- Kiro reports task failure if connection can't be restored

**Validation:**
```
✅ Connection error detected
✅ Error reported clearly
✅ Kiro suggests troubleshooting steps
✅ Task failure reported if unrecoverable
```

---

## Phase 8: End-to-End Acceptance Test

### Test 8.1: Complete Workflow (Acceptance Criteria)

**Objective:** Execute the complete workflow from the requirements document.

**Steps:**
1. Set `CODER_URL` and `CODER_TOKEN` in environment ✓ (already done)
2. Install the Power in Kiro ✓ (already done)
3. See "Connected to Coder as <username>" during onboarding
4. Say: "I want to start working on a new feature using Coder"
5. Kiro shows available templates and asks for confirmation
6. Confirm a template
7. Kiro calls `coder_create_task`
8. Within 60 seconds, task appears in Coder Tasks UI with status "starting"
9. Kiro polls until workspace is running
10. Kiro updates Tasks UI to "working"
11. Kiro runs `ls /home/coder` and shows output
12. Trigger "Report Coder Task Complete" hook
13. Kiro reports "idle" in Tasks UI and stops workspace

**Expected Results:**
- All steps complete successfully
- No errors or failures
- Task visible in Coder Tasks UI throughout
- Workspace starts, runs commands, and stops cleanly
- All status updates appear in Tasks UI

**Validation:**
```
✅ Connection verified during onboarding
✅ Templates shown and confirmed
✅ Task created successfully
✅ Task appears in UI within 60 seconds
✅ Workspace reaches "running" status
✅ Tasks UI shows "working" status
✅ Command executes successfully
✅ Hook triggers completion
✅ Tasks UI shows "idle" status
✅ Workspace stops successfully
```

**This is the primary acceptance test. If this passes, the prototype is working.**

---

## Phase 9: Documentation and Cleanup

### Test 9.1: Verify Documentation Accuracy

**Objective:** Ensure all documentation matches actual behavior.

**Steps:**
1. Review POWER.md for accuracy
2. Review steering files for accuracy
3. Test all documented examples
4. Verify troubleshooting steps work

**Expected Results:**
- All documentation is accurate
- All examples work as documented
- Troubleshooting steps are helpful
- No outdated or incorrect information

**Validation:**
```
✅ POWER.md is accurate
✅ Steering files are accurate
✅ All examples work
✅ Troubleshooting steps are helpful
```

### Test 9.2: Clean Up Test Resources

**Objective:** Clean up all test tasks and workspaces.

**Steps:**
1. List all tasks: call `coder_list_tasks`
2. For each test task:
   - Stop workspace if running
   - Delete task
3. Verify cleanup in Coder UI

**Expected Results:**
- All test tasks stopped
- All test tasks deleted
- Coder UI shows clean state

**Validation:**
```
✅ All test workspaces stopped
✅ All test tasks deleted
✅ Coder UI is clean
```

---

## Success Criteria Summary

The Coder Guardian Forge Power is ready for use when:

✅ **Installation**
- Power installs from local directory without errors
- Connection to Coder MCP server succeeds
- Templates are listed successfully
- Task completion hook is created

✅ **Task Creation**
- Tasks can be created via `coder_create_task`
- Tasks appear in Coder Tasks UI within 60 seconds
- Workspace provisioning completes successfully
- Workspace name is retrieved correctly

✅ **Workspace Operations**
- Commands execute successfully via `coder_workspace_bash`
- Files can be listed, read, written, and edited
- All file operations use dedicated tools (not bash)
- Appropriate timeouts are used for different operations

✅ **Progress Reporting**
- Progress is reported after each major step
- Summaries are clear, concise, and under 160 characters
- Tasks UI shows real-time updates

✅ **Task Completion**
- Tasks can be completed successfully (state="idle")
- Tasks can be failed appropriately (state="failure")
- Workspaces are stopped after completion or failure
- Task completion hook works correctly

✅ **Error Handling**
- Errors are detected and reported clearly
- Kiro suggests corrective actions
- No infinite retry loops
- Graceful degradation on failures

✅ **End-to-End**
- Complete acceptance test passes
- All steps work without manual intervention
- Tasks UI shows full lifecycle visibility

---

## Next Steps After Testing

Once all tests pass:

1. **Document any issues found** and create fixes
2. **Update documentation** based on testing insights
3. **Create example workflows** for common use cases
4. **Prepare for sharing** (sanitize mcp.json if needed)
5. **Consider submitting** to Kiro recommended powers

---

## Testing Checklist

Use this checklist to track testing progress:

### Phase 1: Setup
- [ ] 1.1: Power installed locally
- [ ] 1.2: Connection verified
- [ ] 1.3: Templates listed
- [ ] 1.4: Hook created

### Phase 2: Task Creation
- [ ] 2.1: Task created successfully
- [ ] 2.2: Workspace ready
- [ ] 2.3: Workspace name retrieved

### Phase 3: Workspace Operations
- [ ] 3.1: Commands execute
- [ ] 3.2: Directory listing works
- [ ] 3.3: File reading works
- [ ] 3.4: File writing works
- [ ] 3.5: File editing works
- [ ] 3.6: Timeouts appropriate

### Phase 4: Progress Reporting
- [ ] 4.1: Progress reported
- [ ] 4.2: Summaries quality verified

### Phase 5: Task Completion
- [ ] 5.1: Task completed successfully
- [ ] 5.2: Hook works
- [ ] 5.3: Failure handled

### Phase 6: Advanced Scenarios
- [ ] 6.1: Existing tasks checked
- [ ] 6.2: Apps listed
- [ ] 6.3: Multiple files edited
- [ ] 6.4: Background processes work

### Phase 7: Error Handling
- [ ] 7.1: Invalid workspace handled
- [ ] 7.2: Timeout handled
- [ ] 7.3: File not found handled
- [ ] 7.4: Connection loss handled

### Phase 8: End-to-End
- [ ] 8.1: Complete acceptance test passes

### Phase 9: Documentation
- [ ] 9.1: Documentation verified
- [ ] 9.2: Resources cleaned up

---

**Testing complete when all checkboxes are checked and acceptance test passes.**
