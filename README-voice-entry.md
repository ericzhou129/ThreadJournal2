# Voice Entry Feature - Developer Guide

## Overview
ThreadJournal's voice entry feature enables users to create journal entries using voice dictation with complete on-device processing. The feature uses WhisperKit for Core ML-based transcription with a bundled Whisper Small model, ensuring privacy, offline functionality, and zero-configuration user experience.

## Key Features

### Zero-Configuration Approach
- **Bundled Model**: Whisper Small model (39MB) is included in the app bundle
- **No Downloads**: Users can start using voice entry immediately after install
- **Offline-First**: No internet connection required for transcription
- **Instant Availability**: No waiting for model downloads or setup

### User Experience
- **Two Recording Modes**: Tap-to-record and hold-to-record
- **Real-time Feedback**: Live partial transcription results
- **Smart Actions**: Stop & Edit vs Stop & Save options
- **Audio Visualization**: Waveform display during recording
- **Safety Limits**: 5-minute maximum recording duration

### Developer Setup

#### 1. WhisperKit Integration
The app integrates WhisperKit via Swift Package Manager:
- Repository: `https://github.com/argmaxinc/WhisperKit`
- Version: 1.0.0 or higher
- Target: ThreadJournal2

#### 2. Microphone Permission
Required `Info.plist` entry:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>ThreadJournal needs microphone access to transcribe your voice entries</string>
```

#### 3. Model Bundling
The Whisper Small model is bundled in the app using folder references:
- Location: `ThreadJournal2/Resources/Models/openai_whisper-small/`
- Size: ~39MB
- Contents: AudioEncoder.mlmodelc, TextDecoder.mlmodelc, MelSpectrogram.mlmodelc, config.json, tokenizer.json

## Architecture

### Component Overview

```
Voice Entry System
├── Infrastructure Layer
│   ├── Audio/
│   │   └── AudioCaptureService.swift      # AVAudioEngine management
│   └── ML/
│       ├── ModelManager.swift             # Model download/storage
│       └── WhisperKitService.swift        # WhisperKit wrapper (TBD)
│
├── Application Layer
│   ├── Services/
│   │   └── TranscriptionService.swift     # Orchestrates transcription
│   └── ViewModels/
│       ├── VoiceEntryViewModel.swift      # Voice entry logic
│       └── VoiceSettingsViewModel.swift   # Settings management
│
└── Interface Layer
    └── Views/
        ├── VoiceEntryView.swift           # Recording UI
        ├── VoiceSettingsView.swift        # Settings UI
        └── Components/
            ├── WaveformVisualizer.swift   # Audio visualization
            └── ModelDownloadView.swift    # Download progress UI
```

### Data Flow

1. **Recording**: User taps microphone → AudioCaptureService starts recording
2. **Processing**: Audio buffer → WhisperKit → Transcription
3. **Display**: Partial results shown in real-time
4. **Save**: Final transcription → Entry creation → Thread

## Features

### Core Functionality
- ✅ On-device transcription (no cloud calls)
- ✅ Real-time partial results
- ✅ Multilingual support (Whisper Small model)
- ✅ Voice Activity Detection (3s silence threshold)
- ✅ Thread suggestion integration
- ✅ Hold-to-record and tap-to-record modes

### Privacy & Security
- All processing happens locally
- No audio data sent to servers
- Audio buffers cleared after transcription
- Models stored in private app container
- Microphone permission required

## Bundled Model Details

### Whisper Small (Multilingual)
- **Name**: openai_whisper-small
- **Size**: 39MB (bundled in app)
- **Languages**: 99+ languages with automatic detection
- **Performance**: <1s to first partial result on A16+ devices
- **Format**: Core ML (.mlmodelc) optimized for iOS

### Bundle Location
```
ThreadJournal2.app/openai_whisper-small/
├── AudioEncoder.mlmodelc/      # Speech-to-audio-features model
├── TextDecoder.mlmodelc/       # Audio-features-to-text model  
├── MelSpectrogram.mlmodelc/    # Audio preprocessing model
├── config.json                 # Model configuration
└── tokenizer.json             # Text tokenization rules
```

### No Downloads Required
- Models are pre-bundled during build process
- No first-launch download wait times
- No network dependency for voice features
- Consistent experience across all devices

## Performance Guidelines

### Target Metrics
- **Latency**: <1 second to first partial result
- **Memory**: <50MB additional during recording
- **Battery**: <5% drain for 10-minute recording
- **Accuracy**: 95%+ for clear speech

### Device Requirements
- **Recommended**: iPhone 12 or newer (A14+ chip)
- **Minimum**: iPhone 11 (A13 chip)
- **iOS Version**: 17.0+

## Testing

### Unit Tests
```bash
# Run voice entry tests
swift test --filter VoiceEntryTests

# Run audio capture tests
swift test --filter AudioCaptureServiceTests

# Run model manager tests
swift test --filter ModelManagerTests
```

### Integration Tests
1. Test microphone permission flow
2. Test model download with network interruption
3. Test recording with interruptions (calls, notifications)
4. Test AirPods connection/disconnection
5. Test background/foreground transitions

### Performance Tests
```swift
// Test transcription latency
func testTranscriptionLatency() {
    measure {
        // Record 10 seconds of audio
        // Measure time to first partial
        // Should be <1s on A16+
    }
}
```

## Troubleshooting

### Common Issues

#### Microphone Permission Denied
```swift
// Check permission status
AVAudioApplication.shared.recordPermission == .granted

// Request permission
AVAudioApplication.requestRecordPermission { granted in
    // Handle response
}
```

#### Model Not Found
- Verify model bundle is included in Xcode project
- Check folder references (blue folders) not groups (yellow)
- Ensure Bundle.main.path(forResource: "openai_whisper-small") returns valid path
- Rebuild project to refresh bundle contents

#### No Audio Captured
- Verify audio session configuration
- Check for interruptions
- Ensure proper buffer format
- Test with different sample rates

#### Poor Transcription Quality
- Check microphone quality
- Reduce background noise
- Verify model integrity
- Test with different languages

## Development Workflow

### Adding Voice to New Entry Points
1. Import voice entry components
2. Add microphone button to UI
3. Present `VoiceEntryView`
4. Handle transcription result
5. Create entry with transcribed text

### Example Integration
```swift
// In ThreadDetailView - voice recording integration
struct ThreadComposer: View {
    @StateObject private var viewModel: ThreadDetailViewModel
    
    var body: some View {
        VStack {
            TextField("What's on your mind?", text: $viewModel.newEntryText)
            
            if viewModel.isVoiceRecordingAvailable {
                VoiceRecordButton {
                    Task {
                        await viewModel.startVoiceRecording()
                    }
                }
            }
        }
    }
}

// Voice recording coordinator usage
let coordinator = VoiceEntryCoordinator(
    audioService: AudioCaptureService(),
    transcriptionService: WhisperKitService()
)

// Start recording
try await coordinator.startRecording()

// Get final transcription
let transcription = try await coordinator.stopRecording()
```

## Future Enhancements

### Phase 2
- [ ] Medium model option (244MB)
- [ ] Language-specific models
- [ ] Custom vocabulary support
- [ ] Speaker diarization

### Phase 3
- [ ] Offline punctuation enhancement
- [ ] Real-time translation
- [ ] Voice commands
- [ ] Audio export

## Known Limitations

1. **App Size Impact**: 39MB increase in app bundle size
2. **Language Detection**: Auto-detection adds slight processing delay
3. **Background Recording**: Not supported due to iOS app lifecycle restrictions
4. **Recording Duration**: 5-minute safety limit to prevent excessive memory usage
5. **Device Performance**: Older devices (pre-A14) may have slower transcription
6. **Accuracy Factors**: Performance varies with microphone quality, background noise, and speech clarity

## Support

### Resources
- [WhisperKit Documentation](https://github.com/argmaxinc/WhisperKit)
- [Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [AVAudioEngine Guide](https://developer.apple.com/documentation/avfaudio/avaudioengine)

### Debug Settings
Enable in Developer Settings:
- Console logging for transcription
- Partial result display
- Audio level monitoring
- Model performance metrics

## License
This feature uses WhisperKit under MIT license. The Whisper models are provided by OpenAI under Apache 2.0 license.