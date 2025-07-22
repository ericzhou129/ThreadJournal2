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
        let result = sut.export(thread: thread, entries: entries)
        
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
        let result = sut.export(thread: thread, entries: entries)
        
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
        let result = sut.export(thread: thread, entries: entries)
        
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
        let result = sut.export(thread: thread, entries: entries)
        
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
        let result = sut.export(thread: thread, entries: [])
        
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