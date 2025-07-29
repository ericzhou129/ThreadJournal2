//
//  CustomFieldTests.swift
//  ThreadJournal2Tests
//
//  Tests for CustomField domain entity
//

import XCTest
@testable import ThreadJournal2

final class CustomFieldTests: XCTestCase {
    
    func testCreateValidCustomField() throws {
        let threadId = UUID()
        let field = try CustomField(
            threadId: threadId,
            name: "Mood",
            order: 1
        )
        
        XCTAssertEqual(field.name, "Mood")
        XCTAssertEqual(field.threadId, threadId)
        XCTAssertEqual(field.order, 1)
        XCTAssertFalse(field.isGroup)
    }
    
    func testCreateCustomFieldGroup() throws {
        let field = try CustomField(
            threadId: UUID(),
            name: "ADHD Check-in",
            order: 1,
            isGroup: true
        )
        
        XCTAssertTrue(field.isGroup)
    }
    
    func testTrimsWhitespace() throws {
        let field = try CustomField(
            threadId: UUID(),
            name: "  Mood  \n",
            order: 1
        )
        
        XCTAssertEqual(field.name, "Mood")
    }
    
    func testEmptyNameThrows() {
        XCTAssertThrowsError(
            try CustomField(threadId: UUID(), name: "", order: 1)
        ) { error in
            XCTAssertEqual(error as? ValidationError, .emptyFieldName)
        }
        
        XCTAssertThrowsError(
            try CustomField(threadId: UUID(), name: "   ", order: 1)
        ) { error in
            XCTAssertEqual(error as? ValidationError, .emptyFieldName)
        }
    }
    
    func testNameTooLongThrows() {
        let longName = String(repeating: "a", count: 51)
        
        XCTAssertThrowsError(
            try CustomField(threadId: UUID(), name: longName, order: 1)
        ) { error in
            XCTAssertEqual(error as? ValidationError, .fieldNameTooLong)
        }
    }
    
    func testMaxLengthName() throws {
        let maxName = String(repeating: "a", count: 50)
        let field = try CustomField(threadId: UUID(), name: maxName, order: 1)
        
        XCTAssertEqual(field.name.count, 50)
    }
    
    func testEquality() throws {
        let id = UUID()
        let threadId = UUID()
        
        let field1 = try CustomField(
            id: id,
            threadId: threadId,
            name: "Mood",
            order: 1
        )
        
        let field2 = try CustomField(
            id: id,
            threadId: threadId,
            name: "Mood",
            order: 1
        )
        
        XCTAssertEqual(field1, field2)
    }
    
    func testInequalityDifferentId() throws {
        let threadId = UUID()
        
        let field1 = try CustomField(
            threadId: threadId,
            name: "Mood",
            order: 1
        )
        
        let field2 = try CustomField(
            threadId: threadId,
            name: "Mood",
            order: 1
        )
        
        XCTAssertNotEqual(field1, field2)
    }
}