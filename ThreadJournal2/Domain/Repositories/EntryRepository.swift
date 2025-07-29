//
//  EntryRepository.swift
//  ThreadJournal2
//
//  Repository protocol for entry-specific operations including field values
//

import Foundation

/// Protocol defining methods for entry field value operations
protocol EntryRepository {
    /// Adds or updates field values for an entry
    /// - Parameters:
    ///   - entryId: The ID of the entry
    ///   - fieldValues: Array of field values to save
    /// - Throws: PersistenceError if the operation fails
    func saveFieldValues(for entryId: UUID, fieldValues: [EntryFieldValue]) async throws
    
    /// Fetches field values for a specific entry
    /// - Parameter entryId: The ID of the entry
    /// - Returns: Array of field values for the entry
    /// - Throws: PersistenceError if the operation fails
    func fetchFieldValues(for entryId: UUID) async throws -> [EntryFieldValue]
    
    /// Removes a specific field value from an entry
    /// - Parameters:
    ///   - entryId: The ID of the entry
    ///   - fieldId: The ID of the field to remove
    /// - Throws: PersistenceError if the operation fails
    func removeFieldValue(from entryId: UUID, fieldId: UUID) async throws
    
    /// Fetches all entries with a specific field value
    /// - Parameters:
    ///   - fieldId: The ID of the field
    ///   - value: The value to search for (optional, returns all if nil)
    ///   - threadId: Limit to specific thread (optional)
    /// - Returns: Array of entries that have the specified field value
    /// - Throws: PersistenceError if the operation fails
    func fetchEntriesWithField(
        fieldId: UUID,
        value: String?,
        in threadId: UUID?
    ) async throws -> [Entry]
}