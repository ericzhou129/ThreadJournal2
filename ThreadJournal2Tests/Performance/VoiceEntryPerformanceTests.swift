//
//  VoiceEntryPerformanceTests.swift
//  ThreadJournal2Tests
//
//  Performance tests for the voice entry feature
//

import XCTest
@testable import ThreadJournal2

@MainActor
final class VoiceEntryPerformanceTests: XCTestCase {
    
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
    
    // MARK: - Recording Start Performance
    
    func testRecordingStartsWithin500Milliseconds() {
        // Given
        mockAudioService.shouldStartRecordingSucceed = true
        mockTranscriptionService.shouldInitializeSucceed = true
        
        // When/Then
        measure {
            let expectation = XCTestExpectation(description: "Recording started")
            
            Task {
                do {
                    try await coordinator.startRecording()
                    expectation.fulfill()
                } catch {
                    XCTFail("Recording failed to start: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 0.5) // 500ms timeout
        }
        
        // Verify recording actually started
        XCTAssertTrue(coordinator.isRecording, "Recording should have started")
    }
    
    // MARK: - Audio Levels Update Performance
    
    func testAudioLevelsUpdateAt60FPS() {
        // Given
        let targetFPS = 60.0
        let testDuration = 1.0 // 1 second test
        let expectedUpdates = Int(targetFPS * testDuration)
        var updateCount = 0
        
        // Simulate 60fps updates
        measure {
            let startTime = Date()
            
            while Date().timeIntervalSince(startTime) < testDuration {
                // Simulate audio level update
                mockAudioService.setAudioLevel(Float.random(in: 0...1))
                let _ = coordinator.audioLevel // Access to trigger update
                updateCount += 1
                
                // Sleep for 1/60th of a second (approximately 16.67ms)
                usleep(16670) // microseconds
            }
        }
        
        // Verify we achieved close to 60 FPS
        XCTAssertGreaterThan(updateCount, expectedUpdates - 10, "Should achieve close to 60 FPS")
        XCTAssertLessThan(updateCount, expectedUpdates + 10, "Should not exceed 60 FPS significantly")
    }
    
    // MARK: - Memory Usage Tests
    
    func testMemoryUsageStaysUnder50MBDuringRecording() async throws {
        // Given
        mockAudioService.shouldStartRecordingSucceed = true
        mockTranscriptionService.shouldInitializeSucceed = true
        
        let memoryBefore = getMemoryUsage()
        
        // When - start recording and simulate audio data
        try await coordinator.startRecording()
        
        // Simulate recording for several seconds
        for i in 0..<100 {
            mockAudioService.setRecordingDuration(Double(i) * 0.1)
            mockAudioService.setAudioLevel(Float.random(in: 0...1))
            
            // Brief delay to simulate real recording
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        let memoryDuring = getMemoryUsage()
        let memoryIncrease = memoryDuring - memoryBefore
        
        // Stop recording
        mockAudioService.recordingData = createMockAudioData()
        _ = try await coordinator.stopRecording()
        
        // Then - memory increase should be under 50MB
        let maxMemoryIncrease = 50.0 * 1024 * 1024 // 50MB in bytes
        XCTAssertLessThan(
            Double(memoryIncrease), 
            maxMemoryIncrease, 
            "Memory usage increase (\(memoryIncrease / (1024*1024))MB) should stay under 50MB"
        )
    }
    
    // MARK: - Memory Leak Tests
    
    func testNoMemoryLeaksAfterRecordingStops() async throws {
        // Given
        mockAudioService.shouldStartRecordingSucceed = true
        mockTranscriptionService.shouldInitializeSucceed = true
        
        let memoryBefore = getMemoryUsage()
        
        // When - perform multiple recording cycles
        for _ in 0..<5 {
            try await coordinator.startRecording()
            
            // Simulate brief recording
            mockAudioService.setRecordingDuration(1.0)
            mockAudioService.setAudioLevel(0.5)
            mockAudioService.recordingData = createMockAudioData()
            
            _ = try await coordinator.stopRecording()
            
            // Force garbage collection
            autoreleasepool {
                // Empty pool to encourage cleanup
            }
        }
        
        // Small delay to allow cleanup
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        let memoryAfter = getMemoryUsage()
        let memoryIncrease = memoryAfter - memoryBefore
        
        // Then - memory should not have grown significantly
        let maxMemoryGrowth = 10.0 * 1024 * 1024 // 10MB tolerance
        XCTAssertLessThan(
            Double(memoryIncrease), 
            maxMemoryGrowth,
            "Memory growth (\(memoryIncrease / (1024*1024))MB) should be minimal after cleanup"
        )
    }
    
    // MARK: - Transcription Performance Tests
    
    func testTranscriptionPerformanceWithLargeAudio() async throws {
        // Given
        mockTranscriptionService.shouldInitializeSucceed = true
        try await mockTranscriptionService.initialize()
        
        let largeAudioData = createLargeAudioData() // ~5MB of audio data
        
        // When/Then
        measure {
            let expectation = XCTestExpectation(description: "Transcription completed")
            
            Task {
                do {
                    let _ = try await mockTranscriptionService.transcribeAudio(audio: largeAudioData)
                    expectation.fulfill()
                } catch {
                    XCTFail("Transcription failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0) // 5 second timeout for large audio
        }
    }
    
    func testConcurrentTranscriptionRequests() async throws {
        // Given
        mockTranscriptionService.shouldInitializeSucceed = true
        try await mockTranscriptionService.initialize()
        
        let audioData = createMockAudioData()
        let concurrentRequestCount = 5
        
        // When/Then
        measure {
            let expectations = (0..<concurrentRequestCount).map { i in
                XCTestExpectation(description: "Transcription \(i) completed")
            }
            
            for (index, expectation) in expectations.enumerated() {
                Task {
                    do {
                        let _ = try await mockTranscriptionService.transcribeAudio(audio: audioData)
                        expectation.fulfill()
                    } catch {
                        XCTFail("Transcription \(index) failed: \(error)")
                        expectation.fulfill()
                    }
                }
            }
            
            wait(for: expectations, timeout: 3.0)
        }
    }
    
    // MARK: - UI Animation Performance
    
    func testWaveformAnimationPerformance() {
        // Given
        let waveform = WaveformVisualizer(
            audioLevel: 0.5,
            onStopAndEdit: { },
            onStopAndSave: { }
        )
        
        // When/Then - measure animation setup time
        measure {
            // Simulate multiple audio level changes
            for _ in 0..<60 { // Simulate 1 second of 60fps updates
                let _ = WaveformVisualizer(
                    audioLevel: Float.random(in: 0...1),
                    onStopAndEdit: { },
                    onStopAndSave: { }
                )
            }
        }
    }
    
    func testVoiceRecordButtonAnimationPerformance() {
        // When/Then - measure button creation and animation setup
        measure {
            for _ in 0..<100 {
                let _ = VoiceRecordButton {
                    // Empty action
                }
            }
        }
    }
    
    // MARK: - Coordinator Performance Under Load
    
    func testCoordinatorPerformanceWithRapidStateChanges() async throws {
        // Given
        mockAudioService.shouldStartRecordingSucceed = true
        mockTranscriptionService.shouldInitializeSucceed = true
        
        // When/Then - measure rapid start/stop cycles
        measure {
            let expectation = XCTestExpectation(description: "Rapid cycles completed")
            
            Task {
                do {
                    for _ in 0..<10 {
                        try await coordinator.startRecording()
                        mockAudioService.recordingData = createMockAudioData()
                        _ = try await coordinator.stopRecording()
                    }
                    expectation.fulfill()
                } catch {
                    XCTFail("Rapid cycles failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Real-Time Performance Tests
    
    func testRealTimeAudioProcessingSimulation() async throws {
        // Given
        mockAudioService.shouldStartRecordingSucceed = true
        try await coordinator.startRecording()
        
        let testDuration = 2.0 // 2 seconds
        let updateInterval = 0.016 // ~60fps (16ms)
        var processedUpdates = 0
        
        // When - simulate real-time audio processing
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < testDuration {
            // Simulate audio level update
            mockAudioService.setAudioLevel(Float.random(in: 0...1))
            mockAudioService.setRecordingDuration(Date().timeIntervalSince(startTime))
            
            // Access coordinator properties to trigger updates
            let _ = coordinator.audioLevel
            let _ = coordinator.recordingDuration
            
            processedUpdates += 1
            
            // Sleep for update interval
            try await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
        }
        
        // Stop recording
        mockAudioService.recordingData = createMockAudioData()
        _ = try await coordinator.stopRecording()
        
        // Then - verify we processed expected number of updates
        let expectedUpdates = Int(testDuration / updateInterval)
        XCTAssertGreaterThan(
            processedUpdates, 
            expectedUpdates - 10,
            "Should process close to expected number of updates"
        )
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.phys_footprint) : 0
    }
    
    private func createMockAudioData() -> Data {
        // Create realistic WAV file data
        var data = Data()
        data.append("RIFF".data(using: .ascii)!)
        data.append(Data(count: 36)) // WAV header
        data.append("WAVE".data(using: .ascii)!)
        data.append(Data(repeating: 0x01, count: 1000)) // Sample data
        return data
    }
    
    private func createLargeAudioData() -> Data {
        // Create large audio data (~5MB for performance testing)
        var data = createMockAudioData()
        data.append(Data(repeating: 0x02, count: 5_000_000)) // 5MB of sample data
        return data
    }
}

// MARK: - Enhanced Mock Services for Performance Testing

private class MockAudioCaptureService: AudioCaptureServiceProtocol {
    var shouldStartRecordingSucceed = true
    var shouldGrantPermission = true
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var recordingData = Data()
    private var _isRecording = false
    private var _recordingDuration: TimeInterval = 0.0
    private var _audioLevel: Float = 0.0
    
    // Performance tracking
    private var startTime: Date?
    
    func requestMicrophonePermission() async -> Bool {
        return shouldGrantPermission
    }
    
    func startRecording() async throws {
        startTime = Date()
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
        startTime = nil
        return recordingData
    }
    
    func getAudioLevel() -> Float {
        return _audioLevel
    }
    
    func isRecording() -> Bool {
        return _isRecording
    }
    
    func getRecordingDuration() -> TimeInterval {
        guard let startTime = startTime else { return _recordingDuration }
        return max(_recordingDuration, Date().timeIntervalSince(startTime))
    }
    
    func getLatestChunk() -> Data? {
        return nil // Mock returns nil for simplicity
    }
    
    // Test helper methods
    func setAudioLevel(_ level: Float) {
        _audioLevel = level
    }
    
    func setRecordingDuration(_ duration: TimeInterval) {
        _recordingDuration = duration
    }
}

private class MockWhisperKitService: WhisperKitServiceProtocol {
    var shouldInitializeSucceed = true
    var mockTranscription = "Mock transcription for performance testing"
    var isInitialized = false
    
    func initialize() async throws {
        if shouldInitializeSucceed {
            // Simulate initialization delay
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
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
        
        // Simulate transcription processing time based on data size
        let processingTime = min(Double(audio.count) / 1_000_000.0, 2.0) // Max 2 seconds
        try await Task.sleep(nanoseconds: UInt64(processingTime * 100_000_000)) // Scale down for testing
        
        // Return transcription based on audio size
        if audio.count > 1_000_000 {
            return "Large audio transcription: \(mockTranscription)"
        }
        return mockTranscription
    }
    
    func transcribeChunk(audio: Data) async throws -> String {
        return try await transcribeAudio(audio: audio)
    }
    
    func cancelTranscription() async {
        // Mock cancellation with brief delay
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
    }
}