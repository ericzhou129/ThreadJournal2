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
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(coordinator.accumulatedTranscription, "")
        XCTAssertEqual(coordinator.currentPartialTranscription, "")
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
        XCTAssertEqual(coordinator.accumulatedTranscription, "")
        XCTAssertEqual(coordinator.currentPartialTranscription, "")
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
        
        // When
        let result = try await coordinator.stopRecording()
        
        // Then
        XCTAssertFalse(coordinator.isRecording)
        XCTAssertTrue(mockAudioService.stopRecordingCalled)
        XCTAssertEqual(coordinator.currentPartialTranscription, "")
    }
    
    func testCancelRecording() async {
        // Given
        await startRecordingSuccessfully()
        
        // When
        await coordinator.cancelRecording()
        
        // Then
        XCTAssertFalse(coordinator.isRecording)
        XCTAssertTrue(mockAudioService.stopRecordingCalled)
        XCTAssertEqual(coordinator.accumulatedTranscription, "")
        XCTAssertEqual(coordinator.currentPartialTranscription, "")
        XCTAssertEqual(coordinator.audioLevel, 0.0)
        XCTAssertEqual(coordinator.recordingDuration, 0.0)
    }
    
    // MARK: - Full Transcription Tests
    
    func testFullTranscription_Empty() {
        // Given/When
        let fullTranscription = coordinator.fullTranscription
        
        // Then
        XCTAssertEqual(fullTranscription, "")
    }
    
    // MARK: - Helper Methods
    
    private func startRecordingSuccessfully() async {
        mockAudioService.shouldStartRecordingSucceed = true
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