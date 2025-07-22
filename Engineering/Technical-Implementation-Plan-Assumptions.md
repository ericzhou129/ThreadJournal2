## This document records assumptions used in the Technical Implementation plan

### Phase Planning Context
- **Phase 1**: Core journaling functionality (current TIP)
- **Phase 2**: Edit/delete, attachments, iCloud sync
- **Phase 3**: Security, tags, backup, telemetry, speech-to-text

---

1. Local-First Architecture

  - Assumption: No cloud sync or backup capabilities
  - Impact: Users cannot access journals across devices or recover
   data if device is lost
  - Alternative: Could add iCloud sync in Phase 2
  
  Stakeholder commentary: Local-first for now. IN phase 2 we will add icloud sync.
  
  **Engineering Decision**: Keep repository pattern clean to swap implementations later 

  2. Security Model

  - Assumption: All entries are encrypted at rest using
  device-level encryption
  - Impact: Performance overhead for large threads, potential data
   recovery issues
  - Alternative: Optional encryption per thread or unencrypted
  storage
  
    Stakeholder commentary: I think eventually we will want to focus more on security, but this let's leave for phase 3'
    
  **Engineering Decision**: Phase 1 uses iOS default file protection only. No custom encryption. 

  3. iOS 17+ Requirement

  - Assumption: Latest SwiftUI features justify excluding older
  iOS versions
  - Impact: ~15-20% of iOS users on older versions cannot use the
  app
  - Alternative: iOS 16+ support with feature degradation
  
    Stakeholder commentary: Let's go with iOS 17+

  4. No User Profiles/Authentication

  - Assumption: Single user per device, no multi-user support
  - Impact: Shared devices (family iPads) cannot separate journals
  - Alternative: Local profiles without cloud auth
  
    Stakeholder commentary: Single user per device, correct. 

  5. Text-Only Entries

  - Assumption: No image, audio, or drawing support
  - Impact: Limited expression options for visual thinkers
  - Alternative: Rich media support would require different
  storage strategy
  
    Stakeholder commentary: In phase 2 I'm thinking of adding file attachment and photo attachment. In a later phase 3 we will also add speech to text so the user presses a button to transcribe their speech into journal entry.
    
  **Engineering Decision**: Keep Entry.content as String for Phase 1. No attachment fields. 

  6. Thread Organization Model

  - Assumption: Threads are the only organizational unit (no
  folders, tags, categories)
  - Impact: May become unwieldy with many threads
  - Alternative: The tickets mention tags as a Phase 2 feature
  
    Stakeholder commentary: In phase 3 we may add the idea of 'tags'

  7. Export Format

  - Assumption: CSV is sufficient for data portability
  - Impact: Loss of formatting, no re-import capability
  - Alternative: JSON or markdown export for richer data
  
    Stakeholder commentary: Let's add JSON as well so that we can support imports and backups. I will want to create a backup functionality in phase 3 that allows us to backup the entire journal (every thread)
    
  **Engineering Decision**: Phase 1 implements CSV only. Add JSON export protocol for easy extension.

  8. Performance Targets

  - Assumption: 50 entries loaded at once, 1000 entries max for
  export
  - Impact: Power users with very long threads may experience
  degradation
  - Alternative: Streaming architecture for unlimited entries
  
    Stakeholder commentary: Well what if a user has more than 50 entries in a thread? Will the thread load as they scroll? 1000 entries max for a single file, if there are more than 1000 entries in a thread can we break this down into multiple files? What is 1000 entries based on filesize? I like the idea of a streaming architecture for unlimited entries.
    
  **Engineering Decision**: Phase 1 loads ALL entries (no pagination). Typical thread ~20-100 entries. If performance issues arise, add lazy loading in Phase 1.1. CSV export chunks at 10MB file size. 
  
    Stakeholder commentary 2: what if 1000 entries is a reasonable assumption and assume each entries is 5 lines of text across an iphone screen?
    
  **Updated Engineering Decision**: 1000 entries × 5 lines × ~50 chars = ~250KB text. This is fine to load all at once. Keep simple "load all" approach. Only optimize if actual performance issues.
  

  9. No Analytics

  - Assumption: Zero telemetry or usage tracking
  - Impact: No data to guide feature development or debug issues
  - Alternative: Privacy-preserving local analytics
  
    Stakeholder commentary: In phase 3, we can consider telemetry as long as it respects privacy. 

  10. Entry Immutability

  - Assumption: Entries cannot be edited after creation (not
  mentioned in tickets)
  - Impact: Users cannot correct typos or update thoughts
  - Alternative: Edit with history tracking
  
    Stakeholder commentary: Entries will need to be able to be deleted and edited in phase 2. In fact entire threads will be allowed to be deleted.
    
  **Engineering Decision**: Phase 1 entries are immutable. No edit/delete UI or logic.
  
    Stakeholder commentary 2: can this be changed when we get to phase 2? Why not do it now?
    
  **Response**: Yes, easily changed in Phase 2. Not doing now because: 1) Keeps Phase 1 focused on core journaling, 2) Edit/delete adds UI complexity (swipe actions, confirmation dialogs), 3) Need to decide on edit history tracking. Clean architecture makes this easy to add later.

11. Thread Ordering

  - Assumption: Threads ordered by last updated time only
  - Impact: No manual sorting or pinning favorite threads
  - Alternative: Custom sort options, pin to top
  
  **Engineering Decision**: Simple lastUpdated sort only. No user preferences.
  
    Stakeholder commentary 2: We will want pin to top in phase 2. Or pin to some special access place.
    
  **Response**: Good to know. Thread entity won't need a "isPinned" field in Phase 1. Will add in Phase 2 with minimal schema change. 

12. Entry Timestamps

  - Assumption: System-generated timestamps only, no manual date entry
  - Impact: Cannot backdate entries or journal for previous days
  - Alternative: Allow date picker for entry creation
  
  **Engineering Decision**: Auto-timestamp on creation. No manual dates.
  
    Stakeholder commentary 2: we may want to backdate in phase 3, let's just not make a irreversable decision here
    
  **Response**: Understood. Entry.timestamp will be a standard Date field that can accept any date. Phase 1 UI only sets "now", but data model supports any date for Phase 3.

13. Data Migration

  - Assumption: No migration needed for Phase 1
  - Impact: Phase 2 changes may require data migration
  - Alternative: Version schema from day 1
  
  **Engineering Decision**: Add schemaVersion field to Core Data from start.
  
    Stakeholder commentary 2: Phase 2 changes may require migration, let's be prepred for it
    
  **Response**: Agreed. Will implement Core Data versioning from day 1. Makes future migrations straightforward.

14. Thread Limits

  - Assumption: No limits on number of threads or entries
  - Impact: UI may degrade with 100+ threads
  - Alternative: Implement archiving or limits
  
  **Engineering Decision**: No limits. Monitor performance in testing.
  
    Stakeholder commentary 2: No limits correct, expect that a thread could have 1000+ entries. Expect there can be 100+ threads.
    
  **Response**: Will performance test with 100 threads × 1000 entries each. May need to implement lazy loading for thread list if 100+ threads cause lag. 

15. Keyboard Behavior

  - Assumption: Compose area expands to 50% screen max
  - Impact: Long entries need fullscreen mode
  - Alternative: Dynamic expansion based on content
  
  **Engineering Decision**: Implement expand button per ticket. Max 50% in inline mode.

16. FaceID/TouchID

  - Assumption: Optional biometric lock for whole app
  - Impact: Cannot lock individual threads
  - Alternative: Per-thread security
  
  **Engineering Decision**: Defer ALL biometric auth to Phase 2 per stakeholder comment.

17. Export Scope

  - Assumption: Export one thread at a time only
  - Impact: No bulk export in Phase 1
  - Alternative: Multi-select threads
  
  **Engineering Decision**: Single thread export only. Multi-thread export in Phase 2.

18. Import Functionality

  - Assumption: No import in Phase 1
  - Impact: Cannot restore from backup
  - Alternative: CSV import
  
  **Engineering Decision**: Export only. Import requires data validation complexity.
  
    Stakeholder commentary 2: will want to add import or restore from backup in phase 2.
    
  **Response**: Good. Export format (CSV) will include all necessary fields for clean re-import. Will design schema to support round-trip import/export. 

19. Settings Storage

  - Assumption: No user settings in Phase 1
  - Impact: No font size adjustment despite Dynamic Type
  - Alternative: Basic settings for accessibility
  
  **Engineering Decision**: Use system Dynamic Type. No app-specific settings.

20. Error Recovery

  - Assumption: Basic error alerts only
  - Impact: Data loss if save fails
  - Alternative: Retry logic and draft recovery
  
  **Engineering Decision**: Simple error alerts. Core Data handles basic persistence.
    Stakeholder commentary2: I think retry logic and draft recovery will be important even in phase 1, we don't want users to lose long texts they are typing. however, I want to keep the implementation simple and not bloated and lightweight/highly performant.
    
  **Updated Engineering Decision**: Implement auto-save draft in memory while typing (every 5 seconds). If save fails, show retry button. Keep draft until successfully saved. Simple but effective. 

---

### Summary for Phase 1 Scope

  Stakeholder commentary 2: take a look at my comments above and revise again as necessary. But yes focus is on phase 1. We can figure out phase 2 later, as long as we don't make one-way-door decisions'

**IN SCOPE:**
- Create, view threads
- Add entries to threads  
- Export single thread to CSV
- Basic error handling with retry
- Dynamic Type support
- Auto-save drafts (in memory)
- Performance support for 100+ threads, 1000+ entries per thread

**OUT OF SCOPE:**
- Edit/delete anything
- Attachments
- Security/encryption
- Settings
- Import
- Multi-thread operations
- iCloud sync
- Search functionality
- Tags
- Pin threads

### Key Architecture Decisions for Future-Proofing
1. **Core Data with version field** - Easy migrations
2. **Repository pattern** - Swap storage implementations
3. **Clean architecture** - Add features without breaking existing code
4. **Export includes all fields** - Enable round-trip import later
5. **No artificial limits** - Support power users from day 1
