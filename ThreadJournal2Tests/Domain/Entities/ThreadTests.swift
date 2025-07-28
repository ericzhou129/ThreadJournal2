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
    
    // MARK: - Soft Delete Tests
    
    func testThreadCreationWithNilDeletedAt() throws {
        // Given
        let title = "Active Thread"
        
        // When
        let thread = try Thread(title: title)
        
        // Then
        XCTAssertNil(thread.deletedAt)
        XCTAssertFalse(thread.isDeleted)
    }
    
    func testThreadCreationWithDeletedAt() throws {
        // Given
        let title = "Deleted Thread"
        let deletedAt = Date()
        
        // When
        let thread = try Thread(
            title: title,
            deletedAt: deletedAt
        )
        
        // Then
        XCTAssertEqual(thread.deletedAt, deletedAt)
        XCTAssertTrue(thread.isDeleted)
    }
    
    func testIsDeletedReturnsTrueWhenDeletedAtIsSet() throws {
        // Given
        let thread = try Thread(
            title: "Test Thread",
            deletedAt: Date()
        )
        
        // When/Then
        XCTAssertTrue(thread.isDeleted)
    }
    
    func testIsDeletedReturnsFalseWhenDeletedAtIsNil() throws {
        // Given
        let thread = try Thread(title: "Test Thread")
        
        // When/Then
        XCTAssertFalse(thread.isDeleted)
    }
    
    func testThreadCodableConformance() throws {
        // Given
        let originalThread = try Thread(
            title: "Codable Thread",
            deletedAt: Date()
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalThread)
        
        let decoder = JSONDecoder()
        let decodedThread = try decoder.decode(Thread.self, from: data)
        
        // Then
        XCTAssertEqual(decodedThread.id, originalThread.id)
        XCTAssertEqual(decodedThread.title, originalThread.title)
        XCTAssertEqual(decodedThread.createdAt.timeIntervalSince1970, 
                      originalThread.createdAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(decodedThread.updatedAt.timeIntervalSince1970, 
                      originalThread.updatedAt.timeIntervalSince1970, accuracy: 0.001)
        if let decodedDeletedAt = decodedThread.deletedAt, 
           let originalDeletedAt = originalThread.deletedAt {
            XCTAssertEqual(decodedDeletedAt.timeIntervalSince1970, 
                          originalDeletedAt.timeIntervalSince1970, accuracy: 0.001)
        }
    }
    
    func testThreadCodableWithNilDeletedAt() throws {
        // Given
        let originalThread = try Thread(title: "Active Thread")
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalThread)
        
        let decoder = JSONDecoder()
        let decodedThread = try decoder.decode(Thread.self, from: data)
        
        // Then
        XCTAssertNil(decodedThread.deletedAt)
        XCTAssertFalse(decodedThread.isDeleted)
    }
}