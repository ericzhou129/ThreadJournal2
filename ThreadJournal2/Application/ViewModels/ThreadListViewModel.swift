//
//  ThreadListViewModel.swift
//  ThreadJournal2
//
//  View model for the thread list UI, managing thread loading and creation
//

import Foundation

/// Loading states for the thread list
enum ThreadListLoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(Error)
    
    static func == (lhs: ThreadListLoadingState, rhs: ThreadListLoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.loaded, .loaded):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            // Compare error types and descriptions
            return type(of: lhsError) == type(of: rhsError) && 
                   lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

/// Thread with metadata for UI display
struct ThreadWithMetadata: Identifiable, Equatable {
    let thread: Thread
    let entryCount: Int
    
    var id: UUID { thread.id }
}

/// View model for the thread list screen
@MainActor
final class ThreadListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Array of threads with metadata sorted by most recently updated
    @Published private(set) var threadsWithMetadata: [ThreadWithMetadata] = []
    
    /// Current loading state
    @Published private(set) var loadingState: ThreadListLoadingState = .idle
    
    /// Thread to delete (shows confirmation dialog when set)
    @Published var threadToDelete: Thread?
    
    /// Whether to show the delete confirmation dialog
    @Published var showDeleteConfirmation: Bool = false
    
    /// Convenience property for checking if loading
    var isLoading: Bool {
        if case .loading = loadingState {
            return true
        }
        return false
    }
    
    /// Current error if any
    var error: Error? {
        if case .error(let error) = loadingState {
            return error
        }
        return nil
    }
    
    // MARK: - Dependencies
    
    let repository: ThreadRepository
    private let createThreadUseCase: CreateThreadUseCase
    private let deleteThreadUseCase: DeleteThreadUseCase
    
    // MARK: - Initialization
    
    /// Initializes the view model with required dependencies
    /// - Parameters:
    ///   - repository: Thread repository for fetching threads
    ///   - createThreadUseCase: Use case for creating new threads
    ///   - deleteThreadUseCase: Use case for deleting threads
    init(
        repository: ThreadRepository, 
        createThreadUseCase: CreateThreadUseCase,
        deleteThreadUseCase: DeleteThreadUseCase
    ) {
        self.repository = repository
        self.createThreadUseCase = createThreadUseCase
        self.deleteThreadUseCase = deleteThreadUseCase
    }
    
    // MARK: - Public Methods
    
    /// Loads all threads from the repository
    func loadThreads() {
        Task {
            loadingState = .loading
            
            do {
                // Fetch all threads (repository returns them sorted by updatedAt)
                let fetchedThreads = try await repository.fetchAll()
                
                // Fetch entry counts for each thread
                var threadsWithMeta: [ThreadWithMetadata] = []
                for thread in fetchedThreads {
                    let entries = try await repository.fetchEntries(for: thread.id)
                    let threadWithMeta = ThreadWithMetadata(
                        thread: thread,
                        entryCount: entries.count
                    )
                    threadsWithMeta.append(threadWithMeta)
                }
                
                // Update the threads array
                threadsWithMetadata = threadsWithMeta
                loadingState = .loaded
            } catch {
                loadingState = .error(error)
                // Keep existing threads in case of error
            }
        }
    }
    
    /// Creates a new thread with the given title and optional first entry
    /// - Parameters:
    ///   - title: The title for the new thread
    ///   - firstEntry: Optional first entry content to add to the thread
    /// - Returns: The created thread
    /// - Throws: ValidationError if title is empty, or PersistenceError if creation fails
    @discardableResult
    func createThread(title: String, firstEntry: String? = nil) async throws -> Thread {
        do {
            // Create the thread using the use case
            let newThread = try await createThreadUseCase.execute(
                title: title,
                firstEntry: firstEntry
            )
            
            // Reload threads to include the new one
            loadThreads()
            
            return newThread
        } catch {
            // Update state to show error
            loadingState = .error(error)
            throw error
        }
    }
    
    /// Shows confirmation dialog for deleting a thread
    /// - Parameter thread: The thread to potentially delete
    func confirmDeleteThread(_ thread: Thread) {
        threadToDelete = thread
        showDeleteConfirmation = true
    }
    
    /// Cancels the deletion process
    func cancelDelete() {
        threadToDelete = nil
        showDeleteConfirmation = false
    }
    
    /// Deletes the currently selected thread
    func deleteThread() async {
        guard let thread = threadToDelete else { return }
        
        // Hide the confirmation dialog
        showDeleteConfirmation = false
        
        do {
            // Perform the deletion
            try await deleteThreadUseCase.execute(threadId: thread.id)
            
            // Clear the selection
            threadToDelete = nil
            
            // Reload threads to reflect the deletion
            loadThreads()
        } catch {
            // Update state to show error
            loadingState = .error(error)
        }
    }
}