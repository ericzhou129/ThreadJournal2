//
//  CustomFieldGroup.swift
//  ThreadJournal2
//
//  Domain entity representing a group of custom fields
//

import Foundation

/// Represents the relationship between a parent field (group) and its child fields
struct CustomFieldGroup: Equatable {
    let parentField: CustomField
    let childFields: [CustomField]
    
    /// Creates a new CustomFieldGroup with validation
    /// - Parameters:
    ///   - parentField: The field that acts as the group container
    ///   - childFields: Fields contained within this group
    /// - Throws: ValidationError if parent is not a group or if nested groups detected
    init(parentField: CustomField, childFields: [CustomField]) throws {
        guard parentField.isGroup else {
            throw ValidationError.parentNotGroup
        }
        
        // Ensure no nested groups
        if childFields.contains(where: { $0.isGroup }) {
            throw ValidationError.nestedGroupsNotAllowed
        }
        
        // Ensure all fields belong to same thread
        let threadId = parentField.threadId
        guard childFields.allSatisfy({ $0.threadId == threadId }) else {
            throw ValidationError.fieldsFromDifferentThreads
        }
        
        self.parentField = parentField
        self.childFields = childFields
    }
}