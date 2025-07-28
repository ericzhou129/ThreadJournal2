# ThreadJournal Tickets

## Overview
This document provides tickets for implementing ThreadJournal. All Claude Code agents must follow these criteria. 

## Architecture Alignment
From the TIP, we have these bounded contexts and layers:
- **Contexts**: Journaling Context, Export Context, Settings Context (Phase 2)
- **Layers**: domain/, application/, interface/, infrastructure/

---

## Definition of Done (Applies to All Tickets)

For a ticket to be considered "Done", ALL of the following must be satisfied:

### Code Complete
- [ ] All acceptance criteria met
- [ ] Code follows Clean Architecture principles
- [ ] SwiftLint passes with no warnings
- [ ] Architecture tests pass
- [ ] No hardcoded values or magic numbers

### Testing
- [ ] Unit tests written and passing (80% minimum coverage)
- [ ] QA test criteria verified
- [ ] Manual testing on iPhone simulator
- [ ] No memory leaks (verified with Instruments)

### Documentation
- [ ] Code comments for complex logic only
- [ ] Public APIs documented
- [ ] README updated if needed
- [ ] Component references match design files

### Review & Merge
- [ ] Code reviewed by at least one team member
- [ ] PR description references ticket number
- [ ] CI pipeline passes (all tests green)
- [ ] Merged to main via squash commit
- [ ] Ticket marked as Done in project board

### Git Workflow
- Branch naming: `feature/TICKET-XXX-brief-description`
- Commit messages: Conventional commits (feat:, fix:, docs:, etc.)
- PR title: `TICKET-XXX: Brief description`

---

## Spaghetti-Risk Checklist

### Architecture Enforcement
✓ **SwiftLint Rules**: Custom rules prevent domain importing UI/Infrastructure
✓ **Layer Boundaries**: Each ticket tagged with single layer
✓ **Architecture Tests**: TICKET-016 ensures ongoing compliance
✓ **Single Responsibility**: Each use case has one public method
✓ **Dependency Injection**: All tickets use constructor injection

### Code Quality Gates
✓ **Line Length**: Max 100 characters
✓ **File Length**: Max 200 lines
✓ **Method Length**: Max 15 lines
✓ **Cyclomatic Complexity**: Max 5
✓ **Test Coverage**: Minimum 80% for new code

### CI/CD Pipeline
✓ **Pre-commit**: SwiftLint runs locally
✓ **PR Checks**: Architecture tests must pass
✓ **Coverage Gate**: No merge if coverage drops
✓ **Performance Tests**: Validate 100 threads/1000 entries

### Future-Proofing
✓ **Repository Pattern**: Easy to swap storage
✓ **Export Protocol**: Simple to add JSON later
✓ **Schema Versioning**: Migrations supported
✓ **Clean Architecture**: New features don't break existing

---

