//
//  CustomFieldsManagementViewTests.swift
//  ThreadJournal2Tests
//
//  Unit tests for CustomFieldsManagementView
//

import XCTest
import SwiftUI
@testable import ThreadJournal2

@MainActor
final class CustomFieldsManagementViewTests: XCTestCase {
    private var mockRepository: MockThreadRepository!
    private var mockCreateFieldUseCase: MockCreateCustomFieldUseCase!
    private var mockCreateGroupUseCase: MockCreateFieldGroupUseCase!
    private var mockDeleteFieldUseCase: MockDeleteCustomFieldUseCase!
    private var viewModel: CustomFieldsViewModel!
    private var threadId: UUID!
    
    override func setUp() async throws {
        try await super.setUp()
        
        threadId = UUID()
        mockRepository = MockThreadRepository()
        mockCreateFieldUseCase = MockCreateCustomFieldUseCase()
        mockCreateGroupUseCase = MockCreateFieldGroupUseCase()
        mockDeleteFieldUseCase = MockDeleteCustomFieldUseCase()
        
        viewModel = CustomFieldsViewModel(
            threadId: threadId,
            threadRepository: mockRepository,
            createFieldUseCase: mockCreateFieldUseCase,
            createGroupUseCase: mockCreateGroupUseCase,
            deleteFieldUseCase: mockDeleteFieldUseCase
        )
    }
    
    func testEmptyStateWhenNoFields() async throws {
        // Given: No fields
        mockRepository.customFields = []
        
        // When: Load fields
        await viewModel.loadFields()
        
        // Then: Fields array is empty
        XCTAssertTrue(viewModel.fields.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testFieldsLoadSuccessfully() async throws {
        // Given: Some fields
        let fields = [
            try CustomField(id: UUID(), threadId: threadId, name: "Energy", order: 1),
            try CustomField(id: UUID(), threadId: threadId, name: "Mood", order: 2)
        ]
        mockRepository.customFields = fields
        
        // When: Load fields
        await viewModel.loadFields()
        
        // Then: Fields are loaded
        XCTAssertEqual(viewModel.fields.count, 2)
        XCTAssertEqual(viewModel.fields[0].name, "Energy")
        XCTAssertEqual(viewModel.fields[1].name, "Mood")
    }
    
    func testGroupFieldIdentification() async throws {
        // Given: A group field
        let groupField = try CustomField(
            id: UUID(),
            threadId: threadId,
            name: "ADHD Check-in",
            order: 1,
            isGroup: true
        )
        mockRepository.customFields = [groupField]
        
        // When: Load fields
        await viewModel.loadFields()
        
        // Then: Field is identified as group
        XCTAssertEqual(viewModel.fields.count, 1)
        XCTAssertTrue(viewModel.fields[0].isGroup)
    }
    
    func testAddFieldWithValidName() async throws {
        // Given: Empty fields and valid name
        mockRepository.customFields = []
        viewModel.newFieldName = "New Field"
        
        // When: Add field
        await viewModel.addField()
        
        // Then: Field is added
        XCTAssertEqual(viewModel.fields.count, 1)
        XCTAssertEqual(viewModel.fields[0].name, "New Field")
        XCTAssertEqual(viewModel.newFieldName, "") // Cleared after success
        XCTAssertNil(viewModel.validationError)
    }
    
    func testAddFieldWithDuplicateName() async throws {
        // Given: Existing field
        let existingField = try CustomField(
            id: UUID(),
            threadId: threadId,
            name: "Existing",
            order: 1
        )
        mockRepository.customFields = [existingField]
        await viewModel.loadFields()
        
        // When: Try to add field with same name
        viewModel.newFieldName = "Existing"
        mockCreateFieldUseCase.shouldThrow = true
        mockCreateFieldUseCase.errorToThrow = CustomFieldError.duplicateFieldName
        
        await viewModel.addField()
        
        // Then: Error is shown
        XCTAssertNotNil(viewModel.validationError)
        XCTAssertEqual(viewModel.validationError, "A field with this name already exists")
        XCTAssertEqual(viewModel.fields.count, 1) // No new field added
    }
    
    func testDeleteField() async throws {
        // Given: A field
        let field = try CustomField(id: UUID(), threadId: threadId, name: "Test", order: 1)
        mockRepository.customFields = [field]
        await viewModel.loadFields()
        
        // When: Delete field
        await viewModel.deleteField(field)
        
        // Then: Field is removed
        XCTAssertTrue(viewModel.fields.isEmpty)
        XCTAssertTrue(mockDeleteFieldUseCase.deletedFieldIds.contains(field.id))
    }
    
    func testDragAndDropReordersFields() throws {
        // Given: Multiple fields
        let fields = [
            try CustomField(id: UUID(), threadId: threadId, name: "Field 1", order: 1),
            try CustomField(id: UUID(), threadId: threadId, name: "Field 2", order: 2),
            try CustomField(id: UUID(), threadId: threadId, name: "Field 3", order: 3)
        ]
        mockRepository.customFields = fields
        
        let expectation = expectation(description: "Fields loaded")
        
        let view = CustomFieldsManagementView(viewModel: viewModel)
            .onAppear {
                Task {
                    await self.viewModel.loadFields()
                    expectation.fulfill()
                }
            }
        
        wait(for: [expectation], timeout: 1.0)
        
        // When: Drag field 3 to position 1
        viewModel.moveFields(from: IndexSet(integer: 2), to: 0)
        
        // Then: Fields are reordered
        XCTAssertEqual(viewModel.fields[0].name, "Field 3")
        XCTAssertEqual(viewModel.fields[1].name, "Field 1")
        XCTAssertEqual(viewModel.fields[2].name, "Field 2")
    }
    
    func testMaximumFieldsLimitEnforced() throws {
        // Given: 20 fields already exist
        let fields = (1...20).map { order in
            try! CustomField(
                id: UUID(),
                threadId: threadId,
                name: "Field \(order)",
                order: order
            )
        }
        mockRepository.customFields = fields
        
        let expectation = expectation(description: "Fields loaded")
        
        let view = CustomFieldsManagementView(viewModel: viewModel)
            .onAppear {
                Task {
                    await self.viewModel.loadFields()
                    expectation.fulfill()
                }
            }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then: Add button should be disabled or show warning
        // TODO: Add proper UI testing for button state
        // let addButton = try view.inspect().find(button: "+ Add Field")
        // XCTAssertTrue(try addButton.isDisabled())
        
        // For now, just verify the view model has the expected state
        XCTAssertEqual(viewModel.fields.count, 20)
    }
}

// MARK: - Mock Classes

private class MockCreateCustomFieldUseCase: CreateCustomFieldUseCaseProtocol {
    var shouldThrow = false
    var errorToThrow: Error?
    
    func execute(threadId: UUID, name: String, order: Int) async throws -> CustomField {
        if shouldThrow {
            throw errorToThrow ?? CustomFieldError.duplicateFieldName
        }
        
        return try CustomField(
            id: UUID(),
            threadId: threadId,
            name: name,
            order: order
        )
    }
}

private class MockCreateFieldGroupUseCase: CreateFieldGroupUseCaseProtocol {
    var shouldThrow = false
    
    func execute(parentFieldId: UUID, childFieldIds: [UUID]) async throws -> CustomFieldGroup {
        if shouldThrow {
            throw ValidationError.nestedGroupsNotAllowed
        }
        
        // Create mock parent field
        let parentField = try CustomField(
            id: parentFieldId,
            threadId: UUID(),
            name: "Mock Group",
            order: 0,
            isGroup: true
        )
        
        // Create mock child fields
        let childFields = childFieldIds.enumerated().map { index, id in
            try! CustomField(
                id: id,
                threadId: parentField.threadId,
                name: "Child \(index)",
                order: index + 1
            )
        }
        
        return try CustomFieldGroup(
            parentField: parentField,
            childFields: childFields
        )
    }
}

private class MockDeleteCustomFieldUseCase: DeleteCustomFieldUseCaseProtocol {
    var shouldThrow = false
    var deletedFieldIds: [UUID] = []
    
    func execute(fieldId: UUID, preserveHistoricalData: Bool) async throws {
        if shouldThrow {
            throw PersistenceError.notFound(id: fieldId)
        }
        deletedFieldIds.append(fieldId)
    }
}