//
//  AddEntryUseCase.swift
//  ThreadJournal2
//
//  Use case for adding entries to existing threads
//

import Foundation

/// Use case responsible for adding entries to existing threads
final class AddEntryUseCase {
    private let repository: ThreadRepository
    
    /// Initializes the use case with a thread repository
    /// - Parameter repository: The repository to use for persistence
    init(repository: ThreadRepository) {
        self.repository = repository
    }
    
    /// Adds a new entry to an existing thread
    /// - Parameters:
    ///   - content: The content of the entry
    ///   - threadId: The ID of the thread to add the entry to
    /// - Returns: The created entry
    /// - Throws: ValidationError if content is empty, PersistenceError if operation fails
    func execute(content: String, threadId: UUID) async throws -> Entry {
        // Validate content is not empty
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyContent
        }
        
        // Check if thread exists
        guard let thread = try await repository.fetch(threadId: threadId) else {
            throw PersistenceError.notFound(id: threadId)
        }
        
        // Create entry (Entry init will validate content)
        let entry = try Entry(
            id: UUID(),
            threadId: threadId,
            content: content,
            timestamp: Date()
        )
        
        // Add entry to repository
        try await repository.addEntry(entry, to: threadId)
        
        // Update thread's updatedAt timestamp
        let updatedThread = try Thread(
            id: thread.id,
            title: thread.title,
            createdAt: thread.createdAt,
            updatedAt: Date()
        )
        try await repository.update(thread: updatedThread)
        
        return entry
    }
}