# Quick Setup Reference - v2.0

## For Coder Administrators

### Add to Template (One-Time Setup)

```hcl
resource "coder_agent" "dev" {
  startup_script = <<-EOT
    # Kiro MCP Auto-Configuration
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
        "coder_get_task_status"
      ]
    }
  }
}
MCPEOF
    sed -i "s|\$${CODER_URL}|$${CODER_URL}|g" ~/.kiro/settings/mcp.json
    sed -i "s|\$${CODER_SESSION_TOKEN}|$${CODER_SESSION_TOKEN}|g" ~/.kiro/settings/mcp.json
  EOT
}
```

**That's it!** All developers get automatic configuration.

---

## For Developers

### Automatic Setup (If Admin Configured Template)

**No action needed!** Just:
1. Start your workspace
2. Start Kiro
3. MCP server connects automatically

### Manual Setup (If Template Not Updated)

```bash
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh
```

Then restart Kiro.

---

## Verification

### Check Configuration
```bash
cat ~/.kiro/settings/mcp.json
```

Should show actual values (not `${VAR}` placeholders).

### Test Connection
In Kiro, call:
```
coder_get_authenticated_user
```

Should return your user info.

---

## Troubleshooting

### MCP Server Not Connected

```bash
# Run setup script
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh

# Restart Kiro
```

### Configuration Has Placeholders

```bash
# Manually substitute values
sed -i "s|\${CODER_URL}|${CODER_URL}|g" ~/.kiro/settings/mcp.json
sed -i "s|\${CODER_SESSION_TOKEN}|${CODER_SESSION_TOKEN}|g" ~/.kiro/settings/mcp.json

# Restart Kiro
```

### Unauthorized Errors

```bash
# Restart workspace to get fresh token
# Then run setup again
bash ~/.kiro/powers/installed/kiro-coder-guardian-forge/setup.sh
```

---

## Key Files

- **`setup.sh`** - Manual configuration script
- **`coder-template-example.tf`** - Complete template example
- **`MCP-STABILITY-NOTES.md`** - Detailed troubleshooting
- **`POWER.md`** - Complete documentation

---

## Quick Facts

✅ **No personal API tokens needed** - uses session tokens  
✅ **No environment variables to set** - automatic  
✅ **No rate limiting** - session tokens have higher limits  
✅ **Auto-rotated tokens** - managed by Coder  
✅ **Zero configuration** - with template approach  

---

## Support

**For detailed help:** See `MCP-STABILITY-NOTES.md`  
**For migration:** See `MIGRATION-TO-V2.md`  
**For architecture:** See `RECOMMENDED-SOLUTION.md`
