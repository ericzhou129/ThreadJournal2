//
//  MockEntryRepository.swift
//  ThreadJournal2Tests
//
//  Mock implementation of EntryRepository for testing
//

import Foundation
@testable import ThreadJournal2

class MockEntryRepository: EntryRepository {
    var savedFieldValues: [UUID: [EntryFieldValue]] = [:]
    var fetchFieldValuesCalled = false
    var removeFieldValueCalled = false
    
    func saveFieldValues(for entryId: UUID, fieldValues: [EntryFieldValue]) async throws {
        savedFieldValues[entryId] = fieldValues
    }
    
    func fetchFieldValues(for entryId: UUID) async throws -> [EntryFieldValue] {
        fetchFieldValuesCalled = true
        return savedFieldValues[entryId] ?? []
    }
    
    func removeFieldValue(from entryId: UUID, fieldId: UUID) async throws {
        removeFieldValueCalled = true
        if var values = savedFieldValues[entryId] {
            values.removeAll { $0.fieldId == fieldId }
            savedFieldValues[entryId] = values
        }
    }
    
    func fetchEntriesWithField(
        fieldId: UUID,
        value: String?,
        in threadId: UUID?
    ) async throws -> [Entry] {
        // Mock implementation
        return []
    }
}