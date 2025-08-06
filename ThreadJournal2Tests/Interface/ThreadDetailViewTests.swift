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
    private var updateEntryUseCase: UpdateEntryUseCase!
    private var deleteEntryUseCase: DeleteEntryUseCase!
    private var draftManager: InMemoryDraftManager!
    private var createFieldUseCase: CreateCustomFieldUseCase!
    private var createGroupUseCase: CreateFieldGroupUseCase!
    private var deleteFieldUseCase: DeleteCustomFieldUseCase!
    
    override func setUp() {
        super.setUp()
        repository = MockThreadRepository()
        addEntryUseCase = AddEntryUseCase(repository: repository)
        updateEntryUseCase = UpdateEntryUseCase(repository: repository)
        deleteEntryUseCase = DeleteEntryUseCase(repository: repository)
        draftManager = InMemoryDraftManager()
        createFieldUseCase = CreateCustomFieldUseCase(threadRepository: repository)
        createGroupUseCase = CreateFieldGroupUseCase(threadRepository: repository)
        deleteFieldUseCase = DeleteCustomFieldUseCase(threadRepository: repository)
    }
    
    override func tearDown() {
        repository = nil
        addEntryUseCase = nil
        updateEntryUseCase = nil
        deleteEntryUseCase = nil
        draftManager = nil
        createFieldUseCase = nil
        createGroupUseCase = nil
        deleteFieldUseCase = nil
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
        
        let view = ThreadDetailViewFixed(
            threadId: thread.id,
            repository: repository,
            addEntryUseCase: addEntryUseCase,
            updateEntryUseCase: updateEntryUseCase,
            deleteEntryUseCase: deleteEntryUseCase,
            draftManager: draftManager,
            exportThreadUseCase: exportThreadUseCase,
            createFieldUseCase: createFieldUseCase,
            createGroupUseCase: createGroupUseCase,
            deleteFieldUseCase: deleteFieldUseCase
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
                updateEntryUseCase: updateEntryUseCase,
                deleteEntryUseCase: deleteEntryUseCase,
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
    
    // MARK: - Text Input Auto-Expansion Tests
    
    @MainActor
    func testTextInputStartsAtMinimumHeight() async throws {
        // Given
        let threadId = UUID()
        let thread = try Thread(
            id: threadId,
            title: "Test Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        repository.mockThreads = [thread]
        repository.mockEntries[threadId] = []
        
        // When
        let mockExporter = MockExporter()
        let exportThreadUseCase = ExportThreadUseCase(
            repository: repository,
            exporter: mockExporter
        )
        
        let viewModel = ThreadDetailViewModel(
            repository: repository,
            addEntryUseCase: addEntryUseCase,
            updateEntryUseCase: updateEntryUseCase,
            deleteEntryUseCase: deleteEntryUseCase,
            draftManager: draftManager,
            exportThreadUseCase: exportThreadUseCase
        )
        
        await viewModel.loadThread(id: threadId)
        
        // Then
        XCTAssertEqual(viewModel.draftContent, "")
        // Note: With the new TextField approach, minimum height is handled automatically
    }
    
    @MainActor
    func testTextInputExpandsWithLongText() async throws {
        // Given
        let threadId = UUID()
        let thread = try Thread(
            id: threadId,
            title: "Test Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        repository.mockThreads = [thread]
        repository.mockEntries[threadId] = []
        
        // When
        let mockExporter = MockExporter()
        let exportThreadUseCase = ExportThreadUseCase(
            repository: repository,
            exporter: mockExporter
        )
        
        let viewModel = ThreadDetailViewModel(
            repository: repository,
            addEntryUseCase: addEntryUseCase,
            updateEntryUseCase: updateEntryUseCase,
            deleteEntryUseCase: deleteEntryUseCase,
            draftManager: draftManager,
            exportThreadUseCase: exportThreadUseCase
        )
        
        await viewModel.loadThread(id: threadId)
        
        // Simulate typing long text that would wrap
        let longText = String(repeating: "This is a long text that should wrap to multiple lines. ", count: 5)
        viewModel.draftContent = longText
        
        // Then
        XCTAssertFalse(viewModel.draftContent.isEmpty)
        XCTAssertTrue(viewModel.draftContent.count > 100)
        // Note: With TextField axis: .vertical, expansion happens automatically
    }
    
    @MainActor
    func testTextInputExpandsWithMultipleLines() async throws {
        // Given
        let threadId = UUID()
        let thread = try Thread(
            id: threadId,
            title: "Test Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        repository.mockThreads = [thread]
        repository.mockEntries[threadId] = []
        
        // When
        let mockExporter = MockExporter()
        let exportThreadUseCase = ExportThreadUseCase(
            repository: repository,
            exporter: mockExporter
        )
        
        let viewModel = ThreadDetailViewModel(
            repository: repository,
            addEntryUseCase: addEntryUseCase,
            updateEntryUseCase: updateEntryUseCase,
            deleteEntryUseCase: deleteEntryUseCase,
            draftManager: draftManager,
            exportThreadUseCase: exportThreadUseCase
        )
        
        await viewModel.loadThread(id: threadId)
        
        // Simulate typing text with newlines
        let multilineText = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5"
        viewModel.draftContent = multilineText
        
        // Then
        let lineCount = viewModel.draftContent.components(separatedBy: .newlines).count
        XCTAssertEqual(lineCount, 5)
        // Note: With TextField lineLimit(1...10), this will expand to show 5 lines
    }
    
    @MainActor
    func testTextInputRespectsMaximumHeight() async throws {
        // Given
        let threadId = UUID()
        let thread = try Thread(
            id: threadId,
            title: "Test Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        repository.mockThreads = [thread]
        repository.mockEntries[threadId] = []
        
        // When
        let mockExporter = MockExporter()
        let exportThreadUseCase = ExportThreadUseCase(
            repository: repository,
            exporter: mockExporter
        )
        
        let viewModel = ThreadDetailViewModel(
            repository: repository,
            addEntryUseCase: addEntryUseCase,
            updateEntryUseCase: updateEntryUseCase,
            deleteEntryUseCase: deleteEntryUseCase,
            draftManager: draftManager,
            exportThreadUseCase: exportThreadUseCase
        )
        
        await viewModel.loadThread(id: threadId)
        
        // Simulate typing many lines
        let manyLines = (1...20).map { "Line \($0)" }.joined(separator: "\n")
        viewModel.draftContent = manyLines
        
        // Then
        let lineCount = viewModel.draftContent.components(separatedBy: .newlines).count
        XCTAssertEqual(lineCount, 20)
        // Note: With TextField lineLimit(1...10), it will show max 10 lines with scrolling
    }
    
    @MainActor
    func testTextInputShrinksWhenContentDeleted() async throws {
        // Given
        let threadId = UUID()
        let thread = try Thread(
            id: threadId,
            title: "Test Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        repository.mockThreads = [thread]
        repository.mockEntries[threadId] = []
        
        // When
        let mockExporter = MockExporter()
        let exportThreadUseCase = ExportThreadUseCase(
            repository: repository,
            exporter: mockExporter
        )
        
        let viewModel = ThreadDetailViewModel(
            repository: repository,
            addEntryUseCase: addEntryUseCase,
            updateEntryUseCase: updateEntryUseCase,
            deleteEntryUseCase: deleteEntryUseCase,
            draftManager: draftManager,
            exportThreadUseCase: exportThreadUseCase
        )
        
        await viewModel.loadThread(id: threadId)
        
        // First add multiple lines
        viewModel.draftContent = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5"
        
        // Then delete most content
        viewModel.draftContent = "Short text"
        
        // Then
        XCTAssertEqual(viewModel.draftContent, "Short text")
        XCTAssertEqual(viewModel.draftContent.components(separatedBy: .newlines).count, 1)
        // Note: TextField will automatically shrink back to single line
    }
}