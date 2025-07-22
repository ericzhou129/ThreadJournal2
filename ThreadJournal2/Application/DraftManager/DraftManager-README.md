# Draft Manager

## Overview

The Draft Manager is responsible for auto-saving user input to prevent data loss. It implements intelligent debouncing and periodic auto-save to balance between data safety and performance.

## Key Features

1. **In-Memory Storage**: Drafts are stored in memory until successfully persisted
2. **Auto-Save**: Automatic save every 30 seconds while user is typing
3. **Debouncing**: Waits 2 seconds after last keystroke before saving to reduce writes
4. **Thread Safety**: Concurrent access is handled safely with a concurrent queue
5. **Per-Thread Drafts**: Each thread maintains its own independent draft

## Architecture

### DraftManager Protocol

```swift
protocol DraftManager {
    func saveDraft(_ content: String, for threadId: UUID)
    func getDraft(for threadId: UUID) -> String?
    func clearDraft(for threadId: UUID)
}
```

### InMemoryDraftManager Implementation

The implementation uses:
- **Concurrent Queue**: For thread-safe access to draft storage
- **Timer-based Auto-Save**: Periodic saves every 30 seconds
- **Debounce Timer**: Prevents excessive saves during rapid typing

## Usage

### Basic Usage

```swift
let draftManager = InMemoryDraftManager()

// Set up auto-save callback
draftManager.onAutoSave = { threadId, content in
    // Persist to database or handle save
    await saveToDatabase(threadId: threadId, content: content)
}

// Save a draft
draftManager.saveDraft("My journal entry...", for: threadId)

// Retrieve a draft
if let draft = draftManager.getDraft(for: threadId) {
    textField.text = draft
}

// Clear after successful save
draftManager.clearDraft(for: threadId)
```

### Integration with ViewModels

```swift
class ThreadDetailViewModel: ObservableObject {
    private let draftManager: DraftManager
    
    func updateDraft(_ content: String) {
        draftManager.saveDraft(content, for: currentThreadId)
    }
    
    func loadDraft() {
        if let draft = draftManager.getDraft(for: currentThreadId) {
            self.draftContent = draft
        }
    }
    
    func entrySaved() {
        draftManager.clearDraft(for: currentThreadId)
    }
}
```

## Testing

The implementation includes two test suites:

1. **InMemoryDraftManagerTests**: Standard tests with real timers
2. **InMemoryDraftManagerFastTests**: Fast tests with shortened intervals (100ms debounce, 500ms auto-save)

### Test Coverage

- Basic CRUD operations
- Debouncing behavior
- Auto-save functionality
- Thread safety with concurrent access
- Multiple thread draft management
- Edge cases (rapid save/clear, etc.)

## Implementation Details

### Debouncing Logic

When a user types:
1. Each keystroke cancels the previous debounce timer
2. A new 2-second timer starts
3. If no keystrokes for 2 seconds, the draft is saved
4. This prevents excessive saves during rapid typing

### Auto-Save Logic

1. A 30-second timer runs continuously
2. When it fires, all pending drafts are saved
3. This ensures drafts are persisted even if user keeps typing
4. Provides safety net for long writing sessions

### Thread Safety

- Read operations use concurrent reads
- Write operations use barrier flags
- All timer operations happen on main queue
- No force unwrapping or unsafe operations

## Future Enhancements

1. **Persistence Layer**: Add SQLite/Core Data backing for app termination
2. **Conflict Resolution**: Handle multiple devices editing same thread
3. **Compression**: Compress large drafts to save memory
4. **Encryption**: Encrypt drafts for privacy (Phase 3)
5. **Analytics**: Track draft recovery success rate