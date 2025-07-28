# Thread Deletion EPIC

## Overview
This epic covers the implementation of thread deletion functionality with soft delete support, allowing users to delete threads while maintaining data integrity and providing recovery options.

## Design Reference
`/Design/delete-thread-mockup.html` - Interactive mockup showing:
- Ellipsis menu on thread list items
- Context menu with single "Delete Thread" option  
- Confirmation dialog with thread name and entry count
- Thread removal from list after deletion

## Technical Architecture
Following Clean Architecture principles from the TIP:
- **Context**: Journaling Context
- **Layers**: Changes span all four layers (domain, application, interface, infrastructure)
- **Pattern**: Soft delete with preserved data for future recovery

## TICKETS

### thread-deletion-TICKET-001: Thread Entity Soft Delete Support
**Story ID**: thread-deletion-TICKET-001  
**Context/Layer**: Journaling / domain  
**As a** developer  
**I want** Thread entity to support soft delete functionality  
**So that** threads can be safely deleted with recovery options  

**Acceptance Criteria**:
- Given the existing Thread entity in Domain layer
- When I update `Domain/Entities/Thread.swift`
- Then Thread has optional `deletedAt: Date?` property
- And computed property `isDeleted: Bool { deletedAt != nil }` exists
- And helper method `entryCount: Int` returns count of entries
- And entity remains Codable for future export functionality
- [Arch-Lint] Entity follows TIP section 5.1.1 (Core Entities)
- [Coverage] 100% unit test coverage for new properties
- [Doc] Soft delete pattern documented in entity

**Implementation Guide**:
```swift
// Thread.swift additions
struct Thread: Identifiable, Codable {
    // Existing properties...
    let deletedAt: Date?
    
    var isDeleted: Bool {
        deletedAt != nil
    }
    
    var entryCount: Int {
        entries.filter { !$0.isDeleted }.count
    }
}
```

**QA Test Criteria**:
1. Test deletedAt property serialization/deserialization
2. Test isDeleted returns true when deletedAt is set
3. Test isDeleted returns false when deletedAt is nil
4. Test entryCount excludes soft-deleted entries
5. Verify Codable conformance with new property

**Priority Score**: 8 (WSJF) - Foundation for all deletion features  
**Dependencies**: None

---

### thread-deletion-TICKET-002: Delete Thread Use Case
**Story ID**: thread-deletion-TICKET-002  
**Context/Layer**: Journaling / domain  
**As a** developer  
**I want** DeleteThreadUseCase to handle thread deletion business logic  
**So that** threads can be soft deleted with proper cascade behavior  

**Acceptance Criteria**:
- Given thread entity with soft delete support from TICKET-001
- When I create `Domain/UseCases/DeleteThreadUseCase.swift`
- Then protocol has single `execute(threadId: UUID) async throws` method
- And implementation sets deletedAt timestamp on thread
- And all associated entries are cascade soft deleted
- And ThreadNotFoundError thrown for invalid thread ID
- [Arch-Lint] Single execute method per TIP section 5.1.2 (Use Cases)
- [Coverage] 90%+ unit test coverage
- [Doc] Business rules for cascade deletion documented

**Implementation Guide**:
```swift
// DeleteThreadUseCase.swift
protocol DeleteThreadUseCase {
    func execute(threadId: UUID) async throws
}

final class DeleteThreadUseCaseImpl: DeleteThreadUseCase {
    private let repository: ThreadRepository
    
    func execute(threadId: UUID) async throws {
        // 1. Fetch thread or throw ThreadNotFoundError
        // 2. Set deletedAt = Date()
        // 3. Cascade delete all entries
        // 4. Call repository.softDelete(thread)
    }
}
```

**QA Test Criteria**:
1. Test valid thread ID results in soft delete
2. Test invalid thread ID throws ThreadNotFoundError
3. Test all entries in thread are cascade deleted
4. Test deletedAt timestamp is current time
5. Mock repository to verify softDelete called

**Priority Score**: 9 (WSJF) - Core deletion business logic  
**Dependencies**: thread-deletion-TICKET-001

---

### thread-deletion-TICKET-003: Core Data Migration for Soft Delete
**Story ID**: thread-deletion-TICKET-003  
**Context/Layer**: Journaling / infrastructure  
**As a** developer  
**I want** Core Data migration to support soft delete fields  
**So that** thread deletion can be persisted with data recovery capability  

**Acceptance Criteria**:
- Given existing Core Data model version 1.1
- When I create new model version 1.2
- Then CDThread entity has `deletedAt` attribute (type: Date, optional)
- And lightweight migration is configured properly
- And existing data is preserved after migration
- And migration succeeds with 100+ threads in < 2 seconds
- [Arch-Lint] Follows TIP section 5.4.1 (Core Data Implementation)
- [Coverage] Migration tested with edge cases
- [Doc] Migration steps documented

**Implementation Guide**:
```swift
// Core Data Model Changes
// 1. Select ThreadJournal2.xcdatamodeld
// 2. Editor > Add Model Version > Based on v1.1
// 3. Set v1.2 as current version
// 4. Add to CDThread:
//    - Attribute: deletedAt
//    - Type: Date
//    - Optional: YES
// 5. Enable lightweight migration in options
```

**QA Test Criteria**:
1. Test migration with empty database
2. Test migration with 100+ threads
3. Test existing data integrity preserved
4. Test new deletedAt field defaults to nil
5. Verify no data loss or corruption
6. Performance test: migration < 2s for 100 threads

**Priority Score**: 8 (WSJF) - Enables persistence layer  
**Dependencies**: None (can run parallel with domain tickets)

---

### thread-deletion-TICKET-004: Repository Soft Delete Implementation  
**Story ID**: thread-deletion-TICKET-004  
**Context/Layer**: Journaling / infrastructure  
**As a** developer  
**I want** ThreadRepository to support soft delete operations  
**So that** deleted threads are filtered from queries while remaining recoverable  

**Acceptance Criteria**:
- Given Core Data migration from TICKET-003
- When I update `Domain/Repositories/ThreadRepository.swift` protocol
- Then protocol includes `softDelete(threadId: UUID) async throws` method
- And `Infrastructure/Repositories/CoreDataThreadRepository.swift` implements it
- And fetchAll excludes soft-deleted threads by default
- And `fetchAll(includeDeleted: Bool)` overload exists for recovery
- [Arch-Lint] Repository interface per TIP section 5.1.4
- [Coverage] 100% integration test coverage
- [Doc] Soft delete behavior documented

**Implementation Guide**:
```swift
// ThreadRepository protocol update
protocol ThreadRepository {
    func softDelete(threadId: UUID) async throws
    func fetchAll() async throws -> [Thread]
    func fetchAll(includeDeleted: Bool) async throws -> [Thread]
}

// CoreDataThreadRepository implementation
func fetchAll() async throws -> [Thread] {
    // NSPredicate: deletedAt == nil
    return try await fetchAll(includeDeleted: false)
}
```

**QA Test Criteria**:
1. Test softDelete sets deletedAt timestamp
2. Test fetchAll excludes deleted threads
3. Test fetchAll(includeDeleted: true) includes all
4. Test deleted threads remain in Core Data
5. Test concurrent delete operations
6. Verify predicate performance

**Priority Score**: 8 (WSJF) - Critical for data layer  
**Dependencies**: thread-deletion-TICKET-003

---

### thread-deletion-TICKET-005: Thread List ViewModel Delete Support
**Story ID**: thread-deletion-TICKET-005  
**Context/Layer**: Journaling / application  
**As a** developer  
**I want** ThreadListViewModel to support thread deletion  
**So that** the UI can trigger deletions with proper state management  

**Acceptance Criteria**:
- Given DeleteThreadUseCase from TICKET-002
- When I update `Application/ViewModels/ThreadListViewModel.swift`
- Then ViewModel has `@Published threadToDelete: Thread?`
- And `@Published showDeleteConfirmation: Bool` property exists
- And methods `confirmDelete()`, `deleteThread()`, `cancelDelete()` work
- And thread list refreshes after successful deletion
- [Arch-Lint] Follows MVVM per TIP section 5.2.1 (View Models)
- [Coverage] 90%+ unit test coverage
- [Doc] State transitions documented

**Implementation Guide**:
```swift
// ThreadListViewModel additions
@MainActor
final class ThreadListViewModel: ObservableObject {
    @Published var threadToDelete: Thread?
    @Published var showDeleteConfirmation = false
    private let deleteThreadUseCase: DeleteThreadUseCase
    
    func confirmDelete(thread: Thread) {
        threadToDelete = thread
        showDeleteConfirmation = true
    }
    
    func deleteThread() async {
        guard let thread = threadToDelete else { return }
        // 1. Call deleteThreadUseCase.execute(thread.id)
        // 2. Handle errors with errorMessage
        // 3. Refresh thread list on success
        // 4. Reset deletion state
    }
}
```

**QA Test Criteria**:
1. Test confirmDelete sets state correctly
2. Test deleteThread calls use case with correct ID
3. Test successful deletion refreshes list
4. Test error handling shows error message
5. Test cancelDelete resets state
6. Mock use case for all scenarios

**Priority Score**: 7 (WSJF) - Bridges domain to UI  
**Dependencies**: thread-deletion-TICKET-002

---

### thread-deletion-TICKET-006: Thread List Item Ellipsis Menu
**Story ID**: thread-deletion-TICKET-006  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want** an ellipsis menu on each thread  
**So that** I can access thread actions like delete  

**Acceptance Criteria**:
- Given ThreadListViewModel with delete support from TICKET-005
- When I update `Interface/Views/ThreadListView.swift`
- Then each ThreadListItem has ellipsis button (SF Symbol)
- And button shows SwiftUI Menu on tap
- And menu contains "Delete Thread" option in red
- And touch target is minimum 44×44pt
- [Arch-Lint] Follows TIP section 5.3.1 (SwiftUI Views)
- [Coverage] Visual regression tests pass
- [Doc] Accessibility labels documented

**Implementation Guide**:
```swift
// ThreadListItem modification
HStack {
    // Existing thread info...
    Spacer()
    Menu {
        Button(role: .destructive) {
            viewModel.confirmDelete(thread: thread)
        } label: {
            Label("Delete Thread", systemImage: "trash")
        }
    } label: {
        Image(systemName: "ellipsis")
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }
}
```

**QA Test Criteria**:
1. Test ellipsis button visible on all items
2. Test menu appears on tap
3. Test delete option has destructive styling
4. Test 44×44pt touch target
5. Test VoiceOver reads "More options for [thread name]"
6. Visual test against design mockup

**Priority Score**: 6 (WSJF) - User-facing delete entry point  
**Dependencies**: thread-deletion-TICKET-005

---

### thread-deletion-TICKET-007: Delete Confirmation Dialog
**Story ID**: thread-deletion-TICKET-007  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want** confirmation before deleting a thread  
**So that** I don't accidentally delete important journal entries  

**Acceptance Criteria**:
- Given ellipsis menu from TICKET-006
- When I tap "Delete Thread" in menu
- Then alert shows with thread name and entry count
- And message says "Delete '[Thread Name]'? This thread contains X entries."
- And "Delete" button has destructive style
- And "Cancel" button dismisses without action
- [Arch-Lint] Uses SwiftUI .alert modifier
- [Coverage] UI tests verify dialog flow
- [Doc] Copy matches design mockup exactly

**Implementation Guide**:
```swift
// ThreadListView alert modifier
.alert("Delete Thread", 
       isPresented: $viewModel.showDeleteConfirmation,
       presenting: viewModel.threadToDelete) { thread in
    Button("Cancel", role: .cancel) {
        viewModel.cancelDelete()
    }
    Button("Delete", role: .destructive) {
        Task {
            await viewModel.deleteThread()
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
} message: { thread in
    Text("Delete '\(thread.title)'? This thread contains \(thread.entryCount) entries.")
}
```

**QA Test Criteria**:
1. Test alert title is "Delete Thread"
2. Test message shows correct thread name
3. Test entry count is accurate
4. Test Cancel dismisses without deletion
5. Test Delete triggers deletion
6. Test haptic feedback fires on delete
7. Test VoiceOver reads full message

**Priority Score**: 7 (WSJF) - Prevents data loss  
**Dependencies**: thread-deletion-TICKET-006

---

### thread-deletion-TICKET-008: Post-Delete Navigation & Feedback
**Story ID**: thread-deletion-TICKET-008  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want** clear feedback after deleting a thread  
**So that** I know the deletion succeeded and can undo if needed  

**Acceptance Criteria**:
- Given successful thread deletion from TICKET-007
- When deletion completes
- Then thread animates out of list smoothly
- And success toast shows "Thread deleted" with undo button
- And undo is available for 5 seconds
- And empty state appears if last thread deleted
- [Arch-Lint] Uses SwiftUI animations
- [Coverage] UI tests verify animations
- [Doc] Undo implementation documented

**Implementation Guide**:
```swift
// Post-deletion in ThreadListView
.onAppear {
    if viewModel.showUndoToast {
        withAnimation(.easeOut(duration: 0.3)) {
            // Show toast
        }
        
        // Auto-hide after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            viewModel.clearUndoState()
        }
    }
}

// List animation
List {
    ForEach(viewModel.threads) { thread in
        ThreadListItem(thread: thread)
    }
}
.animation(.default, value: viewModel.threads)
```

**QA Test Criteria**:
1. Test thread removal animates smoothly
2. Test toast appears with "Thread deleted"
3. Test undo button restores thread
4. Test toast auto-hides after 5 seconds
5. Test empty state for no threads
6. Test list reorders smoothly
7. Test rapid deletions handled correctly

**Priority Score**: 4 (WSJF) - Polish feature  
**Dependencies**: thread-deletion-TICKET-007

---

## Testing Strategy

### Unit Tests
- Thread entity soft delete properties
- DeleteThreadUseCase business logic
- ViewModel delete flow and state management
- Repository soft delete implementation

### Integration Tests  
- Core Data migration from v1.1 to v1.2
- Full delete flow from UI to persistence
- Undo functionality within time window

### UI Tests
- Ellipsis menu interaction
- Confirmation dialog flow
- Post-deletion animations

### Performance Tests
- Deletion with 100+ threads
- Deletion of thread with 1000+ entries
- Migration performance with large datasets

## Success Metrics
- Zero data loss from soft delete
- Delete operation < 100ms
- Migration completes < 2s for 100 threads
- 90%+ test coverage for new code

## Definition of Done
- [ ] All tickets completed and tested
- [ ] SwiftLint passes with no warnings
- [ ] Architecture tests pass
- [ ] Design matches mockup exactly
- [ ] PR approved and merged to main