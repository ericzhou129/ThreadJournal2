# WhisperKit Integration Guide

## Swift Package Manager Setup

### 1. Add WhisperKit Package

In Xcode:
1. Open your project (`ThreadJournal2.xcodeproj`)
2. Go to File → Add Package Dependencies
3. Enter the WhisperKit repository URL:
   ```
   https://github.com/argmaxinc/WhisperKit
   ```
4. Select the latest version (or specify version 0.8.0 or later)
5. Click "Add Package"
6. Select "WhisperKit" from the product list
7. Add to the "ThreadJournal2" target
8. Click "Add Package"

### 2. Bundle Whisper Small Model

The Whisper Small model (~39MB) should be bundled with the app to work immediately on first launch.

#### Option A: Download and Bundle (Recommended)

1. Create a `Models` folder in your app bundle:
   ```
   ThreadJournal2/
   ├── Models/
   │   └── openai_whisper-small/
   │       ├── AudioEncoder.mlmodelc
   │       ├── TextDecoder.mlmodelc
   │       ├── MelSpectrogram.mlmodelc
   │       ├── config.json
   │       └── tokenizer.json
   ```

2. Download the model files from the official WhisperKit repository:
   - Base URL: `https://huggingface.co/argmaxinc/whisperkit-coreml/resolve/main/openai_whisper-small/`
   - Required files:
     - `AudioEncoder.mlmodelc` (directory with .mlmodel files)
     - `TextDecoder.mlmodelc` (directory with .mlmodel files)  
     - `MelSpectrogram.mlmodelc` (directory with .mlmodel files)
     - `config.json`
     - `tokenizer.json`

3. Add the model folder to your Xcode project:
   - Right-click on ThreadJournal2 folder in Xcode
   - Select "Add Files to 'ThreadJournal2'"
   - Select the Models folder
   - Make sure "Copy items if needed" is checked
   - Select "Create folder references" (blue folder icon)
   - Add to ThreadJournal2 target

#### Option B: WhisperKit Auto-Download with Bundle Fallback

If bundling the full model is challenging, use WhisperKit's built-in download with bundle detection:

```swift
// WhisperKit will check for bundled models first, then download if needed
let whisperKit = try await WhisperKit(modelFolder: "openai_whisper-small")
```

### 3. Info.plist Configuration

Add required permissions to `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>ThreadJournal needs microphone access to transcribe your voice entries.</string>
```

### 4. Bundle Size Impact

- WhisperKit framework: ~5MB
- Whisper Small model: ~39MB
- Total app size increase: ~44MB

### 5. Verification

To verify the integration:

1. Build the project to ensure no compilation errors
2. Check that WhisperKit is properly linked
3. Verify model files are included in app bundle
4. Test on simulator (transcription may be slower)
5. Test on device for optimal performance

## Technical Notes

- **Model Format**: WhisperKit uses Core ML models (.mlmodelc directories)
- **Performance**: On-device transcription works best on iPhone 12 and newer
- **Languages**: Whisper Small supports 99+ languages automatically
- **Chunk Size**: Optimized for 2-second audio chunks
- **Memory**: Expect ~200MB RAM usage during transcription