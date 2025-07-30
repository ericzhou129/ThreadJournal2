//
//  CoreDataThreadRepository.swift
//  ThreadJournal2
//
//  Core Data implementation of ThreadRepository protocol
//

import Foundation
import CoreData

/// Core Data implementation of the ThreadRepository protocol
final class CoreDataThreadRepository: ThreadRepository {
    private let persistentContainer: NSPersistentContainer
    private let maxRetryAttempts = 3
    
    /// Initializes the repository with a persistent container
    /// - Parameter persistentContainer: The Core Data persistent container
    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }
    
    // MARK: - Thread Operations
    
    func create(thread: Thread) async throws {
        let context = persistentContainer.viewContext
        
        try await performWithRetry { [weak self] in
            guard let self = self else { return }
            
            // Check if thread already exists
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Thread")
            fetchRequest.predicate = NSPredicate(format: "id == %@", thread.id as CVarArg)
            
            let results = try context.fetch(fetchRequest)
            guard results.isEmpty else {
                throw PersistenceError.saveFailed(underlying: NSError(
                    domain: "CoreDataThreadRepository",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "Thread with ID \(thread.id) already exists"]
                ))
            }
            
            // Create new managed object
            let managedThread = NSManagedObject(entity: NSEntityDescription.entity(forEntityName: "Thread", in: context)!,
                                               insertInto: context)
            
            // Map domain entity to managed object
            self.mapThreadToManagedObject(thread, managedThread: managedThread)
            
            // Save context
            try self.saveContext(context)
        }
    }
    
    func update(thread: Thread) async throws {
        let context = persistentContainer.viewContext
        
        try await performWithRetry { [weak self] in
            guard let self = self else { return }
            
            // Fetch existing thread
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Thread")
            fetchRequest.predicate = NSPredicate(format: "id == %@", thread.id as CVarArg)
            
            let results = try context.fetch(fetchRequest)
            guard let managedThread = results.first else {
                throw PersistenceError.notFound(id: thread.id)
            }
            
            // Update managed object
            self.mapThreadToManagedObject(thread, managedThread: managedThread)
            
            // Save context
            try self.saveContext(context)
        }
    }
    
    func delete(threadId: UUID) async throws {
        let context = persistentContainer.viewContext
        
        try await performWithRetry { [weak self] in
            guard let self = self else { return }
            
            // Fetch thread to delete
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Thread")
            fetchRequest.predicate = NSPredicate(format: "id == %@", threadId as CVarArg)
            
            let results = try context.fetch(fetchRequest)
            guard let managedThread = results.first else {
                throw PersistenceError.notFound(id: threadId)
            }
            
            // Delete thread (cascade will delete entries)
            context.delete(managedThread)
            
            // Save context
            try self.saveContext(context)
        }
    }
    
    func softDelete(threadId: UUID) async throws {
        let context = persistentContainer.viewContext
        
        try await performWithRetry { [weak self] in
            guard let self = self else { return }
            
            // Fetch thread to soft delete
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Thread")
            fetchRequest.predicate = NSPredicate(format: "id == %@", threadId as CVarArg)
            
            let results = try context.fetch(fetchRequest)
            guard let managedThread = results.first else {
                throw PersistenceError.notFound(id: threadId)
            }
            
            // Set deletedAt timestamp
            managedThread.setValue(Date(), forKey: "deletedAt")
            
            // Also soft delete all entries
            if let entries = managedThread.value(forKey: "entries") as? Set<NSManagedObject> {
                for entry in entries {
                    entry.setValue(Date(), forKey: "deletedAt")
                }
            }
            
            // Save context
            try self.saveContext(context)
        }
    }
    
    func fetch(threadId: UUID) async throws -> Thread? {
        let context = persistentContainer.viewContext
        
        return try await context.perform { [weak self] in
            guard let self = self else { return nil }
            
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Thread")
            fetchRequest.predicate = NSPredicate(format: "id == %@", threadId as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                guard let managedThread = results.first else { return nil }
                return try self.mapManagedObjectToThread(managedThread)
            } catch {
                throw PersistenceError.fetchFailed(underlying: error)
            }
        }
    }
    
    func fetchAll() async throws -> [Thread] {
        // Default to not including deleted threads
        return try await fetchAll(includeDeleted: false)
    }
    
    func fetchAll(includeDeleted: Bool) async throws -> [Thread] {
        let context = persistentContainer.viewContext
        
        return try await context.perform { [weak self] in
            guard let self = self else { return [] }
            
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Thread")
            
            // Filter out deleted threads unless specifically requested
            if !includeDeleted {
                fetchRequest.predicate = NSPredicate(format: "deletedAt == nil")
            }
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            do {
                let results = try context.fetch(fetchRequest)
                return try results.compactMap { try self.mapManagedObjectToThread($0) }
            } catch {
                throw PersistenceError.fetchFailed(underlying: error)
            }
        }
    }
    
    // MARK: - Entry Operations
    
    func addEntry(_ entry: Entry, to threadId: UUID) async throws {
        let context = persistentContainer.viewContext
        
        try await performWithRetry { [weak self] in
            guard let self = self else { return }
            
            // Fetch the thread
            let threadFetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Thread")
            threadFetchRequest.predicate = NSPredicate(format: "id == %@", threadId as CVarArg)
            
            let threadResults = try context.fetch(threadFetchRequest)
            guard let managedThread = threadResults.first else {
                throw PersistenceError.notFound(id: threadId)
            }
            
            // Create new entry
            let managedEntry = NSManagedObject(entity: NSEntityDescription.entity(forEntityName: "Entry", in: context)!,
                                              insertInto: context)
            
            // Map domain entity to managed object
            self.mapEntryToManagedObject(entry, managedEntry: managedEntry, managedThread: managedThread)
            
            // Update thread's updatedAt timestamp
            managedThread.setValue(Date(), forKey: "updatedAt")
            
            // Save context
            try self.saveContext(context)
        }
    }
    
    func fetchEntries(for threadId: UUID) async throws -> [Entry] {
        let context = persistentContainer.viewContext
        
        return try await context.perform { [weak self] in
            guard let self = self else { return [] }
            
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Entry")
            // Filter out soft-deleted entries (deletedAt == nil)
            let threadPredicate = NSPredicate(format: "threadId == %@", threadId as CVarArg)
            let notDeletedPredicate = NSPredicate(format: "deletedAt == nil")
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [threadPredicate, notDeletedPredicate])
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            
            do {
                let results = try context.fetch(fetchRequest)
                return try results.compactMap { try self.mapManagedObjectToEntry($0) }
            } catch {
                throw PersistenceError.fetchFailed(underlying: error)
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Performs an operation with retry logic
    private func performWithRetry(_ operation: @escaping () async throws -> Void) async throws {
        var lastError: Error?
        
        for attempt in 1...maxRetryAttempts {
            do {
                try await operation()
                return // Success, exit the retry loop
            } catch {
                lastError = error
                
                // Don't retry for validation errors or not found errors
                if error is ValidationError || (error as? PersistenceError)?.isNotFound == true {
                    throw error
                }
                
                // Wait before retrying (exponential backoff)
                if attempt < maxRetryAttempts {
                    let delay = UInt64(pow(2.0, Double(attempt - 1)) * 0.1 * 1_000_000_000) // nanoseconds
                    try await Task.sleep(nanoseconds: delay)
                }
            }
        }
        
        // All retries failed
        if let error = lastError {
            throw PersistenceError.saveFailed(underlying: error)
        }
    }
    
    /// Saves the context with proper error handling
    private func saveContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
    
    /// Maps a Thread domain entity to a managed object
    private func mapThreadToManagedObject(_ thread: Thread, managedThread: NSManagedObject) {
        managedThread.setValue(thread.id, forKey: "id")
        managedThread.setValue(thread.title, forKey: "title")
        managedThread.setValue(thread.createdAt, forKey: "createdAt")
        managedThread.setValue(thread.updatedAt, forKey: "updatedAt")
        managedThread.setValue(thread.deletedAt, forKey: "deletedAt")
    }
    
    /// Maps a managed object to a Thread domain entity
    private func mapManagedObjectToThread(_ managedObject: NSManagedObject) throws -> Thread {
        guard let id = managedObject.value(forKey: "id") as? UUID,
              let title = managedObject.value(forKey: "title") as? String,
              let createdAt = managedObject.value(forKey: "createdAt") as? Date,
              let updatedAt = managedObject.value(forKey: "updatedAt") as? Date else {
            throw PersistenceError.fetchFailed(underlying: NSError(
                domain: "CoreDataThreadRepository",
                code: 2001,
                userInfo: [NSLocalizedDescriptionKey: "Failed to map managed object to Thread"]
            ))
        }
        
        let deletedAt = managedObject.value(forKey: "deletedAt") as? Date
        
        return try Thread(id: id, title: title, createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt)
    }
    
    /// Maps an Entry domain entity to a managed object
    private func mapEntryToManagedObject(_ entry: Entry, managedEntry: NSManagedObject, managedThread: NSManagedObject) {
        managedEntry.setValue(entry.id, forKey: "id")
        managedEntry.setValue(entry.threadId, forKey: "threadId")
        managedEntry.setValue(entry.content, forKey: "content")
        managedEntry.setValue(entry.timestamp, forKey: "timestamp")
        managedEntry.setValue(managedThread, forKey: "thread")
    }
    
    /// Maps a managed object to an Entry domain entity
    private func mapManagedObjectToEntry(_ managedObject: NSManagedObject) throws -> Entry {
        guard let id = managedObject.value(forKey: "id") as? UUID,
              let threadId = managedObject.value(forKey: "threadId") as? UUID,
              let content = managedObject.value(forKey: "content") as? String,
              let timestamp = managedObject.value(forKey: "timestamp") as? Date else {
            throw PersistenceError.fetchFailed(underlying: NSError(
                domain: "CoreDataThreadRepository",
                code: 2002,
                userInfo: [NSLocalizedDescriptionKey: "Failed to map managed object to Entry"]
            ))
        }
        
        return try Entry(id: id, threadId: threadId, content: content, timestamp: timestamp)
    }
    
    /// Maps a CustomField domain entity to a managed object
    private func mapCustomFieldToManagedObject(_ field: CustomField, managedField: NSManagedObject) {
        managedField.setValue(field.id, forKey: "id")
        managedField.setValue(field.threadId, forKey: "threadId")
        managedField.setValue(field.name, forKey: "name")
        managedField.setValue(Int32(field.order), forKey: "order")
        managedField.setValue(field.isGroup, forKey: "isGroup")
    }
    
    /// Maps a managed object to a CustomField domain entity
    private func mapManagedObjectToCustomField(_ managedObject: NSManagedObject) throws -> CustomField {
        guard let id = managedObject.value(forKey: "id") as? UUID,
              let threadId = managedObject.value(forKey: "threadId") as? UUID,
              let name = managedObject.value(forKey: "name") as? String else {
            throw PersistenceError.fetchFailed(underlying: NSError(
                domain: "CoreDataThreadRepository",
                code: 2003,
                userInfo: [NSLocalizedDescriptionKey: "Failed to map managed object to CustomField"]
            ))
        }
        
        let order = managedObject.value(forKey: "order") as? Int32 ?? 0
        let isGroup = managedObject.value(forKey: "isGroup") as? Bool ?? false
        
        return try CustomField(
            id: id,
            threadId: threadId,
            name: name,
            order: Int(order),
            isGroup: isGroup
        )
    }
    
    // MARK: - Entry Update Operations
    
    func fetchEntry(id: UUID) async throws -> Entry? {
        let context = persistentContainer.viewContext
        
        return try await context.perform { [weak self] in
            guard let self = self else { return nil }
            
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Entry")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let results = try context.fetch(fetchRequest)
                guard let managedEntry = results.first else {
                    return nil
                }
                
                return try self.mapManagedObjectToEntry(managedEntry)
            } catch {
                throw PersistenceError.fetchFailed(underlying: error)
            }
        }
    }
    
    func updateEntry(_ entry: Entry) async throws -> Entry {
        let context = persistentContainer.viewContext
        
        var updatedEntry: Entry?
        
        try await performWithRetry { [weak self] in
            guard let self = self else { throw PersistenceError.updateFailed(underlying: NSError()) }
            
            // Fetch the existing entry
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Entry")
            fetchRequest.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            let results = try context.fetch(fetchRequest)
            guard let managedEntry = results.first else {
                throw PersistenceError.notFound(id: entry.id)
            }
            
            // Update the content
            managedEntry.setValue(entry.content, forKey: "content")
            
            // Also update the thread's updatedAt timestamp
            if let managedThread = managedEntry.value(forKey: "thread") as? NSManagedObject {
                managedThread.setValue(Date(), forKey: "updatedAt")
            }
            
            // Save context
            try self.saveContext(context)
            
            updatedEntry = try self.mapManagedObjectToEntry(managedEntry)
        }
        
        guard let result = updatedEntry else {
            throw PersistenceError.updateFailed(underlying: NSError())
        }
        
        return result
    }
    
    func softDeleteEntry(entryId: UUID) async throws {
        let context = persistentContainer.viewContext
        
        try await performWithRetry { [weak self] in
            guard let self = self else { throw PersistenceError.deleteFailed(underlying: NSError()) }
            
            // Fetch the entry to delete
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Entry")
            fetchRequest.predicate = NSPredicate(format: "id == %@", entryId as CVarArg)
            fetchRequest.fetchLimit = 1
            
            let results = try context.fetch(fetchRequest)
            guard let managedEntry = results.first else {
                throw PersistenceError.notFound(id: entryId)
            }
            
            // Set deletedAt timestamp
            managedEntry.setValue(Date(), forKey: "deletedAt")
            
            // Also update the thread's updatedAt timestamp
            if let managedThread = managedEntry.value(forKey: "thread") as? NSManagedObject {
                managedThread.setValue(Date(), forKey: "updatedAt")
            }
            
            // Save context
            try self.saveContext(context)
        }
    }
    
    // MARK: - Custom Field Operations
    
    func createCustomField(_ field: CustomField) async throws {
        let context = persistentContainer.viewContext
        
        try await performWithRetry { [weak self] in
            guard let self = self else { return }
            
            // Check if field already exists
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CustomField")
            fetchRequest.predicate = NSPredicate(format: "id == %@", field.id as CVarArg)
            
            let results = try context.fetch(fetchRequest)
            guard results.isEmpty else {
                throw PersistenceError.saveFailed(underlying: NSError(
                    domain: "CoreDataThreadRepository",
                    code: 1002,
                    userInfo: [NSLocalizedDescriptionKey: "CustomField with ID \(field.id) already exists"]
                ))
            }
            
            // Create new managed object
            let managedField = NSManagedObject(entity: NSEntityDescription.entity(forEntityName: "CustomField", in: context)!,
                                              insertInto: context)
            
            // Map domain entity to managed object
            self.mapCustomFieldToManagedObject(field, managedField: managedField)
            
            // Save context
            try self.saveContext(context)
        }
    }
    
    func updateCustomField(_ field: CustomField) async throws {
        let context = persistentContainer.viewContext
        
        try await performWithRetry { [weak self] in
            guard let self = self else { return }
            
            // Fetch existing field
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CustomField")
            fetchRequest.predicate = NSPredicate(format: "id == %@", field.id as CVarArg)
            
            let results = try context.fetch(fetchRequest)
            guard let managedField = results.first else {
                throw PersistenceError.notFound(id: field.id)
            }
            
            // Update managed object
            self.mapCustomFieldToManagedObject(field, managedField: managedField)
            
            // Save context
            try self.saveContext(context)
        }
    }
    
    func softDeleteCustomField(fieldId: UUID) async throws {
        let context = persistentContainer.viewContext
        
        try await performWithRetry { [weak self] in
            guard let self = self else { return }
            
            // Fetch field to soft delete
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CustomField")
            fetchRequest.predicate = NSPredicate(format: "id == %@", fieldId as CVarArg)
            
            let results = try context.fetch(fetchRequest)
            guard let managedField = results.first else {
                throw PersistenceError.notFound(id: fieldId)
            }
            
            // Set deletedAt timestamp
            managedField.setValue(Date(), forKey: "deletedAt")
            
            // Save context
            try self.saveContext(context)
        }
    }
    
    func fetchCustomFields(for threadId: UUID, includeDeleted: Bool) async throws -> [CustomField] {
        let context = persistentContainer.viewContext
        
        return try await context.perform { [weak self] in
            guard let self = self else { return [] }
            
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CustomField")
            
            // Filter by thread and deleted status
            var predicates = [NSPredicate(format: "threadId == %@", threadId as CVarArg)]
            if !includeDeleted {
                predicates.append(NSPredicate(format: "deletedAt == nil"))
            }
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            
            do {
                let results = try context.fetch(fetchRequest)
                return try results.compactMap { try self.mapManagedObjectToCustomField($0) }
            } catch {
                throw PersistenceError.fetchFailed(underlying: error)
            }
        }
    }
    
    func createFieldGroup(parentFieldId: UUID, childFieldIds: [UUID]) async throws {
        let context = persistentContainer.viewContext
        
        try await performWithRetry { [weak self] in
            guard let self = self else { return }
            
            // Fetch parent field
            let parentFetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CustomField")
            parentFetchRequest.predicate = NSPredicate(format: "id == %@", parentFieldId as CVarArg)
            
            let parentResults = try context.fetch(parentFetchRequest)
            guard let parentField = parentResults.first else {
                throw PersistenceError.notFound(id: parentFieldId)
            }
            
            // Mark parent as group
            parentField.setValue(true, forKey: "isGroup")
            
            // Fetch and update child fields
            for childId in childFieldIds {
                let childFetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CustomField")
                childFetchRequest.predicate = NSPredicate(format: "id == %@", childId as CVarArg)
                
                let childResults = try context.fetch(childFetchRequest)
                guard let childField = childResults.first else {
                    throw PersistenceError.notFound(id: childId)
                }
                
                // Set parent relationship
                childField.setValue(parentField, forKey: "parentField")
            }
            
            // Save context
            try self.saveContext(context)
        }
    }
    
    func removeFromGroup(fieldId: UUID) async throws {
        let context = persistentContainer.viewContext
        
        try await performWithRetry { [weak self] in
            guard let self = self else { return }
            
            // Fetch field to remove from group
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CustomField")
            fetchRequest.predicate = NSPredicate(format: "id == %@", fieldId as CVarArg)
            
            let results = try context.fetch(fetchRequest)
            guard let managedField = results.first else {
                throw PersistenceError.notFound(id: fieldId)
            }
            
            // Remove parent relationship
            managedField.setValue(nil, forKey: "parentField")
            
            // Save context
            try self.saveContext(context)
        }
    }
}

// MARK: - PersistenceError Extension

private extension PersistenceError {
    var isNotFound: Bool {
        if case .notFound = self {
            return true
        }
        return false
    }
}