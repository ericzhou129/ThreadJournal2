//
//  MockThreadRepository+CustomFields.swift
//  ThreadJournal2Tests
//
//  Mock implementation of ThreadRepository custom field methods for testing
//

import Foundation
@testable import ThreadJournal2

extension MockThreadRepository {
    private struct AssociatedKeys {
        static var customFields: UInt8 = 0
        static var softDeletedFieldIds: UInt8 = 0
        static var fieldGroups: UInt8 = 0
    }
    
    var customFields: [CustomField] {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.customFields) as? [CustomField] ?? []
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.customFields, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var softDeletedFieldIds: [UUID] {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.softDeletedFieldIds) as? [UUID] ?? []
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.softDeletedFieldIds, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var fieldGroups: [CustomFieldGroup] {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.fieldGroups) as? [CustomFieldGroup] ?? []
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.fieldGroups, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    func createCustomField(_ field: CustomField) async throws {
        customFields.append(field)
    }
    
    func updateCustomField(_ field: CustomField) async throws {
        if let index = customFields.firstIndex(where: { $0.id == field.id }) {
            customFields[index] = field
        }
    }
    
    func softDeleteCustomField(fieldId: UUID) async throws {
        softDeletedFieldIds.append(fieldId)
    }
    
    func fetchCustomFields(for threadId: UUID, includeDeleted: Bool) async throws -> [CustomField] {
        fetchCustomFieldsCallCount += 1
        return customFields.filter { $0.threadId == threadId }
    }
    
    func createFieldGroup(parentFieldId: UUID, childFieldIds: [UUID]) async throws {
        // Verify the IDs exist
        guard customFields.contains(where: { $0.id == parentFieldId }) else {
            throw PersistenceError.notFound(id: parentFieldId)
        }
        
        for childId in childFieldIds {
            guard customFields.contains(where: { $0.id == childId }) else {
                throw PersistenceError.notFound(id: childId)
            }
        }
    }
    
    func removeFromGroup(fieldId: UUID) async throws {
        // Mock implementation - in real implementation would update relationships
    }
    
    func fetchFieldGroups(for threadId: UUID, includeDeleted: Bool) async throws -> [CustomFieldGroup] {
        fetchFieldGroupsCallCount += 1
        return fieldGroups.filter { $0.parentField.threadId == threadId }
    }
    
    /// Sets custom fields for a thread (for performance testing)
    func setCustomFields(_ fields: [CustomField], for threadId: UUID) {
        // Filter fields by the specific threadId and add them to the global customFields array
        let threadFields = fields.filter { $0.threadId == threadId }
        customFields = customFields.filter { $0.threadId != threadId } + threadFields
    }
}