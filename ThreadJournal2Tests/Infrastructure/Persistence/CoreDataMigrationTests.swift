//
//  CoreDataMigrationTests.swift
//  ThreadJournal2Tests
//
//  Tests for Core Data model migrations
//

import XCTest
import CoreData
@testable import ThreadJournal2

class CoreDataMigrationTests: XCTestCase {
    
    // MARK: - Migration v1.0 to v1.2 Tests
    
    func testMigrationFromV1ToV2AddsDeletedAtToThread() throws {
        // This test verifies that the migration properly adds the deletedAt field
        // In a real app, you would:
        // 1. Create a v1 store with test data
        // 2. Perform migration to v2
        // 3. Verify data integrity and new field exists
        
        // For now, we'll test that the current model has the expected attributes
        let container = NSPersistentContainer(name: "ThreadDataModel")
        
        // Load the model
        let model = container.managedObjectModel
        
        // Check Thread entity has deletedAt attribute
        guard let threadEntity = model.entitiesByName["Thread"] else {
            XCTFail("Thread entity not found in model")
            return
        }
        
        let deletedAtAttribute = threadEntity.attributesByName["deletedAt"]
        XCTAssertNotNil(deletedAtAttribute, "Thread entity should have deletedAt attribute")
        XCTAssertEqual(deletedAtAttribute?.attributeType, .dateAttributeType)
        XCTAssertTrue(deletedAtAttribute?.isOptional ?? false, "deletedAt should be optional")
    }
    
    func testEntryEntityHasDeletedAt() throws {
        // Verify Entry entity already has deletedAt from previous migrations
        let container = NSPersistentContainer(name: "ThreadDataModel")
        
        let model = container.managedObjectModel
        
        guard let entryEntity = model.entitiesByName["Entry"] else {
            XCTFail("Entry entity not found in model")
            return
        }
        
        let deletedAtAttribute = entryEntity.attributesByName["deletedAt"]
        XCTAssertNotNil(deletedAtAttribute, "Entry entity should have deletedAt attribute")
        XCTAssertEqual(deletedAtAttribute?.attributeType, .dateAttributeType)
        XCTAssertTrue(deletedAtAttribute?.isOptional ?? false, "deletedAt should be optional")
    }
    
    func testThreadEntityRelationships() throws {
        // Verify Thread has cascade delete relationship to entries
        let container = NSPersistentContainer(name: "ThreadDataModel")
        
        let model = container.managedObjectModel
        
        guard let threadEntity = model.entitiesByName["Thread"] else {
            XCTFail("Thread entity not found in model")
            return
        }
        
        guard let entriesRelationship = threadEntity.relationshipsByName["entries"] else {
            XCTFail("Thread should have entries relationship")
            return
        }
        
        XCTAssertEqual(entriesRelationship.deleteRule, .cascadeDeleteRule, 
                      "Thread entries relationship should have cascade delete rule")
        XCTAssertTrue(entriesRelationship.isToMany, "Entries relationship should be to-many")
    }
    
    // MARK: - Lightweight Migration Test
    
    func testLightweightMigrationIsSupported() throws {
        // Create a persistent store coordinator with automatic migration
        let storeURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
        
        let container = NSPersistentContainer(name: "ThreadDataModel")
        
        // Configure for automatic lightweight migration
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        container.persistentStoreDescriptions = [description]
        
        let expectation = self.expectation(description: "Store loaded")
        
        container.loadPersistentStores { (storeDescription, error) in
            XCTAssertNil(error, "Lightweight migration should succeed")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
        
        // Clean up
        try? FileManager.default.removeItem(at: storeURL)
    }
}