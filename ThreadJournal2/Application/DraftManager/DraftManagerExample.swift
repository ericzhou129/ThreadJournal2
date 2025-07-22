//
//  DraftManagerExample.swift
//  ThreadJournal2
//
//  Created on 1/19/25.
//

import Foundation

/// Example usage of DraftManager for documentation and testing
struct DraftManagerExample {
    
    static func demonstrateUsage() {
        // Create draft manager instance
        let draftManager = InMemoryDraftManager()
        
        // Example thread IDs
        let threadId1 = UUID()
        let threadId2 = UUID()
        
        // Set up auto-save handler
        draftManager.onAutoSave = { threadId, content in
            print("Auto-saving draft for thread \(threadId): '\(content)'")
            // In real app, this would persist to Core Data
        }
        
        // Example 1: Basic draft save and retrieve
        draftManager.saveDraft("Starting my journal entry...", for: threadId1)
        if let draft = draftManager.getDraft(for: threadId1) {
            print("Retrieved draft: \(draft)")
        }
        
        // Example 2: Multiple threads
        draftManager.saveDraft("Thread 1 content", for: threadId1)
        draftManager.saveDraft("Thread 2 content", for: threadId2)
        
        // Example 3: Clear draft after successful save
        draftManager.clearDraft(for: threadId1)
        print("Draft for thread 1 exists: \(draftManager.hasDraft(for: threadId1))")
        
        // Example 4: Simulate typing with updates
        let typingSimulation = [
            "I",
            "I am",
            "I am writing",
            "I am writing in",
            "I am writing in my",
            "I am writing in my journal"
        ]
        
        for text in typingSimulation {
            draftManager.saveDraft(text, for: threadId2)
            // Debouncing will prevent immediate saves
        }
    }
    
    /// Example integration with a view model
    static func viewModelIntegration() {
        class ExampleViewModel {
            private let draftManager: DraftManager
            private let threadId: UUID
            
            init(draftManager: DraftManager, threadId: UUID) {
                self.draftManager = draftManager
                self.threadId = threadId
            }
            
            func userTyping(_ text: String) {
                // Save draft as user types
                draftManager.saveDraft(text, for: threadId)
            }
            
            func loadExistingDraft() -> String? {
                return draftManager.getDraft(for: threadId)
            }
            
            func entrySuccessfullySaved() {
                // Clear draft after successful save
                draftManager.clearDraft(for: threadId)
            }
        }
    }
}