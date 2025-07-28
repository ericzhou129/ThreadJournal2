//
//  MockThreadRepository.swift
//  ThreadJournal2Tests
//
//  Mock implementation of ThreadRepository for testing
//

import Foundation
@testable import ThreadJournal2

// Use type alias to disambiguate
typealias DomainThread = ThreadJournal2.Thread
typealias DomainEntry = ThreadJournal2.Entry

/// Mock thread repository for testing
final class MockThreadRepository: ThreadRepository {
    // MARK: - Mock State
    
    var mockThreads: [DomainThread] = []
    var mockEntries: [UUID: [DomainEntry]] = [:]
    
    // Internal state tracking
    var threads: [DomainThread] = []
    var entries: [UUID: [DomainEntry]] = [:]
    
    // For performance tests - direct access to entries by thread
    var entriesByThread: [UUID: [DomainEntry]] = [:]
    
    // MARK: - Error Injection
    
    var shouldFailCreate = false
    var shouldFailFetch = false
    var shouldFailUpdate = false
    var shouldFailDelete = false
    var shouldFailAddEntry = false
    
    var injectedError: Error = PersistenceError.saveFailed(underlying: NSError(domain: "MockError", code: 1))
    
    // MARK: - Call Tracking
    
    var createCallCount = 0
    var fetchAllCallCount = 0
    var fetchCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0
    var addEntryCallCount = 0
    var fetchEntriesCallCount = 0
    var fetchEntryCallCount = 0
    var updateEntryCallCount = 0
    var softDeleteEntryCallCount = 0
    var softDeleteCallCount = 0
    
    // MARK: - Test Helpers for New Methods
    
    var fetchEntryResult: DomainEntry?
    var updateEntryResult: DomainEntry?
    var softDeleteEntryError: Error?
    var lastSoftDeletedEntryId: UUID?
    var lastFetchedEntryId: UUID?
    var lastUpdatedEntry: DomainEntry?
    
    // MARK: - ThreadRepository Implementation
    
    func create(thread: DomainThread) async throws {
        createCallCount += 1
        
        if shouldFailCreate {
            throw injectedError
        }
        
        threads.append(thread)
        mockThreads.append(thread)
        entries[thread.id] = []
        mockEntries[thread.id] = []
    }
    
    func update(thread: DomainThread) async throws {
        updateCallCount += 1
        
        if shouldFailUpdate {
            throw injectedError
        }
        
        guard let index = threads.firstIndex(where: { $0.id == thread.id }) else {
            throw PersistenceError.notFound(id: thread.id)
        }
        
        threads[index] = thread
    }
    
    func delete(threadId: UUID) async throws {
        deleteCallCount += 1
        
        if shouldFailDelete {
            throw injectedError
        }
        
        threads.removeAll { $0.id == threadId }
        entries.removeValue(forKey: threadId)
    }
    
    func fetch(threadId: UUID) async throws -> DomainThread? {
        fetchCallCount += 1
        
        if shouldFailFetch {
            throw injectedError
        }
        
        // Check mock data first
        if let mockThread = mockThreads.first(where: { $0.id == threadId }) {
            return mockThread
        }
        
        return threads.first { $0.id == threadId }
    }
    
    func fetchAll() async throws -> [DomainThread] {
        fetchAllCallCount += 1
        
        if shouldFailFetch {
            throw injectedError
        }
        
        // Return threads sorted by updatedAt (most recent first), excluding deleted
        return threads
            .filter { $0.deletedAt == nil }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func fetchAll(includeDeleted: Bool) async throws -> [DomainThread] {
        fetchAllCallCount += 1
        
        if shouldFailFetch {
            throw injectedError
        }
        
        if includeDeleted {
            return threads.sorted { $0.updatedAt > $1.updatedAt }
        } else {
            return threads
                .filter { $0.deletedAt == nil }
                .sorted { $0.updatedAt > $1.updatedAt }
        }
    }
    
    func addEntry(_ entry: DomainEntry, to threadId: UUID) async throws {
        addEntryCallCount += 1
        
        if shouldFailAddEntry {
            throw injectedError
        }
        
        guard threads.contains(where: { $0.id == threadId }) else {
            throw PersistenceError.notFound(id: threadId)
        }
        
        if entries[threadId] == nil {
            entries[threadId] = []
        }
        entries[threadId]?.append(entry)
        
        // Also update entriesByThread for performance tests
        if entriesByThread[threadId] == nil {
            entriesByThread[threadId] = []
        }
        entriesByThread[threadId]?.append(entry)
        
        // Update thread's updatedAt timestamp
        if let index = threads.firstIndex(where: { $0.id == threadId }) {
            let updatedThread = try DomainThread(
                id: threadId,
                title: threads[index].title,
                createdAt: threads[index].createdAt,
                updatedAt: Date()
            )
            threads[index] = updatedThread
        }
    }
    
    func fetchEntries(for threadId: UUID) async throws -> [DomainEntry] {
        fetchEntriesCallCount += 1
        
        if shouldFailFetch {
            throw injectedError
        }
        
        // Check mock data first
        if let mockThreadEntries = mockEntries[threadId] {
            return mockThreadEntries.sorted { $0.timestamp < $1.timestamp }
        }
        
        // Check performance test data
        if let performanceEntries = entriesByThread[threadId] {
            return performanceEntries.sorted { $0.timestamp < $1.timestamp }
        }
        
        guard let threadEntries = entries[threadId] else {
            // If no entries found, return empty array instead of throwing
            return []
        }
        
        // Return entries sorted chronologically (oldest first)
        return threadEntries.sorted { $0.timestamp < $1.timestamp }
    }
    
    // MARK: - Test Helpers
    
    /// Resets all mock state
    func reset() {
        threads = []
        entries = [:]
        entriesByThread = [:]
        mockThreads = []
        mockEntries = [:]
        
        shouldFailCreate = false
        shouldFailFetch = false
        shouldFailUpdate = false
        shouldFailDelete = false
        shouldFailAddEntry = false
        
        createCallCount = 0
        fetchAllCallCount = 0
        fetchCallCount = 0
        updateCallCount = 0
        deleteCallCount = 0
        addEntryCallCount = 0
        fetchEntriesCallCount = 0
        fetchEntryCallCount = 0
        updateEntryCallCount = 0
        softDeleteEntryCallCount = 0
        softDeleteCallCount = 0
        
        fetchEntryResult = nil
        updateEntryResult = nil
        softDeleteEntryError = nil
        lastSoftDeletedEntryId = nil
        lastFetchedEntryId = nil
        lastUpdatedEntry = nil
    }
    
    // MARK: - New Repository Methods
    
    func fetchEntry(id: UUID) async throws -> DomainEntry? {
        fetchEntryCallCount += 1
        lastFetchedEntryId = id
        
        if shouldFailFetch {
            throw injectedError
        }
        
        return fetchEntryResult
    }
    
    func updateEntry(_ entry: DomainEntry) async throws -> DomainEntry {
        updateEntryCallCount += 1
        lastUpdatedEntry = entry
        
        if shouldFailUpdate {
            throw injectedError
        }
        
        guard let result = updateEntryResult else {
            // Default: return the same entry if no mock result specified
            return entry
        }
        
        return result
    }
    
    func softDeleteEntry(entryId: UUID) async throws {
        softDeleteEntryCallCount += 1
        lastSoftDeletedEntryId = entryId
        
        if let error = softDeleteEntryError {
            throw error
        }
        
        if shouldFailDelete {
            throw injectedError
        }
        
        // Update internal state - mark entry as soft deleted
        for (threadId, threadEntries) in entries {
            if threadEntries.contains(where: { $0.id == entryId }) {
                // Remove from entries collection to simulate soft delete
                entries[threadId] = threadEntries.filter { $0.id != entryId }
                break
            }
        }
    }
    
    func softDelete(threadId: UUID) async throws {
        softDeleteCallCount += 1
        
        if shouldFailDelete {
            throw injectedError
        }
        
        guard let index = threads.firstIndex(where: { $0.id == threadId }) else {
            throw PersistenceError.notFound(id: threadId)
        }
        
        let thread = threads[index]
        let softDeletedThread = try DomainThread(
            id: thread.id,
            title: thread.title,
            createdAt: thread.createdAt,
            updatedAt: Date(),
            deletedAt: Date()
        )
        threads[index] = softDeletedThread
        
        // Also clear entries for the soft deleted thread (simulating cascade delete)
        entries[threadId] = []
    }
}