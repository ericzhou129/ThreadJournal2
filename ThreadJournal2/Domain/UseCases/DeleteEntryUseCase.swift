//
//  DeleteEntryUseCase.swift
//  ThreadJournal2
//
//  Use case for soft deleting journal entries
//

import Foundation

/// Use case for soft deleting journal entries
final class DeleteEntryUseCase {
    
    // MARK: - Properties
    
    private let repository: ThreadRepository
    
    // MARK: - Initialization
    
    /// Initializes the use case with required dependencies
    /// - Parameter repository: Repository for thread data access
    init(repository: ThreadRepository) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    
    /// Soft deletes an entry by marking it with a deletion timestamp
    /// - Parameter entryId: The ID of the entry to delete
    /// - Throws: PersistenceError if the operation fails
    func execute(entryId: UUID) async throws {
        try await repository.softDeleteEntry(entryId: entryId)
    }
}