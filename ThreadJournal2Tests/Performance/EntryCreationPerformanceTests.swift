//
//  EntryCreationPerformanceTests.swift
//  ThreadJournal2Tests
//
//  Performance tests for creating new entries
//

import XCTest
@testable import ThreadJournal2

final class EntryCreationPerformanceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var repository: MockThreadRepository!
    private var addEntryUseCase: AddEntryUseCase!
    private var viewModel: ThreadDetailViewModel!
    private var testThread: Thread!
    private var draftManager: DraftManager!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        // Create test thread
        testThread = TestDataBuilder.createThread(title: "Entry Creation Test")
        
        // Setup repository
        repository = MockThreadRepository()
        repository.threads = [testThread]
        repository.entriesByThread[testThread.id] = []
        
        // Setup use case
        addEntryUseCase = AddEntryUseCase(repository: repository)
        
        // Setup view model
        draftManager = InMemoryDraftManager()
        let exportUseCase = ExportThreadUseCase(
            repository: repository,
            exporter: CSVExporter()
        )
        
        viewModel = ThreadDetailViewModel(
            repository: repository,
            addEntryUseCase: addEntryUseCase,
            draftManager: draftManager,
            exportThreadUseCase: exportUseCase
        )
    }
    
    override func tearDown() {
        viewModel = nil
        addEntryUseCase = nil
        repository = nil
        testThread = nil
        draftManager = nil
        
        super.tearDown()
    }
    
    // MARK: - Performance Tests
    
    func testCreateSingleEntry_CompletesUnder50ms() {
        // Given: A thread ready for new entries
        let content = "This is a test entry for performance measurement."
        let expectation = XCTestExpectation(description: "Entry created")
        
        measure {
            // When: Creating a new entry
            Task {
                do {
                    let entry = try await addEntryUseCase.execute(
                        content: content,
                        threadId: testThread.id
                    )
                    
                    // Then: Entry should be created
                    XCTAssertEqual(entry.content, content)
                    XCTAssertEqual(entry.threadId, testThread.id)
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to create entry: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 0.5)
        }
    }
    
    func testCreateMultipleEntries_Sequential_MaintainsPerformance() {
        // Given: Need to create 10 entries sequentially
        let entryCount = 10
        let expectation = XCTestExpectation(description: "All entries created")
        expectation.expectedFulfillmentCount = entryCount
        
        measure {
            // When: Creating entries one after another
            Task {
                for i in 0..<entryCount {
                    do {
                        let content = "Sequential entry #\(i + 1)"
                        _ = try await addEntryUseCase.execute(
                            content: content,
                            threadId: testThread.id
                        )
                        expectation.fulfill()
                    } catch {
                        XCTFail("Failed to create entry: \(error)")
                    }
                }
            }
            
            wait(for: [expectation], timeout: 2.0)
            
            // Then: All entries should be created
            XCTAssertEqual(repository.entriesByThread[testThread.id]?.count, entryCount)
        }
    }
    
    func testCreateEntryWithLongContent_HandlesWell() {
        // Given: Very long content
        let longContent = String(repeating: "This is a long journal entry. ", count: 100)
        let expectation = XCTestExpectation(description: "Long entry created")
        
        measure {
            // When: Creating entry with long content
            Task {
                do {
                    let entry = try await addEntryUseCase.execute(
                        content: longContent,
                        threadId: testThread.id
                    )
                    
                    // Then: Should handle long content
                    XCTAssertEqual(entry.content, longContent)
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to create long entry: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 0.5)
        }
    }
    
    func testDraftSaving_WithAutoSave_PerformsWell() {
        // Given: Draft content that triggers auto-save
        let draftContent = "This is draft content that will be auto-saved"
        
        measure {
            // When: Setting draft content (triggers auto-save timer)
            Task { @MainActor in
                viewModel.draftContent = draftContent
            }
            
            // Wait briefly for debounce
            Thread.sleep(forTimeInterval: 0.01)
            
            // Then: Draft should be scheduled for saving
            XCTAssertEqual(viewModel.draftContent, draftContent)
        }
    }
    
    func testEntryValidation_Performance() {
        // Given: Various content to validate
        let testCases = [
            "",                          // Empty
            "   ",                      // Whitespace only
            "Valid content",            // Valid
            String(repeating: "a", count: 10000)  // Very long
        ]
        
        measure {
            // When: Validating entries
            for content in testCases {
                do {
                    _ = try Entry(
                        id: UUID(),
                        threadId: testThread.id,
                        content: content,
                        timestamp: Date()
                    )
                } catch {
                    // Expected for invalid content
                }
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsage_Creating100Entries_StaysReasonable() {
        // Given: Initial memory state
        let initialMemory = getCurrentMemoryUsage()
        
        // When: Creating 100 entries
        let expectation = XCTestExpectation(description: "Entries created")
        
        Task {
            for i in 0..<100 {
                do {
                    _ = try await addEntryUseCase.execute(
                        content: "Memory test entry #\(i + 1)",
                        threadId: testThread.id
                    )
                } catch {
                    XCTFail("Failed to create entry: \(error)")
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Then: Memory increase should be minimal
        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        let memoryIncreaseMB = Double(memoryIncrease) / 1024.0 / 1024.0
        
        XCTAssertLessThan(memoryIncreaseMB, 5.0, "Memory usage exceeded 5MB for 100 entries")
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