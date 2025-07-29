//
//  EntryFieldValueTests.swift
//  ThreadJournal2Tests
//
//  Tests for EntryFieldValue domain entity
//

import XCTest
@testable import ThreadJournal2

final class EntryFieldValueTests: XCTestCase {
    
    func testCreateFieldValue() {
        let fieldId = UUID()
        let fieldValue = EntryFieldValue(
            fieldId: fieldId,
            value: "Happy"
        )
        
        XCTAssertEqual(fieldValue.fieldId, fieldId)
        XCTAssertEqual(fieldValue.value, "Happy")
    }
    
    func testTrimsWhitespace() {
        let fieldValue = EntryFieldValue(
            fieldId: UUID(),
            value: "  Happy  \n"
        )
        
        XCTAssertEqual(fieldValue.value, "Happy")
    }
    
    func testEmptyValueAllowed() {
        let fieldValue = EntryFieldValue(
            fieldId: UUID(),
            value: ""
        )
        
        XCTAssertEqual(fieldValue.value, "")
    }
    
    func testWhitespaceOnlyBecomesEmpty() {
        let fieldValue = EntryFieldValue(
            fieldId: UUID(),
            value: "   \n\t"
        )
        
        XCTAssertEqual(fieldValue.value, "")
    }
    
    func testEquality() {
        let fieldId = UUID()
        
        let value1 = EntryFieldValue(fieldId: fieldId, value: "Happy")
        let value2 = EntryFieldValue(fieldId: fieldId, value: "Happy")
        
        XCTAssertEqual(value1, value2)
    }
    
    func testInequalityDifferentFieldId() {
        let value1 = EntryFieldValue(fieldId: UUID(), value: "Happy")
        let value2 = EntryFieldValue(fieldId: UUID(), value: "Happy")
        
        XCTAssertNotEqual(value1, value2)
    }
    
    func testInequalityDifferentValue() {
        let fieldId = UUID()
        
        let value1 = EntryFieldValue(fieldId: fieldId, value: "Happy")
        let value2 = EntryFieldValue(fieldId: fieldId, value: "Sad")
        
        XCTAssertNotEqual(value1, value2)
    }
}