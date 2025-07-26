//
//  DeleteEntryUseCaseTests.swift
//  ThreadJournal2Tests
//
//  Unit tests for DeleteEntryUseCase
//

import XCTest
@testable import ThreadJournal2

@MainActor
final class DeleteEntryUseCaseTests: XCTestCase {
    
    private var sut: DeleteEntryUseCase!
    private var mockRepository: MockThreadRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockThreadRepository()
        sut = DeleteEntryUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testExecute_callsSoftDeleteOnRepository() async throws {
        // Given
        let entryId = UUID()
        
        // When
        try await sut.execute(entryId: entryId)
        
        // Then
        XCTAssertEqual(mockRepository.softDeleteEntryCallCount, 1)
        XCTAssertEqual(mockRepository.lastSoftDeletedEntryId, entryId)
    }
    
    func testExecute_whenRepositoryThrows_propagatesError() async {
        // Given
        let entryId = UUID()
        let expectedError = PersistenceError.notFound(id: entryId)
        mockRepository.softDeleteEntryError = expectedError
        
        // When/Then
        do {
            try await sut.execute(entryId: entryId)
            XCTFail("Expected error to be thrown")
        } catch {
            if let persistenceError = error as? PersistenceError,
               case .notFound(let id) = persistenceError {
                XCTAssertEqual(id, entryId)
            } else {
                XCTFail("Expected PersistenceError.notFound")
            }
        }
    }
}