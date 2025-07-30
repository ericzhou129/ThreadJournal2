//
//  DeleteCustomFieldUseCaseTests.swift
//  ThreadJournal2Tests
//
//  Tests for DeleteCustomFieldUseCase
//

import XCTest
@testable import ThreadJournal2

final class DeleteCustomFieldUseCaseTests: XCTestCase {
    private var mockRepository: MockThreadRepository!
    private var useCase: DeleteCustomFieldUseCase!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockThreadRepository()
        useCase = DeleteCustomFieldUseCase(threadRepository: mockRepository)
    }
    
    func testDeleteFieldPreservesHistoricalData() async throws {
        // Given
        let fieldId = UUID()
        mockRepository.softDeletedFieldIds = []
        
        // When
        try await useCase.execute(
            fieldId: fieldId,
            preserveHistoricalData: true
        )
        
        // Then
        XCTAssertTrue(mockRepository.softDeletedFieldIds.contains(fieldId))
    }
    
    func testDeleteFieldAlwaysSoftDeletes() async throws {
        // Given
        let fieldId = UUID()
        mockRepository.softDeletedFieldIds = []
        
        // When - Even with preserveHistoricalData = false
        try await useCase.execute(
            fieldId: fieldId,
            preserveHistoricalData: false
        )
        
        // Then - Still soft deletes (as per current implementation)
        XCTAssertTrue(mockRepository.softDeletedFieldIds.contains(fieldId))
    }
}

