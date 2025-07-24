//
//  EditEntryTests.swift
//  ThreadJournal2Tests
//
//  Tests for edit entry functionality
//

import XCTest
import SwiftUI
@testable import ThreadJournal2

final class EditEntryTests: XCTestCase {
    
    private var repository: MockThreadRepository!
    private var addEntryUseCase: AddEntryUseCase!
    private var draftManager: InMemoryDraftManager!
    private var exportThreadUseCase: ExportThreadUseCase!
    
    override func setUp() {
        super.setUp()
        repository = MockThreadRepository()
        addEntryUseCase = AddEntryUseCase(repository: repository)
        draftManager = InMemoryDraftManager()
        let mockExporter = MockExporter()
        exportThreadUseCase = ExportThreadUseCase(repository: repository, exporter: mockExporter)
    }
    
    override func tearDown() {
        repository = nil
        addEntryUseCase = nil
        draftManager = nil
        exportThreadUseCase = nil
        super.tearDown()
    }
    
    func testUpdateEntryUpdatesLocalState() async throws {
        // Given: A thread with an entry
        let threadId = UUID()
        let thread = try ThreadJournal2.Thread(
            id: threadId,
            title: "Test Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let originalContent = "Original entry content"
        let entry = try Entry(
            id: UUID(),
            threadId: threadId,
            content: originalContent,
            timestamp: Date()
        )
        
        repository.mockThreads = [thread]
        repository.mockEntries[threadId] = [entry]
        
        // When: Creating view model and updating entry
        let viewModel = await MainActor.run {
            ThreadDetailViewModel(
                repository: repository,
                addEntryUseCase: addEntryUseCase,
                draftManager: draftManager,
                exportThreadUseCase: exportThreadUseCase
            )
        }
        
        await viewModel.loadThread(id: threadId)
        
        // Verify initial state
        await MainActor.run {
            XCTAssertEqual(viewModel.entries.count, 1)
            XCTAssertEqual(viewModel.entries[0].content, originalContent)
        }
        
        // Update the entry
        let newContent = "Updated entry content"
        await viewModel.updateEntry(entry, newContent: newContent)
        
        // Then: Entry should be updated in local state
        await MainActor.run {
            XCTAssertEqual(viewModel.entries.count, 1)
            XCTAssertEqual(viewModel.entries[0].content, newContent)
            XCTAssertEqual(viewModel.entries[0].id, entry.id)
        }
    }
    
    func testUpdateEntryWithEmptyContentDoesNotUpdate() async throws {
        // Given: A thread with an entry
        let threadId = UUID()
        let thread = try ThreadJournal2.Thread(
            id: threadId,
            title: "Test Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let originalContent = "Original entry content"
        let entry = try Entry(
            id: UUID(),
            threadId: threadId,
            content: originalContent,
            timestamp: Date()
        )
        
        repository.mockThreads = [thread]
        repository.mockEntries[threadId] = [entry]
        
        // When: Creating view model and attempting to update with empty content
        let viewModel = await MainActor.run {
            ThreadDetailViewModel(
                repository: repository,
                addEntryUseCase: addEntryUseCase,
                draftManager: draftManager,
                exportThreadUseCase: exportThreadUseCase
            )
        }
        
        await viewModel.loadThread(id: threadId)
        
        // Update with empty content
        await viewModel.updateEntry(entry, newContent: "")
        
        // Then: Entry should not be updated
        await MainActor.run {
            XCTAssertEqual(viewModel.entries.count, 1)
            XCTAssertEqual(viewModel.entries[0].content, originalContent)
        }
    }
    
    func testUpdateEntryPreservesTimestamp() async throws {
        // Given: A thread with an entry
        let threadId = UUID()
        let thread = try ThreadJournal2.Thread(
            id: threadId,
            title: "Test Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let originalTimestamp = Date().addingTimeInterval(-3600) // 1 hour ago
        let entry = try Entry(
            id: UUID(),
            threadId: threadId,
            content: "Original content",
            timestamp: originalTimestamp
        )
        
        repository.mockThreads = [thread]
        repository.mockEntries[threadId] = [entry]
        
        // When: Updating the entry
        let viewModel = await MainActor.run {
            ThreadDetailViewModel(
                repository: repository,
                addEntryUseCase: addEntryUseCase,
                draftManager: draftManager,
                exportThreadUseCase: exportThreadUseCase
            )
        }
        
        await viewModel.loadThread(id: threadId)
        await viewModel.updateEntry(entry, newContent: "Updated content")
        
        // Then: Timestamp should be preserved
        await MainActor.run {
            XCTAssertEqual(viewModel.entries[0].timestamp, originalTimestamp)
        }
    }
}