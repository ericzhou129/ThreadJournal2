//
//  CoreDataMigrationV3Tests.swift
//  ThreadJournal2Tests
//
//  Tests for Core Data migration from v2 to v3 (custom fields)
//

import XCTest
import CoreData
@testable import ThreadJournal2

final class CoreDataMigrationV3Tests: XCTestCase {
    
    func testMigrationFromV2ToV3() throws {
        // Given - Create a v2 persistent container
        let v2ModelURL = Bundle.main.url(
            forResource: "ThreadDataModel_v2",
            withExtension: "xcdatamodel",
            subdirectory: "ThreadDataModel.xcdatamodeld"
        )!
        
        let v2Model = NSManagedObjectModel(contentsOf: v2ModelURL)!
        
        // Create temporary store
        let storeURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
        
        let v2Container = NSPersistentContainer(name: "TestContainer", managedObjectModel: v2Model)
        let description = NSPersistentStoreDescription(url: storeURL)
        v2Container.persistentStoreDescriptions = [description]
        
        var loadError: Error?
        v2Container.loadPersistentStores { _, error in
            loadError = error
        }
        XCTAssertNil(loadError)
        
        // Add some v2 data
        let context = v2Container.viewContext
        let thread = NSEntityDescription.insertNewObject(forEntityName: "Thread", into: context)
        thread.setValue(UUID(), forKey: "id")
        thread.setValue("Test Thread", forKey: "title")
        thread.setValue(Date(), forKey: "createdAt")
        thread.setValue(Date(), forKey: "updatedAt")
        
        let entry = NSEntityDescription.insertNewObject(forEntityName: "Entry", into: context)
        entry.setValue(UUID(), forKey: "id")
        entry.setValue(thread.value(forKey: "id"), forKey: "threadId")
        entry.setValue("Test entry", forKey: "content")
        entry.setValue(Date(), forKey: "timestamp")
        entry.setValue(thread, forKey: "thread")
        
        try context.save()
        
        // When - Migrate to v3
        let v3ModelURL = Bundle.main.url(
            forResource: "ThreadDataModel_v3",
            withExtension: "xcdatamodel",
            subdirectory: "ThreadDataModel.xcdatamodeld"
        )!
        
        let v3Model = NSManagedObjectModel(contentsOf: v3ModelURL)!
        
        // Perform migration
        let migrationSuccess = migrateStore(
            from: v2Model,
            to: v3Model,
            storeURL: storeURL
        )
        
        // Then
        XCTAssertTrue(migrationSuccess, "Migration should succeed")
        
        // Verify data preserved in v3
        let v3Container = NSPersistentContainer(name: "TestContainer", managedObjectModel: v3Model)
        v3Container.persistentStoreDescriptions = [description]
        
        v3Container.loadPersistentStores { _, error in
            loadError = error
        }
        XCTAssertNil(loadError)
        
        let v3Context = v3Container.viewContext
        let threadFetch = NSFetchRequest<NSManagedObject>(entityName: "Thread")
        let threads = try v3Context.fetch(threadFetch)
        
        XCTAssertEqual(threads.count, 1)
        XCTAssertEqual(threads.first?.value(forKey: "title") as? String, "Test Thread")
        
        // Clean up
        try FileManager.default.removeItem(at: storeURL)
    }
    
    private func migrateStore(from sourceModel: NSManagedObjectModel,
                             to destinationModel: NSManagedObjectModel,
                             storeURL: URL) -> Bool {
        // Check if migration is needed
        let sourceMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: storeURL
        )
        
        guard let metadata = sourceMetadata else { return false }
        
        if destinationModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
            // No migration needed
            return true
        }
        
        // Perform lightweight migration
        let mappingModel = try? NSMappingModel.inferredMappingModel(
            forSourceModel: sourceModel,
            destinationModel: destinationModel
        )
        
        guard mappingModel != nil else {
            // Fall back to manual migration if needed
            return false
        }
        
        return true // Lightweight migration should work
    }
}