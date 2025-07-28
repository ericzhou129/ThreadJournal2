## Ideas for next phase
1. A backup capability
2. Security - need FaceID to see the page (this should be configurable in settings)
3. Add a settings page
4. The ability to tag threads entries
5. The ability to add 'snippets' to thread entries to fill out
6. The ability to have a 'all threads' view that's sorted by time
7. The ability to export more than one thread together (ie. select multiple threads to export)
9. Deleting entire threads (safety confirmation to do so - ie type a word)
10. Search functionality
11. Add a setting option to shorten long entries and if a long entry is shortened there's a button to expand that in the thread
12. Pull-to-refresh on thread list
13. Undo/redo for entry edits
14. Archive threads instead of delete
15. Entry templates/prompts
17. Settings menu - change templates



### IDEA-1: Ability to Delete Threads -- IN PROGRESS
User Story: 
As a user, I want the ability to delete threads that I've created in case I don't want them anymore. 

Acceptance Criteria: 
- Beside each thread on the main page with all the threads, there is an 'ellipesis' side menu option that displays options, one of the option is 'delete'. When this is selected, a thread is then deleted. 
- When a user chooses to 'delete' a thread there is a confirmation popup asking 'Are you sure you want to delete this thread?'
- If a Thread is 'deleted', the thread itself and it's entries are all soft-deleted'. In the 'soft-delete' the 'soft-deleted' entries shoudl still be associated wiht the thread so that the thread can be recoverable in the future (future implementation)
- Once a Thread is deleted, it is no longer visible on the thread list


### IDEA-2: Settings menu
User Story, 
As a user, I want the ability to access a settings page from the home page (page with all the threads), so that I can configure my app settings through this page. 

AC: 
- 

### IDEA-3: Add option to recover 'deleted threads' to the settings menu or delete forever

- Include a 'deleted threads' sub-menu'

### IDEA-4: ALL ENTRIES thread 


### IDEA-5: Ability to omit threads from ALL ENTRIES thread


### IDEA-6: Ability to PIN entries within a thread


### IDEA-7: Ability to Add templated fields to an entry so that a user can create a thread for tracking something more structured 

AC:
- The structured stuff should be included as a field in the CSV




# ThreadJournal Tickets - Phase 2 (Future Features)

## Overview
This document contains tickets for Phase 2 features of ThreadJournal. These tickets are for future implementation after Phase 1 is complete.

---

## Epic 6: Security & Privacy

### TICKET-023: FaceID/TouchID Authentication
**Story ID**: TICKET-023  
**Context/Layer**: Settings / application + interface  
**As a** user  
**I want to** secure my journal with biometric authentication  
**So that** my private thoughts remain protected from unauthorized access  

**Acceptance Criteria**:
1. App checks for biometric capability on launch
2. If no biometrics enrolled, show settings prompt
3. Authentication required when:
   - App launches from terminated state
   - App returns from background after 30 seconds
   - User manually locks from settings
4. Failed authentication shows retry option
5. After 3 failed attempts, falls back to device passcode
6. Settings toggle to enable/disable biometric lock
7. Grace period setting: immediate, 30s, 1min, 5min
8. Blur content while locked (not just overlay)
- [Arch-Lint] BiometricAuthManager in application layer
- [Coverage] Test all authentication states
- [Doc] Privacy section in Settings design

**Technical Implementation**:
- Use LocalAuthentication framework
- Create `Application/Security/BiometricAuthManager.swift`
- Store settings in UserDefaults (not sensitive data)
- Implement blur view modifier for locked state

**QA Test Criteria**:
1. Test with FaceID, TouchID, and no biometrics
2. Verify grace period timing
3. Test fallback to passcode
4. Verify content is blurred when locked
5. Test settings persistence

**Priority Score**: 8 (WSJF) - High user value for privacy  
**Dependencies**: TICKET-024 (Settings infrastructure)

---

## Epic 7: Settings & Configuration -- IN PROGRESS

### TICKET-024: Settings Page Infrastructure
**Story ID**: TICKET-024  
**Context/Layer**: Settings / interface + application  
**As a** user  
**I want to** access app settings from a dedicated page  
**So that** I can customize my journaling experience  

**Acceptance Criteria**:
1. Settings icon in thread list navigation bar
2. Settings page with sections:
   - Security (biometric toggle, grace period)
   - Display (text size, theme - future)
   - Export (default format - future)
   - About (version, privacy policy link)
3. Each setting persists across app launches
4. Settings use native iOS styling (Form/List)
5. Changes take effect immediately
6. Back button returns to thread list
- [Arch-Lint] SettingsViewModel in application layer
- [Coverage] Test settings persistence
- [Doc] Settings screen in Design:v2.0

**Technical Implementation**:
- Create `Application/ViewModels/SettingsViewModel.swift`
- Create `Interface/Screens/SettingsScreen.swift`
- Use @AppStorage for simple values
- Create SettingsRepository for complex settings

**QA Test Criteria**:
1. Verify all settings persist
2. Test immediate effect of changes
3. Verify navigation flow
4. Test with different device sizes

**Priority Score**: 7 (WSJF) - Enables other features  
**Dependencies**: None

---

## Epic 8: Enhanced Organization

### TICKET-025: Entry Tagging System
**Story ID**: TICKET-025  
**Context/Layer**: Journaling / domain + interface  
**As a** user  
**I want to** tag my journal entries with keywords  
**So that** I can find related entries across different threads  

**Acceptance Criteria**:
1. Add tags during entry creation (inline #hashtags)
2. Tags extracted automatically from content
3. Tag suggestions based on previously used tags
4. Tags display as clickable pills below entry
5. Tapping tag shows all entries with that tag
6. Tag search across all threads
7. Maximum 10 tags per entry
8. Tags persist with entry data
- [Arch-Lint] Tag extraction in domain layer
- [Coverage] Test tag parsing logic
- [Doc] Tag UI components

**Technical Implementation**:
- Update Entry entity with tags: [String]
- Create TagExtractionService in domain
- Create TaggedEntriesViewModel
- Update Core Data model to v1.2

**QA Test Criteria**:
1. Test hashtag extraction
2. Verify tag persistence
3. Test cross-thread tag search
4. Performance with many tags

**Priority Score**: 6 (WSJF) - Nice organization feature  
**Dependencies**: TICKET-026 (Search infrastructure)

### TICKET-026: Search Functionality
**Story ID**: TICKET-026  
**Context/Layer**: Journaling / application + interface  
**As a** user  
**I want to** search across all my journal entries  
**So that** I can find specific thoughts or memories  

**Acceptance Criteria**:
1. Search bar in thread list (pull down to reveal)
2. Search across entry content and thread titles
3. Real-time search results as typing
4. Results grouped by thread
5. Highlight search terms in results
6. Tap result navigates to entry in thread
7. Recent searches (last 5)
8. Clear search history option
9. Search supports quoted phrases
10. Case-insensitive search
- [Arch-Lint] SearchUseCase in domain layer
- [Coverage] Test search algorithms
- [Doc] Search UI patterns

**Technical Implementation**:
- Create SearchUseCase with repository method
- Implement FTS in Core Data (or simple predicate)
- Create SearchViewModel
- Create SearchResultsView

**QA Test Criteria**:
1. Test search accuracy
2. Verify real-time updates
3. Test with 10k+ entries
4. Verify highlighting works

**Priority Score**: 8 (WSJF) - High user value  
**Dependencies**: None

---

## Epic 9: Content Management

### TICKET-027: Archive Threads
**Story ID**: TICKET-027  
**Context/Layer**: Journaling / domain + interface  
**As a** user  
**I want to** archive threads I'm no longer actively using  
**So that** my active thread list stays focused and clean  

**Acceptance Criteria**:
1. Swipe action on thread list: "Archive"
2. Archive confirmation dialog
3. Archived threads section at bottom of list
4. Toggle to show/hide archived threads
5. Unarchive action available
6. Archived threads excluded from search by default
7. Archive state persists
8. Export includes archive status
- [Arch-Lint] Archive flag in Thread entity
- [Coverage] Test archive/unarchive flow
- [Doc] Archive UI patterns

**Technical Implementation**:
- Add isArchived: Bool to Thread entity
- Update ThreadListViewModel to filter
- Add archive/unarchive methods
- Core Data migration to v1.3

**QA Test Criteria**:
1. Test archive/unarchive flow
2. Verify filtering works
3. Test search exclusion
4. Verify export format

**Priority Score**: 5 (WSJF) - Quality of life  
**Dependencies**: None

### TICKET-028: Delete Thread (with Confirmation)
**Story ID**: TICKET-028  
**Context/Layer**: Journaling / domain + interface  
**As a** user  
**I want to** permanently delete threads I no longer need  
**So that** I can remove unwanted content completely  

**Acceptance Criteria**:
1. Delete option in thread detail menu
2. Two-step confirmation:
   - First dialog: "Delete Thread?"
   - Type thread name to confirm
3. Show entry count in warning
4. Deletion is permanent (no soft delete)
5. Cascading delete all entries
6. Return to thread list after delete
7. Success message briefly shown
- [Arch-Lint] DeleteThreadUseCase in domain
- [Coverage] Test cascade deletion
- [Doc] Delete confirmation UX

**Technical Implementation**:
- Create DeleteThreadUseCase
- Implement type-to-confirm dialog
- Ensure Core Data cascade rule
- Add success toast/banner

**QA Test Criteria**:
1. Test deletion with many entries
2. Verify type-to-confirm
3. Test cascade deletion
4. Verify no orphaned data

**Priority Score**: 6 (WSJF) - Important for management  
**Dependencies**: None

---

## Epic 10: Advanced Features

### TICKET-029: Entry Templates/Prompts
**Story ID**: TICKET-029  
**Context/Layer**: Journaling / domain + interface  
**As a** user  
**I want to** use templates or prompts for journal entries  
**So that** I can overcome writer's block and maintain consistency  

**Acceptance Criteria**:
1. Template button in compose area
2. Built-in templates:
   - Daily reflection
   - Gratitude journal
   - Goal tracking
   - Free write
3. Custom template creation
4. Template fills compose area
5. Variables in templates: {date}, {time}, {weather}
6. Skip template option
7. Remember last used per thread
- [Arch-Lint] TemplateManager in application
- [Coverage] Test variable replacement
- [Doc] Template selection UI

**Technical Implementation**:
- Create Template entity
- Create TemplateManager
- Variable replacement engine
- Template selection sheet

**QA Test Criteria**:
1. Test all built-in templates
2. Verify variable replacement
3. Test custom templates
4. Verify per-thread memory

**Priority Score**: 4 (WSJF) - Engagement feature  
**Dependencies**: None

### TICKET-030: Multi-Thread Export
**Story ID**: TICKET-030  
**Context/Layer**: Export / interface  
**As a** user  
**I want to** export multiple threads at once  
**So that** I can backup or analyze related journals together  

**Acceptance Criteria**:
1. "Select" mode in thread list
2. Checkbox appears on each thread
3. Select all/none options
4. Export button shows count
5. Single CSV with thread names as sections
6. Or ZIP with multiple CSVs
7. Progress indicator for large exports
8. Cancel export option
- [Arch-Lint] Extend ExportUseCase
- [Coverage] Test multi-selection
- [Doc] Bulk actions UI

**Technical Implementation**:
- Update ThreadListViewModel for selection
- Extend ExportThreadUseCase
- Create ZIP functionality
- Progress reporting

**QA Test Criteria**:
1. Test selection UI
2. Export 50+ threads
3. Verify ZIP format
4. Test cancellation

**Priority Score**: 3 (WSJF) - Power user feature  
**Dependencies**: TICKET-014 (Export base)

### TICKET-031: All Entries Timeline View
**Story ID**: TICKET-031  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want to** view all my entries in a single timeline  
**So that** I can see my complete journaling history chronologically  

**Acceptance Criteria**:
1. "Timeline" tab in main navigation
2. All entries from all threads in one list
3. Sorted by timestamp (newest first)
4. Thread name shown with each entry
5. Tap entry to go to thread context
6. Same entry UI as thread detail
7. Search/filter within timeline
8. Performance with 10k+ entries
9. Pull to refresh
- [Arch-Lint] TimelineViewModel in application
- [Coverage] Test performance
- [Doc] Timeline navigation

**Technical Implementation**:
- Create GetAllEntriesUseCase
- Implement pagination
- Create TimelineView
- Add tab navigation

**QA Test Criteria**:
1. Test with many entries
2. Verify navigation
3. Test performance
4. Memory usage testing

**Priority Score**: 5 (WSJF) - Useful overview  
**Dependencies**: None

---

## Epic 11: UI Enhancements

### TICKET-032: Pull-to-Refresh
**Story ID**: TICKET-032  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want to** pull down to refresh my thread list  
**So that** I can ensure I'm seeing the latest data  

**Acceptance Criteria**:
1. Standard iOS pull-to-refresh gesture
2. Loading indicator while refreshing
3. Haptic feedback on trigger
4. Refreshes thread list from repository
5. Maintains scroll position after refresh
6. Works in both thread list and timeline
- [Arch-Lint] Refresh logic in ViewModel
- [Coverage] Test refresh behavior
- [Doc] Standard iOS pattern

**Priority Score**: 2 (WSJF) - Minor enhancement  
**Dependencies**: None

### TICKET-033: Long Entry Truncation
**Story ID**: TICKET-033  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want** long entries to be truncated in the list view  
**So that** I can see more entries at once without excessive scrolling  

**Acceptance Criteria**:
1. Entries > 5 lines show "Show more"
2. Tap expands inline (no navigation)
3. "Show less" to collapse
4. Smooth animation
5. Setting to disable truncation
6. Remember expanded state in session
- [Arch-Lint] UI state in View
- [Coverage] Test expand/collapse
- [Doc] Truncation patterns

**Priority Score**: 3 (WSJF) - UI improvement  
**Dependencies**: TICKET-024 (Settings)

---

## Implementation Priority Matrix

### High Priority (Do First)
1. TICKET-024: Settings Page (enables others)
2. TICKET-023: Biometric Security (user requested)
3. TICKET-026: Search Functionality (high value)

### Medium Priority (Do Next)
4. TICKET-025: Entry Tags (with search)
5. TICKET-027: Archive Threads
6. TICKET-028: Delete Thread
7. TICKET-031: Timeline View

### Low Priority (Nice to Have)
8. TICKET-029: Templates
9. TICKET-030: Multi-Export
10. TICKET-032: Pull-to-Refresh
11. TICKET-033: Entry Truncation

---

## Technical Considerations

### Core Data Migrations
- v1.2: Add tags to Entry
- v1.3: Add isArchived to Thread
- v1.4: Add Template entity

### Performance Targets
- Search: < 100ms for 10k entries
- Timeline: < 200ms initial load
- Tag extraction: < 50ms per entry

### Security Notes
- Biometric auth at app level only
- No encryption of journal data
- Settings in UserDefaults (non-sensitive)



