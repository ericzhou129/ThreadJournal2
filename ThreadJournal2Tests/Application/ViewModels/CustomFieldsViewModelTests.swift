//
//  CustomFieldsViewModelTests.swift
//  ThreadJournal2Tests
//
//  Tests for CustomFieldsViewModel
//

import XCTest
import Combine
@testable import ThreadJournal2

@MainActor
final class CustomFieldsViewModelTests: XCTestCase {
    private var mockRepository: MockThreadRepository!
    private var createFieldUseCase: CreateCustomFieldUseCase!
    private var createGroupUseCase: CreateFieldGroupUseCase!
    private var deleteFieldUseCase: DeleteCustomFieldUseCase!
    private var viewModel: CustomFieldsViewModel!
    private var cancellables: Set<AnyCancellable>!
    private let threadId = UUID()
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockRepository = MockThreadRepository()
        createFieldUseCase = CreateCustomFieldUseCase(threadRepository: mockRepository)
        createGroupUseCase = CreateFieldGroupUseCase(threadRepository: mockRepository)
        deleteFieldUseCase = DeleteCustomFieldUseCase(threadRepository: mockRepository)
        
        viewModel = CustomFieldsViewModel(
            threadId: threadId,
            threadRepository: mockRepository,
            createFieldUseCase: createFieldUseCase,
            createGroupUseCase: createGroupUseCase,
            deleteFieldUseCase: deleteFieldUseCase
        )
        
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Load Fields Tests
    
    func testLoadFieldsSuccess() async {
        // Given
        let expectedFields = [
            try! CustomField(threadId: threadId, name: "Mood", order: 1),
            try! CustomField(threadId: threadId, name: "Energy", order: 2)
        ]
        mockRepository.customFields = expectedFields
        
        // When
        await viewModel.loadFields()
        
        // Then
        XCTAssertEqual(viewModel.fields.count, 2)
        XCTAssertEqual(viewModel.fields[0].name, "Mood")
        XCTAssertEqual(viewModel.fields[1].name, "Energy")
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadFieldsFailure() async {
        // Given
        mockRepository.shouldFailFetch = true
        
        // When
        await viewModel.loadFields()
        
        // Then
        XCTAssertTrue(viewModel.fields.isEmpty)
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Add Field Tests
    
    func testAddFieldSuccess() async {
        // Given
        viewModel.newFieldName = "  Mood  "
        mockRepository.customFields = []
        
        // When
        await viewModel.addField()
        
        // Then
        XCTAssertEqual(viewModel.fields.count, 1)
        XCTAssertEqual(viewModel.fields[0].name, "Mood")
        XCTAssertEqual(viewModel.fields[0].order, 1)
        XCTAssertEqual(viewModel.newFieldName, "")
        XCTAssertNil(viewModel.validationError)
    }
    
    func testAddFieldEmptyName() async {
        // Given
        viewModel.newFieldName = "   "
        
        // When
        await viewModel.addField()
        
        // Then
        XCTAssertTrue(viewModel.fields.isEmpty)
        XCTAssertNotNil(viewModel.validationError)
    }
    
    func testAddFieldDuplicateName() async {
        // Given
        let existingField = try! CustomField(threadId: threadId, name: "Mood", order: 1)
        mockRepository.customFields = [existingField]
        await viewModel.loadFields()
        viewModel.newFieldName = "mood" // Case insensitive
        
        // When
        await viewModel.addField()
        
        // Then
        XCTAssertEqual(viewModel.fields.count, 1) // No new field added
        XCTAssertNotNil(viewModel.validationError)
    }
    
    func testAddFieldMaxFieldsExceeded() async {
        // Given - Create 20 fields (max)
        var fields: [CustomField] = []
        for i in 0..<20 {
            fields.append(try! CustomField(threadId: threadId, name: "Field \(i)", order: i))
        }
        mockRepository.customFields = fields
        await viewModel.loadFields()
        viewModel.newFieldName = "Field 21"
        
        // When
        await viewModel.addField()
        
        // Then
        XCTAssertEqual(viewModel.fields.count, 20) // No new field added
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.error?.contains("Maximum") ?? false)
    }
    
    // MARK: - Field Validation Tests
    
    func testFieldNameValidation() async {
        // Given
        let existingField = try! CustomField(threadId: threadId, name: "Mood", order: 1)
        mockRepository.customFields = [existingField]
        await viewModel.loadFields()
        
        let expectation = XCTestExpectation(description: "Validation completes")
        
        // When - Set duplicate name
        viewModel.newFieldName = "mood"
        
        // Wait for debounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNotNil(viewModel.validationError)
        XCTAssertTrue(viewModel.validationError?.contains("already exists") ?? false)
    }
    
    // MARK: - Delete Field Tests
    
    func testDeleteFieldSuccess() async {
        // Given
        let field = try! CustomField(threadId: threadId, name: "Mood", order: 1)
        mockRepository.customFields = [field]
        await viewModel.loadFields()
        
        // When
        await viewModel.deleteField(field)
        
        // Then
        XCTAssertTrue(viewModel.fields.isEmpty)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(mockRepository.softDeletedFieldIds.contains(field.id))
    }
    
    // MARK: - Create Group Tests
    
    func testCreateGroupSuccess() async {
        // Given
        let parentField = try! CustomField(threadId: threadId, name: "Health", order: 1)
        let childField1 = try! CustomField(threadId: threadId, name: "BP", order: 2)
        let childField2 = try! CustomField(threadId: threadId, name: "HR", order: 3)
        
        mockRepository.customFields = [parentField, childField1, childField2]
        await viewModel.loadFields()
        
        // When
        await viewModel.createGroup(
            parentFieldId: parentField.id,
            childFieldIds: [childField1.id, childField2.id]
        )
        
        // Then
        let updatedParent = viewModel.fields.first { $0.id == parentField.id }
        XCTAssertTrue(updatedParent?.isGroup ?? false)
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Move Fields Tests
    
    func testMoveFields() async {
        // Given
        let field1 = try! CustomField(threadId: threadId, name: "Field 1", order: 1)
        let field2 = try! CustomField(threadId: threadId, name: "Field 2", order: 2)
        let field3 = try! CustomField(threadId: threadId, name: "Field 3", order: 3)
        
        mockRepository.customFields = [field1, field2, field3]
        await viewModel.loadFields()
        
        // When - Move field 3 to position 1
        viewModel.moveFields(from: IndexSet(integer: 2), to: 0)
        
        // Then
        XCTAssertEqual(viewModel.fields[0].name, "Field 3")
        XCTAssertEqual(viewModel.fields[0].order, 1)
        XCTAssertEqual(viewModel.fields[1].name, "Field 1")
        XCTAssertEqual(viewModel.fields[1].order, 2)
        XCTAssertEqual(viewModel.fields[2].name, "Field 2")
        XCTAssertEqual(viewModel.fields[2].order, 3)
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStateChanges() async {
        // Given
        let expectation = XCTestExpectation(description: "Loading state changes")
        var loadingStates: [Bool] = []
        
        viewModel.$isLoading
            .sink { loading in
                loadingStates.append(loading)
                if loadingStates.count == 3 { // Initial false, true, false
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.loadFields()
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(loadingStates, [false, true, false])
    }
}