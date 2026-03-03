# Documentation

This directory contains reference documentation and implementation guides for the Kiro Coder Guardian Forge power.

---

## Current Documentation

### Implementation Guides

- **[WORK-TRANSFER-PATTERN.md](WORK-TRANSFER-PATTERN.md)** - Git-based work transfer pattern
  - How work is transferred between task and home workspaces
  - `complete_task_with_cleanup()` function documentation
  - Code examples and troubleshooting
  - v3.2 pattern (git fetch/merge)

- **[TASK-READY-TEMPLATES.md](TASK-READY-TEMPLATES.md)** - Template requirements
  - What makes a template "task-ready"
  - Required `coder_ai_task` resource
  - Template configuration examples
  - Best practices for template design

- **[QUICK-REFERENCE-V3.2.md](QUICK-REFERENCE-V3.2.md)** - Quick examples
  - Copy-paste code examples for v3.2 features
  - Automated work transfer examples
  - Task prompt templates
  - Parallel task coordination
  - Validation patterns

---

## Historical Documentation

Historical development documentation is archived in the `archive/` directory:

- **[archive/v3-development/](archive/v3-development/)** - v3.2 development documentation
  - Enhancement recommendations and analysis
  - Implementation summaries
  - Review reports

- **[archive/v1-v2-historical/](archive/v1-v2-historical/)** - v1 and v2 historical documentation
  - Original development documentation
  - Migration guides
  - Historical implementation summaries

See [archive/README.md](archive/README.md) for complete archive index.

---

## Quick Links

### Getting Started
- [POWER.md](../POWER.md) - Main power documentation
- [README.md](../README.md) - Overview and quick reference
- [QUICK-START.md](../QUICK-START.md) - 5-minute getting started guide
- [CHANGELOG.md](../CHANGELOG.md) - Version history

### Steering Files (On-Demand Loading)
- [steering/task-workflow.md](../steering/task-workflow.md) - Task creation and monitoring
- [steering/agent-interaction.md](../steering/agent-interaction.md) - Workspace agent collaboration
- [steering/workspace-ops.md](../steering/workspace-ops.md) - Workspace operations

### Configuration
- [coder-template-example.tf](../coder-template-example.tf) - Complete template example
- [setup.sh](../setup.sh) - Manual setup script (fallback)

---

## Documentation Organization

```
docs/
├── README.md                      # This file
├── WORK-TRANSFER-PATTERN.md       # Work transfer guide
├── TASK-READY-TEMPLATES.md        # Template requirements
├── QUICK-REFERENCE-V3.2.md        # Quick examples
│
└── archive/                       # Historical documentation
    ├── README.md                  # Archive index
    ├── v3-development/            # v3.2 development docs
    └── v1-v2-historical/          # v1 and v2 historical docs
```

---

## Contributing

When adding new documentation:

1. **User-facing guides** → Root directory or docs/
2. **Reference documentation** → docs/
3. **Development documentation** → docs/archive/vX-development/
4. **Historical documentation** → docs/archive/vX-historical/

Keep the root directory clean with only essential, current documentation.

---

**Version:** 3.2.0  
**Last Updated:** March 3, 2026
