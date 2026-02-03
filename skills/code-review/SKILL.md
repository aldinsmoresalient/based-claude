---
name: code-review
description: Risk-aware code review assistant. Use when reviewing PRs, diffs, or code changes. Focuses on correctness, security, performance, and maintainability. Identifies potential bugs, security issues, and architectural concerns before they reach production.
---

# Code Review Assistant

Perform thorough, risk-aware code reviews that catch issues before production.

## Review Framework

### 1. Risk Assessment (First Pass)

Before detailed review, assess overall risk:

```
RISK_LEVEL: low | medium | high | critical

RISK_FACTORS:
- [ ] Touches authentication/authorization
- [ ] Modifies financial/billing logic
- [ ] Changes database schema
- [ ] Affects public API
- [ ] Modifies security-critical code
- [ ] Large change (>500 lines)
- [ ] Unfamiliar code area
```

### 2. Correctness Review

```
CHECK: Logic correctness
CHECK: Edge case handling
CHECK: Error handling completeness
CHECK: Null/undefined safety
CHECK: Type safety
CHECK: Resource cleanup (connections, files, locks)
CHECK: Concurrent access safety
```

### 3. Security Review

```
SEC_CHECK: Input validation
SEC_CHECK: Output encoding
SEC_CHECK: Authentication checks
SEC_CHECK: Authorization checks
SEC_CHECK: SQL injection vectors
SEC_CHECK: XSS vectors
SEC_CHECK: Secrets in code
SEC_CHECK: Dependency vulnerabilities
```

### 4. Performance Review

```
PERF_CHECK: N+1 queries
PERF_CHECK: Unbounded loops
PERF_CHECK: Missing indexes
PERF_CHECK: Large allocations
PERF_CHECK: Blocking operations
PERF_CHECK: Cache considerations
```

### 5. Maintainability Review

```
MAINT_CHECK: Code clarity
MAINT_CHECK: Naming quality
MAINT_CHECK: Appropriate abstraction level
MAINT_CHECK: Test coverage
MAINT_CHECK: Documentation needs
```

## Output Format

```markdown
## Code Review: [PR/Change Title]

### Summary
[One-paragraph assessment]

### Risk Level: [low/medium/high/critical]

### Critical Issues (Must Fix)
1. **[Category]** File:line - Issue description
   - Why it matters
   - Suggested fix

### Important Issues (Should Fix)
1. ...

### Suggestions (Nice to Have)
1. ...

### Questions
1. [Questions for the author]

### Checklist
- [ ] Tests pass
- [ ] No security regressions
- [ ] Performance acceptable
- [ ] Documentation updated
- [ ] INVARIANTS.md respected
```

## Process

1. **Read the diff** completely before commenting
2. **Check INVARIANTS.md** for constraints
3. **Assess risk level** based on areas touched
4. **Review systematically** using framework above
5. **Prioritize feedback** - critical vs nice-to-have
6. **Be constructive** - suggest solutions, not just problems

## Guidelines

- Start with positive observations when genuine
- Focus on code, not coder
- Explain the "why" behind suggestions
- Provide code examples for complex suggestions
- Consider the author's context and constraints
- Ask questions before assuming mistakes

## Guardrails

- NEVER approve changes that violate INVARIANTS.md
- NEVER skip security review for auth/payment code
- Flag any credentials or secrets found in code
- Escalate high-risk changes for additional review
- Check if tests cover the changed behavior
