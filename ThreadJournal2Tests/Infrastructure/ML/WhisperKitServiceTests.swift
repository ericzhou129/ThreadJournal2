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
    
    // MARK: - WAV Parsing Tests
    
    func testExtractFloat32FromWAVData() {
        // Given - Create a simple WAV file with Float32 PCM data
        let service = WhisperKitService()
        let testSamples: [Float] = [0.1, 0.2, -0.1, -0.2, 0.0]
        let wavData = createTestWAVFile(samples: testSamples)
        
        // When
        let extractedSamples = service.extractFloat32FromWAVDataForTesting(wavData)
        
        // Then
        XCTAssertNotNil(extractedSamples, "Should successfully extract samples from WAV data")
        XCTAssertEqual(extractedSamples?.count, testSamples.count, "Should extract correct number of samples")
        
        if let extracted = extractedSamples {
            for (index, expectedSample) in testSamples.enumerated() {
                XCTAssertEqual(extracted[index], expectedSample, accuracy: 0.0001, 
                             "Sample \(index) should match expected value")
            }
        }
    }
    
    func testExtractFloat32FromInvalidWAVData() {
        // Given
        let service = WhisperKitService()
        let invalidData = Data(repeating: 0xFF, count: 100)
        
        // When
        let extractedSamples = service.extractFloat32FromWAVDataForTesting(invalidData)
        
        // Then
        XCTAssertNil(extractedSamples, "Should return nil for invalid WAV data")
    }
    
    func testExtractFloat32FromEmptyData() {
        // Given
        let service = WhisperKitService()
        let emptyData = Data()
        
        // When
        let extractedSamples = service.extractFloat32FromWAVDataForTesting(emptyData)
        
        // Then
        XCTAssertNil(extractedSamples, "Should return nil for empty data")
    }
    
    private func createTestWAVFile(samples: [Float]) -> Data {
        var data = Data()
        
        // RIFF header
        data.append("RIFF".data(using: .ascii)!)
        
        // File size placeholder (will be updated)
        let fileSizePlaceholder = data.count
        data.append(Data(count: 4)) // Placeholder for file size
        
        // WAVE format
        data.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        data.append("fmt ".data(using: .ascii)!)
        
        // fmt chunk size (16 bytes for PCM)
        let fmtSize: UInt32 = 16
        data.append(withUnsafeBytes(of: fmtSize.littleEndian) { Data($0) })
        
        // Audio format (3 = IEEE Float)
        let audioFormat: UInt16 = 3
        data.append(withUnsafeBytes(of: audioFormat.littleEndian) { Data($0) })
        
        // Number of channels (1 = mono)
        let numChannels: UInt16 = 1
        data.append(withUnsafeBytes(of: numChannels.littleEndian) { Data($0) })
        
        // Sample rate (44100 Hz)
        let sampleRate: UInt32 = 44100
        data.append(withUnsafeBytes(of: sampleRate.littleEndian) { Data($0) })
        
        // Byte rate (sampleRate * numChannels * bitsPerSample / 8)
        let byteRate: UInt32 = 44100 * 1 * 32 / 8
        data.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        
        // Block align (numChannels * bitsPerSample / 8)
        let blockAlign: UInt16 = 1 * 32 / 8
        data.append(withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        
        // Bits per sample (32 for Float32)
        let bitsPerSample: UInt16 = 32
        data.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })
        
        // data chunk
        data.append("data".data(using: .ascii)!)
        
        // data chunk size
        let dataSize: UInt32 = UInt32(samples.count * MemoryLayout<Float>.size)
        data.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })
        
        // PCM data (Float32 samples)
        for sample in samples {
            data.append(withUnsafeBytes(of: sample) { Data($0) })
        }
        
        // Update file size in header (total size - 8 bytes for RIFF header)
        let totalFileSize = UInt32(data.count - 8)
        data.replaceSubrange(fileSizePlaceholder..<(fileSizePlaceholder + 4), 
                           with: withUnsafeBytes(of: totalFileSize.littleEndian) { Data($0) })
        
        return data
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