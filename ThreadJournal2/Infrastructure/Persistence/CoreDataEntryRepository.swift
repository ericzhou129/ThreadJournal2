//
//  CoreDataEntryRepository.swift
//  ThreadJournal2
//
//  Core Data implementation of EntryRepository protocol for field values
//

import Foundation
import CoreData

/// Core Data implementation of the EntryRepository protocol
final class CoreDataEntryRepository: EntryRepository {
    private let persistentContainer: NSPersistentContainer
    
    /// Initializes the repository with a persistent container
    /// - Parameter persistentContainer: The Core Data persistent container
    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }
    
    // MARK: - EntryRepository Implementation
    
    func saveFieldValues(for entryId: UUID, fieldValues: [EntryFieldValue]) async throws {
        let context = persistentContainer.viewContext
        
        try await context.perform { [weak self] in
            guard let self = self else { return }
            
            // First, remove existing field values for this entry
            let deleteRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "EntryFieldValue")
            deleteRequest.predicate = NSPredicate(format: "entryId == %@", entryId as CVarArg)
            
            let existingValues = try context.fetch(deleteRequest)
            existingValues.forEach { context.delete($0) }
            
            // Then add new field values
            for fieldValue in fieldValues {
                let managedFieldValue = NSManagedObject(
                    entity: NSEntityDescription.entity(forEntityName: "EntryFieldValue", in: context)!,
                    insertInto: context
                )
                
                managedFieldValue.setValue(UUID(), forKey: "id")
                managedFieldValue.setValue(entryId, forKey: "entryId")
                managedFieldValue.setValue(fieldValue.fieldId, forKey: "fieldId")
                managedFieldValue.setValue(fieldValue.value, forKey: "value")
            }
            
            // Save context
            guard context.hasChanges else { return }
            
            do {
                try context.save()
            } catch {
                context.rollback()
                throw PersistenceError.saveFailed(underlying: error)
            }
        }
    }
    
    func fetchFieldValues(for entryId: UUID) async throws -> [EntryFieldValue] {
        let context = persistentContainer.viewContext
        
        return try await context.perform { [weak self] in
            guard self != nil else { return [] }
            
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "EntryFieldValue")
            fetchRequest.predicate = NSPredicate(format: "entryId == %@", entryId as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                return results.compactMap { managedObject in
                    guard let fieldId = managedObject.value(forKey: "fieldId") as? UUID,
                          let value = managedObject.value(forKey: "value") as? String else {
                        return nil
                    }
                    
                    return EntryFieldValue(fieldId: fieldId, value: value)
                }
            } catch {
                throw PersistenceError.fetchFailed(underlying: error)
            }
        }
    }
    
    func removeFieldValue(from entryId: UUID, fieldId: UUID) async throws {
        let context = persistentContainer.viewContext
        
        try await context.perform { [weak self] in
            guard self != nil else { return }
            
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "EntryFieldValue")
            let entryPredicate = NSPredicate(format: "entryId == %@", entryId as CVarArg)
            let fieldPredicate = NSPredicate(format: "fieldId == %@", fieldId as CVarArg)
            fetchRequest.predicate = NSCompoundPredicate(
                andPredicateWithSubpredicates: [entryPredicate, fieldPredicate]
            )
            
            do {
                let results = try context.fetch(fetchRequest)
                results.forEach { context.delete($0) }
                
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                context.rollback()
                throw PersistenceError.deleteFailed(underlying: error)
            }
        }
    }
    
    func fetchEntriesWithField(
        fieldId: UUID,
        value: String?,
        in threadId: UUID?
    ) async throws -> [Entry] {
        let context = persistentContainer.viewContext
        
        return try await context.perform { [weak self] in
            guard let self = self else { return [] }
            
            // First fetch the field values
            let fieldValueFetchRequest: NSFetchRequest<NSManagedObject> = 
                NSFetchRequest(entityName: "EntryFieldValue")
            
            var fieldPredicates = [NSPredicate(format: "fieldId == %@", fieldId as CVarArg)]
            if let value = value {
                fieldPredicates.append(NSPredicate(format: "value == %@", value))
            }
            fieldValueFetchRequest.predicate = NSCompoundPredicate(
                andPredicateWithSubpredicates: fieldPredicates
            )
            
            do {
                let fieldValueResults = try context.fetch(fieldValueFetchRequest)
                let entryIds = fieldValueResults.compactMap { 
                    $0.value(forKey: "entryId") as? UUID 
                }
                
                guard !entryIds.isEmpty else { return [] }
                
                // Then fetch the entries
                let entryFetchRequest: NSFetchRequest<NSManagedObject> = 
                    NSFetchRequest(entityName: "Entry")
                
                var entryPredicates = [
                    NSPredicate(format: "id IN %@", entryIds),
                    NSPredicate(format: "deletedAt == nil")
                ]
                
                if let threadId = threadId {
                    entryPredicates.append(NSPredicate(format: "threadId == %@", threadId as CVarArg))
                }
                
                entryFetchRequest.predicate = NSCompoundPredicate(
                    andPredicateWithSubpredicates: entryPredicates
                )
                entryFetchRequest.sortDescriptors = [
                    NSSortDescriptor(key: "timestamp", ascending: false)
                ]
                
                let entryResults = try context.fetch(entryFetchRequest)
                return try entryResults.compactMap { managedEntry in
                    guard let id = managedEntry.value(forKey: "id") as? UUID,
                          let threadId = managedEntry.value(forKey: "threadId") as? UUID,
                          let content = managedEntry.value(forKey: "content") as? String,
                          let timestamp = managedEntry.value(forKey: "timestamp") as? Date else {
                        return nil
                    }
                    
                    return try Entry(
                        id: id,
                        threadId: threadId,
                        content: content,
                        timestamp: timestamp
                    )
                }
            } catch {
                throw PersistenceError.fetchFailed(underlying: error)
            }
        }
    }
}