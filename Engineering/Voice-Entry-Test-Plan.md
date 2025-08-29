# Voice Entry Feature - Manual Testing Plan

## Overview
This document outlines manual testing scenarios for the voice entry feature in ThreadJournal2. These tests should be performed on physical devices to ensure the feature works correctly in real-world conditions.

## Prerequisites
- Physical iOS device (iPhone/iPad) with microphone
- iOS 17.0 or later
- Microphone permission granted to the app
- Quiet testing environment for audio quality verification

## Test Categories

### 1. Basic Functionality Tests

#### 1.1 Voice Recording Button
**Scenario**: Verify voice recording button appears and functions correctly
- **Steps**:
  1. Open a thread detail view
  2. Look for the "Tap to speak" button below the compose field
  3. Tap the button
- **Expected**: 
  - Button has smooth animation on press
  - Recording UI appears with waveform visualization
  - Microphone permission is requested if not already granted

#### 1.2 Stop and Edit Workflow
**Scenario**: Record voice and edit the transcription
- **Steps**:
  1. Tap voice button to start recording
  2. Speak clearly for 5-10 seconds: "This is a test entry for my journal"
  3. Tap the pencil icon (Stop & Edit)
  4. Wait for transcription to appear
  5. Edit the text if needed
  6. Tap send button
- **Expected**:
  - Smooth transition from recording UI to compose field
  - Transcribed text appears in compose field
  - Text is editable before sending
  - Entry is created with the final text

#### 1.3 Stop and Save Workflow
**Scenario**: Record voice and save directly
- **Steps**:
  1. Tap voice button to start recording
  2. Speak clearly for 5-10 seconds: "Another test entry for direct saving"
  3. Tap the checkmark icon (Stop & Save)
  4. Wait for transcription and entry creation
- **Expected**:
  - Recording stops immediately
  - Entry is created automatically with transcribed text
  - User returns to thread view with new entry visible

### 2. Performance Tests

#### 2.1 Recording Startup Time
**Scenario**: Verify recording starts quickly
- **Steps**:
  1. Tap voice button
  2. Measure time until waveform animation begins
- **Expected**: Recording should start within 0.5 seconds

#### 2.2 Waveform Animation Smoothness
**Scenario**: Verify smooth waveform animation at 60fps
- **Steps**:
  1. Start recording
  2. Speak at various volumes (whisper, normal, loud)
  3. Observe waveform bars animation
- **Expected**:
  - Smooth animation without stuttering
  - Bars respond to audio levels in real-time
  - No visible lag or frame drops

#### 2.3 Long Recording Performance
**Scenario**: Test extended recording up to 5 minutes
- **Steps**:
  1. Start recording
  2. Speak intermittently for 4-5 minutes
  3. Monitor app performance and memory usage
  4. Stop recording normally
- **Expected**:
  - No performance degradation
  - Memory usage stays reasonable (<50MB increase)
  - App remains responsive throughout
  - Recording automatically stops at 5-minute limit

### 3. Edge Case Tests

#### 3.1 Microphone Permission Denied
**Scenario**: Test behavior when microphone access is denied
- **Steps**:
  1. Go to Settings > Privacy > Microphone
  2. Disable ThreadJournal2 microphone access
  3. Return to app and tap voice button
- **Expected**:
  - Clear error message about microphone permission
  - Option to go to Settings to enable permission
  - No app crash or frozen state

#### 3.2 Phone Call Interruption
**Scenario**: Test recording interruption by incoming call
- **Steps**:
  1. Start voice recording
  2. Have someone call your device during recording
  3. Answer the call
  4. End the call and return to app
- **Expected**:
  - Recording stops gracefully during call
  - No app crash
  - User can restart recording after call ends

#### 3.3 App Backgrounding During Recording
**Scenario**: Test behavior when app goes to background
- **Steps**:
  1. Start voice recording
  2. Press home button or switch to another app
  3. Wait 10-20 seconds
  4. Return to ThreadJournal2
- **Expected**:
  - Recording continues briefly in background (iOS allows short background recording)
  - Recording stops automatically after background limit
  - App state is preserved when returning

#### 3.4 Low Storage Space
**Scenario**: Test recording with insufficient storage
- **Steps**:
  1. Ensure device has very low storage (< 1GB)
  2. Attempt to start voice recording
  3. Record for an extended period
- **Expected**:
  - Graceful handling of storage errors
  - Clear error message to user
  - App doesn't crash

#### 3.5 Rapid Start/Stop Sequences
**Scenario**: Test rapid button presses
- **Steps**:
  1. Quickly tap voice button multiple times
  2. Start recording, immediately stop
  3. Repeat 5-6 times rapidly
- **Expected**:
  - No app crashes or undefined states
  - Each recording session is independent
  - UI state is correctly maintained

### 4. Audio Quality Tests

#### 4.1 Various Audio Levels
**Scenario**: Test recording at different volumes
- **Test Inputs**:
  - Whisper level speech
  - Normal conversation volume
  - Loud speech
  - Background noise with speech
- **Expected**:
  - All levels are captured appropriately
  - Waveform visualization responds to volume changes
  - Transcription quality remains good

#### 4.2 Different Speaking Styles
**Scenario**: Test various speech patterns
- **Test Inputs**:
  - Slow, clear speech
  - Fast speech
  - Speech with pauses
  - Multiple sentences
  - Questions and statements
- **Expected**:
  - All speech styles are captured
  - Transcription handles different patterns appropriately

#### 4.3 Ambient Noise Handling
**Scenario**: Test in various environments
- **Environments**:
  - Quiet room
  - Room with background music
  - Outdoor environment
  - Car with engine running
- **Expected**:
  - Recording captures primarily voice
  - Background noise doesn't prevent recording
  - Transcription quality degrades gracefully with noise

### 5. UI/UX Tests

#### 5.1 Transition Animations
**Scenario**: Verify smooth UI transitions
- **Steps**:
  1. Tap voice button (compose → recording)
  2. Tap Stop & Edit (recording → compose)
  3. Tap voice button again
  4. Tap Stop & Save (recording → thread view)
- **Expected**:
  - All transitions are smooth and spring-like
  - No jarring jumps or layout issues
  - Animations feel natural and responsive

#### 5.2 Visual Feedback
**Scenario**: Verify all visual elements work correctly
- **Elements to Test**:
  - Voice button press animation
  - Waveform bar animations
  - Stop button animations
  - Recording duration display
  - Transcription text updates
- **Expected**:
  - All animations are smooth
  - Visual feedback is immediate
  - No visual glitches or artifacts

#### 5.3 Accessibility
**Scenario**: Test with accessibility features enabled
- **Steps**:
  1. Enable VoiceOver
  2. Navigate to voice button
  3. Attempt to use voice recording
- **Expected**:
  - Voice button is accessible
  - Clear announcements for state changes
  - Recording can be stopped via accessibility

### 6. Device Compatibility Tests

#### 6.1 iPhone Models
**Test on various iPhone models**:
- iPhone 12/13/14/15 (A-series chips)
- Older models (iPhone XR, iPhone 11)
- Different screen sizes

#### 6.2 iPad Models
**Test on iPad devices**:
- iPad Air
- iPad Pro
- iPad mini

#### 6.3 iOS Versions
**Test on supported iOS versions**:
- iOS 17.0+
- Latest iOS version
- Beta versions (if available)

## Known Limitations

1. **WhisperKit Integration**: Currently using mock transcription service. Real transcription will be available after WhisperKit package integration.

2. **Background Recording**: iOS limits background audio recording to ~30 seconds for privacy reasons.

3. **Transcription Accuracy**: Accuracy depends on audio quality, speaking clarity, and background noise levels.

4. **Language Support**: Initial implementation supports English only. Additional languages may be added with WhisperKit.

5. **Device Performance**: Transcription performance varies by device capability and available memory.

## Test Completion Checklist

### Basic Functionality
- [ ] Voice button appears and responds
- [ ] Stop & Edit workflow works correctly
- [ ] Stop & Save workflow works correctly
- [ ] Recording duration displays accurately
- [ ] Audio levels visualization works

### Performance
- [ ] Recording starts within 0.5 seconds
- [ ] Waveform animates smoothly at 60fps
- [ ] Memory usage stays under limits
- [ ] Long recordings work properly
- [ ] 5-minute timeout functions correctly

### Edge Cases
- [ ] Permission denial handled gracefully
- [ ] Phone call interruption works correctly
- [ ] App backgrounding handled properly
- [ ] Low storage scenario tested
- [ ] Rapid start/stop sequences work

### Audio Quality
- [ ] Various volume levels captured
- [ ] Different speaking styles work
- [ ] Ambient noise handling verified

### UI/UX
- [ ] All animations are smooth
- [ ] Visual feedback is appropriate
- [ ] Accessibility features work

### Device Compatibility
- [ ] Tested on multiple iPhone models
- [ ] Tested on iPad devices
- [ ] Tested on different iOS versions

## Reporting Issues

When reporting issues, please include:
1. Device model and iOS version
2. Steps to reproduce
3. Expected vs actual behavior
4. Screenshots or screen recordings if applicable
5. Audio quality assessment if relevant

## Success Criteria

The voice entry feature is considered ready for production when:
- All basic functionality tests pass
- Performance meets specified benchmarks
- Edge cases are handled gracefully
- UI animations are smooth and responsive
- Feature works across target device range
- No critical or high-severity bugs remain