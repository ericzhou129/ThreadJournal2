import XCTest
import Foundation
@testable import ThreadJournal2

final class WhisperKitServiceTests: XCTestCase {
    
    var mockService: MockWhisperKitService!
    
    override func setUp() {
        super.setUp()
        mockService = MockWhisperKitService()
    }
    
    override func tearDown() {
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        // Given
        let service = MockWhisperKitService()
        
        // Then
        XCTAssertFalse(service.isInitialized, "Service should not be initialized initially")
    }
    
    func testInitializeSuccess() async throws {
        // Given
        XCTAssertFalse(mockService.isInitialized, "Service should start uninitialized")
        
        // When
        try await mockService.initialize()
        
        // Then
        XCTAssertTrue(mockService.isInitialized, "Service should be initialized after initialize()")
    }
    
    func testInitializeIsIdempotent() async throws {
        // Given
        try await mockService.initialize()
        XCTAssertTrue(mockService.isInitialized)
        
        // When - initialize again
        try await mockService.initialize()
        
        // Then - should remain initialized without error
        XCTAssertTrue(mockService.isInitialized)
    }
    
    // MARK: - Transcription Tests
    
    func testTranscribeChunkWithValidAudio() async throws {
        // Given
        try await mockService.initialize()
        let audioData = Data(repeating: 0x01, count: 1000)
        
        // When
        let transcription = try await mockService.transcribeChunk(audio: audioData)
        
        // Then
        XCTAssertFalse(transcription.isEmpty, "Transcription should not be empty")
        XCTAssertEqual(transcription, "Hello", "Mock should return expected transcription")
    }
    
    func testTranscribeChunkWithLargerAudio() async throws {
        // Given
        try await mockService.initialize()
        let audioData = Data(repeating: 0x01, count: 5000)
        
        // When
        let transcription = try await mockService.transcribeChunk(audio: audioData)
        
        // Then
        XCTAssertFalse(transcription.isEmpty, "Transcription should not be empty")
        XCTAssertTrue(transcription.contains("Hello world"), "Should return multiple words for larger audio")
    }
    
    func testTranscribeChunkNotInitialized() async {
        // Given
        XCTAssertFalse(mockService.isInitialized)
        let audioData = Data(repeating: 0x01, count: 1000)
        
        // When/Then
        do {
            _ = try await mockService.transcribeChunk(audio: audioData)
            XCTFail("Should throw notInitialized error")
        } catch WhisperKitServiceError.notInitialized {
            // Expected
        } catch {
            XCTFail("Should throw notInitialized error, got \(error)")
        }
    }
    
    func testTranscribeChunkWithEmptyAudio() async {
        // Given
        try? await mockService.initialize()
        let emptyAudio = Data()
        
        // When/Then
        do {
            _ = try await mockService.transcribeChunk(audio: emptyAudio)
            XCTFail("Should throw invalidAudioData error")
        } catch WhisperKitServiceError.invalidAudioData {
            // Expected
        } catch {
            XCTFail("Should throw invalidAudioData error, got \(error)")
        }
    }
    
    func testTranscribeAudioUsesChunkMethod() async throws {
        // Given
        try await mockService.initialize()
        let audioData = Data(repeating: 0x01, count: 1000)
        
        // When
        let chunkResult = try await mockService.transcribeChunk(audio: audioData)
        let audioResult = try await mockService.transcribeAudio(audio: audioData)
        
        // Then
        XCTAssertEqual(chunkResult, audioResult, "transcribeAudio should use same logic as transcribeChunk")
    }
    
    // MARK: - Cancellation Tests
    
    func testCancelTranscription() async {
        // Given
        try? await mockService.initialize()
        
        // When/Then - should not throw
        await mockService.cancelTranscription()
    }
    
    // MARK: - Real Service Initialization Tests
    
    func testRealServiceInitialState() {
        // Given
        let realService = WhisperKitService()
        
        // Then
        XCTAssertFalse(realService.isInitialized, "Real service should not be initialized initially")
    }
    
    func testRealServiceCancellation() async {
        // Given
        let realService = WhisperKitService()
        
        // When/Then - should not throw
        await realService.cancelTranscription()
    }
    
    // MARK: - Performance Tests
    
    func testTranscribeChunkPerformance() async throws {
        // Given
        try await mockService.initialize()
        let audioData = Data(repeating: 0x01, count: 2000) // 2-second chunk equivalent
        
        // When/Then
        measure {
            let expectation = XCTestExpectation(description: "Transcription completed")
            
            Task {
                do {
                    _ = try await mockService.transcribeChunk(audio: audioData)
                    expectation.fulfill()
                } catch {
                    XCTFail("Transcription failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    func testMultipleTranscriptionRequests() async throws {
        // Given
        try await mockService.initialize()
        let audioData = Data(repeating: 0x01, count: 1000)
        let requestCount = 5
        
        // When
        let transcriptions = try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<requestCount {
                group.addTask {
                    try await self.mockService.transcribeChunk(audio: audioData)
                }
            }
            
            var results: [String] = []
            for try await transcription in group {
                results.append(transcription)
            }
            return results
        }
        
        // Then
        XCTAssertEqual(transcriptions.count, requestCount, "Should handle multiple concurrent requests")
        transcriptions.forEach { transcription in
            XCTAssertFalse(transcription.isEmpty, "Each transcription should be non-empty")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorDescriptions() {
        // Given/When/Then
        XCTAssertEqual(
            WhisperKitServiceError.notInitialized.errorDescription,
            "WhisperKit service not initialized"
        )
        
        XCTAssertEqual(
            WhisperKitServiceError.invalidAudioData.errorDescription,
            "Invalid audio data provided"
        )
        
        XCTAssertEqual(
            WhisperKitServiceError.initializationFailed("test").errorDescription,
            "WhisperKit initialization failed: test"
        )
        
        XCTAssertEqual(
            WhisperKitServiceError.transcriptionFailed("test").errorDescription,
            "Transcription failed: test"
        )
        
        XCTAssertEqual(
            WhisperKitServiceError.modelNotFound.errorDescription,
            "Whisper model not found in bundle"
        )
    }
    
    // MARK: - Integration Tests
    
    func testServiceProtocolConformance() {
        // Given
        let realService: WhisperKitServiceProtocol = WhisperKitService()
        let mockService: WhisperKitServiceProtocol = MockWhisperKitService()
        
        // Then - both should conform to the protocol
        XCTAssertFalse(realService.isInitialized)
        XCTAssertFalse(mockService.isInitialized)
    }
}