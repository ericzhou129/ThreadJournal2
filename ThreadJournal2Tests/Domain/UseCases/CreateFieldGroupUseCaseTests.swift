//
//  CreateFieldGroupUseCaseTests.swift
//  ThreadJournal2Tests
//
//  Tests for CreateFieldGroupUseCase
//

import XCTest
@testable import ThreadJournal2

final class CreateFieldGroupUseCaseTests: XCTestCase {
    private var mockRepository: MockThreadRepository!
    private var useCase: CreateFieldGroupUseCase!
    private let threadId = UUID()
    
    override func setUp() {
        super.setUp()
        mockRepository = MockThreadRepository()
        useCase = CreateFieldGroupUseCase(threadRepository: mockRepository)
        
        // Setup a test thread
        Task {
            let thread = try Thread(title: "Test Thread")
            try await mockRepository.create(thread: thread)
        }
    }
    
    func testCreateGroupFromRegularField() async throws {
        // Given
        let parentField = try CustomField(
            id: UUID(),
            threadId: threadId,
            name: "ADHD Check-in",
            order: 1,
            isGroup: false // Regular field
        )
        
        let child1 = try CustomField(
            threadId: threadId,
            name: "Mood",
            order: 2
        )
        
        let child2 = try CustomField(
            threadId: threadId,
            name: "Energy",
            order: 3
        )
        
        mockRepository.customFields = [parentField, child1, child2]
        
        // When
        let group = try await useCase.execute(
            parentFieldId: parentField.id,
            childFieldIds: [child1.id, child2.id]
        )
        
        // Then
        XCTAssertTrue(group.parentField.isGroup)
        XCTAssertEqual(group.parentField.name, "ADHD Check-in")
        XCTAssertEqual(group.childFields.count, 2)
    }
    
    func testNestedGroupsNotAllowed() async throws {
        // Given
        let parentField = try CustomField(
            id: UUID(),
            threadId: threadId,
            name: "Parent Group",
            order: 1,
            isGroup: true
        )
        
        let nestedGroup = try CustomField(
            id: UUID(),
            threadId: threadId,
            name: "Nested Group",
            order: 2,
            isGroup: true // This is a group
        )
        
        mockRepository.customFields = [parentField, nestedGroup]
        
        // When/Then
        do {
            _ = try await useCase.execute(
                parentFieldId: parentField.id,
                childFieldIds: [nestedGroup.id]
            )
            XCTFail("Should throw nested groups error")
        } catch {
            XCTAssertEqual(error as? ValidationError, .nestedGroupsNotAllowed)
        }
    }
    
    func testParentFieldNotFound() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When/Then
        do {
            _ = try await useCase.execute(
                parentFieldId: nonExistentId,
                childFieldIds: []
            )
            XCTFail("Should throw not found error")
        } catch {
            XCTAssertTrue(error is PersistenceError)
        }
    }
}

// Extend MockThreadRepository for group operations
extension MockThreadRepository {
    func updateCustomField(_ field: CustomField) async throws {
        if let index = customFields.firstIndex(where: { $0.id == field.id }) {
            customFields[index] = field
        }
    }
    
    func createFieldGroup(parentFieldId: UUID, childFieldIds: [UUID]) async throws {
        // Mock implementation - just verify the IDs exist
        guard customFields.contains(where: { $0.id == parentFieldId }) else {
            throw PersistenceError.notFound(id: parentFieldId)
        }
    }
}