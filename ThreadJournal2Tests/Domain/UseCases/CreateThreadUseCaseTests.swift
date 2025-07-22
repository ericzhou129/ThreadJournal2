//
//  CreateThreadUseCaseTests.swift
//  ThreadJournal2Tests
//
//  Tests for CreateThreadUseCase
//

import XCTest
@testable import ThreadJournal2

final class CreateThreadUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: CreateThreadUseCase!
    private var mockRepository: MockThreadRepository!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        mockRepository = MockThreadRepository()
        sut = CreateThreadUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        
        super.tearDown()
    }
    
    // MARK: - Success Tests
    
    func testExecute_ValidTitle_CreatesThread() async throws {
        // Given
        let title = "Test Thread"
        
        // When
        let thread = try await sut.execute(title: title)
        
        // Then
        XCTAssertEqual(thread.title, title)
        XCTAssertNotNil(thread.id)
        XCTAssertNotNil(thread.createdAt)
        XCTAssertNotNil(thread.updatedAt)
        XCTAssertEqual(thread.createdAt, thread.updatedAt)
        
        // Verify repository was called
        XCTAssertEqual(mockRepository.createCallCount, 1)
        XCTAssertEqual(mockRepository.threads.count, 1)
        XCTAssertEqual(mockRepository.threads[0].title, title)
    }
    
    func testExecute_WithFirstEntry_CreatesThreadAndEntry() async throws {
        // Given
        let title = "Thread with Entry"
        let firstEntryContent = "This is the first entry"
        
        // When
        let thread = try await sut.execute(title: title, firstEntry: firstEntryContent)
        
        // Then
        XCTAssertEqual(thread.title, title)
        
        // Verify thread was created
        XCTAssertEqual(mockRepository.createCallCount, 1)
        XCTAssertEqual(mockRepository.threads.count, 1)
        
        // Verify entry was added
        XCTAssertEqual(mockRepository.addEntryCallCount, 1)
        let entries = mockRepository.entries[thread.id] ?? []
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].content, firstEntryContent)
        XCTAssertEqual(entries[0].threadId, thread.id)
    }
    
    func testExecute_WithEmptyFirstEntry_CreatesThreadOnly() async throws {
        // Given
        let title = "Thread without Entry"
        let emptyEntry = "   "
        
        // When
        let thread = try await sut.execute(title: title, firstEntry: emptyEntry)
        
        // Then
        XCTAssertEqual(thread.title, title)
        
        // Verify only thread was created, no entry
        XCTAssertEqual(mockRepository.createCallCount, 1)
        XCTAssertEqual(mockRepository.addEntryCallCount, 0)
        let entries = mockRepository.entries[thread.id] ?? []
        XCTAssertTrue(entries.isEmpty)
    }
    
    func testExecute_WithNilFirstEntry_CreatesThreadOnly() async throws {
        // Given
        let title = "Thread without Entry"
        
        // When
        let thread = try await sut.execute(title: title, firstEntry: nil)
        
        // Then
        XCTAssertEqual(thread.title, title)
        
        // Verify only thread was created
        XCTAssertEqual(mockRepository.createCallCount, 1)
        XCTAssertEqual(mockRepository.addEntryCallCount, 0)
    }
    
    // MARK: - Validation Tests
    
    func testExecute_EmptyTitle_ThrowsValidationError() async {
        // Given
        let emptyTitle = ""
        
        // When/Then
        do {
            _ = try await sut.execute(title: emptyTitle)
            XCTFail("Expected ValidationError.emptyTitle")
        } catch let error as ValidationError {
            XCTAssertEqual(error, .emptyTitle)
        } catch {
            XCTFail("Expected ValidationError.emptyTitle, got \(error)")
        }
        
        // Verify nothing was created
        XCTAssertEqual(mockRepository.createCallCount, 0)
    }
    
    func testExecute_WhitespaceTitle_ThrowsValidationError() async {
        // Given
        let whitespaceTitle = "   \n\t   "
        
        // When/Then
        do {
            _ = try await sut.execute(title: whitespaceTitle)
            XCTFail("Expected ValidationError.emptyTitle")
        } catch let error as ValidationError {
            XCTAssertEqual(error, .emptyTitle)
        } catch {
            XCTFail("Expected ValidationError.emptyTitle, got \(error)")
        }
    }
    
    // MARK: - Repository Error Tests
    
    func testExecute_RepositoryCreateFails_ThrowsPersistenceError() async {
        // Given
        mockRepository.shouldFailCreate = true
        let expectedError = PersistenceError.saveFailed(underlying: NSError(domain: "Test", code: 1))
        mockRepository.injectedError = expectedError
        
        // When/Then
        do {
            _ = try await sut.execute(title: "Valid Title")
            XCTFail("Expected PersistenceError")
        } catch let error as PersistenceError {
            if case .saveFailed = error {
                // Success
            } else {
                XCTFail("Expected PersistenceError.saveFailed")
            }
        } catch {
            XCTFail("Expected PersistenceError, got \(error)")
        }
    }
    
    func testExecute_EntryAddFails_ThrowsPersistenceError() async {
        // Given
        mockRepository.shouldFailAddEntry = true
        let expectedError = PersistenceError.saveFailed(underlying: NSError(domain: "Test", code: 1))
        mockRepository.injectedError = expectedError
        
        // When/Then
        do {
            _ = try await sut.execute(title: "Valid Title", firstEntry: "Entry content")
            XCTFail("Expected PersistenceError")
        } catch let error as PersistenceError {
            if case .saveFailed = error {
                // Success
            } else {
                XCTFail("Expected PersistenceError.saveFailed")
            }
        } catch {
            XCTFail("Expected PersistenceError, got \(error)")
        }
        
        // Verify thread was created but entry failed
        XCTAssertEqual(mockRepository.createCallCount, 1)
        XCTAssertEqual(mockRepository.addEntryCallCount, 1)
    }
    
    // MARK: - Timestamp Tests
    
    func testExecute_SetsCorrectTimestamps() async throws {
        // Given
        let title = "Timestamp Test"
        let beforeCreation = Date()
        
        // When
        let thread = try await sut.execute(title: title)
        let afterCreation = Date()
        
        // Then
        XCTAssertTrue(thread.createdAt >= beforeCreation)
        XCTAssertTrue(thread.createdAt <= afterCreation)
        XCTAssertEqual(thread.createdAt, thread.updatedAt)
    }
}