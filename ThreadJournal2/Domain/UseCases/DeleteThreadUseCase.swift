//
//  DeleteThreadUseCase.swift
//  ThreadJournal2
//
//  Use case for soft deleting threads and their entries
//

import Foundation

/// Protocol defining the contract for thread deletion operations
protocol DeleteThreadUseCase {
    /// Soft deletes a thread and all its associated entries
    /// - Parameter threadId: The ID of the thread to delete
    /// - Throws: ThreadNotFoundError if thread doesn't exist, or PersistenceError if operation fails
    func execute(threadId: UUID) async throws
}

/// Use case for soft deleting threads with cascade deletion of entries
final class DeleteThreadUseCaseImpl: DeleteThreadUseCase {
    
    // MARK: - Properties
    
    private let repository: ThreadRepository
    
    // MARK: - Initialization
    
    /// Initializes the use case with required dependencies
    /// - Parameter repository: Repository for thread data access
    init(repository: ThreadRepository) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    
    /// Soft deletes a thread by setting deletedAt timestamp and cascading to all entries
    /// - Parameter threadId: The ID of the thread to delete
    /// - Throws: ThreadNotFoundError if thread doesn't exist, or PersistenceError if operation fails
    func execute(threadId: UUID) async throws {
        // Verify thread exists before attempting deletion
        guard try await repository.fetch(threadId: threadId) != nil else {
            throw ThreadNotFoundError(threadId: threadId)
        }
        
        // Perform soft delete
        try await repository.softDelete(threadId: threadId)
    }
}

/// Error thrown when attempting to delete a thread that doesn't exist
struct ThreadNotFoundError: Error, LocalizedError {
    let threadId: UUID
    
    var errorDescription: String? {
        "Thread with ID \(threadId) not found"
    }
}