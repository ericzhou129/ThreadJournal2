# Quick Entry Feature Epic

## Epic Overview
Implement an AI-powered quick entry system that allows users to rapidly capture thoughts with intelligent thread routing and offline support.

## Epic Goals
- Enable frictionless thought capture across the app
- Provide AI-powered thread suggestions based on content
- Support offline entry queuing for processing when online
- Maintain architectural integrity while adding AI capabilities

## Dependencies
- Core journaling infrastructure (existing)
- API key management system (new)
- Embedding/ML services (new)

## Requirements

  Core Writing Experience Details

  Launch Behavior

  - App opens directly to writing view with keyboard already shown
  - Cursor blinking in text field, ready to type
  - No splash screen or thread list - straight to writing
  - Previous draft restored if app was interrupted

  Text Field Specifics

  - Starts at 3 lines tall, expands up to 80% of screen height
  - 18pt font size for comfortable reading while writing
  - 1.5x line height for breathing room
  - Subtle left margin (20pt) to avoid edge cramping
  - No character counter - keep it distraction-free

  Thread Selection Interaction

  Default: [AI icon] → [thinking animation] → "Work Thoughts"
  Manual:  Tap thread name → Bottom sheet slides up with thread list
           Selected thread shown as: [Pin icon] "Thread Name"

  AI Processing States

  1. Typing: No indication (don't distract)
  2. Stopped typing (0.5s): Subtle pulse animation on AI icon
  3. Suggestion ready: Thread name appears with confidence dot
    - Green = >85% confident
    - Yellow = 70-85%
    - Red/None = Will use "Other"
  4. Offline: Icon changes to offline indicator, shows "Select thread ↓"

  Thread Drawer Behavior

  - Trigger: Swipe from left edge OR tap subtle hamburger icon (top left)
  - Width: 75% of screen with dark overlay on remaining 25%
  - Content: Thread list + "New Thread" button at top
  - Dismiss: Tap overlay, swipe left, or X button
  - State: Maintains your writing when opened/closed

  Post-Send Confirmation

  Success: ✓ Added to [Thread Name]
           (Fades up from bottom, stays 2s, fades out)

  Queued:  ⏳ Queued for processing (offline)
           (Stays visible until connection restored)

  Critical Edge Cases

  Offline Behavior:
  - Entry stays in field with "No connection" banner
  - Manual thread selector becomes required (highlighted)
  - Can still send to manually selected thread
  - AI processing queued for when online

  Rapid Entry Mode:
  - After send, if user starts typing within 1s, skip confirmation
  - Allows stream-of-consciousness writing
  - Batch process AI suggestions

  Draft Protection:
  - Auto-save every 5 seconds
  - Restore on app restart
  - Warning if trying to close with unsaved content

  Visual Hierarchy (Zen Mode)

  1. Your text (largest, most prominent)
  2. Thread indicator (subtle, bottom)
  3. Send button (only when content exists)
  4. Everything else (hidden until needed)

  What We're NOT Including (Scope Control)

  - Thread statistics/analytics
  - Entry search from writing view
  - Rich text formatting
  - Tags or categories
  - Multiple entry selection
  - Export from zen mode

  This keeps the zen mode pure: Write → Send → Write again. Everything else is secondary and accessed intentionally.

---

## TICKETS

### TICKET-026: Quick Entry UI Container
**Story ID**: TICKET-026  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want** a floating quick entry box always available on the thread list screen  
**So that** I can quickly capture thoughts without navigating to a specific thread first  

**Acceptance Criteria**:
1. Floating container appears at bottom of ThreadListScreen with proper safe area handling
2. Container shows "Quick Entry" title in header
3. Auto-expanding text input with placeholder "What's on your mind?"
4. Send button (↑ icon) that's disabled when input is empty
5. AI suggestion area showing "AI will suggest thread" when empty
6. Container slides up/down with keyboard appearance/dismissal
7. Minimum height: 80pt, maximum height: 200pt (when expanded)
8. Proper shadow and rounded corners per design specs
- [Arch-Lint] SwiftUI view uses ViewModel for all logic
- [Coverage] UI test for keyboard handling
- [Doc] Component matches Design:v1.2/QuickEntryContainer

**Component Reference**:
- Design:v1.2/QuickEntryContainer
- Design:v1.2/QuickEntryInput
- Design:v1.2/QuickSendButton

**Technical Implementation**:
- Create `Interface/Components/QuickEntryView.swift`
- Use `@StateObject var viewModel: QuickEntryViewModel`
- Dynamic keyboard handling with `.keyboardAdaptive()` modifier
- Text input auto-expansion with height constraints
- Disabled state management for send button

**QA Test Criteria**:
1. Verify container appears at bottom of thread list
2. Test keyboard show/hide behavior
3. Test text input expansion up to maximum height
4. Test send button enable/disable based on content
5. Verify proper safe area handling on different devices
6. Test accessibility labels and Dynamic Type support

**Priority Score**: 10 (WSJF) - Core user interface  
**Dependencies**: None

---

### TICKET-027: AI Thread Suggestion Infrastructure
**Story ID**: TICKET-027  
**Context/Layer**: AI / infrastructure  
**As a** developer  
**I want** embedding-based thread suggestion infrastructure  
**So that** the app can intelligently route quick entries to appropriate threads  

**Acceptance Criteria**:
1. EmbeddingService protocol with generateEmbedding(text) method
2. ThreadSuggestionService protocol with suggestThread(content, threads) method
3. Configuration support for multiple embedding providers (OpenAI, local CoreML)
4. Embedding caching to avoid duplicate API calls for similar content
5. Fallback to "Other" thread when confidence is low (<70%)
6. Service responds within 2 seconds or times out gracefully
7. No API calls made for content shorter than 10 characters
- [Arch-Lint] Infrastructure layer only, no UI imports
- [Coverage] 100% unit test coverage with mocked dependencies
- [Doc] Service contracts documented in TIP Section 6.3

**Implementation Guide**:
```swift
// EmbeddingService protocol
func generateEmbedding(text: String) async throws -> [Float]

// ThreadSuggestionService protocol  
func suggestThread(content: String, availableThreads: [Thread]) async throws -> ThreadSuggestion
```

**QA Test Criteria**:
1. Test embedding generation for various text lengths
2. Test timeout handling (>2 seconds)
3. Test caching behavior for duplicate content
4. Test fallback to "Other" thread with low confidence
5. Mock API failures and verify graceful degradation
6. Performance test with 20+ threads

**Priority Score**: 9 (WSJF) - Critical AI infrastructure  
**Dependencies**: TICKET-028 (API key management)

---

### TICKET-028: API Key Management and Configuration
**Story ID**: TICKET-028  
**Context/Layer**: Settings / infrastructure  
**As a** user  
**I want** to configure AI services with my own API keys  
**So that** I can use quick entry suggestions while maintaining control over my data and costs  

**Acceptance Criteria**:
1. Settings screen section for "AI Features" with toggle for Enable AI Suggestions
2. Secure API key input field for OpenAI API key (masked input)
3. API key validation with test connection button
4. API key stored securely in iOS Keychain (not UserDefaults)
5. Clear indication when AI features are disabled (no API key)
6. Option to disable AI suggestions entirely (falls back to "Other" thread)
7. Error handling for invalid/expired API keys with user-friendly messages
- [Arch-Lint] Settings context with secure storage
- [Coverage] Integration test for keychain storage
- [Doc] Security practices documented

**Component Reference**:
- Design:v1.2/SettingsAISection
- Secure input field with visibility toggle

**Technical Implementation**:
- Extend `Interface/Screens/SettingsScreen.swift` with AI section
- Create `Infrastructure/Security/APIKeyManager.swift`
- Use iOS Keychain Services for secure storage
- Add validation endpoint call to verify API key

**QA Test Criteria**:
1. Test API key input with masking/revealing
2. Test keychain storage and retrieval
3. Test API key validation with invalid key
4. Test toggle behavior (enable/disable AI features)
5. Verify API key not stored in app backups
6. Test error messages for various failure scenarios

**Priority Score**: 9 (WSJF) - Required for AI functionality  
**Dependencies**: None

---

### TICKET-029: Quick Entry ViewModel and Business Logic
**Story ID**: TICKET-029  
**Context/Layer**: Journaling / application  
**As a** developer  
**I want** QuickEntryViewModel to orchestrate AI suggestions and entry creation  
**So that** users get intelligent thread routing with proper error handling  

**Acceptance Criteria**:
1. QuickEntryViewModel manages text input, AI suggestions, and entry submission
2. Real-time thread suggestion as user types (debounced by 500ms)
3. Loading states for AI suggestion requests
4. Graceful fallback when AI services are unavailable
5. Validation of entry content before submission
6. Success feedback and input clearing after successful entry creation
7. Error handling with user-friendly error messages
8. Integration with offline queue when network unavailable
- [Arch-Lint] Application layer with proper dependency injection
- [Coverage] 95% unit test coverage including error scenarios
- [Doc] State management patterns documented

**Implementation Guide**:
```swift
@MainActor
final class QuickEntryViewModel: ObservableObject {
    @Published var currentText: String = ""
    @Published var suggestedThread: Thread?
    @Published var isLoadingSuggestion: Bool = false
    @Published var error: QuickEntryError?
    
    func submitEntry() async
    func onTextChanged() // debounced suggestion request
}
```

**QA Test Criteria**:
1. Test text input debouncing (500ms delay)
2. Test AI suggestion loading states
3. Test successful entry creation and cleanup
4. Test error handling for various failure modes
5. Test offline queue integration
6. Performance test with rapid text changes

**Priority Score**: 8 (WSJF) - Core business logic  
**Dependencies**: TICKET-027, TICKET-030

---

### TICKET-030: Offline Queue Management System
**Story ID**: TICKET-030  
**Context/Layer**: Journaling / infrastructure  
**As a** user  
**I want** my quick entries to be queued when offline  
**So that** I never lose thoughts even without internet connectivity  

**Acceptance Criteria**:
1. OfflineQueueService stores entries locally when network unavailable
2. Queue badge shows number of pending entries in QuickEntry header
3. Automatic processing of queued entries when connectivity restored
4. Persistent storage survives app restarts
5. FIFO processing order with retry logic for failures
6. Visual feedback during queue processing
7. Maximum queue size of 50 entries with oldest-first eviction
8. Queue entries include timestamp and original text content
- [Arch-Lint] Infrastructure layer with Core Data persistence
- [Coverage] Integration tests for network scenarios
- [Doc] Queue processing logic documented

**Component Reference**:
- Design:v1.2/QueueBadge
- Design:v1.2/OfflineIndicator

**Technical Implementation**:
- Create `Infrastructure/Queue/OfflineQueueService.swift`
- Core Data entity for QueuedEntry
- Network reachability monitoring
- Background processing when app becomes active

**QA Test Criteria**:
1. Test entry queuing when offline
2. Test automatic processing when back online
3. Test queue persistence across app restarts
4. Test queue badge count accuracy
5. Test maximum queue size enforcement
6. Test retry logic for failed processing

**Priority Score**: 7 (WSJF) - Important UX feature  
**Dependencies**: None

---

### TICKET-031: Thread Suggestion Display and Interaction
**Story ID**: TICKET-031  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want** clear visual feedback about which thread my entry will go to  
**So that** I can confirm or adjust the AI's suggestion before submitting  

**Acceptance Criteria**:
1. Thread suggestion appears below text input with "→ [Thread Name]" format
2. AI icon (green dot) indicates when suggestion is from AI
3. Loading indicator during suggestion processing
4. Tap suggestion to manually select different thread
5. Thread picker sheet shows all available threads with search
6. "Other" thread suggestion for uncertain matches
7. Offline indicator when network unavailable
8. Smooth animations for suggestion state changes
- [Arch-Lint] SwiftUI view with proper state management
- [Coverage] UI test for thread selection flow
- [Doc] Component matches Design:v1.2/ThreadSuggestion

**Component Reference**:
- Design:v1.2/ThreadSuggestion
- Design:v1.2/ThreadPicker
- Design:v1.2/AIIndicator

**Technical Implementation**:
- Create `Interface/Components/ThreadSuggestionView.swift`
- Thread picker sheet with search functionality
- State animations with proper timing
- Accessibility support for suggestion interactions

**QA Test Criteria**:
1. Test suggestion display with various thread names
2. Test loading states and animations
3. Test thread picker sheet presentation and selection
4. Test manual thread override functionality
5. Test offline indicator appearance
6. Verify Dynamic Type support for thread names

**Priority Score**: 6 (WSJF) - UI polish feature  
**Dependencies**: TICKET-026, TICKET-029

---

### TICKET-032: AI Service Integration and Configuration
**Story ID**: TICKET-032  
**Context/Layer**: AI / infrastructure  
**As a** developer  
**I want** production-ready AI service integration  
**So that** thread suggestions work reliably with proper error handling and performance  

**Acceptance Criteria**:
1. OpenAI API integration for text embeddings
2. Rate limiting and quota management
3. Request/response caching with TTL (time-to-live)
4. Circuit breaker pattern for service resilience
5. Metrics collection for AI service performance
6. Configuration for embedding model selection
7. Proper error classification (network, API, quota, etc.)
8. Service health monitoring and fallback strategies
- [Arch-Lint] Infrastructure layer following repository pattern
- [Coverage] Integration tests with API mocking
- [Doc] Service architecture documented in TIP

**Implementation Guide**:
```swift
final class OpenAIEmbeddingService: EmbeddingService {
    func generateEmbedding(text: String) async throws -> [Float]
    // Rate limiting, caching, circuit breaker logic
}
```

**QA Test Criteria**:
1. Test API integration with valid requests
2. Test rate limiting behavior
3. Test caching effectiveness
4. Test circuit breaker activation/recovery
5. Test various error scenarios
6. Performance test with concurrent requests

**Priority Score**: 8 (WSJF) - Production reliability  
**Dependencies**: TICKET-027, TICKET-028

---

### TICKET-033: Thread List Integration and Entry Routing
**Story ID**: TICKET-033  
**Context/Layer**: Journaling / domain  
**As a** developer  
**I want** seamless integration between quick entry and existing thread management  
**So that** entries created via quick entry appear correctly in their target threads  

**Acceptance Criteria**:
1. QuickEntryUseCase creates entries in suggested threads
2. Thread list updates immediately when quick entry submitted
3. Entry timestamp and metadata preserved correctly
4. Integration with existing thread creation if suggested thread doesn't exist
5. Proper error handling for thread access failures
6. Entry content validation consistent with manual entry creation
7. Thread update timestamp refreshed when quick entry added
8. Support for entry creation with location data if enabled
- [Arch-Lint] Domain layer with clean use case pattern
- [Coverage] 100% unit test coverage for entry routing
- [Doc] Business rules documented

**Implementation Guide**:
```swift
final class QuickEntryUseCase {
    func execute(content: String, suggestedThreadId: UUID?) async throws -> Entry
    // Route to suggested thread or create new thread
}
```

**QA Test Criteria**:
1. Test entry creation in existing thread
2. Test new thread creation when needed
3. Test thread list refresh after entry creation
4. Test integration with location services
5. Test error handling for invalid thread IDs
6. Verify entry ordering and timestamps

**Priority Score**: 7 (WSJF) - Integration requirement  
**Dependencies**: TICKET-029, existing thread management

---

### TICKET-034: Performance Optimization and Caching
**Story ID**: TICKET-034  
**Context/Layer**: AI / infrastructure  
**As a** developer  
**I want** optimized performance for AI suggestions and caching  
**So that** quick entry feels instantaneous and doesn't consume excessive API quota  

**Acceptance Criteria**:
1. LRU cache for embeddings with configurable size (default 100 entries)
2. Similarity threshold for reusing cached embeddings (>95% similar)
3. Background pre-computation of thread embeddings
4. Request deduplication for identical content
5. Lazy loading of AI services (initialize on first use)
6. Memory pressure handling with cache eviction
7. Performance metrics: <100ms for cached suggestions, <2s for new suggestions
8. Efficient similarity computation using cosine distance
- [Arch-Lint] Infrastructure layer with proper memory management
- [Coverage] Performance tests with cache scenarios
- [Doc] Caching strategy documented

**Implementation Guide**:
```swift
final class EmbeddingCache {
    func getCachedEmbedding(text: String) -> [Float]?
    func cacheEmbedding(text: String, embedding: [Float])
    func evictLeastRecentlyUsed()
}
```

**QA Test Criteria**:
1. Test cache hit/miss scenarios
2. Test memory pressure handling
3. Test similarity threshold accuracy
4. Performance test with various cache sizes
5. Test background thread embedding computation
6. Verify no memory leaks in cache implementation

**Priority Score**: 5 (WSJF) - Performance optimization  
**Dependencies**: TICKET-027, TICKET-032

---

### TICKET-035: Comprehensive Testing and Error Recovery
**Story ID**: TICKET-035  
**Context/Layer**: AI / application  
**As a** developer  
**I want** comprehensive test coverage and error recovery for AI features  
**So that** quick entry works reliably across all network and API scenarios  

**Acceptance Criteria**:
1. Unit tests for all AI service components (>95% coverage)
2. Integration tests with mocked API responses
3. Error recovery tests (network failures, API errors, quota exceeded)
4. Performance tests with realistic thread counts (20+ threads)
5. UI tests for complete quick entry workflow
6. Accessibility tests for all new components
7. Memory leak detection for AI service components
8. Stress testing with rapid entry creation
- [Arch-Lint] Test files follow naming conventions
- [Coverage] Comprehensive test coverage report
- [Doc] Testing strategy documented

**Test Categories**:
- Unit: Individual service components
- Integration: API interactions with mocks
- UI: Complete user workflows
- Performance: Response times and memory usage
- Accessibility: VoiceOver and Dynamic Type

**QA Test Criteria**:
1. All unit tests pass consistently
2. Integration tests cover error scenarios
3. UI tests work on different device sizes
4. Performance tests meet defined targets
5. Accessibility tests pass with VoiceOver
6. No memory leaks detected in Instruments

**Priority Score**: 6 (WSJF) - Quality assurance  
**Dependencies**: All previous tickets

---

## Epic Summary

**Total Tickets**: 10  
**Estimated Effort**: 25-30 story points  
**Key Risks**: 
- AI API reliability and costs
- Performance with large thread counts
- Offline/online state management complexity

**Success Metrics**:
- 90%+ quick entries routed to correct threads
- <2 second response time for AI suggestions
- Zero data loss in offline scenarios
- User adoption of quick entry over manual thread selection

**Implementation Phases**:
1. **Phase 1**: UI and basic infrastructure (TICKET-026, TICKET-028, TICKET-030)
2. **Phase 2**: AI services and integration (TICKET-027, TICKET-032, TICKET-029)
3. **Phase 3**: Advanced features and optimization (TICKET-031, TICKET-033, TICKET-034)
4. **Phase 4**: Testing and polish (TICKET-035)
