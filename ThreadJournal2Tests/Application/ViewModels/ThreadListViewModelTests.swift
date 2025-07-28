//
//  ThreadListViewModelTests.swift
//  ThreadJournal2Tests
//
//  Tests for ThreadListViewModel
//

import XCTest
@testable import ThreadJournal2

@MainActor
final class ThreadListViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: ThreadListViewModel!
    private var mockRepository: MockThreadRepository!
    private var createThreadUseCase: CreateThreadUseCase!
    
    // MARK: - Setup
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockRepository = MockThreadRepository()
        createThreadUseCase = CreateThreadUseCase(repository: mockRepository)
        let deleteThreadUseCase = DeleteThreadUseCaseImpl(repository: mockRepository)
        sut = ThreadListViewModel(
            repository: mockRepository,
            createThreadUseCase: createThreadUseCase,
            deleteThreadUseCase: deleteThreadUseCase
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        createThreadUseCase = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        // Then
        XCTAssertTrue(sut.threadsWithMetadata.isEmpty)
        XCTAssertEqual(sut.loadingState, .idle)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    // MARK: - Load Threads Tests
    
    func testLoadThreads_Success_UpdatesThreadsAndState() async throws {
        // Given
        let thread1 = try Thread(title: "Thread 1", createdAt: Date().addingTimeInterval(-3600), updatedAt: Date().addingTimeInterval(-1800))
        let thread2 = try Thread(title: "Thread 2", createdAt: Date().addingTimeInterval(-7200), updatedAt: Date())
        let thread3 = try Thread(title: "Thread 3", createdAt: Date().addingTimeInterval(-10800), updatedAt: Date().addingTimeInterval(-3600))
        
        mockRepository.threads = [thread1, thread2, thread3]
        
        // When
        sut.loadThreads()
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(sut.threadsWithMetadata.count, 3)
        XCTAssertEqual(sut.threadsWithMetadata[0].thread.id, thread2.id) // Most recent first
        XCTAssertEqual(sut.threadsWithMetadata[1].thread.id, thread1.id)
        XCTAssertEqual(sut.threadsWithMetadata[2].thread.id, thread3.id)
        XCTAssertEqual(sut.loadingState, .loaded)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertEqual(mockRepository.fetchAllCallCount, 1)
    }
    
    func testLoadThreads_EmptyRepository_ReturnsEmptyArray() async throws {
        // Given
        mockRepository.threads = []
        
        // When
        sut.loadThreads()
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(sut.threadsWithMetadata.isEmpty)
        XCTAssertEqual(sut.loadingState, .loaded)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    func testLoadThreads_Failure_UpdatesErrorState() async throws {
        // Given
        mockRepository.shouldFailFetch = true
        let expectedError = PersistenceError.fetchFailed(underlying: NSError(domain: "Test", code: 1))
        mockRepository.injectedError = expectedError
        
        // When
        sut.loadThreads()
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(sut.threadsWithMetadata.isEmpty)
        XCTAssertEqual(sut.loadingState, .error(expectedError))
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.error)
        
        if let error = sut.error as? PersistenceError,
           case .fetchFailed = error {
            // Success - correct error type
        } else {
            XCTFail("Expected PersistenceError.fetchFailed")
        }
    }
    
    func testLoadThreads_SetsLoadingStateWhileLoading() async throws {
        // Given
        let thread = try Thread(title: "Test Thread")
        mockRepository.threads = [thread]
        
        // When
        sut.loadThreads()
        
        // Then - immediately check loading state
        XCTAssertEqual(sut.loadingState, .loading)
        XCTAssertTrue(sut.isLoading)
        
        // Wait for completion
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify final state
        XCTAssertEqual(sut.loadingState, .loaded)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Create Thread Tests
    
    func testCreateThread_Success_CreatesThreadAndReloads() async throws {
        // Given
        let title = "New Thread"
        let firstEntry = "First entry content"
        
        // When
        let createdThread = try await sut.createThread(title: title, firstEntry: firstEntry)
        
        // Wait for reload to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(createdThread.title, title)
        XCTAssertEqual(sut.threadsWithMetadata.count, 1)
        XCTAssertEqual(sut.threadsWithMetadata[0].thread.title, title)
        XCTAssertEqual(mockRepository.createCallCount, 1)
        XCTAssertEqual(mockRepository.addEntryCallCount, 1)
        XCTAssertEqual(mockRepository.fetchAllCallCount, 1) // From reload
    }
    
    func testCreateThread_WithoutFirstEntry_CreatesThreadOnly() async throws {
        // Given
        let title = "Thread Without Entry"
        
        // When
        let createdThread = try await sut.createThread(title: title, firstEntry: nil)
        
        // Wait for reload to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(createdThread.title, title)
        XCTAssertEqual(sut.threadsWithMetadata.count, 1)
        XCTAssertEqual(mockRepository.createCallCount, 1)
        XCTAssertEqual(mockRepository.addEntryCallCount, 0) // No entry added
    }
    
    func testCreateThread_EmptyTitle_ThrowsValidationError() async {
        // Given
        let emptyTitle = "   "
        
        // When/Then
        do {
            _ = try await sut.createThread(title: emptyTitle)
            XCTFail("Expected ValidationError.emptyTitle")
        } catch let error as ValidationError {
            XCTAssertEqual(error, .emptyTitle)
        } catch {
            XCTFail("Expected ValidationError.emptyTitle, got \(error)")
        }
    }
    
    func testCreateThread_RepositoryFailure_UpdatesErrorState() async {
        // Given
        mockRepository.shouldFailCreate = true
        let expectedError = PersistenceError.saveFailed(underlying: NSError(domain: "Test", code: 1))
        mockRepository.injectedError = expectedError
        
        // When/Then
        do {
            _ = try await sut.createThread(title: "Test Thread")
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify error state is updated
            if case .error(let stateError) = sut.loadingState,
               let persistenceError = stateError as? PersistenceError,
               case .saveFailed = persistenceError {
                // Success - correct error in state
            } else {
                XCTFail("Expected error state with PersistenceError.saveFailed")
            }
        }
    }
    
    func testCreateThread_MultipleThreads_MaintainsSortOrder() async throws {
        // Given - Create threads with delays to ensure different timestamps
        let thread1 = try await sut.createThread(title: "First Thread")
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        
        let thread2 = try await sut.createThread(title: "Second Thread")
        try await Task.sleep(nanoseconds: 10_000_000)
        
        let thread3 = try await sut.createThread(title: "Third Thread")
        
        // Wait for final reload
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - Verify most recent thread is first
        XCTAssertEqual(sut.threadsWithMetadata.count, 3)
        XCTAssertEqual(sut.threadsWithMetadata[0].thread.id, thread3.id) // Most recent
        XCTAssertEqual(sut.threadsWithMetadata[1].thread.id, thread2.id)
        XCTAssertEqual(sut.threadsWithMetadata[2].thread.id, thread1.id) // Oldest
    }
    
    // MARK: - Error State Tests
    
    func testError_PropertyReturnsCorrectError() async throws {
        // Given
        mockRepository.shouldFailFetch = true
        let expectedError = PersistenceError.notFound(id: UUID())
        mockRepository.injectedError = expectedError
        
        // When
        sut.loadThreads()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        let error = sut.error
        XCTAssertNotNil(error)
        if let persistenceError = error as? PersistenceError,
           case .notFound = persistenceError {
            // Success
        } else {
            XCTFail("Expected PersistenceError.notFound")
        }
    }
    
    func testError_PropertyReturnsNilWhenNoError() {
        // Given/When - Initial state has no error
        
        // Then
        XCTAssertNil(sut.error)
    }
    
    // MARK: - Loading State Tests
    
    func testIsLoading_TrueWhenLoading() async throws {
        // Given
        let thread = try Thread(title: "Test Thread")
        mockRepository.threads = [thread]
        
        // When
        sut.loadThreads()
        
        // Then - immediately check loading state
        XCTAssertTrue(sut.isLoading)
        
        // Wait for completion
        try await Task.sleep(nanoseconds: 100_000_000)
    }
    
    func testIsLoading_FalseWhenNotLoading() {
        // When/Then - Check initial state and after operations
        XCTAssertFalse(sut.isLoading, "isLoading should be false initially")
    }
    
    // MARK: - Delete Thread Tests
    
    func testConfirmDeleteThread_SetsThreadAndShowsConfirmation() {
        // Given
        let thread = try! Thread(title: "Thread to Delete")
        
        // When
        sut.confirmDeleteThread(thread)
        
        // Then
        XCTAssertEqual(sut.threadToDelete?.id, thread.id)
        XCTAssertTrue(sut.showDeleteConfirmation)
    }
    
    func testCancelDelete_ClearsThreadAndHidesConfirmation() {
        // Given
        let thread = try! Thread(title: "Thread to Delete")
        sut.confirmDeleteThread(thread)
        
        // Verify setup
        XCTAssertNotNil(sut.threadToDelete)
        XCTAssertTrue(sut.showDeleteConfirmation)
        
        // When
        sut.cancelDelete()
        
        // Then
        XCTAssertNil(sut.threadToDelete)
        XCTAssertFalse(sut.showDeleteConfirmation)
    }
    
    func testDeleteThread_Success_DeletesThreadAndReloads() async throws {
        // Given
        let thread1 = try Thread(title: "Thread 1")
        let thread2 = try Thread(title: "Thread 2")
        mockRepository.threads = [thread1, thread2]
        
        // Set up for deletion
        sut.confirmDeleteThread(thread1)
        
        // When
        await sut.deleteThread()
        
        // Wait for reload to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertNil(sut.threadToDelete) // Selection cleared
        XCTAssertFalse(sut.showDeleteConfirmation) // Dialog hidden
        XCTAssertEqual(mockRepository.softDeleteCallCount, 1)
        XCTAssertEqual(mockRepository.fetchAllCallCount, 1) // From reload
    }
    
    func testDeleteThread_WithoutSelection_DoesNothing() async {
        // Given - No thread selected
        XCTAssertNil(sut.threadToDelete)
        
        // When
        await sut.deleteThread()
        
        // Then
        XCTAssertEqual(mockRepository.softDeleteCallCount, 0)
        XCTAssertFalse(sut.showDeleteConfirmation)
    }
    
    func testDeleteThread_Failure_UpdatesErrorState() async throws {
        // Given
        let thread = try Thread(title: "Thread to Delete")
        mockRepository.threads = [thread]
        mockRepository.shouldFailDelete = true
        let expectedError = PersistenceError.deleteFailed(underlying: NSError(domain: "Test", code: 1))
        mockRepository.injectedError = expectedError
        
        // Set up for deletion
        sut.confirmDeleteThread(thread)
        
        // When
        await sut.deleteThread()
        
        // Then
        XCTAssertFalse(sut.showDeleteConfirmation) // Dialog hidden even on error
        
        // Check error state
        if case .error(let stateError) = sut.loadingState,
           let persistenceError = stateError as? PersistenceError,
           case .deleteFailed = persistenceError {
            // Success - correct error in state
        } else {
            XCTFail("Expected error state with PersistenceError.deleteFailed")
        }
    }
    
    func testDeleteThread_HidesConfirmationImmediately() async throws {
        // Given
        let thread = try Thread(title: "Thread to Delete")
        mockRepository.threads = [thread]
        sut.confirmDeleteThread(thread)
        
        // Verify setup
        XCTAssertTrue(sut.showDeleteConfirmation)
        
        // When
        await sut.deleteThread()
        
        // Then - Confirmation should be hidden immediately
        XCTAssertFalse(sut.showDeleteConfirmation)
    }
    
    func testDeleteThread_ClearsSelectionAfterDeletion() async throws {
        // Given
        let thread = try Thread(title: "Thread to Delete")
        mockRepository.threads = [thread]
        sut.confirmDeleteThread(thread)
        
        // Verify setup
        XCTAssertNotNil(sut.threadToDelete)
        
        // When
        await sut.deleteThread()
        
        // Then
        XCTAssertNil(sut.threadToDelete)
    }
    
    func testMultipleDeleteOperations_HandledCorrectly() async throws {
        // Given
        let thread1 = try Thread(title: "Thread 1")
        let thread2 = try Thread(title: "Thread 2") 
        let thread3 = try Thread(title: "Thread 3")
        mockRepository.threads = [thread1, thread2, thread3]
        
        // Delete first thread
        sut.confirmDeleteThread(thread1)
        await sut.deleteThread()
        
        // Delete second thread
        sut.confirmDeleteThread(thread2)
        await sut.deleteThread()
        
        // Wait for operations to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(mockRepository.softDeleteCallCount, 2)
        XCTAssertNil(sut.threadToDelete)
        XCTAssertFalse(sut.showDeleteConfirmation)
    }
}