//
//  CSVExporterTests.swift
//  ThreadJournal2Tests
//
//  Tests for CSVExporter
//

import XCTest
@testable import ThreadJournal2

final class CSVExporterTests: XCTestCase {
    
    private var sut: CSVExporter!
    
    override func setUp() {
        super.setUp()
        sut = CSVExporter()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testExport_WithBasicEntries_GeneratesCorrectCSV() throws {
        // Given
        let thread = try Thread(
            id: UUID(),
            title: "Test Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let date1 = createDate(year: 2024, month: 1, day: 15, hour: 10, minute: 30)
        let date2 = createDate(year: 2024, month: 1, day: 15, hour: 14, minute: 45)
        
        let entries = [
            try Entry(id: UUID(), threadId: thread.id, content: "Started my journal today", timestamp: date1),
            try Entry(id: UUID(), threadId: thread.id, content: "Another entry", timestamp: date2)
        ]
        
        // When
        let result = sut.export(thread: thread, entries: entries, customFields: [], fieldGroups: [])
        
        // Then
        XCTAssertTrue(result.fileName.contains("Test Thread"))
        XCTAssertTrue(result.fileName.hasSuffix(".csv"))
        XCTAssertEqual(result.mimeType, "text/csv")
        
        let csvString = String(data: result.data, encoding: .utf8)!
        XCTAssertTrue(csvString.contains("\"Date & Time\",\"Entry Content\""))
        XCTAssertTrue(csvString.contains("\"2024-01-15 10:30\",\"Started my journal today\""))
        XCTAssertTrue(csvString.contains("\"2024-01-15 14:45\",\"Another entry\""))
    }
    
    func testExport_WithSpecialCharacters_EscapesCorrectly() throws {
        // Given
        let thread = try Thread(
            id: UUID(),
            title: "Test/Thread:With*Special<>Characters?",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let entries = [
            try Entry(
                id: UUID(),
                threadId: thread.id,
                content: "Had a thought with a comma, here",
                timestamp: Date()
            ),
            try Entry(
                id: UUID(),
                threadId: thread.id,
                content: "Quote test: She said \"Hello\" to me",
                timestamp: Date()
            )
        ]
        
        // When
        let result = sut.export(thread: thread, entries: entries, customFields: [], fieldGroups: [])
        
        // Then
        // Check filename sanitization
        XCTAssertFalse(result.fileName.contains("/"))
        XCTAssertFalse(result.fileName.contains(":"))
        XCTAssertFalse(result.fileName.contains("*"))
        XCTAssertFalse(result.fileName.contains("<"))
        XCTAssertFalse(result.fileName.contains(">"))
        XCTAssertFalse(result.fileName.contains("?"))
        
        // Check CSV content escaping
        let csvString = String(data: result.data, encoding: .utf8)!
        XCTAssertTrue(csvString.contains("\"Had a thought with a comma, here\""))
        XCTAssertTrue(csvString.contains("\"Quote test: She said \"\"Hello\"\" to me\""))
    }
    
    func testExport_WithEmptyEntries_GeneratesHeaderOnly() throws {
        // Given
        let thread = try Thread(
            id: UUID(),
            title: "Empty Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        let entries: [Entry] = []
        
        // When
        let result = sut.export(thread: thread, entries: entries, customFields: [], fieldGroups: [])
        
        // Then
        let csvString = String(data: result.data, encoding: .utf8)!
        XCTAssertEqual(csvString, "\"Date & Time\",\"Entry Content\"\n")
    }
    
    func testExport_WithNewlinesInContent_HandlesCorrectly() throws {
        // Given
        let thread = try Thread(
            id: UUID(),
            title: "Test Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let entries = [
            try Entry(
                id: UUID(),
                threadId: thread.id,
                content: "First line\nSecond line\nThird line",
                timestamp: Date()
            )
        ]
        
        // When
        let result = sut.export(thread: thread, entries: entries, customFields: [], fieldGroups: [])
        
        // Then
        let csvString = String(data: result.data, encoding: .utf8)!
        XCTAssertTrue(csvString.contains("\"First line\nSecond line\nThird line\""))
    }
    
    func testFilename_GeneratedWithCorrectFormat() throws {
        // Given
        let thread = try Thread(
            id: UUID(),
            title: "My Journal",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When
        let result = sut.export(thread: thread, entries: [], customFields: [], fieldGroups: [])
        
        // Then
        let regex = try NSRegularExpression(
            pattern: "My Journal_\\d{8}_\\d{4}\\.csv",
            options: []
        )
        let matches = regex.matches(
            in: result.fileName,
            options: [],
            range: NSRange(location: 0, length: result.fileName.count)
        )
        XCTAssertEqual(matches.count, 1, "Filename should match pattern: ThreadName_YYYYMMDD_HHMM.csv")
    }
    
    // MARK: - Custom Fields Tests
    
    func testExport_WithCustomFields_IncludesFieldColumns() throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread", createdAt: Date(), updatedAt: Date())
        
        let fieldId1 = UUID()
        let fieldId2 = UUID()
        let customFields = [
            try CustomField(id: fieldId1, threadId: thread.id, name: "Priority", order: 1),
            try CustomField(id: fieldId2, threadId: thread.id, name: "Category", order: 2)
        ]
        
        let entries = [
            try Entry(
                id: UUID(),
                threadId: thread.id,
                content: "First entry",
                timestamp: Date(),
                customFieldValues: [
                    EntryFieldValue(fieldId: fieldId1, value: "High"),
                    EntryFieldValue(fieldId: fieldId2, value: "Work")
                ]
            ),
            try Entry(
                id: UUID(),
                threadId: thread.id,
                content: "Second entry",
                timestamp: Date(),
                customFieldValues: [
                    EntryFieldValue(fieldId: fieldId1, value: "Low")
                ]
            )
        ]
        
        // When
        let result = sut.export(thread: thread, entries: entries, customFields: customFields, fieldGroups: [])
        
        // Then
        let csvString = String(data: result.data, encoding: .utf8)!
        XCTAssertTrue(csvString.contains("\"Date & Time\",\"Entry Content\",\"Priority\",\"Category\""))
        XCTAssertTrue(csvString.contains("\"High\",\"Work\""))
        XCTAssertTrue(csvString.contains("\"Low\",\"\"")) // Empty for missing field value
    }
    
    func testExport_WithGroupFields_FormatsAsGroupDotField() throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread", createdAt: Date(), updatedAt: Date())
        
        let parentId = UUID()
        let childId1 = UUID()
        let childId2 = UUID()
        
        let parentField = try CustomField(id: parentId, threadId: thread.id, name: "Personal", order: 1, isGroup: true)
        let childField1 = try CustomField(id: childId1, threadId: thread.id, name: "Mood", order: 2)
        let childField2 = try CustomField(id: childId2, threadId: thread.id, name: "Energy", order: 3)
        
        let customFields = [parentField, childField1, childField2]
        let fieldGroups = [
            try CustomFieldGroup(parentField: parentField, childFields: [childField1, childField2])
        ]
        
        let entries = [
            try Entry(
                id: UUID(),
                threadId: thread.id,
                content: "Feeling good today",
                timestamp: Date(),
                customFieldValues: [
                    EntryFieldValue(fieldId: childId1, value: "Happy"),
                    EntryFieldValue(fieldId: childId2, value: "High")
                ]
            )
        ]
        
        // When
        let result = sut.export(thread: thread, entries: entries, customFields: customFields, fieldGroups: fieldGroups)
        
        // Then
        let csvString = String(data: result.data, encoding: .utf8)!
        XCTAssertTrue(csvString.contains("\"Date & Time\",\"Entry Content\",\"Personal.Mood\",\"Personal.Energy\""))
        XCTAssertTrue(csvString.contains("\"Happy\",\"High\""))
    }
    
    func testExport_WithMixedFieldsAndGroups_OrdersCorrectly() throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread", createdAt: Date(), updatedAt: Date())
        
        let standaloneId = UUID()
        let groupParentId = UUID()
        let groupChildId = UUID()
        
        // Note: order determines column position
        let standaloneField = try CustomField(id: standaloneId, threadId: thread.id, name: "Tags", order: 1)
        let parentField = try CustomField(id: groupParentId, threadId: thread.id, name: "Health", order: 2, isGroup: true)
        let childField = try CustomField(id: groupChildId, threadId: thread.id, name: "Sleep", order: 3)
        
        let customFields = [standaloneField, parentField, childField]
        let fieldGroups = [
            try CustomFieldGroup(parentField: parentField, childFields: [childField])
        ]
        
        let entries = [
            try Entry(
                id: UUID(),
                threadId: thread.id,
                content: "Good day",
                timestamp: Date(),
                customFieldValues: [
                    EntryFieldValue(fieldId: standaloneId, value: "personal"),
                    EntryFieldValue(fieldId: groupChildId, value: "8 hours")
                ]
            )
        ]
        
        // When
        let result = sut.export(thread: thread, entries: entries, customFields: customFields, fieldGroups: fieldGroups)
        
        // Then
        let csvString = String(data: result.data, encoding: .utf8)!
        XCTAssertTrue(csvString.contains("\"Date & Time\",\"Entry Content\",\"Tags\",\"Health.Sleep\""))
        XCTAssertTrue(csvString.contains("\"personal\",\"8 hours\""))
    }
    
    func testExport_WithEmptyFieldValues_ShowsEmptyStrings() throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread", createdAt: Date(), updatedAt: Date())
        
        let fieldId = UUID()
        let customFields = [
            try CustomField(id: fieldId, threadId: thread.id, name: "Mood", order: 1)
        ]
        
        let entries = [
            try Entry(id: UUID(), threadId: thread.id, content: "Entry without field", timestamp: Date(), customFieldValues: []),
            try Entry(
                id: UUID(),
                threadId: thread.id,
                content: "Entry with field",
                timestamp: Date(),
                customFieldValues: [EntryFieldValue(fieldId: fieldId, value: "Happy")]
            )
        ]
        
        // When
        let result = sut.export(thread: thread, entries: entries, customFields: customFields, fieldGroups: [])
        
        // Then
        let csvString = String(data: result.data, encoding: .utf8)!
        let lines = csvString.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 4) // Header + 2 entries + empty line at end
        XCTAssertTrue(lines[1].contains("\"Entry without field\",\"\"")) // Empty field value
        XCTAssertTrue(lines[2].contains("\"Entry with field\",\"Happy\""))
    }
    
    func testExport_WithSpecialCharactersInFieldNames_EscapesCorrectly() throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread", createdAt: Date(), updatedAt: Date())
        
        let fieldId = UUID()
        let customFields = [
            try CustomField(id: fieldId, threadId: thread.id, name: "Field, with \"quotes\"", order: 1)
        ]
        
        let entries = [
            try Entry(
                id: UUID(),
                threadId: thread.id,
                content: "Test entry",
                timestamp: Date(),
                customFieldValues: [EntryFieldValue(fieldId: fieldId, value: "Value with, comma")]
            )
        ]
        
        // When
        let result = sut.export(thread: thread, entries: entries, customFields: customFields, fieldGroups: [])
        
        // Then
        let csvString = String(data: result.data, encoding: .utf8)!
        XCTAssertTrue(csvString.contains("\"Field, with \"\"quotes\"\"\""))
        XCTAssertTrue(csvString.contains("\"Value with, comma\""))
    }
    
    // MARK: - Helper Methods
    
    private func createDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = TimeZone.current
        
        return Calendar.current.date(from: components)!
    }
}