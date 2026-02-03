---
name: spec-generator
description: Generate structured specifications and PRDs for features, systems, or changes. Use when the user needs to create a spec, PRD, technical design doc, RFC, or wants to formalize requirements before implementation. Helps ensure alignment before coding begins.
---

# Spec Generator

Generate clear, actionable specifications that align stakeholders before implementation.

## Output Formats

### Feature Spec (Default)

```markdown
# [Feature Name] Spec

## Summary
One paragraph explaining what and why.

## Goals
- Primary goal
- Secondary goals

## Non-Goals
- Explicitly out of scope

## User Stories
As a [user], I want [action] so that [benefit].

## Requirements

### Functional
REQ-F001: [Requirement]
REQ-F002: [Requirement]

### Non-Functional
REQ-N001: [Performance requirement]
REQ-N002: [Security requirement]

## Design

### Data Model
[Key entities and relationships]

### API Surface
[Endpoints or interfaces]

### UI/UX
[If applicable]

## Implementation Notes
- Key technical decisions
- Dependencies
- Migration considerations

## Open Questions
- [ ] Question 1
- [ ] Question 2

## Success Criteria
How we know this is done and working.
```

### Technical Design Doc

```markdown
# [System] Technical Design

## Context
Why this design is needed.

## Goals
What success looks like.

## Proposed Solution

### Architecture
[Diagram or description]

### Components
[Key components and responsibilities]

### Data Flow
[How data moves through the system]

## Alternatives Considered
| Option | Pros | Cons |
|--------|------|------|
| A | ... | ... |
| B | ... | ... |

## Security Considerations
[Threat model, mitigations]

## Rollout Plan
1. Phase 1
2. Phase 2

## Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
```

## Process

1. **Gather context**: Read relevant files, understand current state
2. **Clarify scope**: Ask what's in/out of scope
3. **Draft spec**: Use appropriate template
4. **Identify gaps**: List open questions
5. **Review**: Walk through with user

## Guidelines

- Specs should be grep-searchable (use consistent prefixes like REQ-F001)
- Keep specs in version control alongside code
- Link to related ADRs in DECISIONS.md
- Update spec when requirements change
- Spec is not implementation - avoid premature detail

## Guardrails

- Do NOT start implementation until spec is approved
- Do NOT include credentials or secrets
- Do NOT make assumptions - ask
- Check INVARIANTS.md for constraints that affect the design
