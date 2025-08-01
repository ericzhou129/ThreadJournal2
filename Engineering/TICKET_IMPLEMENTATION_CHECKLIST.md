# Ticket Implementation Checklist

## Before Starting a Ticket

- [ ] Read ticket completely, including:
  - [ ] Story description
  - [ ] Layer designation (domain/application/interface/infrastructure)
  - [ ] Acceptance criteria (ALL items)
  - [ ] QA test criteria
  - [ ] Design references (if any)
  - [ ] Dependencies

- [ ] Verify understanding:
  - [ ] Can I explain what the user will see/do?
  - [ ] Do I know which files to modify/create?
  - [ ] Is this the right architectural layer?

## During Implementation

- [ ] Working in correct layer?
  - [ ] Domain → `Domain/` directory only
  - [ ] Interface → `Interface/` directory only
  - [ ] No cross-layer imports

- [ ] Meeting acceptance criteria?
  - [ ] Check off each criterion as completed
  - [ ] If unclear, ask for clarification
  - [ ] Don't mark complete if ANY criteria missing

## Before Committing

- [ ] Run all tests
- [ ] Test acceptance criteria manually
- [ ] Run QA test criteria
- [ ] Verify no architecture violations
- [ ] Check file/line length limits

## Commit Message

```
feat/fix: [Brief description] (TICKET-XXX)

- List what was actually implemented
- Note any deviations from ticket
- Mention test coverage

Implements: TICKET-XXX
```

## Before Marking Complete

- [ ] ALL acceptance criteria met
- [ ] QA tests pass
- [ ] Code reviewed
- [ ] Tests written and passing
- [ ] No "TODO" comments related to ticket
- [ ] Documentation updated if needed

## Red Flags 🚩

Stop and reconsider if:
- Implementing UI in domain layer
- Creating domain entities for UI tickets  
- Can't test acceptance criteria
- Changing unrelated files
- Breaking existing tests
- Adding cross-layer dependencies

## Example Verification

For TICKET-003 (Show Custom Fields Button):
```
✅ Correct:
- Modified Interface/Views/ComposeBar.swift
- Added Button component
- Button shows/hides based on field count
- Positioned correctly in layout

❌ Wrong:
- Created Domain/Entities/CustomField.swift
- No UI components added
- No button visibility logic
- Wrong architectural layer
```