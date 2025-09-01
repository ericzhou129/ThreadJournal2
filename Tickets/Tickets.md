# ThreadJournal Tickets

## Overview
This document provides tickets for implementing ThreadJournal. All Claude Code agents must follow these criteria. 

## Architecture Alignment
From the TIP, we have these bounded contexts and layers:
- **Contexts**: Journaling Context, AI Context, Export Context, Settings Context, Queue Context
- **Layers**: domain/, application/, interface/, infrastructure/

## Active Epics
- [Voice Entry Feature Epic](voice-entry-EPIC.md) - On-device voice transcription (TICKET-025 through TICKET-030)
- [Quick Entry Feature Epic](quick-entry-EPIC.md) - AI-powered rapid thought capture (TICKET-031 through TICKET-040)
- [Settings Configuration Epic](settings-configuration-EPIC.md) - User preferences and security
- [Custom Fields Epic](templated-fields-EPIC.md) - Structured data entry
- [Location Tracking Epic](location-tracking-EPIC.md) - Geographic context for entries

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

## Voice Entry Feature Tickets

### TICKET-025: Simplified Audio Capture Service
**Status**: DONE  
**Priority**: High  
**Size**: M  
**Layer**: Infrastructure  

#### Description
Implement a streamlined audio capture service for inline voice recording. No settings or configuration needed - it just works. Recording continues through silences (no auto-stop).

#### Technical Requirements
- Configure AVAudioSession with PlayAndRecord category
- Setup AVAudioEngine with 44.1kHz sampling rate, mono channel
- Simple start/stop recording interface
- Basic audio level metering for waveform visualization
- Handle interruptions gracefully (pause/resume)
- NO auto-stop on silence (people need time to think)
- Safety timeout only after 5 minutes of complete silence

#### Acceptance Criteria
- [ ] Microphone permission requested on first use
- [ ] Audio recording starts/stops immediately
- [ ] Audio levels update in real-time for waveform
- [ ] Recording continues through pauses and silences
- [ ] Only stops when user manually presses stop button
- [ ] Safety stop after 5 minutes of silence (edge case)
- [ ] Interruptions auto-pause recording
- [ ] Returns audio buffer for transcription

#### Implementation Tasks
1. Simplify existing `AudioCaptureService` in `Infrastructure/Audio/`
2. Remove unnecessary configuration options
3. Add permission handling in Info.plist
4. Implement single transcription on stop
5. Add simple interruption handling

#### Dependencies
- None (foundational component)

#### QA Test Criteria
- Test microphone permission flow
- Test interruption by phone call
- Test recording start/stop responsiveness
- Verify audio quality for transcription

---

### TICKET-026: WhisperKit Bundle Integration
**Status**: DONE  
**Priority**: High  
**Size**: L  
**Layer**: Infrastructure  

#### Description
Integrate WhisperKit for on-device speech recognition. Implemented with Path B approach - model downloads automatically on first use and caches for offline operation.

#### Technical Requirements
- Add WhisperKit via Swift Package Manager
- Use openai_whisper-small model (~216MB) with auto-download on first use
- Create `WhisperKitService` wrapper with real WhisperKit implementation
- Implement single transcription when recording stops
- Auto-detect language (multilingual model supports 99 languages)
- No auto-stop (user must manually stop)
- Safety timeout at 5 minutes of silence
- Optimize for Apple Neural Engine (ANE)

#### Acceptance Criteria
- [x] WhisperKit integrated via SPM
- [x] Model downloads automatically on first use
- [x] Transcription works offline after initial download
- [x] Single transcription provides final result when recording stops
- [x] Continues recording through silences (no auto-stop)
- [x] Safety stop only after 5 minutes of complete silence
- [x] Handles multiple languages automatically

#### Implementation Tasks
1. ✅ Add WhisperKit SPM dependency to project.pbxproj
2. ✅ Implement automatic model download on first use (Path B)
3. ✅ Create `WhisperKitService` in `Infrastructure/ML/` with real WhisperKit
4. ✅ Implement single transcription on recording stop
5. ✅ Configure for ANE optimization
6. ✅ Handle transcription result array properly

#### Dependencies
- TICKET-025 (Audio Capture Service)

#### QA Test Criteria
- Test first launch experience (no downloads)
- Test transcription accuracy in English
- Test at least 2 other languages
- Verify single transcription accuracy
- Test recording continues through 30-second silence
- Test 5-minute safety timeout works
- Test manual stop button responsiveness

---

### TICKET-027: Inline Voice UI Integration
**Status**: DONE  
**Priority**: High  
**Size**: M  
**Layer**: Interface  

#### Description
Add voice recording UI directly to ThreadDetailView. Single button below text field, minimal waveform when recording with two stop options, no separate screens.

#### Technical Requirements
- Add full-width voice button below compose field
- Show minimal waveform visualization during recording
- Display recording status and waveform visualization
- Two stop buttons on waveform: pencil (Stop & Edit) and checkmark (Stop & Save)
- Stop & Edit: fills text field for editing before sending
- Stop & Save: instantly creates entry in thread (no edit step)
- Keep thread entries visible during recording
- Brief green highlight on new entry when using Stop & Save
- No modal screens or settings

#### Acceptance Criteria
- [ ] Voice button always visible below text field
- [ ] Tapping button starts recording immediately
- [ ] Waveform shows recording is active
- [ ] Transcription appears after user stops recording
- [ ] "Stop & Edit" button fills text field for editing
- [ ] "Stop & Save" button creates entry immediately
- [ ] Both stop buttons clearly visible but minimal
- [ ] Thread remains scrollable during recording

#### Implementation Tasks
1. Modify `ThreadDetailViewFixed` to add voice button
2. Create minimal `WaveformView` component
3. Add transcription preview area
4. Implement two-button stop UI (pencil and checkmark icons)
5. Add logic for Stop & Edit (fills text field)
6. Add logic for Stop & Save (creates entry directly)
7. Add green highlight animation for saved entries
8. Ensure recording continues through user pauses

#### Dependencies
- TICKET-025 (Audio Capture)
- TICKET-026 (WhisperKit Integration)

#### QA Test Criteria
- Test UI transitions (text → recording → text)
- Test with long transcriptions
- Verify thread remains interactive
- Test orientation changes while recording

---

### TICKET-028: Voice Recording State Management
**Status**: DONE  
**Priority**: Medium  
**Size**: S  
**Layer**: Application  

#### Description
Create simple state management for voice recording in ThreadDetailViewModel. Handle recording states, final transcription processing, and two different stop behaviors.

#### Technical Requirements
- Add recording state to ThreadDetailViewModel
- Handle start/stop recording logic
- Process final transcription when recording stops
- Stop & Edit: fill compose field with transcription
- Stop & Save: create entry directly without edit step
- Manage audio service lifecycle
- Track recording duration for 5-minute safety timeout

#### Acceptance Criteria
- [ ] Recording starts from voice button tap
- [ ] Recording only stops via Stop & Edit or Stop & Save buttons
- [ ] Final transcription processed when recording stops
- [ ] Stop & Edit fills compose field for editing
- [ ] Stop & Save creates entry immediately
- [ ] No auto-stop during normal pauses (up to 5 minutes)
- [ ] Proper cleanup on view dismissal
- [ ] Error states handled gracefully

#### Implementation Tasks
1. Extend `ThreadDetailViewModel` with voice state
2. Add recording start method
3. Add stopAndEdit() method (fills text field)
4. Add stopAndSave() method (creates entry)
5. Handle final transcription processing
6. Implement 5-minute safety timeout
7. Add error handling

#### Dependencies
- TICKET-025 (Audio Capture)
- TICKET-026 (WhisperKit Integration)
- TICKET-027 (UI Integration)

#### QA Test Criteria
- Test state transitions
- Test error scenarios
- Verify memory cleanup
- Test with view lifecycle events

---

### TICKET-029: Testing and Polish
**Status**: DONE  
**Priority**: Medium  
**Size**: M  
**Layer**: All  

#### Description
Comprehensive testing of the simplified voice entry feature. Ensure smooth experience with no configuration needed.

#### Technical Requirements
- Unit tests for audio capture service
- Unit tests for transcription service
- UI tests for voice button interaction
- Performance testing on various devices
- Polish animations and transitions

#### Acceptance Criteria
- [x] 80% test coverage for voice components
- [x] UI transitions are smooth
- [x] Works on iPhone 12 and newer
- [x] Transcription accuracy >90%
- [x] No memory leaks

#### Implementation Tasks
1. ✅ Write unit tests for AudioCaptureService
2. ✅ Write unit tests for WhisperKitService  
3. ✅ Create UI tests for voice flow
4. ✅ Performance profiling
5. ✅ Polish animations

#### Dependencies
- All other voice tickets

#### QA Test Criteria
- Test on iPhone 12, 14, 15
- Test 5-minute recordings
- Test with background noise
- Verify transcription accuracy

---

### TICKET-030: Documentation and Release
**Status**: DONE  
**Priority**: Low  
**Size**: S  
**Layer**: Documentation  

#### Description
Update documentation to reflect the simplified voice entry approach. Prepare for release.

#### Technical Requirements
- Update README with voice entry section
- Document zero-configuration approach
- Add troubleshooting guide
- Update app store description
- Prepare release notes

#### Acceptance Criteria
- [x] README includes voice entry usage
- [x] WhisperKit integration documented
- [x] App size increase documented (~216MB model download on first use)
- [x] Release notes highlight feature

#### Implementation Tasks
1. ✅ Implement real WhisperKit integration (not mock)
2. ✅ Configure automatic model download (Path B)
3. ✅ Remove ADD_WHISPERKIT_INSTRUCTIONS.md
4. ✅ Update code documentation
5. ✅ Commit changes with proper message

#### Dependencies
- All implementation tickets

#### QA Test Criteria
- Review documentation accuracy
- Test troubleshooting steps
- Verify feature description

---

