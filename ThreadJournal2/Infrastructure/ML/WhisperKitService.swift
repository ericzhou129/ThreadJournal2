import Foundation
import AVFoundation
import WhisperKit

/*
 * WhisperKit Integration: ACTIVE
 * 
 * This service uses WhisperKit for on-device speech recognition.
 * Configuration:
 * - Model: openai_whisper-small (multilingual, ~216MB)
 * - Download: Automatic on first use (Path B)
 * - Compute: CPU and Neural Engine
 * - Storage: Application Support directory
 */

// MARK: - Protocol

protocol WhisperKitServiceProtocol {
    func initialize() async throws
    func transcribeAudio(audio: Data) async throws -> String
    func cancelTranscription() async
    var isInitialized: Bool { get }
}

// MARK: - Errors

enum WhisperKitServiceError: LocalizedError {
    case notInitialized
    case initializationFailed(String)
    case transcriptionFailed(String)
    case invalidAudioData
    case modelNotFound
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "WhisperKit service not initialized"
        case .initializationFailed(let reason):
            return "WhisperKit initialization failed: \(reason)"
        case .transcriptionFailed(let reason):
            return "Transcription failed: \(reason)"
        case .invalidAudioData:
            return "Invalid audio data provided"
        case .modelNotFound:
            return "Whisper model not found in bundle"
        }
    }
}

// MARK: - Service Implementation

final class WhisperKitService: WhisperKitServiceProtocol {
    
    // MARK: - Properties
    
    private var whisperKit: WhisperKit?
    private let modelName = "openai_whisper-small"
    private var currentTask: Task<Void, Never>?
    
    private let audioQueue = DispatchQueue(label: "whisperkit.audio", qos: .userInitiated)
    
    // Download progress tracking (internal only)
    private var downloadProgress: Float = 0.0
    private var isDownloading = false
    
    var isInitialized: Bool {
        whisperKit != nil
    }
    
    // MARK: - Initialization
    
    init() {}
    
    func initialize() async throws {
        guard whisperKit == nil else { return }
        
        do {
            print("WhisperKitService: Initializing with model: \(modelName)")
            
            // Path A: Try to use bundled model first (if available)
            if let bundledModelPath = getBundledModelPath() {
                print("WhisperKitService: Found bundled model at \(bundledModelPath)")
                let bundledURL = URL(fileURLWithPath: bundledModelPath).deletingLastPathComponent()
                whisperKit = try await WhisperKit(
                    model: modelName,
                    downloadBase: bundledURL,
                    computeOptions: .init(audioEncoderCompute: .cpuAndNeuralEngine,
                                         textDecoderCompute: .cpuAndNeuralEngine),
                    verbose: true,
                    logLevel: .debug
                )
            } else {
                // Path B: Use WhisperKit's automatic download mechanism
                // This will download from HuggingFace and cache locally if needed
                print("WhisperKitService: Using WhisperKit with automatic model management...")
                
                whisperKit = try await WhisperKit(
                    model: modelName,
                    computeOptions: .init(audioEncoderCompute: .cpuAndNeuralEngine,
                                         textDecoderCompute: .cpuAndNeuralEngine),
                    verbose: true,
                    logLevel: .debug,
                    prewarm: true
                )
                
                print("WhisperKitService: Model initialized successfully")
            }
            
            guard whisperKit != nil else {
                throw WhisperKitServiceError.initializationFailed("Failed to create WhisperKit instance")
            }
            
            print("WhisperKitService: Successfully initialized with \(modelName)")
            
        } catch let error {
            isDownloading = false
            print("WhisperKitService: Initialization failed: \(error)")
            throw WhisperKitServiceError.initializationFailed(error.localizedDescription)
        }
    }
    
    
    // MARK: - Transcription Methods
    
    
    func transcribeAudio(audio: Data) async throws -> String {
        guard let whisperKit = whisperKit else {
            throw WhisperKitServiceError.notInitialized
        }
        
        guard !audio.isEmpty else {
            throw WhisperKitServiceError.invalidAudioData
        }
        
        do {
            // Convert audio data to the format expected by WhisperKit
            let audioArray = try convertAudioDataToFloatArray(audio)
            
            // Log audio array details
            print("WhisperKitService: Transcribing audio array with \(audioArray.count) samples")
            
            // Perform transcription for full audio
            let transcriptionResult = try await whisperKit.transcribe(
                audioArray: audioArray,
                decodeOptions: DecodingOptions(
                    task: .transcribe,
                    language: "en", // Force English to prevent language detection issues
                    temperatureFallbackCount: 3,
                    usePrefillPrompt: false,
                    skipSpecialTokens: true,
                    withoutTimestamps: false // Enable for word-level timing
                )
            )
            
            // Extract and return the transcribed text
            // WhisperKit returns an array of TranscriptionResult
            print("WhisperKitService: Got \(transcriptionResult.count) transcription results")
            
            if !transcriptionResult.isEmpty {
                // Log each transcription result for debugging
                for (index, result) in transcriptionResult.enumerated() {
                    print("WhisperKitService: Result \(index): \(result.segments.count) segments")
                    for (segIndex, segment) in result.segments.enumerated() {
                        print("WhisperKitService: Segment \(segIndex): '\(segment.text)'")
                    }
                }
                
                // Get all segments and combine their text
                let text = transcriptionResult
                    .flatMap { $0.segments }
                    .map { $0.text }
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !text.isEmpty {
                    print("WhisperKitService: Final transcription: '\(text)'")
                    return text
                } else {
                    print("WhisperKitService: WARNING - No text content in transcription results")
                }
            } else {
                print("WhisperKitService: WARNING - No transcription results returned")
            }
            
            return ""
            
        } catch {
            print("WhisperKitService: Transcription error: \(error)")
            throw WhisperKitServiceError.transcriptionFailed(error.localizedDescription)
        }
    }
    
    func cancelTranscription() async {
        currentTask?.cancel()
        currentTask = nil
    }
    
    // MARK: - Private Methods
    
    private func getBundledModelPath() -> String? {
        guard let bundlePath = Bundle.main.path(forResource: modelName, ofType: nil) else {
            return nil
        }
        return bundlePath
    }
    
    
    private func convertAudioDataToFloatArray(_ audioData: Data) throws -> [Float] {
        print("WhisperKitService: Converting audio data of size \(audioData.count) bytes")
        
        // AudioCaptureService outputs Float32 PCM data in WAV format
        // We need to extract the raw PCM Float32 samples from the WAV file
        
        // First, try to parse as WAV file and extract Float32 PCM data
        if let floatArray = extractFloat32FromWAVData(audioData), !floatArray.isEmpty {
            print("WhisperKitService: Successfully extracted \(floatArray.count) Float32 samples from WAV")
            
            // Validate the extracted audio data
            let maxValue = floatArray.max() ?? 0.0
            let minValue = floatArray.min() ?? 0.0
            let rms = sqrt(floatArray.map { $0 * $0 }.reduce(0, +) / Float(floatArray.count))
            
            print("WhisperKitService: Audio validation - min: \(minValue), max: \(maxValue), RMS: \(rms)")
            
            // Check for invalid audio data (infinity, NaN, or extreme values)
            if rms.isInfinite || rms.isNaN {
                print("WhisperKitService: ERROR - Invalid audio data (RMS is \(rms))")
                throw WhisperKitServiceError.invalidAudioData
            }
            
            // Check for unrealistic audio values (audio should typically be between -1 and 1)
            if abs(maxValue) > 10.0 || abs(minValue) > 10.0 {
                print("WhisperKitService: ERROR - Audio values out of range (min: \(minValue), max: \(maxValue))")
                throw WhisperKitServiceError.invalidAudioData
            }
            
            // Check if audio is silent (very low RMS indicates silence)
            if rms < 0.001 {
                print("WhisperKitService: WARNING - Audio appears to be silent (RMS: \(rms))")
                // Don't throw error for silence, just warn
            }
            
            return floatArray
        }
        
        // If WAV parsing fails, it's an error - don't try raw interpretation
        print("WhisperKitService: ERROR - Failed to parse WAV data. Audio data must be in proper WAV format.")
        throw WhisperKitServiceError.invalidAudioData
    }
    
    /// Extracts Float32 PCM data from a WAV file
    private func extractFloat32FromWAVData(_ wavData: Data) -> [Float]? {
        print("WhisperKitService: Parsing WAV data of size \(wavData.count) bytes")
        
        // WAV file format parsing
        guard wavData.count > 44 else { 
            print("WhisperKitService: WAV data too small (need >44 bytes, got \(wavData.count))")
            return nil 
        }
        
        // Check for WAV file signature "RIFF"
        let riffSignature = wavData.subdata(in: 0..<4)
        guard riffSignature == "RIFF".data(using: .ascii) else { 
            print("WhisperKitService: Missing RIFF signature")
            return nil 
        }
        
        // Get file size from RIFF header
        let riffSize = wavData.subdata(in: 4..<8).withUnsafeBytes {
            UInt32(littleEndian: $0.load(as: UInt32.self))
        }
        print("WhisperKitService: RIFF size: \(riffSize)")
        
        // Check for WAV format "WAVE"
        let waveSignature = wavData.subdata(in: 8..<12)
        guard waveSignature == "WAVE".data(using: .ascii) else { 
            print("WhisperKitService: Missing WAVE signature")
            return nil 
        }
        
        // Parse chunks to find format and data
        var audioFormat: UInt16 = 0
        var numChannels: UInt16 = 0
        var sampleRate: UInt32 = 0
        var bitsPerSample: UInt16 = 0
        var dataChunkData: Data? = nil
        
        var offset = 12
        while offset < wavData.count - 8 {
            let chunkId = wavData.subdata(in: offset..<offset+4)
            let chunkSize = wavData.subdata(in: offset+4..<offset+8).withUnsafeBytes {
                UInt32(littleEndian: $0.load(as: UInt32.self))
            }
            
            print("WhisperKitService: Found chunk '\(String(data: chunkId, encoding: .ascii) ?? "unknown")' with size \(chunkSize)")
            
            if chunkId == "fmt ".data(using: .ascii) {
                // Format chunk - extract audio format information
                let fmtStart = offset + 8
                guard fmtStart + 16 <= wavData.count else {
                    print("WhisperKitService: fmt chunk too small")
                    return nil
                }
                
                audioFormat = wavData.subdata(in: fmtStart..<fmtStart+2).withUnsafeBytes {
                    UInt16(littleEndian: $0.load(as: UInt16.self))
                }
                numChannels = wavData.subdata(in: fmtStart+2..<fmtStart+4).withUnsafeBytes {
                    UInt16(littleEndian: $0.load(as: UInt16.self))
                }
                sampleRate = wavData.subdata(in: fmtStart+4..<fmtStart+8).withUnsafeBytes {
                    UInt32(littleEndian: $0.load(as: UInt32.self))
                }
                
                // Skip byte rate (4 bytes) and block align (2 bytes)
                if fmtStart + 16 <= wavData.count {
                    bitsPerSample = wavData.subdata(in: fmtStart+14..<fmtStart+16).withUnsafeBytes {
                        UInt16(littleEndian: $0.load(as: UInt16.self))
                    }
                }
                
                print("WhisperKitService: Format - audioFormat: \(audioFormat), channels: \(numChannels), sampleRate: \(sampleRate), bitsPerSample: \(bitsPerSample)")
                
            } else if chunkId == "data".data(using: .ascii) {
                // Data chunk - extract PCM samples
                let dataStart = offset + 8
                let dataEnd = min(dataStart + Int(chunkSize), wavData.count)
                dataChunkData = wavData.subdata(in: dataStart..<dataEnd)
                print("WhisperKitService: Found data chunk with \(dataChunkData?.count ?? 0) bytes")
            }
            
            // Move to next chunk (with proper alignment)
            let alignedChunkSize = (Int(chunkSize) + 1) & ~1 // Align to even boundary
            offset += 8 + alignedChunkSize
        }
        
        // Validate format
        guard audioFormat == 3, // IEEE Float (32-bit float)
              numChannels == 1,   // Mono
              bitsPerSample == 32 // 32-bit
        else {
            print("WhisperKitService: Unsupported audio format - format: \(audioFormat), channels: \(numChannels), bits: \(bitsPerSample)")
            return nil
        }
        
        // Extract Float32 samples from data chunk
        guard let pcmData = dataChunkData, !pcmData.isEmpty else {
            print("WhisperKitService: No PCM data found")
            return nil
        }
        
        let floatArray = pcmData.withUnsafeBytes { bytes in
            Array(bytes.bindMemory(to: Float.self))
        }
        
        print("WhisperKitService: Successfully extracted \(floatArray.count) Float32 samples")
        return floatArray
    }
    
    deinit {
        currentTask?.cancel()
    }
    
    // MARK: - Testing Support
    
    /// Exposed for testing purposes only
    func extractFloat32FromWAVDataForTesting(_ wavData: Data) -> [Float]? {
        return extractFloat32FromWAVData(wavData)
    }
    
    /// Test method to validate WAV parsing with a minimal WAV file
    func testWAVParsingWithSampleData() {
        print("WhisperKitService: Testing WAV parsing with sample data")
        
        // Create a minimal WAV file with Float32 PCM data
        let testSamples: [Float] = [0.1, -0.1, 0.2, -0.2, 0.0]
        let wavData = createTestWAVFile(samples: testSamples)
        
        print("WhisperKitService: Created test WAV file with \(wavData.count) bytes")
        
        // Test the parsing
        if let extractedSamples = extractFloat32FromWAVData(wavData) {
            print("WhisperKitService: Successfully parsed \(extractedSamples.count) samples")
            print("WhisperKitService: Original samples: \(testSamples)")
            print("WhisperKitService: Extracted samples: \(extractedSamples)")
            
            // Verify samples match
            let samplesMatch = zip(testSamples, extractedSamples).allSatisfy { abs($0.0 - $0.1) < 0.0001 }
            print("WhisperKitService: Samples match: \(samplesMatch)")
        } else {
            print("WhisperKitService: ERROR - Failed to parse test WAV file")
        }
    }
    
    private func createTestWAVFile(samples: [Float]) -> Data {
        var data = Data()
        
        // RIFF header
        data.append("RIFF".data(using: .ascii)!)
        
        // File size (will be updated later)
        let fileSizeOffset = data.count
        data.append(Data(count: 4)) // Placeholder for file size
        
        // WAVE format
        data.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        data.append("fmt ".data(using: .ascii)!)
        
        // fmt chunk size (16 bytes for basic PCM)
        let fmtSize: UInt32 = 16
        data.append(withUnsafeBytes(of: fmtSize.littleEndian) { Data($0) })
        
        // Audio format (3 = IEEE Float)
        let audioFormat: UInt16 = 3
        data.append(withUnsafeBytes(of: audioFormat.littleEndian) { Data($0) })
        
        // Number of channels (1 = mono)
        let numChannels: UInt16 = 1
        data.append(withUnsafeBytes(of: numChannels.littleEndian) { Data($0) })
        
        // Sample rate (16000 Hz - Whisper requirement)
        let sampleRate: UInt32 = 16000
        data.append(withUnsafeBytes(of: sampleRate.littleEndian) { Data($0) })
        
        // Byte rate (sampleRate * numChannels * bitsPerSample / 8)
        let byteRate: UInt32 = 16000 * 1 * 32 / 8
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
        data.replaceSubrange(fileSizeOffset..<(fileSizeOffset + 4), 
                           with: withUnsafeBytes(of: totalFileSize.littleEndian) { Data($0) })
        
        return data
    }
}

// MARK: - Mock Implementation for Testing

final class MockWhisperKitService: WhisperKitServiceProtocol {
    
    private var _isInitialized = false
    private let mockDelay: TimeInterval = 0.1
    
    var isInitialized: Bool {
        _isInitialized
    }
    
    func initialize() async throws {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        _isInitialized = true
    }
    
    
    func transcribeAudio(audio: Data) async throws -> String {
        guard _isInitialized else {
            throw WhisperKitServiceError.notInitialized
        }
        
        guard !audio.isEmpty else {
            throw WhisperKitServiceError.invalidAudioData
        }
        
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        // Return mock transcription based on audio size
        let words = ["Hello", "world", "this", "is", "a", "test", "transcription"]
        let wordCount = min(audio.count / 1000, words.count)
        return Array(words.prefix(wordCount)).joined(separator: " ")
    }
    
    func cancelTranscription() async {
        // Mock cancellation - no-op
    }
}