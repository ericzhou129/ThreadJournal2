//
//  ThreadTests.swift
//  ThreadJournal2Tests
//
//  Tests for Thread entity validation
//

import XCTest
@testable import ThreadJournal2

final class ThreadTests: XCTestCase {
    
    func testThreadCreationWithValidTitle() throws {
        // Given
        let title = "My Journal Thread"
        
        // When
        let thread = try Thread(title: title)
        
        // Then
        XCTAssertEqual(thread.title, title)
        XCTAssertNotNil(thread.id)
        XCTAssertNotNil(thread.createdAt)
        XCTAssertNotNil(thread.updatedAt)
    }
    
    func testThreadCreationWithEmptyTitleThrows() {
        // Given
        let emptyTitle = ""
        
        // When/Then
        XCTAssertThrowsError(try Thread(title: emptyTitle)) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.emptyTitle)
        }
    }
    
    func testThreadCreationWithWhitespaceOnlyTitleThrows() {
        // Given
        let whitespaceTitle = "   \n\t   "
        
        // When/Then
        XCTAssertThrowsError(try Thread(title: whitespaceTitle)) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.emptyTitle)
        }
    }
    
    func testThreadCreationWithCustomDates() throws {
        // Given
        let title = "Test Thread"
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)
        let customId = UUID()
        
        // When
        let thread = try Thread(
            id: customId,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        
        // Then
        XCTAssertEqual(thread.id, customId)
        XCTAssertEqual(thread.title, title)
        XCTAssertEqual(thread.createdAt, createdAt)
        XCTAssertEqual(thread.updatedAt, updatedAt)
    }
}