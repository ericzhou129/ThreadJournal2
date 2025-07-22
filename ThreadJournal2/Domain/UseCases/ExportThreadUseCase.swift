//
//  ExportThreadUseCase.swift
//  ThreadJournal2
//
//  Use case for exporting thread data
//

import Foundation

/// Protocol defining exported data format
protocol ExportData {
    var fileName: String { get }
    var mimeType: String { get }
    var data: Data { get }
}

/// Use case for exporting a thread to various formats
final class ExportThreadUseCase {
    private let repository: ThreadRepository
    private let exporter: Exporter
    
    init(repository: ThreadRepository, exporter: Exporter) {
        self.repository = repository
        self.exporter = exporter
    }
    
    /// Exports a thread with all its entries
    /// - Parameters:
    ///   - threadId: The ID of the thread to export
    /// - Returns: ExportData containing the exported content
    func execute(threadId: UUID) async throws -> ExportData {
        // Fetch thread
        guard let thread = try await repository.fetch(threadId: threadId) else {
            throw ExportError.threadNotFound
        }
        
        // Fetch all entries for the thread
        let entries = try await repository.fetchEntries(for: threadId)
        
        // Use injected exporter to generate export data
        return exporter.export(thread: thread, entries: entries)
    }
}

/// Export-specific errors
enum ExportError: LocalizedError {
    case threadNotFound
    case exportFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .threadNotFound:
            return "Thread not found"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        }
    }
}