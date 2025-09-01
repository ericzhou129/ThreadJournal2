//
//  VoiceEntryCoordinator.swift
//  ThreadJournal2
//
//  Coordinates audio capture and transcription services for voice entry functionality
//

import Foundation

/// Errors that can occur during voice entry coordination
enum VoiceEntryError: LocalizedError {
    case transcriptionServiceNotAvailable
    case audioServiceNotAvailable
    
    var errorDescription: String? {
        switch self {
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
    
    
    /// Current audio level for visualization
    @Published private(set) var audioLevel: Float = 0.0
    
    /// Recording duration
    @Published private(set) var recordingDuration: TimeInterval = 0.0
    
    /// Current recording state
    @Published private(set) var isRecording = false
    
    /// Error state
    @Published private(set) var error: Error?
    
    // MARK: - Private Properties
    
    private let audioService: AudioCaptureServiceProtocol
    private let transcriptionService: WhisperKitServiceProtocol
    
    
    /// Timer for updating audio level and duration
    private var updateTimer: Timer?
    
    
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
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Public Methods
    
    /// Starts voice recording and transcription
    func startRecording() async throws {
        guard !isRecording else { return }
        
        // Initialize transcription service if needed
        if !transcriptionService.isInitialized {
            try await transcriptionService.initialize()
        }
        
        // Clear previous state
        audioLevel = 0.0
        recordingDuration = 0.0
        error = nil
        safetyTimeoutReached = false
        
        // Start audio recording
        try await audioService.startRecording()
        isRecording = true
        
        // Start timer
        startUpdateTimer()
    }
    
    /// Stops recording and returns final transcription
    func stopRecording() async throws -> String {
        guard isRecording else { return "" }
        
        stopTimers()
        isRecording = false
        
        // Stop audio recording and get final audio data
        let finalAudioData = try await audioService.stopRecording()
        
        // Process final audio data for transcription
        if !finalAudioData.isEmpty {
            do {
                let finalTranscription = try await transcriptionService.transcribeAudio(audio: finalAudioData)
                return finalTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                // Log error and throw - transcription failed
                print("Failed to transcribe final audio: \(error)")
                throw error
            }
        }
        
        return ""
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
        
        // Clear state
        audioLevel = 0.0
        recordingDuration = 0.0
    }
    
    
    // MARK: - Private Methods
    
    
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateAudioLevel()
                self?.updateRecordingDuration()
            }
        }
    }
    
    private func stopTimers() {
        updateTimer?.invalidate()
        updateTimer = nil
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