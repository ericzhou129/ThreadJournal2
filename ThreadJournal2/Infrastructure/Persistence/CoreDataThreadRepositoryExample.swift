//
//  CoreDataThreadRepositoryExample.swift
//  ThreadJournal2
//
//  Example usage of CoreDataThreadRepository
//

import Foundation

/// Example demonstrating how to use CoreDataThreadRepository
class CoreDataThreadRepositoryExample {
    private let repository: ThreadRepository
    
    init() {
        // In production, inject the repository through dependency injection
        self.repository = PersistenceController.shared.makeThreadRepository()
    }
    
    /// Example: Creating a new thread with entries
    func createThreadWithEntries() async {
        do {
            // Create a new thread
            let thread = try Thread(title: "My Development Journal")
            try await repository.create(thread: thread)
            print("Created thread: \(thread.title)")
            
            // Add entries to the thread
            let entry1 = try Entry(
                threadId: thread.id,
                content: "Started working on the persistence layer today. Using Core Data for local storage."
            )
            try await repository.addEntry(entry1, to: thread.id)
            
            let entry2 = try Entry(
                threadId: thread.id,
                content: "Implemented retry logic for save operations. Testing shows good resilience."
            )
            try await repository.addEntry(entry2, to: thread.id)
            
            print("Added \(2) entries to the thread")
            
        } catch ValidationError.emptyTitle {
            print("Error: Thread title cannot be empty")
        } catch ValidationError.emptyContent {
            print("Error: Entry content cannot be empty")
        } catch let error as PersistenceError {
            print("Persistence error: \(error.localizedDescription)")
        } catch {
            print("Unexpected error: \(error)")
        }
    }
    
    /// Example: Fetching and displaying all threads
    func displayAllThreads() async {
        do {
            let threads = try await repository.fetchAll()
            
            print("\nAll Threads (\(threads.count) total):")
            for thread in threads {
                print("- \(thread.title) (Updated: \(thread.updatedAt))")
                
                // Fetch entries for each thread
                let entries = try await repository.fetchEntries(for: thread.id)
                print("  Entries: \(entries.count)")
            }
        } catch {
            print("Error fetching threads: \(error)")
        }
    }
    
    /// Example: Updating a thread
    func updateThreadTitle(threadId: UUID, newTitle: String) async {
        do {
            // Fetch the existing thread
            guard let existingThread = try await repository.fetch(threadId: threadId) else {
                print("Thread not found")
                return
            }
            
            // Create updated thread with new title
            let updatedThread = try Thread(
                id: existingThread.id,
                title: newTitle,
                createdAt: existingThread.createdAt,
                updatedAt: Date()
            )
            
            try await repository.update(thread: updatedThread)
            print("Updated thread title to: \(newTitle)")
            
        } catch PersistenceError.notFound {
            print("Thread not found")
        } catch ValidationError.emptyTitle {
            print("Error: New title cannot be empty")
        } catch {
            print("Error updating thread: \(error)")
        }
    }
    
    /// Example: Handling errors with retry
    func demonstrateErrorHandling() async {
        do {
            // Try to update a non-existent thread
            let nonExistentThread = try Thread(
                id: UUID(),
                title: "This thread doesn't exist"
            )
            
            try await repository.update(thread: nonExistentThread)
            
        } catch PersistenceError.notFound(let id) {
            print("Thread with ID \(id) not found - this is expected")
        } catch {
            print("Unexpected error: \(error)")
        }
        
        // Demonstrate validation error
        do {
            let invalidThread = try Thread(title: "   ") // Empty after trimming
            try await repository.create(thread: invalidThread)
        } catch ValidationError.emptyTitle {
            print("Validation error caught - empty title not allowed")
        } catch {
            print("Unexpected error: \(error)")
        }
    }
    
    /// Example: Deleting a thread and its entries
    func deleteThread(threadId: UUID) async {
        do {
            // Check if thread exists first
            guard let thread = try await repository.fetch(threadId: threadId) else {
                print("Thread not found")
                return
            }
            
            // Get entry count before deletion
            let entries = try await repository.fetchEntries(for: threadId)
            print("Deleting thread '\(thread.title)' with \(entries.count) entries")
            
            // Delete the thread (entries will be cascade deleted)
            try await repository.delete(threadId: threadId)
            print("Thread and all entries deleted successfully")
            
        } catch PersistenceError.notFound {
            print("Thread not found")
        } catch {
            print("Error deleting thread: \(error)")
        }
    }
}