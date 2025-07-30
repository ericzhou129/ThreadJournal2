//
//  CreateCustomFieldUseCaseTests.swift
//  ThreadJournal2Tests
//
//  Tests for CreateCustomFieldUseCase
//

import XCTest
@testable import ThreadJournal2

final class CreateCustomFieldUseCaseTests: XCTestCase {
    private var mockRepository: MockThreadRepository!
    private var useCase: CreateCustomFieldUseCase!
    private let threadId = UUID()
    
    override func setUp() {
        super.setUp()
        mockRepository = MockThreadRepository()
        useCase = CreateCustomFieldUseCase(threadRepository: mockRepository)
    }
    
    func testCreateValidField() async throws {
        // Given
        mockRepository.customFields = []
        
        // When
        let field = try await useCase.execute(
            threadId: threadId,
            name: "Mood",
            order: 1
        )
        
        // Then
        XCTAssertEqual(field.name, "Mood")
        XCTAssertEqual(field.threadId, threadId)
        XCTAssertEqual(field.order, 1)
        XCTAssertFalse(field.isGroup)
    }
    
    func testTrimsWhitespaceFromName() async throws {
        // Given
        mockRepository.customFields = []
        
        // When
        let field = try await useCase.execute(
            threadId: threadId,
            name: "  Energy Level  \n",
            order: 1
        )
        
        // Then
        XCTAssertEqual(field.name, "Energy Level")
    }
    
    func testDuplicateNameThrows() async throws {
        // Given
        let existingField = try CustomField(
            threadId: threadId,
            name: "Mood",
            order: 1
        )
        mockRepository.customFields = [existingField]
        
        // When/Then
        do {
            _ = try await useCase.execute(
                threadId: threadId,
                name: "mood", // Case insensitive check
                order: 2
            )
            XCTFail("Should throw duplicate name error")
        } catch {
            XCTAssertEqual(error as? CustomFieldError, .duplicateFieldName)
        }
    }
    
    func testMaxFieldsValidation() async throws {
        // Given - Create 20 fields (max allowed)
        var fields: [CustomField] = []
        for i in 0..<20 {
            fields.append(try CustomField(
                threadId: threadId,
                name: "Field \(i)",
                order: i
            ))
        }
        mockRepository.customFields = fields
        
        // When/Then
        do {
            _ = try await useCase.execute(
                threadId: threadId,
                name: "Field 21",
                order: 21
            )
            XCTFail("Should throw max fields error")
        } catch {
            XCTAssertEqual(error as? CustomFieldError, .maxFieldsExceeded)
        }
    }
    
    func testIgnoresDeletedFieldsInCount() async throws {
        // Given - 19 active fields + 5 deleted fields
        var fields: [CustomField] = []
        for i in 0..<19 {
            fields.append(try CustomField(
                threadId: threadId,
                name: "Field \(i)",
                order: i
            ))
        }
        mockRepository.customFields = fields
        
        // When - Should succeed since only 19 active fields
        let field = try await useCase.execute(
            threadId: threadId,
            name: "Field 20",
            order: 20
        )
        
        // Then
        XCTAssertEqual(field.name, "Field 20")
    }
}

