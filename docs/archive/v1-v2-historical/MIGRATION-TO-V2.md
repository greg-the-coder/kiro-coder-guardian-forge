# Migration Guide: v1.0 to v2.0

## Overview

Version 2.0 introduces a **template-based configuration approach** that eliminates manual setup and provides a better developer experience.

## What Changed

### Configuration Method

**v1.0 (Old):**
- Power included `mcp.json` with environment variable placeholders
- Required manual environment variable setup
- Used personal API tokens
- Developers had to configure each workspace

**v2.0 (New):**
- No `mcp.json` in power
- Template-based automatic configuration
- Uses session tokens (automatically available)
- Zero configuration for developers

### Authentication

**v1.0 (Old):**
```bash
export CODER_TOKEN="<personal-api-token>"
```
- Manual token generation required
- Lower rate limits
- Manual token rotation

**v2.0 (New):**
```bash
# No manual setup needed - uses CODER_SESSION_TOKEN
```
- Automatically available in workspaces
- Higher rate limits
- Auto-rotated by Coder

### Setup Process

**v1.0 (Old):**
1. Generate personal API token
2. Set environment variables
3. Reload shell
4. Install power
5. Restart Kiro

**v2.0 (New):**

**Option A (Recommended):**
1. Admin adds config to template (one-time)
2. Developers start workspace
3. Configuration created automatically
4. Start Kiro - works immediately

**Option B (Manual):**
1. Run `setup.sh` script
2. Restart Kiro
3. Done

## Migration Steps

### For Coder Administrators

**Step 1: Update workspace templates**

Add this to your template's agent startup script:

```hcl
resource "coder_agent" "dev" {
  startup_script = <<-EOT
    #!/bin/bash
    
    # Your existing startup commands...
    
    # Kiro MCP Configuration
    echo "🔧 Configuring Kiro MCP for Coder..."
    mkdir -p ~/.kiro/settings
    
    cat > ~/.kiro/settings/mcp.json << 'MCPEOF'
{
  "mcpServers": {
    "coder": {
      "url": "$${CODER_URL}api/experimental/mcp/http",
      "headers": {
        "Authorization": "Bearer $${CODER_SESSION_TOKEN}"
      },
      "autoApprove": [
        "coder_workspace_edit_file",
        "coder_workspace_read_file",
        "coder_get_task_status",
        "coder_workspace_write_file",
        "coder_workspace_ls",
        "coder_workspace_bash",
        "coder_get_task_logs",
        "coder_list_templates",
        "coder_create_task"
      ]
    }
  }
}
MCPEOF
    
    sed -i "s|\$${CODER_URL}|$${CODER_URL}|g" ~/.kiro/settings/mcp.json
    sed -i "s|\$${CODER_SESSION_TOKEN}|$${CODER_SESSION_TOKEN}|g" ~/.kiro/settings/mcp.json
    
    echo "✅ Kiro MCP configuration created"
  EOT
}
```

**Step 2: Test in a new workspace**

1. Create a test workspace from the updated template
2. Verify `~/.kiro/settings/mcp.json` is created
3. Start Kiro and verify MCP server connects
4. Test with `coder_get_authenticated_user`

**Step 3: Roll out to production templates**

Once tested, update all production templates.

**Step 4: Communicate to developers**

Let developers know:
- Next workspace rebuild will have automatic configuration
- No action needed from them
- Old manual setup no longer required

### For Developers

#### If Your Admin Has Updated Templates

**No action needed!** Next time you start/rebuild your workspace:
1. Configuration will be created automatically
2. Start Kiro - MCP server connects automatically
3. Start working

#### If Your Admin Hasn't Updated Templates Yet

**Run the setup script:**

```bash
# Navigate to the power directory
cd ~/.kiro/powers/installed/kiro-coder-guardian-forge

# Run setup script
bash setup.sh

# Restart Kiro
```

**Verify connection:**
1. Check MCP Servers panel - "coder" should be connected
2. Test: Call `coder_get_authenticated_user`

## Troubleshooting Migration

### Issue: MCP server not connecting after migration

**Solution:**
```bash
# Check if config file exists
cat ~/.kiro/settings/mcp.json

# If missing or has ${VAR} placeholders, run setup
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh

# Restart Kiro
```

### Issue: Still getting 429 rate limit errors

**Cause:** May still be using old personal API token configuration

**Solution:**
```bash
# Remove old config
rm ~/.kiro/settings/mcp.json

# Run setup script to create new config with session token
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh

# Restart Kiro
```

### Issue: Configuration has ${CODER_SESSION_TOKEN} placeholder

**Cause:** Template script didn't substitute environment variables

**Solution:**
```bash
# Manually run the substitution
sed -i "s|\${CODER_URL}|${CODER_URL}|g" ~/.kiro/settings/mcp.json
sed -i "s|\${CODER_SESSION_TOKEN}|${CODER_SESSION_TOKEN}|g" ~/.kiro/settings/mcp.json

# Restart Kiro
```

### Issue: "Unauthorized" errors after migration

**Cause:** Session token may have expired

**Solution:**
```bash
# Restart workspace to get fresh session token
# Then run setup script
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh

# Restart Kiro
```

## Verification Checklist

After migration, verify:

- [ ] Configuration file exists: `~/.kiro/settings/mcp.json`
- [ ] Config has actual values (not `${VAR}` placeholders)
- [ ] Config uses session token (not personal API token)
- [ ] MCP server "coder" appears in Kiro MCP Servers panel
- [ ] Server status shows "connected"
- [ ] Can call `coder_get_authenticated_user` successfully
- [ ] Can call `coder_list_templates` successfully
- [ ] No 429 rate limiting errors
- [ ] Configuration persists across Kiro restarts

## Benefits of v2.0

### For Developers
- ✅ Zero manual configuration
- ✅ Works immediately in new workspaces
- ✅ No token management
- ✅ No rate limiting issues
- ✅ Automatic updates on workspace restart

### For Administrators
- ✅ Centralized configuration management
- ✅ Consistent setup across all workspaces
- ✅ No support burden for token setup
- ✅ Better security (session tokens)
- ✅ Easier onboarding for new developers

### For Everyone
- ✅ More reliable (no environment variable issues)
- ✅ Better security (auto-rotated tokens)
- ✅ Higher rate limits (session tokens)
- ✅ Easier maintenance
- ✅ Better developer experience

## Rollback Plan

If you need to rollback to v1.0 approach:

1. **Restore `mcp.json` to power:**
   ```json
   {
     "mcpServers": {
       "coder": {
         "url": "YOUR_CODER_URL_HERE/api/experimental/mcp/http",
         "headers": {
           "Authorization": "Bearer YOUR_CODER_TOKEN_HERE"
         }
       }
     }
   }
   ```

2. **Update with actual values:**
   - Replace `YOUR_CODER_URL_HERE` with your Coder URL
   - Replace `YOUR_CODER_TOKEN_HERE` with personal API token

3. **Restart Kiro**

However, we recommend staying on v2.0 for the improved experience.

## Support

If you encounter issues during migration:

1. Check `MCP-STABILITY-NOTES.md` for troubleshooting
2. Review `RECOMMENDED-SOLUTION.md` for architecture details
3. Check Kiro MCP logs for error messages
4. Contact your Coder administrator for template issues

## Summary

v2.0 provides a significantly better experience through:
- Template-based automatic configuration
- Session token authentication
- Zero manual setup for developers
- Better reliability and security

The migration is straightforward and provides immediate benefits.
