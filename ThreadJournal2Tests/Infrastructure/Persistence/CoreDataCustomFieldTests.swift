//
//  CoreDataCustomFieldTests.swift
//  ThreadJournal2Tests
//
//  Tests for Core Data custom field operations
//

import XCTest
import CoreData
@testable import ThreadJournal2

final class CoreDataCustomFieldTests: XCTestCase {
    private var persistentContainer: NSPersistentContainer!
    private var repository: CoreDataThreadRepository!
    private var testThread: ThreadJournal2.Thread!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data stack
        persistentContainer = NSPersistentContainer(name: "ThreadDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        await withCheckedContinuation { continuation in
            persistentContainer.loadPersistentStores { _, error in
                XCTAssertNil(error)
                continuation.resume()
            }
        }
        
        repository = CoreDataThreadRepository(persistentContainer: persistentContainer)
        
        // Create a test thread
        testThread = try ThreadJournal2.Thread(id: UUID(), title: "Test Thread")
        try await repository.create(thread: testThread)
    }
    
    override func tearDown() {
        persistentContainer = nil
        repository = nil
        testThread = nil
        super.tearDown()
    }
    
    // MARK: - Create Custom Field Tests
    
    func testCreateCustomField() async throws {
        // Given
        let field = try CustomField(
            threadId: testThread.id,
            name: "Mood",
            order: 1
        )
        
        // When
        try await repository.createCustomField(field)
        
        // Then
        let fields = try await repository.fetchCustomFields(for: testThread.id, includeDeleted: false)
        XCTAssertEqual(fields.count, 1)
        XCTAssertEqual(fields.first?.name, "Mood")
        XCTAssertEqual(fields.first?.order, 1)
        XCTAssertFalse(fields.first?.isGroup ?? true)
    }
    
    func testCreateDuplicateFieldThrows() async throws {
        // Given
        let field = try CustomField(
            threadId: testThread.id,
            name: "Mood",
            order: 1
        )
        try await repository.createCustomField(field)
        
        // When/Then
        do {
            try await repository.createCustomField(field)
            XCTFail("Should throw error for duplicate field")
        } catch {
            // Expected error
        }
    }
    
    // MARK: - Update Custom Field Tests
    
    func testUpdateCustomField() async throws {
        // Given
        let field = try CustomField(
            threadId: testThread.id,
            name: "Mood",
            order: 1
        )
        try await repository.createCustomField(field)
        
        // When
        let updatedField = try CustomField(
            id: field.id,
            threadId: field.threadId,
            name: "Energy Level",
            order: 2,
            isGroup: false
        )
        try await repository.updateCustomField(updatedField)
        
        // Then
        let fields = try await repository.fetchCustomFields(for: testThread.id, includeDeleted: false)
        XCTAssertEqual(fields.count, 1)
        XCTAssertEqual(fields.first?.name, "Energy Level")
        XCTAssertEqual(fields.first?.order, 2)
    }
    
    // MARK: - Soft Delete Tests
    
    func testSoftDeleteCustomField() async throws {
        // Given
        let field = try CustomField(
            threadId: testThread.id,
            name: "Mood",
            order: 1
        )
        try await repository.createCustomField(field)
        
        // When
        try await repository.softDeleteCustomField(fieldId: field.id)
        
        // Then
        let activeFields = try await repository.fetchCustomFields(
            for: testThread.id,
            includeDeleted: false
        )
        XCTAssertEqual(activeFields.count, 0)
        
        let allFields = try await repository.fetchCustomFields(
            for: testThread.id,
            includeDeleted: true
        )
        XCTAssertEqual(allFields.count, 1)
    }
    
    // MARK: - Field Group Tests
    
    func testCreateFieldGroup() async throws {
        // Given
        let parentField = try CustomField(
            threadId: testThread.id,
            name: "Health",
            order: 1
        )
        let childField1 = try CustomField(
            threadId: testThread.id,
            name: "Blood Pressure",
            order: 2
        )
        let childField2 = try CustomField(
            threadId: testThread.id,
            name: "Heart Rate",
            order: 3
        )
        
        try await repository.createCustomField(parentField)
        try await repository.createCustomField(childField1)
        try await repository.createCustomField(childField2)
        
        // When
        try await repository.createFieldGroup(
            parentFieldId: parentField.id,
            childFieldIds: [childField1.id, childField2.id]
        )
        
        // Then
        let fields = try await repository.fetchCustomFields(for: testThread.id, includeDeleted: false)
        let parent = fields.first { $0.id == parentField.id }
        XCTAssertTrue(parent?.isGroup ?? false)
    }
    
    func testRemoveFromGroup() async throws {
        // Given
        let parentField = try CustomField(
            threadId: testThread.id,
            name: "Health",
            order: 1
        )
        let childField = try CustomField(
            threadId: testThread.id,
            name: "Blood Pressure",
            order: 2
        )
        
        try await repository.createCustomField(parentField)
        try await repository.createCustomField(childField)
        try await repository.createFieldGroup(
            parentFieldId: parentField.id,
            childFieldIds: [childField.id]
        )
        
        // When
        try await repository.removeFromGroup(fieldId: childField.id)
        
        // Then - verify child is no longer in group
        // (Would need to extend repository to verify parent relationship is nil)
        let fields = try await repository.fetchCustomFields(for: testThread.id, includeDeleted: false)
        XCTAssertEqual(fields.count, 2)
    }
    
    // MARK: - Fetch Tests
    
    func testFetchCustomFieldsSortedByOrder() async throws {
        // Given
        let field1 = try CustomField(
            threadId: testThread.id,
            name: "Field 3",
            order: 3
        )
        let field2 = try CustomField(
            threadId: testThread.id,
            name: "Field 1",
            order: 1
        )
        let field3 = try CustomField(
            threadId: testThread.id,
            name: "Field 2",
            order: 2
        )
        
        try await repository.createCustomField(field1)
        try await repository.createCustomField(field2)
        try await repository.createCustomField(field3)
        
        // When
        let fields = try await repository.fetchCustomFields(for: testThread.id, includeDeleted: false)
        
        // Then
        XCTAssertEqual(fields.count, 3)
        XCTAssertEqual(fields[0].name, "Field 1")
        XCTAssertEqual(fields[1].name, "Field 2")
        XCTAssertEqual(fields[2].name, "Field 3")
    }
    
    func testUpdateNonExistentFieldThrows() async throws {
        // Given
        let field = try CustomField(
            id: UUID(),
            threadId: testThread.id,
            name: "NonExistent",
            order: 1
        )
        
        // When/Then
        do {
            try await repository.updateCustomField(field)
            XCTFail("Should throw not found error")
        } catch {
            // Expected error
        }
    }
    
    func testSoftDeleteNonExistentFieldThrows() async throws {
        // When/Then
        do {
            try await repository.softDeleteCustomField(fieldId: UUID())
            XCTFail("Should throw not found error")
        } catch {
            // Expected error
        }
    }
    
    func testCreateFieldGroupWithNonExistentParentThrows() async throws {
        // When/Then
        do {
            try await repository.createFieldGroup(
                parentFieldId: UUID(),
                childFieldIds: []
            )
            XCTFail("Should throw not found error")
        } catch {
            // Expected error
        }
    }
    
    func testCreateFieldGroupWithNonExistentChildThrows() async throws {
        // Given
        let parentField = try CustomField(
            threadId: testThread.id,
            name: "Parent",
            order: 1
        )
        try await repository.createCustomField(parentField)
        
        // When/Then
        do {
            try await repository.createFieldGroup(
                parentFieldId: parentField.id,
                childFieldIds: [UUID()]
            )
            XCTFail("Should throw not found error")
        } catch {
            // Expected error
        }
    }
    
    func testRemoveFromGroupNonExistentFieldThrows() async throws {
        // When/Then
        do {
            try await repository.removeFromGroup(fieldId: UUID())
            XCTFail("Should throw not found error")
        } catch {
            // Expected error
        }
    }
    
    func testFetchOnlyThreadSpecificFields() async throws {
        // Given
        let otherThread = try ThreadJournal2.Thread(id: UUID(), title: "Other Thread")
        try await repository.create(thread: otherThread)
        
        let field1 = try CustomField(
            threadId: testThread.id,
            name: "Thread 1 Field",
            order: 1
        )
        let field2 = try CustomField(
            threadId: otherThread.id,
            name: "Thread 2 Field",
            order: 1
        )
        
        try await repository.createCustomField(field1)
        try await repository.createCustomField(field2)
        
        // When
        let thread1Fields = try await repository.fetchCustomFields(
            for: testThread.id,
            includeDeleted: false
        )
        let thread2Fields = try await repository.fetchCustomFields(
            for: otherThread.id,
            includeDeleted: false
        )
        
        // Then
        XCTAssertEqual(thread1Fields.count, 1)
        XCTAssertEqual(thread1Fields.first?.name, "Thread 1 Field")
        XCTAssertEqual(thread2Fields.count, 1)
        XCTAssertEqual(thread2Fields.first?.name, "Thread 2 Field")
    }
}