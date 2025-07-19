//
//  ThreadRepository.swift
//  ThreadJournal2
//
//  Repository protocol defining methods for thread and entry persistence
//

import Foundation

/// Protocol defining methods for thread and entry persistence operations
protocol ThreadRepository {
    /// Creates a new thread in the repository
    /// - Parameter thread: The thread to create
    /// - Throws: PersistenceError if the operation fails
    func create(thread: Thread) async throws
    
    /// Updates an existing thread in the repository
    /// - Parameter thread: The thread to update
    /// - Throws: PersistenceError if the operation fails
    func update(thread: Thread) async throws
    
    /// Deletes a thread and all its entries from the repository
    /// - Parameter threadId: The ID of the thread to delete
    /// - Throws: PersistenceError if the operation fails
    func delete(threadId: UUID) async throws
    
    /// Fetches a specific thread by ID
    /// - Parameter threadId: The ID of the thread to fetch
    /// - Returns: The thread if found, nil otherwise
    /// - Throws: PersistenceError if the operation fails
    func fetch(threadId: UUID) async throws -> Thread?
    
    /// Fetches all threads from the repository
    /// - Returns: Array of all threads, sorted by most recently updated
    /// - Throws: PersistenceError if the operation fails
    func fetchAll() async throws -> [Thread]
    
    /// Adds a new entry to an existing thread
    /// - Parameters:
    ///   - entry: The entry to add
    ///   - threadId: The ID of the thread to add the entry to
    /// - Throws: PersistenceError if the operation fails or thread not found
    func addEntry(_ entry: Entry, to threadId: UUID) async throws
    
    /// Fetches all entries for a specific thread
    /// - Parameter threadId: The ID of the thread
    /// - Returns: Array of entries sorted chronologically (oldest first)
    /// - Throws: PersistenceError if the operation fails
    func fetchEntries(for threadId: UUID) async throws -> [Entry]
}

/// Errors that can occur during persistence operations
enum PersistenceError: Error, LocalizedError {
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case notFound(id: UUID)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch: \(error.localizedDescription)"
        case .notFound(let id):
            return "Resource not found with ID: \(id)"
        case .updateFailed(let error):
            return "Failed to update: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete: \(error.localizedDescription)"
        }
    }
}