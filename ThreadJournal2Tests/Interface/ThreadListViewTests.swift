//
//  ThreadListViewTests.swift
//  ThreadJournal2Tests
//
//  UI tests for ThreadListView
//

import XCTest
import SwiftUI
@testable import ThreadJournal2

final class ThreadListViewTests: XCTestCase {
    
    var mockRepository: MockThreadRepository!
    var createThreadUseCase: CreateThreadUseCase!
    var viewModel: ThreadListViewModel!
    
    @MainActor
    override func setUp() async throws {
        mockRepository = MockThreadRepository()
        createThreadUseCase = CreateThreadUseCase(repository: mockRepository)
        viewModel = ThreadListViewModel(
            repository: mockRepository,
            createThreadUseCase: createThreadUseCase
        )
    }
    
    func testThreadListViewInitialization() {
        // Given
        let view = ThreadListView(viewModel: viewModel)
        
        // Then
        XCTAssertNotNil(view)
    }
    
    @MainActor
    func testEmptyStateShown() async {
        // Given
        mockRepository.threads = []
        
        // When
        viewModel.loadThreads()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertTrue(viewModel.threadsWithMetadata.isEmpty)
        XCTAssertEqual(viewModel.loadingState, .loaded)
    }
    
    @MainActor
    func testThreadsDisplayed() async throws {
        // Given
        let thread1 = try Thread(title: "Test Thread 1")
        let thread2 = try Thread(title: "Test Thread 2")
        mockRepository.threads = [thread1, thread2]
        
        // When
        viewModel.loadThreads()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(viewModel.threadsWithMetadata.count, 2)
        XCTAssertEqual(viewModel.threadsWithMetadata[0].thread.title, "Test Thread 1")
        XCTAssertEqual(viewModel.threadsWithMetadata[1].thread.title, "Test Thread 2")
    }
}