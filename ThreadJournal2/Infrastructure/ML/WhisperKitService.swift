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
    @Published var modelSizeBytes: Int64 = 0
    
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
                // Path B: Auto-download model using WhisperKit's built-in mechanism
                print("WhisperKitService: No bundled model found, downloading via WhisperKit...")
                isDownloading = true
                
                // Use WhisperKit's automatic download mechanism
                // This will download from HuggingFace and cache locally
                whisperKit = try await WhisperKit(
                    model: modelName,
                    computeOptions: .init(audioEncoderCompute: .cpuAndNeuralEngine,
                                         textDecoderCompute: .cpuAndNeuralEngine),
                    verbose: true,
                    logLevel: .debug,
                    prewarm: true
                )
                
                isDownloading = false
                print("WhisperKitService: Model downloaded and initialized")
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
            
            // Perform transcription with streaming support
            let transcriptionResult = try await whisperKit.transcribe(
                audioArray: audioArray,
                decodeOptions: DecodingOptions(
                    task: .transcribe,
                    language: nil, // Auto-detect language
                    temperatureFallbackCount: 3,
                    sampleLength: 224, // Optimal for 2-second chunks
                    usePrefillPrompt: false,
                    skipSpecialTokens: true,
                    withoutTimestamps: false // Enable for word-level timing
                )
            )
            
            // Extract and return the transcribed text
            // WhisperKit returns an array of TranscriptionResult
            if !transcriptionResult.isEmpty {
                // Get all segments and combine their text
                let text = transcriptionResult
                    .flatMap { $0.segments }
                    .map { $0.text }
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !text.isEmpty {
                    print("WhisperKitService: Transcribed: \(text)")
                    return text
                }
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
    
    private func convertAudioDataToFloatArray(_ audioData: Data) throws -> [Float] {
        // Convert PCM audio data to Float array expected by WhisperKit
        let int16Array = audioData.withUnsafeBytes { bytes in
            Array(bytes.bindMemory(to: Int16.self))
        }
        
        // Convert Int16 to Float and normalize to [-1.0, 1.0]
        return int16Array.map { Float($0) / Float(Int16.max) }
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