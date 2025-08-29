# Voice Entry Feature Epic

## Epic Overview
**Epic ID**: EPIC-003  
**Epic Name**: Voice-to-Text Entry  
**Priority**: High  
**Status**: In Development  
**Target Release**: v2.0  

## Business Value
Enable users to create journal entries through voice dictation, making journaling more accessible and convenient. This feature uses on-device transcription to maintain complete privacy while providing a seamless voice-to-text experience.

## User Story
As a ThreadJournal user, I want to speak my journal entries instead of typing them, so that I can capture thoughts more quickly and naturally, especially when typing is inconvenient.

## Success Criteria
- [ ] Users can record voice and see real-time transcription
- [ ] All processing happens on-device (no cloud calls)
- [ ] Recording continues through pauses (no auto-stop)
- [ ] Two stop options: Stop & Edit and Stop & Save
- [ ] <2 second latency to transcription chunks on modern devices (A16+)
- [ ] Multilingual transcription support
- [ ] Model bundled with app (no download needed)
- [ ] Voice entries integrate seamlessly with existing thread system

## Technical Requirements

### Core Components
1. **WhisperKit Integration**: Use WhisperKit framework for Core ML-based transcription
2. **Model**: Whisper Small multilingual (39MB) bundled with app
3. **Audio Pipeline**: AVAudioSession (PlayAndRecord) → AVAudioEngine → WhisperKit
4. **Chunked Transcription**: 2-second chunks for live feedback
5. **No Auto-Stop**: Recording continues through pauses (5-minute safety limit)
6. **Dual Stop Options**: Stop & Edit (fill text field) or Stop & Save (instant entry)

### Architecture Alignment
- **Voice Context**: New bounded context in Domain layer
- **Infrastructure/Audio**: AudioCaptureService, AudioSessionManager
- **Infrastructure/ML**: ModelManager, WhisperKitService, ModelDownloadService
- **Application/Services**: TranscriptionService
- **Interface/Components**: VoiceEntryView, WaveformVisualizer, ModelDownloadView

## Tickets Breakdown

### Phase 1: Core Infrastructure
- **TICKET-025**: Simplified Audio Capture Service
  - AudioCaptureService with no auto-stop
  - AVAudioSession configuration
  - 5-minute safety timeout only
  - Interruption handling

### Phase 2: ML Integration
- **TICKET-026**: WhisperKit Bundle Integration
  - WhisperKit SPM dependency
  - Bundle Whisper Small model in app
  - 2-second chunk transcription
  - No download needed

### Phase 3: UI Implementation
- **TICKET-027**: Inline Voice UI Integration
  - Voice button in ThreadDetailView
  - Minimal waveform visualization
  - Two stop buttons (Edit vs Save)
  - Live transcription preview

- **TICKET-028**: Voice Recording State Management
  - Recording state in ViewModel
  - Stop & Edit logic (fill text field)
  - Stop & Save logic (instant entry)
  - Transcription chunk handling

### Phase 4: Testing & Polish
- **TICKET-029**: Testing and Polish
  - Unit tests for all services
  - UI transition polish
  - Performance verification

- **TICKET-030**: Documentation and Release
  - Update documentation
  - Release notes
  - Troubleshooting guide

## Dependencies
- iOS 17+ (for latest AVAudioEngine features)
- WhisperKit framework (via SPM)
- Existing Quick Entry system (for thread suggestions)
- Settings infrastructure (for voice preferences)

## Risks & Mitigations

### Risk 1: Model Download Size
**Impact**: High - Users may be reluctant to download 39MB model  
**Mitigation**: 
- Clear communication about one-time download
- Show benefits during download
- Allow deletion to free space

### Risk 2: Performance on Older Devices
**Impact**: Medium - Slower transcription on older chips  
**Mitigation**:
- Test on iPhone 12 minimum
- Implement quality settings
- Show device compatibility warnings

### Risk 3: Audio Interruptions
**Impact**: Medium - Calls/notifications interrupt recording  
**Mitigation**:
- Robust interruption handling
- Auto-save partial transcriptions
- Clear recovery UI

### Risk 4: Battery Impact
**Impact**: Medium - Continuous recording drains battery  
**Mitigation**:
- Auto-stop on silence (VAD)
- Efficient buffer sizes
- Background processing limits

## Acceptance Tests

### Functional Tests
1. **First-Time Setup**
   - User prompted to download model
   - Progress shown during download
   - Model persists across app launches

2. **Recording Flow**
   - Microphone permission requested
   - Recording starts/stops correctly
   - Partial results appear in <1s
   - Final transcription is accurate

3. **Thread Integration**
   - Voice entries appear in threads
   - Thread suggestions work
   - Entries marked with voice indicator

4. **Error Handling**
   - Graceful handling of permission denial
   - Network failure during model download
   - Insufficient storage space
   - Microphone conflicts

### Performance Tests
1. **Latency**: <1s to first partial on A16+
2. **Accuracy**: 95%+ for clear speech
3. **Memory**: <50MB additional during recording
4. **Battery**: <5% drain for 10min recording

### Device Compatibility
- iPhone 12 and newer: Full functionality
- iPhone 11 and older: Reduced quality mode
- iPad: Full support with enhanced UI

## UI/UX Specifications
See [Design Mockup](../Design/voice-entry-mockup.html) for detailed designs.

### Key Interactions
1. **Entry Points**
   - Microphone button in compose bar
   - Quick Entry voice mode
   - Settings → Voice Entry

2. **Recording Modes**
   - Hold-to-record: For quick thoughts
   - Tap-to-record: For longer entries

3. **Visual Feedback**
   - Waveform animation during recording
   - Pulsing record button
   - Real-time transcription display

## Implementation Timeline

### Week 1-2: Infrastructure
- Audio capture setup
- WhisperKit integration
- Basic transcription working

### Week 3: Model Management
- Download system
- Progress tracking
- Storage management

### Week 4: UI Implementation
- Recording interface
- Settings screen
- Integration with threads

### Week 5: Polish & Testing
- Performance optimization
- Comprehensive testing
- Bug fixes

## Success Metrics
- **Adoption**: 40% of users try voice entry within first week
- **Retention**: 25% regular voice entry users after 1 month
- **Performance**: 95% successful transcriptions
- **Satisfaction**: 4.5+ star rating for feature

## Related Documents
- [Technical Implementation Plan](../Engineering/Technical-Implementation-Plan.md)
- [Voice Entry Design Mockup](../Design/voice-entry-mockup.html)
- [Quick Entry Epic](quick-entry-EPIC.md)

## Notes for Implementation
- Prioritize privacy - no telemetry on audio content
- Consider future: Medium model as optional upgrade
- Plan for offline-first operation
- Integrate with existing draft system
- Support undo/redo for transcriptions