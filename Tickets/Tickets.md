# ThreadJournal Tickets - Phase 1

## Overview
This document provides comprehensive tickets for implementing ThreadJournal. All Claude Code agents must follow these criteria. 

## Architecture Alignment
From the TIP, we have these bounded contexts and layers:
- **Contexts**: Journaling Context, Export Context, Settings Context (Phase 2)
- **Layers**: domain/, application/, interface/, infrastructure/

---

## Epic 1: Core Infrastructure Setup

### TICKET-001: Project Setup and Architecture
**Story ID**: TICKET-001  
**Context/Layer**: All / infrastructure  
**As a** developer  
**I want** the Xcode project configured with Clean Architecture folders  
**So that** the codebase maintains clear boundaries from the start  

**Acceptance Criteria**:
- Given existing Xcode project at `ThreadJournal2.xcodeproj`
- When I open the project structure
- Then I see folders: Domain/, Application/, Interface/, Infrastructure/
- And git repository is initialized with .gitignore for Swift
- [Arch-Lint] SwiftLint configured with rules from TIP Section 3
- [Coverage] GitHub Actions CI pipeline configured (.github/workflows/ci.yml)
- [Doc] README with architecture overview created

**Git Workflow**:
- Branch naming: `feature/TICKET-001-project-setup`
- Commit message: "feat: Setup Clean Architecture folders and CI"
- PR required before merge to main

**QA Test Criteria**:
1. Verify folder structure matches TIP Section 3
2. Run `swiftlint` and verify no violations
3. Push to branch and verify CI pipeline runs
4. Verify .gitignore excludes xcuserdata/, .DS_Store, etc.

**Priority Score**: 10 (WSJF) - Foundational, blocks all other work  
**Dependencies**: None  



### TICKET-002: Core Data Schema Setup
**Story ID**: TICKET-002  
**Context/Layer**: Journaling / infrastructure  
**As a** developer  
**I want** Core Data models for Thread and Entry with versioning  
**So that** we can store journal data with future migration support  

**Acceptance Criteria**:
- Given Core Data schema from TIP Section 2 "Entity-Relationship Diagram"
- When I create `Infrastructure/Persistence/ThreadDataModel.xcdatamodeld`
- Then Thread entity has: id (UUID), title (String), createdAt (Date), updatedAt (Date)
- And Entry entity has: id (UUID), threadId (UUID), content (String), timestamp (Date)
- And model includes version identifier "1.0"
- [Arch-Lint] Models in Infrastructure layer only
- [Coverage] 100% model coverage
- [Doc] Core Data model documented

**Technical Reference**:
- Schema location: `Infrastructure/Persistence/ThreadDataModel.xcdatamodeld`
- See TIP Section 2 for complete ERD
- Thread has one-to-many relationship with Entry

**QA Test Criteria**:
1. Verify Core Data model matches ERD exactly
2. Test creating Thread with 1000 entries (performance)
3. Verify cascade delete (deleting thread deletes entries)
4. Test migration by changing version to "1.1"

**Priority Score**: 9 (WSJF) - Critical path, enables persistence  
**Dependencies**: TICKET-001




### TICKET-003: Domain Entities and Repository
**Story ID**: TICKET-003  
**Context/Layer**: Journaling / domain  
**As a** developer  
**I want** domain entities and repository protocols  
**So that** business logic remains independent of infrastructure  

**Acceptance Criteria**:
- Given domain layer setup from TIP Section 2
- When I create `Domain/Entities/Thread.swift` and `Domain/Entities/Entry.swift`
- Then they contain only business data, no Core Data dependencies
- And `Domain/Repositories/ThreadRepository.swift` protocol defined
- [Arch-Lint] No imports from UIKit, SwiftUI, or CoreData
- [Coverage] 100% unit test coverage
- [Doc] Repository contract documented

**Technical Reference**:
- Thread entity: id (UUID), title (String), createdAt (Date), updatedAt (Date)
- Entry entity: id (UUID), threadId (UUID), content (String), timestamp (Date)
- Repository protocol from TIP Section 6 "Internal API Contracts"

**QA Test Criteria**:
1. Run architecture test to verify no UI/Infrastructure imports
2. Verify Thread.title validation (not empty)
3. Verify Entry.content validation (not empty)
4. Mock repository and test all protocol methods

**Priority Score**: 9 (WSJF) - Foundation for all features  
**Dependencies**: TICKET-001  

### TICKET-004: Core Data Repository Implementation
**Story ID**: TICKET-004  
**Context/Layer**: Journaling / infrastructure  
**As a** developer  
**I want** CoreDataThreadRepository implementing ThreadRepository  
**So that** we can persist threads and entries  

**Acceptance Criteria**:
- Given ThreadRepository protocol from TICKET-003 and Core Data models from TICKET-002
- When I implement `Infrastructure/Persistence/CoreDataThreadRepository.swift`
- Then all CRUD operations work correctly
- And error handling includes:
  - PersistenceError.saveFailed with retry logic (3 attempts)
  - ValidationError.emptyTitle, ValidationError.emptyContent
  - NotFoundError for fetch operations
- [Arch-Lint] Implementation in infrastructure layer only
- [Coverage] 80% test coverage with mocked Core Data
- [Doc] Error cases documented

**Error Handling Details**:
```swift
enum PersistenceError: Error {
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case notFound(id: UUID)
}
```

**QA Test Criteria**:
1. Test save failure with retry (mock Core Data save to fail twice)
2. Verify empty title/content throws ValidationError
3. Test concurrent access (create 10 threads simultaneously)
4. Verify fetch with non-existent ID throws NotFoundError

**Priority Score**: 8 (WSJF) - Critical for persistence  
**Dependencies**: TICKET-002, TICKET-003  

### TICKET-005: CreateThreadUseCase and AddEntryUseCase Implementation
**Story ID**: TICKET-005  
**Context/Layer**: Journaling / domain  
**As a** developer  
**I want** CreateThreadUseCase and AddEntryUseCase  
**So that** the app can create threads and add entries  

**Acceptance Criteria**:
- Given repository protocol from TICKET-003
- When I create classes implementing protocols from TIP Section 6:
  - `Domain/UseCases/CreateThreadUseCase.swift`
  - `Domain/UseCases/AddEntryUseCase.swift`
- Then CreateThreadUseCase validates title not empty and creates thread
- And AddEntryUseCase validates content not empty and adds entry
- And both set timestamps (createdAt, updatedAt) correctly
- [Arch-Lint] Single execute method per use case
- [Coverage] 100% unit test coverage
- [Doc] Business rules documented

**Implementation Guide**:
```swift
// CreateThreadUseCase
final class CreateThreadUseCase {
    func execute(title: String, firstEntry: String?) async throws -> Thread {
        // 1. Validate title not empty
        // 2. Create Thread with UUID, timestamps
        // 3. If firstEntry provided, create Entry
        // 4. Call repository.create(thread)
    }
}
```

**QA Test Criteria**:
1. Test empty title throws ValidationError
2. Test thread created with current timestamp
3. Test optional first entry is added if provided
4. Mock repository to verify correct calls

**Priority Score**: 8 (WSJF) - Core business logic  
**Dependencies**: TICKET-003  

### TICKET-006: Draft Manager Implementation
**Story ID**: TICKET-006  
**Context/Layer**: Journaling / application  
**As a** developer  
**I want** InMemoryDraftManager for auto-saving drafts  
**So that** users don't lose their work if save fails  

**Acceptance Criteria**:
- Given DraftManager protocol from TIP Section 14
- When implementing `Application/DraftManager/InMemoryDraftManager.swift`
- Then drafts are saved every 30 seconds while typing (with debouncing)
- And drafts persist in memory until successfully saved
- And retry mechanism triggers on save failure
- [Arch-Lint] No UI dependencies
- [Coverage] 90% test coverage including timer logic
- [Doc] Draft lifecycle documented

**Implementation Details**:
```swift
protocol DraftManager {
    func saveDraft(_ content: String, for threadId: UUID)
    func getDraft(for threadId: UUID) -> String?
    func clearDraft(for threadId: UUID)
}
```
- Use Timer with 30 second interval
- Debounce rapid changes (wait 2 seconds after last keystroke)

**QA Test Criteria**:
1. Verify draft saves after 30 seconds of typing
2. Test draft persists if app backgrounds (but not force quit)
3. Verify draft cleared after successful entry save
4. Test debouncing (rapid typing doesn't trigger multiple saves)

**Priority Score**: 7 (WSJF) - Important for UX  
**Dependencies**: TICKET-001  

---

## Epic 2: Thread Management (User Features)

### TICKET-007: Thread List View Model
**Story ID**: TICKET-007  
**Context/Layer**: Journaling / application  
**As a** developer  
**I want** ThreadListViewModel implementation  
**So that** the UI can display and manage threads  

**Acceptance Criteria**:
- Given use cases and repository
- When implementing ThreadListViewModel
- Then it loads all threads sorted by lastUpdated
- And provides createThread method
- And handles loading states and errors
- [Arch-Lint] ViewModel in application layer
- [Coverage] 80% test coverage
- [Doc] State management documented

**Priority Score**: 8 (WSJF) - Enables thread list UI  
**Dependencies**: TICKET-005  

### TICKET-008: Ability to see all threads
**Story ID**: TICKET-008  
**Context/Layer**: Journaling / interface  
**As a** user  
**I am able to** see all my journal threads in a single list view  
**So that** I can quickly access any thread I want to continue or read  

**Acceptance Criteria**:
1. Thread list displays all threads with title prominently shown (16pt semibold font with Dynamic Type)
2. Each thread card shows metadata: number of entries and when it was last updated (e.g., "3 entries • Updated 2 hours ago")
3. Threads ordered by most recently updated first
4. Thread cards tappable to navigate to ThreadDetailScreen (TICKET-011)
5. Thread cards have subtle visual feedback on tap (scale to 0.95 with spring animation)
6. Floating "+" button visible in bottom right corner - tapping navigates to NewThreadScreen (TICKET-009)
- [Arch-Lint] SwiftUI view uses ViewModel for all logic
- [Coverage] UI test for navigation flow
- [Doc] Component matches Design:v1.2/Screen/ThreadList

**Component Reference**:
- Design:v1.2/Screen/ThreadList
- Design:v1.2/ThreadListItem
- Design:v1.2/FAB

**Technical Implementation**:
- Create `Interface/Screens/ThreadListScreen.swift`
- Use `@StateObject var viewModel: ThreadListViewModel`
- Dynamic Type: `@ScaledMetric(relativeTo: .callout) var titleSize = 16`
- NavigationLink to ThreadDetailScreen passing threadId
- "+" button presents NewThreadScreen as sheet
- Empty state: "No threads yet. Tap + to create your first thread."

**QA Test Criteria**:
1. Verify all threads display with correct metadata
2. Test Dynamic Type scaling (Settings > Accessibility > Larger Text)
3. Test navigation to ThreadDetailScreen on tap
4. Test "+" button presents NewThreadScreen
5. Verify empty state when no threads
6. End-to-end: Create thread via "+" and verify it appears in list

**Priority Score**: 9 (WSJF) - Primary user interface  
**Dependencies**: TICKET-007  

### TICKET-009: Ability to add a new thread
**Story ID**: TICKET-009  
**Context/Layer**: Journaling / interface  
**As a** user  
**I am able to** create a new thread by tapping the floating "+" button and entering a thread title  
**So that** I can start journaling about a new topic  

**Acceptance Criteria**:
1. Tapping "+" button on ThreadListScreen (from TICKET-008) presents new thread creation screen
2. Screen has "X" button in top left to cancel creation
3. Large text input field at top for thread title (28pt bold with Dynamic Type)
4. Placeholder text reads "Name your thread..."
5. Compose area at bottom available to immediately add first entry
6. Create button disabled until thread title is entered
7. After creating thread with title and optional first entry, user taken to ThreadDetailScreen
8. New thread appears at top of thread list (most recent)
- [Arch-Lint] Creation logic via ViewModel only
- [Coverage] UI test for creation flow
- [Doc] Component matches Design:v1.2/Screen/NewThread

**Note**: This creates a NEW thread, different from TICKET-012 which adds entries to EXISTING threads.

**Component Reference**:
- Design:v1.2/FAB
- Design:v1.2/Screen/NewThread
- Design:v1.2/ThreadTitleInput
- Design:v1.2/ComposeArea

**QA Test Criteria**:
1. Test "+" button from ThreadListScreen opens this screen
2. Test "X" button dismisses without saving
3. Verify create button disabled when title empty
4. Test Dynamic Type for title input (28pt scales properly)
5. End-to-end: Create thread with title and first entry, verify navigation to detail
6. Verify new thread appears at top of list when returning

**Priority Score**: 9 (WSJF) - Core user flow  
**Dependencies**: TICKET-008  

---

## Epic 3: Entry Management (User Features)

### TICKET-010: Thread Detail View Model
**Story ID**: TICKET-010  
**Context/Layer**: Journaling / application  
**As a** developer  
**I want** ThreadDetailViewModel with draft support  
**So that** the UI can display thread and handle entry creation  

**Acceptance Criteria**:
- Given AddEntryUseCase from TICKET-005 and DraftManager from TICKET-006
- When implementing `Application/ViewModels/ThreadDetailViewModel.swift`
- Then it loads thread with all entries chronologically
- And manages draft with auto-save every 30 seconds (via DraftManager)
- And shows retry button on save failure with 3 retry attempts
- And provides shouldScrollToLatest flag for UI
- [Arch-Lint] ViewModel in application layer
- [Coverage] 80% test coverage including draft logic
- [Doc] Draft state machine documented

**Implementation Details**:
- See TIP Section 6 for ThreadDetailViewModelProtocol
- Draft states: empty, typing, saving, saved, failed
- Properties: thread, entries, draftContent, isSavingDraft, hasFailedSave

**QA Test Criteria**:
1. Test loads thread and all entries
2. Test draft auto-saves after 30 seconds
3. Test retry appears on save failure
4. Verify draft persists during save attempts

**Priority Score**: 8 (WSJF) - Enables entry features  
**Dependencies**: TICKET-005, TICKET-006  

### TICKET-011: Ability to see all entries in a thread
**Story ID**: TICKET-011  
**Context/Layer**: Journaling / interface  
**As a** user  
**I am able to** view all entries in a thread in chronological order on ThreadDetailScreen  
**So that** I can follow my journey of thoughts over time  

**Acceptance Criteria**:
1. Thread title displayed at top of screen (20pt bold with Dynamic Type)
2. Entries listed chronologically with oldest at top and newest at bottom
3. Each entry shows timestamp (11pt medium with Dynamic Type, secondary color) above content
4. Entry content displayed in 14pt regular font with Dynamic Type and proper line spacing
5. Entries separated by subtle dividers except for last entry
6. View automatically scrolls to latest entry when thread opened
7. Three-dot menu button in header shows "Export as CSV" option (implemented in TICKET-015)
- [Arch-Lint] View uses ViewModel for all data and logic
- [Coverage] UI test for scroll behavior
- [Doc] Component matches Design:v1.2/Screen/ThreadDetail

**Component Reference**:
- Design:v1.2/Screen/ThreadDetail
- Design:v1.2/ThreadEntry
- Design:v1.2/MenuButton

**QA Test Criteria**:
1. Navigate from ThreadListScreen and verify correct thread loads
2. Test Dynamic Type for all text (title, timestamps, content)
3. Verify chronological order (oldest to newest)
4. Test auto-scroll to bottom on load
5. Verify menu shows "Export as CSV" (may be disabled until TICKET-015)
6. Test with 0, 1, and 1000 entries

**Priority Score**: 9 (WSJF) - Core viewing experience  
**Dependencies**: TICKET-010  

### TICKET-012: Ability to add a new entry to a thread
**Story ID**: TICKET-012  
**Context/Layer**: Journaling / interface  
**As a** user  
**I am able to** add a new entry to an EXISTING thread using the compose area on ThreadDetailScreen  
**So that** I can continue journaling my thoughts  

**Acceptance Criteria**:
1. Compose area fixed at bottom of ThreadDetailScreen with text input field
2. Text input has placeholder text "Add to journal..."
3. Send button (arrow icon) visible next to input field
4. Send button disabled (50% opacity) when input empty
5. When typing begins, view scrolls to show latest entry above keyboard
6. After sending, new entry appears at bottom of thread with current timestamp
7. Input field clears after successful submission
8. Compose area remains accessible above keyboard when typing
- [Arch-Lint] Draft auto-save every 5 seconds via ViewModel
- [Coverage] UI test for keyboard handling and draft recovery
- [Doc] Component matches Design:v1.2/ComposeArea

**Component Reference**:
- Design:v1.2/ComposeArea
- Design:v1.2/SendButton
- Design:v1.2/Screen/ThreadDetail

**Note**: This adds entries to EXISTING threads (different from TICKET-009 which creates NEW threads)

**QA Test Criteria**:
1. Test on ThreadDetailScreen with existing thread
2. Verify send button disabled when empty
3. Test keyboard avoidance (compose area stays visible)
4. Verify draft auto-saves every 30 seconds while typing
5. Test retry button appears on save failure
6. End-to-end: Add entry and verify it appears at bottom with timestamp

**Priority Score**: 9 (WSJF) - Core creation functionality  
**Dependencies**: TICKET-011  

### TICKET-013: Keyboard entry view enhancements
**Story ID**: TICKET-013  
**Context/Layer**: Journaling / interface  
**As a** user  
**I am able to** expand the entry textbox for focused writing  
**So that** I can have max space to focus on what I'm writing  

**Acceptance Criteria**:
1. Little expand icon in keyboard entry area that user can click
2. Clicking expand icon makes textbox expand to full screen
3. Default shows few lines so user can see other entries while typing
4. When typing, automatically scroll to bottom with latest entry
5. Latest entry moves up as keyboard pops up
6. As user enters text, textbox increases in size until half of screen
7. Enter key creates new line instead of dismissing keyboard
8. Text editor resets to minimum height after sending entry
9. Placeholder text 'Add to journal...' appears when text field is empty
- [Arch-Lint] Expansion state managed by ViewModel
- [Coverage] UI test for all expansion states
- [Doc] Component matches Design:v1.2/ComposeArea keyboard states

**Technical Implementation**:
- Add expand button to ComposeArea component
- State: `@State private var isExpanded = false`
- Use `.sheet` or `.fullScreenCover` for expanded mode
- TextEditor with dynamic height:
  - Min height: 44pt (3 lines)
  - Max height: 50% of screen or fullscreen if expanded
  - Font size: 16pt for better readability
- Use GeometryReader for height calculations
- Use NSLayoutManager for accurate text height calculation
- Smooth animation (0.2s ease-in-out) when height changes
- `.scrollDismissesKeyboard(.interactively)`
- Auto-scroll in parent when text changes
- Changed from TextField to TextEditor for multi-line support

**Component Reference**:
- Design:v1.2/ComposeArea
- Design:v1.2/Screen/ThreadDetail

**QA Test Criteria**:
1. Test expand button toggles fullscreen mode
2. Verify default height is 3 lines (44pt)
3. Test textbox grows to 50% screen max
4. Verify fullscreen mode covers entire screen
5. Test keyboard dismiss behavior
6. Verify content preserved when toggling modes
7. Test Enter key adds new line (doesn't dismiss keyboard)
8. Test text editor height resets after sending
9. Test placeholder text visibility when empty
10. Test text wrapping and line breaks

**Priority Score**: 7 (WSJF) - Enhancement for power users  
**Dependencies**: TICKET-012  

---

## Epic 4: Export Functionality

### TICKET-014: Export Use Case and CSV Implementation
**Story ID**: TICKET-014  
**Context/Layer**: Export / domain + infrastructure  
**As a** developer  
**I want** ExportThreadUseCase with CSV exporter  
**So that** users can export their journal data  

**Acceptance Criteria**:
- Given thread repository from TICKET-003
- When implementing export functionality:
  - `Domain/UseCases/ExportThreadUseCase.swift`
  - `Infrastructure/Export/CSVExporter.swift`
- Then ExportThreadUseCase returns ExportData protocol (TIP Section 6)
- And CSVExporter generates proper CSV format:
  - Headers: "Date & Time","Entry Content"
  - Quotes escaped by doubling (" becomes "")
  - Content wrapped in quotes if contains comma/newline
- And filename format: ThreadName_YYYYMMDD_HHMM.csv
- [Arch-Lint] Use case in domain, exporter in infrastructure
- [Coverage] 90% test coverage with edge cases
- [Doc] Export format documented for future formats

**CSV Format Example**:
```csv
"Date & Time","Entry Content"
"2024-01-15 10:30","Started my journal today"
"2024-01-15 14:45","Had a thought with a comma, here"
"2024-01-15 16:20","Quote test: She said ""Hello"" to me"
```

**QA Test Criteria**:
1. Test export with special characters (quotes, commas, newlines)
2. Verify CSV opens correctly in Excel/Numbers
3. Test thread name with special characters in filename
4. Test empty thread export
5. Performance test with 1000 entries

**Priority Score**: 6 (WSJF) - Important but not blocking  
**Dependencies**: TICKET-003  

### TICKET-015: Export any thread to CSV
**Story ID**: TICKET-015  
**Context/Layer**: Export / interface  
**As a** user  
**I want the ability to** export each thread of my journal to CSV  
**So that** I can analyze this data in other ways  

**Acceptance Criteria**:
1. Three-dot menu on ThreadDetailScreen shows "Export as CSV" option
2. CSV contains columns: "Date & Time", "Entry Content" 
3. CSV named ThreadName_YYYYMMDD_HHMM.csv (sanitized for filesystem)
4. When export selected, iOS share sheet shown with save/send options
5. Loading indicator shown during export
6. Error alert if export fails
- [Arch-Lint] Export triggered via ViewModel.exportToCSV()
- [Coverage] UI test for share sheet presentation
- [Doc] Component matches Design:v1.2/ExportMenu

**Component Reference**:
- Design:v1.2/ExportMenu
- Design:v1.2/Screen/ThreadDetail

**Technical Implementation**:
- Add to menu in ThreadDetailScreen header
- Call `viewModel.exportToCSV()` which uses ExportThreadUseCase
- Present UIActivityViewController with CSV file URL
- Handle loading state during export

**QA Test Criteria**:
1. Test menu shows "Export as CSV" option
2. Verify share sheet appears with CSV file
3. Test "Save to Files" saves correct CSV
4. Test email attachment includes CSV
5. Verify filename sanitization (remove /, :, etc.)
6. Test export with 0 entries shows appropriate message

**Priority Score**: 7 (WSJF) - User-requested feature  
**Dependencies**: TICKET-011, TICKET-014  

---

## Epic 5: Architecture & Quality

### TICKET-016: Architecture Tests
**Story ID**: TICKET-016  
**Context/Layer**: All / infrastructure  
**As a** developer  
**I want** automated architecture tests  
**So that** Clean Architecture boundaries are enforced  

**Acceptance Criteria**:
- Given test suite in `ThreadJournal2Tests/Architecture/`
- When running architecture tests
- Then verify domain layer has no imports from UIKit, SwiftUI, or CoreData
- And verify use cases have single public execute() method
- And verify dependency rules from TIP Section 3:
  - Domain imports nothing
  - Application imports Domain only
  - Interface imports Application + Domain
  - Infrastructure imports Domain only
- [Arch-Lint] Tests fail CI build on violation
- [Coverage] All layers tested
- [Doc] Architecture rules documented

**Test Implementation**:
```swift
func testDomainHasNoUIImports() {
    let domainFiles = FileScanner.scan("Domain/")
    for file in domainFiles {
        XCTAssertFalse(file.contains("import UIKit"))
        XCTAssertFalse(file.contains("import SwiftUI"))
        XCTAssertFalse(file.contains("import CoreData"))
    }
}
```

**QA Test Criteria**:
1. Add violating import to domain layer, verify test fails
2. Add second public method to use case, verify test fails
3. Import Infrastructure from Domain, verify test fails
4. Run in CI pipeline, verify blocks merge on failure

**Priority Score**: 7 (WSJF) - Prevents technical debt  
**Dependencies**: TICKET-001  

### TICKET-017: Performance Tests
**Story ID**: TICKET-017  
**Context/Layer**: All / infrastructure  
**As a** developer  
**I want** performance tests for 100 threads/1000 entries  
**So that** we validate our performance assumptions  

**Acceptance Criteria**:
- Given performance test suite in `ThreadJournal2Tests/Performance/`
- When testing with 100 threads, 1000 entries each
- Then thread list loads < 200ms
- And thread detail loads < 300ms
- And entry creation < 50ms
- And CSV export of 1000 entries < 3s
- [Arch-Lint] Test data builders follow factory pattern
- [Coverage] Critical user paths tested
- [Doc] Performance benchmarks documented

**Test Setup**:
```swift
func testThreadListPerformanceWith100Threads() {
    // Given: 100 threads with varying entry counts
    let threads = TestDataBuilder.createThreads(count: 100)
    
    measure {
        // When: Loading thread list
        viewModel.loadThreads()
        // Then: Should complete < 200ms
    }
}
```

**QA Test Criteria**:
1. Run test with 100 threads, verify < 200ms
2. Run test with 1000 entries per thread, verify < 300ms load
3. Test on oldest supported device (iPhone SE)
4. Monitor memory usage stays < 150MB
5. Verify no memory leaks with Instruments

**Priority Score**: 5 (WSJF) - Important for validation  
**Dependencies**: TICKET-004  

---

## Epic 5: Entry Management

### TICKET-018: Long Press Context Menu for Entries
**Story ID**: TICKET-018  
**Context/Layer**: Journaling / interface  

THIS TICKET IS DEPRECIATED AND REMOVED FROM IMPLEMENTATION. 

**As a** user  
**I want to** long press on any entry to see edit and delete options  
**So that** I can manage my journal entries after they've been posted  

**Acceptance Criteria**:
1. Long press gesture (0.5 seconds) on any entry shows context menu
2. Context menu appears with two options: "Edit" and "Delete"
3. Menu has iOS-native appearance with SF Symbol icons
4. Edit option has pencil icon (SF Symbol: pencil)
5. Delete option has trash icon (SF Symbol: trash) in red
6. Tapping outside menu dismisses it
7. Visual feedback (haptic + slight scale) when long press detected
8. Menu positioned above/below entry based on screen position
- [Arch-Lint] Long press state managed by View, actions delegated to ViewModel
- [Coverage] UI test for long press gesture and menu appearance
- [Doc] Component matches Design:v1.2/EntryContextMenu

**Component Reference**:
- Design:v1.2/EntryContextMenu
- Design:v1.2/ThreadEntry (base component)

**Technical Reference**:
- ViewModel methods from TIP Section 6 (API Contracts)
- View implementation pattern from TIP Section 3 (Clean Architecture)

**Technical Implementation**:
- Use `.contextMenu` modifier on entry view
- Add to entryView in ThreadDetailViewFixed:
  ```swift
  .contextMenu {
      Button(action: { viewModel.startEditingEntry(entry) }) {
          Label("Edit", systemImage: "pencil")
      }
      Button(role: .destructive, action: { viewModel.confirmDeleteEntry(entry) }) {
          Label("Delete", systemImage: "trash")
      }
  }
  ```
- Add haptic feedback: `UIImpactFeedbackGenerator(style: .medium)`
- ViewModel methods: `startEditingEntry(_:)`, `confirmDeleteEntry(_:)`
- Note: TICKET-021 adds swipe actions as an alternative interaction method

**QA Test Criteria**:
1. Test long press shows menu within 0.5 seconds
2. Verify both Edit and Delete options appear
3. Test haptic feedback triggers on long press
4. Verify menu dismisses when tapping outside
5. Test menu positioning near screen edges
6. Verify delete option appears in red
7. Test on both iPhone and iPad

**Priority Score**: 6 (WSJF) - Important UX enhancement  
**Dependencies**: TICKET-011 (Thread Detail UI)

### TICKET-019: Edit Entry Mode Implementation
**Story ID**: TICKET-019  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want to** edit an existing entry's content and save changes  
**So that** I can correct mistakes or update my thoughts  

**Acceptance Criteria**:
1. Tapping "Edit" from menu button enters edit mode for that entry
2. Entry content becomes editable TextEditor with existing text
3. TextEditor automatically sizes to fit content height (no internal scrolling)
4. Entry timestamp remains visible above the edit box
5. Save and Cancel buttons appear below the edit area, right-aligned
6. Original entry view replaced with edit UI inline
7. Other entries remain visible but dimmed (50% opacity)
8. Keyboard appears automatically when entering edit mode
9. Save button disabled if content unchanged or empty
10. After saving, entry shows with "(edited)" next to timestamp
11. Escape/swipe down cancels edit without saving
- [Arch-Lint] Edit state managed by ViewModel with original content backup
- [Coverage] Test edit/save/cancel flows with state verification
- [Doc] Component matches Design:v1.2/EditMode (revised)

**Component Reference**:
- Design:v1.2/EditMode (revised)
- Design:v1.2/ComposeArea (reuse styling)
- Reference: `/Design/edit-mode-final-design.html`

**Technical Reference**:
- UpdateEntryUseCase from TIP Section 6 (API Contracts)
- Edit entry data flow from TIP Section 7 (Data Flow)
- ViewModel edit methods from TIP Section 6

**Technical Implementation**:
- Add to ThreadDetailViewModel:
  ```swift
  @Published var editingEntry: Entry?
  @Published var editingContent: String = ""
  @Published var isEditFieldFocused = false
  
  func startEditingEntry(_ entry: Entry) {
      editingEntry = entry
      editingContent = entry.content
      isEditFieldFocused = true
  }
  
  func saveEditedEntry() async {
      // Update entry via repository
  }
  
  func cancelEditing() {
      editingEntry = nil
      editingContent = ""
      isEditFieldFocused = false
  }
  ```
- Edit mode UI structure:
  ```swift
  VStack(alignment: .leading, spacing: 8) {
      // 1. Timestamp remains visible
      Text(formatTimestamp(entry.timestamp))
          .font(.system(size: 11, weight: .medium))
          .foregroundColor(Color(.secondaryLabel))
      
      // 2. Edit box with blue border
      TextEditor(text: $viewModel.editedContent)
          .scrollDisabled(true)  // No internal scrolling
          .background(Color(.systemGray6))
          .overlay(RoundedRectangle(cornerRadius: 8)
              .stroke(Color.accentColor, lineWidth: 2))
      
      // 3. Buttons below, right-aligned
      HStack {
          Spacer()
          Button("Cancel") { viewModel.cancelEditing() }
              .font(.system(size: 16, weight: .medium))
          Button("Save") { await viewModel.saveEditedEntry() }
              .font(.system(size: 16, weight: .semibold))
      }
  }
  ```
- Use TextEditor with `.scrollDisabled(true)` for no internal scrolling
- Expand to fit content using ZStack sizing technique
- Add UpdateEntryUseCase to domain layer
- Track edit history in Entry entity (optional for v1)

**Component Reference**:
- Reuse styling from Design:v1.2/ComposeArea
- Button styling from existing Send button

**QA Test Criteria**:
1. Test edit mode replaces entry inline
2. Verify TextEditor shows full content without internal scrolling
3. Test TextEditor height adjusts when adding/removing lines
4. Verify keyboard appears automatically
5. Test Save button enables only when content changes
6. Verify Cancel restores original content
7. Test "(edited)" indicator appears after save
8. Verify other entries dim during edit
9. Test concurrent edits not allowed
10. Test edit mode survives rotation (iPad)
11. Verify edit changes persist after app restart

**Priority Score**: 5 (WSJF) - Valuable but not critical path  
**Dependencies**: TICKET-018 (Context Menu)

### TICKET-020: Delete Entry Implementation (Soft Delete)
**Story ID**: TICKET-020  
**Context/Layer**: Journaling / domain + infrastructure + interface  
**As a** user  
**I want to** delete journal entries I no longer want to see  
**So that** I can hide mistaken or unwanted entries from my journal (with ability to recover later)  

**Acceptance Criteria**:
1. Tapping "Delete" from context menu shows confirmation dialog
2. Confirmation dialog title: "Delete Entry?"
3. Dialog message: "This entry will be removed from your journal."
4. Dialog has two buttons: "Cancel" (default) and "Delete" (destructive/red)
5. Tapping Cancel dismisses dialog without action
6. Tapping Delete marks entry as deleted (soft delete) with fade-out animation
7. Deleted entries no longer appear in thread view
8. Thread's updatedAt timestamp updates after deletion
9. If deleted entry was the last visible one, show empty state
10. Entry data remains in database with deletedAt timestamp
- [Arch-Lint] Soft delete preserves data integrity per TIP Section 2
- [Coverage] Test soft delete flow and filtering of deleted entries
- [Doc] Component matches Design:v1.2/DeleteConfirmation

**Component Reference**:
- Design:v1.2/DeleteConfirmation
- Design:v1.2/EntryContextMenu (trigger point)

**Technical Reference**:
- Updated Entry entity from TIP Section 2 with deletedAt field
- DeleteEntryUseCase protocol from TIP Section 6
- Repository soft delete method from TIP Section 6
- Data flow diagram from TIP Section 7

**Technical Implementation**:

1. **Domain Layer Updates** (per TIP Section 3):
   Create `Domain/UseCases/DeleteEntryUseCase.swift`:
   ```swift
   final class DeleteEntryUseCase {
       private let repository: ThreadRepository
       
       init(repository: ThreadRepository) {
           self.repository = repository
       }
       
       func execute(entryId: UUID) async throws {
           try await repository.softDeleteEntry(entryId: entryId)
       }
   }
   ```

2. **Infrastructure Updates** (per TIP Section 6):
   Update `Infrastructure/Persistence/CoreDataThreadRepository.swift`:
   ```swift
   func softDeleteEntry(entryId: UUID) async throws {
       let context = container.viewContext
       
       let request = CDEntry.fetchRequest()
       request.predicate = NSPredicate(format: "id == %@", entryId as CVarArg)
       
       guard let cdEntry = try context.fetch(request).first else {
           throw PersistenceError.notFound(id: entryId)
       }
       
       cdEntry.deletedAt = Date()
       
       // Update thread's updatedAt
       if let cdThread = cdEntry.thread {
           cdThread.updatedAt = Date()
       }
       
       try context.save()
   }
   
   func fetchEntries(for threadId: UUID, includeDeleted: Bool = false) async throws -> [Entry] {
       var predicates = [NSPredicate(format: "thread.id == %@", threadId as CVarArg)]
       
       if !includeDeleted {
           predicates.append(NSPredicate(format: "deletedAt == nil"))
       }
       
       request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
       // ... rest of implementation
   }
   ```

3. **Interface Layer Updates**:
   Update ThreadDetailViewModel (following TIP Section 7 data flow):
   ```swift
   @Published var entryToDelete: Entry?
   @Published var showDeleteConfirmation = false
   @Published var isDeletingEntry = false
   
   func confirmDeleteEntry(_ entry: Entry) {
       entryToDelete = entry
       showDeleteConfirmation = true
   }
   
   func deleteEntry() async {
       guard let entry = entryToDelete else { return }
       isDeletingEntry = true
       
       do {
           try await deleteEntryUseCase.execute(entryId: entry.id)
           
           withAnimation(.easeOut(duration: 0.3)) {
               entries.removeAll { $0.id == entry.id }
           }
           
           if let thread = thread {
               self.thread = try? Thread(
                   id: thread.id,
                   title: thread.title,
                   createdAt: thread.createdAt,
                   updatedAt: Date()
               )
           }
       } catch {
           // Handle error
       }
       
       isDeletingEntry = false
       entryToDelete = nil
       showDeleteConfirmation = false
   }
   ```

**Core Data Migration** (per TIP Core Data versioning):
1. Create ThreadDataModel v1.1
2. Add deletedAt attribute to CDEntry
3. Lightweight migration will handle existing data

**QA Test Criteria**:
1. Test delete shows confirmation dialog
2. Verify Cancel dismisses without deletion
3. Test Delete removes entry from view with animation
4. Verify entry still exists in database with deletedAt set
5. Test deleted entries don't appear after app restart
6. Verify thread updatedAt updates correctly
7. Test deleting last visible entry shows empty state
8. Test repository's includeDeleted parameter works
9. Verify migration from v1.0 to v1.1 succeeds
10. Test performance with many deleted entries

**Priority Score**: 6 (WSJF) - Essential for entry management  
**Dependencies**: TICKET-018 (Context Menu), TICKET-004 (Repository), TICKET-002 (Core Data Schema)

### TICKET-021: Entry Menu Button for Entry Management
**Story ID**: TICKET-021  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want to** tap a menu button on entries to access Edit and Delete actions  
**So that** I have a clear and discoverable way to manage entries  

**Acceptance Criteria**:
1. Each entry displays a subtle three-dot menu button (⋮) in the top-right corner
2. Menu button uses SF Symbol "ellipsis" with `.secondaryLabel` color
3. Button has 44x44pt tap target with 20x20pt icon
4. Tapping button shows native iOS context menu with two options
5. Edit option has pencil icon (SF Symbol: pencil) in default blue
6. Delete option has trash icon (SF Symbol: trash) in destructive red
7. Light haptic feedback when menu button is tapped
8. Edit action triggers same flow as TICKET-019 (edit mode)
9. Delete action triggers same confirmation as TICKET-020 (delete dialog)
10. Menu button positioned 8pt from right edge, vertically centered with timestamp
11. Button always visible but subtle (no hover states needed)
12. Menu dismisses when tapping outside or selecting an option
- [Arch-Lint] Menu state handled by native iOS, actions delegate to ViewModel
- [Coverage] UI test for menu button tap and option selection
- [Doc] Component matches Design:v1.2/EntryMenuButton and Design:v1.2/EntryContextMenu

**Component Reference**:
- Design:v1.2/EntryMenuButton (menu button on each entry)
- Design:v1.2/EntryContextMenu (menu that appears on tap)
- Design:v1.2/ThreadEntry (parent component)

**Technical Implementation**:

1. **Menu Button Design** (per Design:v1.2/EntryMenuButton):
   - Icon: SF Symbol "ellipsis" (vertical three dots)
   - Size: 20x20pt icon with 44x44pt tap target
   - Color: `.secondaryLabel` for subtle appearance
   - Position: Top-right of entry, 8pt from edge
   - Alignment: Vertically centered with timestamp line

2. **Entry Layout Update**:
   ```swift
   private func entryView(entry: Entry, isLast: Bool) -> some View {
       HStack(alignment: .top, spacing: 0) {
           // Entry content
           VStack(alignment: .leading, spacing: 8) {
               Text(formatTimestamp(entry.timestamp))
                   .font(.system(size: timestampSize, weight: .medium))
                   .foregroundColor(Color(.secondaryLabel))
               
               Text(entry.content)
                   .font(.system(size: contentSize))
                   .foregroundColor(Color(.label))
                   .lineSpacing(4)
                   .frame(maxWidth: .infinity, alignment: .leading)
           }
           .frame(maxWidth: .infinity)
           
           // Menu button
           Menu {
               Button {
                   viewModel.startEditingEntry(entry)
               } label: {
                   Label("Edit", systemImage: "pencil")
               }
               
               Button(role: .destructive) {
                   viewModel.confirmDeleteEntry(entry)
               } label: {
                   Label("Delete", systemImage: "trash")
               }
           } label: {
               Image(systemName: "ellipsis")
                   .font(.system(size: 16))
                   .foregroundColor(Color(.secondaryLabel))
                   .frame(width: 44, height: 44)
                   .contentShape(Rectangle())
           }
           .buttonStyle(PlainButtonStyle())
           .simultaneousGesture(
               TapGesture().onEnded { _ in
                   UIImpactFeedbackGenerator(style: .light).impactOccurred()
               }
           )
       }
       
       // Divider logic remains the same
   }
   ```

3. **ViewModel Integration**:
   ```swift
   // In ThreadDetailViewModel
   func startEditingEntry(_ entry: Entry) {
       editingEntry = entry
       editedContent = entry.content
       isEditFieldFocused = true
   }
   
   func confirmDeleteEntry(_ entry: Entry) {
       entryToDelete = entry
       showDeleteConfirmation = true
   }
   ```

4. **Key Implementation Notes**:
   - Use native `Menu` component for iOS 14+ compatibility
   - Button uses `.buttonStyle(PlainButtonStyle())` to prevent row highlighting
   - `.contentShape(Rectangle())` ensures full 44x44pt tap area
   - Haptic feedback via `.simultaneousGesture()` to not interfere with menu
   - Menu dismisses automatically when tapping outside (native behavior)
   - Works identically in both ScrollView and List containers

5. **Accessibility Implementation**:
   ```swift
   .accessibilityLabel("More options for entry")
   .accessibilityHint("Double tap to show edit and delete options")
   .accessibilityAddTraits(.isButton)
   ```

**QA Test Criteria**:
1. Verify menu button appears on all entries
2. Test menu button tap shows context menu
3. Verify haptic feedback on button tap
4. Test Edit option launches edit mode
5. Test Delete option shows confirmation dialog
6. Verify menu dismisses when tapping outside
7. Test menu positioning near screen edges
8. Test on various device sizes
9. Verify accessibility with VoiceOver
10. Test button remains visible during scroll
11. Verify button tap target is 44x44pt minimum
12. Test behavior when keyboard opens
13. Verify works with Dynamic Type sizes
14. Test menu button doesn't interfere with text selection
15. Verify works in both ScrollView and List

**Priority Score**: 5 (WSJF) - More discoverable than swipe gestures, essential for entry management  
**Dependencies**: TICKET-019 (Edit mode), TICKET-020 (Delete functionality)

---

## Sprint Plan

### Sprint 1 (Week 1) - Foundation
| Story ID | Story | Points | Layer |
|----------|-------|--------|-------|
| TICKET-001 | Project Setup | 1 | infrastructure |
| TICKET-002 | Core Data Schema | 1 | infrastructure |
| TICKET-003 | Domain Entities & Repository | 1 | domain |
| TICKET-004 | Core Data Implementation | 1 | infrastructure |
| TICKET-005 | Use Cases | 1 | domain |
| TICKET-006 | Draft Manager | 1 | application |
| TICKET-007 | Thread List View Model | 1 | application |
| TICKET-016 | Architecture Tests | 1 | infrastructure |
**Total**: 8 points

### Sprint 2 (Week 2) - Core User Features
| Story ID | Story | Points | Layer |
|----------|-------|--------|-------|
| TICKET-008 | Thread List UI | 1 | interface |
| TICKET-009 | Create Thread UI | 1 | interface |
| TICKET-010 | Thread Detail View Model | 1 | application |
| TICKET-011 | Thread Detail UI | 1 | interface |
| TICKET-012 | Add Entry UI | 1 | interface |
| TICKET-013 | Keyboard Enhancements | 1 | interface |
**Total**: 6 points

### Sprint 3 (Week 3) - Export & Polish
| Story ID | Story | Points | Layer |
|----------|-------|--------|-------|
| TICKET-014 | Export Implementation | 1 | domain/infrastructure |
| TICKET-015 | Export UI | 1 | interface |
| TICKET-017 | Performance Tests | 1 | infrastructure |
**Total**: 3 points

### Sprint 4 (Week 4) - Entry Management
| Story ID | Story | Points | Layer |
|----------|-------|--------|-------|
| TICKET-018 | Context Menu | 1 | interface |
| TICKET-019 | Edit Entry Mode | 1 | interface |
| TICKET-020 | Delete Entry (Soft) | 1 | domain/infrastructure/interface |
**Total**: 3 points

### Sprint 5 (Week 5) - Enhanced Interactions
| Story ID | Story | Points | Layer |
|----------|-------|--------|-------|
| TICKET-021 | Swipe Actions | 1 | interface |
| TICKET-022 | Blue Circle Timestamp | 1 | interface |
**Total**: 2 points

---

### TICKET-022: Blue Circle Timestamp Enhancement
**Story ID**: TICKET-022  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want** a subtle blue circle behind entry timestamps  
**So that** I can more easily distinguish between separate entries when reading or scanning  

**Acceptance Criteria**:
1. Each entry timestamp displays with a light blue circular background
2. Background color: #E8F3FF (or system equivalent)
3. Border radius: 10px (rounded rectangle, not full circle)
4. Padding: 2px vertical, 10px horizontal
5. Subtle shadow: 0 1px 3px rgba(0,0,0,0.08)
6. Timestamp text remains 11pt, color #8E8E93 (unchanged)
7. Background adapts to Dynamic Type sizing
8. Works with all timestamp formats ("Just now", "Today, 2:15 PM", "5 years ago")
9. Maintains left alignment with entry content
10. No animation or transitions - static visual enhancement
11. Supports both light and dark mode appropriately
- [Arch-Lint] Purely presentational change in Interface layer
- [Coverage] Visual regression test for timestamp appearance
- [Doc] Design mockup at Design/blue-circle-timestamp-mockup.html

**Design Reference**:
- Mockup: `/Design/blue-circle-timestamp-mockup.html`
- Component: `Design:v1.2/ThreadEntry` (timestamp portion)
- See mockup for exact visual specifications and variations

**User Need**:
- Problem: Hard to distinguish separate entries when scanning through journal
- Use case: Quickly reading through entries or looking for specific ones to edit
- Solution: Subtle visual indicator that maintains minimalist aesthetic

**QA Test Criteria**:
1. Verify timestamp background appears correctly in light mode
2. Test with various timestamp lengths
3. Verify Dynamic Type support (increase/decrease text size)
4. Check dark mode appearance (adjust colors appropriately)
5. Verify no performance impact with many entries
6. Test with edited entries that show "(edited)" suffix

**Priority Score**: 3 (WSJF) - Quality of life enhancement  
**Dependencies**: None - can be implemented independently

**Technical Implementation**:
1. **Update DesignSystem.swift**:
   - Add TimestampStyle struct with color, padding, and shadow constants
   - Reference: Technical-Implementation-Plan.md Section 6.1
   
2. **Create TimestampBackground ViewModifier**:
   ```swift
   struct TimestampBackground: ViewModifier {
       @Environment(\.colorScheme) var colorScheme
       
       func body(content: Content) -> some View {
           content
               .padding(.horizontal, 10)
               .padding(.vertical, 2)
               .background(
                   RoundedRectangle(cornerRadius: 10)
                       .fill(colorScheme == .dark ? Color(hex: "#1C3A52") : Color(hex: "#E8F3FF"))
                       .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
               )
       }
   }
   ```

3. **Update ThreadDetailViewFixed.swift**:
   - Apply modifier to timestamp Text view in entryView function
   - Ensure Dynamic Type support is maintained
   - Test with various colorScheme environments

4. **Testing Approach**:
   - Unit test: Verify modifier applies correct styling
   - UI test: Screenshot comparison for visual regression
   - Manual test: Dynamic Type scaling, dark mode

**Files to Modify**:
- `Interface/Theme/DesignSystem.swift` - Add TimestampStyle configuration
- `Interface/Views/ThreadDetailViewFixed.swift` - Apply modifier to timestamps
- `ThreadJournal2Tests/Interface/TimestampBackgroundTests.swift` - New test file

---

## MVP Definition
By the end of Sprint 3, users will be able to:
1. ✅ View all their journal threads in a list
2. ✅ Create new threads with titles
3. ✅ View all entries in a thread chronologically
4. ✅ Add new entries to threads with auto-save protection
5. ✅ Use expanded keyboard mode for longer entries
6. ✅ Export any thread to CSV for analysis

This is a fully functional journaling app!

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

## Ideas for next phase
1. A backup capability
2. Security - need FaceID to see the page (this should be configurable in settings)
3. Add a settings page
4. The ability to tag threads entries
5. The ability to add 'snippets' to thread entries to fill out
6. The ability to have a 'all threads' view that's sorted by time
7. The ability to export more than one thread together (ie. select multiple threads to export)
8. ~~Editing thread entries, deleting entries~~ ✅ Completed in Sprint 4-5 (TICKET-018 through TICKET-021)
9. Deleting entire threads (safety confirmation to do so - ie type a word)
10. Search functionality
11. Add a setting option to shorten long entries and if a long entry is shortened there's a button to expand that in the thread
12. Pull-to-refresh on thread list
13. Undo/redo for entry edits
14. Archive threads instead of delete
15. Entry templates/prompts
