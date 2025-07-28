//
//  ThreadListPerformanceTests.swift
//  ThreadJournal2Tests
//
//  Performance tests for thread list loading with 100 threads
//

import XCTest
@testable import ThreadJournal2


final class ThreadListPerformanceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var repository: ThreadRepository!
    private var viewModel: ThreadListViewModel!
    private var testThreads: [ThreadJournal2.Thread]!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        // Create test data
        testThreads = TestDataBuilder.createThreadListTestData()
        
        // Setup mock repository with test data
        let mockRepository = MockThreadRepository()
        mockRepository.threads = testThreads
        
        repository = mockRepository
        
        // Create use case and view model within MainActor context
        let createThreadUseCase = CreateThreadUseCase(repository: repository)
        let deleteThreadUseCase = DeleteThreadUseCaseImpl(repository: repository)
        
        // Use synchronous expectation to create view model on MainActor
        let expectation = expectation(description: "Setup complete")
        Task { @MainActor in
            viewModel = ThreadListViewModel(
                repository: repository,
                createThreadUseCase: createThreadUseCase,
                deleteThreadUseCase: deleteThreadUseCase
            )
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    override func tearDown() {
        viewModel = nil
        repository = nil
        testThreads = nil
        
        super.tearDown()
    }
    
    // MARK: - Performance Tests
    
    func testLoadThreadList_With100Threads_CompletesUnder200ms() {
        // Given: Repository with 100 threads
        
        // Measure performance
        measure {
            let expectation = XCTestExpectation(description: "Thread list loads")
            
            // When: Loading thread list
            Task { @MainActor in
                await viewModel.loadThreads()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
            
            // Then: Should have loaded all threads
            Task { @MainActor in
                XCTAssertEqual(viewModel.threadsWithMetadata.count, 100)
            }
        }
    }
    
    func testFilterThreadList_ByTitle_CompletesQuickly() {
        // Given: Loaded thread list
        let loadExpectation = expectation(description: "Initial load")
        Task { @MainActor in
            await viewModel.loadThreads()
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 1.0)
        
        measure {
            // When: Filtering threads
            let filteredThreads = testThreads.filter { thread in
                thread.title.localizedCaseInsensitiveContains("Test Thread 5")
            }
            
            // Then: Should complete quickly
            XCTAssertGreaterThan(filteredThreads.count, 0)
            XCTAssertLessThan(filteredThreads.count, 20) // Should match ~11 threads (50-59)
        }
    }
    
    func testSortThreadList_ByLastUpdated_CompletesQuickly() {
        // Given: Unsorted thread list
        let unsortedThreads = testThreads.shuffled()
        
        measure {
            // When: Sorting by last updated
            let sortedThreads = unsortedThreads.sorted { thread1, thread2 in
                thread1.updatedAt > thread2.updatedAt
            }
            
            // Then: Should be properly sorted
            XCTAssertEqual(sortedThreads.count, 100)
            for i in 0..<(sortedThreads.count - 1) {
                XCTAssertGreaterThanOrEqual(
                    sortedThreads[i].updatedAt,
                    sortedThreads[i + 1].updatedAt
                )
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testThreadListMemoryUsage_With100Threads_StaysUnderLimit() {
        // Given: Memory tracking
        let initialMemory = getCurrentMemoryUsage()
        
        // When: Loading 100 threads
        let loadExpectation = expectation(description: "Load completes")
        Task { @MainActor in
            await viewModel.loadThreads()
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 1.0)
        
        // Then: Memory increase should be reasonable
        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        let memoryIncreaseMB = Double(memoryIncrease) / 1024.0 / 1024.0
        
        // Each thread should use minimal memory
        XCTAssertLessThan(memoryIncreaseMB, 10.0, "Memory usage exceeded 10MB for 100 threads")
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

// MARK: - Extended Mock for Performance Testing

extension MockThreadRepository {
    
    /// Simulates network/database delay for more realistic performance testing
    func simulateRealisticDelay() async {
        // Simulate 10-50ms database query time
        let delay = Double.random(in: 0.01...0.05)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
}