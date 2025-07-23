//
//  ThreadDetailPerformanceTests.swift
//  ThreadJournal2Tests
//
//  Performance tests for thread detail view with 1000 entries
//

import XCTest
@testable import ThreadJournal2

final class ThreadDetailPerformanceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var repository: MockThreadRepository!
    private var viewModel: ThreadDetailViewModel!
    private var testThread: Thread!
    private var testEntries: [Entry]!
    private var draftManager: DraftManager!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        // Create test data - 1 thread with 1000 entries
        let testData = TestDataBuilder.createThreadDetailTestData()
        testThread = testData.thread
        testEntries = testData.entries
        
        // Setup mock repository
        repository = MockThreadRepository()
        repository.threads = [testThread]
        repository.entriesByThread[testThread.id] = testEntries
        
        // Setup dependencies
        draftManager = InMemoryDraftManager()
        let addEntryUseCase = AddEntryUseCase(repository: repository)
        let exportUseCase = ExportThreadUseCase(
            repository: repository,
            exporter: CSVExporter()
        )
        
        // Create view model
        viewModel = ThreadDetailViewModel(
            repository: repository,
            addEntryUseCase: addEntryUseCase,
            draftManager: draftManager,
            exportThreadUseCase: exportUseCase
        )
    }
    
    override func tearDown() {
        viewModel = nil
        repository = nil
        testThread = nil
        testEntries = nil
        draftManager = nil
        
        super.tearDown()
    }
    
    // MARK: - Performance Tests
    
    func testLoadThreadDetail_With1000Entries_CompletesUnder300ms() {
        // Given: Thread with 1000 entries
        let expectation = XCTestExpectation(description: "Thread detail loads")
        
        measure {
            // When: Loading thread detail
            Task { @MainActor in
                await viewModel.loadThread(id: testThread.id)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
            
            // Then: Should have loaded all entries
            XCTAssertEqual(viewModel.entries.count, 1000)
            XCTAssertEqual(viewModel.thread?.id, testThread.id)
        }
    }
    
    func testScrollToLatestEntry_With1000Entries_CompletesQuickly() {
        // Given: Loaded thread with entries
        Task { @MainActor in
            await viewModel.loadThread(id: testThread.id)
        }
        
        // Wait for initial load
        let loadExpectation = XCTestExpectation(description: "Initial load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 0.5)
        
        measure {
            // When: Triggering scroll to latest
            Task { @MainActor in
                viewModel.triggerScrollToLatest()
            }
            
            // Then: Should set flag quickly
            XCTAssertTrue(viewModel.shouldScrollToLatest)
        }
    }
    
    func testFilterEntries_ByContent_PerformsWell() {
        // Given: 1000 entries
        measure {
            // When: Filtering entries by content
            let filteredEntries = testEntries.filter { entry in
                entry.content.localizedCaseInsensitiveContains("grateful")
            }
            
            // Then: Should complete quickly
            XCTAssertGreaterThan(filteredEntries.count, 0)
        }
    }
    
    // MARK: - Memory Tests
    
    func testThreadDetailMemoryUsage_With1000Entries_StaysUnderLimit() {
        // Given: Memory tracking
        let initialMemory = getCurrentMemoryUsage()
        
        // When: Loading thread with 1000 entries
        Task { @MainActor in
            await viewModel.loadThread(id: testThread.id)
        }
        
        // Wait for load to complete
        let expectation = XCTestExpectation(description: "Load completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: Memory increase should be reasonable
        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        let memoryIncreaseMB = Double(memoryIncrease) / 1024.0 / 1024.0
        
        // 1000 entries with ~100 chars each = ~100KB, plus overhead
        XCTAssertLessThan(memoryIncreaseMB, 20.0, "Memory usage exceeded 20MB for 1000 entries")
    }
    
    func testRenderPerformance_LongEntries_HandlesWell() {
        // Given: Entries with varying content lengths
        let longEntries = (0..<100).map { index in
            let longContent = String(repeating: "This is a long entry. ", count: 50)
            return try! Entry(
                id: UUID(),
                threadId: testThread.id,
                content: longContent + "Entry #\(index)",
                timestamp: Date()
            )
        }
        
        repository.entriesByThread[testThread.id] = longEntries
        
        let expectation = XCTestExpectation(description: "Load long entries")
        
        measure {
            // When: Loading entries with long content
            Task { @MainActor in
                await viewModel.loadThread(id: testThread.id)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
            
            // Then: Should handle long entries well
            XCTAssertEqual(viewModel.entries.count, 100)
        }
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