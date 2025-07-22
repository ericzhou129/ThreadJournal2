//
//  CreateThreadUseCase.swift
//  ThreadJournal2
//
//  Use case for creating new threads with optional first entry
//

import Foundation

/// Use case for creating a new thread with optional first entry
final class CreateThreadUseCase {
    private let repository: ThreadRepository
    
    init(repository: ThreadRepository) {
        self.repository = repository
    }
    
    /// Creates a new thread with the given title and optional first entry
    /// - Parameters:
    ///   - title: The title of the thread (must not be empty)
    ///   - firstEntry: Optional first entry content to add to the thread
    /// - Returns: The created thread
    /// - Throws: ValidationError if title is empty, or PersistenceError if save fails
    func execute(title: String, firstEntry: String? = nil) async throws -> Thread {
        // Create the thread with validation (Thread init validates title)
        let thread = try Thread(
            id: UUID(),
            title: title,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Save the thread to repository
        try await repository.create(thread: thread)
        
        // If firstEntry is provided and not empty, create and add it
        if let firstEntry = firstEntry,
           !firstEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let entry = try Entry(
                id: UUID(),
                threadId: thread.id,
                content: firstEntry,
                timestamp: Date()
            )
            try await repository.addEntry(entry, to: thread.id)
        }
        
        return thread
    }
}