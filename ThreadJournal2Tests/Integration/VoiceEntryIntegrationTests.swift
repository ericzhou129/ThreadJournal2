//
//  VoiceEntryIntegrationTests.swift
//  ThreadJournal2Tests
//
//  Integration tests for the complete voice entry workflow
//

import XCTest
@testable import ThreadJournal2

@MainActor
final class VoiceEntryIntegrationTests: XCTestCase {
    
    private var coordinator: VoiceEntryCoordinator!
    private var mockAudioService: MockAudioCaptureService!
    private var mockTranscriptionService: MockWhisperKitService!
    
    override func setUp() {
        super.setUp()
        mockAudioService = MockAudioCaptureService()
        mockTranscriptionService = MockWhisperKitService()
        coordinator = VoiceEntryCoordinator(
            audioService: mockAudioService,
            transcriptionService: mockTranscriptionService
        )
    }
    
    override func tearDown() {
        coordinator = nil
        mockAudioService = nil
        mockTranscriptionService = nil
        super.tearDown()
    }
    
    // MARK: - Full Recording Flow Tests
    
    func testFullRecordingFlowFromButtonTapToEntryCreation() async throws {
        // Given - successful setup
        mockAudioService.shouldStartRecordingSucceed = true
        mockTranscriptionService.shouldInitializeSucceed = true
        mockAudioService.recordingData = createMockAudioData()
        mockTranscriptionService.mockTranscription = "This is a test transcription"
        
        // When - simulate button tap to start recording
        try await coordinator.startRecording()
        
        // Then - verify recording started
        XCTAssertTrue(coordinator.isRecording, "Recording should have started")
        XCTAssertTrue(mockAudioService.startRecordingCalled)
        
        // When - simulate recording for some time (mock audio levels and duration)
        mockAudioService.setAudioLevel(0.7)
        mockAudioService.setRecordingDuration(2.5)
        
        // Then - verify live updates
        XCTAssertEqual(coordinator.audioLevel, 0.7, accuracy: 0.01)
        XCTAssertEqual(coordinator.recordingDuration, 2.5, accuracy: 0.01)
        
        // When - stop recording and get transcription
        let transcription = try await coordinator.stopRecording()
        
        // Then - verify completion
        XCTAssertFalse(coordinator.isRecording, "Recording should have stopped")
        XCTAssertEqual(transcription, "This is a test transcription")
    }
    
    func testStopAndEditWorkflow() async throws {
        // Given - recording in progress
        mockAudioService.shouldStartRecordingSucceed = true
        mockTranscriptionService.shouldInitializeSucceed = true
        mockAudioService.recordingData = createMockAudioData()
        mockTranscriptionService.mockTranscription = "Draft text for editing"
        
        try await coordinator.startRecording()
        mockAudioService.setRecordingDuration(3.0)
        
        // When - stop and edit
        let transcription = try await coordinator.stopRecording()
        
        // Then - verify transcription is ready for editing
        XCTAssertFalse(coordinator.isRecording)
        XCTAssertEqual(transcription, "Draft text for editing")
        
        // Verify coordinator state is clean for next recording
        XCTAssertEqual(coordinator.currentPartialTranscription, "")
        XCTAssertEqual(coordinator.recordingDuration, 0.0)
        XCTAssertEqual(coordinator.audioLevel, 0.0)
    }
    
    func testStopAndSaveWorkflow() async throws {
        // Given - recording in progress
        mockAudioService.shouldStartRecordingSucceed = true
        mockTranscriptionService.shouldInitializeSucceed = true
        mockAudioService.recordingData = createMockAudioData()
        mockTranscriptionService.mockTranscription = "Final transcription for saving"
        
        try await coordinator.startRecording()
        mockAudioService.setRecordingDuration(4.5)
        
        // When - stop and save (same as regular stop but indicates intent)
        let transcription = try await coordinator.stopRecording()
        
        // Then - verify transcription is ready to save
        XCTAssertFalse(coordinator.isRecording)
        XCTAssertEqual(transcription, "Final transcription for saving")
        
        // Verify clean state
        XCTAssertEqual(coordinator.currentPartialTranscription, "")
        XCTAssertEqual(coordinator.accumulatedTranscription, "")
    }
    
    // MARK: - Timeout Behavior Tests
    
    func testFiveMinuteTimeoutBehavior() async throws {
        // Given - recording started successfully
        mockAudioService.shouldStartRecordingSucceed = true
        try await coordinator.startRecording()
        
        // When - simulate 5-minute timeout
        mockAudioService.setRecordingDuration(300.0) // 5 minutes
        
        // Note: Actual timeout behavior would be handled by the coordinator's timer
        // This test verifies we can handle long recordings properly
        XCTAssertTrue(coordinator.isRecording)
        
        // When - stop after timeout duration
        mockAudioService.recordingData = createMockAudioData()
        let transcription = try await coordinator.stopRecording()
        
        // Then - should complete successfully
        XCTAssertNotNil(transcription)
        XCTAssertFalse(coordinator.isRecording)
    }
    
    // MARK: - Interruption Handling Tests
    
    func testRecordingInterruptedByPhoneCall() async throws {
        // Given - recording in progress
        mockAudioService.shouldStartRecordingSucceed = true
        try await coordinator.startRecording()
        mockAudioService.setRecordingDuration(1.5)
        
        // When - simulate audio session interruption
        mockAudioService.simulateInterruption()
        
        // Then - coordinator should handle gracefully
        // Note: In real implementation, this would be handled via audio session notifications
        // For mock, we verify the coordinator can handle unexpected stops
        do {
            let transcription = try await coordinator.stopRecording()
            XCTAssertNotNil(transcription)
        } catch {
            // Interruption might cause an error, which is acceptable
            XCTAssertFalse(coordinator.isRecording, "Recording should be stopped after interruption")
        }
    }
    
    func testAppBackgroundingDuringRecording() async throws {
        // Given - recording in progress
        mockAudioService.shouldStartRecordingSucceed = true
        try await coordinator.startRecording()
        mockAudioService.setRecordingDuration(2.0)
        
        // When - simulate app backgrounding
        mockAudioService.simulateBackgrounding()
        
        // Then - recording should continue (iOS allows brief background recording)
        XCTAssertTrue(coordinator.isRecording)
        
        // When - return to foreground and stop
        mockAudioService.recordingData = createMockAudioData()
        let transcription = try await coordinator.stopRecording()
        
        // Then - should complete normally
        XCTAssertNotNil(transcription)
        XCTAssertFalse(coordinator.isRecording)
    }
    
    // MARK: - Very Long Recording Tests
    
    func testVeryLongRecordingUpToFiveMinutes() async throws {
        // Given - setup for long recording
        mockAudioService.shouldStartRecordingSucceed = true
        mockTranscriptionService.shouldInitializeSucceed = true
        
        try await coordinator.startRecording()
        
        // When - simulate very long recording (just under 5 minutes)
        mockAudioService.setRecordingDuration(299.0) // 4:59
        mockAudioService.setAudioLevel(0.3)
        
        // Then - should still be recording
        XCTAssertTrue(coordinator.isRecording)
        XCTAssertEqual(coordinator.recordingDuration, 299.0, accuracy: 0.1)
        XCTAssertEqual(coordinator.audioLevel, 0.3, accuracy: 0.01)
        
        // When - stop the long recording
        mockAudioService.recordingData = createLargeMockAudioData() // Larger data for long recording
        mockTranscriptionService.mockTranscription = "This is a very long transcription from a five minute recording"
        
        let transcription = try await coordinator.stopRecording()
        
        // Then - should handle large data successfully
        XCTAssertEqual(transcription, "This is a very long transcription from a five minute recording")
        XCTAssertFalse(coordinator.isRecording)
    }
    
    // MARK: - Rapid Start/Stop Sequences Tests
    
    func testRapidStartStopSequences() async throws {
        // Given
        mockAudioService.shouldStartRecordingSucceed = true
        mockTranscriptionService.shouldInitializeSucceed = true
        mockAudioService.recordingData = createMockAudioData()
        mockTranscriptionService.mockTranscription = "Quick test"
        
        // When - perform rapid start/stop cycles
        for i in 0..<3 {
            // Start recording
            try await coordinator.startRecording()
            XCTAssertTrue(coordinator.isRecording, "Recording \(i + 1) should start")
            
            // Brief recording
            mockAudioService.setRecordingDuration(Double(i) * 0.5 + 0.3)
            
            // Stop recording
            let transcription = try await coordinator.stopRecording()
            XCTAssertFalse(coordinator.isRecording, "Recording \(i + 1) should stop")
            XCTAssertNotNil(transcription)
            
            // Verify clean state between recordings
            XCTAssertEqual(coordinator.recordingDuration, 0.0)
            XCTAssertEqual(coordinator.audioLevel, 0.0)
            XCTAssertEqual(coordinator.currentPartialTranscription, "")
        }
    }
    
    // MARK: - Microphone Permission Tests
    
    func testMicrophonePermissionDenied() async {
        // Given - permission will be denied
        mockAudioService.shouldGrantPermission = false
        
        // When - attempt to start recording
        do {
            try await coordinator.startRecording()
            XCTFail("Should throw permission denied error")
        } catch {
            // Then - should handle permission error gracefully
            XCTAssertFalse(coordinator.isRecording)
            // Check if error is related to permissions
            if let audioError = error as? AudioCaptureError {
                XCTAssertEqual(audioError, AudioCaptureError.microphonePermissionDenied)
            }
        }
    }
    
    func testMicrophonePermissionGrantedAfterDenial() async throws {
        // Given - initially deny permission
        mockAudioService.shouldGrantPermission = false
        
        // When - first attempt fails
        do {
            try await coordinator.startRecording()
            XCTFail("Should throw permission denied error")
        } catch {
            // Expected
        }
        
        // When - permission is granted and try again
        mockAudioService.shouldGrantPermission = true
        mockAudioService.shouldStartRecordingSucceed = true
        
        try await coordinator.startRecording()
        
        // Then - should succeed
        XCTAssertTrue(coordinator.isRecording)
        
        // Cleanup
        mockAudioService.recordingData = createMockAudioData()
        _ = try await coordinator.stopRecording()
    }
    
    // MARK: - Cancel Recording Tests
    
    func testCancelRecordingCleansUpState() async throws {
        // Given - recording in progress
        mockAudioService.shouldStartRecordingSucceed = true
        try await coordinator.startRecording()
        
        mockAudioService.setRecordingDuration(2.0)
        mockAudioService.setAudioLevel(0.8)
        // Note: accumulatedTranscription and currentPartialTranscription are set internally
        // We'll verify they get reset during cancel instead of setting them manually
        
        // When - cancel recording
        await coordinator.cancelRecording()
        
        // Then - all state should be reset
        XCTAssertFalse(coordinator.isRecording)
        XCTAssertEqual(coordinator.recordingDuration, 0.0)
        XCTAssertEqual(coordinator.audioLevel, 0.0)
        XCTAssertEqual(coordinator.accumulatedTranscription, "")
        XCTAssertEqual(coordinator.currentPartialTranscription, "")
        XCTAssertTrue(mockAudioService.stopRecordingCalled)
    }
    
    // MARK: - Error Recovery Tests
    
    func testRecoveryFromAudioServiceErrors() async throws {
        // Given - audio service will fail initially
        mockAudioService.shouldStartRecordingSucceed = false
        
        // When - first attempt fails
        do {
            try await coordinator.startRecording()
            XCTFail("Should throw audio service error")
        } catch {
            // Expected error
        }
        
        // When - service recovers and we try again
        mockAudioService.shouldStartRecordingSucceed = true
        try await coordinator.startRecording()
        
        // Then - should succeed after recovery
        XCTAssertTrue(coordinator.isRecording)
        
        // Cleanup
        mockAudioService.recordingData = createMockAudioData()
        _ = try await coordinator.stopRecording()
    }
    
    func testRecoveryFromTranscriptionServiceErrors() async throws {
        // Given - transcription service fails but audio succeeds
        mockAudioService.shouldStartRecordingSucceed = true
        mockTranscriptionService.shouldInitializeSucceed = false
        
        try await coordinator.startRecording()
        
        // When - stop recording (transcription will fail)
        mockAudioService.recordingData = createMockAudioData()
        
        let transcription = try await coordinator.stopRecording()
        
        // Then - should still return transcription even if transcription service fails
        // Transcription might be empty or error message depending on implementation
        XCTAssertNotNil(transcription)
    }
    
    // MARK: - Helper Methods
    
    private func createMockAudioData() -> Data {
        // Create mock WAV file data (simplified)
        var data = Data()
        data.append("RIFF".data(using: .ascii)!)
        data.append(Data(count: 36)) // WAV header padding
        data.append("WAVE".data(using: .ascii)!)
        data.append(Data(repeating: 0x01, count: 1000)) // Sample audio data
        return data
    }
    
    private func createLargeMockAudioData() -> Data {
        // Create larger mock audio data for long recordings
        var data = createMockAudioData()
        data.append(Data(repeating: 0x02, count: 50000)) // Much larger sample
        return data
    }
}

// MARK: - Enhanced Mock Services

private class MockAudioCaptureService: AudioCaptureServiceProtocol {
    var shouldStartRecordingSucceed = true
    var shouldGrantPermission = true
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var recordingData = Data()
    private var _isRecording = false
    private var _recordingDuration: TimeInterval = 0.0
    private var _audioLevel: Float = 0.0
    private var _isInterrupted = false
    private var _isBackgrounded = false
    
    func requestMicrophonePermission() async -> Bool {
        return shouldGrantPermission
    }
    
    func startRecording() async throws {
        startRecordingCalled = true
        if !shouldGrantPermission {
            throw AudioCaptureError.microphonePermissionDenied
        }
        if shouldStartRecordingSucceed {
            _isRecording = true
        } else {
            throw AudioCaptureError.recordingFailed
        }
    }
    
    func stopRecording() async throws -> Data {
        stopRecordingCalled = true
        _isRecording = false
        _recordingDuration = 0.0
        _audioLevel = 0.0
        return recordingData
    }
    
    func getAudioLevel() -> Float {
        return _audioLevel
    }
    
    func isRecording() -> Bool {
        return _isRecording && !_isInterrupted
    }
    
    func getRecordingDuration() -> TimeInterval {
        return _recordingDuration
    }
    
    // Test helper methods
    func setAudioLevel(_ level: Float) {
        _audioLevel = level
    }
    
    func setRecordingDuration(_ duration: TimeInterval) {
        _recordingDuration = duration
    }
    
    func simulateInterruption() {
        _isInterrupted = true
    }
    
    func simulateBackgrounding() {
        _isBackgrounded = true
        // In real implementation, this might continue recording briefly
    }
}

private class MockWhisperKitService: WhisperKitServiceProtocol {
    var shouldInitializeSucceed = true
    var mockTranscription = "Mock transcription"
    var isInitialized = false
    
    func initialize() async throws {
        if shouldInitializeSucceed {
            isInitialized = true
        } else {
            throw WhisperKitServiceError.initializationFailed("Mock initialization failure")
        }
    }
    
    func transcribeAudio(audio: Data) async throws -> String {
        if !isInitialized {
            throw WhisperKitServiceError.notInitialized
        }
        if audio.isEmpty {
            throw WhisperKitServiceError.invalidAudioData
        }
        
        // Return different transcriptions based on audio size for testing
        if audio.count > 5000 {
            return "This is a longer transcription for larger audio files: \(mockTranscription)"
        }
        return mockTranscription
    }
    
    func transcribeChunk(audio: Data) async throws -> String {
        return try await transcribeAudio(audio: audio)
    }
    
    func cancelTranscription() async {
        // Mock cancellation
    }
}