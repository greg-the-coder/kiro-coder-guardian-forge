# One-Time Setup for Kiro + Coder (5 minutes)

This guide walks you through the one-time setup required before creating your first Coder task. After completing these steps once, all future workspaces will work automatically.

---

## What's Automatic vs. What's Manual

### ✅ Automatic (Template Handles This)

Your Coder workspace template automatically configures:
- **SSH key generation** - Creates `~/.ssh/id_ed25519` key pair
- **Git identity configuration** - Sets your name and email from Coder profile
- **Git remote format** - Uses SSH format (`git@github.com:user/repo.git`)
- **Coder SSH wrapper** - Handles SSH authentication through Coder infrastructure
- **File permissions** - Sets correct permissions on SSH keys (600 for private, 644 for public)

### ⚠️ Manual (You Do This Once)

You need to complete one manual step:
- **Add SSH public key to GitHub/GitLab** - This authorizes your Coder workspaces to push code

**Why this can't be automated:** GitHub and GitLab require you to manually add SSH keys to your account for security reasons. This is standard git workflow and ensures only you can authorize access to your repositories.

---

## Setup Steps

### Step 1: Get Your SSH Public Key

Your Coder workspace has already generated an SSH key. Display it with:

```bash
cat ~/.ssh/id_ed25519.pub
```

You'll see output like:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOJlS4Ynsmgt4i0y7qYcF6hesW9NTdCGahedxqFDa3j0 your@email.com
```

**Copy the entire line** - you'll need it in the next step.

---

### Step 2: Add Key to GitHub

1. Copy the entire public key from Step 1
2. Go to https://github.com/settings/keys
3. Click **"New SSH key"**
4. Give it a title (e.g., "Coder Workspace")
5. Paste your public key into the "Key" field
6. Click **"Add SSH key"**

**Screenshot reference:**
```
GitHub Settings → SSH and GPG keys → New SSH key
┌─────────────────────────────────────────┐
│ Title: Coder Workspace                  │
│ Key:   ssh-ed25519 AAAAC3Nza...        │
│        [paste your full public key]     │
│                                         │
│        [Add SSH key]                    │
└─────────────────────────────────────────┘
```

---

### Step 2 (Alternative): Add Key to GitLab

If you're using GitLab instead of GitHub:

1. Copy the entire public key from Step 1
2. Go to https://gitlab.com/-/profile/keys
3. Paste your public key into the "Key" field
4. Give it a title (e.g., "Coder Workspace")
5. Set expiration date (optional, recommended: 1 year)
6. Click **"Add key"**

---

### Step 3: Test Authentication

Verify that GitHub/GitLab recognizes your SSH key:

**For GitHub:**
```bash
ssh -T git@github.com
```

**Expected output:**
```
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

**For GitLab:**
```bash
ssh -T git@gitlab.com
```

**Expected output:**
```
Welcome to GitLab, @username!
```

✅ If you see these messages, authentication is working!

---

### Step 4: Verify Git Configuration

Check that your git identity is configured correctly:

```bash
env | grep GIT_
```

You should see:
```
GIT_AUTHOR_NAME=your-name
GIT_AUTHOR_EMAIL=your@email.com
GIT_COMMITTER_NAME=your-name
GIT_COMMITTER_EMAIL=your@email.com
GIT_SSH_COMMAND=/tmp/coder.../coder gitssh --
```

✅ If you see these variables, your git configuration is correct!

---

### Step 5: Verify Git Remote Format

If you have an existing repository cloned, verify it uses SSH format:

```bash
cd /workspaces/your-project
git remote -v
```

You should see:
```
origin  git@github.com:user/repo.git (fetch)
origin  git@github.com:user/repo.git (push)
```

✅ If you see `git@github.com:...`, the remote is correctly configured!

❌ If you see `https://github.com/...`, convert to SSH:
```bash
git remote set-url origin git@github.com:user/repo.git
git remote -v  # Verify the change
```

---

## That's It!

After completing this one-time setup, all Coder workspaces will work automatically. You won't need to repeat these steps.

**What happens next:**
- All new Coder workspaces will use the same SSH key
- Git operations (clone, push, pull) will work seamlessly
- Task workspaces can push code without additional configuration
- You can create and complete tasks without manual intervention

---

## Troubleshooting

### Problem: "Permission denied (publickey)"

**Cause:** SSH key not added to GitHub/GitLab

**Solution:**
1. Get your public key: `cat ~/.ssh/id_ed25519.pub`
2. Add to GitHub: https://github.com/settings/keys
3. Test again: `ssh -T git@github.com`

---

### Problem: "Could not resolve hostname"

**Cause:** Network connectivity issue

**Solution:**
1. Check network: `ping github.com`
2. If ping fails, check your internet connection
3. Contact Coder administrator if issue persists

---

### Problem: Git remote uses HTTPS instead of SSH

**Cause:** Repository was cloned with HTTPS URL

**Solution:**
```bash
cd /workspaces/your-project

# Get current remote URL
git remote get-url origin

# Convert HTTPS to SSH
# From: https://github.com/user/repo.git
# To:   git@github.com:user/repo.git
git remote set-url origin git@github.com:user/repo.git

# Verify
git remote -v
```

---

### Problem: SSH key permissions incorrect

**Cause:** File permissions were changed manually

**Solution:**
```bash
# Fix permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Test again
ssh -T git@github.com
```

---

### Problem: "Host key verification failed"

**Cause:** GitHub/GitLab host key not in known_hosts

**Solution:**
```bash
# Add GitHub to known hosts
ssh-keyscan github.com >> ~/.ssh/known_hosts

# Or for GitLab
ssh-keyscan gitlab.com >> ~/.ssh/known_hosts

# Test again
ssh -T git@github.com
```

---

## Verification Checklist

Before creating your first task, verify:

- [ ] SSH public key added to GitHub/GitLab
- [ ] `ssh -T git@github.com` shows successful authentication
- [ ] `env | grep GIT_` shows git identity variables
- [ ] `git remote -v` shows SSH format (if repository exists)
- [ ] No "Permission denied" errors when testing SSH

✅ All checks passed? You're ready to create Coder tasks!

---

## Next Steps

Now that setup is complete:

1. **Create your first task** - See QUICK-START.md for a 5-minute guide
2. **Load task-workflow.md** - Learn the complete task creation workflow
3. **Explore validation patterns** - See validation-patterns.md for quality gates

---

## Additional Resources

- **QUICK-START.md** - 5-minute quick start guide
- **POWER.md** - Complete power documentation
- **steering/task-workflow.md** - Detailed task creation workflow
- **GitHub SSH Documentation** - https://docs.github.com/en/authentication/connecting-to-github-with-ssh
- **GitLab SSH Documentation** - https://docs.gitlab.com/ee/user/ssh.html

---

**Setup Time:** 5 minutes (one-time only)  
**Future Workspaces:** Zero setup required  
**Benefit:** Seamless git operations in all Coder tasks
