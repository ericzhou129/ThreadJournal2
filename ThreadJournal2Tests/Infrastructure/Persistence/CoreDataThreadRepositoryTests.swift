//
//  CoreDataThreadRepositoryTests.swift
//  ThreadJournal2Tests
//
//  Tests for CoreDataThreadRepository with mocked Core Data
//

import XCTest
import CoreData
@testable import ThreadJournal2

class CoreDataThreadRepositoryTests: XCTestCase {
    var repository: CoreDataThreadRepository!
    var persistentContainer: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory Core Data stack for testing
        persistentContainer = createInMemoryPersistentContainer()
        repository = CoreDataThreadRepository(persistentContainer: persistentContainer)
    }
    
    override func tearDown() {
        repository = nil
        persistentContainer = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createInMemoryPersistentContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "ThreadDataModel")
        
        // Use in-memory store for testing
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { (description, error) in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
        
        return container
    }
    
    // MARK: - Thread Tests
    
    func testCreateThread() async throws {
        // Arrange
        let thread = try Thread(title: "Test Thread")
        
        // Act
        try await repository.create(thread: thread)
        
        // Assert
        let fetchedThread = try await repository.fetch(threadId: thread.id)
        XCTAssertNotNil(fetchedThread)
        XCTAssertEqual(fetchedThread?.id, thread.id)
        XCTAssertEqual(fetchedThread?.title, thread.title)
    }
    
    func testCreateDuplicateThreadFails() async throws {
        // Arrange
        let thread = try Thread(title: "Test Thread")
        try await repository.create(thread: thread)
        
        // Act & Assert
        do {
            try await repository.create(thread: thread)
            XCTFail("Expected error when creating duplicate thread")
        } catch is PersistenceError {
            // Expected error
        }
    }
    
    func testUpdateThread() async throws {
        // Arrange
        let thread = try Thread(title: "Original Title")
        try await repository.create(thread: thread)
        
        let updatedThread = try Thread(
            id: thread.id,
            title: "Updated Title",
            createdAt: thread.createdAt,
            updatedAt: Date()
        )
        
        // Act
        try await repository.update(thread: updatedThread)
        
        // Assert
        let fetchedThread = try await repository.fetch(threadId: thread.id)
        XCTAssertEqual(fetchedThread?.title, "Updated Title")
    }
    
    func testUpdateNonExistentThreadFails() async throws {
        // Arrange
        let thread = try Thread(title: "Test Thread")
        
        // Act & Assert
        do {
            try await repository.update(thread: thread)
            XCTFail("Expected error when updating non-existent thread")
        } catch PersistenceError.notFound {
            // Expected error
        }
    }
    
    func testDeleteThread() async throws {
        // Arrange
        let thread = try Thread(title: "Test Thread")
        try await repository.create(thread: thread)
        
        // Act
        try await repository.delete(threadId: thread.id)
        
        // Assert
        let fetchedThread = try await repository.fetch(threadId: thread.id)
        XCTAssertNil(fetchedThread)
    }
    
    func testDeleteNonExistentThreadFails() async throws {
        // Act & Assert
        do {
            try await repository.delete(threadId: UUID())
            XCTFail("Expected error when deleting non-existent thread")
        } catch PersistenceError.notFound {
            // Expected error
        }
    }
    
    func testFetchAllThreads() async throws {
        // Arrange
        let thread1 = try Thread(title: "Thread 1")
        let thread2 = try Thread(title: "Thread 2")
        let thread3 = try Thread(title: "Thread 3")
        
        try await repository.create(thread: thread1)
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        try await repository.create(thread: thread2)
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        try await repository.create(thread: thread3)
        
        // Act
        let threads = try await repository.fetchAll()
        
        // Assert
        XCTAssertEqual(threads.count, 3)
        // Should be sorted by most recently updated (created in this case)
        XCTAssertEqual(threads[0].id, thread3.id)
        XCTAssertEqual(threads[1].id, thread2.id)
        XCTAssertEqual(threads[2].id, thread1.id)
    }
    
    // MARK: - Entry Tests
    
    func testAddEntry() async throws {
        // Arrange
        let thread = try Thread(title: "Test Thread")
        try await repository.create(thread: thread)
        
        let entry = try Entry(threadId: thread.id, content: "Test entry content")
        
        // Act
        try await repository.addEntry(entry, to: thread.id)
        
        // Assert
        let entries = try await repository.fetchEntries(for: thread.id)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].id, entry.id)
        XCTAssertEqual(entries[0].content, entry.content)
    }
    
    func testAddEntryToNonExistentThreadFails() async throws {
        // Arrange
        let nonExistentThreadId = UUID()
        let entry = try Entry(threadId: nonExistentThreadId, content: "Test content")
        
        // Act & Assert
        do {
            try await repository.addEntry(entry, to: nonExistentThreadId)
            XCTFail("Expected error when adding entry to non-existent thread")
        } catch PersistenceError.notFound {
            // Expected error
        }
    }
    
    func testFetchEntriesChronologicalOrder() async throws {
        // Arrange
        let thread = try Thread(title: "Test Thread")
        try await repository.create(thread: thread)
        
        let entry1 = try Entry(threadId: thread.id, content: "First entry")
        let entry2 = try Entry(threadId: thread.id, content: "Second entry")
        let entry3 = try Entry(threadId: thread.id, content: "Third entry")
        
        // Add entries with slight delays to ensure different timestamps
        try await repository.addEntry(entry1, to: thread.id)
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        try await repository.addEntry(entry2, to: thread.id)
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        try await repository.addEntry(entry3, to: thread.id)
        
        // Act
        let entries = try await repository.fetchEntries(for: thread.id)
        
        // Assert
        XCTAssertEqual(entries.count, 3)
        // Should be sorted chronologically (oldest first)
        XCTAssertEqual(entries[0].id, entry1.id)
        XCTAssertEqual(entries[1].id, entry2.id)
        XCTAssertEqual(entries[2].id, entry3.id)
    }
    
    func testAddingEntryUpdatesThreadTimestamp() async throws {
        // Arrange
        let thread = try Thread(title: "Test Thread")
        try await repository.create(thread: thread)
        
        let originalUpdatedAt = thread.updatedAt
        
        // Wait a bit to ensure timestamp difference
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let entry = try Entry(threadId: thread.id, content: "New entry")
        
        // Act
        try await repository.addEntry(entry, to: thread.id)
        
        // Assert
        let updatedThread = try await repository.fetch(threadId: thread.id)
        XCTAssertNotNil(updatedThread)
        XCTAssertGreaterThan(updatedThread!.updatedAt, originalUpdatedAt)
    }
    
    // MARK: - Validation Error Tests
    
    func testCreateThreadWithEmptyTitleFails() async throws {
        // Act & Assert
        do {
            let thread = try Thread(title: "   ")
            try await repository.create(thread: thread)
            XCTFail("Expected ValidationError for empty title")
        } catch ValidationError.emptyTitle {
            // Expected error
        }
    }
    
    func testAddEntryWithEmptyContentFails() async throws {
        // Arrange
        let thread = try Thread(title: "Test Thread")
        try await repository.create(thread: thread)
        
        // Act & Assert
        do {
            let entry = try Entry(threadId: thread.id, content: "   ")
            try await repository.addEntry(entry, to: thread.id)
            XCTFail("Expected ValidationError for empty content")
        } catch ValidationError.emptyContent {
            // Expected error
        }
    }
    
    // MARK: - Cascade Delete Test
    
    func testDeleteThreadCascadesEntries() async throws {
        // Arrange
        let thread = try Thread(title: "Test Thread")
        try await repository.create(thread: thread)
        
        let entry1 = try Entry(threadId: thread.id, content: "Entry 1")
        let entry2 = try Entry(threadId: thread.id, content: "Entry 2")
        
        try await repository.addEntry(entry1, to: thread.id)
        try await repository.addEntry(entry2, to: thread.id)
        
        // Act
        try await repository.delete(threadId: thread.id)
        
        // Assert
        let entries = try await repository.fetchEntries(for: thread.id)
        XCTAssertEqual(entries.count, 0)
    }
    
    // MARK: - Soft Delete Tests
    
    func testSoftDeleteThread() async throws {
        // Arrange
        let thread = try Thread(title: "Thread to Soft Delete")
        try await repository.create(thread: thread)
        
        // Act
        try await repository.softDelete(threadId: thread.id)
        
        // Assert - Thread should not be visible in regular fetch
        let threads = try await repository.fetchAll()
        XCTAssertFalse(threads.contains { $0.id == thread.id })
        
        // But should still exist in database with deletedAt set
        let deletedThread = try await repository.fetch(threadId: thread.id)
        XCTAssertNotNil(deletedThread)
        XCTAssertNotNil(deletedThread?.deletedAt)
        XCTAssertTrue(deletedThread?.isDeleted ?? false)
    }
    
    func testSoftDeleteNonExistentThreadThrows() async throws {
        // Arrange
        let nonExistentId = UUID()
        
        // Act & Assert
        do {
            try await repository.softDelete(threadId: nonExistentId)
            XCTFail("Expected error when soft deleting non-existent thread")
        } catch let error as PersistenceError {
            if case .notFound(let id) = error {
                XCTAssertEqual(id, nonExistentId)
            } else {
                XCTFail("Expected notFound error, got \(error)")
            }
        }
    }
    
    func testSoftDeleteThreadCascadesToEntries() async throws {
        // Arrange
        let thread = try Thread(title: "Thread with Entries")
        try await repository.create(thread: thread)
        
        let entry1 = try Entry(threadId: thread.id, content: "Entry 1")
        let entry2 = try Entry(threadId: thread.id, content: "Entry 2")
        try await repository.addEntry(entry1, to: thread.id)
        try await repository.addEntry(entry2, to: thread.id)
        
        // Act
        try await repository.softDelete(threadId: thread.id)
        
        // Assert - Entries should not be visible in regular fetch
        let entries = try await repository.fetchEntries(for: thread.id)
        XCTAssertEqual(entries.count, 0)
        
        // But entries should still exist with deletedAt set
        // Note: We can't directly test this without exposing internal Core Data details
        // The implementation should handle cascade soft delete
    }
    
    func testFetchAllExcludesDeletedThreadsByDefault() async throws {
        // Arrange
        let thread1 = try Thread(title: "Active Thread 1")
        let thread2 = try Thread(title: "Thread to Delete")
        let thread3 = try Thread(title: "Active Thread 2")
        
        try await repository.create(thread: thread1)
        try await repository.create(thread: thread2)
        try await repository.create(thread: thread3)
        
        // Soft delete thread2
        try await repository.softDelete(threadId: thread2.id)
        
        // Act
        let threads = try await repository.fetchAll()
        
        // Assert
        XCTAssertEqual(threads.count, 2)
        XCTAssertTrue(threads.contains { $0.id == thread1.id })
        XCTAssertTrue(threads.contains { $0.id == thread3.id })
        XCTAssertFalse(threads.contains { $0.id == thread2.id })
    }
    
    func testFetchAllWithIncludeDeletedReturnsAllThreads() async throws {
        // Arrange
        let thread1 = try Thread(title: "Active Thread")
        let thread2 = try Thread(title: "Deleted Thread")
        
        try await repository.create(thread: thread1)
        try await repository.create(thread: thread2)
        try await repository.softDelete(threadId: thread2.id)
        
        // Act
        let allThreads = try await repository.fetchAll(includeDeleted: true)
        let activeThreads = try await repository.fetchAll(includeDeleted: false)
        
        // Assert
        XCTAssertEqual(allThreads.count, 2)
        XCTAssertEqual(activeThreads.count, 1)
        
        // All threads should include the deleted one
        XCTAssertTrue(allThreads.contains { $0.id == thread1.id })
        XCTAssertTrue(allThreads.contains { $0.id == thread2.id })
        
        // Active threads should not include the deleted one
        XCTAssertTrue(activeThreads.contains { $0.id == thread1.id })
        XCTAssertFalse(activeThreads.contains { $0.id == thread2.id })
        
        // Verify the deleted thread has deletedAt set
        let deletedThread = allThreads.first { $0.id == thread2.id }
        XCTAssertNotNil(deletedThread?.deletedAt)
        XCTAssertTrue(deletedThread?.isDeleted ?? false)
    }
    
    func testSoftDeletePreservesThreadData() async throws {
        // Arrange
        let originalTitle = "Important Thread"
        let thread = try Thread(title: originalTitle)
        try await repository.create(thread: thread)
        
        let originalCreatedAt = thread.createdAt
        let originalUpdatedAt = thread.updatedAt
        
        // Act
        try await repository.softDelete(threadId: thread.id)
        
        // Assert - All original data should be preserved
        let deletedThread = try await repository.fetch(threadId: thread.id)
        XCTAssertNotNil(deletedThread)
        XCTAssertEqual(deletedThread?.id, thread.id)
        XCTAssertEqual(deletedThread?.title, originalTitle)
        XCTAssertEqual(deletedThread?.createdAt, originalCreatedAt)
        XCTAssertEqual(deletedThread?.updatedAt, originalUpdatedAt)
        XCTAssertNotNil(deletedThread?.deletedAt)
    }
}