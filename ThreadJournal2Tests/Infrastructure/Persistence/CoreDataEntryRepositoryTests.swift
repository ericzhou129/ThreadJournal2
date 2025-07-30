//
//  CoreDataEntryRepositoryTests.swift
//  ThreadJournal2Tests
//
//  Tests for Core Data entry repository field value operations
//

import XCTest
import CoreData
@testable import ThreadJournal2

final class CoreDataEntryRepositoryTests: XCTestCase {
    private var persistentContainer: NSPersistentContainer!
    private var threadRepository: CoreDataThreadRepository!
    private var entryRepository: CoreDataEntryRepository!
    private var testThread: ThreadJournal2.Thread!
    private var testEntry: Entry!
    
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
        
        // Create test data
        testThread = try ThreadJournal2.Thread(id: UUID(), title: "Test Thread")
        try await threadRepository.create(thread: testThread)
        
        testEntry = try Entry(
            id: UUID(),
            threadId: testThread.id,
            content: "Test entry"
        )
        try await threadRepository.addEntry(testEntry, to: testThread.id)
    }
    
    override func tearDown() {
        persistentContainer = nil
        threadRepository = nil
        entryRepository = nil
        testThread = nil
        testEntry = nil
        super.tearDown()
    }
    
    // MARK: - Save Field Values Tests
    
    func testSaveFieldValues() async throws {
        // Given
        let fieldValues = [
            EntryFieldValue(fieldId: UUID(), value: "Happy"),
            EntryFieldValue(fieldId: UUID(), value: "8/10")
        ]
        
        // When
        try await entryRepository.saveFieldValues(for: testEntry.id, fieldValues: fieldValues)
        
        // Then
        let savedValues = try await entryRepository.fetchFieldValues(for: testEntry.id)
        XCTAssertEqual(savedValues.count, 2)
        XCTAssertTrue(savedValues.contains { $0.value == "Happy" })
        XCTAssertTrue(savedValues.contains { $0.value == "8/10" })
    }
    
    func testSaveFieldValuesReplacesExisting() async throws {
        // Given
        let initialValues = [
            EntryFieldValue(fieldId: UUID(), value: "Initial")
        ]
        try await entryRepository.saveFieldValues(for: testEntry.id, fieldValues: initialValues)
        
        // When
        let newValues = [
            EntryFieldValue(fieldId: UUID(), value: "Updated"),
            EntryFieldValue(fieldId: UUID(), value: "New")
        ]
        try await entryRepository.saveFieldValues(for: testEntry.id, fieldValues: newValues)
        
        // Then
        let savedValues = try await entryRepository.fetchFieldValues(for: testEntry.id)
        XCTAssertEqual(savedValues.count, 2)
        XCTAssertFalse(savedValues.contains { $0.value == "Initial" })
        XCTAssertTrue(savedValues.contains { $0.value == "Updated" })
        XCTAssertTrue(savedValues.contains { $0.value == "New" })
    }
    
    // MARK: - Fetch Field Values Tests
    
    func testFetchFieldValuesForEntryWithNoValues() async throws {
        // When
        let values = try await entryRepository.fetchFieldValues(for: testEntry.id)
        
        // Then
        XCTAssertEqual(values.count, 0)
    }
    
    // MARK: - Remove Field Value Tests
    
    func testRemoveSpecificFieldValue() async throws {
        // Given
        let fieldId1 = UUID()
        let fieldId2 = UUID()
        let fieldValues = [
            EntryFieldValue(fieldId: fieldId1, value: "Value 1"),
            EntryFieldValue(fieldId: fieldId2, value: "Value 2")
        ]
        try await entryRepository.saveFieldValues(for: testEntry.id, fieldValues: fieldValues)
        
        // When
        try await entryRepository.removeFieldValue(from: testEntry.id, fieldId: fieldId1)
        
        // Then
        let remainingValues = try await entryRepository.fetchFieldValues(for: testEntry.id)
        XCTAssertEqual(remainingValues.count, 1)
        XCTAssertEqual(remainingValues.first?.fieldId, fieldId2)
        XCTAssertEqual(remainingValues.first?.value, "Value 2")
    }
    
    // MARK: - Fetch Entries With Field Tests
    
    func testFetchEntriesWithSpecificFieldValue() async throws {
        // Given
        let fieldId = UUID()
        let entry2 = try Entry(
            id: UUID(),
            threadId: testThread.id,
            content: "Second entry"
        )
        try await threadRepository.addEntry(entry2, to: testThread.id)
        
        // Add field values
        try await entryRepository.saveFieldValues(
            for: testEntry.id,
            fieldValues: [EntryFieldValue(fieldId: fieldId, value: "Happy")]
        )
        try await entryRepository.saveFieldValues(
            for: entry2.id,
            fieldValues: [EntryFieldValue(fieldId: fieldId, value: "Sad")]
        )
        
        // When
        let happyEntries = try await entryRepository.fetchEntriesWithField(
            fieldId: fieldId,
            value: "Happy",
            in: nil
        )
        
        // Then
        XCTAssertEqual(happyEntries.count, 1)
        XCTAssertEqual(happyEntries.first?.id, testEntry.id)
    }
    
    func testFetchEntriesWithFieldAnyValue() async throws {
        // Given
        let fieldId = UUID()
        let entry2 = try Entry(
            id: UUID(),
            threadId: testThread.id,
            content: "Second entry"
        )
        try await threadRepository.addEntry(entry2, to: testThread.id)
        
        // Add field value to only one entry
        try await entryRepository.saveFieldValues(
            for: testEntry.id,
            fieldValues: [EntryFieldValue(fieldId: fieldId, value: "Any value")]
        )
        
        // When
        let entriesWithField = try await entryRepository.fetchEntriesWithField(
            fieldId: fieldId,
            value: nil,
            in: nil
        )
        
        // Then
        XCTAssertEqual(entriesWithField.count, 1)
        XCTAssertEqual(entriesWithField.first?.id, testEntry.id)
    }
    
    func testFetchEntriesWithFieldInSpecificThread() async throws {
        // Given
        let fieldId = UUID()
        let otherThread = try ThreadJournal2.Thread(id: UUID(), title: "Other Thread")
        try await threadRepository.create(thread: otherThread)
        
        let otherEntry = try Entry(
            id: UUID(),
            threadId: otherThread.id,
            content: "Other thread entry"
        )
        try await threadRepository.addEntry(otherEntry, to: otherThread.id)
        
        // Add same field to entries in different threads
        try await entryRepository.saveFieldValues(
            for: testEntry.id,
            fieldValues: [EntryFieldValue(fieldId: fieldId, value: "Value")]
        )
        try await entryRepository.saveFieldValues(
            for: otherEntry.id,
            fieldValues: [EntryFieldValue(fieldId: fieldId, value: "Value")]
        )
        
        // When
        let threadSpecificEntries = try await entryRepository.fetchEntriesWithField(
            fieldId: fieldId,
            value: nil,
            in: testThread.id
        )
        
        // Then
        XCTAssertEqual(threadSpecificEntries.count, 1)
        XCTAssertEqual(threadSpecificEntries.first?.threadId, testThread.id)
    }
    
    func testRemoveFieldValueThatDoesNotExist() async throws {
        // Given - entry with no field values
        
        // When - attempt to remove non-existent field value
        try await entryRepository.removeFieldValue(from: testEntry.id, fieldId: UUID())
        
        // Then - should not throw error
        let values = try await entryRepository.fetchFieldValues(for: testEntry.id)
        XCTAssertEqual(values.count, 0)
    }
    
    func testSaveEmptyFieldValues() async throws {
        // Given
        let fieldValues: [EntryFieldValue] = []
        
        // When
        try await entryRepository.saveFieldValues(for: testEntry.id, fieldValues: fieldValues)
        
        // Then
        let savedValues = try await entryRepository.fetchFieldValues(for: testEntry.id)
        XCTAssertEqual(savedValues.count, 0)
    }
    
    func testFetchEntriesWithFieldNoMatches() async throws {
        // Given
        let fieldId = UUID()
        
        // When - search for field that no entry has
        let entries = try await entryRepository.fetchEntriesWithField(
            fieldId: fieldId,
            value: nil,
            in: nil
        )
        
        // Then
        XCTAssertEqual(entries.count, 0)
    }
    
    func testFetchEntriesWithFieldValueNoMatches() async throws {
        // Given
        let fieldId = UUID()
        try await entryRepository.saveFieldValues(
            for: testEntry.id,
            fieldValues: [EntryFieldValue(fieldId: fieldId, value: "Happy")]
        )
        
        // When - search for different value
        let entries = try await entryRepository.fetchEntriesWithField(
            fieldId: fieldId,
            value: "Sad",
            in: nil
        )
        
        // Then
        XCTAssertEqual(entries.count, 0)
    }
}