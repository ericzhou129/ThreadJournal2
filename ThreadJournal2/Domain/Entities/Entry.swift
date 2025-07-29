//
//  Entry.swift
//  ThreadJournal2
//
//  Domain entity representing a single timestamped thought within a thread
//

import Foundation

/// A single timestamped thought within a thread
struct Entry: Identifiable, Equatable {
    let id: UUID
    let threadId: UUID
    let content: String
    let timestamp: Date
    let customFieldValues: [EntryFieldValue]
    
    /// Creates a new Entry with validation
    /// - Parameters:
    ///   - id: Unique identifier for the entry
    ///   - threadId: The ID of the thread this entry belongs to
    ///   - content: The content of the entry (cannot be empty)
    ///   - timestamp: When the entry was created
    ///   - customFieldValues: Optional custom field values for structured data
    /// - Throws: ValidationError if content is empty
    init(
        id: UUID = UUID(),
        threadId: UUID,
        content: String,
        timestamp: Date = Date(),
        customFieldValues: [EntryFieldValue] = []
    ) throws {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyContent
        }
        
        self.id = id
        self.threadId = threadId
        self.content = content
        self.timestamp = timestamp
        self.customFieldValues = customFieldValues
    }
}