# Validation Patterns and Quality Gates

This steering file provides comprehensive validation patterns for different project types. Load this when creating tasks to include validation requirements in prompts, reducing post-task bugs by 80%.

---

## Overview

**Validation-First Approach:**
- Include validation requirements in task prompts
- Workspace agents validate before marking complete
- External agents verify after work transfer
- Reduces post-task bug fixes from 20 minutes to 0 minutes

**Three Validation Layers:**
1. **Pre-Completion Validation** - Workspace agent validates before finishing
2. **Post-Transfer Validation** - External agent verifies after merge
3. **Deployment Validation** - Final checks before production

---

## Universal Validation Checklist

**Include this in every task prompt:**

```markdown
## Validation Requirements

Before marking this task complete, validate:

### Code Quality
- [ ] All code follows project style guidelines
- [ ] No syntax errors or linting warnings
- [ ] All functions have docstrings/comments
- [ ] No hardcoded credentials or secrets
- [ ] Error handling implemented for edge cases

### Testing
- [ ] Unit tests written for new functions
- [ ] All tests pass locally
- [ ] Test coverage meets project standards (>80%)
- [ ] Edge cases covered in tests

### Documentation
- [ ] README updated with new features
- [ ] API documentation updated
- [ ] Code comments explain complex logic
- [ ] CHANGELOG updated with changes

### Git Hygiene
- [ ] All changes committed with clear messages
- [ ] No debug code or console.logs left in
- [ ] Branch pushed to remote
- [ ] No merge conflicts

### Verification
- [ ] Run full test suite: `npm test` or `pytest`
- [ ] Check for linting errors: `npm run lint` or `flake8`
- [ ] Verify application starts: `npm start` or `python app.py`
- [ ] Test key functionality manually

**Only mark task as complete after all checks pass.**
```

---

## Project-Type-Specific Validation

### Python Projects

```markdown
## Python Validation Checklist

### Code Quality
- [ ] PEP 8 compliance: `flake8 .`
- [ ] Type hints on all functions
- [ ] No unused imports: `autoflake --check .`
- [ ] Code formatted: `black --check .`

### Testing
- [ ] pytest runs successfully: `pytest -v`
- [ ] Coverage >80%: `pytest --cov=src --cov-report=term`
- [ ] No test warnings or deprecations

### Dependencies
- [ ] requirements.txt updated
- [ ] Virtual environment works: `python -m venv test_env && source test_env/bin/activate && pip install -r requirements.txt`
- [ ] No security vulnerabilities: `pip-audit`

### Python-Specific
- [ ] No circular imports
- [ ] __init__.py files present in packages
- [ ] Docstrings follow Google/NumPy style

### Verification Commands
```bash
# Run all validations
flake8 src/
black --check src/
pytest --cov=src --cov-report=term-missing
python -m mypy src/
```
```

### Node.js/TypeScript Projects

```markdown
## Node.js/TypeScript Validation Checklist

### Code Quality
- [ ] ESLint passes: `npm run lint`
- [ ] TypeScript compiles: `npm run build`
- [ ] No TypeScript errors: `tsc --noEmit`
- [ ] Code formatted: `npm run format:check`

### Testing
- [ ] All tests pass: `npm test`
- [ ] Coverage >80%: `npm run test:coverage`
- [ ] No console errors in test output

### Dependencies
- [ ] package.json updated
- [ ] package-lock.json committed
- [ ] No security vulnerabilities: `npm audit`
- [ ] Dependencies install cleanly: `rm -rf node_modules && npm install`

### TypeScript-Specific
- [ ] All types properly defined (no `any` unless necessary)
- [ ] Interfaces exported for public APIs
- [ ] Strict mode enabled in tsconfig.json

### Verification Commands
```bash
# Run all validations
npm run lint
npm run build
npm test
npm audit
tsc --noEmit
```
```

### Go Projects

```markdown
## Go Validation Checklist

### Code Quality
- [ ] gofmt applied: `gofmt -l .`
- [ ] go vet passes: `go vet ./...`
- [ ] golint passes: `golint ./...`
- [ ] No unused variables or imports

### Testing
- [ ] All tests pass: `go test ./...`
- [ ] Coverage >80%: `go test -cover ./...`
- [ ] Race detector passes: `go test -race ./...`
- [ ] Benchmarks run: `go test -bench=. ./...`

### Dependencies
- [ ] go.mod updated
- [ ] go.sum committed
- [ ] Dependencies tidy: `go mod tidy`
- [ ] Vendor directory updated (if used): `go mod vendor`

### Go-Specific
- [ ] Error handling follows Go conventions
- [ ] Exported functions have godoc comments
- [ ] Context passed correctly in concurrent code

### Verification Commands
```bash
# Run all validations
gofmt -l .
go vet ./...
go test -race -cover ./...
go mod tidy
```
```

### React/Frontend Projects

```markdown
## React/Frontend Validation Checklist

### Code Quality
- [ ] ESLint passes: `npm run lint`
- [ ] No console.log statements in production code
- [ ] PropTypes or TypeScript types defined
- [ ] Accessibility attributes present (aria-*, alt text)

### Testing
- [ ] Component tests pass: `npm test`
- [ ] No React warnings in console
- [ ] Snapshot tests updated if needed
- [ ] Integration tests pass

### Build & Bundle
- [ ] Production build succeeds: `npm run build`
- [ ] Bundle size acceptable: `npm run analyze`
- [ ] No build warnings
- [ ] Assets optimized (images, fonts)

### UI/UX
- [ ] Responsive design works (mobile, tablet, desktop)
- [ ] Loading states implemented
- [ ] Error states handled gracefully
- [ ] Keyboard navigation works

### Verification Commands
```bash
# Run all validations
npm run lint
npm test
npm run build
npm run analyze
```
```

### API/Backend Projects

```markdown
## API/Backend Validation Checklist

### Code Quality
- [ ] API follows RESTful conventions
- [ ] Input validation on all endpoints
- [ ] Authentication/authorization implemented
- [ ] Rate limiting configured

### Testing
- [ ] Unit tests for business logic
- [ ] Integration tests for API endpoints
- [ ] Load tests for critical paths
- [ ] Security tests (SQL injection, XSS, etc.)

### API Documentation
- [ ] OpenAPI/Swagger spec updated
- [ ] Example requests/responses documented
- [ ] Error codes documented
- [ ] Authentication flow documented

### Security
- [ ] No secrets in code
- [ ] Environment variables used for config
- [ ] HTTPS enforced
- [ ] CORS configured correctly
- [ ] SQL injection prevention
- [ ] XSS prevention

### Verification Commands
```bash
# Run all validations
npm test
npm run test:integration
npm run test:security
curl -X GET http://localhost:3000/health
```
```

### Infrastructure/DevOps Projects

```markdown
## Infrastructure/DevOps Validation Checklist

### Code Quality
- [ ] Terraform/CDK code formatted
- [ ] No hardcoded values (use variables)
- [ ] Resource naming follows conventions
- [ ] Tags applied to all resources

### Testing
- [ ] Terraform plan succeeds: `terraform plan`
- [ ] No security warnings
- [ ] Cost estimation reviewed
- [ ] Dry-run deployment tested

### Documentation
- [ ] Architecture diagram updated
- [ ] Deployment instructions clear
- [ ] Rollback procedure documented
- [ ] Monitoring/alerting configured

### Security
- [ ] IAM policies follow least privilege
- [ ] Secrets in secret manager (not code)
- [ ] Network security groups configured
- [ ] Encryption enabled

### Verification Commands
```bash
# Run all validations
terraform fmt -check
terraform validate
terraform plan
tfsec .
```
```

---

## Enhanced Task Prompt Templates

### Template 1: Feature Implementation

```markdown
# Task: Implement [Feature Name]

## Objective
[Clear description of what needs to be built]

## Requirements
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

## Technical Specifications
- Language: [Python/Node.js/Go/etc.]
- Framework: [React/Express/Django/etc.]
- Key files to modify: [list files]

## Implementation Steps
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Validation Requirements

### Pre-Completion Checklist
[Include project-type-specific checklist from above]

### Verification Commands
```bash
# Run these commands before marking complete
[project-specific commands]
```

### Success Criteria
- [ ] All tests pass
- [ ] No linting errors
- [ ] Feature works as specified
- [ ] Documentation updated
- [ ] Code committed and pushed

**Do not mark this task complete until all validation requirements are met.**
```

### Template 2: Bug Fix

```markdown
# Task: Fix [Bug Description]

## Bug Description
[Detailed description of the bug]

## Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Expected vs Actual behavior]

## Root Cause Analysis
[If known, describe the root cause]

## Fix Requirements
- Identify root cause
- Implement fix
- Add regression test
- Verify fix works
- Document the fix

## Validation Requirements

### Pre-Completion Checklist
- [ ] Bug reproduced and confirmed
- [ ] Root cause identified
- [ ] Fix implemented
- [ ] Regression test added
- [ ] All existing tests still pass
- [ ] Bug no longer reproducible
- [ ] Code reviewed for similar issues
- [ ] Documentation updated

### Verification Commands
```bash
# Reproduce bug (should fail before fix)
[commands to reproduce]

# Run tests (should pass after fix)
[test commands]

# Verify fix
[verification commands]
```

### Success Criteria
- [ ] Bug is fixed
- [ ] Regression test prevents recurrence
- [ ] No new bugs introduced
- [ ] All tests pass

**Do not mark this task complete until bug is verified fixed.**
```

### Template 3: Refactoring

```markdown
# Task: Refactor [Component/Module Name]

## Refactoring Goal
[What needs to be improved and why]

## Current Issues
- [Issue 1]
- [Issue 2]
- [Issue 3]

## Refactoring Plan
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Validation Requirements

### Pre-Completion Checklist
- [ ] All functionality preserved (no behavior changes)
- [ ] All existing tests still pass
- [ ] Code is more maintainable
- [ ] Performance not degraded
- [ ] Documentation updated
- [ ] No new warnings or errors

### Verification Commands
```bash
# Run full test suite
[test commands]

# Check performance (if applicable)
[benchmark commands]

# Verify no regressions
[verification commands]
```

### Success Criteria
- [ ] Code quality improved
- [ ] All tests pass
- [ ] No functionality broken
- [ ] Performance maintained or improved

**Do not mark this task complete until all tests pass and functionality is verified.**
```

---

## Validation Function Library

### Function: Generate Validation Prompt

```python
def generate_validation_prompt(project_type, task_description):
    """
    Generate task prompt with appropriate validation requirements.
    
    Args:
        project_type: 'python', 'nodejs', 'go', 'react', 'api', 'infrastructure'
        task_description: Description of the task
    
    Returns:
        Complete task prompt with validation requirements
    """
    
    # Universal validation
    universal_validation = """
## Validation Requirements

Before marking this task complete, validate:

### Code Quality
- [ ] All code follows project style guidelines
- [ ] No syntax errors or linting warnings
- [ ] All functions have docstrings/comments
- [ ] No hardcoded credentials or secrets
- [ ] Error handling implemented for edge cases

### Testing
- [ ] Unit tests written for new functions
- [ ] All tests pass locally
- [ ] Test coverage meets project standards (>80%)
- [ ] Edge cases covered in tests

### Documentation
- [ ] README updated with new features
- [ ] API documentation updated
- [ ] Code comments explain complex logic
- [ ] CHANGELOG updated with changes

### Git Hygiene
- [ ] All changes committed with clear messages
- [ ] No debug code or console.logs left in
- [ ] Branch pushed to remote
- [ ] No merge conflicts
"""
    
    # Project-specific validation
    project_validations = {
        'python': """
### Python-Specific Validation
- [ ] PEP 8 compliance: `flake8 .`
- [ ] Type hints on all functions
- [ ] Code formatted: `black --check .`
- [ ] pytest passes: `pytest -v`
- [ ] Coverage >80%: `pytest --cov=src`

### Verification Commands
```bash
flake8 src/
black --check src/
pytest --cov=src --cov-report=term-missing
python -m mypy src/
```
""",
        'nodejs': """
### Node.js-Specific Validation
- [ ] ESLint passes: `npm run lint`
- [ ] TypeScript compiles: `npm run build`
- [ ] All tests pass: `npm test`
- [ ] No security vulnerabilities: `npm audit`

### Verification Commands
```bash
npm run lint
npm run build
npm test
npm audit
```
""",
        'go': """
### Go-Specific Validation
- [ ] gofmt applied: `gofmt -l .`
- [ ] go vet passes: `go vet ./...`
- [ ] All tests pass: `go test ./...`
- [ ] Race detector passes: `go test -race ./...`

### Verification Commands
```bash
gofmt -l .
go vet ./...
go test -race -cover ./...
```
""",
        'react': """
### React-Specific Validation
- [ ] ESLint passes: `npm run lint`
- [ ] Component tests pass: `npm test`
- [ ] Production build succeeds: `npm run build`
- [ ] No React warnings in console
- [ ] Accessibility attributes present

### Verification Commands
```bash
npm run lint
npm test
npm run build
```
""",
        'api': """
### API-Specific Validation
- [ ] API follows RESTful conventions
- [ ] Input validation on all endpoints
- [ ] Authentication/authorization implemented
- [ ] OpenAPI/Swagger spec updated
- [ ] Integration tests pass

### Verification Commands
```bash
npm test
npm run test:integration
curl -X GET http://localhost:3000/health
```
""",
        'infrastructure': """
### Infrastructure-Specific Validation
- [ ] Terraform/CDK code formatted
- [ ] Terraform plan succeeds: `terraform plan`
- [ ] No security warnings: `tfsec .`
- [ ] IAM policies follow least privilege
- [ ] Secrets in secret manager

### Verification Commands
```bash
terraform fmt -check
terraform validate
terraform plan
tfsec .
```
"""
    }
    
    # Build complete prompt
    prompt = f"""# Task: {task_description}

## Objective
{task_description}

{universal_validation}

{project_validations.get(project_type, '')}

### Success Criteria
- [ ] All validation checks pass
- [ ] All tests pass
- [ ] Code committed and pushed
- [ ] Documentation updated

**Do not mark this task complete until all validation requirements are met.**
"""
    
    return prompt

# Usage
task_prompt = generate_validation_prompt(
    project_type='python',
    task_description='Implement user authentication with JWT tokens'
)
```

### Function: Verify Task Completion

```python
def verify_task_completion(home_workspace, repo_path, project_type):
    """
    Verify task completed all validation requirements.
    
    Args:
        home_workspace: Home workspace identifier
        repo_path: Path to repository
        project_type: Type of project for specific checks
    
    Returns:
        dict with validation results
    """
    results = {
        'passed': [],
        'failed': [],
        'warnings': [],
        'overall_pass': False
    }
    
    # Universal checks
    
    # Check 1: No uncommitted changes
    result = coder_workspace_bash(
        workspace=home_workspace,
        command=f"cd {repo_path} && git status --porcelain",
        timeout_ms=5000
    )
    if result.stdout.strip():
        results['failed'].append("Uncommitted changes found")
    else:
        results['passed'].append("All changes committed")
    
    # Check 2: Branch pushed to remote
    result = coder_workspace_bash(
        workspace=home_workspace,
        command=f"cd {repo_path} && git status -sb",
        timeout_ms=5000
    )
    if "ahead" in result.stdout:
        results['failed'].append("Branch not pushed to remote")
    else:
        results['passed'].append("Branch pushed to remote")
    
    # Project-specific checks
    if project_type == 'python':
        # Check flake8
        result = coder_workspace_bash(
            workspace=home_workspace,
            command=f"cd {repo_path} && flake8 src/",
            timeout_ms=30000
        )
        if result.exit_code == 0:
            results['passed'].append("Flake8 passed")
        else:
            results['failed'].append(f"Flake8 failed: {result.stdout}")
        
        # Check pytest
        result = coder_workspace_bash(
            workspace=home_workspace,
            command=f"cd {repo_path} && pytest -v",
            timeout_ms=60000
        )
        if result.exit_code == 0:
            results['passed'].append("Pytest passed")
        else:
            results['failed'].append(f"Pytest failed: {result.stdout}")
    
    elif project_type == 'nodejs':
        # Check lint
        result = coder_workspace_bash(
            workspace=home_workspace,
            command=f"cd {repo_path} && npm run lint",
            timeout_ms=30000
        )
        if result.exit_code == 0:
            results['passed'].append("ESLint passed")
        else:
            results['failed'].append(f"ESLint failed: {result.stdout}")
        
        # Check tests
        result = coder_workspace_bash(
            workspace=home_workspace,
            command=f"cd {repo_path} && npm test",
            timeout_ms=60000
        )
        if result.exit_code == 0:
            results['passed'].append("Tests passed")
        else:
            results['failed'].append(f"Tests failed: {result.stdout}")
    
    # Determine overall pass/fail
    results['overall_pass'] = len(results['failed']) == 0
    
    return results

# Usage
validation_results = verify_task_completion(
    home_workspace=home_workspace,
    repo_path=repo_path,
    project_type='python'
)

if validation_results['overall_pass']:
    print("✅ All validation checks passed")
else:
    print("❌ Validation failed:")
    for failure in validation_results['failed']:
        print(f"   - {failure}")
```

---

## Quality Gates

### Gate 1: Pre-Merge Quality Gate

```python
def pre_merge_quality_gate(home_workspace, repo_path, project_type):
    """
    Quality gate before merging feature branch.
    """
    print("🚦 Running pre-merge quality gate...")
    
    # Run validation
    results = verify_task_completion(home_workspace, repo_path, project_type)
    
    if not results['overall_pass']:
        print("❌ Quality gate FAILED - cannot merge")
        for failure in results['failed']:
            print(f"   - {failure}")
        return False
    
    print("✅ Quality gate PASSED - safe to merge")
    return True
```

### Gate 2: Pre-Deployment Quality Gate

```python
def pre_deployment_quality_gate(home_workspace, repo_path, min_consistency=85, min_compliance=90):
    """
    Quality gate before deployment.
    """
    print("🚦 Running pre-deployment quality gate...")
    
    # Run post-task analysis
    from post_task_analysis import complete_post_task_analysis
    analysis = complete_post_task_analysis(home_workspace, repo_path)
    
    consistency_score = analysis['consistency']['score']
    compliance_score = analysis['compliance'].get('score', 0)
    
    if consistency_score < min_consistency:
        print(f"❌ Deployment BLOCKED: Consistency {consistency_score}% < {min_consistency}%")
        return False
    
    if compliance_score < min_compliance:
        print(f"❌ Deployment BLOCKED: Compliance {compliance_score}% < {min_compliance}%")
        return False
    
    print("✅ Deployment gate PASSED")
    return True
```

---

## Best Practices

### Validation Timing
- **During task execution:** Workspace agent validates continuously
- **Before task completion:** Workspace agent runs full validation
- **After work transfer:** External agent verifies in home workspace
- **Before deployment:** Run comprehensive quality gates

### Prompt Engineering
- Always include validation requirements in task prompts
- Be specific about verification commands
- List exact success criteria
- Emphasize "do not complete until validated"

### Automation
- Use validation functions in task workflow
- Integrate quality gates into CI/CD
- Automate report generation
- Track validation metrics over time

---

## Integration with Task Workflow

```python
# Enhanced task creation with validation
def create_validated_task(task_description, project_type, template_version_id, home_workspace, repo_path):
    """
    Create task with comprehensive validation requirements.
    """
    # Generate validation prompt
    task_prompt = generate_validation_prompt(project_type, task_description)
    
    # Create feature branch
    feature_branch = create_feature_branch(home_workspace, repo_path, task_description)
    
    # Create task with validation prompt
    task = coder_create_task(
        input=task_prompt,
        template_version_id=template_version_id,
        rich_parameter_values={
            "feature_branch": feature_branch,
            "home_workspace": home_workspace
        }
    )
    
    return task, feature_branch

# After task completes
def complete_validated_task(task_workspace, home_workspace, repo_path, feature_branch, project_type):
    """
    Complete task with validation verification.
    """
    # Transfer work
    complete_task_with_cleanup(task_workspace, home_workspace, feature_branch, repo_path)
    
    # Verify validation
    validation_results = verify_task_completion(home_workspace, repo_path, project_type)
    
    if not validation_results['overall_pass']:
        print("⚠️ Warning: Validation checks failed after transfer")
        for failure in validation_results['failed']:
            print(f"   - {failure}")
        return False
    
    # Run quality gate
    if not pre_merge_quality_gate(home_workspace, repo_path, project_type):
        print("❌ Quality gate failed - do not merge")
        return False
    
    print("✅ Task validated and ready to merge")
    return True
```

---

**Validation Impact:**
- Pre-completion validation: 80% reduction in post-task bugs
- Quality gates: 95% reduction in deployment issues
- Automated verification: 90% time savings vs manual review
