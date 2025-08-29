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
    func transcribeChunk(audio: Data) async throws -> String
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
    
    // Download progress tracking
    @Published var downloadProgress: Float = 0.0
    @Published var isDownloading = false
    @Published var modelSizeBytes: Int64 = 216_000_000 // ~216MB for openai_whisper-small
    @Published var downloadPermissionRequested = false
    @Published var downloadPermissionGranted = false
    
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
                // Path B: Check if model needs to be downloaded
                let needsDownload = !isModelCached()
                
                if needsDownload {
                    // Request permission before downloading
                    if !downloadPermissionGranted {
                        downloadPermissionRequested = true
                        throw WhisperKitServiceError.initializationFailed("Model download permission required")
                    }
                    
                    print("WhisperKitService: No bundled model found, downloading via WhisperKit...")
                    isDownloading = true
                    downloadProgress = 0.0
                } else {
                    print("WhisperKitService: Using cached model")
                }
                
                // Use WhisperKit's automatic download mechanism
                // This will download from HuggingFace and cache locally if needed
                whisperKit = try await WhisperKit(
                    model: modelName,
                    computeOptions: .init(audioEncoderCompute: .cpuAndNeuralEngine,
                                         textDecoderCompute: .cpuAndNeuralEngine),
                    verbose: true,
                    logLevel: .debug,
                    prewarm: true
                )
                
                if needsDownload {
                    isDownloading = false
                    downloadProgress = 1.0
                    print("WhisperKitService: Model downloaded and initialized")
                }
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
    
    /// Grants permission to download the model
    func grantDownloadPermission() {
        downloadPermissionGranted = true
        downloadPermissionRequested = false
    }
    
    /// Denies permission to download the model
    func denyDownloadPermission() {
        downloadPermissionGranted = false
        downloadPermissionRequested = false
    }
    
    // MARK: - Transcription Methods
    
    func transcribeChunk(audio: Data) async throws -> String {
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
            
            // Perform transcription with streaming support
            let transcriptionResult = try await whisperKit.transcribe(
                audioArray: audioArray,
                decodeOptions: DecodingOptions(
                    task: .transcribe,
                    language: "en", // Force English to prevent language detection issues
                    temperatureFallbackCount: 3,
                    sampleLength: 224, // Optimal for 2-second chunks
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
    
    func transcribeAudio(audio: Data) async throws -> String {
        // For full audio transcription, use the same method as chunk transcription
        // WhisperKit handles longer audio automatically
        return try await transcribeChunk(audio: audio)
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
    
    /// Checks if the model is already cached locally
    private func isModelCached() -> Bool {
        // WhisperKit caches models in the Application Support directory
        let fileManager = FileManager.default
        guard let appSupportDir = fileManager.urls(for: .applicationSupportDirectory,
                                                  in: .userDomainMask).first else {
            return false
        }
        
        let modelDir = appSupportDir.appendingPathComponent("com.argmax.whisperkit")
                                   .appendingPathComponent(modelName)
        
        return fileManager.fileExists(atPath: modelDir.path)
    }
    
    private func convertAudioDataToFloatArray(_ audioData: Data) throws -> [Float] {
        print("WhisperKitService: Converting audio data of size \(audioData.count) bytes")
        
        // AudioCaptureService outputs Float32 PCM data in WAV format
        // We need to extract the raw PCM Float32 samples from the WAV file
        
        // First, try to parse as WAV file and extract Float32 PCM data
        if let floatArray = extractFloat32FromWAVData(audioData) {
            print("WhisperKitService: Extracted \(floatArray.count) Float32 samples from WAV")
            return floatArray
        }
        
        // Fallback: Try to interpret as raw Float32 data
        let floatArray = audioData.withUnsafeBytes { bytes in
            Array(bytes.bindMemory(to: Float.self))
        }
        
        print("WhisperKitService: Interpreted as raw Float32 data: \(floatArray.count) samples")
        
        // Validate the audio data
        let maxValue = floatArray.max() ?? 0.0
        let minValue = floatArray.min() ?? 0.0
        let rms = sqrt(floatArray.map { $0 * $0 }.reduce(0, +) / Float(floatArray.count))
        
        print("WhisperKitService: Audio validation - min: \(minValue), max: \(maxValue), RMS: \(rms)")
        
        // Check if audio is silent (very low RMS indicates silence)
        if rms < 0.001 {
            print("WhisperKitService: WARNING - Audio appears to be silent (RMS: \(rms))")
        }
        
        return floatArray
    }
    
    /// Extracts Float32 PCM data from a WAV file
    private func extractFloat32FromWAVData(_ wavData: Data) -> [Float]? {
        // WAV file format parsing
        guard wavData.count > 44 else { return nil } // WAV header is at least 44 bytes
        
        // Check for WAV file signature "RIFF"
        let riffSignature = wavData.subdata(in: 0..<4)
        guard riffSignature == "RIFF".data(using: .ascii) else { return nil }
        
        // Check for WAV format "WAVE"
        let waveSignature = wavData.subdata(in: 8..<12)
        guard waveSignature == "WAVE".data(using: .ascii) else { return nil }
        
        // Find the "data" chunk
        var offset = 12
        while offset < wavData.count - 8 {
            let chunkId = wavData.subdata(in: offset..<offset+4)
            let chunkSize = wavData.subdata(in: offset+4..<offset+8).withUnsafeBytes {
                $0.load(as: UInt32.self)
            }
            
            if chunkId == "data".data(using: .ascii) {
                // Found data chunk, extract Float32 samples
                let dataStart = offset + 8
                let dataEnd = min(dataStart + Int(chunkSize), wavData.count)
                let pcmData = wavData.subdata(in: dataStart..<dataEnd)
                
                return pcmData.withUnsafeBytes { bytes in
                    Array(bytes.bindMemory(to: Float.self))
                }
            }
            
            offset += 8 + Int(chunkSize)
        }
        
        return nil
    }
    
    deinit {
        currentTask?.cancel()
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
    
    func transcribeChunk(audio: Data) async throws -> String {
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
    
    func transcribeAudio(audio: Data) async throws -> String {
        return try await transcribeChunk(audio: audio)
    }
    
    func cancelTranscription() async {
        // Mock cancellation - no-op
    }
}