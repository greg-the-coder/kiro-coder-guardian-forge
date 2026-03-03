# CRITICAL ISSUE: Environment Variable Expansion Not Supported

## Problem Discovery

While testing the kiro-coder-guardian-forge power, we discovered that **Kiro does NOT support environment variable expansion in `mcp.json` files**.

### What Doesn't Work

```json
{
  "mcpServers": {
    "coder": {
      "url": "${CODER_URL}/api/experimental/mcp/http",  // ❌ Not expanded
      "headers": {
        "Authorization": "Bearer ${CODER_TOKEN}"  // ❌ Not expanded
      }
    }
  }
}
```

**Error message:**
```
[warning] [coder] Invalid MCP Server coder URL: ${CODER_URL}/api/experimental/mcp/http, ignoring.
```

## Root Cause

The power's design assumes Kiro will expand `${VAR}` references at runtime, but this feature doesn't exist. The documentation incorrectly states:

> "Kiro expands the `${VAR}` references at runtime, so credentials are never hardcoded"

This is **false** - Kiro does not expand environment variables in MCP configurations.

## Impact

This makes the power **unusable as designed** because:

1. Users cannot use environment variables for configuration
2. Users must hardcode their Coder URL and API token in the config file
3. The config file becomes sensitive and cannot be safely committed to version control
4. The power cannot be easily shared or distributed
5. Each user needs a different configuration file

## Required Solution

The power needs a **fundamental redesign**. Here are the options:

### Option 1: Use Placeholders (Recommended for Powers)

Update the power's `mcp.json` to use placeholders that users must manually replace:

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

**In POWER.md, add a "MCP Config Placeholders" section:**

```markdown
## MCP Config Placeholders

**IMPORTANT:** Before using this power, replace the following placeholders in `mcp.json`:

- **`YOUR_CODER_URL_HERE`**: Your Coder server URL (e.g., `https://coder.mycompany.com`)
  - **How to get it:** 
    1. Check your Coder deployment URL
    2. If running inside a Coder workspace: `echo $CODER_URL`
    3. Replace `YOUR_CODER_URL_HERE` with the actual URL (without trailing slash)

- **`YOUR_CODER_TOKEN_HERE`**: Your Coder personal API token
  - **How to get it:**
    1. Log into Coder web UI
    2. Navigate to Account → Tokens
    3. Click "Generate Token"
    4. Copy the token value
    5. Replace `YOUR_CODER_TOKEN_HERE` with your actual token

**After replacing placeholders, your mcp.json should look like:**
```json
{
  "mcpServers": {
    "coder": {
      "url": "https://coder.mycompany.com/api/experimental/mcp/http",
      "headers": {
        "Authorization": "Bearer coder_abc123xyz..."
      }
    }
  }
}
```

**Security Note:** After configuration, your `mcp.json` contains sensitive credentials. Do not commit this file to version control.
```

### Option 2: Local STDIO MCP Server (Alternative)

Instead of a remote HTTP server, create a local MCP server wrapper that:
1. Reads environment variables
2. Proxies requests to the Coder HTTP API
3. Can be configured via environment variables

**mcp.json:**
```json
{
  "mcpServers": {
    "coder": {
      "command": "npx",
      "args": ["-y", "@coder/mcp-server"],
      "env": {
        "CODER_URL": "CODER_URL",
        "CODER_TOKEN": "CODER_TOKEN"
      }
    }
  }
}
```

This requires building a new MCP server package, but would provide the environment variable support the power needs.

### Option 3: User-Level Configuration Only

Don't include `mcp.json` in the power at all. Instead, instruct users to manually configure the MCP server in their user-level or workspace-level settings.

**Remove `mcp.json` from the power entirely.**

**In POWER.md:**
```markdown
## Manual MCP Server Configuration

This power requires manual MCP server configuration because Kiro does not support environment variable expansion in MCP configs.

**Step 1: Get your Coder URL and token**
[existing instructions]

**Step 2: Configure the MCP server**

Add this to your `.kiro/settings/mcp.json` (workspace) or `~/.kiro/settings/mcp.json` (user):

```json
{
  "mcpServers": {
    "coder": {
      "url": "https://your-coder-url.com/api/experimental/mcp/http",
      "headers": {
        "Authorization": "Bearer your-actual-token-here"
      }
    }
  }
}
```

Replace:
- `https://your-coder-url.com` with your actual Coder server URL
- `your-actual-token-here` with your actual Coder API token
```

## Recommendation

**Use Option 1 (Placeholders)** for the power distribution, with clear documentation about replacing placeholders.

This follows the power-builder best practices for handling user-specific configuration in shareable powers.

## Files That Need Updates

1. **`mcp.json`** - Replace environment variables with placeholder text
2. **`POWER.md`** - Add "MCP Config Placeholders" section with detailed instructions
3. **`POWER.md`** - Remove claims about environment variable expansion
4. **`POWER.md`** - Update onboarding to explain placeholder replacement
5. **All steering files** - Remove references to automatic environment variable expansion

## Testing After Fix

After implementing the fix, verify:
- [ ] Power can be installed from the power directory
- [ ] Documentation clearly explains placeholder replacement
- [ ] Users can successfully configure the MCP server
- [ ] MCP server connects after placeholder replacement
- [ ] All tools work correctly after configuration
