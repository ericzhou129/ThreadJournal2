//
//  ThreadDetailViewModel.swift
//  ThreadJournal2
//
//  View model for the thread detail screen handling entries, drafts, and auto-save
//

import Foundation
import SwiftUI

/// View model managing thread detail display, entry creation, and draft auto-save
@MainActor
final class ThreadDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The current thread being displayed
    @Published private(set) var thread: Thread?
    
    /// All entries for the current thread, sorted chronologically (oldest first)
    @Published private(set) var entries: [Entry] = []
    
    /// Loading state for initial thread/entries fetch
    @Published private(set) var isLoading = false
    
    /// Current draft content being typed
    @Published var draftContent = "" {
        didSet {
            if draftContent != oldValue {
                scheduleDraftSave()
            }
        }
    }
    
    /// Indicates if a draft is currently being saved
    @Published private(set) var isSavingDraft = false
    
    /// Indicates if the last save attempt failed
    @Published private(set) var hasFailedSave = false
    
    /// Error message from the last failed save
    @Published private(set) var saveError: String?
    
    /// Flag indicating if UI should scroll to latest entry
    @Published private(set) var shouldScrollToLatest = false
    
    /// Export state
    @Published private(set) var isExporting = false
    @Published var exportError: String?
    @Published private(set) var exportedFileURL: URL?
    
    // MARK: - Draft State Machine
    
    /// Current state of the draft
    enum DraftState: Equatable {
        case empty
        case typing
        case saving
        case saved
        case failed(error: Error)
        
        static func == (lhs: DraftState, rhs: DraftState) -> Bool {
            switch (lhs, rhs) {
            case (.empty, .empty),
                 (.typing, .typing),
                 (.saving, .saving),
                 (.saved, .saved):
                return true
            case (.failed, .failed):
                return true // Consider all failures equal for state comparison
            default:
                return false
            }
        }
    }
    
    @Published private(set) var draftState: DraftState = .empty
    
    // MARK: - Private Properties
    
    private let repository: ThreadRepository
    private let addEntryUseCase: AddEntryUseCase
    private let draftManager: DraftManager
    private let exportThreadUseCase: ExportThreadUseCase
    
    /// Current thread ID being displayed
    private var currentThreadId: UUID?
    
    /// Number of retry attempts for save failures
    private var retryCount = 0
    private let maxRetryAttempts = 3
    
    /// Timer for triggering draft saves
    private var draftSaveTimer: Timer?
    
    // MARK: - Initialization
    
    /// Initializes the view model with required dependencies
    /// - Parameters:
    ///   - repository: Thread repository for data access
    ///   - addEntryUseCase: Use case for adding entries
    ///   - draftManager: Manager for draft auto-save functionality
    ///   - exportThreadUseCase: Use case for exporting threads to CSV
    init(
        repository: ThreadRepository,
        addEntryUseCase: AddEntryUseCase,
        draftManager: DraftManager,
        exportThreadUseCase: ExportThreadUseCase
    ) {
        self.repository = repository
        self.addEntryUseCase = addEntryUseCase
        self.draftManager = draftManager
        self.exportThreadUseCase = exportThreadUseCase
        
        // Configure draft manager auto-save callback
        if let inMemoryDraftManager = draftManager as? InMemoryDraftManager {
            inMemoryDraftManager.onAutoSave = { [weak self] threadId, content in
                Task { @MainActor [weak self] in
                    await self?.performDraftAutoSave(threadId: threadId, content: content)
                }
            }
        }
    }
    
    deinit {
        draftSaveTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Loads a thread and its entries
    /// - Parameter threadId: The ID of the thread to load
    func loadThread(id threadId: UUID) async {
        isLoading = true
        currentThreadId = threadId
        
        do {
            // Fetch thread
            guard let fetchedThread = try await repository.fetch(threadId: threadId) else {
                throw PersistenceError.notFound(id: threadId)
            }
            
            thread = fetchedThread
            
            // Fetch entries
            entries = try await repository.fetchEntries(for: threadId)
            
            // Check for existing draft
            if let existingDraft = draftManager.getDraft(for: threadId) {
                draftContent = existingDraft
                draftState = .typing
            } else {
                draftContent = ""
                draftState = .empty
            }
            
            // Set scroll flag
            shouldScrollToLatest = true
            
            // Reset after brief delay to allow UI to use it
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                shouldScrollToLatest = false
            }
            
        } catch {
            // Handle error - could show alert
            print("Failed to load thread: \(error)")
        }
        
        isLoading = false
    }
    
    /// Adds a new entry to the current thread
    /// - Parameter content: The content of the entry
    func addEntry() async {
        guard let threadId = currentThreadId,
              !draftContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let content = draftContent
        
        do {
            // Add entry via use case
            let newEntry = try await addEntryUseCase.execute(
                content: content,
                threadId: threadId
            )
            
            // Update local entries
            entries.append(newEntry)
            
            // Clear draft on success
            draftContent = ""
            draftState = .empty
            draftManager.clearDraft(for: threadId)
            
            // Reset retry count
            retryCount = 0
            hasFailedSave = false
            saveError = nil
            
            // Update thread's updatedAt locally
            if let currentThread = thread {
                thread = try? Thread(
                    id: currentThread.id,
                    title: currentThread.title,
                    createdAt: currentThread.createdAt,
                    updatedAt: Date()
                )
            }
            
            // Trigger scroll to latest
            shouldScrollToLatest = true
            
        } catch {
            // Keep draft on failure
            hasFailedSave = true
            saveError = error.localizedDescription
            draftState = .failed(error: error)
        }
    }
    
    /// Manually triggers a retry of the failed save
    func retrySave() async {
        guard hasFailedSave, retryCount < maxRetryAttempts else { return }
        
        retryCount += 1
        hasFailedSave = false
        await addEntry()
    }
    
    /// Exports the current thread to CSV format
    func exportToCSV() async {
        guard let threadId = currentThreadId else { return }
        
        isExporting = true
        exportError = nil
        exportedFileURL = nil
        
        do {
            // Export using the use case
            let exportData = try await exportThreadUseCase.execute(threadId: threadId)
            
            // Save to temporary directory
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileURL = tempDirectory.appendingPathComponent(exportData.fileName)
            
            // Write data to file
            try exportData.data.write(to: fileURL)
            
            // Set the exported file URL for the UI to present share sheet
            exportedFileURL = fileURL
            
        } catch {
            exportError = error.localizedDescription
        }
        
        isExporting = false
    }
    
    // MARK: - Private Methods
    
    /// Schedules a draft save after a delay
    private func scheduleDraftSave() {
        // Update state
        if !draftContent.isEmpty {
            draftState = .typing
        }
        
        // Cancel existing timer
        draftSaveTimer?.invalidate()
        
        // Don't save empty drafts
        guard !draftContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let threadId = currentThreadId else {
            draftState = .empty
            return
        }
        
        // Save to draft manager immediately (it will handle debouncing)
        draftManager.saveDraft(draftContent, for: threadId)
    }
    
    /// Performs auto-save triggered by draft manager
    private func performDraftAutoSave(threadId: UUID, content: String) async {
        // Only save if this is still the current thread
        guard threadId == currentThreadId else { return }
        
        isSavingDraft = true
        draftState = .saving
        
        // Simulate network save in future implementation
        // For now, just update state after brief delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        isSavingDraft = false
        draftState = .saved
        
        // Return to typing state after brief delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            if draftState == .saved && !draftContent.isEmpty {
                draftState = .typing
            }
        }
    }
}

// MARK: - State Helpers

extension ThreadDetailViewModel {
    /// Computed property for draft state description
    var draftStateDescription: String {
        switch draftState {
        case .empty:
            return ""
        case .typing:
            return "Draft"
        case .saving:
            return "Saving..."
        case .saved:
            return "Draft saved"
        case .failed:
            return "Save failed"
        }
    }
    
    /// Whether the send button should be enabled
    var canSendEntry: Bool {
        !draftContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isLoading
    }
}