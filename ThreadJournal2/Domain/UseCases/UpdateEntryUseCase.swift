//
//  UpdateEntryUseCase.swift
//  ThreadJournal2
//
//  Use case for updating an existing journal entry's content
//

import Foundation

/// Use case for updating an existing journal entry
final class UpdateEntryUseCase {
    
    // MARK: - Properties
    
    private let repository: ThreadRepository
    
    // MARK: - Initialization
    
    /// Initializes the use case with required dependencies
    /// - Parameter repository: Repository for thread data access
    init(repository: ThreadRepository) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    
    /// Updates an existing entry's content
    /// - Parameters:
    ///   - entryId: The ID of the entry to update
    ///   - newContent: The new content for the entry
    /// - Returns: The updated entry
    /// - Throws: ValidationError if content is empty, PersistenceError if update fails
    func execute(entryId: UUID, newContent: String) async throws -> Entry {
        // Validate content not empty
        let trimmedContent = newContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw ValidationError.emptyContent
        }
        
        // Fetch the existing entry to get its current data
        guard let existingEntry = try await repository.fetchEntry(id: entryId) else {
            throw PersistenceError.notFound(id: entryId)
        }
        
        // Create updated entry with new content
        let updatedEntry = try Entry(
            id: existingEntry.id,
            threadId: existingEntry.threadId,
            content: trimmedContent,
            timestamp: existingEntry.timestamp
        )
        
        // Update via repository
        return try await repository.updateEntry(updatedEntry)
    }
}