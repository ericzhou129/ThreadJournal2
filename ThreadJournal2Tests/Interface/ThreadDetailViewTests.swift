//
//  ThreadDetailViewTests.swift
//  ThreadJournal2Tests
//
//  Tests for ThreadDetailView
//

import XCTest
import SwiftUI
@testable import ThreadJournal2


final class ThreadDetailViewTests: XCTestCase {
    
    private var repository: MockThreadRepository!
    private var addEntryUseCase: AddEntryUseCase!
    private var draftManager: InMemoryDraftManager!
    
    override func setUp() {
        super.setUp()
        repository = MockThreadRepository()
        addEntryUseCase = AddEntryUseCase(repository: repository)
        draftManager = InMemoryDraftManager()
    }
    
    override func tearDown() {
        repository = nil
        addEntryUseCase = nil
        draftManager = nil
        super.tearDown()
    }
    
    func testThreadDetailViewInitialization() throws {
        // Given
        let thread = try Thread(
            id: UUID(),
            title: "Test Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When
        let mockExporter = MockExporter()
        let exportThreadUseCase = ExportThreadUseCase(
            repository: repository,
            exporter: mockExporter
        )
        
        let view = ThreadDetailView(
            threadId: thread.id,
            repository: repository,
            addEntryUseCase: addEntryUseCase,
            draftManager: draftManager,
            exportThreadUseCase: exportThreadUseCase
        )
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testThreadDetailViewWithEntries() async throws {
        // Given
        let threadId = UUID()
        let thread = try Thread(
            id: threadId,
            title: "Test Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let entry1 = try Entry(
            id: UUID(),
            threadId: threadId,
            content: "First entry",
            timestamp: Date().addingTimeInterval(-3600)
        )
        
        let entry2 = try Entry(
            id: UUID(),
            threadId: threadId,
            content: "Second entry",
            timestamp: Date()
        )
        
        repository.mockThreads = [thread]
        repository.mockEntries[threadId] = [entry1, entry2]
        
        // When
        let expectation = XCTestExpectation(description: "Load thread")
        
        Task { @MainActor in
            let mockExporter = MockExporter()
            let exportThreadUseCase = ExportThreadUseCase(
                repository: repository,
                exporter: mockExporter
            )
            
            let viewModel = ThreadDetailViewModel(
                repository: repository,
                addEntryUseCase: addEntryUseCase,
                draftManager: draftManager,
                exportThreadUseCase: exportThreadUseCase
            )
            
            await viewModel.loadThread(id: threadId)
            
            // Then
            XCTAssertEqual(viewModel.thread?.id, threadId)
            XCTAssertEqual(viewModel.entries.count, 2)
            XCTAssertEqual(viewModel.entries[0].content, "First entry")
            XCTAssertEqual(viewModel.entries[1].content, "Second entry")
            XCTAssertTrue(viewModel.shouldScrollToLatest)
            
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
}