//
//  EntryTests.swift
//  ThreadJournal2Tests
//
//  Tests for Entry entity validation
//

import XCTest
@testable import ThreadJournal2

final class EntryTests: XCTestCase {
    
    func testEntryCreationWithValidContent() throws {
        // Given
        let threadId = UUID()
        let content = "This is my journal entry"
        
        // When
        let entry = try Entry(threadId: threadId, content: content)
        
        // Then
        XCTAssertEqual(entry.content, content)
        XCTAssertEqual(entry.threadId, threadId)
        XCTAssertNotNil(entry.id)
        XCTAssertNotNil(entry.timestamp)
    }
    
    func testEntryCreationWithEmptyContentThrows() {
        // Given
        let threadId = UUID()
        let emptyContent = ""
        
        // When/Then
        XCTAssertThrowsError(try Entry(threadId: threadId, content: emptyContent)) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.emptyContent)
        }
    }
    
    func testEntryCreationWithWhitespaceOnlyContentThrows() {
        // Given
        let threadId = UUID()
        let whitespaceContent = "   \n\t   "
        
        // When/Then
        XCTAssertThrowsError(try Entry(threadId: threadId, content: whitespaceContent)) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.emptyContent)
        }
    }
    
    func testEntryCreationWithCustomValues() throws {
        // Given
        let customId = UUID()
        let threadId = UUID()
        let content = "Custom entry"
        let timestamp = Date(timeIntervalSince1970: 3000)
        
        // When
        let entry = try Entry(
            id: customId,
            threadId: threadId,
            content: content,
            timestamp: timestamp
        )
        
        // Then
        XCTAssertEqual(entry.id, customId)
        XCTAssertEqual(entry.threadId, threadId)
        XCTAssertEqual(entry.content, content)
        XCTAssertEqual(entry.timestamp, timestamp)
        XCTAssertEqual(entry.customFieldValues, [])
    }
    
    func testEntryCreationWithCustomFieldValues() throws {
        // Given
        let threadId = UUID()
        let fieldValues = [
            EntryFieldValue(fieldId: UUID(), value: "Happy"),
            EntryFieldValue(fieldId: UUID(), value: "8/10")
        ]
        
        // When
        let entry = try Entry(
            threadId: threadId,
            content: "Entry with custom fields",
            customFieldValues: fieldValues
        )
        
        // Then
        XCTAssertEqual(entry.customFieldValues, fieldValues)
        XCTAssertEqual(entry.customFieldValues.count, 2)
    }
    
    func testEntryEqualityIncludesCustomFieldValues() throws {
        // Given
        let id = UUID()
        let threadId = UUID()
        let timestamp = Date()
        let fieldValues = [
            EntryFieldValue(fieldId: UUID(), value: "Happy")
        ]
        
        // When
        let entry1 = try Entry(
            id: id,
            threadId: threadId,
            content: "Test",
            timestamp: timestamp,
            customFieldValues: fieldValues
        )
        
        let entry2 = try Entry(
            id: id,
            threadId: threadId,
            content: "Test",
            timestamp: timestamp,
            customFieldValues: fieldValues
        )
        
        // Then
        XCTAssertEqual(entry1, entry2)
    }
}