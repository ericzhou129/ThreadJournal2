//
//  CustomField.swift
//  ThreadJournal2
//
//  Domain entity representing a custom field for structured data
//

import Foundation

/// A custom field that can be attached to journal entries
struct CustomField: Identifiable, Equatable {
    let id: UUID
    let threadId: UUID
    let name: String
    let order: Int
    let isGroup: Bool
    
    /// Creates a new CustomField with validation
    /// - Parameters:
    ///   - id: Unique identifier for the field
    ///   - threadId: The thread this field belongs to
    ///   - name: Display name of the field (1-50 characters)
    ///   - order: Display order within the thread
    ///   - isGroup: Whether this field is a group container
    /// - Throws: ValidationError if name is invalid
    init(
        id: UUID = UUID(),
        threadId: UUID,
        name: String,
        order: Int,
        isGroup: Bool = false
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            throw ValidationError.emptyFieldName
        }
        
        guard trimmedName.count <= 50 else {
            throw ValidationError.fieldNameTooLong
        }
        
        self.id = id
        self.threadId = threadId
        self.name = trimmedName
        self.order = order
        self.isGroup = isGroup
    }
}