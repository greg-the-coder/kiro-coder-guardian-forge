# Token Efficiency Guide for Work Transfer

This guide explains how to minimize token usage when transferring work from task workspaces to home workspaces.

---

## The Problem

Reading file contents into the agent context consumes tokens. For large projects or files, this can:
- ❌ Exceed context window limits
- ❌ Increase costs significantly
- ❌ Slow down operations
- ❌ Cause transfer failures

---

## Token Usage by Method

| Transfer Method | Token Usage | File Size Limit | File Count Limit | Production Ready |
|-----------------|-------------|------------------|------------------|------------------|
| **Git Patch** | **1-10KB** | Unlimited | Unlimited | ✅ Yes |
| **Bash Direct** | **~100 bytes** | Unlimited | Unlimited | ✅ Yes |
| File List | File size × count | 100KB per file | 5-10 files | ⚠️ Limited |
| Full Directory | All file content | 10KB per file | 20 files | ❌ No |

---

## Recommended Methods

### Method 1: Git Patch Transfer (BEST for Git Projects)

**Token Usage:** 1-10KB regardless of project size

**How it works:**
- Creates a git patch containing only diffs (changed lines)
- Patch file is typically 1-10KB even for large changes
- Only the patch content passes through agent context
- Full files never read into context

**Example:**
```python
# 1. Commit in task workspace
coder_workspace_bash(
    workspace=task_ws,
    command="cd /home/coder/project && git add . && git commit -m 'Task complete'"
)

# 2. Create patch (only diffs, ~5KB)
coder_workspace_bash(
    workspace=task_ws,
    command="cd /home/coder/project && git format-patch -1 HEAD --stdout > /tmp/task.patch"
)

# 3. Transfer patch (minimal tokens)
patch = coder_workspace_read_file(workspace=task_ws, path="/tmp/task.patch")
coder_workspace_write_file(workspace=home_ws, path="/tmp/task.patch", content=patch)

# 4. Apply patch
coder_workspace_bash(
    workspace=home_ws,
    command="cd /home/coder/project && git am /tmp/task.patch"
)
```

**Token Breakdown:**
- Bash commands: ~200 bytes
- Patch file content: 1-10KB (only diffs)
- **Total: ~10KB maximum**

**Comparison:**
- Traditional file-by-file: 100KB - 10MB+ (all file content)
- Git patch: 1-10KB (only diffs)
- **Savings: 90-99%**

---

### Method 2: Bash Direct Transfer (BEST for Non-Git Projects)

**Token Usage:** ~100 bytes (only bash commands)

**How it works:**
- Uses bash commands to copy files directly
- No file content passes through agent context
- Requires workspaces to share filesystem or use rsync

**Example:**
```python
# Transfer using rsync (zero tokens for file content)
coder_workspace_bash(
    workspace=task_ws,
    command="""
        rsync -av --delete /home/coder/project/ \
        /home/coder/workspaces/home-workspace/project/
    """
)
```

**Token Breakdown:**
- Bash command: ~100 bytes
- File content: 0 bytes (not in context)
- **Total: ~100 bytes**

**Comparison:**
- Traditional file-by-file: 100KB - 10MB+
- Bash direct: ~100 bytes
- **Savings: 99.9%**

---

## Anti-Patterns (Avoid These)

### Anti-Pattern 1: Reading Large Files

```python
# ❌ BAD: Reads entire file into context
content = coder_workspace_read_file(
    workspace=task_ws,
    path="/home/coder/project/large-file.json"  # 5MB file
)
# This uses 5MB of tokens!
```

**Problem:** Large files consume massive tokens

**Solution:** Use git patch or bash direct transfer

---

### Anti-Pattern 2: Looping Through Many Files

```python
# ❌ BAD: Reads each file individually
for file in changed_files:  # 100 files
    content = coder_workspace_read_file(workspace=task_ws, path=file)
    coder_workspace_write_file(workspace=home_ws, path=file, content=content)
# This reads 100 files into context!
```

**Problem:** Each file read consumes tokens

**Solution:** Use git patch (one operation) or bash direct transfer

---

### Anti-Pattern 3: Transferring Binary Files

```python
# ❌ BAD: Binary files are base64 encoded (33% larger)
image = coder_workspace_read_file(
    workspace=task_ws,
    path="/home/coder/project/image.png"  # 2MB image
)
# This uses 2.66MB of tokens (base64 overhead)!
```

**Problem:** Binary files are inefficient in base64

**Solution:** Use bash direct transfer or git (git handles binaries efficiently)

---

## Token Efficiency Checklist

Before transferring work, ask:

- [ ] Is this a git project? → Use git patch transfer
- [ ] Do workspaces share filesystem? → Use bash direct transfer
- [ ] Are there < 5 small files? → File list transfer acceptable
- [ ] Are there large files (> 1MB)? → Must use git patch or bash direct
- [ ] Are there many files (> 10)? → Must use git patch or bash direct
- [ ] Are there binary files? → Must use bash direct or git

---

## Calculating Token Usage

### Git Patch Method

```python
# Estimate patch size
result = coder_workspace_bash(
    workspace=task_ws,
    command="cd /home/coder/project && git diff HEAD --stat"
)

# Typical output:
# 5 files changed, 120 insertions(+), 30 deletions(-)
# Patch size: ~5KB (150 lines × ~30 bytes/line)
```

**Formula:** ~30 bytes per changed line

**Example:**
- 100 lines changed → ~3KB patch
- 1000 lines changed → ~30KB patch
- 10000 lines changed → ~300KB patch

---

### File List Method

```python
# Calculate total size
total_size = 0
for file in changed_files:
    result = coder_workspace_bash(
        workspace=task_ws,
        command=f"stat -c%s {file}"
    )
    total_size += int(result.stdout.strip())

# Add base64 overhead (33%)
token_usage = total_size * 1.33

print(f"Estimated token usage: {token_usage / 1024:.1f} KB")
```

**Formula:** File size × 1.33 (base64 overhead)

**Example:**
- 10 files × 10KB each = 100KB
- With base64: 133KB tokens
- **Recommendation:** Use git patch instead (would be ~5KB)

---

## Optimization Strategies

### Strategy 1: Batch Commits

Instead of transferring after each change:

```python
# ❌ BAD: Transfer after each change
for task in tasks:
    do_work(task)
    transfer_to_home()  # Multiple transfers

# ✅ GOOD: Batch changes
for task in tasks:
    do_work(task)

transfer_to_home()  # Single transfer
```

---

### Strategy 2: Checkpoint Strategically

Transfer at logical boundaries, not time-based:

```python
# ❌ BAD: Transfer every hour
while working:
    do_work()
    if time_elapsed > 1_hour:
        transfer_to_home()

# ✅ GOOD: Transfer at milestones
implement_feature()
transfer_to_home()  # Checkpoint

add_tests()
transfer_to_home()  # Checkpoint

add_documentation()
transfer_to_home()  # Final
```

---

### Strategy 3: Use .gitignore

Exclude unnecessary files from transfer:

```bash
# .gitignore
node_modules/
*.log
.DS_Store
__pycache__/
*.pyc
.env
```

This reduces:
- Files to transfer
- Patch size
- Token usage

---

## Monitoring Token Usage

### Track Transfer Size

```python
def transfer_with_monitoring(task_ws, home_ws):
    # Before transfer
    start_time = time.time()
    
    # Create patch
    coder_workspace_bash(
        workspace=task_ws,
        command="cd /home/coder/project && git format-patch -1 HEAD --stdout > /tmp/task.patch"
    )
    
    # Check patch size
    result = coder_workspace_bash(
        workspace=task_ws,
        command="stat -c%s /tmp/task.patch"
    )
    
    patch_size = int(result.stdout.strip())
    print(f"Patch size: {patch_size / 1024:.1f} KB")
    
    # Transfer
    patch = coder_workspace_read_file(workspace=task_ws, path="/tmp/task.patch")
    coder_workspace_write_file(workspace=home_ws, path="/tmp/task.patch", content=patch)
    
    # Apply
    coder_workspace_bash(
        workspace=home_ws,
        command="cd /home/coder/project && git am /tmp/task.patch"
    )
    
    elapsed = time.time() - start_time
    print(f"Transfer complete in {elapsed:.1f}s using {patch_size / 1024:.1f} KB tokens")
```

---

## Best Practices Summary

1. **Always use git patch for git projects** (90-99% token savings)
2. **Use bash direct for non-git projects** (99.9% token savings)
3. **Never read large files into context** (> 100KB)
4. **Never loop through many files** (> 10 files)
5. **Check file sizes before transfer** (fail fast if too large)
6. **Use .gitignore to exclude unnecessary files**
7. **Batch changes before transferring**
8. **Monitor patch sizes** (should be < 100KB)
9. **Checkpoint at logical boundaries** (not time-based)
10. **Verify transfer method is efficient** (log token usage)

---

## Troubleshooting

### Problem: "Context window exceeded"

**Cause:** Trying to transfer too much content through agent context

**Solution:**
1. Switch to git patch method
2. Or use bash direct transfer
3. Check for large files: `find . -type f -size +1M`
4. Check file count: `find . -type f | wc -l`

---

### Problem: "Patch file too large"

**Cause:** Too many changes in one commit

**Solution:**
1. Break into smaller commits
2. Transfer at checkpoints more frequently
3. Use bash direct transfer instead

---

### Problem: "Transfer taking too long"

**Cause:** Reading many files individually

**Solution:**
1. Use git patch (single operation)
2. Or use bash direct transfer
3. Don't loop through files

---

## Summary

**Token Efficiency Ranking:**

1. **Bash Direct:** ~100 bytes (99.9% savings)
2. **Git Patch:** 1-10KB (90-99% savings)
3. **File List:** File size × 1.33 (moderate)
4. **Full Directory:** All content (avoid)

**Default Strategy:**
- Git project? → Git patch
- Non-git project? → Bash direct
- Emergency only? → File list (< 5 small files)

**Remember:** Token efficiency is critical for production use. Always prefer git patch or bash direct transfer methods.
