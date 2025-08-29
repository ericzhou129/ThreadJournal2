# Whisper Small Model Bundling Instructions

## Overview
This guide provides step-by-step instructions for bundling the Whisper Small model with ThreadJournal2 to enable offline voice transcription from first launch.

## Model Details
- **Model Name**: `openai_whisper-small`
- **Size**: ~39MB
- **Languages**: 99+ languages (multilingual)
- **Format**: Core ML (.mlmodelc directories)
- **Performance**: Optimized for iOS devices

## Step 1: Download Model Files

### Option A: Manual Download
1. Create a temporary folder: `~/Downloads/whisper-small-model/`
2. Download the following files from the official WhisperKit repository:

```bash
# Base URL
BASE_URL="https://huggingface.co/argmaxinc/whisperkit-coreml/resolve/main/openai_whisper-small"

# Required files
curl -L "$BASE_URL/AudioEncoder.mlmodelc.zip" -o AudioEncoder.mlmodelc.zip
curl -L "$BASE_URL/TextDecoder.mlmodelc.zip" -o TextDecoder.mlmodelc.zip  
curl -L "$BASE_URL/MelSpectrogram.mlmodelc.zip" -o MelSpectrogram.mlmodelc.zip
curl -L "$BASE_URL/config.json" -o config.json
curl -L "$BASE_URL/tokenizer.json" -o tokenizer.json

# Extract .mlmodelc files
unzip AudioEncoder.mlmodelc.zip
unzip TextDecoder.mlmodelc.zip
unzip MelSpectrogram.mlmodelc.zip
```

### Option B: WhisperKit CLI Tool (Recommended)
```bash
# Install WhisperKit CLI (if available)
git clone https://github.com/argmaxinc/WhisperKit.git
cd WhisperKit

# Download model using CLI
swift run whisperkit-cli download --model openai_whisper-small --output ~/Downloads/whisper-small-model/
```

## Step 2: Prepare Bundle Structure

Create the following directory structure in your project:

```
ThreadJournal2/
├── Resources/
│   └── Models/
│       └── openai_whisper-small/
│           ├── AudioEncoder.mlmodelc/          (Core ML model directory)
│           │   ├── model.mil
│           │   ├── coremldata.bin
│           │   └── metadata.json
│           ├── TextDecoder.mlmodelc/           (Core ML model directory)
│           │   ├── model.mil
│           │   ├── coremldata.bin
│           │   └── metadata.json
│           ├── MelSpectrogram.mlmodelc/        (Core ML model directory)
│           │   ├── model.mil
│           │   ├── coremldata.bin
│           │   └── metadata.json
│           ├── config.json
│           └── tokenizer.json
```

## Step 3: Add Model to Xcode Project

### Method 1: Drag and Drop
1. Open ThreadJournal2.xcodeproj in Xcode
2. Create a new group: Right-click on ThreadJournal2 → New Group → Name it "Resources"
3. Create another group inside Resources: Right-click on Resources → New Group → Name it "Models"
4. Drag the entire `openai_whisper-small` folder from Finder into the Models group
5. **Important**: Select "Create folder references" (blue folder icon, not yellow)
6. Ensure "Copy items if needed" is checked
7. Add to ThreadJournal2 target
8. Click "Finish"

### Method 2: File Menu
1. In Xcode: File → Add Files to 'ThreadJournal2'
2. Navigate to your downloaded model folder
3. Select the `openai_whisper-small` folder
4. **Important**: Select "Create folder references" 
5. Ensure target is ThreadJournal2
6. Click "Add"

## Step 4: Verify Bundle Integration

### Check Bundle Contents
Add this verification code to test the bundle:

```swift
// Verify model is bundled (add to WhisperKitService for debugging)
private func verifyBundledModel() -> Bool {
    guard let modelPath = Bundle.main.path(forResource: "openai_whisper-small", ofType: nil) else {
        print("❌ Model folder not found in bundle")
        return false
    }
    
    let requiredFiles = [
        "AudioEncoder.mlmodelc",
        "TextDecoder.mlmodelc", 
        "MelSpectrogram.mlmodelc",
        "config.json",
        "tokenizer.json"
    ]
    
    for file in requiredFiles {
        let filePath = (modelPath as NSString).appendingPathComponent(file)
        if !FileManager.default.fileExists(atPath: filePath) {
            print("❌ Missing required file: \(file)")
            return false
        }
    }
    
    print("✅ All model files found in bundle")
    return true
}
```

### Check App Size Impact
1. Build the project: Cmd+B
2. Archive the app: Product → Archive
3. Check the archive size - should increase by ~39MB
4. Verify no build errors related to model files

## Step 5: Configure Info.plist

Add microphone permission (if not already present):

```xml
<key>NSMicrophoneUsageDescription</key>
<string>ThreadJournal needs microphone access to transcribe your voice entries.</string>
```

## Step 6: Test Integration

### Simulator Testing
```swift
// Test in iOS Simulator (performance will be slower)
let service = WhisperKitService()
try await service.initialize()
print("WhisperKit initialized: \(service.isInitialized)")
```

### Device Testing
1. Run on physical device (iPhone 12 or newer recommended)
2. Test voice transcription functionality
3. Verify no network requests are made during transcription
4. Check memory usage stays within reasonable limits (~200MB during transcription)

## Troubleshooting

### Common Issues

1. **"Model not found" error**
   - Verify folder references (blue folders) not group references (yellow folders)
   - Check bundle contents in Build Phases → Copy Bundle Resources

2. **Build size too large**
   - Ensure you're only including necessary files
   - Remove any duplicate or test files

3. **Runtime crashes**
   - Verify .mlmodelc directories are complete
   - Check device has sufficient memory (recommend 2GB+ available)

4. **Slow performance**
   - Test on physical device, not simulator
   - Ensure device is iPhone 12 or newer for optimal performance

### Verification Commands

```bash
# Check downloaded model integrity
ls -la ~/Downloads/whisper-small-model/openai_whisper-small/
du -sh ~/Downloads/whisper-small-model/openai_whisper-small/

# Verify Xcode bundle contents
ls -la "~/Library/Developer/Xcode/DerivedData/ThreadJournal2-*/Build/Products/Debug-iphonesimulator/ThreadJournal2.app/openai_whisper-small/"
```

## Performance Expectations

- **Initialization**: 2-5 seconds on first launch
- **2-second chunk**: ~0.5-2 seconds transcription time
- **Memory Usage**: ~200MB during active transcription
- **Supported Devices**: iPhone 12+ (older devices may be slower)
- **Languages**: Automatic detection of 99+ languages

## Final Notes

- The bundled model enables offline-first experience
- No network connection required for transcription
- App size will increase by ~39MB
- Consider app store guidelines for large downloads
- Test thoroughly on target devices before release