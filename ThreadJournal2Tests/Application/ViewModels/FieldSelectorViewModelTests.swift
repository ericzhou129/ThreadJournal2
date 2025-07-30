//
//  FieldSelectorViewModelTests.swift
//  ThreadJournal2Tests
//
//  Tests for FieldSelectorViewModel
//

import XCTest
@testable import ThreadJournal2

@MainActor
final class FieldSelectorViewModelTests: XCTestCase {
    private var mockRepository: MockThreadRepository!
    private var viewModel: FieldSelectorViewModel!
    private let threadId = UUID()
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockRepository = MockThreadRepository()
        viewModel = FieldSelectorViewModel(
            threadId: threadId,
            threadRepository: mockRepository
        )
    }
    
    // MARK: - Load Fields Tests
    
    func testLoadFieldsSuccess() async {
        // Given
        let fields = [
            try! CustomField(threadId: threadId, name: "Mood", order: 1),
            try! CustomField(threadId: threadId, name: "Energy", order: 2),
            try! CustomField(threadId: threadId, name: "Health", order: 3, isGroup: true)
        ]
        mockRepository.customFields = fields
        
        // When
        await viewModel.loadFields()
        
        // Then
        XCTAssertEqual(viewModel.selectableFields.count, 3)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testLoadFieldsFailure() async {
        // Given
        mockRepository.shouldFailFetch = true
        
        // When
        await viewModel.loadFields()
        
        // Then
        XCTAssertTrue(viewModel.selectableFields.isEmpty)
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Field Selection Tests
    
    func testToggleFieldSelection() async {
        // Given
        let field = try! CustomField(threadId: threadId, name: "Mood", order: 1)
        mockRepository.customFields = [field]
        await viewModel.loadFields()
        
        // When - Toggle on
        viewModel.toggleField(field.id)
        
        // Then
        XCTAssertTrue(viewModel.selectedFieldIds.contains(field.id))
        XCTAssertTrue(viewModel.hasSelectedFields)
        XCTAssertEqual(viewModel.selectedFields.count, 1)
        
        // When - Toggle off
        viewModel.toggleField(field.id)
        
        // Then
        XCTAssertFalse(viewModel.selectedFieldIds.contains(field.id))
        XCTAssertFalse(viewModel.hasSelectedFields)
        XCTAssertTrue(viewModel.selectedFields.isEmpty)
    }
    
    func testToggleGroupSelection() async {
        // Given
        let group = try! CustomField(threadId: threadId, name: "Health", order: 1, isGroup: true)
        mockRepository.customFields = [group]
        await viewModel.loadFields()
        
        // When - Toggle group
        viewModel.toggleField(group.id)
        
        // Then
        XCTAssertTrue(viewModel.selectedFieldIds.contains(group.id))
        XCTAssertTrue(viewModel.selectableFields[0].isSelected)
    }
    
    func testSelectGroup() async {
        // Given
        let group = try! CustomField(threadId: threadId, name: "Health", order: 1, isGroup: true)
        mockRepository.customFields = [group]
        await viewModel.loadFields()
        
        // When
        viewModel.selectGroup(group.id)
        
        // Then
        XCTAssertTrue(viewModel.selectedFieldIds.contains(group.id))
        XCTAssertTrue(viewModel.selectableFields[0].isSelected)
    }
    
    // MARK: - Clear Selection Tests
    
    func testClearSelection() async {
        // Given
        let field1 = try! CustomField(threadId: threadId, name: "Mood", order: 1)
        let field2 = try! CustomField(threadId: threadId, name: "Energy", order: 2)
        mockRepository.customFields = [field1, field2]
        await viewModel.loadFields()
        
        viewModel.toggleField(field1.id)
        viewModel.toggleField(field2.id)
        
        // When
        viewModel.clearSelection()
        
        // Then
        XCTAssertTrue(viewModel.selectedFieldIds.isEmpty)
        XCTAssertFalse(viewModel.hasSelectedFields)
        XCTAssertTrue(viewModel.selectedFields.isEmpty)
        XCTAssertFalse(viewModel.selectableFields[0].isSelected)
        XCTAssertFalse(viewModel.selectableFields[1].isSelected)
    }
    
    // MARK: - Restore Selection Tests
    
    func testRestoreSelection() async {
        // Given
        let field1 = try! CustomField(threadId: threadId, name: "Mood", order: 1)
        let field2 = try! CustomField(threadId: threadId, name: "Energy", order: 2)
        let field3 = try! CustomField(threadId: threadId, name: "Sleep", order: 3)
        mockRepository.customFields = [field1, field2, field3]
        await viewModel.loadFields()
        
        // When
        let previousSelection: Set<UUID> = [field1.id, field3.id]
        viewModel.restoreSelection(fieldIds: previousSelection)
        
        // Then
        XCTAssertEqual(viewModel.selectedFieldIds.count, 2)
        XCTAssertTrue(viewModel.selectedFieldIds.contains(field1.id))
        XCTAssertTrue(viewModel.selectedFieldIds.contains(field3.id))
        XCTAssertFalse(viewModel.selectedFieldIds.contains(field2.id))
        XCTAssertTrue(viewModel.selectableFields[0].isSelected)
        XCTAssertFalse(viewModel.selectableFields[1].isSelected)
        XCTAssertTrue(viewModel.selectableFields[2].isSelected)
    }
    
    func testRestoreSelectionWithInvalidIds() async {
        // Given
        let field = try! CustomField(threadId: threadId, name: "Mood", order: 1)
        mockRepository.customFields = [field]
        await viewModel.loadFields()
        
        // When
        let previousSelection: Set<UUID> = [field.id, UUID()] // One valid, one invalid
        viewModel.restoreSelection(fieldIds: previousSelection)
        
        // Then
        XCTAssertEqual(viewModel.selectedFieldIds.count, 1)
        XCTAssertTrue(viewModel.selectedFieldIds.contains(field.id))
    }
    
    // MARK: - Selected Fields Tests
    
    func testSelectedFieldsComputed() async {
        // Given
        let field1 = try! CustomField(threadId: threadId, name: "Mood", order: 1)
        let field2 = try! CustomField(threadId: threadId, name: "Energy", order: 2)
        let field3 = try! CustomField(threadId: threadId, name: "Sleep", order: 3)
        mockRepository.customFields = [field1, field2, field3]
        await viewModel.loadFields()
        
        // When
        viewModel.toggleField(field1.id)
        viewModel.toggleField(field3.id)
        
        // Then
        let selected = viewModel.selectedFields
        XCTAssertEqual(selected.count, 2)
        XCTAssertTrue(selected.contains { $0.id == field1.id })
        XCTAssertTrue(selected.contains { $0.id == field3.id })
    }
    
    // MARK: - Edge Cases
    
    func testToggleNonExistentField() async {
        // Given
        let field = try! CustomField(threadId: threadId, name: "Mood", order: 1)
        mockRepository.customFields = [field]
        await viewModel.loadFields()
        
        // When - Try to toggle non-existent field
        let nonExistentId = UUID()
        viewModel.toggleField(nonExistentId)
        
        // Then - Nothing should change
        XCTAssertTrue(viewModel.selectedFieldIds.isEmpty)
        XCTAssertFalse(viewModel.hasSelectedFields)
    }
    
    func testSelectNonExistentGroup() async {
        // Given
        let field = try! CustomField(threadId: threadId, name: "Mood", order: 1)
        mockRepository.customFields = [field]
        await viewModel.loadFields()
        
        // When
        viewModel.selectGroup(UUID())
        
        // Then - Nothing should change
        XCTAssertTrue(viewModel.selectedFieldIds.isEmpty)
    }
}