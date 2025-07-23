//
//  CSVExportPerformanceTests.swift
//  ThreadJournal2Tests
//
//  Performance tests for CSV export functionality
//

import XCTest
@testable import ThreadJournal2

final class CSVExportPerformanceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var repository: MockThreadRepository!
    private var exportUseCase: ExportThreadUseCase!
    private var csvExporter: CSVExporter!
    private var testThread: Thread!
    private var testEntries: [Entry]!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        // Create test data - thread with 1000 entries including special characters
        let testData = TestDataBuilder.createCSVExportTestData()
        testThread = testData.thread
        testEntries = testData.entries
        
        // Setup repository
        repository = MockThreadRepository()
        repository.threads = [testThread]
        repository.entriesByThread[testThread.id] = testEntries
        
        // Setup export components
        csvExporter = CSVExporter()
        exportUseCase = ExportThreadUseCase(
            repository: repository,
            exporter: csvExporter
        )
    }
    
    override func tearDown() {
        exportUseCase = nil
        csvExporter = nil
        repository = nil
        testThread = nil
        testEntries = nil
        
        super.tearDown()
    }
    
    // MARK: - Performance Tests
    
    func testExport1000Entries_CompletesUnder3Seconds() {
        // Given: Thread with 1000 entries
        let expectation = XCTestExpectation(description: "Export completes")
        
        measure {
            // When: Exporting to CSV
            Task {
                do {
                    let exportData = try await exportUseCase.execute(threadId: testThread.id)
                    
                    // Then: Should produce valid CSV
                    XCTAssertFalse(exportData.data.isEmpty)
                    XCTAssertTrue(exportData.filename.hasSuffix(".csv"))
                    XCTAssertEqual(exportData.mimeType, "text/csv")
                    
                    // Verify CSV content
                    if let csvString = String(data: exportData.data, encoding: .utf8) {
                        let lines = csvString.components(separatedBy: .newlines)
                        XCTAssertEqual(lines[0], "Date & Time,Entry Content")
                        XCTAssertGreaterThan(lines.count, 1000) // Header + entries
                    }
                    
                    expectation.fulfill()
                } catch {
                    XCTFail("Export failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testExportWithSpecialCharacters_HandlesEscapingWell() {
        // Given: Entries with quotes, commas, and newlines
        let specialEntries = [
            "Simple entry",
            "Entry with \"quotes\" inside",
            "Entry with, comma",
            "Entry with\nnewline",
            "Entry with \"quotes\", comma, and\nnewline",
            "Entry with unicode: 🎉 ñ € → ∞"
        ].enumerated().map { index, content in
            try! Entry(
                id: UUID(),
                threadId: testThread.id,
                content: content,
                timestamp: Date().addingTimeInterval(TimeInterval(-index * 60))
            )
        }
        
        repository.entriesByThread[testThread.id] = specialEntries
        let expectation = XCTestExpectation(description: "Special export completes")
        
        measure {
            // When: Exporting entries with special characters
            Task {
                do {
                    let exportData = try await exportUseCase.execute(threadId: testThread.id)
                    
                    // Then: CSV should be properly escaped
                    if let csvString = String(data: exportData.data, encoding: .utf8) {
                        XCTAssertTrue(csvString.contains("\"Entry with \"\"quotes\"\" inside\""))
                        XCTAssertTrue(csvString.contains("\"Entry with, comma\""))
                        XCTAssertTrue(csvString.contains("\"Entry with\\nnewline\""))
                    }
                    
                    expectation.fulfill()
                } catch {
                    XCTFail("Special export failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    func testExportLargeEntries_HandlesMemoryWell() {
        // Given: Entries with very long content
        let largeEntries = (0..<100).map { index in
            let content = String(repeating: "This is a very long journal entry. ", count: 100)
            return try! Entry(
                id: UUID(),
                threadId: testThread.id,
                content: content + "Entry #\(index)",
                timestamp: Date()
            )
        }
        
        repository.entriesByThread[testThread.id] = largeEntries
        let expectation = XCTestExpectation(description: "Large export completes")
        
        measure {
            // When: Exporting large entries
            Task {
                do {
                    let exportData = try await exportUseCase.execute(threadId: testThread.id)
                    
                    // Then: Should handle large data
                    let dataSizeMB = Double(exportData.data.count) / 1024.0 / 1024.0
                    XCTAssertLessThan(dataSizeMB, 10.0, "Export size too large")
                    
                    expectation.fulfill()
                } catch {
                    XCTFail("Large export failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    func testFilenameGeneration_Performance() {
        // Given: Thread titles that need sanitization
        let testTitles = [
            "Normal Thread",
            "Thread/With/Slashes",
            "Thread:With:Colons",
            "Thread With Spaces",
            "Thread_With-Special.Characters!@#$%",
            "Very Long Thread Title That Exceeds Normal Length Limits And Should Be Truncated"
        ]
        
        measure {
            // When: Generating filenames
            for title in testTitles {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd_HHmm"
                let timestamp = dateFormatter.string(from: Date())
                
                let sanitized = title
                    .replacingOccurrences(of: "/", with: "-")
                    .replacingOccurrences(of: ":", with: "-")
                    .replacingOccurrences(of: "\\", with: "-")
                    .replacingOccurrences(of: "*", with: "-")
                    .replacingOccurrences(of: "?", with: "-")
                    .replacingOccurrences(of: "\"", with: "-")
                    .replacingOccurrences(of: "<", with: "-")
                    .replacingOccurrences(of: ">", with: "-")
                    .replacingOccurrences(of: "|", with: "-")
                
                let filename = "\(sanitized)_\(timestamp).csv"
                
                // Then: Filename should be valid
                XCTAssertFalse(filename.isEmpty)
                XCTAssertLessThan(filename.count, 255) // Filesystem limit
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testExportMemoryUsage_With1000Entries_StaysReasonable() {
        // Given: Initial memory state
        let initialMemory = getCurrentMemoryUsage()
        
        // When: Exporting 1000 entries
        let expectation = XCTestExpectation(description: "Export completes")
        
        Task {
            do {
                _ = try await exportUseCase.execute(threadId: testThread.id)
                expectation.fulfill()
            } catch {
                XCTFail("Export failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Then: Memory increase should be reasonable
        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        let memoryIncreaseMB = Double(memoryIncrease) / 1024.0 / 1024.0
        
        // CSV for 1000 entries should be ~250KB, allow for processing overhead
        XCTAssertLessThan(memoryIncreaseMB, 10.0, "Memory usage exceeded 10MB for export")
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}