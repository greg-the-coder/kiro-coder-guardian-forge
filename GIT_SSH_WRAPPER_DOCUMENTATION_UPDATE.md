# Git SSH Wrapper Documentation Update

## Summary

Updated the Kiro Coder Guardian Forge power documentation to explicitly document Coder's custom git SSH wrapper, which is critical for git operations in Coder workspaces.

## Problem

The power documentation did not explicitly mention that Coder workspaces use a custom git SSH wrapper configured via the `GIT_SSH_COMMAND` environment variable. This led to confusion when git operations failed, as users and agents were unaware of this critical component.

## Solution

Added comprehensive documentation about the Coder git SSH wrapper across multiple files:

### 1. ONE-TIME-SETUP.md

**Changes:**
- Updated "Automatic (Template Handles This)" section to explicitly mention the Coder git SSH wrapper
- Added detailed explanation of `GIT_SSH_COMMAND` environment variable in Step 4
- Added new troubleshooting sections:
  - "Git operations fail with 'ssh: command not found'"
  - "Git push works in home workspace but fails in task workspace"

**Key additions:**
- Explanation that `GIT_SSH_COMMAND` points to `/tmp/coder.*/coder gitssh --`
- Clarification that the path is dynamically generated and varies between workspaces
- Troubleshooting steps for when the wrapper is missing or misconfigured

### 2. steering/task-workflow.md

**Changes:**
- Added new validation check (3a) in `validate_task_prerequisites()` function
- Updated Pre-Flight Validation Checklist to include git SSH wrapper verification
- Added detailed error messages and fixes for missing wrapper

**Key additions:**
```python
# Check 3a: Verify Coder git SSH wrapper is configured (CRITICAL)
result = coder_workspace_bash(
    workspace=home_workspace,
    command="echo $GIT_SSH_COMMAND",
    timeout_ms=5000
)
if not result.stdout.strip() or "coder gitssh" not in result.stdout:
    issues.append("Coder git SSH wrapper not configured")
    fixes.append("""
GIT_SSH_COMMAND environment variable must be set to Coder's git SSH wrapper.
Expected: GIT_SSH_COMMAND=/tmp/coder.*/coder gitssh --
...
""")
```

### 3. POWER.md

**Changes:**
- Updated "SSH Authentication Setup" section to explain the git SSH wrapper
- Added git SSH wrapper verification to quick verification steps
- Added new troubleshooting entries for git SSH wrapper issues

**Key additions:**
- Explanation of what the wrapper is and why it's needed
- Verification command: `echo $GIT_SSH_COMMAND`
- Troubleshooting for when git operations fail due to wrapper issues

### 4. coder-template-example.tf

**Changes:**
- Added header comment explaining the git SSH wrapper requirement
- Added git SSH wrapper verification in startup script

**Key additions:**
```bash
# Git SSH Wrapper Verification
if [ -z "$GIT_SSH_COMMAND" ]; then
  echo "⚠️  WARNING: GIT_SSH_COMMAND not set"
  echo "Git operations may fail without Coder's SSH wrapper"
else
  echo "✅ Git SSH wrapper configured: $GIT_SSH_COMMAND"
fi
```

## Validation in Current Workspace

Verified the git SSH wrapper is working correctly in this Coder workspace:

```bash
# Environment variable is set
$ echo $GIT_SSH_COMMAND
/tmp/coder.Ir4oL9/coder gitssh --

# Wrapper binary exists
$ ls -la /tmp/coder.Ir4oL9/coder
-rwxr-xr-x. 1 coder coder 53395640 Mar 10 20:35 /tmp/coder.Ir4oL9/coder

# Authentication works
$ $GIT_SSH_COMMAND -T git@github.com
Hi greg-the-coder! You've successfully authenticated...

# Git operations work
$ git ls-remote git@github.com:coder/coder.git HEAD
e7f8dfbe15e8a5fbed889e9de604b2da1aefccd8        HEAD
```

## Impact

These updates ensure that:

1. **Users understand** the git SSH wrapper is a critical component of Coder workspaces
2. **Agents can validate** the wrapper is configured before creating tasks
3. **Troubleshooting is easier** with clear error messages and fixes
4. **Template authors know** to verify the wrapper in startup scripts
5. **Documentation is complete** with all necessary information about git operations

## Files Modified

1. `kiro-coder-guardian-forge/ONE-TIME-SETUP.md`
2. `kiro-coder-guardian-forge/steering/task-workflow.md`
3. `kiro-coder-guardian-forge/POWER.md`
4. `kiro-coder-guardian-forge/coder-template-example.tf`

## Testing Recommendations

1. Test task creation with validation function to ensure git SSH wrapper check works
2. Verify error messages are clear when wrapper is missing
3. Test git operations in both home and task workspaces
4. Verify documentation is clear for new users

## Next Steps

Consider adding:
1. Automated tests for git SSH wrapper validation
2. Template validation tool to check for wrapper configuration
3. Dashboard indicator showing wrapper status
4. Automatic wrapper configuration if missing (if possible)
