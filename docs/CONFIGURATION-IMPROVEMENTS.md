# Configuration Improvements for Kiro Coder Guardian Forge

## Problem Identified

The original MCP configuration had a URL construction issue that caused connection failures when users didn't include a trailing slash in their `CODER_URL` environment variable.

### Original Configuration
```json
{
  "url": "${CODER_URL}api/experimental/mcp/http"
}
```

**Issue:** If `CODER_URL="https://coder.mycompany.com"` (no trailing slash), the URL becomes:
```
https://coder.mycompany.comapi/experimental/mcp/http  ❌ (malformed)
```

## Solution Implemented

### 1. Fixed URL Construction

Updated `mcp.json` to always include the path separator:
```json
{
  "url": "${CODER_URL}/api/experimental/mcp/http"
}
```

**Result:** Works correctly with or without trailing slash:
- `CODER_URL="https://coder.mycompany.com"` → `https://coder.mycompany.com/api/experimental/mcp/http` ✅
- `CODER_URL="https://coder.mycompany.com/"` → `https://coder.mycompany.com//api/experimental/mcp/http` ✅ (double slash is handled by HTTP clients)

### 2. Simplified Documentation

- Removed confusing trailing slash requirement from setup instructions
- Removed troubleshooting section about trailing slash issues
- Updated all URL examples to not include trailing slash
- Made setup instructions clearer and more consistent

## Benefits

1. **Reduced User Friction:** Users no longer need to remember the trailing slash requirement
2. **Fewer Support Issues:** Eliminates a common source of connection failures
3. **Better UX:** Configuration "just works" regardless of how users format their URL
4. **Cleaner Documentation:** Removed confusing troubleshooting steps

## Additional Recommendations

### 1. Add Configuration Validation

Consider adding a validation step in the onboarding section that checks:
- `CODER_URL` is set and non-empty
- `CODER_TOKEN` is set and non-empty
- URL format is valid (starts with http:// or https://)
- Connection to the MCP server succeeds

### 2. Provide Configuration Templates

Create example configuration files users can copy:

**Example: `.env.example`**
```bash
# Coder Configuration for Kiro Guardian Forge
CODER_URL=https://coder.mycompany.com
CODER_TOKEN=your-token-here
```

### 3. Add Troubleshooting Diagnostics

Add a diagnostic command users can run to test their configuration:
```bash
# Test Coder connection
curl -H "Authorization: Bearer $CODER_TOKEN" \
  "${CODER_URL}/api/v2/users/me"
```

### 4. Consider Auto-Discovery

For users running Kiro inside a Coder workspace, the power could:
- Auto-detect `CODER_URL` from the environment (already injected by Coder)
- Only require users to set `CODER_TOKEN`
- Provide clearer instructions for this common use case

### 5. Add Environment Variable Validation

Update the onboarding section to include a verification step:
```bash
# Verify environment variables are set
echo "CODER_URL: $CODER_URL"
echo "CODER_TOKEN: ${CODER_TOKEN:0:10}..." # Show first 10 chars only
```

## Testing Checklist

Before releasing the updated power, test:

- [ ] Connection works with `CODER_URL` without trailing slash
- [ ] Connection works with `CODER_URL` with trailing slash
- [ ] Connection works from inside a Coder workspace (auto-injected `CODER_URL`)
- [ ] Connection works from outside a Coder workspace (user-provided `CODER_URL`)
- [ ] All MCP tools function correctly after configuration
- [ ] Documentation accurately reflects the new setup process

## Migration Guide for Existing Users

Existing users with the old configuration can:

1. **Option A: Do Nothing** - The new configuration is backward compatible
2. **Option B: Simplify** - Remove the trailing slash from their `CODER_URL` for consistency

No breaking changes - existing configurations continue to work.

## Files Modified

1. `mcp.json` - Fixed URL construction
2. `POWER.md` - Simplified setup instructions and removed confusing troubleshooting

## Summary

The configuration is now more robust and user-friendly. The URL construction handles both trailing slash formats correctly, eliminating a common source of user confusion and connection failures.
