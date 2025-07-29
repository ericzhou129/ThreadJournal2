//
//  EntryFieldValue.swift
//  ThreadJournal2
//
//  Domain entity representing a field value attached to an entry
//

import Foundation

/// A value for a custom field attached to a specific entry
struct EntryFieldValue: Equatable {
    let fieldId: UUID
    let value: String
    
    /// Creates a new EntryFieldValue with validation
    /// - Parameters:
    ///   - fieldId: The ID of the custom field
    ///   - value: The value for this field (can be empty)
    init(fieldId: UUID, value: String) {
        self.fieldId = fieldId
        self.value = value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}