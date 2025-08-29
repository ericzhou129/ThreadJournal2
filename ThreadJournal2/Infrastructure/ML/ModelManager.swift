import Foundation
import Combine

protocol ModelManagerProtocol {
    func downloadModel(name: String) async throws -> Progress
    func deleteModel(name: String) async throws
    func getAvailableModels() async throws -> [WhisperModel]
    func getInstalledModels() async throws -> [WhisperModel]
    func getModelSize(name: String) -> Int64
    func isModelDownloaded(name: String) -> Bool
    func getModelPath(name: String) -> URL?
}

struct WhisperModel {
    let name: String
    let displayName: String
    let size: Int64
    let language: String
    let isMultilingual: Bool
    let downloadURL: String
    let version: String
    
    static let whisperSmall = WhisperModel(
        name: "openai_whisper-small",
        displayName: "Whisper Small",
        size: 39_000_000,
        language: "Multilingual",
        isMultilingual: true,
        downloadURL: "https://huggingface.co/argmaxinc/whisperkit-coreml/resolve/main/openai_whisper-small",
        version: "1.0"
    )
    
    static let whisperBase = WhisperModel(
        name: "openai_whisper-base",
        displayName: "Whisper Base",
        size: 15_000_000,
        language: "Multilingual",
        isMultilingual: true,
        downloadURL: "https://huggingface.co/argmaxinc/whisperkit-coreml/resolve/main/openai_whisper-base",
        version: "1.0"
    )
    
    static let availableModels = [whisperSmall, whisperBase]
}

enum ModelManagerError: LocalizedError {
    case modelNotFound
    case downloadFailed
    case insufficientStorage
    case invalidModelFormat
    case deletionFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Model not found"
        case .downloadFailed:
            return "Failed to download model"
        case .insufficientStorage:
            return "Insufficient storage space"
        case .invalidModelFormat:
            return "Invalid model format"
        case .deletionFailed:
            return "Failed to delete model"
        }
    }
}

final class ModelManager: NSObject, ModelManagerProtocol {
    private let fileManager = FileManager.default
    private var downloadTask: URLSessionDownloadTask?
    private var progressObservation: NSKeyValueObservation?
    private var currentProgress: Progress?
    
    private var modelsDirectory: URL {
        let documentsPath = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        let modelsPath = documentsPath.appendingPathComponent("WhisperModels")
        
        if !fileManager.fileExists(atPath: modelsPath.path) {
            try? fileManager.createDirectory(
                at: modelsPath,
                withIntermediateDirectories: true
            )
        }
        
        return modelsPath
    }
    
    func downloadModel(name: String) async throws -> Progress {
        guard let model = WhisperModel.availableModels.first(where: { $0.name == name }) else {
            throw ModelManagerError.modelNotFound
        }
        
        guard hasEnoughStorage(for: model.size) else {
            throw ModelManagerError.insufficientStorage
        }
        
        let progress = Progress(totalUnitCount: 100)
        currentProgress = progress
        
        let modelPath = modelsDirectory.appendingPathComponent(model.name)
        
        if fileManager.fileExists(atPath: modelPath.path) {
            progress.completedUnitCount = 100
            return progress
        }
        
        return try await downloadModelFiles(model: model, progress: progress)
    }
    
    func deleteModel(name: String) async throws {
        let modelPath = modelsDirectory.appendingPathComponent(name)
        
        guard fileManager.fileExists(atPath: modelPath.path) else {
            throw ModelManagerError.modelNotFound
        }
        
        do {
            try fileManager.removeItem(at: modelPath)
        } catch {
            throw ModelManagerError.deletionFailed
        }
    }
    
    func getAvailableModels() async throws -> [WhisperModel] {
        WhisperModel.availableModels
    }
    
    func getInstalledModels() async throws -> [WhisperModel] {
        let installedModelNames = try fileManager.contentsOfDirectory(
            at: modelsDirectory,
            includingPropertiesForKeys: nil
        ).map { $0.lastPathComponent }
        
        return WhisperModel.availableModels.filter { model in
            installedModelNames.contains(model.name)
        }
    }
    
    func getModelSize(name: String) -> Int64 {
        WhisperModel.availableModels
            .first(where: { $0.name == name })?
            .size ?? 0
    }
    
    func isModelDownloaded(name: String) -> Bool {
        let modelPath = modelsDirectory.appendingPathComponent(name)
        
        guard fileManager.fileExists(atPath: modelPath.path) else {
            return false
        }
        
        return verifyModelIntegrity(at: modelPath)
    }
    
    func getModelPath(name: String) -> URL? {
        let modelPath = modelsDirectory.appendingPathComponent(name)
        
        guard fileManager.fileExists(atPath: modelPath.path) else {
            return nil
        }
        
        return modelPath
    }
    
    private func downloadModelFiles(model: WhisperModel, progress: Progress) async throws -> Progress {
        let modelPath = modelsDirectory.appendingPathComponent(model.name)
        try fileManager.createDirectory(at: modelPath, withIntermediateDirectories: true)
        
        let modelFiles = [
            "AudioEncoder.mlmodelc",
            "TextDecoder.mlmodelc",
            "MelSpectrogram.mlmodelc",
            "config.json",
            "tokenizer.json"
        ]
        
        let fileProgress = Progress(totalUnitCount: Int64(modelFiles.count))
        progress.addChild(fileProgress, withPendingUnitCount: 100)
        
        for (index, fileName) in modelFiles.enumerated() {
            let fileURL = URL(string: "\(model.downloadURL)/\(fileName)")!
            let destinationPath = modelPath.appendingPathComponent(fileName)
            
            try await downloadFile(from: fileURL, to: destinationPath)
            
            fileProgress.completedUnitCount = Int64(index + 1)
        }
        
        guard verifyModelIntegrity(at: modelPath) else {
            try? fileManager.removeItem(at: modelPath)
            throw ModelManagerError.invalidModelFormat
        }
        
        return progress
    }
    
    private func downloadFile(from url: URL, to destination: URL) async throws {
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        
        try fileManager.moveItem(at: tempURL, to: destination)
    }
    
    private func hasEnoughStorage(for size: Int64) -> Bool {
        guard let attributes = try? fileManager.attributesOfFileSystem(
            forPath: modelsDirectory.path
        ),
        let freeSpace = attributes[.systemFreeSize] as? Int64 else {
            return false
        }
        
        let requiredSpace = size * 2
        return freeSpace > requiredSpace
    }
    
    private func verifyModelIntegrity(at path: URL) -> Bool {
        let requiredFiles = [
            "AudioEncoder.mlmodelc",
            "TextDecoder.mlmodelc",
            "config.json"
        ]
        
        for fileName in requiredFiles {
            let filePath = path.appendingPathComponent(fileName)
            if !fileManager.fileExists(atPath: filePath.path) {
                return false
            }
        }
        
        return true
    }
}

extension ModelManager: URLSessionDownloadDelegate {
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        currentProgress?.completedUnitCount = Int64(progress * 100)
    }
}