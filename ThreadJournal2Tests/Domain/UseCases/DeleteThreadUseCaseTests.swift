//
//  DeleteThreadUseCaseTests.swift
//  ThreadJournal2Tests
//
//  Tests for DeleteThreadUseCase
//

import XCTest
@testable import ThreadJournal2

final class DeleteThreadUseCaseTests: XCTestCase {
    
    private var sut: DeleteThreadUseCase!
    private var mockRepository: MockDeleteThreadRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockDeleteThreadRepository()
        sut = DeleteThreadUseCaseImpl(repository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Success Tests
    
    func testExecute_WhenThreadExists_DeletesSuccessfully() async throws {
        // Given
        let threadId = UUID()
        let thread = try ThreadJournal2.Thread(title: "Test Thread")
        mockRepository.mockThreads[threadId] = thread
        
        // When
        try await sut.execute(threadId: threadId)
        
        // Then
        XCTAssertTrue(mockRepository.softDeleteCalled)
        XCTAssertEqual(mockRepository.softDeletedThreadId, threadId)
    }
    
    // MARK: - Error Tests
    
    func testExecute_WhenThreadDoesNotExist_ThrowsThreadNotFoundError() async {
        // Given
        let nonExistentThreadId = UUID()
        
        // When/Then
        do {
            try await sut.execute(threadId: nonExistentThreadId)
            XCTFail("Expected ThreadNotFoundError to be thrown")
        } catch let error as ThreadNotFoundError {
            XCTAssertEqual(error.threadId, nonExistentThreadId)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testExecute_WhenRepositoryThrowsError_PropagatesError() async {
        // Given
        let threadId = UUID()
        let thread = try! Thread(title: "Test Thread")
        mockRepository.mockThreads[threadId] = thread
        mockRepository.shouldThrowError = true
        
        // When/Then
        do {
            try await sut.execute(threadId: threadId)
            XCTFail("Expected PersistenceError to be thrown")
        } catch is PersistenceError {
            // Expected error
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Business Logic Tests
    
    func testExecute_VerifiesThreadExistsBeforeDeleting() async throws {
        // Given
        let threadId = UUID()
        let thread = try ThreadJournal2.Thread(title: "Test Thread")
        mockRepository.mockThreads[threadId] = thread
        
        // When
        try await sut.execute(threadId: threadId)
        
        // Then
        XCTAssertTrue(mockRepository.fetchThreadCalled)
        XCTAssertEqual(mockRepository.fetchedThreadId, threadId)
        XCTAssertTrue(mockRepository.fetchThreadCalledBeforeSoftDelete)
    }
}

// MARK: - Mock Repository

private class MockDeleteThreadRepository: ThreadRepository {
    var mockThreads: [UUID: ThreadJournal2.Thread] = [:]
    var shouldThrowError = false
    
    var fetchThreadCalled = false
    var fetchedThreadId: UUID?
    var deleteThreadCalled = false
    var deletedThreadId: UUID?
    var fetchThreadCalledBeforeDelete = false
    var softDeleteCalled = false
    var softDeletedThreadId: UUID?
    var fetchThreadCalledBeforeSoftDelete = false
    
    func create(thread: ThreadJournal2.Thread) async throws {
        if shouldThrowError {
            throw PersistenceError.saveFailed(underlying: NSError(domain: "test", code: 1))
        }
    }
    
    func update(thread: ThreadJournal2.Thread) async throws {
        if shouldThrowError {
            throw PersistenceError.updateFailed(underlying: NSError(domain: "test", code: 1))
        }
    }
    
    func delete(threadId: UUID) async throws {
        deleteThreadCalled = true
        deletedThreadId = threadId
        
        if shouldThrowError {
            throw PersistenceError.deleteFailed(underlying: NSError(domain: "test", code: 1))
        }
        
        mockThreads.removeValue(forKey: threadId)
    }
    
    func softDelete(threadId: UUID) async throws {
        softDeleteCalled = true
        softDeletedThreadId = threadId
        
        if shouldThrowError {
            throw PersistenceError.deleteFailed(underlying: NSError(domain: "test", code: 1))
        }
        
        // Mark thread as deleted but keep in storage
        if var thread = mockThreads[threadId] {
            thread = try! ThreadJournal2.Thread(
                id: thread.id,
                title: thread.title,
                createdAt: thread.createdAt,
                updatedAt: thread.updatedAt,
                deletedAt: Date()
            )
            mockThreads[threadId] = thread
        }
    }
    
    func fetch(threadId: UUID) async throws -> ThreadJournal2.Thread? {
        fetchThreadCalled = true
        fetchedThreadId = threadId
        
        if !deleteThreadCalled {
            fetchThreadCalledBeforeDelete = true
        }
        
        if !softDeleteCalled {
            fetchThreadCalledBeforeSoftDelete = true
        }
        
        if shouldThrowError {
            throw PersistenceError.fetchFailed(underlying: NSError(domain: "test", code: 1))
        }
        
        return mockThreads[threadId]
    }
    
    func fetchAll() async throws -> [ThreadJournal2.Thread] {
        if shouldThrowError {
            throw PersistenceError.fetchFailed(underlying: NSError(domain: "test", code: 1))
        }
        return Array(mockThreads.values).filter { $0.deletedAt == nil }
    }
    
    func fetchAll(includeDeleted: Bool) async throws -> [ThreadJournal2.Thread] {
        if shouldThrowError {
            throw PersistenceError.fetchFailed(underlying: NSError(domain: "test", code: 1))
        }
        
        if includeDeleted {
            return Array(mockThreads.values)
        } else {
            return Array(mockThreads.values).filter { $0.deletedAt == nil }
        }
    }
    
    func addEntry(_ entry: Entry, to threadId: UUID) async throws {
        if shouldThrowError {
            throw PersistenceError.saveFailed(underlying: NSError(domain: "test", code: 1))
        }
    }
    
    func fetchEntries(for threadId: UUID) async throws -> [Entry] {
        if shouldThrowError {
            throw PersistenceError.fetchFailed(underlying: NSError(domain: "test", code: 1))
        }
        return []
    }
    
    func fetchEntry(id: UUID) async throws -> Entry? {
        if shouldThrowError {
            throw PersistenceError.fetchFailed(underlying: NSError(domain: "test", code: 1))
        }
        return nil
    }
    
    func updateEntry(_ entry: Entry) async throws -> Entry {
        if shouldThrowError {
            throw PersistenceError.updateFailed(underlying: NSError(domain: "test", code: 1))
        }
        return entry
    }
    
    func softDeleteEntry(entryId: UUID) async throws {
        if shouldThrowError {
            throw PersistenceError.deleteFailed(underlying: NSError(domain: "test", code: 1))
        }
    }
    
    // MARK: - Custom Fields (Added for protocol conformance)
    
    func createCustomField(_ field: CustomField) async throws {
        if shouldThrowError {
            throw PersistenceError.saveFailed(underlying: NSError(domain: "test", code: 1))
        }
    }
    
    func updateCustomField(_ field: CustomField) async throws {
        if shouldThrowError {
            throw PersistenceError.updateFailed(underlying: NSError(domain: "test", code: 1))
        }
    }
    
    func softDeleteCustomField(fieldId: UUID) async throws {
        if shouldThrowError {
            throw PersistenceError.deleteFailed(underlying: NSError(domain: "test", code: 1))
        }
    }
    
    func fetchCustomFields(for threadId: UUID, includeDeleted: Bool) async throws -> [CustomField] {
        if shouldThrowError {
            throw PersistenceError.fetchFailed(underlying: NSError(domain: "test", code: 1))
        }
        return []
    }
    
    func createFieldGroup(parentFieldId: UUID, childFieldIds: [UUID]) async throws {
        if shouldThrowError {
            throw PersistenceError.saveFailed(underlying: NSError(domain: "test", code: 1))
        }
    }
    
    func removeFromGroup(fieldId: UUID) async throws {
        if shouldThrowError {
            throw PersistenceError.updateFailed(underlying: NSError(domain: "test", code: 1))
        }
    }
}