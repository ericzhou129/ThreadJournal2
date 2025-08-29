# Voice Entry API Documentation

## Overview

The voice entry system in ThreadJournal follows Clean Architecture principles with well-defined interfaces for audio capture, speech recognition, and coordination. This document describes the public APIs, integration points, and extension mechanisms.

## Architecture Layers

### Domain Layer
The domain layer defines the core protocols without any implementation details.

### Application Layer
Contains the coordination logic and use cases for voice entry.

### Infrastructure Layer  
Implements the actual audio capture and speech recognition services.

### Interface Layer
Provides SwiftUI components and view models for voice entry UI.

## Core Protocols

### AudioCaptureServiceProtocol

Protocol for managing audio recording functionality.

```swift
protocol AudioCaptureServiceProtocol {
    func startRecording() async throws
    func stopRecording() async throws -> Data
    func getAudioLevel() -> Float
    func getRecordingDuration() -> TimeInterval
    var isRecording: Bool { get }
}
```

#### Methods

**`startRecording() async throws`**
- Initiates audio recording session
- Configures audio session for recording
- Throws `AudioCaptureError` if recording cannot be started
- Requires microphone permission

**`stopRecording() async throws -> Data`**
- Stops active recording session
- Returns recorded audio data as PCM format
- Throws `AudioCaptureError` if stopping fails
- Clears audio buffers after returning data

**`getAudioLevel() -> Float`**
- Returns current audio input level (0.0 to 1.0)
- Used for real-time audio visualization
- Returns 0.0 when not recording
- Updates at ~10Hz during recording

**`getRecordingDuration() -> TimeInterval`**
- Returns total recording duration in seconds
- Starts from 0 when recording begins
- Continues until recording stops
- Used for displaying recording time

#### Properties

**`isRecording: Bool`**
- Indicates current recording state
- `true` during active recording
- `false` when stopped or not started
- Observable property for UI updates

### WhisperKitServiceProtocol

Protocol for speech recognition and transcription.

```swift
protocol WhisperKitServiceProtocol {
    func initialize() async throws
    func transcribeChunk(audio: Data) async throws -> String
    func transcribeAudio(audio: Data) async throws -> String
    func cancelTranscription() async
    var isInitialized: Bool { get }
}
```

#### Methods

**`initialize() async throws`**
- Initializes the speech recognition engine
- Loads bundled Whisper model from app bundle
- Sets up Core ML pipeline for transcription
- Throws `WhisperKitServiceError` if initialization fails

**`transcribeChunk(audio: Data) async throws -> String`**
- Transcribes a short audio chunk (typically 2 seconds)
- Returns partial transcription results
- Used for real-time transcription updates
- Optimized for low-latency processing

**`transcribeAudio(audio: Data) async throws -> String`**
- Transcribes complete audio data
- Returns final, complete transcription
- Used for processing entire recordings
- May provide higher accuracy than chunks

**`cancelTranscription() async`**
- Cancels any ongoing transcription operations
- Cleans up processing resources
- Safe to call multiple times
- Non-throwing cleanup method

#### Properties

**`isInitialized: Bool`**
- Indicates if service is ready for transcription
- `true` after successful initialization
- `false` before initialization or after errors
- Used to check service availability

## Core Services

### VoiceEntryCoordinator

Main coordination service that orchestrates audio capture and transcription.

```swift
@MainActor
final class VoiceEntryCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var accumulatedTranscription = ""
    @Published private(set) var currentPartialTranscription = ""  
    @Published private(set) var audioLevel: Float = 0.0
    @Published private(set) var recordingDuration: TimeInterval = 0.0
    @Published private(set) var isRecording = false
    @Published private(set) var error: Error?
    
    // MARK: - Public Methods
    func startRecording() async throws
    func stopRecording() async throws -> String
    func cancelRecording() async
    var fullTranscription: String { get }
}
```

#### Published Properties

**`accumulatedTranscription: String`**
- Completed transcription segments
- Updated every 2 seconds during recording
- Final confirmed text that won't change
- Used for displaying stable transcription

**`currentPartialTranscription: String`**
- Current partial transcription being processed
- Updates in real-time during speech
- May change as more audio is processed
- Combined with accumulated for full display

**`audioLevel: Float`**
- Current microphone input level (0.0 to 1.0)
- Updates at 10Hz during recording
- Used for waveform visualization
- 0.0 when not recording

**`recordingDuration: TimeInterval`**
- Total recording time in seconds
- Updates every 0.1 seconds
- Used for recording timer display
- Includes safety timeout monitoring

**`isRecording: Bool`**
- Current recording state
- `true` during active recording
- Used for UI state management
- Controls timer and audio processing

**`error: Error?`**
- Last error encountered during recording
- Automatically cleared on new recording
- Used for error state display
- Non-nil indicates error condition

#### Methods

**`startRecording() async throws`**
- Begins voice recording session
- Initializes transcription service if needed
- Starts audio capture and processing timers
- Throws errors for permission or hardware issues

**`stopRecording() async throws -> String`**
- Ends recording and returns final transcription
- Processes any remaining audio data
- Combines accumulated and final transcription
- Returns complete transcribed text

**`cancelRecording() async`**
- Cancels recording without processing final result
- Cleans up resources and resets state
- Non-throwing operation for safe cancellation
- Used when user cancels or errors occur

**`fullTranscription: String`**
- Computed property combining all transcription
- Returns accumulated + current partial text
- Used for real-time display updates
- Always returns current complete state

## UI Components

### VoiceRecordButton

SwiftUI component for initiating voice recording.

```swift
struct VoiceRecordButton: View {
    let action: () -> Void
    
    var body: some View {
        // Implementation details
    }
}
```

#### Usage Example

```swift
VoiceRecordButton {
    Task {
        await viewModel.startVoiceRecording()
    }
}
```

#### Features
- Visual feedback for press states
- Gradient background with shadow
- Animation during interaction
- Accessibility support
- Minimum 44pt touch target

### WaveformVisualizer

SwiftUI component for displaying audio levels during recording.

```swift
struct WaveformVisualizer: View {
    let audioLevel: Float
    let isRecording: Bool
    
    var body: some View {
        // Implementation details
    }
}
```

#### Usage Example

```swift
WaveformVisualizer(
    audioLevel: coordinator.audioLevel,
    isRecording: coordinator.isRecording
)
```

#### Features
- Real-time audio level display
- Smooth animations
- Visual feedback for recording state
- Customizable colors and sizing

## Integration Points

### ThreadDetailViewModel Integration

The main integration point for voice entry in the app.

```swift
extension ThreadDetailViewModel {
    
    @Published var isVoiceRecordingAvailable: Bool = true
    
    func startVoiceRecording() async {
        // Voice recording implementation
        // Coordinates with VoiceEntryCoordinator
        // Handles results and error states
    }
    
    private func handleVoiceTranscription(_ text: String) {
        // Processes transcribed text
        // Integrates with entry creation
        // Handles thread context and suggestions
    }
}
```

### Error Handling

Voice entry uses structured error handling with specific error types.

#### AudioCaptureError

```swift
enum AudioCaptureError: LocalizedError {
    case permissionDenied
    case hardwareUnavailable
    case recordingFailed(String)
    case configurationFailed(String)
    
    var errorDescription: String? {
        // Localized error descriptions
    }
}
```

#### WhisperKitServiceError

```swift
enum WhisperKitServiceError: LocalizedError {
    case notInitialized
    case initializationFailed(String)
    case transcriptionFailed(String)
    case invalidAudioData
    case modelNotFound
    
    var errorDescription: String? {
        // Localized error descriptions
    }
}
```

## Extension Points

### Custom Audio Processing

Developers can extend audio processing by implementing custom audio capture services:

```swift
final class CustomAudioCaptureService: AudioCaptureServiceProtocol {
    // Custom implementation for specialized audio handling
    // Could add noise reduction, audio effects, etc.
}
```

### Alternative Speech Engines

The `WhisperKitServiceProtocol` allows for alternative speech recognition engines:

```swift
final class AlternativeTranscriptionService: WhisperKitServiceProtocol {
    // Implementation using different speech recognition engine
    // Could integrate cloud services, different models, etc.
}
```

### Custom UI Components

Voice entry UI components are composable and extensible:

```swift
struct CustomVoiceButton: View {
    let coordinator: VoiceEntryCoordinator
    
    var body: some View {
        // Custom UI implementation
        // Can use coordinator's published properties
        // Implement custom recording interactions
    }
}
```

## Testing Support

### Mock Implementations

The voice entry system provides mock implementations for testing:

```swift
final class MockWhisperKitService: WhisperKitServiceProtocol {
    // Deterministic mock responses
    // Configurable delays and errors
    // Used in unit tests
}

final class MockAudioCaptureService: AudioCaptureServiceProtocol {
    // Simulated audio capture
    // Controllable audio levels and durations
    // Used for UI testing
}
```

### Test Utilities

```swift
extension VoiceEntryCoordinator {
    // Test-specific initializers with mock services
    // Methods for controlling state in tests
    // Synchronous variants for testing
}
```

## Performance Considerations

### Memory Management

- Audio buffers are automatically cleared after processing
- Transcription services manage Core ML model memory
- Coordinator implements proper cleanup in `deinit`
- Timers are invalidated to prevent retain cycles

### Async/Await Usage

- All transcription operations use async/await
- Proper task cancellation for interrupted operations
- Main actor isolation for UI updates
- Background queues for audio processing

### Resource Optimization

- Audio capture uses optimized sample rates
- Transcription processes chunks for responsiveness  
- Memory usage is monitored and limited
- Safety timeouts prevent runaway recordings

## Configuration

### Audio Settings

Audio capture can be configured for different use cases:

```swift
struct AudioConfiguration {
    let sampleRate: Float = 16000.0
    let channels: UInt32 = 1
    let bitDepth: UInt32 = 16
    let bufferSize: UInt32 = 1024
}
```

### Transcription Settings

Speech recognition behavior can be tuned:

```swift
struct TranscriptionConfiguration {
    let chunkDuration: TimeInterval = 2.0
    let language: String? = nil // Auto-detect
    let enableTimestamps: Bool = false
    let enableWordConfidence: Bool = false
}
```

## Future Extensions

### Planned API Additions

- Voice commands for navigation
- Custom vocabulary management
- Multiple language model support
- Real-time translation capabilities
- Audio export functionality

### Extensibility Design

The current API is designed to support future enhancements without breaking changes:

- Protocol-based design allows implementation swapping
- Coordinator pattern enables feature composition
- Published properties support additional UI requirements
- Error handling is extensible for new error types

---

This API documentation provides the foundation for integrating, extending, and maintaining the voice entry feature in ThreadJournal. The clean separation of concerns and protocol-based design ensures maintainability and testability.