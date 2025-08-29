# Adding WhisperKit to ThreadJournal2

## Manual Installation Required

To enable real voice transcription, you need to add the WhisperKit package to your Xcode project:

### Steps to Add WhisperKit:

1. **Open the project in Xcode**
   - Open `ThreadJournal2.xcodeproj` in Xcode

2. **Add Package Dependency**
   - Select the ThreadJournal2 project in the navigator
   - Click on the ThreadJournal2 project (not a target) at the top of the file navigator
   - Select the "Package Dependencies" tab
   - Click the "+" button

3. **Enter WhisperKit URL**
   - In the search field, enter: `https://github.com/argmaxinc/WhisperKit`
   - Click "Add Package"

4. **Configure Package Options**
   - Dependency Rule: "Up to Next Major Version"
   - Version: 0.13.1 (or latest)
   - Click "Add Package"

5. **Add to Target**
   - Select "WhisperKit" product
   - Add to Target: ThreadJournal2
   - Click "Add Package"

### After Installation:

Once WhisperKit is added:
1. Clean build folder: Product → Clean Build Folder (⇧⌘K)
2. Build the project: Product → Build (⌘B)

The app will now use real on-device speech recognition instead of mock transcription.

### Model Download

On first use, WhisperKit will automatically download the Whisper model (approximately 39MB). This happens once and the model is cached locally.

### Verification

To verify WhisperKit is working:
1. Run the app in the simulator or on a device
2. Tap "Tap to speak" in a thread
3. Grant microphone permission if prompted
4. Speak into the microphone
5. You should see real transcription appear instead of "This is a sample transcription"

## Alternative: Use Mock Implementation

If you don't want to use WhisperKit right now, you can revert the WhisperKitService.swift file to use the mock implementation by:
1. Commenting out `import WhisperKit`
2. Using the mock implementation code that's commented in the file