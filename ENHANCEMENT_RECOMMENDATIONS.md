# Kiro Coder Guardian Forge - Enhancement Recommendations

**Date:** March 3, 2026  
**Based on:** Test Iteration 2 Analysis  
**Focus:** Addressing new bottlenecks while preserving improvements

---

## Executive Summary

Your second test iteration showed **significant improvements** (89% faster task creation, zero recreation cycles), but revealed **new critical bottlenecks** that prevent achieving the full potential of the power:

**Primary Bottleneck:** Manual file transfer (20 minutes) - Task workspaces created independent git repos instead of using worktrees despite instructions.

**Secondary Issues:** Post-task validation gaps (5 min bug fixes), unclear workspace lifecycle management (5 min cleanup).

**Opportunity:** With targeted enhancements, you can reduce total time from 75 minutes to ~45 minutes (40% improvement) with near-zero manual intervention.

---

## Priority 1: Automated Git-Based Work Transfer ⭐⭐⭐

### Problem
Manual file copying is now the biggest bottleneck (20+ minutes):
- Task workspaces created independent git clones instead of worktrees
- Had to manually read 18 files via MCP and write to home workspace
- Tedious, error-prone, high token usage

### Root Cause
Git worktree instructions in task prompts aren't being followed by task workspace agents. They clone the repo independently instead of creating a worktree.

### Recommended Solution: Enhanced Steering Guidance

**Update `steering/task-workflow.md` with explicit git-fetch workflow:**

```markdown
## Work Transfer Pattern: Git Fetch (Recommended)

**CRITICAL:** Task workspaces may not support git worktrees. Use this git-fetch pattern instead:

### Step 1: Task Workspace Commits and Pushes

```python
# In task workspace: commit all work to feature branch
coder_workspace_bash(
    workspace=task_workspace,
    command=f"""
        cd /workspaces/project
        
        # Stage all changes
        git add .
        
        # Commit with descriptive message
        git commit -m "Complete: {task_description}"
        
        # Push to remote
        git push origin {feature_branch}
        
        # Verify push succeeded
        if [ $? -eq 0 ]; then
            echo "✅ Pushed to {feature_branch}"
            git log -1 --oneline
        else
            echo "❌ Push failed"
            exit 1
        fi
    """,
    timeout_ms=60000
)
```

### Step 2: Home Workspace Fetches and Merges

```python
# In home workspace: fetch and merge feature branch
result = coder_workspace_bash(
    workspace=home_workspace,
    command=f"""
        cd /workspaces/project
        
        # Fetch latest from remote
        git fetch origin {feature_branch}
        
        # Checkout main branch
        git checkout main
        
        # Merge feature branch (no fast-forward)
        git merge origin/{feature_branch} --no-ff -m "Merge: {task_description}"
        
        # Push to remote
        git push origin main
        
        # Show merge result
        echo "✅ Merge complete"
        git log --oneline -3
        git diff --stat HEAD~1
    """,
    timeout_ms=60000
)

# Verify merge succeeded
if result.exit_code == 0:
    print(f"✅ Work transferred successfully via git")
    print(f"Files changed: {result.stdout}")
else:
    print(f"❌ Merge failed: {result.stderr}")
    # Fallback to manual file transfer if needed
```

### Benefits
- ✅ Fast: 2 minutes vs 20 minutes (90% reduction)
- ✅ Reliable: Standard git operations
- ✅ Complete: All files transferred atomically
- ✅ History: Full git history preserved
- ✅ Low token usage: Only git commands, no file reading
```

**Impact:** Reduces file transfer from 20 minutes to 2 minutes (90% reduction)

**Implementation Effort:** Low - documentation update only

---

## Priority 2: Pre-Task Validation Enhancement ⭐⭐⭐

### Problem
Tasks can complete successfully but deliver buggy code:
- Phase 5 task completed but deployment script had TypeScript error
- `vite.config.ts` imported from wrong package
- Build failed when running deployment script in home workspace

### Root Cause
Tasks don't run end-to-end validation before marking complete.

### Recommended Solution: Validation Checklist in Task Prompts

**Add to `steering/agent-interaction.md` - Task Prompt Templates:**

```markdown
## Task Prompt Template with Validation

When delegating work to task workspace agents, include validation requirements:

```python
task_prompt = f"""
{task_description}

VALIDATION REQUIREMENTS (MUST COMPLETE BEFORE FINISHING):

1. Build Validation:
   - Run full build: `npm run build` or equivalent
   - Verify build succeeds with zero errors
   - Check dist/ or build/ directory contains expected output

2. Type Checking:
   - Run type checker: `npm run type-check` or `tsc --noEmit`
   - Verify zero TypeScript errors
   - Check all imports resolve correctly

3. Test Validation:
   - Run test suite: `npm test` or equivalent
   - Verify all tests pass
   - Check test coverage meets requirements

4. Lint Validation:
   - Run linter: `npm run lint` or equivalent
   - Fix any linting errors
   - Verify code style compliance

5. Integration Validation:
   - Test integration with dependent systems
   - Verify configuration files are correct
   - Check environment variables are documented

CRITICAL: If any validation fails, fix the issue before completing the task.
Document any issues found and how they were resolved.

Git Instructions:
- Work on feature branch: {feature_branch}
- Commit frequently with descriptive messages
- Push final work: git push origin {feature_branch}
"""
```

### Validation Script Template

**Create reusable validation script for common project types:**

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

echo "✅ All validations passed - ready to complete task"
```

**Include in task workspace:**
```python
# Write validation script to task workspace
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
```
```

**Impact:** 80% reduction in post-task bug fixes (5 min → 1 min)

**Implementation Effort:** Low - documentation and template updates

---

## Priority 3: Workspace Lifecycle Automation ⭐⭐

### Problem
Unclear when to stop/delete task workspaces:
- Phase 2 task workspace couldn't be found (404 error)
- Phase 3 task workspace still running after work transferred
- Manual cleanup required, consuming resources

### Root Cause
No automated lifecycle management or clear policies.

### Recommended Solution: Lifecycle Management Guidance

**Add to `steering/task-workflow.md`:**

```markdown
## Workspace Lifecycle Management

### Automatic Cleanup After Work Transfer

**BEST PRACTICE:** Stop task workspaces immediately after successful work transfer to free resources.

```python
def complete_task_with_cleanup(task_workspace, home_workspace, feature_branch, task_description):
    """Complete task with automatic cleanup"""
    
    # Step 1: Commit and push from task workspace
    print("📤 Committing and pushing from task workspace...")
    result = coder_workspace_bash(
        workspace=task_workspace,
        command=f"""
            cd /workspaces/project
            git add .
            git commit -m "Complete: {task_description}"
            git push origin {feature_branch}
        """,
        timeout_ms=60000
    )
    
    if result.exit_code != 0:
        print(f"❌ Failed to push: {result.stderr}")
        return False
    
    # Step 2: Fetch and merge in home workspace
    print("📥 Fetching and merging in home workspace...")
    result = coder_workspace_bash(
        workspace=home_workspace,
        command=f"""
            cd /workspaces/project
            git fetch origin {feature_branch}
            git checkout main
            git merge origin/{feature_branch} --no-ff -m "Merge: {task_description}"
            git push origin main
        """,
        timeout_ms=60000
    )
    
    if result.exit_code != 0:
        print(f"❌ Failed to merge: {result.stderr}")
        return False
    
    print("✅ Work transferred successfully")
    
    # Step 3: Stop task workspace immediately
    print("🛑 Stopping task workspace...")
    try:
        # Get workspace ID from task
        workspaces = coder_list_workspaces()
        task_ws = next((w for w in workspaces if task_workspace in w.name), None)
        
        if task_ws:
            coder_create_workspace_build(
                workspace_id=task_ws.id,
                transition="stop"
            )
            print(f"✅ Task workspace stopped: {task_workspace}")
        else:
            print(f"⚠️ Task workspace not found (may already be stopped): {task_workspace}")
    except Exception as e:
        print(f"⚠️ Could not stop workspace: {e}")
        print("Note: Workspace may have auto-stopped or been deleted")
    
    # Step 4: Optional - Delete feature branch
    print("🧹 Cleaning up feature branch...")
    coder_workspace_bash(
        workspace=home_workspace,
        command=f"""
            cd /workspaces/project
            git branch -d {feature_branch}
            git push origin --delete {feature_branch}
        """,
        timeout_ms=30000
    )
    
    print(f"""
✅ Task complete and cleaned up!

Work transferred: {feature_branch} → main
Task workspace: stopped
Feature branch: deleted
    """)
    
    return True
```

### Workspace Lifecycle States

| State | Meaning | Action |
|-------|---------|--------|
| `pending` | Queued for provisioning | Wait |
| `starting` | Provisioning in progress | Wait |
| `running` | Ready for work | Use it |
| `stopping` | Shutting down | Wait for stopped |
| `stopped` | Not consuming resources | Can delete or restart |
| `failed` | Provisioning failed | Delete and retry |

### When to Stop vs Delete

**Stop workspace when:**
- ✅ Work is transferred to home workspace
- ✅ Task is complete
- ✅ Taking a break (>1 hour)
- ✅ End of day

**Delete workspace when:**
- ✅ Work is complete AND merged
- ✅ Task failed and work is not salvageable
- ✅ Workspace is no longer needed
- ✅ Cleaning up old tasks

**Keep workspace running when:**
- ⏳ Actively working
- ⏳ Waiting for long-running operation
- ⏳ Debugging issues
```

**Impact:** Zero manual workspace management, cost savings, clearer expectations

**Implementation Effort:** Low - documentation and helper function

---

## Priority 4: Parallel Task Coordination ⭐

### Problem
Parallel tasks (Phase 5 & 6) worked well but no coordination mechanism:
- Both tasks ran independently
- No way to express dependencies (Phase 6 depends on Phase 5)
- Manual monitoring of multiple tasks

### Recommended Solution: Task Coordination Patterns

**Add to `steering/task-workflow.md`:**

```markdown
## Parallel Task Execution Patterns

### Pattern 1: Independent Parallel Tasks

For completely independent tasks that can run simultaneously:

```python
def create_parallel_tasks(tasks_config, home_workspace):
    """Create multiple independent tasks in parallel"""
    
    task_ids = []
    feature_branches = []
    
    # Create all tasks
    for config in tasks_config:
        # Create feature branch
        branch = f"feature/{config['name']}-{int(time.time())}"
        feature_branches.append(branch)
        
        coder_workspace_bash(
            workspace=home_workspace,
            command=f"""
                cd /workspaces/project
                git checkout -b {branch}
                git push -u origin {branch}
            """,
            timeout_ms=30000
        )
        
        # Create task
        task = coder_create_task(
            input=config['description'],
            template_version_id=config['template_id'],
            rich_parameter_values={
                "feature_branch": branch,
                "home_workspace": home_workspace
            }
        )
        
        task_ids.append(task.id)
        print(f"✅ Created task: {config['name']} on branch {branch}")
    
    return task_ids, feature_branches

# Monitor all tasks
def monitor_parallel_tasks(task_ids):
    """Monitor multiple tasks until all complete"""
    
    pending_tasks = set(task_ids)
    completed_tasks = []
    
    while pending_tasks:
        for task_id in list(pending_tasks):
            status = coder_get_task_status(task_id=task_id)
            
            if status.state.state in ['idle', 'completed']:
                pending_tasks.remove(task_id)
                completed_tasks.append(task_id)
                print(f"✅ Task completed: {task_id}")
            elif status.state.state == 'failure':
                pending_tasks.remove(task_id)
                print(f"❌ Task failed: {task_id}")
        
        if pending_tasks:
            time.sleep(30)  # Check every 30 seconds
    
    return completed_tasks

# Example usage
tasks = [
    {
        'name': 'phase-5-cdk',
        'description': 'Integrate React build into CDK deployment',
        'template_id': 'template-123'
    },
    {
        'name': 'phase-6-monitoring',
        'description': 'Add monitoring dashboard',
        'template_id': 'template-123'
    }
]

task_ids, branches = create_parallel_tasks(tasks, home_workspace)
completed = monitor_parallel_tasks(task_ids)
print(f"✅ All {len(completed)} tasks completed")
```

### Pattern 2: Sequential with Dependencies

For tasks where one depends on another:

```python
def create_sequential_tasks(tasks_config, home_workspace):
    """Create tasks sequentially with dependencies"""
    
    results = []
    
    for i, config in enumerate(tasks_config):
        print(f"Starting task {i+1}/{len(tasks_config)}: {config['name']}")
        
        # Create feature branch
        branch = f"feature/{config['name']}-{int(time.time())}"
        
        coder_workspace_bash(
            workspace=home_workspace,
            command=f"""
                cd /workspaces/project
                git checkout main
                git pull origin main
                git checkout -b {branch}
                git push -u origin {branch}
            """,
            timeout_ms=30000
        )
        
        # Create task
        task = coder_create_task(
            input=config['description'],
            template_version_id=config['template_id'],
            rich_parameter_values={
                "feature_branch": branch,
                "home_workspace": home_workspace,
                "depends_on": results[-1]['branch'] if results else None
            }
        )
        
        # Wait for completion
        while True:
            status = coder_get_task_status(task_id=task.id)
            if status.state.state in ['idle', 'completed']:
                break
            elif status.state.state == 'failure':
                print(f"❌ Task failed: {config['name']}")
                return results
            time.sleep(30)
        
        # Transfer work
        complete_task_with_cleanup(
            task_workspace=f"{owner}/{task.id}",
            home_workspace=home_workspace,
            feature_branch=branch,
            task_description=config['name']
        )
        
        results.append({
            'task_id': task.id,
            'branch': branch,
            'name': config['name']
        })
        
        print(f"✅ Task {i+1} complete: {config['name']}")
    
    return results
```

### Pattern 3: Hybrid (Parallel Groups with Dependencies)

For complex workflows with both parallel and sequential phases:

```python
# Phase 1: Foundation (sequential)
foundation = create_sequential_tasks([
    {'name': 'setup-infrastructure', 'description': '...', 'template_id': '...'}
], home_workspace)

# Phase 2: Parallel development (independent)
parallel_tasks = create_parallel_tasks([
    {'name': 'frontend-components', 'description': '...', 'template_id': '...'},
    {'name': 'backend-api', 'description': '...', 'template_id': '...'},
    {'name': 'database-schema', 'description': '...', 'template_id': '...'}
], home_workspace)

monitor_parallel_tasks(parallel_tasks)

# Phase 3: Integration (sequential, depends on Phase 2)
integration = create_sequential_tasks([
    {'name': 'integrate-components', 'description': '...', 'template_id': '...'}
], home_workspace)
```
```

**Impact:** Better multi-task workflows, clearer dependencies, unified monitoring

**Implementation Effort:** Low - documentation and helper functions

---

## Priority 5: Enhanced Task Prompt Templates ⭐

### Problem
Task prompts don't consistently include all necessary context:
- Git worktree instructions not always followed
- Validation requirements not specified
- Work transfer expectations unclear

### Recommended Solution: Comprehensive Prompt Templates

**Add to `steering/agent-interaction.md`:**

```markdown
## Comprehensive Task Prompt Template

Use this template for all task creation to ensure consistent, high-quality results:

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

# Example usage
prompt = generate_task_prompt(
    task_description="Integrate React app build process into CDK deployment pipeline",
    feature_branch="feature/phase-5-cdk-integration",
    home_workspace="alice/main-workspace",
    repo_path="/workspaces/mvp-ai-demo",
    validation_requirements=[
        "Run full build: `npm run build` - must succeed with zero errors",
        "Test CDK synth: `npx cdk synth -c envName=dev -c siteAssetsPath=../dist`",
        "Verify dist/ directory contains built assets",
        "Check vite.config.ts imports from correct package (vitest/config not vite)",
        "Run type checker: `npm run type-check` - must pass"
    ],
    additional_context="""
CONTEXT:
- React app is in /workspaces/mvp-ai-demo/frontend
- CDK infrastructure is in /workspaces/mvp-ai-demo/infrastructure
- Build output should go to frontend/dist
- CDK needs to reference ../dist for site assets
"""
)

task = coder_create_task(
    input=prompt,
    template_version_id=template_id,
    rich_parameter_values={
        "feature_branch": "feature/phase-5-cdk-integration",
        "home_workspace": "alice/main-workspace"
    }
)
```
```

**Impact:** More consistent task execution, fewer errors, clearer expectations

**Implementation Effort:** Low - documentation and template function

---

## Implementation Roadmap

### Week 1: Critical File Transfer (Immediate Impact)
1. ✅ Update `steering/task-workflow.md` with git-fetch pattern
2. ✅ Add work transfer examples and best practices
3. ✅ Document fallback to manual transfer if git fails
4. ✅ Test with next project iteration

**Expected Impact:** 90% reduction in file transfer time (20 min → 2 min)

### Week 2: Quality & Lifecycle (Reliability)
1. ✅ Add validation checklist to `steering/agent-interaction.md`
2. ✅ Create validation script templates
3. ✅ Add lifecycle management guidance to `steering/task-workflow.md`
4. ✅ Create cleanup helper functions

**Expected Impact:** 80% reduction in post-task fixes, automatic cleanup

### Week 3: Advanced Patterns (Efficiency)
1. ✅ Add parallel task coordination patterns
2. ✅ Create comprehensive prompt templates
3. ✅ Document sequential and hybrid workflows
4. ✅ Add monitoring helper functions

**Expected Impact:** Better multi-task workflows, consistent execution

---

## Success Metrics

### Current State (Session 2)
- Time to first successful task: 5 minutes ✅
- Task recreation cycles: 0 ✅
- Manual file transfer time: 20 minutes ❌
- Post-task bug fixes: 5 minutes ❌
- Total time to completion: 75 minutes

### Target State (With Enhancements)
- Time to first successful task: 5 minutes (maintained)
- Task recreation cycles: 0 (maintained)
- Manual file transfer time: 2 minutes (90% reduction)
- Post-task bug fixes: 1 minute (80% reduction)
- Total time to completion: 45 minutes (40% improvement)

### Success Criteria
- ✅ 100% of tasks created successfully on first attempt (ACHIEVED)
- ✅ Zero template selection errors (ACHIEVED)
- ✅ Zero git authentication failures (ACHIEVED)
- ⏳ 90%+ reduction in file transfer time (TARGET)
- ⏳ 80%+ reduction in post-task bug fixes (TARGET)
- ⏳ Zero manual workspace cleanup (TARGET)

---

## Key Insights from Test Iteration 2

### What Worked Well
1. **Git worktree pattern understanding** - Agent implemented correctly
2. **Template selection** - No errors, correct choice immediately
3. **Parallel execution** - Phase 5 & 6 ran simultaneously, 50% time savings
4. **SSH authentication** - Pre-configured, zero issues

### What Needs Improvement
1. **File transfer** - New biggest bottleneck (20 min)
2. **Task validation** - Bugs slipped through (5 min fixes)
3. **Workspace lifecycle** - Manual cleanup required (5 min)

### Root Causes Identified
1. **Git worktree not enforced** - Instructions alone insufficient
2. **No validation requirements** - Tasks complete without testing
3. **No lifecycle automation** - Manual cleanup needed

---

## Conclusion

Your power has evolved from "error-prone manual" → "reliable but manual" → ready for "automated and efficient."

**Immediate Priority:** Implement git-fetch work transfer pattern in steering documentation. This single change will:
- Reduce file transfer from 20 minutes to 2 minutes (90% reduction)
- Eliminate most tedious manual step
- Reduce total time by 25%

**Next Priorities:** Add validation requirements and lifecycle management for reliability and cost efficiency.

**Expected Outcome:** With these enhancements, total time drops from 75 minutes to ~45 minutes (40% improvement) with near-zero manual intervention.

All recommendations are **documentation-based** - no MCP tool changes needed. Focus on enhancing steering files with patterns, templates, and helper functions that agents can use immediately.
