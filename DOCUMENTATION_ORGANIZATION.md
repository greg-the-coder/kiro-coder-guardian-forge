# Documentation Organization Plan

**Date:** March 3, 2026  
**Purpose:** Organize documentation for clarity and maintainability

---

## Organization Strategy

### Root Directory (User-Facing, Current)
Keep only essential, current documentation that users need:
- POWER.md (required)
- README.md (overview)
- CHANGELOG.md (version history)
- QUICK-START.md (getting started)
- LICENSE (legal)

### docs/ Directory (Reference Documentation)
Current reference documentation:
- WORK-TRANSFER-PATTERN.md (implementation guide)
- TASK-READY-TEMPLATES.md (template requirements)
- QUICK-REFERENCE-V3.2.md (quick examples)
- coder-template-example.tf (template example)
- setup.sh (setup script)

### docs/archive/v3-development/ (v3.2 Development)
Development and enhancement documentation for v3.2:
- ENHANCEMENT_RECOMMENDATIONS.md
- ENHANCEMENTS_V3.2_SUMMARY.md
- IMPLEMENTATION_COMPLETE.md
- POWER_REVIEW_REPORT.md
- REVIEW_FIXES_COMPLETE.md

### docs/archive/v1-v2-historical/ (Historical)
Historical development documentation from v1 and v2:
- All files currently in docs/ folder
- IMPLEMENTATION_OPTIONS.md
- IMPLEMENTATION_SUMMARY.md
- PHASE1_COMPLETE.md
- RESTRUCTURING-SUMMARY.md

---

## File Movements

### Keep in Root (8 files)
- ✅ POWER.md
- ✅ README.md
- ✅ CHANGELOG.md
- ✅ QUICK-START.md
- ✅ LICENSE
- ✅ setup.sh
- ✅ coder-template-example.tf
- ✅ .gitignore

### Move to docs/ (3 files)
- WORK-TRANSFER-PATTERN.md → docs/
- TASK-READY-TEMPLATES.md → docs/
- QUICK-REFERENCE-V3.2.md → docs/

### Move to docs/archive/v3-development/ (5 files)
- ENHANCEMENT_RECOMMENDATIONS.md → docs/archive/v3-development/
- ENHANCEMENTS_V3.2_SUMMARY.md → docs/archive/v3-development/
- IMPLEMENTATION_COMPLETE.md → docs/archive/v3-development/
- POWER_REVIEW_REPORT.md → docs/archive/v3-development/
- REVIEW_FIXES_COMPLETE.md → docs/archive/v3-development/

### Move to docs/archive/v1-v2-historical/ (22 files)
From docs/:
- AGENT-INTERACTION-SUMMARY.md
- COMPLETION-SUMMARY.md
- CONFIGURATION-IMPROVEMENTS.md
- CRITICAL-ISSUE-FOUND.md
- EXECUTION-PLAN.md
- EXECUTION-PLAN-UPDATE.md
- FILE-STRUCTURE.md
- FINAL-SUMMARY.md
- IMPLEMENTATION-SUMMARY.md
- MIGRATION-TO-V2.md
- MIGRATION-TO-WORK-TRANSFER.md
- OPTIMIZATION-SUMMARY.md
- PROTOTYPE-SUMMARY.md
- RECOMMENDED-SOLUTION.md
- REQUIREMENTS.md
- TESTING-PLAN.md
- UPDATE-SUMMARY.md
- V2-COMPLETION-CHECKLIST.md

From root:
- IMPLEMENTATION_OPTIONS.md
- IMPLEMENTATION_SUMMARY.md
- PHASE1_COMPLETE.md
- RESTRUCTURING-SUMMARY.md

---

## Final Structure

```
kiro-coder-guardian-forge/
├── POWER.md                          # Required power documentation
├── README.md                         # Overview and quick reference
├── CHANGELOG.md                      # Version history
├── QUICK-START.md                    # Getting started guide
├── LICENSE                           # License file
├── setup.sh                          # Setup script
├── coder-template-example.tf         # Template example
├── .gitignore                        # Git ignore rules
│
├── steering/                         # Steering files (on-demand loading)
│   ├── task-workflow.md
│   ├── agent-interaction.md
│   └── workspace-ops.md
│
├── docs/                             # Reference documentation
│   ├── README.md                     # Documentation index
│   ├── WORK-TRANSFER-PATTERN.md      # Work transfer guide
│   ├── TASK-READY-TEMPLATES.md       # Template requirements
│   ├── QUICK-REFERENCE-V3.2.md       # Quick examples
│   │
│   └── archive/                      # Historical documentation
│       ├── README.md                 # Archive index
│       │
│       ├── v3-development/           # v3.2 development docs
│       │   ├── ENHANCEMENT_RECOMMENDATIONS.md
│       │   ├── ENHANCEMENTS_V3.2_SUMMARY.md
│       │   ├── IMPLEMENTATION_COMPLETE.md
│       │   ├── POWER_REVIEW_REPORT.md
│       │   └── REVIEW_FIXES_COMPLETE.md
│       │
│       └── v1-v2-historical/         # v1 and v2 historical docs
│           ├── AGENT-INTERACTION-SUMMARY.md
│           ├── COMPLETION-SUMMARY.md
│           ├── CONFIGURATION-IMPROVEMENTS.md
│           ├── CRITICAL-ISSUE-FOUND.md
│           ├── EXECUTION-PLAN.md
│           ├── EXECUTION-PLAN-UPDATE.md
│           ├── FILE-STRUCTURE.md
│           ├── FINAL-SUMMARY.md
│           ├── IMPLEMENTATION-OPTIONS.md
│           ├── IMPLEMENTATION-SUMMARY.md
│           ├── MIGRATION-TO-V2.md
│           ├── MIGRATION-TO-WORK-TRANSFER.md
│           ├── OPTIMIZATION-SUMMARY.md
│           ├── PHASE1_COMPLETE.md
│           ├── PROTOTYPE-SUMMARY.md
│           ├── RECOMMENDED-SOLUTION.md
│           ├── REQUIREMENTS.md
│           ├── RESTRUCTURING-SUMMARY.md
│           ├── TESTING-PLAN.md
│           ├── UPDATE-SUMMARY.md
│           └── V2-COMPLETION-CHECKLIST.md
```

---

## Benefits

### For Users
- ✅ Clean root directory with only essential files
- ✅ Easy to find getting started documentation
- ✅ Clear separation of current vs historical docs
- ✅ Reference docs organized in docs/ folder

### For Maintainers
- ✅ Historical context preserved in archive
- ✅ Development documentation organized by version
- ✅ Easy to find relevant documentation
- ✅ Clear structure for future additions

### For Repository
- ✅ Professional organization
- ✅ Reduced clutter in root
- ✅ Better discoverability
- ✅ Easier navigation

---

## Implementation Steps

1. Create archive directories
2. Move v3 development docs to docs/archive/v3-development/
3. Move v1-v2 historical docs to docs/archive/v1-v2-historical/
4. Move reference docs to docs/
5. Create README.md files for docs/ and docs/archive/
6. Update any references in remaining files
7. Verify all links still work

---

**Status:** Ready for implementation
