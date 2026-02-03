---
name: debugging-playbook
description: Systematic debugging assistant with proven playbooks. Use when investigating bugs, errors, unexpected behavior, or performance issues. Provides structured approaches to isolate root causes and verify fixes.
---

# Debugging Playbook

Systematic approaches to isolate and fix bugs efficiently.

## Debugging Framework

### Phase 1: Understand the Problem

```
BUG_REPORT:
SYMPTOM: [What is happening?]
EXPECTED: [What should happen?]
REPRO_STEPS: [How to reproduce]
FREQUENCY: [Always/Sometimes/Rare]
ENVIRONMENT: [Where does it occur?]
RECENT_CHANGES: [What changed recently?]
```

### Phase 2: Gather Evidence

```
GATHER: Error messages and stack traces
GATHER: Relevant logs (grep patterns below)
GATHER: State at time of failure
GATHER: User/input that triggered it
GATHER: Similar past issues (search history)
```

Useful grep patterns:
```bash
# Find errors in logs
grep -i "error\|exception\|fail" <logfile>

# Find related log entries by timestamp
grep "2024-01-15 10:3" <logfile>

# Find related code
grep -r "functionName" --include="*.ts"
```

### Phase 3: Form Hypotheses

List possible causes ranked by likelihood:

```
HYPOTHESIS: [H1] [Most likely cause]
EVIDENCE_FOR: [Supporting evidence]
EVIDENCE_AGAINST: [Contradicting evidence]
TEST: [How to verify/falsify]

HYPOTHESIS: [H2] [Next likely cause]
...
```

### Phase 4: Test Hypotheses

Test each hypothesis systematically:

```
TESTING: H1
METHOD: [How testing]
RESULT: [Confirmed/Rejected]
NOTES: [What learned]
```

### Phase 5: Implement Fix

```
ROOT_CAUSE: [Confirmed cause]
FIX: [Description of fix]
VERIFICATION: [How to verify fix works]
REGRESSION_CHECK: [Ensure no new issues]
```

## Common Debugging Playbooks

### Playbook: "It worked yesterday"

1. Check recent deployments/commits
2. Check configuration changes
3. Check external dependencies status
4. Check resource exhaustion (disk, memory)
5. Check certificate/token expiration

### Playbook: "Works locally, fails in prod"

1. Compare environment variables
2. Compare dependency versions
3. Check network/firewall rules
4. Check data differences
5. Check permission/credential differences

### Playbook: "Intermittent failure"

1. Check for race conditions
2. Check resource limits being hit
3. Check external service reliability
4. Check time-based triggers
5. Add logging/monitoring for pattern detection

### Playbook: "Performance degradation"

1. Check recent query changes
2. Check data volume growth
3. Check cache hit rates
4. Profile hot paths
5. Check for N+1 queries

### Playbook: "Memory leak"

1. Take heap snapshots over time
2. Look for growing collections
3. Check event listener cleanup
4. Check for circular references
5. Check for unclosed resources

## Output Format

```markdown
## Bug Investigation: [Title]

### Problem Statement
[Clear description of the bug]

### Reproduction
[Steps to reproduce]

### Investigation Log

#### Evidence Gathered
- [Evidence 1]
- [Evidence 2]

#### Hypotheses Tested
| Hypothesis | Result | Notes |
|------------|--------|-------|
| H1: ... | Rejected | ... |
| H2: ... | Confirmed | ... |

### Root Cause
[Explanation of what's actually wrong]

### Fix
[Description of the fix]

### Verification
- [ ] Bug no longer reproduces
- [ ] Tests added/updated
- [ ] No regressions introduced

### Prevention
[How to prevent similar bugs]
```

## Guidelines

- Don't guess - gather evidence
- Test one thing at a time
- Document your investigation (future you will thank you)
- Consider if the bug reveals a deeper issue
- After fixing, ask "what else could break this way?"

## Guardrails

- NEVER deploy untested fixes
- NEVER delete production data while debugging
- Create backups before attempting fixes
- Log investigation steps for postmortems
- Escalate if stuck after 3 hypothesis cycles
