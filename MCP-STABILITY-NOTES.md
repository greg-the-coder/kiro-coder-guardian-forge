# MCP Server Stability Notes

## Current Status: ✅ Connected and Working

The Coder MCP server is now successfully connected and operational.

**Test Results:**
- ✅ `coder_get_authenticated_user` - Working (authenticated as admin)
- ✅ `coder_list_workspaces` - Working (returned 4 workspaces)
- ✅ `coder_list_templates` - Working (returned 14 templates)

## What Fixed the Connection Issues

### 1. Correct Authentication Method
**Problem:** Originally tried to use personal API tokens via `CODER_TOKEN`
**Solution:** Switched to `CODER_SESSION_TOKEN` (automatically available in Coder workspaces)

**Benefits of session tokens:**
- Higher rate limits (no more 429 errors)
- Automatically rotated by Coder
- No manual token generation required
- Scoped to the current user session

### 2. Proper Configuration File
**Problem:** Environment variable expansion (`${VAR}`) doesn't work in Kiro's `mcp.json`
**Solution:** Use `setup.sh` script to generate config with actual values

**Working configuration:**
```json
{
  "mcpServers": {
    "coder": {
      "url": "https://df5td09emx0xp.cloudfront.net/api/experimental/mcp/http",
      "headers": {
        "Authorization": "Bearer OSmgMk8YXl-YScJM79QkxjZTfa1gMqa1O"
      },
      "autoApprove": [...]
    }
  }
}
```

### 3. Correct URL Format
**Problem:** URL construction issues with trailing slashes
**Solution:** Ensure URL is properly formatted: `${CODER_URL}api/experimental/mcp/http`

Since `CODER_URL` already has a trailing slash in Coder workspaces, the final URL becomes:
`https://df5td09emx0xp.cloudfront.net/api/experimental/mcp/http`

## Known MCP Stability Considerations

### 1. Connection Lifecycle

**Normal behavior:**
- MCP servers connect when Kiro starts
- Connection is maintained via HTTP/SSE (Server-Sent Events)
- Automatic reconnection on connection loss
- May see brief disconnections during network issues

**What to expect in logs:**
```
[info] [coder] MCP server connecting...
[info] [coder] MCP server connected
[info] [coder] MCP connection closed successfully  # Normal during reconnects
```

### 2. Rate Limiting

**With personal API tokens:**
- Lower rate limits
- 429 errors common during testing
- Need to wait for rate limit reset

**With session tokens (current setup):**
- Higher rate limits
- Rare 429 errors
- Better for production use

**If you hit rate limits:**
- Wait 5-10 minutes for reset
- Reduce connection retry frequency
- Contact Coder team to increase limits

### 3. Session Token Expiration

**Session tokens expire when:**
- User logs out of Coder
- Workspace is stopped/restarted
- Token is manually revoked
- Session timeout is reached

**What happens:**
- MCP server will fail to authenticate
- Need to regenerate config with new token
- Run `setup.sh` again to update

**Long-term solution:**
- Add token refresh logic to workspace startup script
- Automatically regenerate config on workspace start
- See `coder-template-example.tf` for implementation

### 4. Network Issues

**Symptoms:**
- Intermittent connection failures
- Timeout errors
- SSE connection drops

**Causes:**
- Network latency between workspace and Coder server
- Firewall/proxy issues
- CloudFront CDN issues (in your case)
- Kubernetes pod networking issues

**Solutions:**
- Check network connectivity: `curl ${CODER_URL}`
- Verify DNS resolution
- Check Coder server health
- Review Kubernetes network policies

### 5. Coder Server Issues

**Symptoms:**
- All MCP operations fail
- 500/502/503 errors
- Connection refused

**Causes:**
- Coder server down or restarting
- MCP experiment not enabled
- Server overloaded

**Solutions:**
- Check Coder server status
- Verify `mcp-server-http` experiment is enabled
- Check Coder server logs
- Contact Coder admin

## Best Practices for Stability

### 1. Use Session Tokens
✅ Always use `CODER_SESSION_TOKEN` in Coder workspaces
❌ Avoid personal API tokens for MCP connections

### 2. Auto-Regenerate Config
✅ Add config generation to workspace startup script
❌ Don't rely on manual configuration

### 3. Handle Reconnections Gracefully
✅ Expect brief disconnections
✅ Implement retry logic with backoff
❌ Don't spam reconnection attempts

### 4. Monitor Connection Health
✅ Check MCP server status periodically
✅ Log connection events
✅ Alert on persistent failures

### 5. Keep Tokens Fresh
✅ Regenerate config on workspace restart
✅ Handle token expiration gracefully
❌ Don't cache expired tokens

## Troubleshooting Checklist

If MCP server disconnects:

1. **Check environment variables:**
   ```bash
   echo "CODER_URL: $CODER_URL"
   echo "CODER_SESSION_TOKEN: ${CODER_SESSION_TOKEN:0:10}..."
   ```

2. **Verify config file:**
   ```bash
   cat ~/.kiro/settings/mcp.json
   ```

3. **Test Coder API directly:**
   ```bash
   curl -H "Authorization: Bearer ${CODER_SESSION_TOKEN}" \
     "${CODER_URL}api/v2/users/me"
   ```

4. **Regenerate config:**
   ```bash
   bash ~/kiro-coder-guardian-forge/setup.sh
   ```

5. **Restart Kiro:**
   - Reload window or restart Kiro process
   - Check MCP Servers panel for connection status

6. **Check Kiro logs:**
   - Look for MCP connection errors
   - Check for rate limiting (429)
   - Look for authentication errors (401)

## Monitoring MCP Health

### Quick Health Check
```bash
# Test authentication
curl -s -H "Authorization: Bearer ${CODER_SESSION_TOKEN}" \
  "${CODER_URL}api/v2/users/me" | jq -r '.username'

# Should output: admin (or your username)
```

### Full Diagnostic
```bash
# 1. Check environment
env | grep CODER_

# 2. Check config
cat ~/.kiro/settings/mcp.json

# 3. Test API
curl -s -H "Authorization: Bearer ${CODER_SESSION_TOKEN}" \
  "${CODER_URL}api/v2/users/me"

# 4. Test MCP endpoint
curl -s -X POST \
  -H "Authorization: Bearer ${CODER_SESSION_TOKEN}" \
  -H "Content-Type: application/json" \
  "${CODER_URL}api/experimental/mcp/http" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}'
```

## Known Issues and Workarounds

### Issue: Connection drops after idle period
**Workaround:** Kiro should auto-reconnect. If not, restart Kiro.

### Issue: 429 rate limiting during testing
**Workaround:** Wait 5-10 minutes between test runs. Use session tokens.

### Issue: Token expires after workspace restart
**Workaround:** Add config regeneration to workspace startup script.

### Issue: Environment variables not expanded
**Workaround:** Use `setup.sh` to generate config with actual values.

## Future Improvements

1. **Auto-refresh on token expiration**
   - Detect 401 errors
   - Regenerate config automatically
   - Reconnect MCP server

2. **Health monitoring**
   - Periodic health checks
   - Alert on connection failures
   - Automatic recovery

3. **Better error messages**
   - Clear guidance on fixing issues
   - Link to troubleshooting docs
   - Suggest specific solutions

4. **Connection pooling**
   - Reuse connections
   - Reduce connection overhead
   - Improve performance

## Summary

The Coder MCP server is now stable and working correctly. The key factors for stability are:

1. ✅ Using `CODER_SESSION_TOKEN` for authentication
2. ✅ Proper configuration file with actual values (not env vars)
3. ✅ Correct URL format
4. ✅ Understanding normal connection lifecycle
5. ✅ Having troubleshooting procedures ready

The connection should remain stable during normal use. Brief disconnections during network issues or Kiro restarts are normal and expected.
