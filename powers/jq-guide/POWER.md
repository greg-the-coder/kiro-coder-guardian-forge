---
name: "jq-guide"
displayName: "jq CLI Guide"
description: "Complete guide for using jq command-line JSON processor with common patterns and examples"
keywords: ["jq", "json", "cli", "parser", "filter"]
author: "Kiro Example"
---

# jq CLI Guide

## Overview

jq is a lightweight and flexible command-line JSON processor. It's like sed for JSON data - you can use it to slice, filter, map, and transform structured data with ease. This guide covers installation, common workflows, and troubleshooting for everyday jq usage.

## Onboarding

### Installation

#### Via package manager (Linux)
```bash
sudo apt-get install jq
```

#### Via Homebrew (macOS)
```bash
brew install jq
```

#### Via download (Windows/Other)
Download from: https://jqlang.github.io/jq/download/

### Prerequisites
- No special prerequisites
- Works on Linux, macOS, Windows

### Verification
```bash
# Verify installation
jq --version

# Expected output:
jq-1.6 (or higher)
```

## Common Workflows

### Workflow: Pretty Print JSON

**Goal:** Format JSON for readability

**Command:**
```bash
echo '{"name":"John","age":30}' | jq '.'
```

**Output:**
```json
{
  "name": "John",
  "age": 30
}
```

### Workflow: Extract Specific Fields

**Goal:** Get specific values from JSON

**Commands:**
```bash
# Extract single field
echo '{"name":"John","age":30}' | jq '.name'
# Output: "John"

# Extract multiple fields
echo '{"name":"John","age":30,"city":"NYC"}' | jq '{name, age}'
# Output: {"name":"John","age":30}
```

### Workflow: Filter Arrays

**Goal:** Filter and transform array data

**Command:**
```bash
# Filter array elements
echo '[{"name":"John","age":30},{"name":"Jane","age":25}]' | jq '.[] | select(.age > 26)'
# Output: {"name":"John","age":30}

# Map over array
echo '[1,2,3,4,5]' | jq 'map(. * 2)'
# Output: [2,4,6,8,10]
```

## Command Reference

### Basic Syntax
```bash
jq [options] 'filter' [file...]
```

### Common Options
| Flag | Description | Example |
|------|-------------|---------|
| `-r` | Raw output (no quotes) | `jq -r '.name'` |
| `-c` | Compact output | `jq -c '.'` |
| `-s` | Slurp (read entire input into array) | `jq -s '.'` |
| `-n` | Use null input | `jq -n '{a:1}'` |

## Troubleshooting

### Error: "parse error: Invalid numeric literal"
**Cause:** Invalid JSON input
**Solution:**
1. Validate your JSON: `echo 'your-json' | jq '.'`
2. Check for trailing commas, missing quotes, or malformed structure
3. Use online JSON validator if needed

### Error: "jq: command not found"
**Cause:** jq not installed or not in PATH
**Solution:**
1. Install jq using package manager (see Installation section)
2. Verify installation: `which jq`
3. Restart terminal after installation

## Best Practices

- Use single quotes for jq filters to avoid shell interpretation
- Test filters on small data samples first
- Combine with other CLI tools using pipes
- Use `-r` flag when you need raw string output
- Save complex filters in files for reuse

## Additional Resources

- Official Documentation: https://jqlang.github.io/jq/manual/
- jq Playground: https://jqplay.org/
- GitHub Repository: https://github.com/jqlang/jq

---

**CLI Tool:** `jq`
**Installation:** `brew install jq` or `apt-get install jq`
