# Recommended Long-Term Solution for Kiro Coder Guardian Forge

## Current Issues

1. **Environment variable expansion doesn't work** in Kiro's `mcp.json`
2. **Rate limiting (429 errors)** when using personal API tokens
3. **Manual configuration required** for each user/workspace
4. **Credentials must be hardcoded** in config files

## Discovered: Better Authentication Method

Your Coder workspace already provides `CODER_SESSION_TOKEN` which is:
- ✅ Automatically injected into every workspace
- ✅ Scoped to the current user
- ✅ No manual token generation needed
- ✅ Automatically rotated/managed by Coder

**Available environment variables in Coder workspaces:**
```bash
CODER_URL=https://df5td09emx0xp.cloudfront.net/
CODER_SESSION_TOKEN=OSmgMk8YXl-YScJM79QkxjZTfa1gMqa1O
CODER_WORKSPACE_ID=7d6f1d41-c316-413c-afc4-0cca85745c0b
CODER_WORKSPACE_NAME=kiro-codergf-power-proto
CODER_WORKSPACE_OWNER_NAME=admin
```

## Recommended Solution: Template-Based Configuration

### Option A: Inject MCP Config via Coder Template (BEST)

**Concept:** The Coder workspace template creates the MCP configuration file automatically when the workspace starts.

#### Implementation

**1. Add to your Coder workspace template (Terraform):**

```hcl
resource "coder_agent" "dev" {
  # ... existing agent config ...
  
  startup_script = <<-EOT
    #!/bin/bash
    
    # Create Kiro settings directory
    mkdir -p ~/.kiro/settings
    
    # Create MCP configuration with actual values from environment
    cat > ~/.kiro/settings/mcp.json << 'EOF'
{
  "mcpServers": {
    "coder": {
      "url": "${CODER_URL}api/experimental/mcp/http",
      "headers": {
        "Authorization": "Bearer ${CODER_SESSION_TOKEN}"
      },
      "autoApprove": [
        "coder_workspace_edit_file",
        "coder_workspace_read_file",
        "coder_get_task_status",
        "coder_workspace_write_file",
        "coder_workspace_ls",
        "coder_workspace_bash"
      ]
    }
  }
}
EOF
    
    # Substitute actual environment variable values
    sed -i "s|\${CODER_URL}|${CODER_URL}|g" ~/.kiro/settings/mcp.json
    sed -i "s|\${CODER_SESSION_TOKEN}|${CODER_SESSION_TOKEN}|g" ~/.kiro/settings/mcp.json
    
    echo "✅ Kiro MCP configuration created automatically"
  EOT
}
```

**2. Update the power's POWER.md:**

```markdown
## Onboarding

### For Coder Administrators

**Recommended:** Add automatic MCP configuration to your Coder workspace template.

Add this to your template's agent startup script:

\`\`\`hcl
resource "coder_agent" "dev" {
  startup_script = <<-EOT
    #!/bin/bash
    mkdir -p ~/.kiro/settings
    cat > ~/.kiro/settings/mcp.json << 'MCPEOF'
{
  "mcpServers": {
    "coder": {
      "url": "${CODER_URL}api/experimental/mcp/http",
      "headers": {
        "Authorization": "Bearer ${CODER_SESSION_TOKEN}"
      },
      "autoApprove": [
        "coder_workspace_edit_file",
        "coder_workspace_read_file",
        "coder_get_task_status"
      ]
    }
  }
}
MCPEOF
    sed -i "s|\${CODER_URL}|${CODER_URL}|g" ~/.kiro/settings/mcp.json
    sed -i "s|\${CODER_SESSION_TOKEN}|${CODER_SESSION_TOKEN}|g" ~/.kiro/settings/mcp.json
  EOT
}
\`\`\`

**Benefits:**
- ✅ Zero manual configuration for developers
- ✅ Works automatically in every workspace
- ✅ Uses secure session tokens (no personal API tokens needed)
- ✅ Credentials never committed to version control
- ✅ Automatically updated when workspace restarts

### For Developers (Manual Setup)

If your Coder admin hasn't configured automatic setup, you can configure manually:

[Keep existing manual setup instructions as fallback]
```

**3. Remove `mcp.json` from the power:**

The power should NOT include `mcp.json` since configuration is template-based.

#### Advantages

✅ **Zero configuration for developers** - works automatically  
✅ **Secure** - uses session tokens, not personal API tokens  
✅ **Scalable** - all workspaces get the config automatically  
✅ **Maintainable** - admins control the configuration centrally  
✅ **No rate limiting issues** - session tokens have higher limits  
✅ **No credential management** - tokens are auto-rotated by Coder  

#### Disadvantages

❌ Requires Coder admin to update templates  
❌ Doesn't work outside Coder workspaces (but that's the use case anyway)  

---

### Option B: Startup Script in Power (Alternative)

**Concept:** The power includes a setup script that developers run once.

**Create `kiro-coder-guardian-forge/setup.sh`:**

```bash
#!/bin/bash
set -e

echo "🔧 Setting up Kiro Coder Guardian Forge MCP configuration..."

# Check if running in Coder workspace
if [ -z "$CODER_URL" ] || [ -z "$CODER_SESSION_TOKEN" ]; then
  echo "❌ Error: Not running in a Coder workspace"
  echo "This power requires CODER_URL and CODER_SESSION_TOKEN environment variables"
  exit 1
fi

# Create Kiro settings directory
mkdir -p ~/.kiro/settings

# Create MCP configuration
cat > ~/.kiro/settings/mcp.json << EOF
{
  "mcpServers": {
    "coder": {
      "url": "${CODER_URL}api/experimental/mcp/http",
      "headers": {
        "Authorization": "Bearer ${CODER_SESSION_TOKEN}"
      },
      "autoApprove": [
        "coder_workspace_edit_file",
        "coder_workspace_read_file",
        "coder_get_task_status"
      ]
    }
  }
}
EOF

echo "✅ MCP configuration created at ~/.kiro/settings/mcp.json"
echo "✅ Please restart Kiro to connect to the Coder MCP server"
```

**In POWER.md:**

```markdown
## Onboarding

### Quick Setup

Run the setup script to automatically configure the MCP server:

\`\`\`bash
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh
\`\`\`

Then restart Kiro to connect to the Coder MCP server.
```

#### Advantages

✅ Simple one-command setup  
✅ Works without admin involvement  
✅ Uses secure session tokens  

#### Disadvantages

❌ Developers must run the script manually  
❌ Must re-run after workspace restarts (unless added to shell profile)  
❌ Still requires some user action  

---

### Option C: Kiro Hook for Auto-Configuration (Most Elegant)

**Concept:** Use a Kiro hook to automatically configure MCP on Kiro startup.

**Create `.kiro/hooks/coder-mcp-auto-config.kiro.hook`:**

```json
{
  "name": "Auto-Configure Coder MCP",
  "version": "1.0.0",
  "description": "Automatically configure Coder MCP server on Kiro startup",
  "when": {
    "type": "promptSubmit"
  },
  "then": {
    "type": "runCommand",
    "command": "bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh"
  }
}
```

But this requires the hook to run before MCP servers connect, which may not work.

---

## Final Recommendation

**Use Option A (Template-Based Configuration)** because:

1. **Best user experience** - zero configuration required
2. **Most secure** - uses session tokens, not personal API tokens
3. **Scalable** - works for all developers automatically
4. **Maintainable** - centrally managed by admins
5. **Solves rate limiting** - session tokens have higher limits

### Implementation Steps

1. **Update Coder workspace template** to inject MCP config on startup
2. **Remove `mcp.json` from the power** (not needed with template approach)
3. **Update POWER.md** with template configuration instructions
4. **Add fallback manual setup** for users without template access
5. **Test in a fresh workspace** to verify automatic configuration

### Power Structure After Fix

```
kiro-coder-guardian-forge/
├── POWER.md              # Updated with template-based setup
├── steering/
│   ├── task-workflow.md
│   ├── workspace-ops.md
│   └── agent-interaction.md
└── setup.sh              # Optional: manual setup script as fallback
```

**No `mcp.json` file** - configuration is template-based.

---

## Addressing the 429 Rate Limiting Issue

The 429 error you're seeing is likely because:

1. **Personal API tokens have lower rate limits** than session tokens
2. **Multiple connection attempts** during testing hit the limit
3. **MCP server reconnection logic** may be too aggressive

**Solutions:**

1. **Use `CODER_SESSION_TOKEN` instead of personal API token** (higher limits)
2. **Add rate limit handling** in the MCP server connection logic
3. **Increase reconnection backoff** to avoid hammering the server
4. **Contact Coder team** to increase rate limits for MCP endpoints

---

## Migration Path

### For Existing Users

1. **Coder admins:** Update workspace templates with MCP config injection
2. **Developers:** Rebuild workspaces to get new configuration
3. **Verify:** Check `~/.kiro/settings/mcp.json` exists after workspace start
4. **Test:** Restart Kiro and verify MCP server connects

### For New Users

1. **Install power** from repository
2. **Workspace starts** with MCP config already configured
3. **Start Kiro** - MCP server connects automatically
4. **Start working** - no manual configuration needed

---

## Testing Checklist

After implementing the template-based solution:

- [ ] Fresh workspace creates `~/.kiro/settings/mcp.json` automatically
- [ ] MCP config contains actual values (not `${VAR}` placeholders)
- [ ] Kiro connects to Coder MCP server on startup
- [ ] All MCP tools are available and functional
- [ ] No 429 rate limiting errors with session tokens
- [ ] Configuration persists across Kiro restarts
- [ ] Configuration updates when workspace rebuilds
- [ ] Manual setup script works as fallback

---

## Summary

**Template-based MCP configuration injection** is the best long-term solution because it:

- Eliminates manual configuration entirely
- Uses secure, auto-rotated session tokens
- Scales to all developers automatically
- Solves the environment variable expansion problem
- Avoids rate limiting issues
- Provides the best developer experience

This approach aligns with Coder's philosophy of infrastructure-as-code and makes the power truly "plug and play" for developers.
