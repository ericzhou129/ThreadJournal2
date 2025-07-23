//
//  TestDataBuilder.swift
//  ThreadJournal2Tests
//
//  Factory for creating test data for performance tests
//

import Foundation
@testable import ThreadJournal2

/// Factory for creating test data following the builder pattern
final class TestDataBuilder {
    
    // MARK: - Thread Creation
    
    /// Creates multiple threads with varying entry counts
    /// - Parameter count: Number of threads to create
    /// - Returns: Array of test threads
    static func createThreads(count: Int) -> [Thread] {
        (0..<count).map { index in
            try! Thread(
                id: UUID(),
                title: "Test Thread \(index + 1)",
                createdAt: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                updatedAt: Date().addingTimeInterval(TimeInterval(-index * 1800))
            )
        }
    }
    
    /// Creates a single thread with specific properties
    /// - Parameters:
    ///   - title: Thread title
    ///   - createdAt: Creation date
    /// - Returns: A test thread
    static func createThread(
        title: String = "Test Thread",
        createdAt: Date = Date()
    ) -> Thread {
        try! Thread(
            id: UUID(),
            title: title,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
    
    // MARK: - Entry Creation
    
    /// Creates multiple entries for a thread
    /// - Parameters:
    ///   - count: Number of entries to create
    ///   - threadId: ID of the thread these entries belong to
    /// - Returns: Array of test entries
    static func createEntries(count: Int, for threadId: UUID) -> [Entry] {
        (0..<count).map { index in
            try! Entry(
                id: UUID(),
                threadId: threadId,
                content: generateEntryContent(index: index),
                timestamp: Date().addingTimeInterval(TimeInterval(-index * 60))
            )
        }
    }
    
    /// Creates a single entry with specific content
    /// - Parameters:
    ///   - content: Entry content
    ///   - threadId: ID of the thread this entry belongs to
    ///   - timestamp: Entry timestamp
    /// - Returns: A test entry
    static func createEntry(
        content: String = "Test entry content",
        for threadId: UUID,
        timestamp: Date = Date()
    ) -> Entry {
        try! Entry(
            id: UUID(),
            threadId: threadId,
            content: content,
            timestamp: timestamp
        )
    }
    
    // MARK: - Content Generation
    
    /// Generates realistic entry content of varying lengths
    /// - Parameter index: Index for varying content
    /// - Returns: Entry content string
    private static func generateEntryContent(index: Int) -> String {
        let templates = [
            "Today I'm grateful for the beautiful weather and the opportunity to spend time outdoors.",
            "I had an amazing conversation with a friend that reminded me of the importance of deep connections.",
            "Work was challenging today, but I learned something new about problem-solving and perseverance.",
            "I'm thankful for my health and the ability to move my body. The morning walk was refreshing.",
            "Reading a good book tonight reminded me why I love getting lost in stories and learning new perspectives.",
            "Cooking dinner with family was a simple joy that brought us together. These moments matter most.",
            "I'm grateful for the technology that allows me to stay connected with loved ones far away.",
            "Today's meditation practice helped me find clarity and peace in the midst of a busy schedule.",
            "The sunset tonight was breathtaking. Sometimes nature provides the best reminders to slow down.",
            "I'm appreciative of the challenges I faced today, as they helped me grow stronger and more resilient."
        ]
        
        return templates[index % templates.count] + " (Entry #\(index + 1))"
    }
    
    // MARK: - Complex Scenarios
    
    /// Creates a complete test scenario with threads and entries
    /// - Parameters:
    ///   - threadCount: Number of threads
    ///   - entriesPerThread: Number of entries per thread
    /// - Returns: Tuple of threads and entries
    static func createCompleteScenario(
        threadCount: Int,
        entriesPerThread: Int
    ) -> (threads: [Thread], entriesByThread: [UUID: [Entry]]) {
        let threads = createThreads(count: threadCount)
        var entriesByThread: [UUID: [Entry]] = [:]
        
        for thread in threads {
            entriesByThread[thread.id] = createEntries(
                count: entriesPerThread,
                for: thread.id
            )
        }
        
        return (threads, entriesByThread)
    }
    
    /// Creates a thread with specific entry distribution for testing
    /// - Parameters:
    ///   - entryDistribution: Array of entry counts per day
    /// - Returns: Thread with entries distributed over days
    static func createThreadWithDistribution(
        entryDistribution: [Int]
    ) -> (thread: Thread, entries: [Entry]) {
        let thread = createThread()
        var allEntries: [Entry] = []
        
        for (dayIndex, entryCount) in entryDistribution.enumerated() {
            let dayOffset = TimeInterval(-dayIndex * 86400) // Days in seconds
            
            for entryIndex in 0..<entryCount {
                let timestamp = Date()
                    .addingTimeInterval(dayOffset)
                    .addingTimeInterval(TimeInterval(-entryIndex * 3600)) // Hours
                
                let entry = try! Entry(
                    id: UUID(),
                    threadId: thread.id,
                    content: generateEntryContent(index: allEntries.count),
                    timestamp: timestamp
                )
                allEntries.append(entry)
            }
        }
        
        return (thread, allEntries)
    }
}

// MARK: - Performance Test Helpers

extension TestDataBuilder {
    
    /// Creates data for thread list performance testing
    /// - Returns: Array of 100 threads
    static func createThreadListTestData() -> [Thread] {
        createThreads(count: 100)
    }
    
    /// Creates data for thread detail performance testing
    /// - Returns: Thread with 1000 entries
    static func createThreadDetailTestData() -> (thread: Thread, entries: [Entry]) {
        let thread = createThread(title: "Performance Test Thread")
        let entries = createEntries(count: 1000, for: thread.id)
        return (thread, entries)
    }
    
    /// Creates data for CSV export performance testing
    /// - Returns: Thread with 1000 entries containing varied content
    static func createCSVExportTestData() -> (thread: Thread, entries: [Entry]) {
        let thread = createThread(title: "CSV Export Test")
        let entries = (0..<1000).map { index in
            let content = generateEntryContent(index: index)
            // Add some entries with special characters for CSV escaping
            let testContent = index % 10 == 0 
                ? content + ", with \"quotes\" and\nnewlines" 
                : content
                
            return try! Entry(
                id: UUID(),
                threadId: thread.id,
                content: testContent,
                timestamp: Date().addingTimeInterval(TimeInterval(-index * 60))
            )
        }
        return (thread, entries)
    }
}