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
        
        mockRepository.mockThreads = [thread]
        mockRepository.mockEntries[threadId] = entries
        
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
        
        XCTAssertEqual(mockRepository.fetchCallCount, 1)
        XCTAssertEqual(mockRepository.fetchEntriesCallCount, 1)
        XCTAssertEqual(mockRepository.fetchCustomFieldsCallCount, 1)
        XCTAssertEqual(mockRepository.fetchFieldGroupsCallCount, 1)
        XCTAssertEqual(mockExporter.exportCallCount, 1)
    }
    
    func testExecute_WhenThreadNotFound_ThrowsError() async {
        // Given
        let threadId = UUID()
        mockRepository.mockThreads = []
        
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
        mockRepository.shouldFailFetch = true
        
        // When/Then
        do {
            _ = try await sut.execute(threadId: threadId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

// Mock classes are now in MockExporter.swift