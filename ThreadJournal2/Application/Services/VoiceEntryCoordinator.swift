//
//  VoiceEntryCoordinator.swift
//  ThreadJournal2
//
//  Coordinates audio capture and transcription services for voice entry functionality
//

import Foundation

/// Errors that can occur during voice entry coordination
enum VoiceEntryError: LocalizedError {
    case modelDownloadDenied
    case transcriptionServiceNotAvailable
    case audioServiceNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .modelDownloadDenied:
            return "Voice transcription model download was denied"
        case .transcriptionServiceNotAvailable:
            return "Voice transcription service is not available"
        case .audioServiceNotAvailable:
            return "Audio recording service is not available"
        }
    }
}

/// Coordinates between audio capture and transcription services for voice entry
@MainActor
final class VoiceEntryCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current transcribed text accumulating from chunks
    @Published private(set) var accumulatedTranscription = ""
    
    /// Current partial transcription being processed
    @Published private(set) var currentPartialTranscription = ""
    
    /// Current audio level for visualization
    @Published private(set) var audioLevel: Float = 0.0
    
    /// Recording duration
    @Published private(set) var recordingDuration: TimeInterval = 0.0
    
    /// Current recording state
    @Published private(set) var isRecording = false
    
    /// Error state
    @Published private(set) var error: Error?
    
    /// Model download state
    @Published private(set) var isDownloadingModel = false
    @Published private(set) var downloadProgress: Float = 0.0
    @Published private(set) var downloadPermissionRequested = false
    
    // MARK: - Private Properties
    
    private let audioService: AudioCaptureServiceProtocol
    private let transcriptionService: WhisperKitServiceProtocol
    
    /// Timer for updating transcription chunks every 2 seconds
    private var transcriptionTimer: Timer?
    
    /// Timer for updating audio level and duration
    private var updateTimer: Timer?
    
    /// Buffer to collect recent audio data for transcription
    private var audioChunkBuffer: [Data] = []
    
    /// Tracks if the 5-minute safety timeout was reached
    private var safetyTimeoutReached = false
    
    // MARK: - Initialization
    
    init(
        audioService: AudioCaptureServiceProtocol,
        transcriptionService: WhisperKitServiceProtocol
    ) {
        self.audioService = audioService
        self.transcriptionService = transcriptionService
    }
    
    deinit {
        transcriptionTimer?.invalidate()
        transcriptionTimer = nil
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Public Methods
    
    /// Starts voice recording and transcription
    func startRecording() async throws {
        guard !isRecording else { return }
        
        // Initialize transcription service if needed
        if !transcriptionService.isInitialized {
            // Check if we need to handle download permission
            if let whisperService = transcriptionService as? WhisperKitService {
                // Start observing download state
                observeDownloadState(whisperService)
                
                do {
                    try await transcriptionService.initialize()
                } catch {
                    // Check if this is a permission error
                    if whisperService.downloadPermissionRequested {
                        downloadPermissionRequested = true
                        throw error
                    }
                    throw error
                }
            } else {
                try await transcriptionService.initialize()
            }
        }
        
        // Clear previous state
        accumulatedTranscription = ""
        currentPartialTranscription = ""
        audioLevel = 0.0
        recordingDuration = 0.0
        error = nil
        safetyTimeoutReached = false
        audioChunkBuffer.removeAll()
        
        // Start audio recording
        try await audioService.startRecording()
        isRecording = true
        
        // Start timers
        startTranscriptionTimer()
        startUpdateTimer()
    }
    
    /// Stops recording and returns final transcription
    func stopRecording() async throws -> String {
        guard isRecording else { return accumulatedTranscription }
        
        stopTimers()
        isRecording = false
        
        // Stop audio recording and get final audio data
        let finalAudioData = try await audioService.stopRecording()
        
        // Process any remaining audio data for final transcription
        if !finalAudioData.isEmpty {
            do {
                let finalTranscription = try await transcriptionService.transcribeAudio(audio: finalAudioData)
                if !finalTranscription.isEmpty {
                    // If we have existing transcription, add a space
                    if !accumulatedTranscription.isEmpty && !accumulatedTranscription.hasSuffix(" ") {
                        accumulatedTranscription += " "
                    }
                    accumulatedTranscription += finalTranscription
                }
            } catch {
                // Log error but don't throw - we still want to return what we have
                print("Failed to transcribe final audio chunk: \(error)")
            }
        }
        
        // Clear partial transcription
        currentPartialTranscription = ""
        
        return accumulatedTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Cancels recording without processing final transcription
    func cancelRecording() async {
        guard isRecording else { return }
        
        stopTimers()
        isRecording = false
        
        do {
            _ = try await audioService.stopRecording()
        } catch {
            print("Error stopping audio service during cancel: \(error)")
        }
        
        // Clear all transcription state
        accumulatedTranscription = ""
        currentPartialTranscription = ""
        audioLevel = 0.0
        recordingDuration = 0.0
    }
    
    /// Gets the combined transcription (accumulated + partial)
    var fullTranscription: String {
        let combined = accumulatedTranscription + currentPartialTranscription
        return combined.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Grants permission to download the transcription model
    func grantModelDownloadPermission() async {
        guard let whisperService = transcriptionService as? WhisperKitService else { return }
        
        whisperService.grantDownloadPermission()
        downloadPermissionRequested = false
        
        // Retry initialization
        do {
            try await transcriptionService.initialize()
        } catch {
            self.error = error
        }
    }
    
    /// Denies permission to download the transcription model
    func denyModelDownloadPermission() {
        guard let whisperService = transcriptionService as? WhisperKitService else { return }
        
        whisperService.denyDownloadPermission()
        downloadPermissionRequested = false
        error = VoiceEntryError.modelDownloadDenied
    }
    
    // MARK: - Private Methods
    
    /// Observes the download state of WhisperKit service
    private func observeDownloadState(_ whisperService: WhisperKitService) {
        // Note: In a real implementation, we would set up proper Combine publishers
        // For now, we'll use a simple polling mechanism
        Task { @MainActor in
            while !transcriptionService.isInitialized {
                isDownloadingModel = whisperService.isDownloading
                downloadProgress = whisperService.downloadProgress
                downloadPermissionRequested = whisperService.downloadPermissionRequested
                
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            isDownloadingModel = false
        }
    }
    
    private func startTranscriptionTimer() {
        transcriptionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.processTranscriptionChunk()
            }
        }
    }
    
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateAudioLevel()
                self?.updateRecordingDuration()
            }
        }
    }
    
    private func stopTimers() {
        transcriptionTimer?.invalidate()
        transcriptionTimer = nil
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func processTranscriptionChunk() async {
        guard isRecording else { return }
        
        // Get the latest audio chunk from AudioCaptureService
        guard let audioChunk = audioService.getLatestChunk(), !audioChunk.isEmpty else {
            // No new chunk available yet
            return
        }
        
        do {
            // Transcribe the actual audio chunk
            let chunkTranscription = try await transcriptionService.transcribeChunk(audio: audioChunk)
            
            if !chunkTranscription.isEmpty {
                // Move previous partial to accumulated
                if !currentPartialTranscription.isEmpty {
                    if !accumulatedTranscription.isEmpty && !accumulatedTranscription.hasSuffix(" ") {
                        accumulatedTranscription += " "
                    }
                    accumulatedTranscription += currentPartialTranscription
                }
                
                // Update partial with new chunk
                currentPartialTranscription = chunkTranscription
            }
        } catch {
            print("Chunk transcription error: \(error)")
            self.error = error
        }
    }
    
    private func updateAudioLevel() {
        guard isRecording else { return }
        audioLevel = audioService.getAudioLevel()
    }
    
    private func updateRecordingDuration() {
        guard isRecording else { return }
        recordingDuration = audioService.getRecordingDuration()
        
        // Check for safety timeout (5 minutes = 300 seconds)
        if recordingDuration >= 300.0 && !safetyTimeoutReached {
            safetyTimeoutReached = true
            Task {
                await cancelRecording()
            }
        }
    }
}