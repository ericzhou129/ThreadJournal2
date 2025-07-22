# ThreadJournal2 - Claude Instructions

## Project Overview
ThreadJournal2 is a journaling iOS app built with SwiftUI and Clean Architecture. The app allows users to create multiple journal threads and add entries to them over time.

## Important Instructions for Future Development

### 1. Architecture Requirements
- **ALWAYS follow Clean Architecture principles**:
  - Domain layer: NO imports from UIKit, SwiftUI, or CoreData
  - Application layer: Imports Domain only, NO UI or persistence imports
  - Interface layer: Can import Application + Domain, NO persistence imports
  - Infrastructure layer: Imports Domain only, NO UI imports

### 2. Code Quality Standards
- Maximum line length: 100 characters
- Maximum file length: 200 lines
- Maximum method length: 15 lines
- Cyclomatic complexity: Maximum 5
- Single responsibility: Each use case has ONE public execute() method
- NO singletons - use constructor injection only

### 3. Testing Requirements
- Minimum 80% unit test coverage for new code
- Run architecture tests before committing
- Performance tests must pass: 100 threads/1000 entries
- All ViewModels must be testable with mocked dependencies

### 4. Development Workflow
- Branch naming: `feature/TICKET-XXX-brief-description`
- Conventional commits: `feat:`, `fix:`, `docs:`, etc.
- Always run SwiftLint before committing
- PR required before merge to main

### 5. UI/UX Standards
- Use system colors only (.label, .secondaryLabel, .systemBackground, etc.)
- Support Dynamic Type for all text
- Minimum touch targets: 44×44pt
- All text left-aligned (except buttons)
- Follow Design:v1.2 specifications exactly

### 6. Sprint Execution
When executing tickets:
1. Read the ticket requirements carefully
2. Check dependencies (some tickets can be done in parallel)
3. Reference technical and design artifacts
4. Run QA test criteria after implementation
5. Ensure all acceptance criteria are met
6. Mark ticket as complete only when fully done

### 7. Important Technical Details
- iOS 17+ minimum deployment target
- SwiftUI only (no UIKit)
- Core Data for persistence
- Manual dependency injection (no DI frameworks)
- Auto-save drafts every 30 seconds with 2-second debounce
- CSV export format: "Date & Time","Entry Content"

### 8. Current Sprint Status
Sprint 1 (Foundation) - COMPLETED:
- ✅ TICKET-001: Project Setup and Architecture
- ✅ TICKET-002: Core Data Schema Setup
- ✅ TICKET-003: Domain Entities and Repository
- ✅ TICKET-004: Core Data Repository Implementation
- ✅ TICKET-005: CreateThreadUseCase and AddEntryUseCase
- ✅ TICKET-006: Draft Manager Implementation
- ✅ TICKET-007: Thread List View Model
- ✅ TICKET-016: Architecture Tests

Sprint 2 (Core User Features) - COMPLETED:
- ✅ TICKET-008: Thread List UI Implementation
- ✅ TICKET-009: Create Thread UI
- ✅ TICKET-010: Thread Detail View Model
- ✅ TICKET-011: Thread Detail UI
- ✅ TICKET-012: Add Entry UI
- ✅ TICKET-013: Keyboard Enhancements

Next: Sprint 3 (Export & Polish) - Tickets 014-015, 017

### 9. Common Commands
```bash
# Run SwiftLint
swiftlint

# Run architecture tests
./run-architecture-tests.sh

# Run all tests
xcodebuild test -scheme ThreadJournal2 -destination 'platform=iOS Simulator,name=iPhone 15'
```

### 10. Key Files and Locations
- Technical specs: `Engineering/Technical-Implementation-Plan.md`
- Tickets: `Tickets/tickets.md`
- Design specs: `Design/DESIGN_REFERENCE_GUIDE.md`
- Architecture tests: `ThreadJournal2Tests/Architecture/`
- Domain layer: `ThreadJournal2/Domain/`
- Application layer: `ThreadJournal2/Application/`
- Interface layer: `ThreadJournal2/Interface/`
- Infrastructure layer: `ThreadJournal2/Infrastructure/`