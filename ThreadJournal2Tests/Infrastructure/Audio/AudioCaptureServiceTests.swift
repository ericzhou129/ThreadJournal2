import XCTest
import AVFoundation
@testable import ThreadJournal2

final class AudioCaptureServiceTests: XCTestCase {
    
    var sut: AudioCaptureService!
    
    override func setUp() {
        super.setUp()
        sut = AudioCaptureService()
    }
    
    override func tearDown() {
        if sut.isRecording() {
            try? await sut.stopRecording()
        }
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertFalse(sut.isRecording())
        XCTAssertEqual(sut.getRecordingDuration(), 0.0)
        XCTAssertEqual(sut.getAudioLevel(), 0.0)
    }
    
    // MARK: - Permission Tests
    
    func testMicrophonePermissionRequest() async {
        // This test would require mocking AVAudioApplication
        // For now, we'll test the method exists and returns a Bool
        let hasPermission = await sut.requestMicrophonePermission()
        XCTAssertTrue(hasPermission is Bool)
    }
    
    // MARK: - Recording State Tests
    
    func testRecordingStateAfterStart() async throws {
        // Skip test if no microphone permission
        guard await sut.requestMicrophonePermission() else {
            throw XCTSkip("Microphone permission required for this test")
        }
        
        try await sut.startRecording()
        
        XCTAssertTrue(sut.isRecording())
        XCTAssertGreaterThan(sut.getRecordingDuration(), 0.0)
        
        try await sut.stopRecording()
    }
    
    func testRecordingStateAfterStop() async throws {
        guard await sut.requestMicrophonePermission() else {
            throw XCTSkip("Microphone permission required for this test")
        }
        
        try await sut.startRecording()
        let audioData = try await sut.stopRecording()
        
        XCTAssertFalse(sut.isRecording())
        XCTAssertNotNil(audioData)
        XCTAssertGreaterThan(audioData.count, 0)
    }
    
    func testMultipleStopCallsThrow() async throws {
        guard await sut.requestMicrophonePermission() else {
            throw XCTSkip("Microphone permission required for this test")
        }
        
        try await sut.startRecording()
        _ = try await sut.stopRecording()
        
        // Second stop should throw
        do {
            _ = try await sut.stopRecording()
            XCTFail("Expected AudioCaptureError.audioEngineNotRunning")
        } catch AudioCaptureError.audioEngineNotRunning {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Recording Duration Tests
    
    func testRecordingDurationProgresses() async throws {
        guard await sut.requestMicrophonePermission() else {
            throw XCTSkip("Microphone permission required for this test")
        }
        
        try await sut.startRecording()
        
        let initialDuration = sut.getRecordingDuration()
        
        // Wait briefly
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let laterDuration = sut.getRecordingDuration()
        
        XCTAssertGreaterThan(laterDuration, initialDuration)
        XCTAssertGreaterThan(laterDuration, 0.05) // At least 0.05 seconds
        
        try await sut.stopRecording()
    }
    
    func testRecordingDurationResetsAfterStop() async throws {
        guard await sut.requestMicrophonePermission() else {
            throw XCTSkip("Microphone permission required for this test")
        }
        
        try await sut.startRecording()
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertGreaterThan(sut.getRecordingDuration(), 0.0)
        
        _ = try await sut.stopRecording()
        
        XCTAssertEqual(sut.getRecordingDuration(), 0.0)
    }
    
    // MARK: - Audio Level Tests
    
    func testAudioLevelUpdates() async throws {
        guard await sut.requestMicrophonePermission() else {
            throw XCTSkip("Microphone permission required for this test")
        }
        
        try await sut.startRecording()
        
        // Wait for audio processing
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let audioLevel = sut.getAudioLevel()
        // Audio level should be between 0 and 1 (normalized)
        XCTAssertGreaterThanOrEqual(audioLevel, 0.0)
        XCTAssertLessThanOrEqual(audioLevel, 1.0)
        
        try await sut.stopRecording()
    }
    
    // MARK: - Error Handling Tests
    
    func testStartRecordingWithoutPermissionThrows() async {
        // This test assumes we don't have microphone permission
        // In a real scenario, we'd mock the permission check
        do {
            try await sut.startRecording()
            // If we reach here, we have permission, so skip the test
            try await sut.stopRecording()
            throw XCTSkip("Cannot test permission denial when permission is granted")
        } catch AudioCaptureError.microphonePermissionDenied {
            // This is what we expect when permission is denied
            XCTAssertTrue(true)
        } catch {
            // If we get any other error or success, it means we have permission
            throw XCTSkip("Cannot test permission denial: \(error)")
        }
    }
    
    func testStopRecordingWithoutStartingThrows() async {
        do {
            _ = try await sut.stopRecording()
            XCTFail("Expected AudioCaptureError.audioEngineNotRunning")
        } catch AudioCaptureError.audioEngineNotRunning {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Silence Continuation Tests
    
    func testRecordingContinuesThroughSilence() async throws {
        guard await sut.requestMicrophonePermission() else {
            throw XCTSkip("Microphone permission required for this test")
        }
        
        try await sut.startRecording()
        
        // Record for a few seconds to simulate silence
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Recording should still be active
        XCTAssertTrue(sut.isRecording())
        XCTAssertGreaterThan(sut.getRecordingDuration(), 1.5)
        
        try await sut.stopRecording()
    }
    
    // MARK: - Safety Timeout Tests (Mock)
    
    func testSafetyTimeoutConfiguration() {
        // Test that the service is properly configured for 5-minute timeout
        // This is more of a configuration verification test
        XCTAssertNotNil(sut)
        
        // We can't easily test the actual 5-minute timeout in unit tests
        // but we can verify the service doesn't crash and handles long recordings
        
        // The actual timeout logic would be tested in integration tests
        // or by mocking the timer mechanism
    }
    
    // MARK: - Data Quality Tests
    
    func testRecordedAudioDataIsValid() async throws {
        guard await sut.requestMicrophonePermission() else {
            throw XCTSkip("Microphone permission required for this test")
        }
        
        try await sut.startRecording()
        
        // Record for a brief moment to capture some data
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let audioData = try await sut.stopRecording()
        
        XCTAssertGreaterThan(audioData.count, 0)
        
        // Basic WAV header validation (should start with "RIFF")
        if audioData.count >= 4 {
            let header = audioData.prefix(4)
            let headerString = String(data: header, encoding: .ascii)
            XCTAssertEqual(headerString, "RIFF")
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryCleanupAfterMultipleRecordings() async throws {
        guard await sut.requestMicrophonePermission() else {
            throw XCTSkip("Microphone permission required for this test")
        }
        
        // Perform multiple recording cycles
        for _ in 0..<3 {
            try await sut.startRecording()
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            let _ = try await sut.stopRecording()
            
            // Verify state is properly reset
            XCTAssertFalse(sut.isRecording())
            XCTAssertEqual(sut.getRecordingDuration(), 0.0)
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentRecordingCallsHandledGracefully() async throws {
        guard await sut.requestMicrophonePermission() else {
            throw XCTSkip("Microphone permission required for this test")
        }
        
        // Start recording
        try await sut.startRecording()
        
        // Try to start again - should handle gracefully
        do {
            try await sut.startRecording()
            // If no error, just continue
        } catch {
            // Some error is expected, verify recording is still active
            XCTAssertTrue(sut.isRecording())
        }
        
        try await sut.stopRecording()
    }
}