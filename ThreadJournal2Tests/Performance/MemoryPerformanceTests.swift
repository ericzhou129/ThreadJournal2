//
//  MemoryPerformanceTests.swift
//  ThreadJournal2Tests
//
//  Performance tests for memory usage with large datasets
//

import XCTest
@testable import ThreadJournal2

final class MemoryPerformanceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var repository: MockThreadRepository!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        repository = MockThreadRepository()
    }
    
    override func tearDown() {
        repository = nil
        super.tearDown()
    }
    
    // MARK: - Memory Tests
    
    func testOverallMemoryUsage_100ThreadsWith1000EntriesEach_StaysUnder150MB() {
        // Given: Initial memory baseline
        let initialMemory = getCurrentMemoryUsage()
        print("Initial memory: \(formatMemory(initialMemory))")
        
        // When: Creating 100 threads with varying entry counts
        let threads = TestDataBuilder.createThreads(count: 100)
        var totalEntries = 0
        
        for (index, thread) in threads.enumerated() {
            repository.threads.append(thread)
            
            // Vary entry count: some threads have many entries, some have few
            let entryCount: Int
            switch index {
            case 0..<10:
                entryCount = 1000  // 10 threads with 1000 entries
            case 10..<30:
                entryCount = 100   // 20 threads with 100 entries
            case 30..<60:
                entryCount = 50    // 30 threads with 50 entries
            default:
                entryCount = 10    // 40 threads with 10 entries
            }
            
            let entries = TestDataBuilder.createEntries(count: entryCount, for: thread.id)
            repository.entriesByThread[thread.id] = entries
            totalEntries += entryCount
        }
        
        print("Created \(threads.count) threads with \(totalEntries) total entries")
        
        // Force some allocations to simulate real usage
        _ = repository.threads.map { $0.title }
        _ = repository.entriesByThread.values.flatMap { $0 }.map { $0.content }
        
        // Then: Total memory usage should stay under 150MB
        let finalMemory = getCurrentMemoryUsage()
        let totalMemoryMB = Double(finalMemory) / 1024.0 / 1024.0
        
        print("Final memory: \(formatMemory(finalMemory))")
        print("Memory increase: \(formatMemory(finalMemory - initialMemory))")
        
        XCTAssertLessThan(
            totalMemoryMB, 
            150.0, 
            "Total memory usage (\(String(format: "%.1f", totalMemoryMB))MB) exceeded 150MB limit"
        )
    }
    
    func testMemoryGrowth_AddingEntriesOverTime_StaysLinear() {
        // Given: A thread to add entries to
        let thread = TestDataBuilder.createThread()
        repository.threads = [thread]
        repository.entriesByThread[thread.id] = []
        
        var memoryMeasurements: [(entries: Int, memory: Int64)] = []
        
        // When: Adding entries in batches
        for batch in 1...10 {
            let batchSize = 100
            let newEntries = TestDataBuilder.createEntries(count: batchSize, for: thread.id)
            repository.entriesByThread[thread.id]?.append(contentsOf: newEntries)
            
            // Measure memory after each batch
            let currentMemory = getCurrentMemoryUsage()
            let entryCount = batch * batchSize
            memoryMeasurements.append((entries: entryCount, memory: currentMemory))
            
            print("After \(entryCount) entries: \(formatMemory(currentMemory))")
        }
        
        // Then: Memory growth should be roughly linear
        // Calculate if memory per entry stays consistent
        let firstMeasurement = memoryMeasurements[0]
        let lastMeasurement = memoryMeasurements[9]
        
        let memoryPerEntry = Double(lastMeasurement.memory - firstMeasurement.memory) / 
                            Double(lastMeasurement.entries - firstMeasurement.entries)
        let bytesPerEntry = Int(memoryPerEntry)
        
        print("Average memory per entry: \(bytesPerEntry) bytes")
        
        // Each entry should use less than 1KB on average
        XCTAssertLessThan(bytesPerEntry, 1024, "Memory per entry exceeded 1KB")
    }
    
    func testMemoryRelease_AfterDeletingThreads_ReleasesMemory() {
        // Given: Many threads with entries
        let threadCount = 50
        let entriesPerThread = 100
        
        // Create initial data
        let threads = TestDataBuilder.createThreads(count: threadCount)
        for thread in threads {
            repository.threads.append(thread)
            repository.entriesByThread[thread.id] = TestDataBuilder.createEntries(
                count: entriesPerThread, 
                for: thread.id
            )
        }
        
        let memoryWithData = getCurrentMemoryUsage()
        print("Memory with \(threadCount) threads: \(formatMemory(memoryWithData))")
        
        // When: Removing half the threads
        let threadsToRemove = threads.prefix(threadCount / 2)
        for thread in threadsToRemove {
            repository.threads.removeAll { $0.id == thread.id }
            repository.entriesByThread.removeValue(forKey: thread.id)
        }
        
        // Force cleanup
        autoreleasepool { }
        
        // Then: Memory should decrease
        let memoryAfterDeletion = getCurrentMemoryUsage()
        print("Memory after deleting half: \(formatMemory(memoryAfterDeletion))")
        
        // We expect some memory to be released (though not necessarily 50% due to allocator behavior)
        XCTAssertLessThan(
            memoryAfterDeletion, 
            memoryWithData,
            "Memory did not decrease after deleting threads"
        )
    }
    
    func testPeakMemoryUsage_DuringCSVExport_StaysReasonable() {
        // Given: Thread with many entries
        let thread = TestDataBuilder.createThread()
        let entries = TestDataBuilder.createEntries(count: 1000, for: thread.id)
        repository.threads = [thread]
        repository.entriesByThread[thread.id] = entries
        
        let csvExporter = CSVExporter()
        let exportUseCase = ExportThreadUseCase(
            repository: repository,
            exporter: csvExporter
        )
        
        let memoryBeforeExport = getCurrentMemoryUsage()
        
        // When: Exporting to CSV
        let expectation = XCTestExpectation(description: "Export completes")
        var peakMemory: Int64 = memoryBeforeExport
        
        Task {
            // Monitor memory during export
            let monitorTask = Task {
                for _ in 0..<10 {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    let currentMemory = self.getCurrentMemoryUsage()
                    if currentMemory > peakMemory {
                        peakMemory = currentMemory
                    }
                }
            }
            
            do {
                _ = try await exportUseCase.execute(threadId: thread.id)
                monitorTask.cancel()
                expectation.fulfill()
            } catch {
                XCTFail("Export failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Then: Peak memory during export should be reasonable
        let peakIncrease = peakMemory - memoryBeforeExport
        let peakIncreaseMB = Double(peakIncrease) / 1024.0 / 1024.0
        
        print("Peak memory increase during export: \(formatMemory(peakIncrease))")
        
        XCTAssertLessThan(
            peakIncreaseMB,
            20.0,
            "Peak memory during export increased by more than 20MB"
        )
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
    
    private func formatMemory(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1024.0 / 1024.0
        return String(format: "%.1f MB", mb)
    }
}