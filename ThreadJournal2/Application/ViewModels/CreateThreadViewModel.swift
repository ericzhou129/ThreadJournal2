//
//  CreateThreadViewModel.swift
//  ThreadJournal2
//
//  View model for creating new threads
//

import Foundation

/// View model for the new thread creation screen
@MainActor
final class CreateThreadViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// The thread title entered by the user
    @Published var threadTitle: String = ""
    
    /// The optional first entry content
    @Published var firstEntryContent: String = ""
    
    /// Whether the view model is currently creating a thread
    @Published private(set) var isCreating: Bool = false
    
    /// Error message if creation fails
    @Published var errorMessage: String?
    
    /// The created thread, set after successful creation
    @Published private(set) var createdThread: Thread?
    
    // MARK: - Computed Properties
    
    /// Whether the create button should be enabled
    var isCreateButtonEnabled: Bool {
        !threadTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isCreating
    }
    
    /// Whether there's an error to display
    var hasError: Bool {
        errorMessage != nil
    }
    
    // MARK: - Dependencies
    
    private let createThreadUseCase: CreateThreadUseCase
    private let draftManager: DraftManager
    
    // MARK: - Private Properties
    
    /// Timer for debouncing draft saves
    private var draftSaveTimer: Timer?
    
    /// Special draft ID for new threads
    private let newThreadDraftId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    
    // MARK: - Initialization
    
    /// Initializes the view model with required dependencies
    /// - Parameters:
    ///   - createThreadUseCase: Use case for creating new threads
    ///   - draftManager: Manager for handling drafts
    init(createThreadUseCase: CreateThreadUseCase, draftManager: DraftManager) {
        self.createThreadUseCase = createThreadUseCase
        self.draftManager = draftManager
        
        // Load any existing draft
        loadDraft()
    }
    
    // MARK: - Public Methods
    
    /// Creates a new thread with the current title and optional first entry
    func createThread() async {
        guard isCreateButtonEnabled else { return }
        
        isCreating = true
        errorMessage = nil
        
        do {
            // Trim whitespace from title
            let trimmedTitle = threadTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedEntry = firstEntryContent.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Create the thread
            let thread = try await createThreadUseCase.execute(
                title: trimmedTitle,
                firstEntry: trimmedEntry.isEmpty ? nil : trimmedEntry
            )
            
            // Clear draft after successful creation
            draftManager.clearDraft(for: newThreadDraftId)
            
            // Set the created thread
            createdThread = thread
            
        } catch {
            errorMessage = error.localizedDescription
            isCreating = false
        }
    }
    
    /// Called when the title text changes
    func onTitleChange() {
        // Clear error when user starts typing
        if errorMessage != nil {
            errorMessage = nil
        }
        
        // Debounce draft save
        scheduleDraftSave()
    }
    
    /// Called when the first entry content changes
    func onFirstEntryChange() {
        // Debounce draft save
        scheduleDraftSave()
    }
    
    /// Clears the current draft
    func clearDraft() {
        threadTitle = ""
        firstEntryContent = ""
        draftManager.clearDraft(for: newThreadDraftId)
        draftSaveTimer?.invalidate()
    }
    
    // MARK: - Private Methods
    
    /// Loads any existing draft
    private func loadDraft() {
        if let draftContent = draftManager.getDraft(for: newThreadDraftId) {
            // Parse draft content (format: "title|||firstEntry")
            let components = draftContent.components(separatedBy: "|||")
            if components.count >= 1 {
                threadTitle = components[0]
            }
            if components.count >= 2 {
                firstEntryContent = components[1]
            }
        }
    }
    
    /// Schedules a draft save with debouncing
    private func scheduleDraftSave() {
        // Cancel existing timer
        draftSaveTimer?.invalidate()
        
        // Schedule new save after 2 seconds
        draftSaveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.saveDraft()
            }
        }
    }
    
    /// Saves the current draft
    private func saveDraft() {
        let draftContent = "\(threadTitle)||||\(firstEntryContent)"
        draftManager.saveDraft(draftContent, for: newThreadDraftId)
    }
    
    deinit {
        draftSaveTimer?.invalidate()
    }
}