# ThreadDetailViewModel Draft State Machine Documentation

## Overview

The ThreadDetailViewModel manages draft state for journal entries using a state machine pattern. This ensures proper handling of auto-save functionality and provides clear feedback to users about the status of their drafts.

## Draft States

The `DraftState` enum defines five possible states:

### 1. `empty`
- **Description**: No draft content exists
- **Entry Condition**: Initial state or after successfully sending an entry
- **UI Indication**: No draft status shown

### 2. `typing`
- **Description**: User is actively typing content
- **Entry Condition**: When `draftContent` changes to non-empty value
- **UI Indication**: "Draft" status shown
- **Triggers**: Schedules draft save to DraftManager

### 3. `saving`
- **Description**: Draft is being auto-saved
- **Entry Condition**: When DraftManager triggers auto-save callback
- **UI Indication**: "Saving..." status shown
- **Duration**: Brief (simulated 0.1s currently)

### 4. `saved`
- **Description**: Draft has been successfully saved
- **Entry Condition**: After successful save operation
- **UI Indication**: "Draft saved" status shown
- **Duration**: Shows for 1 second before returning to `typing` state

### 5. `failed(error: Error)`
- **Description**: Entry creation failed, draft preserved
- **Entry Condition**: When `addEntry()` throws an error
- **UI Indication**: "Save failed" status shown
- **Behavior**: Draft content is preserved for retry

## State Transitions

```
empty <--> typing --> saving --> saved --> typing
             |                     ^
             v                     |
          failed <-----------------+
```

### Key Transitions:

1. **Empty → Typing**: User starts typing in empty compose area
2. **Typing → Empty**: User clears all content or sends entry successfully
3. **Typing → Saving**: Auto-save triggered (30-second timer or 2-second debounce)
4. **Saving → Saved**: Auto-save completes successfully
5. **Saved → Typing**: After 1-second delay if content still exists
6. **Typing → Failed**: Entry creation fails (network error, validation, etc.)
7. **Failed → Typing**: User modifies draft after failure

## Auto-Save Mechanism

The draft system integrates with `InMemoryDraftManager` which provides:

- **30-second auto-save interval**: Drafts are automatically saved every 30 seconds while typing
- **2-second debounce**: Rapid changes are debounced to avoid excessive saves
- **Thread-specific drafts**: Each thread maintains its own draft independently
- **Memory persistence**: Drafts persist in memory until successfully saved as entries

## Error Handling

When entry creation fails:

1. Draft content is preserved
2. State transitions to `failed(error)`
3. Retry button becomes available (up to 3 attempts)
4. User can continue editing draft
5. Draft remains in DraftManager until successful save

## Usage in UI

The ViewModel provides several properties for UI binding:

- `draftContent`: Two-way binding for text input
- `draftStateDescription`: Human-readable state for UI display
- `isSavingDraft`: Boolean for showing save indicator
- `hasFailedSave`: Boolean for showing retry button
- `canSendEntry`: Boolean for enabling send button

## Implementation Notes

- State transitions are handled automatically based on user actions
- The state machine ensures drafts are never lost due to failures
- Future enhancement: Actual persistence to disk/cloud instead of memory-only
- Thread safety is handled by DraftManager's internal queue