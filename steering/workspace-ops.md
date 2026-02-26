# Coder Workspace Operations

This steering file teaches you how to work inside a running Coder task workspace. Load this when you need to run commands, read/write files, or interact with applications in the workspace.

**Prerequisites:** You must have a running task workspace and know its name (format: `owner/workspace-name`). Get this from `coder_get_task_logs` after task creation.

---

## Running Commands

Use `coder_workspace_bash` to execute commands inside the workspace.

### Basic Command Execution

**Tool:** `coder_workspace_bash`

**Required parameters:**
- `workspace`: The workspace name in format `owner/workspace-name`
- `command`: The bash command to execute
- `timeout_ms`: Maximum time to wait for command completion (in milliseconds)

**Optional parameters:**
- `background`: Set to `true` for long-running processes that don't need to complete immediately
- `cwd`: Working directory for the command (defaults to `/home/coder`)

**Always check the `exit_code` in the result:**
- `exit_code: 0` means success
- Non-zero exit code means the command failed

### Timeout Guidelines

Choose appropriate timeouts based on operation type:

| Operation Type | Recommended Timeout | Example |
|---|---|---|
| Quick checks | 15000 (15 seconds) | `pwd`, `ls`, `echo` |
| File operations | 30000 (30 seconds) | `cat`, `grep`, `find` |
| Package installs | 60000 (60 seconds) | `npm install`, `pip install` |
| Builds | 120000 (2 minutes) | `go build`, `npm run build` |
| Test suites | 120000 (2 minutes) | `go test`, `npm test` |
| Long operations | 300000 (5 minutes) | Full CI pipeline, large builds |

**For operations that might take longer than 5 minutes:**
- Set `background: true`
- The command runs in the background
- You won't get the output immediately
- Use for: dev servers, watchers, long-running scripts

### Command Examples

**Verify the environment:**
```json
{
  "workspace": "alice/task-123",
  "command": "pwd && ls -la /home/coder",
  "timeout_ms": 15000
}
```

**Install dependencies:**
```json
{
  "workspace": "alice/task-123",
  "command": "cd /home/coder/app && npm install",
  "timeout_ms": 60000
}
```

**Run tests:**
```json
{
  "workspace": "alice/task-123",
  "command": "cd /home/coder/app && go test ./...",
  "timeout_ms": 120000
}
```

**Build application:**
```json
{
  "workspace": "alice/task-123",
  "command": "cd /home/coder/app && npm run build",
  "timeout_ms": 120000
}
```

**Start development server (background):**
```json
{
  "workspace": "alice/task-123",
  "command": "cd /home/coder/app && npm run dev",
  "timeout_ms": 30000,
  "background": true
}
```

**Check running processes:**
```json
{
  "workspace": "alice/task-123",
  "command": "ps aux | grep node",
  "timeout_ms": 15000
}
```

**Git operations:**
```json
{
  "workspace": "alice/task-123",
  "command": "cd /home/coder/app && git status && git log --oneline -5",
  "timeout_ms": 30000
}
```

### Error Handling

**Check exit codes:**
```
If exit_code != 0:
  - The command failed
  - Check stdout and stderr for error messages
  - Report the error to the user
  - Consider reporting task failure if critical
```

**Handle timeouts:**
```
If command times out:
  - Increase timeout_ms if operation legitimately needs more time
  - Or use background: true for long-running processes
  - Or break into smaller commands
```

**Common command failures:**
- `exit_code: 127` → Command not found (check if tool is installed)
- `exit_code: 126` → Permission denied (check file permissions)
- `exit_code: 1` → General error (check stderr for details)
- `exit_code: 2` → Misuse of shell command (check command syntax)

---

## Reading and Writing Files

**CRITICAL:** Always use the dedicated file tools instead of bash `cat` / `echo` / `heredoc`. The file tools are more reliable and handle encoding correctly.

### Listing Directory Contents

**Tool:** `coder_workspace_ls`

**Parameters:**
- `workspace`: The workspace name
- `path`: Absolute path to the directory

**Example:**
```json
{
  "workspace": "alice/task-123",
  "path": "/home/coder/app"
}
```

**Returns:** List of files and directories with metadata (size, permissions, modified time)

**Use cases:**
- Explore project structure
- Verify files exist before reading
- Check file sizes before operations
- Find files by pattern

### Reading Files

**Tool:** `coder_workspace_read_file`

**Parameters:**
- `workspace`: The workspace name
- `path`: Absolute path to the file

**Example:**
```json
{
  "workspace": "alice/task-123",
  "path": "/home/coder/app/src/main.go"
}
```

**Returns:** File contents as a string

**Use cases:**
- Read source code files
- Read configuration files
- Read logs
- Analyze file contents

**Best practices:**
- Always use absolute paths
- Check file exists first with `coder_workspace_ls`
- For large files, consider reading specific sections only
- Handle binary files appropriately (may not be readable as text)

### Writing New Files

**Tool:** `coder_workspace_write_file`

**Parameters:**
- `workspace`: The workspace name
- `path`: Absolute path where file should be created
- `content`: File contents (must be base64-encoded)

**CRITICAL:** The content must be base64-encoded before sending.

**Example workflow:**
```
1. Prepare the file content as a string
2. Base64-encode the content
3. Call coder_workspace_write_file with encoded content
```

**Example:**
```json
{
  "workspace": "alice/task-123",
  "path": "/home/coder/app/config.yaml",
  "content": "bmFtZTogbXktYXBwCnBvcnQ6IDgwODAK"
}
```

**Use cases:**
- Create new source files
- Create configuration files
- Generate scripts
- Create documentation

**Best practices:**
- Always use absolute paths
- Ensure parent directory exists (or create it first with bash `mkdir -p`)
- Verify write succeeded by reading the file back
- Use appropriate file extensions

### Editing Existing Files

**Tool:** `coder_workspace_edit_file`

**Parameters:**
- `workspace`: The workspace name
- `path`: Absolute path to the file to edit
- `edits`: Array of search/replace operations

**Each edit has:**
- `oldText`: Exact text to find (must match exactly)
- `newText`: Replacement text

**Example:**
```json
{
  "workspace": "alice/task-123",
  "path": "/home/coder/app/config.yaml",
  "edits": [
    {
      "oldText": "port: 8080",
      "newText": "port: 3000"
    },
    {
      "oldText": "debug: false",
      "newText": "debug: true"
    }
  ]
}
```

**Use cases:**
- Update configuration values
- Fix bugs in source code
- Modify specific lines
- Apply targeted changes

**Best practices:**
- `oldText` must match exactly (including whitespace)
- Make `oldText` specific enough to match only the intended location
- If unsure about exact text, read the file first
- For multiple edits, include them all in one call
- Verify edits succeeded by reading the file back

### Editing Multiple Files

**Tool:** `coder_workspace_edit_files`

**Parameters:**
- `workspace`: The workspace name
- `files`: Array of file edit operations

**Each file operation has:**
- `path`: Absolute path to the file
- `edits`: Array of search/replace operations (same as `coder_workspace_edit_file`)

**Example:**
```json
{
  "workspace": "alice/task-123",
  "files": [
    {
      "path": "/home/coder/app/src/config.go",
      "edits": [
        {
          "oldText": "Port = 8080",
          "newText": "Port = 3000"
        }
      ]
    },
    {
      "path": "/home/coder/app/README.md",
      "edits": [
        {
          "oldText": "## Installation",
          "newText": "## Installation\n\nUpdated: 2024-01-15"
        }
      ]
    }
  ]
}
```

**Use cases:**
- Apply changes across multiple files
- Refactor code that spans files
- Update version numbers in multiple places
- Batch configuration updates

**Best practices:**
- Use when you need to edit 2+ files atomically
- All edits succeed or all fail (atomic operation)
- Verify all edits succeeded by reading files back

---

## File Operations Best Practices

### Path Guidelines

**Always use absolute paths:**
- ✅ `/home/coder/app/src/main.go`
- ❌ `src/main.go` (relative path — may not work)
- ❌ `~/app/src/main.go` (tilde expansion — may not work)

**Common workspace paths:**
- `/home/coder` — User home directory (default)
- `/home/coder/app` — Common application directory
- `/workspace` — Alternative workspace root (template-dependent)
- `/tmp` — Temporary files

### When to Use Each Tool

| Task | Tool | Why |
|---|---|---|
| List directory | `coder_workspace_ls` | Structured output, metadata included |
| Read file | `coder_workspace_read_file` | Reliable, handles encoding |
| Create new file | `coder_workspace_write_file` | Proper encoding, atomic write |
| Edit existing file | `coder_workspace_edit_file` | Targeted changes, safer than rewrite |
| Edit multiple files | `coder_workspace_edit_files` | Atomic multi-file changes |
| Complex file operations | `coder_workspace_bash` | When file tools don't cover the use case |

### Don't Use Bash for File Operations

**Avoid these bash patterns:**

❌ **Don't use `cat` to read files:**
```bash
cat /home/coder/app/config.yaml
```
✅ **Use `coder_workspace_read_file` instead**

❌ **Don't use `echo` to write files:**
```bash
echo "content" > /home/coder/app/file.txt
```
✅ **Use `coder_workspace_write_file` instead**

❌ **Don't use heredoc to write files:**
```bash
cat << EOF > /home/coder/app/file.txt
content here
EOF
```
✅ **Use `coder_workspace_write_file` instead**

❌ **Don't use `sed` to edit files:**
```bash
sed -i 's/old/new/g' /home/coder/app/file.txt
```
✅ **Use `coder_workspace_edit_file` instead**

**Why file tools are better:**
- Proper encoding handling (especially for base64)
- Atomic operations (all or nothing)
- Better error handling
- More reliable across different workspace configurations
- Clearer intent in code

**When bash is acceptable:**
- Complex file operations not covered by file tools
- Operations involving multiple commands (pipes, redirects)
- File operations combined with other bash commands

---

## Checking Running Applications

### List Exposed Apps

**Tool:** `coder_workspace_list_apps`

**Parameters:**
- `workspace`: The workspace name

**Example:**
```json
{
  "workspace": "alice/task-123"
}
```

**Returns:** List of applications exposed by the workspace with their URLs

**Use cases:**
- Find URLs of running web servers
- Check which ports are exposed
- Verify applications started correctly
- Share URLs with users

**Example response:**
```json
{
  "apps": [
    {
      "name": "web-server",
      "url": "https://alice-task-123--8080.coder.mycompany.com",
      "port": 8080
    },
    {
      "name": "api",
      "url": "https://alice-task-123--3000.coder.mycompany.com",
      "port": 3000
    }
  ]
}
```

### Access Non-Exposed Ports

**Tool:** `coder_workspace_port_forward`

**Parameters:**
- `workspace`: The workspace name
- `port`: The port number to forward

**Example:**
```json
{
  "workspace": "alice/task-123",
  "port": 5432
}
```

**Returns:** URL to access the forwarded port

**Use cases:**
- Access databases (PostgreSQL, MySQL, Redis)
- Access internal services not exposed as apps
- Debug services on non-standard ports
- Connect to development tools

**Example workflow:**
```
1. Start a service on port 5432 (e.g., PostgreSQL)
2. Call coder_workspace_port_forward(port=5432)
3. Get URL: https://alice-task-123--5432.coder.mycompany.com
4. Use URL to connect to the service
```

---

## Common Workflow Patterns

### Pattern: Setup and Verify Environment

```
1. List home directory:
   coder_workspace_ls(path="/home/coder")

2. Check for project directory:
   coder_workspace_ls(path="/home/coder/app")

3. Verify tools installed:
   coder_workspace_bash(command="which go && which npm && which git")

4. Check environment variables:
   coder_workspace_bash(command="env | grep -E '(PATH|HOME|USER)'")
```

### Pattern: Clone and Setup Project

```
1. Clone repository:
   coder_workspace_bash(
     command="cd /home/coder && git clone https://github.com/user/repo.git app",
     timeout_ms=60000
   )

2. Install dependencies:
   coder_workspace_bash(
     command="cd /home/coder/app && npm install",
     timeout_ms=60000
   )

3. Verify installation:
   coder_workspace_ls(path="/home/coder/app/node_modules")

4. Report progress:
   coder_report_task(state="working", summary="Project cloned and dependencies installed")
```

### Pattern: Read, Modify, Test

```
1. Read the file:
   coder_workspace_read_file(path="/home/coder/app/src/handler.go")

2. Make changes:
   coder_workspace_edit_file(
     path="/home/coder/app/src/handler.go",
     edits=[{oldText: "...", newText: "..."}]
   )

3. Verify changes:
   coder_workspace_read_file(path="/home/coder/app/src/handler.go")

4. Run tests:
   coder_workspace_bash(
     command="cd /home/coder/app && go test ./...",
     timeout_ms=120000
   )

5. Report progress:
   coder_report_task(state="working", summary="Handler updated — tests passing")
```

### Pattern: Build and Deploy

```
1. Build application:
   coder_workspace_bash(
     command="cd /home/coder/app && npm run build",
     timeout_ms=120000
   )

2. Check build output:
   coder_workspace_ls(path="/home/coder/app/dist")

3. Run production tests:
   coder_workspace_bash(
     command="cd /home/coder/app && npm run test:prod",
     timeout_ms=120000
   )

4. Deploy (if tests pass):
   coder_workspace_bash(
     command="cd /home/coder/app && ./deploy.sh",
     timeout_ms=300000
   )

5. Report completion:
   coder_report_task(state="idle", summary="Built and deployed to production")
```

### Pattern: Debug Running Application

```
1. Start application in background:
   coder_workspace_bash(
     command="cd /home/coder/app && npm run dev",
     background=true
   )

2. Wait for startup (give it time):
   coder_workspace_bash(
     command="sleep 10",
     timeout_ms=15000
   )

3. Check if running:
   coder_workspace_bash(
     command="ps aux | grep node",
     timeout_ms=15000
   )

4. List exposed apps:
   coder_workspace_list_apps()

5. Test the endpoint:
   coder_workspace_bash(
     command="curl http://localhost:3000/health",
     timeout_ms=15000
   )

6. Check logs:
   coder_workspace_read_file(path="/home/coder/app/logs/app.log")
```

---

## Error Handling

### Command Failures

```
If coder_workspace_bash returns exit_code != 0:
1. Read stderr for error message
2. Determine if error is recoverable:
   - Missing dependency → Install it
   - Wrong directory → Use correct path
   - Permission issue → Check file permissions
   - Syntax error → Fix the command
3. If unrecoverable:
   - Report task failure
   - Stop workspace
```

### File Operation Failures

```
If file operation fails:
1. Check file/directory exists:
   coder_workspace_ls(path=parent_directory)
2. Check permissions:
   coder_workspace_bash(command="ls -la /path/to/file")
3. Verify path is absolute
4. Try alternative approach if needed
```

### Application Not Responding

```
If application doesn't respond:
1. Check if process is running:
   coder_workspace_bash(command="ps aux | grep app-name")
2. Check application logs:
   coder_workspace_read_file(path="/home/coder/app/logs/error.log")
3. Check port is listening:
   coder_workspace_bash(command="netstat -tlnp | grep :3000")
4. Restart application if needed
```

---

## Best Practices Summary

- Use absolute paths for all file operations
- Use dedicated file tools instead of bash `cat`/`echo`/`sed`
- Set appropriate timeouts based on operation type
- Always check exit codes for bash commands
- Report progress after each significant operation
- Verify operations succeeded before proceeding
- Use `background: true` for long-running processes
- Handle errors gracefully and report failures clearly
- Clean up temporary files when done
- Stop workspace when work is complete

---

## Integration with Task Workflow

Remember to report progress to the Coder Tasks UI as you work:

```
After each major operation:
  coder_report_task(
    state="working",
    summary="<what you just did>"
  )

When all work is done:
  coder_report_task(
    state="idle",
    summary="<what was accomplished>"
  )

If something fails:
  coder_report_task(
    state="failure",
    summary="<what went wrong>"
  )
```

This keeps the Tasks UI updated and provides visibility into agent activity.
