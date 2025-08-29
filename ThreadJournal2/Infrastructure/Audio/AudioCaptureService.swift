import AVFoundation
import Foundation

protocol AudioCaptureServiceProtocol {
    func requestMicrophonePermission() async -> Bool
    func startRecording() async throws
    func stopRecording() async throws -> Data
    func getAudioLevel() -> Float
    func isRecording() -> Bool
    func getRecordingDuration() -> TimeInterval
    func getLatestChunk() -> Data?
}

enum AudioCaptureError: LocalizedError {
    case microphonePermissionDenied
    case audioSessionSetupFailed
    case recordingFailed
    case noAudioData
    case audioEngineNotRunning
    case interruptionOccurred
    
    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone permission denied"
        case .audioSessionSetupFailed:
            return "Failed to configure audio session"
        case .recordingFailed:
            return "Recording failed"
        case .noAudioData:
            return "No audio data captured"
        case .audioEngineNotRunning:
            return "Audio engine is not running"
        case .interruptionOccurred:
            return "Recording was interrupted"
        }
    }
}

final class AudioCaptureService: NSObject, AudioCaptureServiceProtocol {
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioBuffers: [AVAudioPCMBuffer] = []
    private var chunkBuffers: [Data] = []
    private var processedChunkCount = 0
    private var isRecordingActive = false
    private var currentAudioLevel: Float = 0.0
    private var recordingStartTime: Date?
    private var lastAudioActivityTime: Date?
    private var safetyTimer: Timer?
    
    private let bufferSize: AVAudioFrameCount = 1024
    private let sampleRate: Double = 44100.0
    private let chunkDuration: TimeInterval = 2.0
    private let safetyTimeoutDuration: TimeInterval = 300.0 // 5 minutes
    private let silenceThreshold: Float = -60.0 // dB
    
    private var chunkTimer: Timer?
    private var currentChunkBuffers: [AVAudioPCMBuffer] = []
    
    override init() {
        super.init()
        setupNotifications()
    }
    
    deinit {
        stopTimers()
        NotificationCenter.default.removeObserver(self)
    }
    
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func startRecording() async throws {
        // Prevent multiple simultaneous recording attempts
        guard !isRecordingActive else {
            print("WARNING: Recording already in progress, ignoring start request")
            return
        }
        
        guard await requestMicrophonePermission() else {
            throw AudioCaptureError.microphonePermissionDenied
        }
        
        try await setupAudioSession()
        try setupAudioEngine()
        
        audioBuffers.removeAll()
        chunkBuffers.removeAll()
        currentChunkBuffers.removeAll()
        processedChunkCount = 0
        audioEngine.prepare()
        
        try audioEngine.start()
        isRecordingActive = true
        recordingStartTime = Date()
        lastAudioActivityTime = Date()
        
        startChunkTimer()
        startSafetyTimer()
    }
    
    func stopRecording() async throws -> Data {
        guard isRecordingActive else {
            throw AudioCaptureError.audioEngineNotRunning
        }
        
        stopTimers()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecordingActive = false
        recordingStartTime = nil
        lastAudioActivityTime = nil
        
        try await deactivateAudioSession()
        
        return try combineAudioBuffers()
    }
    
    func getRecordingDuration() -> TimeInterval {
        guard let startTime = recordingStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    func getAudioLevel() -> Float {
        currentAudioLevel
    }
    
    func isRecording() -> Bool {
        isRecordingActive
    }
    
    func getLatestChunk() -> Data? {
        // Return the next unprocessed chunk if available
        guard processedChunkCount < chunkBuffers.count else {
            return nil
        }
        
        let chunk = chunkBuffers[processedChunkCount]
        processedChunkCount += 1
        return chunk
    }
    
    private func setupAudioSession() async throws {
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .spokenAudio,
                options: [.defaultToSpeaker, .allowBluetooth]
            )
            
            try audioSession.setPreferredSampleRate(sampleRate)
            try audioSession.setPreferredIOBufferDuration(0.005)
            try audioSession.setActive(true)
        } catch {
            throw AudioCaptureError.audioSessionSetupFailed
        }
    }
    
    private func deactivateAudioSession() async throws {
        try audioSession.setActive(false)
    }
    
    private func setupAudioEngine() throws {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )
        
        guard let format = recordingFormat else {
            throw AudioCaptureError.audioSessionSetupFailed
        }
        
        // Remove any existing tap before installing a new one
        inputNode.removeTap(onBus: 0)
        
        inputNode.installTap(
            onBus: 0,
            bufferSize: bufferSize,
            format: inputFormat
        ) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer, targetFormat: format)
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
        guard let convertedBuffer = convertBuffer(buffer, to: targetFormat) else {
            return
        }
        
        audioBuffers.append(convertedBuffer)
        currentChunkBuffers.append(convertedBuffer)
        
        let audioLevel = updateAudioLevel(from: convertedBuffer)
        
        // Update last activity time if audio is above silence threshold
        if audioLevel > silenceThreshold {
            lastAudioActivityTime = Date()
        }
    }
    
    private func convertBuffer(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: buffer.format, to: format) else {
            return nil
        }
        
        guard let convertedBuffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(
                Double(buffer.frameLength) * format.sampleRate / buffer.format.sampleRate
            )
        ) else {
            return nil
        }
        
        var error: NSError?
        converter.convert(
            to: convertedBuffer,
            error: &error
        ) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        return error == nil ? convertedBuffer : nil
    }
    
    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else {
            return -100.0
        }
        
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0.0
        
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        
        let rms = sqrt(sum / Float(frameLength))
        let decibels = 20 * log10(max(0.00001, rms))
        
        // Ensure audio level is valid and clamped between 0.0 and 1.0
        let normalizedLevel = (decibels + 80) / 80
        currentAudioLevel = max(0.0, min(1.0, normalizedLevel.isNaN ? 0.0 : normalizedLevel))
        return decibels
    }
    
    private func combineAudioBuffers() throws -> Data {
        guard !audioBuffers.isEmpty else {
            throw AudioCaptureError.noAudioData
        }
        
        let totalFrames = audioBuffers.reduce(0) { $0 + Int($1.frameLength) }
        guard let format = audioBuffers.first?.format,
              let combinedBuffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(totalFrames)
              ) else {
            throw AudioCaptureError.noAudioData
        }
        
        var writePosition: AVAudioFrameCount = 0
        
        for buffer in audioBuffers {
            guard let sourceData = buffer.floatChannelData?[0],
                  let destData = combinedBuffer.floatChannelData?[0] else {
                continue
            }
            
            let frameCount = Int(buffer.frameLength)
            memcpy(
                destData.advanced(by: Int(writePosition)),
                sourceData,
                frameCount * MemoryLayout<Float>.size
            )
            writePosition += buffer.frameLength
        }
        
        combinedBuffer.frameLength = writePosition
        
        return try convertToData(buffer: combinedBuffer)
    }
    
    private func convertToData(buffer: AVAudioPCMBuffer) throws -> Data {
        guard let fileURL = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first?.appendingPathComponent("temp_audio.wav") else {
            throw AudioCaptureError.noAudioData
        }
        
        let file = try AVAudioFile(
            forWriting: fileURL,
            settings: buffer.format.settings
        )
        
        try file.write(from: buffer)
        
        let data = try Data(contentsOf: fileURL)
        try? FileManager.default.removeItem(at: fileURL)
        
        return data
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info["AVAudioSessionInterruptionTypeKey"] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            if isRecordingActive {
                audioEngine.pause()
            }
        case .ended:
            if let optionsValue = info["AVAudioSessionInterruptionOptionKey"] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) && isRecordingActive {
                    Task {
                        try? audioEngine.start()
                    }
                }
            }
        @unknown default:
            break
        }
    }
    
    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info["AVAudioSessionRouteChangeReasonKey"] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .newDeviceAvailable, .oldDeviceUnavailable:
            if isRecordingActive {
                Task {
                    try? await setupAudioSession()
                }
            }
        default:
            break
        }
    }
    
    // MARK: - Timer Management
    
    private func startChunkTimer() {
        chunkTimer = Timer.scheduledTimer(withTimeInterval: chunkDuration, repeats: true) { [weak self] _ in
            self?.processChunk()
        }
    }
    
    private func startSafetyTimer() {
        safetyTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkSafetyTimeout()
        }
    }
    
    private func stopTimers() {
        chunkTimer?.invalidate()
        chunkTimer = nil
        safetyTimer?.invalidate()
        safetyTimer = nil
    }
    
    private func processChunk() {
        guard !currentChunkBuffers.isEmpty else { return }
        
        // Convert current chunk buffers to data for transcription
        if let chunkData = try? combineBuffersToData(currentChunkBuffers) {
            chunkBuffers.append(chunkData)
        }
        
        currentChunkBuffers.removeAll()
    }
    
    private func checkSafetyTimeout() {
        guard let lastActivity = lastAudioActivityTime else { return }
        
        let timeSinceActivity = Date().timeIntervalSince(lastActivity)
        if timeSinceActivity >= safetyTimeoutDuration {
            // Safety timeout reached - stop recording
            Task {
                try? await stopRecording()
            }
        }
    }
    
    private func combineBuffersToData(_ buffers: [AVAudioPCMBuffer]) throws -> Data {
        guard !buffers.isEmpty else {
            throw AudioCaptureError.noAudioData
        }
        
        let totalFrames = buffers.reduce(0) { $0 + Int($1.frameLength) }
        guard let format = buffers.first?.format,
              let combinedBuffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(totalFrames)
              ) else {
            throw AudioCaptureError.noAudioData
        }
        
        var writePosition: AVAudioFrameCount = 0
        
        for buffer in buffers {
            guard let sourceData = buffer.floatChannelData?[0],
                  let destData = combinedBuffer.floatChannelData?[0] else {
                continue
            }
            
            let frameCount = Int(buffer.frameLength)
            memcpy(
                destData.advanced(by: Int(writePosition)),
                sourceData,
                frameCount * MemoryLayout<Float>.size
            )
            writePosition += buffer.frameLength
        }
        
        combinedBuffer.frameLength = writePosition
        
        return try convertToData(buffer: combinedBuffer)
    }
}