# Workspace Lifecycle Management Guide

This guide helps you decide when to stop, keep running, or delete workspaces and tasks based on your use case.

---

## Decision Tree: After Task Completion

### Short-Lived Tasks (< 1 hour)

**Characteristics:**
- Quick fixes or patches
- One-off scripts or commands
- Simple file operations
- Testing or verification tasks

**Recommended Actions:**
1. ✅ Stop workspace immediately after completion
2. ✅ Delete task to keep UI clean
3. ✅ Free resources quickly

**Example workflow:**
```
1. Create task: "Fix typo in README"
2. Make the change
3. Verify the fix
4. Stop workspace: coder_create_workspace_build(transition="stop")
5. Delete task: coder_delete_task()
```

**Benefits:**
- Minimal resource consumption
- Clean task list
- Fast turnaround

---

### Development Tasks (Hours to Days)

**Characteristics:**
- Feature development
- Bug investigation and fixing
- Code refactoring
- Multiple work sessions

**Recommended Actions:**
1. ✅ Stop workspace after each work session
2. ✅ Keep task for history and reference
3. ✅ Restart workspace for next session
4. ❌ Don't delete task until completely done

**Example workflow:**
```
Session 1:
1. Create task: "Implement user authentication"
2. Work on implementation
3. Stop workspace at end of day

Session 2:
1. Restart workspace (create new build with transition="start")
2. Continue implementation
3. Stop workspace at end of day

Session 3:
1. Restart workspace
2. Complete implementation and testing
3. Stop workspace
4. Keep task for audit trail
```

**Benefits:**
- Stopped workspaces cost minimal (storage only)
- Task history preserved
- Can resume work easily
- Resource-efficient

---

### Long-Running Tasks (Days to Weeks)

**Characteristics:**
- Major feature development
- Large-scale refactoring
- Multi-phase projects
- Ongoing development work

**Recommended Actions:**
1. ✅ Keep workspace running between active sessions
2. ✅ Stop only during extended breaks (weekends, etc.)
3. ✅ Keep task for complete audit trail
4. ❌ Don't delete task - valuable for compliance and history

**Example workflow:**
```
Week 1:
1. Create task: "Migrate to microservices architecture"
2. Work on Phase 1: Service extraction
3. Keep workspace running overnight
4. Continue work next day

Week 2:
1. Continue with Phase 2: API gateway
2. Keep workspace running during active development
3. Stop workspace Friday evening

Week 3:
1. Restart workspace Monday morning
2. Complete Phase 3: Testing and deployment
3. Stop workspace when fully complete
4. Keep task indefinitely for audit trail
```

**Benefits:**
- No startup delay between sessions
- Maintains workspace state
- Complete history for compliance
- Efficient for intensive work

**Cost Consideration:**
- Running workspaces consume full compute resources
- Balance convenience vs. cost
- Stop during nights/weekends if not actively working

---

## Resource Considerations

### Stopped Workspaces

**Cost:** Minimal (storage only)
**State:** Disk persisted, compute freed
**Restart:** Quick (30-60 seconds)
**Use when:** Between work sessions, overnight, weekends

### Running Workspaces

**Cost:** Full compute + storage
**State:** Fully active, processes running
**Use when:** Actively working, need immediate access

### Deleted Tasks

**Cost:** None
**State:** Completely removed
**History:** Lost (unless logged elsewhere)
**Use when:** Task truly complete and no audit trail needed

---

## Best Practices by Use Case

### Quick Fixes and Patches

```
✅ DO:
- Stop workspace immediately after fix
- Delete task to keep UI clean
- Use simple task descriptions

❌ DON'T:
- Leave workspace running
- Keep task in list indefinitely
```

### Feature Development

```
✅ DO:
- Stop workspace between sessions
- Keep task for reference
- Use descriptive task names
- Document progress in task logs

❌ DON'T:
- Delete task prematurely
- Leave workspace running overnight (unless actively needed)
```

### Debugging and Investigation

```
✅ DO:
- Keep workspace running during active debugging
- Stop when switching to other work
- Keep task until issue resolved
- Document findings in logs

❌ DON'T:
- Delete task before issue is fully resolved
- Stop workspace mid-debugging session
```

### Compliance and Audit Requirements

```
✅ DO:
- Keep all tasks indefinitely
- Document all actions in task logs
- Use clear, descriptive task names
- Stop workspaces when not in use

❌ DON'T:
- Delete tasks (violates audit trail)
- Leave workspaces running unnecessarily (cost)
```

---

## Automation Recommendations

### Auto-Stop Policies

Consider implementing auto-stop policies in your Coder templates:

```hcl
resource "coder_agent" "dev" {
  # Auto-stop after 8 hours of inactivity
  shutdown_script_timeout = 300
  
  # Warn before auto-stop
  display_apps {
    vscode = true
    port_forwarding_helper = true
  }
}
```

### Task Cleanup Hooks

Create Kiro hooks for automatic cleanup:

```json
{
  "name": "Auto-cleanup short tasks",
  "when": { "type": "agentStop" },
  "then": {
    "type": "askAgent",
    "prompt": "If the completed task was short-lived (< 1 hour), delete it to keep the task list clean"
  }
}
```

---

## Cost Optimization Tips

1. **Stop workspaces during breaks**
   - Lunch breaks (> 1 hour)
   - End of day
   - Weekends
   - Vacations

2. **Use appropriate workspace sizes**
   - Small tasks: Small instances
   - Development: Medium instances
   - Heavy builds: Large instances (but stop when not building)

3. **Monitor workspace usage**
   - Check Coder UI for running workspaces
   - Review monthly costs
   - Identify idle workspaces

4. **Set team policies**
   - Maximum running time without activity
   - Required stop times (nights, weekends)
   - Task retention policies

---

## Monitoring Workspace State

### Check Running Workspaces

```
Call coder_list_workspaces with status filter:
- status: "running" - Currently active
- status: "stopped" - Stopped but not deleted
```

### Check Task Status

```
Call coder_list_tasks to see:
- Active tasks (workspace running)
- Paused tasks (workspace stopped)
- Completed tasks (workspace stopped, work done)
```

### Identify Idle Workspaces

Look for workspaces that are:
- Running but no recent activity
- No commands executed in last hour
- No file changes in last hour
- Consider stopping these

---

## Summary

**Quick Reference:**

| Task Duration | Stop Workspace? | Delete Task? | Keep Running? |
|---------------|-----------------|--------------|---------------|
| < 1 hour | ✅ Immediately | ✅ Yes | ❌ No |
| Hours to days | ✅ Between sessions | ❌ No | ❌ No |
| Days to weeks | ⚠️ During breaks | ❌ No | ✅ During work |
| Compliance | ✅ When not in use | ❌ Never | ❌ No |

**Key Principles:**
1. Stop workspaces when not actively working
2. Keep tasks for audit trail and reference
3. Delete only short-lived, non-critical tasks
4. Balance convenience with cost
5. Monitor and optimize regularly

---

**Remember:** Stopped workspaces cost very little but preserve your work. When in doubt, stop the workspace and keep the task.
