//
//  PersistenceController.swift
//  ThreadJournal2
//
//  Manages Core Data stack and provides repository instances
//

import CoreData

/// Manages the Core Data stack and provides access to repositories
final class PersistenceController {
    static let shared = PersistenceController()
    
    /// Preview instance for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Add sample data for previews
        let viewContext = controller.container.viewContext
        do {
            // Create sample thread
            let thread = try Thread(title: "Sample Thread")
            let repository = controller.makeThreadRepository()
            
            Task {
                try await repository.create(thread: thread)
                
                // Add sample entries
                let entry1 = try Entry(threadId: thread.id, content: "First sample entry")
                let entry2 = try Entry(threadId: thread.id, content: "Second sample entry with more content")
                
                try await repository.addEntry(entry1, to: thread.id)
                try await repository.addEntry(entry2, to: thread.id)
            }
        } catch {
            // Preview data creation failed, but continue
            print("Failed to create preview data: \(error)")
        }
        
        return controller
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ThreadDataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // In production, this error should be handled appropriately
                // For now, we'll crash as this is a programming error
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /// Creates a new thread repository instance
    func makeThreadRepository() -> ThreadRepository {
        return CoreDataThreadRepository(persistentContainer: container)
    }
}