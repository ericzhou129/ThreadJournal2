//
//  CoreDataIntegrationTests.swift
//  ThreadJournal2Tests
//
//  Integration tests for custom fields with entries
//

import XCTest
import CoreData
@testable import ThreadJournal2

final class CoreDataIntegrationTests: XCTestCase {
    private var persistentContainer: NSPersistentContainer!
    private var threadRepository: CoreDataThreadRepository!
    private var entryRepository: CoreDataEntryRepository!
    
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
        
        threadRepository = CoreDataThreadRepository(persistentContainer: persistentContainer)
        entryRepository = CoreDataEntryRepository(persistentContainer: persistentContainer)
    }
    
    override func tearDown() {
        persistentContainer = nil
        threadRepository = nil
        entryRepository = nil
        super.tearDown()
    }
    
    func testFullCustomFieldWorkflow() async throws {
        // 1. Create a thread
        let thread = try ThreadJournal2.Thread(id: UUID(), title: "Health Journal")
        try await threadRepository.create(thread: thread)
        
        // 2. Create custom fields
        let moodField = try CustomField(
            threadId: thread.id,
            name: "Mood",
            order: 1
        )
        let energyField = try CustomField(
            threadId: thread.id,
            name: "Energy Level",
            order: 2
        )
        
        try await threadRepository.createCustomField(moodField)
        try await threadRepository.createCustomField(energyField)
        
        // 3. Create an entry
        let entry = try Entry(
            id: UUID(),
            threadId: thread.id,
            content: "Today was a good day!"
        )
        try await threadRepository.addEntry(entry, to: thread.id)
        
        // 4. Add field values to the entry
        let fieldValues = [
            EntryFieldValue(fieldId: moodField.id, value: "Happy"),
            EntryFieldValue(fieldId: energyField.id, value: "8/10")
        ]
        try await entryRepository.saveFieldValues(for: entry.id, fieldValues: fieldValues)
        
        // 5. Verify we can fetch everything
        let fetchedFields = try await threadRepository.fetchCustomFields(
            for: thread.id,
            includeDeleted: false
        )
        XCTAssertEqual(fetchedFields.count, 2)
        
        let fetchedValues = try await entryRepository.fetchFieldValues(for: entry.id)
        XCTAssertEqual(fetchedValues.count, 2)
        
        // 6. Test querying entries by field value
        let happyEntries = try await entryRepository.fetchEntriesWithField(
            fieldId: moodField.id,
            value: "Happy",
            in: thread.id
        )
        XCTAssertEqual(happyEntries.count, 1)
        XCTAssertEqual(happyEntries.first?.id, entry.id)
    }
    
    func testFieldGroupIntegration() async throws {
        // Create thread
        let thread = try ThreadJournal2.Thread(id: UUID(), title: "Wellness")
        try await threadRepository.create(thread: thread)
        
        // Create fields for group
        let healthGroup = try CustomField(
            threadId: thread.id,
            name: "Health Metrics",
            order: 1
        )
        let bpField = try CustomField(
            threadId: thread.id,
            name: "Blood Pressure",
            order: 2
        )
        let hrField = try CustomField(
            threadId: thread.id,
            name: "Heart Rate",
            order: 3
        )
        
        try await threadRepository.createCustomField(healthGroup)
        try await threadRepository.createCustomField(bpField)
        try await threadRepository.createCustomField(hrField)
        
        // Create group relationship
        try await threadRepository.createFieldGroup(
            parentFieldId: healthGroup.id,
            childFieldIds: [bpField.id, hrField.id]
        )
        
        // Verify parent is marked as group
        let fields = try await threadRepository.fetchCustomFields(
            for: thread.id,
            includeDeleted: false
        )
        let parent = fields.first { $0.id == healthGroup.id }
        XCTAssertTrue(parent?.isGroup ?? false)
    }
}