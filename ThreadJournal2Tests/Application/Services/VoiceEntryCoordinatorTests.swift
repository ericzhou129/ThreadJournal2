//
//  VoiceEntryCoordinatorTests.swift
//  ThreadJournal2Tests
//
//  Unit tests for VoiceEntryCoordinator
//

import XCTest
@testable import ThreadJournal2

@MainActor
final class VoiceEntryCoordinatorTests: XCTestCase {
    
    private var coordinator: VoiceEntryCoordinator!
    private var mockAudioService: MockAudioCaptureService!
    private var mockTranscriptionService: MockWhisperKitServiceCoordinator!
    
    override func setUp() {
        super.setUp()
        mockAudioService = MockAudioCaptureService()
        mockTranscriptionService = MockWhisperKitServiceCoordinator()
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
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(coordinator.audioLevel, 0.0)
        XCTAssertEqual(coordinator.recordingDuration, 0.0)
        XCTAssertFalse(coordinator.isRecording)
        XCTAssertNil(coordinator.error)
    }
    
    // MARK: - Recording Flow Tests
    
    func testStartRecording_Success() async throws {
        // Given
        mockAudioService.shouldStartRecordingSucceed = true
        
        // When
        try await coordinator.startRecording()
        
        // Then
        XCTAssertTrue(coordinator.isRecording)
        XCTAssertTrue(mockAudioService.startRecordingCalled)
    }
    
    func testStartRecording_AudioServiceFailure() async {
        // Given
        mockAudioService.shouldStartRecordingSucceed = false
        
        // When/Then
        do {
            try await coordinator.startRecording()
            XCTFail("Expected audio service error")
        } catch {
            XCTAssertFalse(coordinator.isRecording)
            XCTAssertTrue(mockAudioService.startRecordingCalled)
        }
    }
    
    func testStopRecording_Success() async throws {
        // Given
        await startRecordingSuccessfully()
        let testAudioData = "test audio data".data(using: .utf8)!
        mockAudioService.recordingData = testAudioData
        mockTranscriptionService.mockTranscription = "Test transcription"
        
        // When
        let result = try await coordinator.stopRecording()
        
        // Then
        XCTAssertFalse(coordinator.isRecording)
        XCTAssertTrue(mockAudioService.stopRecordingCalled)
        XCTAssertEqual(result, "Test transcription")
    }
    
    func testCancelRecording() async {
        // Given
        await startRecordingSuccessfully()
        
        // When
        await coordinator.cancelRecording()
        
        // Then
        XCTAssertFalse(coordinator.isRecording)
        XCTAssertTrue(mockAudioService.stopRecordingCalled)
        XCTAssertEqual(coordinator.audioLevel, 0.0)
        XCTAssertEqual(coordinator.recordingDuration, 0.0)
    }
    
    // MARK: - Simplified Flow Tests
    
    func testSimplifiedTranscriptionFlow() async throws {
        // Given
        mockAudioService.shouldStartRecordingSucceed = true
        mockTranscriptionService.shouldInitializeSucceed = true
        let testAudioData = "test audio data".data(using: .utf8)!
        mockAudioService.recordingData = testAudioData
        mockTranscriptionService.mockTranscription = "Final transcription result"
        
        // When - start and immediately stop recording
        try await coordinator.startRecording()
        XCTAssertTrue(coordinator.isRecording)
        
        let transcription = try await coordinator.stopRecording()
        
        // Then - should get final transcription only
        XCTAssertFalse(coordinator.isRecording)
        XCTAssertEqual(transcription, "Final transcription result")
        XCTAssertTrue(mockAudioService.stopRecordingCalled)
    }
    
    func testTranscriptionServiceInitializationOnStart() async throws {
        // Given
        mockAudioService.shouldStartRecordingSucceed = true
        mockTranscriptionService.shouldInitializeSucceed = true
        mockTranscriptionService.isInitialized = false
        
        // When
        try await coordinator.startRecording()
        
        // Then
        XCTAssertTrue(mockTranscriptionService.isInitialized)
        XCTAssertTrue(coordinator.isRecording)
        
        // Cleanup
        mockAudioService.recordingData = Data()
        _ = try await coordinator.stopRecording()
    }
    
    func testTranscriptionFailureHandling() async throws {
        // Given
        mockAudioService.shouldStartRecordingSucceed = true
        mockTranscriptionService.shouldInitializeSucceed = true
        let testAudioData = "test audio data".data(using: .utf8)!
        mockAudioService.recordingData = testAudioData
        mockTranscriptionService.shouldFailTranscription = true
        
        // When
        try await coordinator.startRecording()
        
        // Then - should throw transcription error
        do {
            _ = try await coordinator.stopRecording()
            XCTFail("Expected transcription error")
        } catch {
            XCTAssertFalse(coordinator.isRecording)
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func startRecordingSuccessfully() async {
        mockAudioService.shouldStartRecordingSucceed = true
        mockTranscriptionService.shouldInitializeSucceed = true
        try? await coordinator.startRecording()
    }
}

// MARK: - Mock Services

private class MockAudioCaptureService: AudioCaptureServiceProtocol {
    var shouldStartRecordingSucceed = true
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var recordingData = Data()
    private var _isRecording = false
    private var _recordingDuration: TimeInterval = 0.0
    private var _audioLevel: Float = 0.0
    
    func requestMicrophonePermission() async -> Bool {
        return true
    }
    
    func startRecording() async throws {
        startRecordingCalled = true
        if shouldStartRecordingSucceed {
            _isRecording = true
        } else {
            throw AudioCaptureError.recordingFailed
        }
    }
    
    func stopRecording() async throws -> Data {
        stopRecordingCalled = true
        _isRecording = false
        return recordingData
    }
    
    func getAudioLevel() -> Float {
        return _audioLevel
    }
    
    func isRecording() -> Bool {
        return _isRecording
    }
    
    func getRecordingDuration() -> TimeInterval {
        return _recordingDuration
    }
    
    
    // Helper methods for tests
    func setAudioLevel(_ level: Float) {
        _audioLevel = level
    }
    
    func setRecordingDuration(_ duration: TimeInterval) {
        _recordingDuration = duration
    }
}

private class MockWhisperKitServiceCoordinator: WhisperKitServiceProtocol {
    var shouldInitializeSucceed = true
    var shouldFailTranscription = false
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
        if shouldFailTranscription {
            throw WhisperKitServiceError.transcriptionFailed("Mock transcription failure")
        }
        
        // Return different transcriptions based on audio size for testing
        if audio.count > 5000 {
            return "This is a longer transcription for larger audio files: \(mockTranscription)"
        }
        return mockTranscription
    }
    
    func cancelTranscription() async {
        // Mock cancellation
    }
}