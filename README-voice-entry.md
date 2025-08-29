# Voice Entry Feature - Setup Guide

## Overview
ThreadJournal's voice entry feature enables users to create journal entries using voice dictation with complete on-device processing. The feature uses WhisperKit for Core ML-based transcription, ensuring privacy and offline functionality.

## Quick Start

### 1. Add WhisperKit Dependency
1. Open `ThreadJournal2.xcodeproj` in Xcode
2. Select the project in the navigator
3. Go to "Package Dependencies" tab
4. Click the "+" button
5. Enter: `https://github.com/argmaxinc/WhisperKit`
6. Select version: Latest (1.0.0 or higher)
7. Click "Add Package"
8. Select target: ThreadJournal2

### 2. Add Microphone Permission
Add to `Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>ThreadJournal needs microphone access to transcribe your voice entries</string>
```

### 3. Build and Run
```bash
# Clean build folder
xcodebuild clean -scheme ThreadJournal2

# Build the project
xcodebuild build -scheme ThreadJournal2 -destination 'platform=iOS Simulator,name=iPhone 15'

# Run tests
xcodebuild test -scheme ThreadJournal2 -destination 'platform=iOS Simulator,name=iPhone 15'
```

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

## Model Management

### Default Model
- **Name**: Whisper Small (Multilingual)
- **Size**: 39 MB
- **Languages**: 99+ languages
- **Performance**: <1s to first partial on A16+

### Model Download
Models are downloaded on-demand from Hugging Face:
```
https://huggingface.co/argmaxinc/whisperkit-coreml/openai_whisper-small
```

### Storage Location
```
Documents/WhisperModels/openai_whisper-small/
├── AudioEncoder.mlmodelc
├── TextDecoder.mlmodelc
├── MelSpectrogram.mlmodelc
├── config.json
└── tokenizer.json
```

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

#### Model Download Failed
- Check network connectivity
- Verify sufficient storage (80MB free)
- Clear cache and retry
- Check Hugging Face availability

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
struct ComposeBar: View {
    @StateObject private var voiceVM = VoiceEntryViewModel()
    @State private var showVoiceEntry = false
    
    var body: some View {
        HStack {
            TextField("What's on your mind?", text: $text)
            
            Button(action: { showVoiceEntry = true }) {
                Image(systemName: "mic.fill")
            }
            .sheet(isPresented: $showVoiceEntry) {
                VoiceEntryView(viewModel: voiceVM)
            }
        }
    }
}
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

1. **Model Size**: 39MB download required
2. **Language Detection**: Auto-detection may be slow
3. **Background Recording**: Not supported due to iOS restrictions
4. **Long Recordings**: Memory usage increases linearly
5. **Accuracy**: Varies with accent and audio quality

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