//
//  MockThreadRepository+CustomFields.swift
//  ThreadJournal2Tests
//
//  Mock implementation of ThreadRepository custom field methods for testing
//

import Foundation
@testable import ThreadJournal2

extension MockThreadRepository {
    func createCustomField(_ field: CustomField) async throws {
        // Mock implementation
    }
    
    func updateCustomField(_ field: CustomField) async throws {
        // Mock implementation
    }
    
    func softDeleteCustomField(fieldId: UUID) async throws {
        // Mock implementation
    }
    
    func fetchCustomFields(for threadId: UUID, includeDeleted: Bool) async throws -> [CustomField] {
        // Mock implementation
        return []
    }
    
    func createFieldGroup(parentFieldId: UUID, childFieldIds: [UUID]) async throws {
        // Mock implementation
    }
    
    func removeFromGroup(fieldId: UUID) async throws {
        // Mock implementation
    }
}