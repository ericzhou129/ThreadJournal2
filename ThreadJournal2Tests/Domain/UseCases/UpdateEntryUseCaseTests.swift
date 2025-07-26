//
//  UpdateEntryUseCaseTests.swift
//  ThreadJournal2Tests
//
//  Unit tests for UpdateEntryUseCase
//

import XCTest
@testable import ThreadJournal2

@MainActor
final class UpdateEntryUseCaseTests: XCTestCase {
    
    private var sut: UpdateEntryUseCase!
    private var mockRepository: MockThreadRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockThreadRepository()
        sut = UpdateEntryUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testExecute_withValidContent_updatesEntry() async throws {
        // Given
        let entryId = UUID()
        let threadId = UUID()
        let originalEntry = try Entry(
            id: entryId,
            threadId: threadId,
            content: "Original content",
            timestamp: Date()
        )
        let newContent = "Updated content"
        
        // Configure mock to return the entry
        mockRepository.fetchEntryResult = originalEntry
        mockRepository.updateEntryResult = try Entry(
            id: entryId,
            threadId: threadId,
            content: newContent,
            timestamp: originalEntry.timestamp
        )
        
        // When
        let result = try await sut.execute(entryId: entryId, newContent: newContent)
        
        // Then
        XCTAssertEqual(result.content, newContent)
        XCTAssertEqual(result.id, entryId)
        XCTAssertEqual(mockRepository.fetchEntryCallCount, 1)
        XCTAssertEqual(mockRepository.updateEntryCallCount, 1)
    }
    
    func testExecute_withEmptyContent_throwsValidationError() async {
        // Given
        let entryId = UUID()
        let emptyContent = "   "
        
        // When/Then
        do {
            _ = try await sut.execute(entryId: entryId, newContent: emptyContent)
            XCTFail("Expected ValidationError.emptyContent")
        } catch {
            XCTAssertEqual(error as? ValidationError, ValidationError.emptyContent)
        }
    }
    
    func testExecute_whenEntryNotFound_throwsPersistenceError() async {
        // Given
        let entryId = UUID()
        let newContent = "Updated content"
        
        // Configure mock to return nil (entry not found)
        mockRepository.fetchEntryResult = nil
        
        // When/Then
        do {
            _ = try await sut.execute(entryId: entryId, newContent: newContent)
            XCTFail("Expected PersistenceError.notFound")
        } catch {
            if let persistenceError = error as? PersistenceError,
               case .notFound(let id) = persistenceError {
                XCTAssertEqual(id, entryId)
            } else {
                XCTFail("Expected PersistenceError.notFound")
            }
        }
    }
    
    func testExecute_withWhitespaceContent_trimmsAndSaves() async throws {
        // Given
        let entryId = UUID()
        let threadId = UUID()
        let originalEntry = try Entry(
            id: entryId,
            threadId: threadId,
            content: "Original",
            timestamp: Date()
        )
        let contentWithWhitespace = "  Updated content  \n"
        let trimmedContent = "Updated content"
        
        // Configure mock
        mockRepository.fetchEntryResult = originalEntry
        mockRepository.updateEntryResult = try Entry(
            id: entryId,
            threadId: threadId,
            content: trimmedContent,
            timestamp: originalEntry.timestamp
        )
        
        // When
        let result = try await sut.execute(entryId: entryId, newContent: contentWithWhitespace)
        
        // Then
        XCTAssertEqual(result.content, trimmedContent)
    }
}