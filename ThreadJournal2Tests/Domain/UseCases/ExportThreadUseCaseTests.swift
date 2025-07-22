//
//  ExportThreadUseCaseTests.swift
//  ThreadJournal2Tests
//
//  Tests for ExportThreadUseCase
//

import XCTest
@testable import ThreadJournal2

final class ExportThreadUseCaseTests: XCTestCase {
    
    private var sut: ExportThreadUseCase!
    private var mockRepository: MockThreadRepository!
    private var mockExporter: MockExporter!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockThreadRepository()
        mockExporter = MockExporter()
        sut = ExportThreadUseCase(repository: mockRepository, exporter: mockExporter)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        mockExporter = nil
        super.tearDown()
    }
    
    func testExecute_WithValidThread_ReturnsExportData() async throws {
        // Given
        let threadId = UUID()
        let thread = try Thread(id: threadId, title: "Test Thread", createdAt: Date(), updatedAt: Date())
        let entries = [
            try Entry(id: UUID(), threadId: threadId, content: "First entry", timestamp: Date()),
            try Entry(id: UUID(), threadId: threadId, content: "Second entry", timestamp: Date())
        ]
        
        mockRepository.fetchThreadResult = thread
        mockRepository.fetchEntriesResult = entries
        
        let expectedData = "test export data".data(using: .utf8)!
        mockExporter.exportResult = MockExportData(
            fileName: "test.csv",
            mimeType: "text/csv",
            data: expectedData
        )
        
        // When
        let result = try await sut.execute(threadId: threadId)
        
        // Then
        XCTAssertEqual(result.fileName, "test.csv")
        XCTAssertEqual(result.mimeType, "text/csv")
        XCTAssertEqual(result.data, expectedData)
        
        XCTAssertEqual(mockRepository.fetchThreadCallCount, 1)
        XCTAssertEqual(mockRepository.fetchEntriesCallCount, 1)
        XCTAssertEqual(mockExporter.exportCallCount, 1)
    }
    
    func testExecute_WhenThreadNotFound_ThrowsError() async {
        // Given
        let threadId = UUID()
        mockRepository.fetchThreadResult = nil
        
        // When/Then
        do {
            _ = try await sut.execute(threadId: threadId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is ExportError)
            if let exportError = error as? ExportError {
                switch exportError {
                case .threadNotFound:
                    break // Expected
                default:
                    XCTFail("Expected threadNotFound error")
                }
            }
        }
    }
    
    func testExecute_WhenRepositoryThrows_PropagatesError() async {
        // Given
        let threadId = UUID()
        mockRepository.error = NSError(domain: "test", code: 1, userInfo: nil)
        
        // When/Then
        do {
            _ = try await sut.execute(threadId: threadId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

// MARK: - Mock Classes

private final class MockExporter: Exporter {
    var exportCallCount = 0
    var exportResult: ExportData?
    
    func export(thread: Thread, entries: [Entry]) -> ExportData {
        exportCallCount += 1
        return exportResult ?? MockExportData(
            fileName: "mock.csv",
            mimeType: "text/csv",
            data: Data()
        )
    }
}

private struct MockExportData: ExportData {
    let fileName: String
    let mimeType: String
    let data: Data
}