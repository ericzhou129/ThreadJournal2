//
//  InMemoryDraftManager.swift
//  ThreadJournal2
//
//  Created on 1/19/25.
//

import Foundation

/// Protocol defining draft management operations
protocol DraftManager {
    /// Saves a draft for a specific thread
    /// - Parameters:
    ///   - content: The draft content to save
    ///   - threadId: The UUID of the thread this draft belongs to
    func saveDraft(_ content: String, for threadId: UUID)
    
    /// Retrieves a draft for a specific thread
    /// - Parameter threadId: The UUID of the thread
    /// - Returns: The draft content if available, nil otherwise
    func getDraft(for threadId: UUID) -> String?
    
    /// Clears a draft for a specific thread
    /// - Parameter threadId: The UUID of the thread
    func clearDraft(for threadId: UUID)
}

/// In-memory implementation of DraftManager with auto-save and debouncing
final class InMemoryDraftManager: DraftManager {
    
    // MARK: - Properties
    
    /// Dictionary storing drafts by thread ID
    private var drafts: [UUID: String] = [:]
    
    /// Timer for 30-second auto-save intervals
    private var autoSaveTimer: Timer?
    
    /// Timer for debouncing rapid changes
    private var debounceTimer: Timer?
    
    /// Queue for thread-safe access to drafts
    private let queue = DispatchQueue(label: "com.threadjournal.draftmanager", attributes: .concurrent)
    
    /// Tracks pending drafts that need to be saved
    private var pendingDrafts: Set<UUID> = []
    
    /// Debounce interval in seconds (waits after last keystroke)
    private let debounceInterval: TimeInterval
    
    /// Auto-save interval in seconds
    private let autoSaveInterval: TimeInterval
    
    /// Callback for when auto-save should persist drafts
    var onAutoSave: ((UUID, String) -> Void)?
    
    // MARK: - Initialization
    
    /// Initializes the draft manager with configurable intervals
    /// - Parameters:
    ///   - debounceInterval: Time to wait after last keystroke (default: 2 seconds)
    ///   - autoSaveInterval: Time between auto-saves (default: 30 seconds)
    init(debounceInterval: TimeInterval = 2.0,
         autoSaveInterval: TimeInterval = 30.0) {
        self.debounceInterval = debounceInterval
        self.autoSaveInterval = autoSaveInterval
        startAutoSaveTimer()
    }
    
    deinit {
        stopTimers()
    }
    
    // MARK: - DraftManager Protocol
    
    func saveDraft(_ content: String, for threadId: UUID) {
        queue.async(flags: .barrier) {
            self.drafts[threadId] = content
            self.pendingDrafts.insert(threadId)
            self.scheduleDebounce(for: threadId)
        }
    }
    
    func getDraft(for threadId: UUID) -> String? {
        queue.sync {
            drafts[threadId]
        }
    }
    
    func clearDraft(for threadId: UUID) {
        queue.async(flags: .barrier) {
            self.drafts.removeValue(forKey: threadId)
            self.pendingDrafts.remove(threadId)
        }
    }
    
    // MARK: - Private Methods
    
    /// Starts the 30-second auto-save timer
    private func startAutoSaveTimer() {
        autoSaveTimer = Timer.scheduledTimer(
            withTimeInterval: autoSaveInterval,
            repeats: true
        ) { [weak self] _ in
            self?.performAutoSave()
        }
    }
    
    /// Stops all timers
    private func stopTimers() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        debounceTimer?.invalidate()
        debounceTimer = nil
    }
    
    /// Schedules debounced save after typing stops
    private func scheduleDebounce(for threadId: UUID) {
        // Cancel existing debounce timer
        debounceTimer?.invalidate()
        
        // Schedule new debounce timer
        debounceTimer = Timer.scheduledTimer(
            withTimeInterval: debounceInterval,
            repeats: false
        ) { [weak self] _ in
            self?.performDebouncedSave(for: threadId)
        }
    }
    
    /// Performs auto-save for all pending drafts
    private func performAutoSave() {
        queue.async(flags: .barrier) {
            for threadId in self.pendingDrafts {
                if let content = self.drafts[threadId] {
                    self.onAutoSave?(threadId, content)
                }
            }
            // Clear pending after auto-save attempt
            self.pendingDrafts.removeAll()
        }
    }
    
    /// Performs debounced save for a specific thread
    private func performDebouncedSave(for threadId: UUID) {
        queue.async {
            if let content = self.drafts[threadId] {
                self.onAutoSave?(threadId, content)
                
                self.queue.async(flags: .barrier) {
                    self.pendingDrafts.remove(threadId)
                }
            }
        }
    }
}

// MARK: - Thread Safety Extension

extension InMemoryDraftManager {
    /// Retrieves all current drafts (for debugging/testing)
    func getAllDrafts() -> [UUID: String] {
        queue.sync {
            drafts
        }
    }
    
    /// Checks if a draft exists for a thread
    func hasDraft(for threadId: UUID) -> Bool {
        queue.sync {
            drafts[threadId] != nil
        }
    }
}