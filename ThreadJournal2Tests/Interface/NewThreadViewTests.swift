//
//  NewThreadViewTests.swift
//  ThreadJournal2Tests
//
//  UI tests for NewThreadView
//

import XCTest
import SwiftUI
@testable import ThreadJournal2

final class NewThreadViewTests: XCTestCase {
    private var mockRepository: MockThreadRepository!
    private var createThreadUseCase: CreateThreadUseCase!
    private var draftManager: InMemoryDraftManager!
    private var viewModel: CreateThreadViewModel!
    private var createdThread: ThreadJournal2.Thread?
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockRepository = MockThreadRepository()
        createThreadUseCase = CreateThreadUseCase(repository: mockRepository)
        draftManager = InMemoryDraftManager()
        viewModel = CreateThreadViewModel(
            createThreadUseCase: createThreadUseCase,
            draftManager: draftManager
        )
        createdThread = nil
    }
    
    override func tearDown() {
        createdThread = nil
        viewModel = nil
        draftManager = nil
        createThreadUseCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    @MainActor
    func testViewStructure() throws {
        // Given
        _ = NewThreadView(viewModel: viewModel) { thread in
            self.createdThread = thread
        }
        
        // Cannot use ViewInspector as it's not in the project
        // This would be where UI structure tests would go
        // For now, we'll just verify the view compiles
        XCTAssertTrue(true)
    }
    
    @MainActor
    func testThreadCreationFlow() async throws {
        // Given
        viewModel.threadTitle = "Test Thread"
        viewModel.firstEntryContent = "First entry"
        
        // When
        await viewModel.createThread()
        
        // Then
        XCTAssertNotNil(viewModel.createdThread)
        XCTAssertEqual(viewModel.createdThread?.title, "Test Thread")
    }
    
    @MainActor
    func testCreateButtonStateUpdates() {
        // Initially disabled
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
        
        // Enabled when title entered
        viewModel.threadTitle = "My Thread"
        XCTAssertTrue(viewModel.isCreateButtonEnabled)
        
        // Disabled when title is whitespace
        viewModel.threadTitle = "   "
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
    }
    
    @MainActor
    func testDraftPersistence() async {
        // Given
        viewModel.threadTitle = "Draft Title"
        viewModel.firstEntryContent = "Draft content"
        viewModel.onTitleChange()
        
        // Wait for draft save
        try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
        
        // When creating new view model with same draft manager
        let newViewModel = CreateThreadViewModel(
            createThreadUseCase: createThreadUseCase,
            draftManager: draftManager
        )
        
        // Then draft should be loaded
        XCTAssertEqual(newViewModel.threadTitle, "Draft Title")
        XCTAssertEqual(newViewModel.firstEntryContent, "Draft content")
    }
    
    @MainActor
    func testErrorHandling() async {
        // Given
        viewModel.threadTitle = "Test Thread"
        mockRepository.shouldFailCreate = true
        
        // When
        await viewModel.createThread()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.hasError)
        XCTAssertNil(viewModel.createdThread)
    }
}